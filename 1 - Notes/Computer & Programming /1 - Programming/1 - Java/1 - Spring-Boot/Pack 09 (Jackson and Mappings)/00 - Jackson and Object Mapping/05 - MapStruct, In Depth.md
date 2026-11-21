

**MapStruct** is a Java library that writes your mapping code for you. You describe the conversion in an _interface_ (for example, "turn a `Product` into a `ProductResponse`"), and MapStruct generates a normal Java class that does the copying, field by field. It does this while your project **compiles**, not while it runs.

That one fact explains most of its strengths. The generated code is plain getter and setter calls, so it is very fast. It is also visible, because you can open the generated file and read it. And mistakes show up as **compile errors** instead of surprises in production. In this lesson you will go from a simple mapper to the advanced features, using the `Product`, `Category`, and `User` classes from the earlier lessons.

---

## 1. How it works under the hood

MapStruct is an **annotation processor**. When you run `mvn compile`, the Java compiler hands your `@Mapper` interfaces to MapStruct, and MapStruct writes the implementation classes.

```
You write:               ProductMapper (interface, with @Mapper)
                              │  compile
                              ▼
MapStruct generates:     ProductMapperImpl (class, with @Component)
                              │
Spring injects it:       private final ProductMapper mapper;
```

You will find the generated file at `target/generated-sources/annotations/.../ProductMapperImpl.java`. Open it whenever you wonder "what did MapStruct actually do?" It is the best debugging tool you have.

---

## 2. Setup with Spring Boot and Lombok

You need the library and the processor. If you also use Lombok (you do), the **order of processors matters**: Lombok must run first so MapStruct can see the getters and setters it creates.

```xml
<properties>
    <org.mapstruct.version>1.6.3</org.mapstruct.version>
</properties>

<dependencies>
    <dependency>
        <groupId>org.mapstruct</groupId>
        <artifactId>mapstruct</artifactId>
        <version>${org.mapstruct.version}</version>
    </dependency>
</dependencies>

<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-compiler-plugin</artifactId>
            <configuration>
                <annotationProcessorPaths>
                    <path>
                        <groupId>org.projectlombok</groupId>
                        <artifactId>lombok</artifactId>
                        <version>${lombok.version}</version>
                    </path>
                    <path>
                        <groupId>org.projectlombok</groupId>
                        <artifactId>lombok-mapstruct-binding</artifactId>
                        <version>0.2.0</version>
                    </path>
                    <path>
                        <groupId>org.mapstruct</groupId>
                        <artifactId>mapstruct-processor</artifactId>
                        <version>${org.mapstruct.version}</version>
                    </path>
                </annotationProcessorPaths>
            </configuration>
        </plugin>
    </plugins>
</build>
```

- `mapstruct` is the annotations you use in your code.
- `mapstruct-processor` is the generator. It only runs at compile time.
- `lombok-mapstruct-binding` is a tiny bridge that makes Lombok and MapStruct cooperate.
- Check the latest 1.6.x version on the MapStruct site, since newer patch releases may exist.

---

## 3. Your first mapper

```java
@Mapper(componentModel = "spring")
public interface ProductMapper {

    ProductResponse toResponse(Product product);
}
```

```java
public record ProductResponse(Long id, String name, BigDecimal price) {}
```

Here is what MapStruct generates (shortened):

```java
@Component
public class ProductMapperImpl implements ProductMapper {

    @Override
    public ProductResponse toResponse(Product product) {
        if (product == null) {
            return null;
        }
        Long id = null;
        String name = null;
        BigDecimal price = null;

        id = product.getId();
        name = product.getName();
        price = product.getPrice();

        return new ProductResponse(id, name, price);
    }
}
```

Walking through it:

- `componentModel = "spring"` adds `@Component`, so Spring can inject the mapper like any bean.
- MapStruct matches fields **by name**: `id` to `id`, `name` to `name`, `price` to `price`.
- It is null-safe by default: a `null` product gives a `null` response.
- Because `ProductResponse` is a **record**, MapStruct calls its constructor. For classes with setters, it calls `new` plus setters. Both work.
- Fields that exist in `Product` but not in the response (like `costPrice`) are simply ignored. Fields in the _target_ with no source get a **warning**.

