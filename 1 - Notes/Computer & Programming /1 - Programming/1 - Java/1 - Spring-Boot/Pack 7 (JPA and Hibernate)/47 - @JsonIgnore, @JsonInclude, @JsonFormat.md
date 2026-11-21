

`@JsonProperty` controlled **what a field is called**. These three control **whether it appears** and **how its value looks**.

## 1. Core intuition

Think of Jackson as a customs officer for your object:

- `@JsonIgnore` is a **banned item**. It never crosses the border.
- `@JsonInclude` is a **conditional pass**. The field crosses only if its value meets a condition (for example, not null).
- `@JsonFormat` is a **repackaging rule**. The item crosses, but in a specific shape (a date as `"01/05/2025"`, not `"2025-05-01"`).

## 2. `@JsonIgnore`: remove a property entirely

```java
public class UserDto {
    private Long id;
    private String username;

    @JsonIgnore
    private String passwordHash;   // never in JSON, in either direction
}
```

**Why it works this way:** as you learned, Jackson groups field + getter + setter into one logical property. `@JsonIgnore` on any one of them removes the **whole group**. Annotating just the getter also blocks the setter, so the property is ignored on input as well.

That is the difference from `@JsonProperty(access = WRITE_ONLY)` from last time:

|Goal|Use|
|---|---|
|Accept on input, hide on output (password)|`@JsonProperty(access = WRITE_ONLY)`|
|Never touch it at all|`@JsonIgnore`|

**Class-level version**, useful when you can't edit the field or want to list several:

```java
@JsonIgnoreProperties({"passwordHash", "internalNotes"})
public class UserDto { ... }

// Also the usual way to tolerate unknown input keys:
@JsonIgnoreProperties(ignoreUnknown = true)
public class UserDto { ... }
```

Spring Boot already ignores unknown keys globally, but this makes the intent explicit and works outside Spring too.

**Gotcha: infinite recursion with JPA entities.**

```java
@Entity class Author { @OneToMany(mappedBy = "author") List<Book> books; }
@Entity class Book   { @ManyToOne Author author; }
```

Serializing an `Author` writes its books, each book writes its author, which writes its books, and so on until `StackOverflowError`. Quick fixes are `@JsonIgnore` on one side, or `@JsonManagedReference` / `@JsonBackReference`. The better fix is not to serialize entities at all. Return **DTOs** or records, which also stops you from accidentally leaking columns.

## 3. `@JsonInclude`: include only when a condition holds

```java
@JsonInclude(JsonInclude.Include.NON_NULL)
public class UserDto {
    private String username;
    private String nickname;    // null → key omitted entirely
}
```

With `nickname = null`, the output is `{"username":"ali"}`, **not** `{"username":"ali","nickname":null}`.

|Value|Omits|
|---|---|
|`ALWAYS` (default)|nothing|
|`NON_NULL`|`null`|
|`NON_ABSENT`|`null` and empty `Optional`|
|`NON_EMPTY`|`null`, empty strings, empty collections/maps/arrays, empty `Optional`|
|`NON_DEFAULT`|values equal to the type's default (`0`, `false`, ...)|

It works at **class level** (applies to all properties) or **field level** (just one):

```java
public class OrderDto {
    private Long id;

    @JsonInclude(JsonInclude.Include.NON_EMPTY)
    private List<String> tags;   // omitted when null or []
}
```

**Global setting** in `application.properties`, usually the best choice for a whole API:

```properties
spring.jackson.default-property-inclusion=non_null
```

**Gotchas:**

- It affects **serialization only**. It does nothing on input.
- `NON_EMPTY` does **not** drop `0` or `false` (a number isn't "empty"). Only `NON_DEFAULT` does that, and it's subtle, so avoid it unless you need it.
- Omitting a key vs. sending `null` is a **contract decision**. Some clients treat a missing key and an explicit `null` differently, especially in PATCH requests, where "not sent" means "don't change" and `null` means "clear it."

## 4. `@JsonFormat`: control the shape of a value

Most commonly used for dates:

```java
public class EventDto {

    @JsonFormat(pattern = "dd/MM/yyyy")
    private LocalDate date;                 // "01/05/2025"

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;        // "2025-05-01 14:30:00"

    @JsonFormat(shape = JsonFormat.Shape.STRING,
                pattern = "yyyy-MM-dd'T'HH:mm:ss",
                timezone = "UTC")
    private Date legacyDate;                // java.util.Date needs a timezone
}
```

It works in **both directions**. The same pattern is used to parse incoming JSON, so a client sending `"2025-05-01"` to a field annotated with `dd/MM/yyyy` gets a `400` error.

**What Spring Boot gives you for free:** it includes Jackson's `jsr310` module and disables writing dates as timestamps. So an unannotated `LocalDate` already serializes as ISO-8601 (`"2025-05-01"`). Annotate only when you need a **different** format. Otherwise ISO-8601 is the right default, because every language parses it.

**Other uses via `shape`:**

```java
@JsonFormat(shape = JsonFormat.Shape.NUMBER)
private Status status;        // enum as its ordinal, not its name (fragile, avoid)

@JsonFormat(shape = JsonFormat.Shape.STRING)
private BigDecimal price;     // 19.99 → "19.99", avoids floating-point issues in JS clients
```

**Global alternatives:**

```properties
spring.jackson.date-format=yyyy-MM-dd HH:mm:ss
spring.jackson.time-zone=UTC
```

These mainly affect `java.util.Date`. For `java.time` types, per-field `@JsonFormat` or a custom `ObjectMapper` is more reliable.

**Gotchas:**

1. **`yyyy` vs `YYYY`:** `YYYY` is the _week-based_ year, which gives wrong results around New Year. Always use lowercase `yyyy`.
2. **`MM` vs `mm`:** months vs minutes. `dd-mm-yyyy` is a classic silent bug.
3. **`LocalDateTime` has no timezone.** A pattern with `Z` or `XXX` will fail. Use `ZonedDateTime`/`OffsetDateTime`/`Instant` if you need zone info.
4. **Mismatched pattern and data:** `LocalDate` with a time pattern (`HH:mm`) throws, because there is no time to format.

## 5. All three together

```java
@JsonInclude(JsonInclude.Include.NON_NULL)
public record UserResponse(
    Long id,
    @JsonProperty("user_name") String username,
    @JsonFormat(pattern = "dd/MM/yyyy") LocalDate birthDate,
    @JsonIgnore String passwordHash,
    String nickname
) {}
```

Output when `nickname` is null:

```json
{ "id": 1, "user_name": "ali", "birthDate": "01/05/2005" }
```

## 6. How they connect

- `@JsonIgnore` and `@JsonProperty(access=...)` are two ways to control **direction**.
- `@JsonInclude` and `@JsonFormat` only shape **output** (`@JsonFormat` also governs input parsing).
- All of them are **annotations over the same logical-property model**. That's why putting them on a field, getter, or setter usually behaves the same.
- Every one has a global equivalent in `application.properties`. Use annotations for exceptions, and global config for rules that apply everywhere.




[[Spring Framework]]