

## The Big Mental Model: Jackson as a Translator

Imagine Jackson is a translator sitting between your Java objects and the JSON world.

```
   Java Object                 Jackson                JSON
  ┌─────────────┐           ┌─────────────┐        ┌─────────────┐
  │             │  Serialize│             │        │             │
  │  User.java  │ ─────────►│ObjectMapper │───────►│ {"name":..} │
  │             │           │             │        │             │
  │             │◄───────── │             │◄───────│             │
  └─────────────┘Deserialize└─────────────┘        └─────────────┘
```

- **Serialization** = Java to JSON (your API response).
- **Deserialization** = JSON to Java (your API request body).
- **Annotations** are the instructions you give the translator: “Call this field differently,” “Skip this field,” “Use this date format,” “Don’t get stuck in a loop.”

Now let’s go annotation by annotation.

---

## 1. `@JsonProperty`

**Definition:** Tells Jackson the exact JSON name for a Java field or method parameter.

**Parameters:**

| Parameter | Type | Default | Meaning |
|-----------|------|---------|---------|
| `value` | String | `""` | The JSON property name |
| `required` | boolean | `false` | Whether the property must be present |
| `access` | `Access` | `AUTO` | Read-only, write-only, or both |

**What it does:** Renames the field during both serialization and deserialization. It is the most fundamental annotation because Jackson cannot always guess the mapping between your Java field name and the JSON key.

**How to use it:**

```java
public class User {
    @JsonProperty("user_id")
    private Long id;

    @JsonProperty(value = "full_name", required = true)
    private String name;
}
```

**Example JSON:**

```json
{
  "user_id": 101,
  "full_name": "Ada Lovelace"
}
```

**Explanation:** Without `@JsonProperty`, Jackson would produce `"id"` and `"name"`. With it, the JSON keys become `"user_id"` and `"full_name"`. The `required = true` tells Jackson to throw an error if `full_name` is missing during deserialization.

**Rule:** If you put `@JsonProperty` on a constructor parameter and also use `@JsonCreator`, the name must match the JSON key. Also, field-level `@JsonProperty` takes precedence over getter/setter naming conventions.

**Related classes/annotations:**

- `@JsonAlias` (allows multiple JSON names for deserialization)
- `@JsonGetter` / `@JsonSetter` (rename only the getter or setter)
- `@JsonCreator` (often paired with `@JsonProperty` on constructor parameters)

**Mental model:** Think of `@JsonProperty` as a sticky note on a box that says “My real name is X.”

---

## 2. `@JsonIgnore`

**Definition:** Marks a field, getter, or setter to be completely ignored by Jackson.

**Parameters:** None (marker annotation).

**What it does:** The annotated property is excluded from both serialization and deserialization. This is your primary tool for hiding sensitive fields or breaking circular references.

**How to use it:**

```java
public class User {
    private String username;

    @JsonIgnore
    private String password;
}
```

**Example JSON output:**

```json
{
  "username": "ada"
}
```

**Explanation:** `password` never appears in JSON, even though it exists in the Java object.

**Rule:** `@JsonIgnore` on a field affects both serialization and deserialization. If you want to ignore only one direction, use `@JsonProperty(access = JsonProperty.Access.WRITE_ONLY)` or `READ_ONLY`.

**Related classes:**

- `@JsonIgnoreProperties` (class-level ignore)
- `@JsonIgnoreType` (ignore an entire type)
- `@JsonProperty.Access` (fine-grained control)

**Mental model:** A red “DO NOT TOUCH” sticker on a field.

---

## 3. `@JsonIgnoreProperties`

**Definition:** A class-level annotation that tells Jackson to ignore one or more properties globally.

**Parameters:**

| Parameter | Type | Meaning |
|-----------|------|---------|
| `value` | String[] | Names of properties to ignore |
| `ignoreUnknown` | boolean | If `true`, unknown JSON properties are ignored instead of throwing an error |

**What it does:** The most common use in Spring Data JPA is to suppress Hibernate proxy fields that Jackson cannot serialize.

**How to use it:**

```java
@Entity
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Department {
    @Id
    private Long id;
    private String name;
}
```

