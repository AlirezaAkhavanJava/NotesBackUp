

**Lombok** is a library that writes boring Java code (getters, setters, constructors, `toString`) for you while your project compiles. You add a small annotation, and the methods appear in the compiled class. In this lesson, you will use it on three kinds of classes (entities, DTOs, and services), and you will learn the part that matters most: **choosing exactly which fields get which methods**, so that a field like `id` can never be changed by accident.

This lesson also covers **validation**. You will learn which annotations to put on your DTOs, how to write messages that help a real person, and how to send those messages back as clean JSON. By the end, you will build one complete feature where the entity, the DTOs, and the mapper each guard a different door, so a client cannot sneak in a value you never meant to accept.

---

## 1. How Lombok works

Lombok is an **annotation processor**, the same kind of tool as MapStruct. During compilation it edits your class and adds the methods. Your source file stays short, and the `.class` file contains the real methods.

```
Product.java:   @Getter class Product { private String name; }
                         │ compile (Lombok runs)
                         ▼
Product.class:  getName() exists
```

You can prove this with `javap -p Product.class` in a terminal. It lists the methods that exist in the compiled class. Your IDE needs the Lombok plugin (IntelliJ includes it) so it knows the methods will exist. You already set up the processor order in the MapStruct lesson: Lombok first, then the binding, then MapStruct.

### The annotations you will actually use

|Annotation|What it generates|Entity|DTO class|Service|
|---|---|---|---|---|
|`@Getter`|getters|Yes|Yes||
|`@Setter`|setters|Selectively|Yes||
|`@NoArgsConstructor`|empty constructor|Yes (`PROTECTED`)|If a library needs it||
|`@AllArgsConstructor`|constructor with every field|**No**|Sometimes||
|`@RequiredArgsConstructor`|constructor for `final` / `@NonNull` fields|||**Yes** (injection)|
|`@Builder`|a builder (`Product.builder().name("x").build()`)|On a constructor|Yes||
|`@Value`|immutable class (final fields, getters, `equals`, `toString`)|**No**|Yes (if not a record)||
|`@ToString`|`toString()`|Only with explicit includes|Yes||
|`@EqualsAndHashCode`|`equals`, `hashCode`|**No**|Sometimes||
|`@Data`|getters, setters, `equals`, `hashCode`, `toString` together|**No**|Rarely||
|`@NonNull`|a null check that throws `NullPointerException`|Yes, on constructor parameters|||
|`@Slf4j`|a `log` field|||Yes|

Remember the two kinds of `null` check. Lombok's `@NonNull` protects your **Java code** (a constructor argument). Bean Validation's `@NotNull` protects your **incoming data** (a JSON body). They do different jobs.

### A safety net: `lombok.config`

Put this file in your project root. It can forbid the risky annotations for the whole team.

```properties
config.stopBubbling = true
lombok.addLombokGeneratedAnnotation = true
lombok.data.flagUsage = error
lombok.allArgsConstructor.flagUsage = warning
```

- `lombok.data.flagUsage = error` makes the build **fail** if anyone writes `@Data`. It is a cheap way to enforce the rule.
- `lombok.addLombokGeneratedAnnotation = true` marks generated methods, so test-coverage tools ignore them.

---

## 2. Choosing which fields get what

This is the heart of your question. Lombok lets you decide **per class** and then override **per field**. There are two strategies.

### Strategy A: opt-in (safest)

Put **no** `@Setter` on the class. Add it only to fields that are allowed to change.

```java
@Getter
public class Product {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;                 // no setter

    @Column(nullable = false, updatable = false, length = 20)
    private String sku;              // no setter, fixed after creation

    @Setter
    private String name;             // setter allowed

    @Setter
    private BigDecimal price;        // setter allowed
}
```

If you add a new field later and forget about it, it stays **read-only**. That is the safe default.

### Strategy B: opt-out

Put `@Setter` on the class, then switch it off for chosen fields with `AccessLevel.NONE`.

```java
@Getter
@Setter
public class Product {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Setter(AccessLevel.NONE)
    private Long id;

    @Version
    @Setter(AccessLevel.NONE)
    private Long version;

    private String name;
}
```

It is shorter, but a new field gets a setter automatically, and you must remember to switch it off.