---

## 4. The `@Mapping` annotation: your main tool

Use `@Mapping` whenever names differ or you want special behavior.

|Attribute|What it does|Example|
|---|---|---|
|`source`|Where the value comes from|`source = "category.name"`|
|`target`|Which target field to fill|`target = "categoryName"`|
|`ignore`|Skip this target field|`ignore = true`|
|`constant`|Fixed value|`constant = "USER"`|
|`expression`|A snippet of Java|`expression = "java(Instant.now())"`|
|`defaultValue`|Used when the source is `null`|`defaultValue = "Unknown"`|
|`qualifiedByName`|Use a named custom method|`qualifiedByName = "fullName"`|
|`dateFormat` / `numberFormat`|Format when converting to text|`dateFormat = "yyyy-MM-dd"`|

### Example: flattening a nested object

```java
public record ProductResponse(Long id, String name, BigDecimal price, String categoryName) {}

@Mapper(componentModel = "spring")
public interface ProductMapper {

    @Mapping(source = "category.name", target = "categoryName")
    ProductResponse toResponse(Product product);
}
```

`source = "category.name"` walks `product.getCategory().getName()`. MapStruct generates a null-safe version, so if `category` is `null`, `categoryName` becomes `null` and nothing crashes.

### Example: creating an entity from a request

```java
@Mapping(target = "id", ignore = true)
@Mapping(target = "costPrice", ignore = true)
@Mapping(target = "createdAt", ignore = true)
@Mapping(target = "version", ignore = true)
@Mapping(target = "category", ignore = true)
Product toEntity(ProductCreateRequest request);
```

Every `ignore = true` says "I know this field exists, I'm leaving it alone on purpose." It keeps the compiler quiet, so a _real_ forgotten field stands out.

---

## 5. Many source parameters

A method can take more than one input. This solves the "request has a `categoryId` but the entity needs a `Category` object" problem from the first lesson, without hiding any database call inside the mapper.

```java
@Mapping(target = "id", ignore = true)
@Mapping(target = "name", source = "request.name")
@Mapping(target = "price", source = "request.price")
@Mapping(target = "category", source = "category")
@Mapping(target = "costPrice", ignore = true)
@Mapping(target = "createdAt", ignore = true)
@Mapping(target = "version", ignore = true)
Product toEntity(ProductCreateRequest request, Category category);
```

The service loads the `Category` and passes it in. The mapper stays a pure converter. When you have several sources, always write the parameter name (`request.name`), so it is clear where each value comes from.

---

## 6. Updating an existing object with `@MappingTarget`

For updates, you want to change the entity you already loaded, not create a new one.

```java
@Mapping(target = "id", ignore = true)
@Mapping(target = "category", ignore = true)
@Mapping(target = "costPrice", ignore = true)
@Mapping(target = "createdAt", ignore = true)
@Mapping(target = "version", ignore = true)
void updateEntity(ProductUpdateRequest request, @MappingTarget Product product);
```

`@MappingTarget` marks the object that gets modified. The generated method calls `product.setName(...)` and `product.setPrice(...)` on it.

### Partial updates (PATCH)

For a PATCH, fields the client left out arrive as `null`, and you don't want them to erase existing values:

```java
@BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
void patchEntity(ProductPatchRequest request, @MappingTarget Product product);
```

|Strategy|When the source value is `null`|
|---|---|
|`SET_TO_NULL` (default)|The target field is set to `null`|
|`IGNORE`|The target field keeps its current value|
|`SET_TO_DEFAULT`|The target gets a default (empty list, `""`, `0`)|

A limit to know about: with `IGNORE`, a client can no longer _clear_ a field by sending `null`. That is a design choice you make for your API.

---

## 7. Lists, sets, and pages

MapStruct reuses your single-object method for collections.