**Explanation:** Hibernate adds two internal fields to every entity for lazy loading. Without this annotation, Jackson tries to serialize them and blows up. This annotation tells Jackson: “For this class, pretend these fields do not exist.”

**Rule:** `ignoreUnknown = true` is extremely useful when your API receives JSON from external clients that may add extra fields. Without it, Jackson throws `UnrecognizedPropertyException`.

**Related:** `@JsonIgnore` (field-level), `spring.jackson.deserialization.fail-on-unknown-properties=false` (global setting).

**Mental model:** A bouncer at the door who has a list of names that are never allowed inside.

---

## 4. `@JsonFormat`

**Definition:** Controls the format of date, time, and number fields during serialization and deserialization.

**Parameters:**

| Parameter | Type | Meaning |
|-----------|------|---------|
| `pattern` | String | Date format pattern, e.g. `"yyyy-MM-dd HH:mm:ss"` |
| `timezone` | String | Timezone, e.g. `"UTC"`, `"Asia/Seoul"` |
| `shape` | `Shape` | `STRING`, `NUMBER`, `ARRAY`, etc. |
| `lenient` | boolean | Whether parsing should be lenient |

**What it does:** This is the annotation you will use most often with `LocalDateTime`, `LocalDate`, and `Date` fields in Spring Boot.

**How to use it:**

```java
public class Event {
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "UTC")
    private LocalDateTime startTime;
}
```

**Example JSON:**

```json
{
  "startTime": "2025-03-15 14:30:00"
}
```

**Explanation:** Without `@JsonFormat`, Jackson serializes `LocalDateTime` as an array or an ISO-8601 string depending on the module configuration. With this annotation, the output is exactly the pattern you specify.

**Rule:** `@JsonFormat` is from Jackson. Do not confuse it with `@DateTimeFormat`, which is a Spring annotation for binding request parameters (query strings, form data). Use `@JsonFormat` for JSON bodies and responses; use `@DateTimeFormat` for `@RequestParam` and `@PathVariable`.

**Related classes:**

- `@DateTimeFormat` (Spring, for request params)
- `JavaTimeModule` (required for `java.time` types in Jackson 2.x)
- `@JsonSerialize` / `@JsonDeserialize` (for fully custom date logic)

**Mental model:** A ruler and a date-stamp that say “Write dates exactly in this shape.”

---

## 5. `@JsonManagedReference` and `@JsonBackReference`

**Definition:** A pair of annotations that solve the infinite recursion problem in bidirectional JPA relationships.

**Parameters:**

| Parameter | Type | Meaning |
|-----------|------|---------|
| `value` | String | Optional logical name to pair the two sides |

**What it does:**

- `@JsonManagedReference` marks the **parent** side. It is serialized normally.
- `@JsonBackReference` marks the **child** side. It is omitted from serialization to break the loop.

**How to use it:**

```java
@Entity
public class User {
    @Id
    private Long id;

    @OneToMany(mappedBy = "user")
    @JsonManagedReference
    private List<Authority> authorities;
}

@Entity
public class Authority {
    @Id
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    @JsonBackReference
    private User user;
}
```

**Example JSON output:**

```json
{
  "id": 1,
  "authorities": [
    { "id": 10, "authority": "ROLE_USER" },
    { "id": 11, "authority": "ROLE_ADMIN" }
  ]
}
```

**Explanation:** Without these annotations, serializing a `User` triggers serialization of each `Authority`, which triggers serialization of its `User`, which triggers… you get `StackOverflowError`. `@JsonBackReference` tells Jackson: “When you reach the child, stop here. Do not go back to the parent.”

**Rule:** These two must be used as a pair. `@JsonBackReference` can only be placed on a single object reference, **not** on a collection, array, or map.

**Related:**

- `@JsonIdentityInfo` (alternative approach using object IDs)
- `@JsonIgnore` (simple but loses both directions)

**ASCII diagram:**

```
   User (Managed)                    Authority (Back)
  ┌───────────────┐                ┌───────────────┐
  │ id: 1         │  @OneToMany    │ id: 10        │
  │ authorities ──┼───────────────►│ authority     │
  │               │                │ user ────────┼──► @JsonBackReference
  └───────────────┘                └───────────────┘     (omitted in JSON)
       ▲
       │  serialized normally
       │
   JSON output includes authorities,
   but each authority does NOT include user.
```

