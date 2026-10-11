

## Explanation (one paragraph)

`@JsonManagedReference` and `@JsonBackReference` solve a mismatch between two worlds. Your JPA mapping is bidirectional, so a `Customer` knows its `Order`s and each `Order` knows its `Customer`, which forms a loop in memory. JSON is a tree and cannot express a loop, so at some point a link has to be left out. These annotations choose that point permanently: the parent-to-child link (`orders`) is written as real JSON, and the child-to-parent link (`customer`) is never written. They also do something `@JsonIgnore` cannot. When JSON comes in, Jackson rebuilds the child-to-parent link for you by setting `order.customer` to the parent object it is currently building. So the pair gives you a loop-free output and a correctly wired object graph on input, which is what lets Hibernate write the `customer_id` foreign key. The cost is that the direction is fixed: you can never get the customer out of an order's JSON.

## Scenario

A client sends a request to create a customer together with their orders. The controller calls `customerRepository.save(customer)`, and `Customer.orders` has `cascade = CascadeType.ALL`.

1. The client sends `POST /customers` with `{"name":"Ali","orders":[{"item":"Book"},{"item":"Pen"}]}`.
2. Jackson creates a `Customer` and sets `name = "Ali"`.
3. Jackson reaches `orders`, sees `@JsonManagedReference`, and creates two `Order` objects (`Book`, `Pen`).
4. Jackson loops over those orders and sets `order.customer = <the Customer it is building>` on each one, using the `@JsonBackReference` setter. The client never sent this.
5. The controller calls `save(customer)`, and the cascade also saves both orders.
6. Hibernate reads each order's `customer` field (the owning side with `@JoinColumn`) and writes `customer_id = 1` into both rows.
7. The response is serialized: `customer` is skipped on each order (back reference), so the output is finite.

## Description of the scenario

|Step|What it demonstrates|
|---|---|
|2-3|The managed side is handled like a normal nested property.|
|4|The key feature: back-linking happens automatically, only because both annotations are present and the children arrived nested inside the parent.|
|5-6|Why this matters for the database: without step 4, `order.customer` stays `null`, and Hibernate would save `customer_id = NULL` for both orders. This is the "only the owning side writes the FK" rule from earlier.|
|7|Why there is no infinite recursion: the back property was removed from `Order`'s property list when the serializer was built, so there is no edge to follow.|

Resulting response:

```json
{ "id": 1, "name": "Ali",
  "orders": [ { "id": 1, "item": "Book" },
              { "id": 2, "item": "Pen" } ] }
```

**What would break this scenario:**

1. If the client sent `POST /orders` with a standalone order, there is no parent in the JSON, so `customer` stays `null`.
2. If you used `@JsonIgnore` on `Order.customer` instead, step 4 would not happen, and the FK would be `NULL`.

---


## 1. The problem

A bidirectional JPA mapping creates a cycle in the **Java object graph**:

```
Customer ── orders──▶ Order ──customer ──▶ Customer ──orders──▶ ...
```

JSON is a **tree**: it has no way to say "this node is the same as one I already wrote." Any cycle in the object graph therefore has to be cut somewhere. These two annotations cut it at a fixed, declared edge:

- **Managed (forward) side:** the edge Jackson follows.
- **Back side:** the edge Jackson refuses to write.

They are always a pair. The pair gives you a contract: **parent to child is real JSON, child to parent is reconstructed by Jackson, not transmitted.**

## 2. Formal definition

```java
@Target({ElementType.ANNOTATION_TYPE, ElementType.METHOD, ElementType.FIELD})
public @interface JsonManagedReference { String value() default "defaultReference"; }

@Target({ElementType.ANNOTATION_TYPE, ElementType.METHOD, ElementType.FIELD})
public @interface JsonBackReference { String value() default "defaultReference"; }
```