```java
ProductResponse toResponse(Product product);

List<ProductResponse> toResponses(List<Product> products);
```

`toResponses` loops over the list and calls `toResponse` for each item. You write only the signature. It also works for `Set`, `Map`, and arrays.

For Spring Data pages, use the page's own method instead:

```java
Page<ProductResponse> page = productRepository.findAll(pageable).map(mapper::toResponse);
```

---

## 8. Automatic type conversion

MapStruct converts many types on its own:

|From|To|Notes|
|---|---|---|
|`int` / `Integer`|`String`|and back|
|`BigDecimal`|`String`|use `numberFormat` for control|
|`LocalDate`, `Instant`|`String`|use `dateFormat`|
|`Enum`|`String`|uses the name|
|`int`|`long`, `double`|widening is automatic|
|Primitive|Wrapper|boxing is automatic|

```java
@Mapping(source = "releaseDate", target = "releaseDate", dateFormat = "dd/MM/yyyy")
@Mapping(source = "price", target = "priceText", numberFormat = "#,##0.00")
MovieResponse toResponse(Movie movie);
```

---

## 9. Custom logic with `@Named` and `default` methods

When a mapping needs real code, write a `default` method inside the interface and reference it by name.

```java
@Mapper(componentModel = "spring")
public interface PersonMapper {

    @Mapping(target = "fullName", source = "person", qualifiedByName = "joinName")
    PersonResponse toResponse(Person person);

    @Named("joinName")
    default String joinName(Person person) {
        return person.getFirstName() + " " + person.getLastName();
    }
}
```

- `source = "person"` passes the **whole object** to the custom method.
- `@Named("joinName")` plus `qualifiedByName` makes the match explicit. Without the name, MapStruct might use your method for _every_ String conversion, which causes odd behavior.
- A default method is regular Java, so you can use `if` statements, other classes, and anything else.

### A quick one-liner with `expression`

```java
@Mapping(target = "createdAt", expression = "java(java.time.Instant.now())")
```

Use `expression` only for tiny snippets. It is plain text inside a string, so the compiler can't help you much. Prefer a `default` method for anything bigger.

---

## 10. Composing mappers with `uses`

Large objects contain smaller ones. Let one mapper reuse another:

```java
@Mapper(componentModel = "spring")
public interface OrderItemMapper {
    OrderItemResponse toResponse(OrderItem item);
}

@Mapper(componentModel = "spring", uses = OrderItemMapper.class)
public interface OrderMapper {
    OrderResponse toResponse(Order order);   // has List<OrderItemResponse> items
}
```

When `OrderMapper` meets the `items` list, it sees that `OrderItemMapper` can convert one `OrderItem`, and it injects and calls that mapper for each element. You write no loop.

---

## 11. Enums with `@ValueMapping`

When two enums have different constants:

```java
public enum Role { USER, ADMIN, MANAGER }
public enum RoleDto { MEMBER, ADMIN }

@ValueMapping(source = "USER", target = "MEMBER")
@ValueMapping(source = "MANAGER", target = "ADMIN")
@ValueMapping(source = MappingConstants.ANY_REMAINING, target = "MEMBER")
RoleDto toDto(Role role);
```

Each line says "this source constant becomes that target constant." `ANY_REMAINING` catches everything you didn't list. Without it, an unlisted constant is a compile error, which is exactly the safety you want.

---

## 12. Hooks: `@BeforeMapping` and `@AfterMapping`

Run extra code around the generated mapping:

```java
@AfterMapping
default void normalize(@MappingTarget User user) {
    user.setUsername(user.getUsername().toLowerCase());
}
```

MapStruct calls this automatically after it fills a `User`. It's handy for clean-up, but don't hide big business rules here. Keep those in the service.

---

## 13. Reverse mappings

If the mapping works both ways, say so instead of writing it twice:

```java
@Mapping(source = "category.name", target = "categoryName")
ProductDto toDto(Product product);

@InheritInverseConfiguration
Product toEntity(ProductDto dto);
```