**Mental model:** A parent holds a child’s hand. The child does not reach back and grab the parent’s hand during the JSON walk.

---

## 6. `@JsonView`

**Definition:** Defines different “views” of the same object so different endpoints can return different subsets of fields.

**Parameters:**

| Parameter | Type | Meaning |
|-----------|------|---------|
| `value` | Class<?>[] | One or more view classes |

**What it does:** You define marker interfaces (empty interfaces) as views. You annotate fields with the view they belong to. Then on the controller, you activate one view.

**How to use it:**

```java
public class User {
    public interface PublicView {}
    public interface InternalView extends PublicView {}

    @JsonView(PublicView.class)
    private String username;

    @JsonView(InternalView.class)
    private String email;
}

@RestController
public class UserController {

    @GetMapping("/user/public")
    @JsonView(User.PublicView.class)
    public User getPublicUser() {
        return new User("ada", "ada@example.com");
    }

    @GetMapping("/user/internal")
    @JsonView(User.InternalView.class)
    public User getInternalUser() {
        return new User("ada", "ada@example.com");
    }
}
```

**Example JSON (public):**

```json
{ "username": "ada" }
```

**Example JSON (internal):**

```json
{ "username": "ada", "email": "ada@example.com" }
```

**Explanation:** Views are hierarchical. If a view extends another, it includes all fields from the parent view. This is cleaner than creating separate DTOs for every variation.

**Rule:** You can specify only **one** `@JsonView` per controller method. If you need to combine multiple views, create a composite interface that extends all the views you need.

**Related:**

- `MappingJacksonValue` (for programmatic view activation)
- `@JsonFilter` (for fully dynamic filtering)

**Mental model:** Different lenses for the same camera. The public lens shows the blurry version; the internal lens shows everything.

---

## 7. `@JsonInclude`

**Definition:** Controls whether a property is included in the JSON output based on its value.

**Parameters:**

| Parameter | Type | Meaning |
|-----------|------|---------|
| `value` | `Include` | `ALWAYS`, `NON_NULL`, `NON_ABSENT`, `NON_EMPTY`, `NON_DEFAULT` |
| `content` | `Include` | Same options, but for the contents of a container |

**What it does:** The most common use is `NON_NULL` to omit null fields from the response, which keeps your JSON clean.

**How to use it:**

```java
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse {
    private String data;
    private String error;
    private List<String> warnings;
}
```

**Example output when `error` is null:**

```json
{
  "data": "success",
  "warnings": ["low memory"]
}
```

**Explanation:** `error` is completely omitted from the JSON because it is null.

**Rule:** Field-level `@JsonInclude` overrides class-level and global `ObjectMapper` settings. If you have a global `spring.jackson.default-property-inclusion=non_empty` and you put `@JsonInclude(NON_NULL)` on a field, that field will use `NON_NULL`, which is looser and may emit empty strings or empty collections.

**Related:**

- `spring.jackson.default-property-inclusion` (global Spring Boot property)
- `@JsonIncludeProperties` (the inverse: only include these)

**Mental model:** A packing rule: “If the box is empty, do not ship it.”

---

## 8. `@JsonSerialize` and `@JsonDeserialize`

**Definition:** These annotations attach custom serializer and deserializer classes to a field.

**Parameters:**

| Parameter | Type | Meaning |
|-----------|------|---------|
| `using` | Class<? extends JsonSerializer/Deserializer> | The custom handler class |
| `contentUsing` | Class<?> | For container contents |
| `keyUsing` | Class<?> | For map keys |

**What it does:** When Jackson’s built-in handling is not enough, you write your own `JsonSerializer` or `JsonDeserializer` and point to it with these annotations.

**How to use it:**

```java
public class Product {
    @JsonSerialize(using = MoneySerializer.class)
    @JsonDeserialize(using = MoneyDeserializer.class)
    private BigDecimal price;
}
```

**Example custom serializer:**

