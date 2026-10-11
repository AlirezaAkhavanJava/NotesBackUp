# `@JsonCreator`, `@JsonAnySetter` / `@JsonAnyGetter`, `@JsonIgnoreProperties`

So far we've controlled names, visibility, and format. This topic is about **how Jackson builds your object** from JSON and what happens to keys that don't fit.

## 1. Core intuition

By default, Jackson builds an object like assembling furniture from a loose pile of parts:

1. Call the **no-arg constructor** (get an empty frame).
2. For each JSON key, call the **setter** (or set the field) to attach one part at a time.

That fails for **immutable** objects (`final` fields, no setters, no empty constructor). There you need a **recipe**: "here are all the parts at once, build me the finished thing." That recipe is `@JsonCreator`.

The other two tools handle parts that don't fit the blueprint: keys you didn't plan for (`@JsonAnySetter`) and keys you deliberately refuse (`@JsonIgnoreProperties`).

## 2. `@JsonCreator`: construct from JSON

### Mode 1: PROPERTIES (the common one)

Each constructor parameter maps to a JSON key.

```java
public class Point {
    private final int x;
    private final int y;

    @JsonCreator
    public Point(@JsonProperty("x") int x, @JsonProperty("y") int y) {
        this.x = x;
        this.y = y;
    }
    // getters only, no setters
}
```

**Why `@JsonProperty` is needed here:** Java doesn't keep parameter names at runtime by default, so Jackson sees `(int arg0, int arg1)`. The annotation supplies the names.

**When you can skip the annotations:**

- **Records** work natively with no annotations at all.
- With a **single constructor**, Spring Boot's `jackson-module-parameter-names` can read the real parameter names, provided the code is compiled with `-parameters`. The Spring Boot Maven/Gradle plugins and the Spring parent POM enable this for you.

```java
public record Point(int x, int y) {}   // nothing else needed
```

If a class has **multiple constructors**, Jackson can't guess which to use, so mark one with `@JsonCreator`.

### Mode 2: DELEGATING (one value in, object out)

The whole JSON value (not an object with keys) is passed to a single-argument creator. This is typical for value objects, and it is usually a **static factory**:

```java
public class Email {
    private final String value;

    private Email(String value) { this.value = value; }

    @JsonCreator(mode = JsonCreator.Mode.DELEGATING)
    public static Email of(String value) {
        if (!value.contains("@")) throw new IllegalArgumentException("Invalid email");
        return new Email(value);
    }

    @JsonValue                       // the output counterpart
    public String value() { return value; }
}
```

JSON `"ali@example.com"` becomes an `Email`, and an `Email` serializes back to `"ali@example.com"`. `@JsonValue` says "serialize this object as the result of this one method." Together they make a clean pair, and the same trick is common on enums.

**Gotchas:**

- **Single-argument ambiguity.** Is `new Foo(String s)` delegating (`"abc"`) or properties (`{"s":"abc"}`)? Jackson heuristically guesses, and sometimes wrongly. **Always set `mode` explicitly** for single-arg creators.
- **Validation inside the creator** works naturally. A thrown `IllegalArgumentException` gets wrapped by Jackson, and Spring turns it into a **400 Bad Request** (`HttpMessageNotReadableException`). This is a good place for invariants, but for user-facing messages, Bean Validation (`@Valid`) is still the standard.
- **Missing keys don't fail by default.** A missing `int` becomes `0`, and a missing object becomes `null`. `@JsonProperty(required = true)` on **creator parameters** is enforced (this is the case I mentioned earlier where `required` actually works). You can also enable `DeserializationFeature.FAIL_ON_MISSING_CREATOR_PROPERTIES` globally.
- **Primitive vs wrapper:** a missing `int` silently becomes `0`, while a missing `Integer` becomes `null`. When "absent" and "zero" must differ, use the wrapper.

## 3. `@JsonAnySetter` / `@JsonAnyGetter`: dynamic keys

Sometimes JSON has keys you can't know in advance (webhooks, metadata, plugin config). Rather than lose them, you catch them in a `Map`.

```java
public class WebhookEvent {
    private String type;

    private final Map<String, Object> extra = new LinkedHashMap<>();

    @JsonAnySetter                       // input: unknown keys land here
    public void addExtra(String key, Object value) {
        extra.put(key, value);
    }

    @JsonAnyGetter                       // output: map entries become top-level keys
    public Map<String, Object> getExtra() {
        return extra;
    }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
}
```

Input:

```json
{ "type": "payment", "amount": 50, "currency": "EUR" }
```

`type` goes through `setType`, while `amount` and `currency` go to `addExtra`.

Output flattens the map back to the **top level**:

```json
{ "type": "payment", "amount": 50, "currency": "EUR" }
```

Without `@JsonAnyGetter`, you'd get `"extra": {"amount": 50, ...}`, a nested object that changes the shape.

You can also place `@JsonAnySetter` directly on a `Map` field, so no method is needed.

**Gotchas:**

- It only receives **unknown** keys. Known properties still use their normal setters.
- Because any-setter catches everything unmatched, those keys are no longer "unknown," so `ignoreUnknown` has no effect on them.
- Use `LinkedHashMap` if output order matters.
- A client can inject arbitrary keys. Never blindly trust or persist the map.

## 4. `@JsonIgnoreProperties` in depth

You saw the basic form last time. Here is the full picture.

|Attribute|Meaning|
|---|---|
|`value`|Property names to ignore|
|`ignoreUnknown`|Silently skip unrecognized input keys|
|`allowGetters`|Ignored for input, but **still written** to output (read-only)|
|`allowSetters`|Ignored for output, but **still read** from input (write-only)|

The last two make it the class-level twin of `@JsonProperty(access=...)`:

```java
@JsonIgnoreProperties(value = "password", allowSetters = true)   // write-only
public class UserDto {
    private String username;
    private String password;
}
```

**On a property, to cut nested cycles.** This revisits the JPA recursion problem from last time, solved at the exact point of the loop:

```java
public class Book {
    @JsonIgnoreProperties("books")      // when serializing the author, skip its books
    private Author author;
}
```

It applies to the **nested object's** properties, not the field itself. It also works on collection elements.

**Strict vs lenient is a design decision.** Spring Boot is lenient: unknown keys are ignored. That helps forward compatibility, because newer clients can send extra fields without breaking you. But it hides typos: a client sending `"frist_name"` gets no error, and `firstName` simply stays `null`. For strictness:

```properties
spring.jackson.deserialization.fail-on-unknown-properties=true
```

Then `@JsonIgnoreProperties(ignoreUnknown = true)` becomes a per-class opt-out for the places where you need tolerance. Public APIs you don't control tend toward lenient, while internal APIs between your own services can go strict.

## 5. Connecting the pieces

|Concern|Tool|
|---|---|
|Construct immutable object|`@JsonCreator` (or a record)|
|Value object as a single JSON value|`@JsonCreator(DELEGATING)` + `@JsonValue`|
|Keep unpredictable keys|`@JsonAnySetter` / `@JsonAnyGetter`|
|Drop keys deliberately|`@JsonIgnoreProperties` / `@JsonIgnore`|
|One-directional properties|`allowGetters` / `allowSetters` / `access`|

**Practical default for modern Spring Boot:** use **records** for DTOs. You get immutability and constructor-based creation without any of this annotation machinery, and you reach for these annotations only for the exceptions.



[[Spring Framework]]