`@InheritInverseConfiguration` flips your `@Mapping` rules. Use it carefully with entities, because the reverse direction may need extra `ignore` lines (such as `id` and `version`). Often it is clearer to write the two directions separately, since _request_ DTOs and _response_ DTOs are usually different classes anyway.

---

## 14. Shared configuration for the whole project

Avoid repeating options on every mapper:

```java
@MapperConfig(
        componentModel = "spring",
        unmappedTargetPolicy = ReportingPolicy.ERROR,
        nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface CentralMapperConfig {}

@Mapper(config = CentralMapperConfig.class)
public interface ProductMapper { ... }
```

The most valuable line is `unmappedTargetPolicy = ReportingPolicy.ERROR`. If a target field has no source and no `ignore`, **compilation fails**. When you add a new field to a DTO and forget the mapper, the compiler tells you immediately.

|Policy|Effect|
|---|---|
|`WARN` (default)|Warning only, easy to miss|
|`ERROR`|Build fails, safest|
|`IGNORE`|Silent, risky|

---

## 15. Mappers that need other beans

Sometimes a mapper needs a Spring bean, for example the `PasswordEncoder`. Use an abstract class:

```java
@Mapper(componentModel = "spring")
public abstract class UserMapper {

    @Autowired
    protected PasswordEncoder passwordEncoder;

    @Mapping(target = "password", expression = "java(passwordEncoder.encode(request.password()))")
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "role", constant = "USER")
    public abstract User toEntity(RegisterRequest request);
}
```

This works, but remember the rule from the User lesson: hashing is a security decision, and the service is usually the better home for it. Treat this as a feature you _can_ use, not one you _should_ reach for.

---

## 16. Testing a mapper

```java
@SpringBootTest(classes = ProductMapperImpl.class)
class ProductMapperTest {

    @Autowired
    ProductMapper mapper;

    @Test
    void toResponse_flattensCategoryName() {
        Category category = new Category();
        category.setName("Books");
        Product product = new Product();
        product.setName("Clean Code");
        product.setPrice(new BigDecimal("39.90"));
        product.setCategory(category);

        ProductResponse response = mapper.toResponse(product);

        assertEquals("Clean Code", response.name());
        assertEquals("Books", response.categoryName());
    }
}
```

`@SpringBootTest(classes = ProductMapperImpl.class)` loads only the generated class, so the test is fast. Test the _tricky_ mappings: renamed fields, ignored fields, null handling, and custom methods.

---

## Common mistakes

|Mistake|What goes wrong|Fix|
|---|---|---|
|Lombok processor listed after MapStruct|MapStruct sees no getters or setters, fields come out empty|Order: Lombok, binding, MapStruct|
|Same field name with a sensitive value (`password`)|It is copied silently|`ignore = true`, set it in the service|
|Leaving unmapped warnings|A forgotten field goes unnoticed|`unmappedTargetPolicy = ERROR`|
|Mapping lazy relationships outside a transaction|`LazyInitializationException`|Call the mapper inside the `@Transactional` service|
|Bidirectional entities (`Order` to `Item` to `Order`)|Infinite recursion, `StackOverflowError`|Design DTOs without back-references|
|`expression` for long code|No compiler help, ugly strings|Use a `default` method with `@Named`|
|Using `@InheritInverseConfiguration` blindly|Ids or versions overwritten|Check the generated code|
|Putting database calls in a mapper|Hidden queries, N+1 problems|Pass loaded objects in as parameters|
|Never reading the generated class|Bugs stay a mystery|Open `target/generated-sources`|

---

## A related concept: ModelMapper

**ModelMapper** is another mapping library, but it works at **runtime** using reflection. You write almost no configuration (`modelMapper.map(product, ProductResponse.class)`), which feels quick at first. The trade-offs are that it is slower, and a wrong or ambiguous mapping only fails when that code actually runs. MapStruct's compile-time approach catches the same problems before you ever start the app, which is why it is the common choice for Spring Boot projects.

---





[[Spring Framework]]