```java
public class MoneySerializer extends JsonSerializer<BigDecimal> {
    @Override
    public void serialize(BigDecimal value, JsonGenerator gen,
                          SerializerProvider provider) throws IOException {
        gen.writeString(value.setScale(2, RoundingMode.HALF_UP) + " USD");
    }
}
```

**Example JSON output:**

```json
{ "price": "19.99 USD" }
```

**Explanation:** The `BigDecimal` is stored as a plain number in Java but is rendered as a formatted currency string in JSON.

**Rule:** Custom serializers are powerful but should be used sparingly. Prefer `@JsonFormat` for simple date and number formatting.

**Related:**

- `JsonSerializer<T>` / `JsonDeserializer<T>` (the interfaces you implement)
- `SimpleModule` (registering serializers globally)
- `@JsonComponent` (Spring Boot way to register custom serializers as beans)

**Mental model:** Hiring a specialist translator for a specific word that the general translator cannot handle.

---

## 9. `@JsonCreator`

**Definition:** Marks a constructor or static factory method as the way Jackson should create an object from JSON.

**Parameters:**

| Parameter | Type | Meaning |
|-----------|------|---------|
| `mode` | `Mode` | `DEFAULT`, `DELEGATING`, `PROPERTIES`, `DISABLED` |

**What it does:** This is essential for immutable classes with `final` fields and no default constructor. Jackson cannot use setters, so it must use the constructor.

**How to use it:**

```java
public class User {
    private final Long id;
    private final String name;

    @JsonCreator
    public User(@JsonProperty("id") Long id,
                @JsonProperty("name") String name) {
        this.id = id;
        this.name = name;
    }
}
```

**Example JSON input:**

```json
{ "id": 1, "name": "Ada" }
```

**Explanation:** Jackson calls this constructor and passes the values from the JSON. Each parameter must have `@JsonProperty` so Jackson knows which JSON key maps to which parameter.

**Rule:** If you have a class with a single-argument constructor and no `@JsonProperty`, Jackson may treat it as a delegating creator. Use `mode = JsonCreator.Mode.PROPERTIES` to be explicit.

**Related:**

- `@JsonProperty` (required on constructor parameters)
- `ParameterNamesModule` (can reduce the need for explicit `@JsonProperty` if compiled with `-parameters`)

**Mental model:** Instead of building a house by adding furniture room by room (setters), you hand the architect a blueprint and they build the whole house at once (constructor).

---

## 10. `@JsonAlias`

**Definition:** Specifies alternative names that Jackson will accept during **deserialization only**.

**Parameters:**

| Parameter | Type | Meaning |
|-----------|------|---------|
| `value` | String[] | One or more alternative JSON names |

**What it does:** This is for backward compatibility. When an API changes a field name, you can accept both the old and new names without breaking existing clients.

**How to use it:**

```java
public class User {
    @JsonAlias({"user_name", "userName"})
    @JsonProperty("username")
    private String username;
}
```

**Explanation:** If the incoming JSON has `"user_name"`, `"userName"`, or `"username"`, all three will map to the `username` field. However, when serializing back to JSON, only `"username"` is used.

**Rule:** `@JsonAlias` does **not** affect serialization. It only affects deserialization.

**Related:** `@JsonProperty` (the primary name), `@JsonSetter` (alternative setter for a different name).

**Mental model:** A person who answers to a nickname and a formal name when you call them, but only signs their formal name on letters.

---

## 11. `@JsonGetter` and `@JsonSetter`

**Definition:** Rename a specific getter or setter method without affecting the field name.

**Parameters:**

| Parameter | Type | Meaning |
|-----------|------|---------|
| `value` | String | The JSON property name for this accessor |

**What it does:** Sometimes you have a computed property or you want the JSON name to differ from the field name only on one side.

**How to use it:**

```java
public class User {
    private String firstName;
    private String lastName;

    @JsonGetter("full_name")
    public String getFullName() {
        return firstName + " " + lastName;
    }
}
```

**Example JSON output:**

```json
{
  "full_name": "Ada Lovelace"
}
```

**Explanation:** `full_name` is a computed property. There is no `fullName` field. Jackson calls the getter and uses the name from `@JsonGetter`.