||Strategy A (opt-in)|Strategy B (opt-out)|
|---|---|---|
|Default for a new field|read-only|writable|
|Risk|You may forget a needed setter (you notice quickly, it won't compile)|You may forget to block a dangerous one (you notice late, or never)|
|Best for|Entities|Simple DTO classes|

### The `AccessLevel` options

|Level|Meaning|
|---|---|
|`PUBLIC`|Anyone can call it (default)|
|`PROTECTED`|Only subclasses and the same package|
|`PACKAGE`|Only the same package|
|`PRIVATE`|Only the class itself|
|`NONE`|The method is **not generated at all**|

### Include and exclude for the other methods

The same idea works for `toString`, `equals`, and constructors:

```java
@ToString(onlyExplicitlyIncluded = true)     // opt-in: print only what I mark
public class Product {

    @ToString.Include
    private Long id;

    @ToString.Include
    private String name;

    private Category category;               // not printed
}
```

```java
@ToString                                    // opt-out: print everything except...
public class ProductDto {
    private String name;

    @ToString.Exclude
    private String internalNote;
}
```

|Annotation on a field|Effect|
|---|---|
|`@Setter(AccessLevel.NONE)`|no setter|
|`@Getter(AccessLevel.NONE)`|no getter|
|`@ToString.Exclude` / `@ToString.Include`|leave out of / put in `toString`|
|`@EqualsAndHashCode.Exclude` / `.Include`|leave out of / put in `equals` and `hashCode`|
|`@NonNull`|included in `@RequiredArgsConstructor` and null-checked|

### A builder that cannot touch `id`

If you put `@Builder` on the **class**, the builder includes every field, including `id`. Put it on the **constructor** instead, and the builder contains only the constructor's parameters.

```java
@Builder
public Product(@NonNull String sku, @NonNull String name,
               @NonNull BigDecimal price, @NonNull Category category) {
    this.sku = sku;
    this.name = name;
    this.price = price;
    this.category = category;
}
```

- `id`, `version`, and `createdAt` are not parameters, so the builder has no `.id(...)` method.
- `@NonNull` on each parameter makes Lombok add a null check and a clear message, such as `sku is marked non-null but is null`.

---

## 3. The entity, with Lombok

```java
@Entity
@Table(name = "products")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@ToString(onlyExplicitlyIncluded = true)
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @ToString.Include
    private Long id;

    @Column(nullable = false, updatable = false, unique = true, length = 20)
    @ToString.Include
    private String sku;

    @Setter
    @Column(nullable = false, length = 120)
    @ToString.Include
    private String name;

    @Setter
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "category_id")
    private Category category;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @Version
    private Long version;

    @Builder
    public Product(@NonNull String sku, @NonNull String name,
                   @NonNull BigDecimal price, @NonNull Category category) {
        this.sku = sku;
        this.name = name;
        this.price = price;
        this.category = category;
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
```

Here is what each field can do:

|Field|Getter|Setter|Why|
|---|---|---|---|
|`id`|yes|**no**|the database owns it|
|`sku`|yes|**no**, and `updatable = false`|fixed after creation|
|`name`|yes|yes|editable|
|`price`|yes|yes|editable|
|`category`|yes|no (add a `moveTo` method if needed)|changes are deliberate|
|`createdAt`|yes|**no**|set once by `@PrePersist`|
|`version`|yes|**no**|Hibernate owns it|

Notice the double protection on `sku` and `createdAt`: no Java setter **and** `updatable = false` on the column. Even if some code reached the field through another route, Hibernate would never write a changed value to the `UPDATE`.

(For `equals` and `hashCode`, write them by hand as shown in the previous lesson.)

---

## 4. DTOs and validation annotations

DTOs are where validation lives. Use **records**, which need no Lombok at all.

```java
public record ProductCreateRequest(

        @NotBlank(message = "{product.sku.required}")
        @Pattern(regexp = "^[A-Z0-9-]{4,20}$", message = "{product.sku.pattern}")
        String sku,

        @NotBlank(message = "{product.name.required}")
        @Size(min = 2, max = 120, message = "{product.name.size}")
        String name,

        @NotNull(message = "{product.price.required}")
        @Positive(message = "{product.price.positive}")
        @Digits(integer = 8, fraction = 2, message = "{product.price.digits}")
        BigDecimal price,

        @NotNull(message = "{product.category.required}")
        Long categoryId
) {}

public record ProductUpdateRequest(

        @NotBlank(message = "{product.name.required}")
        @Size(min = 2, max = 120, message = "{product.name.size}")
        String name,

        @NotNull(message = "{product.price.required}")
        @Positive(message = "{product.price.positive}")
        @Digits(integer = 8, fraction = 2, message = "{product.price.digits}")
        BigDecimal price
) {}

public record ProductResponse(Long id, String sku, String name, BigDecimal price, String categoryName) {}
```

Look at the second door. `ProductUpdateRequest` has **no `sku` and no `id`**. A client cannot change them through this endpoint because there is nowhere in the object for them to go.

### The validation annotations

|Annotation|Checks|Works on|
|---|---|---|
|`@NotNull`|value is not `null` (empty is fine)|any type|
|`@NotEmpty`|not `null` and not empty|String, collections, maps|
|`@NotBlank`|not `null` and has a visible character|String only|
|`@Size(min, max)`|length or number of elements|String, collections|
|`@Min` / `@Max`|whole-number bounds|integers, `BigDecimal`|
|`@Positive` / `@PositiveOrZero`|sign of a number|numbers|
|`@DecimalMin` / `@DecimalMax`|bounds written as text, like `"0.01"`|`BigDecimal`, numbers|
|`@Digits(integer, fraction)`|number of digits|numbers|
|`@Email`|email shape (loose, accepts `a@b`)|String|
|`@Pattern(regexp)`|matches a regular expression|String|
|`@Past`, `@Future`, `@PastOrPresent`|date compared with now|dates, `Instant`|
|`@AssertTrue` / `@AssertFalse`|boolean must be true / false|boolean|
|`@Valid`|validate the **inside** of a nested object|objects, collections|

> **An important surprise.** Most constraints treat `null` as **valid**. `@Size`, `@Positive`, `@Pattern`, and `@Email` all pass when the value is missing. That is why the price above has `@NotNull` **and** `@Positive`. Always add `@NotNull` or `@NotBlank` when the field is required.

### Nested objects and lists

```java
public record OrderCreateRequest(

        @NotNull(message = "Customer is required")
        Long customerId,

        @NotEmpty(message = "An order needs at least one item")
        List<@Valid OrderItemRequest> items
) {}

public record OrderItemRequest(

        @NotNull(message = "Product is required")
        Long productId,

        @NotNull(message = "Quantity is required")
        @Min(value = 1, message = "Quantity must be at least {value}")
        @Max(value = 99, message = "Quantity cannot be more than {value}")
        Integer quantity
) {}
```

`List<@Valid OrderItemRequest>` tells the validator to check every item. Without `@Valid`, it only checks the list itself, and bad items pass through. The error field then looks like `items[1].quantity`, so you know exactly which item failed.

### Rules involving two fields

```java
public record PasswordChangeRequest(
        @NotBlank String newPassword,
        @NotBlank String confirmPassword
) {
    @JsonIgnore
    @AssertTrue(message = "Passwords do not match")
    public boolean isPasswordConfirmed() {
        return newPassword == null || newPassword.equals(confirmPassword);
    }
}
```

`@AssertTrue` on an `isXxx()` method becomes a rule about the whole object. The check returns `true` when the password is `null`, so the user sees only the "required" message and not two errors at once. `@JsonIgnore` keeps this helper out of JSON.

### Where to validate

|Place|Tool|Purpose|
|---|---|---|
|**Request DTO**|Bean Validation annotations + `@Valid`|Friendly, field-by-field messages to the client|
|**Entity**|`@Column(nullable = false, length = ...)`|Database schema and last-line safety|
|**Service**|Business checks (`existsBySku`)|Rules that need the database|
|**Database**|`unique`, foreign keys|The final guarantee|

---

## 5. Writing good messages

You have three ways to write a message. Each one is better for bigger projects.

**Way 1: inline text.** Fine for quick work.

```java
@Size(min = 2, max = 120, message = "Name must be between 2 and 120 characters")
```

**Way 2: placeholders inside the message.** The numbers come from the annotation itself, so the message never goes out of date.

```java
@Size(min = 2, max = 120, message = "Name must be between {min} and {max} characters")
@Min(value = 1, message = "Quantity must be at least {value}")
```

|Annotation|Placeholders you can use|
|---|---|
|`@Size`|`{min}`, `{max}`|
|`@Min`, `@Max`, `@DecimalMin`|`{value}`|
|`@Digits`|`{integer}`, `{fraction}`|
|`@Pattern`|`{regexp}` (avoid showing it to users)|
|Any|`${validatedValue}` shows what the user typed. **Never use it for passwords or other secrets.**|

**Way 3: a message file (best).** Put the text in `src/main/resources/ValidationMessages.properties` and refer to it with `{key}`.

```properties
product.sku.required=SKU is required
product.sku.pattern=SKU must be 4 to 20 characters: capital letters, digits or dashes
product.name.required=Product name is required
product.name.size=Name must be between {min} and {max} characters
product.price.required=Price is required
product.price.positive=Price must be greater than zero
product.price.digits=Price can have up to {integer} digits and {fraction} decimals
product.category.required=Please choose a category
```

Curly braces in `message = "{product.sku.required}"` mean "look this up in the file." The benefits are one place to edit every message, consistent wording, and easy **translation**. Add `ValidationMessages_fr.properties` (or any language code) and the matching language is used, based on the request's language header.

If you already use Spring's `messages.properties` for the rest of the app, you can make validation read from it too:

```java
@Bean
public LocalValidatorFactoryBean validator(MessageSource messageSource) {
    LocalValidatorFactoryBean bean = new LocalValidatorFactoryBean();
    bean.setValidationMessageSource(messageSource);
    return bean;
}
```

### What makes a message good

|Do|Avoid|
|---|---|
|Say what to do: "Price must be greater than zero"|"Invalid value"|
|Use the same tone everywhere|Mixing "must", "please", and "required!!"|
|Describe the rule, not the code|Showing regexes or class names|
|Keep it short and specific to one field|Long paragraphs|
|Keep secrets out|Echoing a rejected password|

---

## 6. Sending the messages back to the client

When `@Valid` fails, Spring throws an exception. One class can catch it and shape the answer for the whole app.

```java
public record FieldIssue(String field, String message, String code) {}

@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail handleValidation(MethodArgumentNotValidException ex) {
        ProblemDetail problem =
                ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Validation failed");
        problem.setTitle("Invalid request");

        List<FieldIssue> errors = ex.getBindingResult().getFieldErrors().stream()
                .map(e -> new FieldIssue(e.getField(), e.getDefaultMessage(), e.getCode()))
                .toList();

        problem.setProperty("errors", errors);
        return problem;
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ProblemDetail handleConflict(DataIntegrityViolationException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT,
                "That value already exists or breaks a data rule");
    }
}
```

Line by line:

- `ProblemDetail` is Spring's built-in class for the standard "problem details" error format (RFC 9457, earlier RFC 7807). It gives you `status`, `title`, `detail`, and `instance` for free.
- `getFieldErrors()` is the list of every failed field.
- `e.getDefaultMessage()` is your message, already resolved from the properties file.
- `e.getCode()` is the constraint name (`Size`, `Positive`). The code stays the same even when the message language changes, so a front end can use it for its own logic.
- We do **not** call `e.getRejectedValue()`, so a typed password is never sent back.
- The conflict handler hides database details such as constraint names and SQL.

The response a client sees:

```json
{
  "type": "about:blank",
  "title": "Invalid request",
  "status": 400,
  "detail": "Validation failed",
  "instance": "/api/products",
  "errors": [
    { "field": "name",  "message": "Name must be between 2 and 120 characters", "code": "Size" },
    { "field": "price", "message": "Price must be greater than zero",           "code": "Positive" }
  ]
}
```

### Other shapes you can choose

|Shape|Looks like|Good for|
|---|---|---|
|List of issues (above)|`[{field, message, code}]`|Most APIs, easy to loop over|
|Map of lists|`{"name": ["too short", "..."]}`|Showing every message under its input in a form|
|One text line|`"Name is required, Price is required"`|Quick tools, logs|

### Which exception means what

|Situation|Exception|
|---|---|
|`@Valid @RequestBody` fails|`MethodArgumentNotValidException`|
|Constraint on `@PathVariable` / `@RequestParam` (Spring 6.1+)|`HandlerMethodValidationException`|
|Same, with `@Validated` on the controller class|`ConstraintViolationException`|
|Broken JSON or an unknown field|`HttpMessageNotReadableException`|
|Unique key broken in the database|`DataIntegrityViolationException`|

---

## 7. The mapper

For an entity like this one, split the job in two:

- **Reading** (entity to response): let MapStruct do it.
- **Creating** (request to entity): use the constructor or builder in the service, so required fields and null checks run.
- **Updating**: MapStruct, but only for the fields you name.

```java
@Mapper(componentModel = "spring")
public interface ProductMapper {

    @Mapping(source = "category.name", target = "categoryName")
    ProductResponse toResponse(Product product);

    List<ProductResponse> toResponses(List<Product> products);

    @BeanMapping(ignoreByDefault = true)
    @Mapping(source = "name", target = "name")
    @Mapping(source = "price", target = "price")
    void updateEntity(ProductUpdateRequest request, @MappingTarget Product product);
}
```

`@BeanMapping(ignoreByDefault = true)` flips MapStruct into **opt-in** mode. It copies _only_ the fields you list with `@Mapping`. If someone adds a new field to the DTO or the entity later, it is not copied unless a person decides to. This is the same idea as Strategy A, applied to mapping.

And the matching service:

```java
@Service
@RequiredArgsConstructor
public class ProductService {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final ProductMapper mapper;

    @Transactional
    public ProductResponse create(ProductCreateRequest request) {
        if (productRepository.existsBySku(request.sku())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "SKU already exists");
        }
        Category category = categoryRepository.findById(request.categoryId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Category not found"));

        Product product = Product.builder()
                .sku(request.sku())
                .name(request.name())
                .price(request.price())
                .category(category)
                .build();

        return mapper.toResponse(productRepository.save(product));
    }

    @Transactional
    public ProductResponse update(Long id, ProductUpdateRequest request) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found"));
        mapper.updateEntity(request, product);
        return mapper.toResponse(product);
    }
}
```

`@RequiredArgsConstructor` creates the constructor for the three `final` fields, so Spring can inject them. The controller then uses `@Valid @RequestBody` on both request records.

**A gotcha to know:** MapStruct automatically notices Lombok builders. If you ever ask MapStruct to _create_ a `Product` and it finds `Product.builder()`, it may use the builder and leave out required values. That is another reason the entity creation stays in the service. If you need to turn it off, use `@Mapper(builder = @Builder(disableBuilder = true))`.

---

## 8. Four locks on `id`

Here is the whole point of the lesson. A field like `id` is protected at several layers, and each layer stops a different mistake.

|Lock|Where|What it stops|
|---|---|---|
|1. No setter|Entity (`@Getter` only, or `@Setter(AccessLevel.NONE)`)|Your own code calling `setId(...)`|
|2. Not in the DTO|`ProductCreateRequest`, `ProductUpdateRequest`|A client having somewhere to put an `id`|
|3. Not mapped|`@BeanMapping(ignoreByDefault = true)`|The mapper copying it by accident|
|4. Unknown fields rejected|`application.properties`|A client sending `"id": 99` that is silently ignored|

For the fourth lock, add this line:

```properties
spring.jackson.deserialization.fail-on-unknown-properties=true
```

Now a request body containing a field your record doesn't have gets a `400 Bad Request` instead of being quietly dropped. Handle it so the message is friendly:

```java
@ExceptionHandler(HttpMessageNotReadableException.class)
public ProblemDetail handleUnreadable(HttpMessageNotReadableException ex) {
    String detail = "Malformed JSON request";
    if (ex.getCause() instanceof UnrecognizedPropertyException unknown) {
        detail = "Unknown field '" + unknown.getPropertyName() + "'";
    }
    return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, detail);
}
```

The imports shown here are for Jackson 2 (used by Spring Boot 3.x). If your project uses Jackson 3 (Spring Boot 4), the package names start with `tools.jackson`, so let your IDE suggest the right import. Also check the default value of this property for your version, since it is the setting that matters.

A fifth, quiet lock sits in the database: `updatable = false` on `sku` and `createdAt`, plus `@Version` for safe concurrent edits.

---

## Common mistakes

|Mistake|What goes wrong|Fix|
|---|---|---|
|`@Data` on an entity|Risky `equals`/`hashCode`, loops in `toString`, a setter on `id`|Specific annotations, plus `lombok.data.flagUsage = error`|
|`@Builder` on the entity class|Builder exposes `id` and `version`|Put `@Builder` on the constructor|
|`@AllArgsConstructor` on an entity|Lets anyone pass `id`|Write the business constructor|
|Forgetting `@Valid`|Annotations never run|`@Valid @RequestBody`|
|Only `@Size` or `@Positive` on a required field|`null` passes|Add `@NotNull` / `@NotBlank`|
|`@NotBlank` on a number|Not supported, throws an error|`@NotNull` for non-text|
|`List<Item>` without `@Valid` inside|Bad items pass|`List<@Valid Item>`|
|`${validatedValue}` on a password|Secret echoed back|Never use it there|
|Returning `getRejectedValue()`|Secret echoed back|Send only message and code|
|Validation rules on `LoginRequest`|Old users locked out|`@NotBlank` only|
|Same DTO for create and update|Fields allowed where they should not be|Separate request records|
|Letting MapStruct create entities with required fields|Missing values or builder surprises|Create in the service|

---

## A related concept: records versus Lombok for DTOs

Before Java 16, people used Lombok's `@Value` (or `@Data`) to make small data classes. A **record** now does the same in one line: `public record ProductUpdateRequest(String name, BigDecimal price) {}`. It gives you an all-args constructor, accessors, `equals`, `hashCode`, and `toString`, and its fields are final. For DTOs, prefer records and keep Lombok for entities and services. Use a Lombok-based DTO class only when you need something a record can't do, such as `@Builder` with defaults or `@Setter` for a library that requires setters.

---





[[Spring Framework]]