||`@JsonManagedReference`|`@JsonBackReference`|
|---|---|---|
|Side|Parent, forward link|Child, link back to parent|
|JPA equivalent|The `mappedBy` (inverse) side|The `@JoinColumn` (owning) side|
|Serialization|Written normally|**Omitted**|
|Deserialization|After the child is built, Jackson calls the child's back-reference setter|Populated by Jackson, **never read from JSON**|
|Allowed types|POJO, `Collection`, `Map`, array|**Single POJO only**|
|`value`|Link name|Same link name|

Both are placed on fields or methods (getter/setter), not on constructor parameters.

## 3. What happens internally

This is where the "why" lives. Jackson treats each direction differently.

### Serialization

1. Jackson builds a `BeanSerializer` for each class by listing its properties.
2. While building the property list, it asks the annotation introspector whether each property is a **back reference**.
3. Back-reference properties are **removed from the list**. They never become a writer.
4. At runtime there is simply no `customer` property on `Order`, so the cycle has no edge to follow.

Nothing is "detected" at runtime. The cycle is prevented **structurally**, before any object is serialized. That is why this approach has no runtime cost and never throws a recursion error.

### Deserialization

1. When Jackson builds the `BeanDeserializer` for `Customer`, it finds `orders` marked as managed with name `"defaultReference"`.
2. In its resolve phase, it asks the `Order` deserializer: "do you have a back-reference property with that name?" If not, it fails at that point, before parsing any JSON.
3. It wraps the `orders` property in a special `ManagedReferenceProperty`.
4. While parsing, after the `orders` value is deserialized, this wrapper loops over every element (it unwraps collections, maps, and arrays) and calls the back property's setter on each element, passing the **parent instance** that is currently being built.

Numbered flow for `{"id":1,"name":"Ali","orders":[{"id":10},{"id":11}]}`:

1. Create `Customer`, set `id` and `name`.
2. Parse the array: create `Order(10)` and `Order(11)`.
3. Managed wrapper iterates: `order10.customer = customer`, `order11.customer = customer`.
4. Set `customer.orders = list`.

Because the parent instance is reused, the back reference is the **same object**, not a copy.

## 4. Full working example

```java
@Entity
public class Customer {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;

    @OneToMany(mappedBy = "customer", cascade = CascadeType.ALL)
    @JsonManagedReference
    private List<Order> orders = new ArrayList<>();
    // getters/setters
}

@Entity
@Table(name = "orders")
public class Order {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String item;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id")
    @JsonBackReference
    private Customer customer;
    // getters/setters
}
```

**Controller:**

```java
@PostMapping("/customers")
public Customer create(@RequestBody Customer c) {
    return customerRepository.save(c);   // cascade saves orders
}
```

**Request:**

```json
{ "name": "Ali", "orders": [ { "item": "Book" }, { "item": "Pen" } ] }
```

Jackson sets `order.customer` on both orders. Hibernate then sees the owning side populated, writes `customer_id` for each, and the foreign keys are saved. Without `@JsonBackReference`, `order.customer` would be `null` and `customer_id` would be saved as `NULL`. This is the real practical benefit, and it connects to what you learned earlier: **only the owning side writes the FK**.

## 5. Naming links: the `value` parameter

The name matters because Jackson **matches pairs by name, within the child type**. If a class has more than one parent/child pair, give each a unique name:

```java
// Customer
@JsonManagedReference("customer-orders")
private List<Order> orders;

@JsonManagedReference("customer-addresses")
private List<Address> addresses;

// Order
@JsonBackReference("customer-orders")
private Customer customer;

// Address
@JsonBackReference("customer-addresses")
private Customer customer;
```

For **multi-level chains** (`Customer` → `Order` → `OrderItem`), naming each link explicitly is the safe habit. A class like `Order` is simultaneously a child (back reference to `Customer`) and a parent (managed reference to `OrderItem`), and distinct names avoid any ambiguity.

## 6. Rules and failure modes