**Rule:** If you use `@JsonGetter` on a method, Jackson will not auto-detect the field name for that property. This is useful for read-only computed properties.

**Related:** `@JsonProperty` (can do the same with `access`), `@JsonAnyGetter` (for dynamic maps).

---

## 12. `@JsonAnyGetter` and `@JsonAnySetter`

**Definition:** These handle “catch-all” properties that do not map to a known field.

**Parameters:** None.

**What it does:**

- `@JsonAnyGetter` takes a `Map<String, Object>` and flattens it into the JSON object.
- `@JsonAnySetter` receives unknown JSON properties and stores them in a map.

**How to use it:**

```java
public class DynamicConfig {
    private Map<String, Object> extra = new HashMap<>();

    @JsonAnyGetter
    public Map<String, Object> getExtra() {
        return extra;
    }

    @JsonAnySetter
    public void setExtra(String key, Object value) {
        extra.put(key, value);
    }
}
```

**Example JSON:**

```json
{
  "timeout": 30,
  "retries": 3,
  "region": "us-east-1"
}
```

**Explanation:** `timeout`, `retries`, and `region` do not correspond to any field in `DynamicConfig`. They are stored in the `extra` map and serialized back out as if they were real fields.

**Rule:** You can have only one `@JsonAnyGetter` and one `@JsonAnySetter` per class.

**Mental model:** A junk drawer. Anything that does not have a designated place goes in the drawer, but it still appears in the final inventory.

---

## 13. `@JsonNaming`

**Definition:** A class-level annotation that applies a naming strategy to all fields.

**Parameters:**

| Parameter | Type | Meaning |
|-----------|------|---------|
| `value` | `PropertyNamingStrategy` | `SNAKE_CASE`, `KEBAB_CASE`, `LOWER_CAMEL_CASE`, etc. |

**What it does:** Instead of putting `@JsonProperty` on every field, you set one strategy for the whole class.

**How to use it:**

```java
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class UserProfile {
    private String firstName;
    private String lastName;
}
```

**Example JSON output:**

```json
{
  "first_name": "Ada",
  "last_name": "Lovelace"
}
```

**Explanation:** Every camelCase field is automatically converted to snake_case in JSON.

**Rule:** `@JsonProperty` on a specific field overrides the class-level naming strategy for that field.

**Related:**

- `spring.jackson.property-naming-strategy` (global Spring Boot setting)
- `PropertyNamingStrategies` (the available strategies)

**Mental model:** A company-wide dress code. Everyone follows the same style unless they have a special exception.

---

## 14. `@JsonUnwrapped`

**Definition:** Flattens a nested object’s properties into the parent JSON object.

**Parameters:**

| Parameter | Type | Meaning |
|-----------|------|---------|
| `prefix` | String | Optional prefix to add to unwrapped property names |
| `suffix` | String | Optional suffix |

**What it does:** This removes one level of nesting in the JSON.

**How to use it:**

```java
public class Order {
    private Long id;

    @JsonUnwrapped
    private Address address;
}

public class Address {
    private String street;
    private String city;
}
```

**Example JSON output:**

```json
{
  "id": 1,
  "street": "123 Main St",
  "city": "Boston"
}
```

**Explanation:** Without `@JsonUnwrapped`, the JSON would be `{ "id": 1, "address": { "street": "...", "city": "..." } }`. With it, the address fields are lifted to the top level.

**Rule:** `@JsonUnwrapped` does not work with custom serializers. Also, if there are name collisions between the parent and the unwrapped object, Jackson may throw an error.

**Related:** `@JsonNaming` (for prefix/suffix strategies).

---

## 15. `@JsonIdentityInfo`

**Definition:** An alternative way to handle circular references by assigning an object ID to each instance.

**Parameters:**

| Parameter | Type | Meaning |
|-----------|------|---------|
| `generator` | Class<? extends ObjectIdGenerator> | How to generate the ID |
| `property` | String | The JSON property name for the ID |
| `scope` | Class<?> | The class the ID applies to |

**What it does:** Instead of omitting the back-reference entirely (like `@JsonBackReference`), it serializes the reference as an ID. The first occurrence is a full object; subsequent occurrences are just the ID.

