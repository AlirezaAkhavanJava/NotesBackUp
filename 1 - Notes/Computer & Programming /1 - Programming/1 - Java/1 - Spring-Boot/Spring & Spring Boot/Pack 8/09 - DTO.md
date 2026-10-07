A **DTO (Data Transfer Object)** is a simple object used to **carry data between different parts of an application**, especially between the client and the backend. Instead of sending the actual Entity with all its database-related fields, we create a DTO containing **only the data we want to receive or send**, which gives us better control over the API and prevents exposing unnecessary or sensitive information.



![[1791349370.jpg]]


# DTO (Data Transfer Object)

## Core intuition

A DTO is a plain Java object whose only job is to **carry data between two parts of a program**, usually between your server and the outside world (the client).

Think of a restaurant. The kitchen (your database and entities) has raw ingredients, internal labels, and storage details. The customer doesn't get the kitchen. They get a **plated dish**, shaped for them. A DTO is the plate: the entity is the kitchen's internal representation, and the DTO is what you serve.

```
Database ──▶ Entity ──▶ [mapping] ──▶ DTO ──▶ JSON ──▶ Client
(rows)       (JPA model)                (API model)
```

## Formal definition

A DTO is an object that:

- Holds **data only**: fields, constructor, getters (no business logic, no database behavior).
- Has **no JPA annotations**: no `@Entity`, `@Id`, `@OneToMany`, and so on.
- Is **shaped for a specific use case** (one endpoint, one screen, one request), not for a table.
- Is typically **immutable** in modern Java.

The pattern comes from distributed systems, where each call across a network boundary is expensive, so you send exactly one well-shaped package instead of many small calls.

## Why it exists: the problems it solves

You have already met the first one:

|Problem when returning entities directly|How a DTO solves it|
|---|---|
|**Infinite recursion** (`Customer` ↔ `Order`)|A DTO graph is a tree with a defined shape, so no cycle can exist.|
|**Leaking fields** (`passwordHash`, internal flags)|Only the fields you put in the DTO exist in the JSON.|
|**API tied to the database** (rename a column, break every client)|The API contract is independent of table structure.|
|**Lazy loading errors** (`LazyInitializationException`, hidden N+1 queries)|You decide in the service layer what gets loaded, then copy it into the DTO.|
|**Over-posting** (client sends `"id": 5` or `"role": "ADMIN"` and it binds to your entity)|A request DTO only contains the fields the client is allowed to set.|
|**One shape for every use** (list needs 3 fields, detail needs 20)|Different DTOs for different endpoints.|

## Code: from entity to DTO

The entity (unchanged, no Jackson annotations needed):

```java
@Entity
public class Customer {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private String email;
    private String passwordHash;          // must never reach the client

    @OneToMany(mappedBy = "customer")
    private List<Order> orders = new ArrayList<>();
    // getters/setters
}
```

The DTOs, written as Java **records** (Java 16+), which are ideal for DTOs because they are immutable and have no boilerplate:

```java
public record OrderResponse(Long id, String item) {}

public record CustomerResponse(Long id, String name, List<OrderResponse> orders) {}
```

The mapping and service:

```java
@Service
public class CustomerService {

    private final CustomerRepository repository;

    public CustomerService(CustomerRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public CustomerResponse getCustomer(Long id) {
        Customer c = repository.findById(id).orElseThrow();
        return new CustomerResponse(
            c.getId(),
            c.getName(),
            c.getOrders().stream()
                .map(o -> new OrderResponse(o.getId(), o.getItem()))
                .toList()
        );
    }
}
```

```java
@RestController
@RequestMapping("/customers")
public class CustomerController {

    private final CustomerService service;

    public CustomerController(CustomerService service) {
        this.service = service;
    }

    @GetMapping("/{id}")
    public CustomerResponse get(@PathVariable Long id) {
        return service.getCustomer(id);
    }
}
```

**What this does:**

1. The service loads the entity inside a transaction, so lazy `orders` can be read safely.
2. It copies exactly the wanted fields into DTOs. `email` and `passwordHash` are never copied.
3. The controller returns the DTO, and Jackson serializes a simple tree.

The JSON is:

```json
{ "id": 1, "name": "Ali", "orders": [ { "id": 10, "item": "Book" } ] }
```

There is no recursion, no hidden fields, and **no Jackson annotations anywhere**.

## Request DTOs vs response DTOs

DTOs work in both directions, and they are usually **different classes**:

```java
// Input: only what the client may send
public record CreateCustomerRequest(
    @NotBlank String name,
    @Email String email
) {}

// Output: only what the client may see
public record CustomerResponse(Long id, String name, List<OrderResponse> orders) {}
```