|Mistake|What you see|
|---|---|
|Managed with no matching back reference|`Cannot handle managed/back reference 'defaultReference': no back reference property found from type ...` (fails when the deserializer is built)|
|Back reference type isn't compatible with the parent type|`back reference type (...) not compatible with managed type (...)`|
|Back reference on a `List<Customer>`|Not supported; the back side must be a single object|
|Annotation on a constructor parameter|Not supported; use field or setter injection for the back side|
|Names don't match (`"a"` vs `"b"`)|Same "no back reference" error|
|Only back reference present, no managed|Back field silently disappears from JSON, with no auto-linking|

## 7. Edge cases and gotchas

**1. Direction is fixed.** `GET /orders/10` will never contain `customer`. If you need the customer's id in that response, annotate with `@JsonProperty` on a getter you add, or use a DTO:

```java
@JsonProperty("customerId")
public Long getCustomerId() { return customer != null ? customer.getId() : null; }
```

**2. Linking happens only when the child arrives inside the parent JSON.** `POST /orders` with a standalone `Order` leaves `customer` as `null`, because Jackson has no parent to inject. You must set it yourself (typically by loading the customer from a `customerId` in the request).

**3. The back field is never read from JSON.** If a client sends `"customer": {...}` inside an order, it is ignored. This is a safety feature, since a client can't point a child at a different parent through the nested JSON.

**4. `PUT`/update behavior.** If a client sends `Customer` with a **new** `orders` list, Jackson links the new children, but Hibernate may complain about replacing a managed collection (`A collection with cascade="all-delete-orphan" was no longer referenced`). The usual fix is to mutate the existing collection instead of replacing it. This is another reason to avoid binding JSON directly to entities for updates.

**5. Lazy loading.** `orders` is lazy by default. If the persistence session is closed when Jackson reaches the managed field, you get `LazyInitializationException`. Spring Boot's `open-in-view` (on by default) hides this during controller serialization, but it can mask N+1 query problems.

**6. Hibernate proxies.** A lazily loaded `Customer` is a proxy subclass with extra fields (`hibernateLazyInitializer`). If you serialize it, Jackson may fail on those fields. That is separate from back references, but it often appears together with them; the `jackson-datatype-hibernate` module handles it.

**7. Sibling entities sharing a child.** If `Order` can belong to a `Customer` **and** a `Shipment`, you need two back references with different names, and Jackson can only fill the one whose parent actually contains the child in the JSON.

**8. It doesn't touch the database mapping.** `mappedBy`, `@JoinColumn`, and cascade are unaffected. This is a pure JSON-layer rule.

## 9. Comparison with the alternatives

|Approach|Output from the parent|Output from the child|Auto back-link on input|
|---|---|---|---|
|Managed/Back pair|Children included|**No** parent|**Yes**|
|`@JsonIgnore` on child's parent field|Children included|No parent|No (also blocks input)|
|`@JsonIgnoreProperties("orders")` on child's parent field|Children included|Parent included (without its children)|No|
|`@JsonIdentityReference(alwaysAsId = true)`|Children included|Parent as id only|No|
|DTOs|You decide|You decide|You decide|

Managed/Back is the only annotation approach that gives you **automatic back-linking on input**. That is its distinguishing feature, and the main reason to choose it over `@JsonIgnore`.

## 10. Quick test you can run

```java
ObjectMapper mapper = new ObjectMapper();

Customer c = mapper.readValue("""
    {"name":"Ali","orders":[{"item":"Book"}]}
    """, Customer.class);

System.out.println(c.getOrders().get(0).getCustomer() == c);   // true
System.out.println(mapper.writeValueAsString(c));
// {"id":null,"name":"Ali","orders":[{"id":null,"item":"Book"}]}
```

The `== c` check shows the back reference is the same instance. The output JSON confirms `customer` is omitted from each order.

## 11. Summary of the mental model

- **Managed** = "I'm the parent; write me, and fix my children's pointers after reading."
- **Back** = "I'm the child's link to the parent; never write me, Jackson fills me."
- Pairs match **by name**, resolved **when the deserializer is built**.
- The cycle is removed **structurally** at serializer-build time, not detected at runtime.
- Use it for quick, nested-POST-friendly APIs. Move to DTOs when your API shape needs to differ from your tables.




[[Spring Framework]]