**How to use it:**

```java
@JsonIdentityInfo(
    generator = ObjectIdGenerators.PropertyGenerator.class,
    property = "id"
)
@Entity
public class User {
    @Id
    private Long id;

    @OneToMany(mappedBy = "user")
    private List<Authority> authorities;
}
```

**Example JSON output:**

```json
{
  "id": 1,
  "authorities": [
    { "id": 10, "user": 1 },
    { "id": 11, "user": 1 }
  ]
}
```

**Explanation:** The first time `User` is serialized, it is a full object. When `Authority` refers back to `User`, Jackson writes `"user": 1` instead of the full object.

**Rule:** This is a more advanced solution than `@JsonManagedReference`/`@JsonBackReference`. It is useful when you need to preserve the reference in the JSON, not just omit it.

**Related:**

- `@JsonIdentityReference` (forces a reference to always be an ID)
- `@JsonManagedReference` / `@JsonBackReference` (simpler alternative)

**Mental model:** A family reunion. The first time you meet someone, you get their full introduction. Every time after that, you just hear their name.

---

## 16. `@JsonTypeInfo` and `@JsonSubTypes`

**Definition:** These handle polymorphic serialization and deserialization. They tell Jackson how to include type information in JSON and how to map it back to the correct Java subclass.

**Parameters for `@JsonTypeInfo`:**

| Parameter | Type | Meaning |
|-----------|------|---------|
| `use` | `Id` | `NAME`, `CLASS`, `MINIMAL_CLASS`, `NONE` |
| `include` | `As` | `PROPERTY`, `WRAPPER_OBJECT`, `WRAPPER_ARRAY`, `EXTERNAL_PROPERTY` |
| `property` | String | The JSON property name for the type |
| `visible` | boolean | Whether the type property is also visible as a field |

**Parameters for `@JsonSubTypes`:**

| Parameter | Type | Meaning |
|-----------|------|---------|
| `value` | `Type[]` | Array of `@Type(value = Class, name = "name")` |

**What it does:** When you have a base class and multiple subclasses, Jackson needs to know which subclass to instantiate during deserialization. This annotation pair solves that.

**How to use it:**

```java
@JsonTypeInfo(
    use = JsonTypeInfo.Id.NAME,
    include = JsonTypeInfo.As.PROPERTY,
    property = "type"
)
@JsonSubTypes({
    @JsonSubTypes.Type(value = Dog.class, name = "dog"),
    @JsonSubTypes.Type(value = Cat.class, name = "cat")
})
public abstract class Animal {
    private String name;
}

public class Dog extends Animal {
    private String breed;
}

public class Cat extends Animal {
    private boolean indoor;
}
```

**Example JSON:**

```json
{
  "type": "dog",
  "name": "Rex",
  "breed": "German Shepherd"
}
```

**Explanation:** During deserialization, Jackson sees `"type": "dog"` and knows to create a `Dog` object.

**Rule:** The type name must be registered in `@JsonSubTypes`. If Jackson encounters an unknown type, it throws an error unless you specify a `defaultImpl`.

**Related:**

- `@JsonTypeName` (alternative way to name a subtype)
- `JsonTypeInfo.Id.DEDUCTION` (Jackson 2.12+, deduces type from fields)

**Mental model:** A package labeled “Animal” with a tag that says “I am a Dog” so the receiver knows how to open it.

---

## 17. `@JsonFilter`

**Definition:** Enables dynamic, programmatic filtering of properties at runtime.

**Parameters:**

| Parameter | Type | Meaning |
|-----------|------|---------|
| `value` | String | The filter ID |

**What it does:** You can include or exclude properties at runtime without changing the class. This is more flexible than `@JsonView` but more complex.

**How to use it:**

```java
@JsonFilter("userFilter")
public class User {
    private String username;
    private String email;
    private String ssn;
}
```

```java
SimpleFilterProvider filters = new SimpleFilterProvider()
    .addFilter("userFilter",
        SimpleBeanPropertyFilter.filterOutAllExcept("username", "email"));

ObjectMapper mapper = new ObjectMapper();
mapper.setFilterProvider(filters);
String json = mapper.writeValueAsString(user);
```

