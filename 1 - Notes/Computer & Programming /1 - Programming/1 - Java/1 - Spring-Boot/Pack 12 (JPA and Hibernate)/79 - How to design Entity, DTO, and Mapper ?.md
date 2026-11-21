

An **Entity** is a Java class that mirrors a database table. It belongs to your persistence layer, and JPA uses it to read and write rows. A **DTO** (Data Transfer Object) is a small, plain class that carries data across a boundary, usually between your API and its clients. A **mapper** is the piece of code that converts one into the other.

These are three separate jobs, and you design them separately. The entity answers "how do I store this?" The DTO answers "what does the outside world see and send?" The mapper is the translator between the two. When you keep them apart, you can change your database without breaking your API, and the other way around.

---

## 1. Designing the Entity

The entity is shaped by your database. Think in tables, columns, and relationships.

```java
@Entity
@Table(name = "products")
@Getter @Setter
@NoArgsConstructor
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @Column(name = "cost_price", nullable = false, precision = 10, scale = 2)
    private BigDecimal costPrice;          // internal, never shown to clients

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "category_id")
    private Category category;

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Version
    private Long version;
}
```

Walking through the important lines:

- `@NoArgsConstructor` is needed because JPA creates objects by calling an empty constructor, then filling the fields.
- `@GeneratedValue(IDENTITY)` lets the database create the id. You never set it yourself.
- `@Column(nullable = false, ...)` documents the rules for your schema. It also lets Hibernate generate matching DDL.
- `BigDecimal` is the right type for money. `double` gives rounding errors.
- `costPrice` is a field that exists in the database but must not leak. Remember it, because the DTO section depends on it.
- `@ManyToOne(fetch = LAZY)` means the category is only loaded when you touch it. This matters later in the mapper.
- `@Version` gives you optimistic locking, so two people editing the same row at once don't silently overwrite each other.

**Entity design rules to keep in mind:**

|Rule|Why|
|---|---|
|Don't use `@Data` on entities|It generates `equals`/`hashCode`/`toString` over all fields, which can trigger lazy loading and infinite loops on relationships|
|Keep entities free of API concerns|No `@JsonIgnore`, no validation tuned for one endpoint|
|Put real business rules inside the entity when they protect its own state|For example, `product.changePrice(newPrice)` can reject negative values|
|Prefer `LAZY` for relationships|`EAGER` quietly loads data you didn't ask for|

---

## 2. Designing the DTO

The DTO is shaped by your API. Think in what a client sends and what a client needs to see.

The first big idea is that **one entity usually needs several DTOs**. A request to create a product is not the same shape as a request to update one, and neither is the same as what you return.

Since Java 16, **records** are a great fit. They are immutable, short, and have no boilerplate.

```java
public record ProductCreateRequest(
        @NotBlank @Size(max = 120) String name,
        @NotNull @Positive BigDecimal price,
        @NotNull Long categoryId
) {}

public record ProductUpdateRequest(
        @NotBlank @Size(max = 120) String name,
        @NotNull @Positive BigDecimal price
) {}

public record ProductResponse(
        Long id,
        String name,
        BigDecimal price,
        String categoryName
) {}
```

Look at what each one leaves out, because that is the design:

|Field|Create request|Update request|Response|
|---|---|---|---|
|`id`|no (database makes it)|no (it's in the URL)|yes|
|`name`|yes|yes|yes|
|`price`|yes|yes|yes|
|`costPrice`|no|no|**no** (internal)|
|`category`|`categoryId` only|no (can't move category here)|`categoryName` only|
|`version`, `createdAt`|no|no|optional|

Notice three things:

1. **Requests carry validation annotations.** The DTO is where you reject bad input, before it ever reaches your entity.
2. **Relationships are flattened.** The request takes a `categoryId`. The response shows a `categoryName`. You never send a whole `Category` object back and forth.
3. **Sensitive and internal fields simply don't exist** in the DTO. This is much safer than hiding them with `@JsonIgnore`. A field that isn't there can't leak, and it can't be set by a client either. That second part protects you from _mass assignment_, where someone sends `"costPrice": 0` or `"role": "ADMIN"` in a JSON body and your code happily saves it.

---

## 3. Designing the Mapper

The mapper has one job: convert. It should hold no business logic and make no database calls.

### Option A: a manual mapper

For small projects, this is perfectly fine and very clear.

```java
@Component
public class ProductMapper {

    public Product toEntity(ProductCreateRequest request, Category category) {
        Product product = new Product();
        product.setName(request.name());
        product.setPrice(request.price());
        product.setCategory(category);
        return product;
    }

    public void updateEntity(Product product, ProductUpdateRequest request) {
        product.setName(request.name());
        product.setPrice(request.price());
    }

    public ProductResponse toResponse(Product product) {
        return new ProductResponse(
                product.getId(),
                product.getName(),
                product.getPrice(),
                product.getCategory().getName()
        );
    }
}
```

Line by line:

- `toEntity` takes the `Category` as a **parameter**. The mapper doesn't look it up, because that would mean a repository call inside a mapper. The service finds the category and hands it in.
- `updateEntity` returns `void` and changes the **existing** entity. Updating means "change the row that's already loaded", not "build a new object and save it". This keeps the `id` and `version` intact.
- `toResponse` reads `product.getCategory().getName()`. If the category is lazy, this triggers a query. Do the mapping while the transaction is still open, which means inside the service (see below).
- Nothing here ever touches `costPrice` on the way out.

### Option B: MapStruct (generated mapper)

When you have many entities, writing mappers by hand gets tiring. MapStruct generates the same kind of code at compile time, so it is fast and fully type-checked.

```java
@Mapper(componentModel = "spring")
public interface ProductMapper {

    @Mapping(source = "category.name", target = "categoryName")
    ProductResponse toResponse(Product product);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "category", ignore = true)
    @Mapping(target = "costPrice", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "version", ignore = true)
    Product toEntity(ProductCreateRequest request);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    @Mapping(target = "id", ignore = true)
    void updateEntity(@MappingTarget Product product, ProductUpdateRequest request);
}
```

- `componentModel = "spring"` makes the generated class a Spring bean, so you can inject it.
- Fields with the same name map automatically. You only write `@Mapping` where names differ or you want to skip something.
- `source = "category.name"` reaches into the nested object for you.
- `ignore = true` says "I know this target field exists, and I'm deliberately not filling it". It also silences compiler warnings, so you can see real mistakes.
- `@MappingTarget` marks the object to update in place.

### Where the mapper is called

The service layer is the right place. It has the transaction, so lazy relationships can load safely.

```java
@Service
@RequiredArgsConstructor
public class ProductService {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final ProductMapper mapper;

    @Transactional
    public ProductResponse create(ProductCreateRequest request) {
        Category category = categoryRepository.findById(request.categoryId())
                .orElseThrow(() -> new EntityNotFoundException("Category not found"));
        Product saved = productRepository.save(mapper.toEntity(request, category));
        return mapper.toResponse(saved);
    }

    @Transactional
    public ProductResponse update(Long id, ProductUpdateRequest request) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Product not found"));
        mapper.updateEntity(product, request);
        return mapper.toResponse(product);   // no save() needed, see note below
    }
}
```

On `update`: the product is a _managed_ entity inside the transaction. Hibernate notices the changes and writes them when the transaction commits. That is called dirty checking, so an explicit `save()` isn't required.

The controller then only speaks DTOs:

```java
@PostMapping
public ResponseEntity<ProductResponse> create(@Valid @RequestBody ProductCreateRequest request) {
    return ResponseEntity.status(HttpStatus.CREATED).body(productService.create(request));
}
```

The flow looks like this:

```
Client JSON → CreateRequest (validated) → Mapper → Entity → Repository → DB
DB → Entity → Mapper → Response → Client JSON
```

---

## 4. Common mistakes to avoid

|Mistake|What goes wrong|Fix|
|---|---|---|
|Returning entities straight from controllers|Leaks internal fields, couples API to schema|Always return a response DTO|
|Accepting entities as `@RequestBody`|Mass assignment, no per-endpoint validation|Use request DTOs|
|Mapping outside a transaction|`LazyInitializationException`|Map inside the `@Transactional` service method|
|Bidirectional relationships serialized to JSON|Infinite recursion|DTOs flatten to ids or small summaries|
|Mapping a list of entities with lazy fields|N+1 queries (one extra query per row)|Use `JOIN FETCH` or `@EntityGraph` in the repository|
|One DTO for everything|Fields that are required in one endpoint and forbidden in another|Separate create/update/response DTOs|
|Business logic in the mapper|Hidden rules, hard to test|Keep the mapper "dumb", put rules in the service or entity|
|Mapper doing repository lookups|Hidden database calls|Service loads related entities and passes them in|

## 5. A quick checklist

1. Start with the entity and design it for the database.
2. Ask what each endpoint receives and returns, then write one DTO per answer.
3. Leave out anything the client shouldn't see or set.
4. Write the mapper as a pure converter with no side effects.
5. Call the mapper from the service, inside the transaction.
6. Pick manual mappers for a handful of entities, MapStruct once the count grows.

---

## A related concept: projections

Sometimes you only need a few columns for a read-only view. Spring Data lets the repository return a DTO or interface directly, skipping the entity and mapper completely:

```java
@Query("select new com.example.dto.ProductResponse(p.id, p.name, p.price, p.category.name) from Product p")
List<ProductResponse> findAllResponses();
```

The database only fetches the four columns you asked for. This is great for list screens and reports. For writes, you still go through entity, DTO, and mapper.






[[Spring Framework]]