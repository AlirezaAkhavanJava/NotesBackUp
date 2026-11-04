

I'm assuming you meant `@JsonProperty` (from the Jackson library), since `@JaosnProperty` doesn't exist.

## 1. Core intuition

Spring Boot converts between **JSON** and **Java objects** using a library called **Jackson**. By default, Jackson matches JSON keys to Java property names exactly.

Think of Jackson as a translator between two languages. `@JsonProperty` is a dictionary entry that says: "when you see `first_name` in JSON, that means `firstName` in Java, and vice versa."

You need it when the names don't match, which happens often:

- The external API uses `snake_case` (`first_name`), but Java uses `camelCase` (`firstName`).
- The JSON key is not a valid Java identifier (`"user-id"`, `"@type"`).
- You want to hide your internal field name from the API contract.

## 2. Basic usage

Jackson comes with `spring-boot-starter-web`, so there's no extra dependency.

```java
import com.fasterxml.jackson.annotation.JsonProperty;

public class UserDto {

    @JsonProperty("first_name")
    private String firstName;

    @JsonProperty("last_name")
    private String lastName;

    private int age; // no annotation: JSON key is "age"

    // getters and setters (or Lombok @Getter/@Setter)
}
```

```java
@RestController
@RequestMapping("/users")
public class UserController {

    @PostMapping
    public UserDto create(@RequestBody UserDto user) {
        return user; // echoes it back
    }
}
```

Request:

```json
{ "first_name": "Alireza", "last_name": "Akhavan", "age": 20 }
```

The same annotation works in both directions: **deserialization** (JSON → Java, on `@RequestBody`) and **serialization** (Java → JSON, on the response). The response will also use `first_name`, not `firstName`.

## 3. Where you can place it

```java
// On a field
@JsonProperty("first_name")
private String firstName;

// On a getter (affects output)
@JsonProperty("first_name")
public String getFirstName() { return firstName; }

// On a setter (affects input)
@JsonProperty("first_name")
public void setFirstName(String firstName) { this.firstName = firstName; }

// On a constructor parameter (needed for immutable classes)
public UserDto(@JsonProperty("first_name") String firstName) {
    this.firstName = firstName;
}

// On record components (the cleanest option)
public record UserDto(
    @JsonProperty("first_name") String firstName,
    @JsonProperty("last_name") String lastName
) {}
```

**Why it works this way:** Jackson builds a single logical property by grouping a field, its getter, and its setter by name. Annotating any one of them renames the whole group. So annotating just the field is usually enough.

## 4. Attributes

```java
@JsonProperty(value = "user_id", required = true, index = 1, defaultValue = "0", access = JsonProperty.Access.READ_ONLY)
```

|Attribute|Purpose|
|---|---|
|`value`|The JSON key name|
|`required`|Marks the property as required|
|`index`|Position in the serialized output|
|`defaultValue`|Documentation metadata only|
|`access`|Controls direction: `READ_ONLY`, `WRITE_ONLY`, `READ_WRITE`, `AUTO`|

The most useful one in practice is `access`. For a password, you want it accepted on input but never returned in a response:

```java
@JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
private String password;
```

For an `id` that the server generates and the client must not set:

```java
@JsonProperty(access = JsonProperty.Access.READ_ONLY)
private Long id;
```

## 5. Gotchas

**1. `required = true` is mostly not enforced.** It's only validated for **constructor/creator parameters**. On a plain field with a setter, Jackson ignores it and leaves the field `null`. For real validation, use Bean Validation: `@NotNull`, `@Valid`.

**2. `defaultValue` does nothing at runtime.** It's only metadata for schema tools like Swagger. Set defaults in Java: `private int age = 18;`.

**3. Boolean naming surprises.** A field `private boolean isActive` with Lombok generates `isActive()`, and Jackson infers the property name as `active`, not `isActive`. Fix it explicitly:

```java
@JsonProperty("isActive")
private boolean isActive;
```

**4. Conflicting names.** If you annotate the field with `"first_name"` and the getter with `"firstName"`, Jackson throws a conflict error. Keep one name per logical property.

**5. Extra JSON keys.** Spring Boot configures Jackson to ignore unknown properties by default (`FAIL_ON_UNKNOWN_PROPERTIES` is off). Plain Jackson outside Spring would fail.

## 6. Related tools

**Accept several input names** with `@JsonAlias`. It affects input only:

```java
@JsonProperty("first_name")
@JsonAlias({"firstName", "fname"})
private String firstName;
```

**Rename everything globally** instead of annotating each field. In `application.properties`:

```properties
spring.jackson.property-naming-strategy=SNAKE_CASE
```

Now `firstName` becomes `first_name` automatically, with no annotations. Use `@JsonProperty` only for exceptions. For a whole API with consistent naming, this is the better choice.

**Exclude a field entirely** with `@JsonIgnore`.

## 7. Decision guide

- A few fields with odd names → `@JsonProperty`
- The whole API uses snake_case → the global naming strategy
- Hiding or protecting a field → `access` or `@JsonIgnore`
- Accepting legacy key names → `@JsonAlias`

[[Spring Framework]]