**Explanation:** At runtime, you decide which fields to include. The `userFilter` ID links the annotation to the filter provider.

**Rule:** `@JsonFilter` requires you to configure the `ObjectMapper` with a `FilterProvider`. In Spring Boot, you can use `MappingJacksonValue` to apply filters in controllers.

**Related:**

- `SimpleBeanPropertyFilter` (the filter implementation)
- `MappingJacksonValue` (Spring MVC wrapper for filters)

**Mental model:** A security guard who checks a list at the door and decides who gets in based on the current situation.

---

## 18. `@JsonRootName`

**Definition:** Wraps the entire JSON output in a root-level object with a specified name.

**Parameters:**

| Parameter | Type | Meaning |
|-----------|------|---------|
| `value` | String | The root name |
| `namespace` | String | Optional XML namespace |

**What it does:** By default, Jackson does not wrap the root object. This annotation adds a wrapper.

**How to use it:**

```java
@JsonRootName("user")
public class User {
    private String username;
}
```

**Example JSON output (with `SerializationFeature.WRAP_ROOT_VALUE` enabled):**

```json
{
  "user": {
    "username": "ada"
  }
}
```

**Rule:** `@JsonRootName` only takes effect if you enable `SerializationFeature.WRAP_ROOT_VALUE` on the `ObjectMapper`. In Spring Boot, you can set `spring.jackson.serialization.wrap-root-value=true`.

**Related:** `@JsonUnwrapped` (the opposite: removes wrapping).

---

## Quick Reference Table

| Annotation | Level | Main Purpose |
|------------|-------|--------------|
| `@JsonProperty` | Field/Param | Rename JSON key |
| `@JsonIgnore` | Field/Method | Skip entirely |
| `@JsonIgnoreProperties` | Class | Skip multiple, ignore unknown |
| `@JsonFormat` | Field | Date/number format |
| `@JsonManagedReference` / `@JsonBackReference` | Field | Break bidirectional loop |
| `@JsonView` | Field/Method | Subset by view |
| `@JsonInclude` | Class/Field | Omit null/empty |
| `@JsonSerialize` / `@JsonDeserialize` | Field | Custom handlers |
| `@JsonCreator` | Constructor | Immutable deserialization |
| `@JsonAlias` | Field | Accept alternative names |
| `@JsonGetter` / `@JsonSetter` | Method | Rename accessor |
| `@JsonAnyGetter` / `@JsonAnySetter` | Method | Catch-all map |
| `@JsonNaming` | Class | Global naming strategy |
| `@JsonUnwrapped` | Field | Flatten nested object |
| `@JsonIdentityInfo` | Class | Circular reference by ID |
| `@JsonTypeInfo` / `@JsonSubTypes` | Class | Polymorphism |
| `@JsonFilter` | Class | Runtime filtering |
| `@JsonRootName` | Class | Root wrapper |

---

## Final Rules to Remember

1. **Jackson annotations live in `com.fasterxml.jackson.annotation`.** The exceptions are `@JsonSerialize` and `@JsonDeserialize`, which live in `com.fasterxml.jackson.databind.annotation`.

2. **Field-level annotations override class-level annotations.** If you put `@JsonProperty` on a field, it wins over `@JsonNaming` on the class.

3. **`@JsonIgnore` beats `@JsonProperty`.** If you annotate a field with both, it is ignored.

4. **In Spring Data JPA, always handle bidirectional relationships.** Either use `@JsonManagedReference`/`@JsonBackReference`, `@JsonIdentityInfo`, or DTOs. Never let Jackson walk a raw bidirectional entity graph.

5. **`@JsonInclude(NON_NULL)` is not the same as `NON_EMPTY`.** `NON_NULL` omits nulls but keeps empty strings and empty collections. `NON_EMPTY` omits those too.

6. **`@JsonView` is the cleanest solution for “same object, different fields per endpoint.”** Use it before you create separate DTOs.

7. **`@JsonCreator` plus `@JsonProperty` is the standard pattern for immutable DTOs.** This is what you will see in modern Spring Boot code.





[[Spring Framework]]