


## 1. Mental model

Jackson is a **translator that works by inspecting your class**. It doesn't need `Serializable`, and it doesn't use Java's native serialization at all.

- **Serialize:** it looks at your object's properties and writes `"name": value` for each one.
- **Deserialize:** it reads JSON keys, finds the matching property in the target class, and sets it.

Unlike native serialization, **Jackson goes through your constructor or setters**, so normal object creation happens. That makes it safer and more predictable, but it also means you must give Jackson a way in.

Jackson has three layers, from low level to high level:

|Layer|Class|What you work with|
|---|---|---|
|Streaming|`JsonParser`, `JsonGenerator`|Token by token, fastest, rarely used directly|
|Tree|`JsonNode`|Generic tree, no class needed|
|**Data binding**|`ObjectMapper`|JSON to and from your classes (95% of use)|

## 2. The core API

```java
ObjectMapper mapper = new ObjectMapper();

// Object -> JSON
String json = mapper.writeValueAsString(new PersonDto("Alice", 25));
// {"name":"Alice","age":25}

// JSON -> Object
PersonDto p = mapper.readValue(json, PersonDto.class);

// JSON -> Tree (no class)
JsonNode node = mapper.readTree(json);
node.get("name").asText();
```

In Spring Boot you almost never call this yourself. `@RequestBody` and `@ResponseBody` (implicit in `@RestController`) call the mapper for you, and Boot gives you a preconfigured one you can inject.

**Version note:** Spring Boot 4 moved to **Jackson 3**, where the packages are `tools.jackson...`, you build mappers with `JsonMapper.builder()`, and exceptions are unchecked. Annotations still live in `com.fasterxml.jackson.annotation`. Boot 3 uses Jackson 2. Check your project's Boot version, because the concepts below are identical but imports differ.

## 3. How Jackson finds the properties

**Serializing:** it uses public **getters** (`getName()` becomes `"name"`), or accessor methods for records (`name()`). Private fields are ignored unless they have a getter or an annotation.

**Deserializing:** it needs a way to create the object and fill it:

1. **Records or an all-args constructor:** match JSON keys to constructor parameters (works out of the box for records).
2. **No-arg constructor plus setters:** the classic JavaBean style.

```java
// Works: record
public record PersonDto(String name, int age) {}

// Works: bean
public class PersonBean {
    private String name;
    public PersonBean() {}
    public String getName() { return name; }
    public void setName(String n) { name = n; }
}
```

**Gotcha:** a class with only a constructor taking arguments, and no records support or annotations, fails with `InvalidDefinitionException: no Creators`. Use a record or add `@JsonCreator`.

## 4. The annotations worth knowing

```java
public record UserDto(
        Long id,

        @JsonProperty("full_name")           // rename in JSON
        String fullName,

        @JsonIgnore                          // never in JSON, either direction
        String passwordHash,

        @JsonFormat(pattern = "yyyy-MM-dd")  // date format
        LocalDate birthDate,

        @JsonInclude(JsonInclude.Include.NON_NULL)  // omit if null
        String nickname
) {}
```

|Annotation|Purpose|
|---|---|
|`@JsonProperty`|Rename, or expose a private field|
|`@JsonIgnore`|Hide a field|
|`@JsonIgnoreProperties(ignoreUnknown = true)`|Tolerate extra JSON keys|
|`@JsonInclude(NON_NULL)`|Skip nulls in output|
|`@JsonFormat`|Format dates, numbers|
|`@JsonCreator`|Choose the constructor or factory for deserializing|
|`@JsonAlias`|Accept several input names for one property|
|`@JsonView`|Different field sets for different audiences|

Related setting: to use snake_case everywhere without annotating each field, set `spring.jackson.property-naming-strategy=SNAKE_CASE`.

## 5. Generics and collections: the type erasure trap

```java
// WRONG: Jackson sees List<Object>, gives you LinkedHashMaps
List<PersonDto> list = mapper.readValue(json, List.class);

// RIGHT: pass the full generic type
List<PersonDto> list = mapper.readValue(json, new TypeReference<List<PersonDto>>() {});
```

Java erases generic types at runtime, so `List.class` carries no information about the element type. `TypeReference` captures it through an anonymous subclass. Symptom of forgetting: a `ClassCastException` far from the cause, when you finally touch an element.

## 6. Custom serializers (when annotations aren't enough)