```java
@PostMapping
public CustomerResponse create(@Valid @RequestBody CreateCustomerRequest req) {
    return service.create(req);
}
```

Why separate? A request has no `id` (the database creates it), and a response has no password. One class can't represent both without compromises. Request DTOs are also the natural home for Bean Validation (`@NotBlank`, `@Email`), which keeps validation rules off your entities.

This also solves what `@JsonManagedReference` did on input: you wire relationships yourself, explicitly.

```java
public record CreateOrderRequest(Long customerId, String item) {}

@Transactional
public OrderResponse createOrder(CreateOrderRequest req) {
    Customer customer = customerRepository.getReferenceById(req.customerId());
    Order order = new Order();
    order.setItem(req.item());
    order.setCustomer(customer);                  // owning side, so the FK is saved
    return toResponse(orderRepository.save(order));
}
```

The client sends only `customerId` (a number), which matches the actual foreign key column from your `@JoinColumn` lesson.

## Ways to do the mapping

Writing `new CustomerResponse(...)` by hand is fine for small projects but becomes tedious. Your options:

|Approach|How|Notes|
|---|---|---|
|**Manual**|Constructors or `toDto()` methods|Most explicit, easiest to debug, best for learning|
|**MapStruct**|Annotation processor that **generates** the mapping code at compile time|Industry standard, fast, type-safe|
|**ModelMapper**|Reflection at runtime|Convenient, but errors appear at runtime and it is slower|
|**JPA projections**|Query returns DTOs directly (below)|Skips loading the full entity|

A MapStruct mapper looks like this:

```java
@Mapper(componentModel = "spring")
public interface CustomerMapper {
    CustomerResponse toResponse(Customer customer);
    OrderResponse toResponse(Order order);
}
```

MapStruct generates the implementation at compile time, and you inject `CustomerMapper` like any Spring bean.

## Projections: skipping the entity entirely

When you only need a few columns, you can have Spring Data build the DTO directly from the query, so Hibernate never loads full entities:

```java
public interface CustomerRepository extends JpaRepository<Customer, Long> {

    // Interface-based projection
    interface CustomerSummary {
        Long getId();
        String getName();
    }
    List<CustomerSummary> findAllBy();

    // Class/record-based projection via JPQL
    @Query("select new com.example.CustomerResponse(c.id, c.name, null) from Customer c")
    List<CustomerResponse> findSummaries();
}
```

This is more efficient for read-heavy list endpoints, because the SQL selects only `id` and `name`.

## Rules and gotchas

- **Do the conversion inside the transaction** (service layer). Lazy fields can only be read while the session is open. Converting there avoids `LazyInitializationException`.
- **Don't put DTOs in the repository layer** except for projections, and don't put entities in the controller layer. The usual flow is Controller (DTO) → Service (converts) → Repository (entity).
- **Nested DTOs should be DTOs too.** If `CustomerResponse` contains `List<Order>` (the entity), you have brought the problem back.
- **A DTO is not an entity copy.** Don't create one DTO per entity out of habit. Create one per use case, and let it differ from the entity.
- **Keep DTOs free of logic.** Formatting or small derived values are fine; database calls and business rules are not.
- **Lombok or records.** Records need no library. If you use classes, `@Getter` and a constructor are enough. Avoid `@Data` on anything with cycles.
- **Naming conventions vary:** `CustomerDto`, `CustomerResponse`, `CustomerRequest`. Pick one style and stay consistent.
- **Don't over-engineer tiny apps.** For a quick prototype, returning entities with `@JsonIgnore` is acceptable. The cost shows up as the project grows.

## Related terms (often confused)

|Term|Meaning|
|---|---|
|**Entity**|A JPA-mapped class tied to a database table. It has identity and lifecycle (managed by Hibernate).|
|**DTO**|A plain data carrier across a boundary. It has no persistence behavior.|
|**POJO**|"Plain Old Java Object": any ordinary class with no framework requirement. Entities and DTOs can both be POJOs, so it is a broader term.|
|**VO (Value Object)**|An immutable object defined by its values, with no identity (like `Money` or `Address`). Sometimes used interchangeably with DTO, but VO is a domain concept, while DTO is a transport concept.|
|**Projection**|A query result shaped as a subset of columns, which can be a DTO.|

## Mental model recap

- **Entity** = how the database sees the data.
- **DTO** = how the outside world sees the data.
- The **service layer** is the translator between them.
- Using DTOs means you never need `@JsonManagedReference`, `@JsonIgnore`, or `@JsonBackReference`, because the problem those annotations patch never reaches the JSON layer.





[[Spring Framework]]