Say you want `Money` to serialize as `"12.50 EUR"`:

```java
public class MoneySerializer extends JsonSerializer<Money> {
    @Override
    public void serialize(Money m, JsonGenerator gen, SerializerProvider p) throws IOException {
        gen.writeString(m.amount() + " " + m.currency());
    }
}

public record Invoice(@JsonSerialize(using = MoneySerializer.class) Money total) {}
```

Deserializers mirror this (`JsonDeserializer<T>`, `@JsonDeserialize`). In Spring Boot you can also register them globally with `@JsonComponent`. Most projects need these rarely, so reach for them last.

## 7. Dates: the classic first bug

Use `java.time` types (`Instant`, `LocalDate`, `LocalDateTime`). Output should be ISO-8601 text (`"2026-10-05T10:00:00Z"`), not a numeric timestamp. Spring Boot configures this for you (in Jackson 2 it pulls in the `jsr310` module and turns off timestamps). Only if you build your own `ObjectMapper` in Jackson 2 do you have to do it yourself:

```java
new ObjectMapper()
    .registerModule(new JavaTimeModule())
    .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
```

**Gotcha:** `LocalDateTime` has no time zone, so it's ambiguous across servers. For moments in time, prefer `Instant`.

## 8. Edge cases and gotchas

1. **Unknown fields:** a vanilla `ObjectMapper` throws on unknown JSON keys. Spring Boot's mapper turns this off. If you create your own mapper with `new ObjectMapper()`, you lose Boot's configuration, so inject the Boot one instead.
2. **Missing vs null:** with a missing key you get `null` (or `0` for primitives). Jackson cannot tell "key absent" from "key null" in a plain DTO. For PATCH semantics, that distinction matters, and people use `Optional`-like wrappers or `JsonNullable`.
3. **Primitive vs wrapper:** `int age` becomes `0` if absent, silently. `Integer age` becomes `null`, which `@NotNull` can catch. Use wrappers for required numbers.
4. **Infinite recursion:** `Order` with `customer`, and `Customer` with `orders`, serializes forever until `StackOverflowError`. The real fix is DTOs. Annotations like `@JsonManagedReference` / `@JsonBackReference` or `@JsonIdentityInfo` exist, but they are patches.
5. **Lazy Hibernate proxies:** serializing an entity with an unloaded lazy relation fails or triggers surprise queries. DTOs again.
6. **`@JsonIgnore` is not security by itself:** it protects a field only on that class. A different DTO or endpoint can expose it again, so design DTOs to _contain only what's allowed_.
7. **Large numbers:** JavaScript loses precision above 2^53, so a `Long` ID like `9007199254740993` can arrive corrupted in the browser. Serialize big IDs as strings if they can get that large.
8. **Performance:** `ObjectMapper` is thread-safe and expensive to create. Create **one** and reuse it, never `new ObjectMapper()` per request.

## 9. Security: polymorphism and "default typing"

Jackson can write the class name into JSON to restore subtypes (`enableDefaultTyping`, `@JsonTypeInfo(use = Id.CLASS)`). That brings back exactly the native-serialization danger: **the sender picks which class gets built**, enabling gadget-chain attacks. Jackson has had a long history of CVEs from this.

The safe pattern is an explicit, closed list of subtypes with logical names:

```java
@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, property = "type")
@JsonSubTypes({
    @JsonSubTypes.Type(value = Card.class, name = "card"),
    @JsonSubTypes.Type(value = Paypal.class, name = "paypal")
})
sealed interface Payment permits Card, Paypal {}
```

JSON: `{"type":"card","number":"..."}`. The client can only choose among the names you listed. This connects back to the earlier point: JSON is safer than native serialization **because your code decides the target class**, and this pattern keeps it that way.

## 10. Summary

```
Serialize:    object ──(getters / record accessors)──▶ JSON
Deserialize:  JSON ──(constructor or setters)──▶ object

Configure with: annotations (per class) → mapper settings (global) → custom (de)serializers (last resort)
```

Quick contrast with the notes from the start of this conversation:

||Java native|Jackson|
|---|---|---|
|Needs `Serializable`|Yes|No|
|Constructor runs|No|Yes (or setters)|
|Output|Binary, Java-only|Text, any language|
|Who picks the class|The bytes (risky)|Your code (safe by default)|
|Format control|`transient`, `writeObject`|Annotations, modules|





[[Serialization]]