

## Mental model: flat-pack furniture

A wardrobe in your living room is a **3D structure**. You can't mail it as is, so you take it apart, put the pieces in a flat box, and ship it. The receiver follows the instructions and rebuilds it.

```
Java object in memory  ──serialize──►  flat bytes/text  ──► network / file / DB / cache
(references, structure)                (a sequence)
                       ◄─deserialize──
```

- **Serialization** (also called marshalling or encoding) turns an object into a **format that can be stored or sent**.
- **Deserialization** (unmarshalling or decoding) rebuilds an object from that format.

**Why it's needed:** memory is not transferable. An object is a web of pointers living inside one JVM at specific addresses. A network cable, a file, or another program (Angular, written in TypeScript) can only handle a **sequence of bytes**. Serialization defines the agreed layout of that sequence, and both sides must follow the same rules, or the rebuilt object is wrong or fails to build.

## Where you've already been using it

Every `@RequestBody` and `@ResponseBody` you learned is exactly this:

```
Angular → {"name":"Ali"}  ──► DESERIALIZE ──► UserDto ──► your method
your method ──► UserDto   ──► SERIALIZE   ──► {"id":7,"name":"Ali"} → Angular
```

The `HttpMessageConverter` is the component that does it, and for JSON the engine behind it is **Jackson**. The `Content-Type` header says _which format to deserialize_, and `Accept` says _which format to serialize into_.

## Formats: the same object in different forms

```java
record User(Long id, String name) {}
User u = new User(7L, "Ali");
```

|Format|Looks like|Human-readable?|Typical use|
|---|---|---|---|
|**JSON**|`{"id":7,"name":"Ali"}`|Yes|REST APIs, the web|
|**XML**|`<user><id>7</id><name>Ali</name></user>`|Yes|legacy/enterprise, SOAP|
|**YAML**|`id: 7`<br>`name: Ali`|Yes|configuration|
|**Form-encoded**|`id=7&name=Ali`|Yes|HTML forms|
|**Protobuf / Avro / MessagePack**|binary|No|gRPC, Kafka, high-performance internal calls|
|**Java native serialization**|binary, Java-only|No|old RMI/session code (avoid)|

**The tradeoff:** text formats are easy to debug but bigger and slower. Binary formats are compact and fast but need tooling and a shared schema to read.

## Part 1: JSON with Jackson

### The core API

```java
ObjectMapper mapper = new ObjectMapper();
mapper.registerModule(new JavaTimeModule());      // needed outside Spring for LocalDate etc.

// SERIALIZE: object → JSON
String json = mapper.writeValueAsString(new User(7L, "Ali"));   // {"id":7,"name":"Ali"}

// DESERIALIZE: JSON → object
User back = mapper.readValue(json, User.class);
```

In Spring Boot, you don't create this. Boot builds a **pre-configured `ObjectMapper` bean** (with the Java-time module registered, sensible defaults) and the converter uses it. You can inject the same one with `private final ObjectMapper mapper;` in any service.

### How Jackson works (the "why")

**Serializing:** Jackson uses **reflection** to inspect the class, finds the properties, and writes them. A property is found through:

- **getters** (`getName()` → `"name"`), the default, or
- **public fields**, or
- **record components**.

Private fields without getters are **ignored**. That's why a class with fields but no getters serializes as `{}` (or throws "No serializer found" depending on settings), a classic beginner surprise.

**Deserializing:** Jackson must **construct** the object, and it needs a way:

1. a **no-arg constructor + setters** (or field access), or
2. a **constructor** whose parameters it can map by name (records work automatically, since Spring Boot compiles with `-parameters`), or
3. an explicit `@JsonCreator`.

Without any of those, you get `InvalidDefinitionException: Cannot construct instance of ...`.

```
JSON text → parser (tokens) → find constructor → match keys to properties → set values → object
```

This is also why **unknown keys** matter: the JSON may contain keys the class doesn't have. Plain Jackson **fails** by default (`UnrecognizedPropertyException`). **Spring Boot turns that failure off**, so extra keys are silently ignored. That is the behavior I described under `@RequestBody`.

## Controlling the output with annotations

All are in `com.fasterxml.jackson.annotation` (this package name stays the same even in newer Jackson versions).

```java
public class UserResponse {

    private Long id;

    @JsonProperty("full_name")                 // rename the JSON key
    private String name;

    @JsonIgnore                                // never in JSON, in either direction
    private String passwordHash;

    @JsonInclude(JsonInclude.Include.NON_NULL) // omit if null
    private String nickname;

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
    private LocalDate birthDate;

    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)  // accepted on input, never output
    private String password;
}
```

|Annotation|Effect|Why you'd use it|
|---|---|---|
|`@JsonProperty("x")`|rename a key|JSON uses `snake_case`, Java uses `camelCase`|
|`@JsonIgnore`|exclude a field|secrets, internal fields|
|`@JsonIgnoreProperties({"a","b"})`|exclude several (class level)|same, in one place|
|`@JsonIgnoreProperties(ignoreUnknown = true)`|tolerate unknown keys|plain Jackson outside Boot|
|`@JsonInclude(NON_NULL)` / `NON_EMPTY`|omit nulls/empties|smaller payloads|
|`@JsonFormat`|date/number/enum formatting|control dates|
|`@JsonAlias({"mail","e-mail"})`|accept several input names|migrating a field name safely|
|`@JsonCreator`|choose the constructor/factory|immutable classes|
|`@JsonView`|different field sets per audience|admin vs public view|
|`@JsonPropertyOrder`|key order|stable output|
|`@JsonProperty(access = WRITE_ONLY)`|password: in only|**the correct way to accept a password but never return it**|

**Global naming style** instead of annotating every field:

```properties
spring.jackson.property-naming-strategy=SNAKE_CASE
```

## Records (the modern DTO)

```java
public record ProductRequest(
        @NotBlank String name,
        @JsonProperty("unit_price") BigDecimal price) {}
```

Records have a canonical constructor and accessor methods (`name()`, not `getName()`), and Jackson supports both **natively** (Jackson 2.12+). That's why DTOs as records need no extra code.

## Part 2: the dangerous areas, with real edge cases

### 1. Dates and time

```java
LocalDate d = LocalDate.of(2026, 10, 3);
```

- Without the **Java time module**, plain Jackson fails or produces a messy structure. Boot registers it for you.
- Boot disables `WRITE_DATES_AS_TIMESTAMPS`, so dates become ISO strings (`"2026-10-03"`) rather than numbers or arrays. Use ISO-8601 on the wire: it's unambiguous.
- Prefer `Instant` or `OffsetDateTime` (with a time zone) for moments in time. A `LocalDateTime` has **no zone**, so the same JSON means different instants in Zürich and in Tokyo.
- Don't send `java.util.Date`, which is legacy, mutable, and format-ambiguous.

### 2. Numbers: JavaScript can't hold your `Long`

JSON numbers are just digits, but **JavaScript parses every number as a 64-bit float**, which is exact only up to 2^53 (about 9 × 10^15).

```
Java:  Long id = 9007199254740993L
JSON:  {"id":9007199254740993}
JS:    9007199254740992      ← silently wrong by one!
```

For database IDs from a snowflake generator or other large values, send them as **strings**: `@JsonFormat(shape = STRING)` on the field, or `spring.jackson.generator.write-numbers-as-strings` for all numbers. Likewise, **money**: use `BigDecimal` (not `double`), and consider sending it as a string so no client rounds it.

### 3. `null` vs missing vs empty (three different states)

```json
{"name": null}     // key present, explicit null
{}                 // key absent
{"name": ""}       // empty string
```

With a normal DTO, absent and `null` both end up as `null`, so you **can't tell them apart**. That matters for **PATCH**: "don't touch this field" (absent) versus "clear this field" (null). Solutions: a `Map<String,Object>`, `Optional`/`JsonNullable` (a library), or JSON Merge Patch. It's why I used `Map<String, Object>` in the first PATCH example.

Primitives add a trap: a missing `int age` silently becomes `0`. Use `Integer` when "not provided" is meaningful.

### 4. Enums

By default, enums are serialized by **name** (`"PAID"`). An unknown value on input (`"SHIPPING"`) throws, which Spring turns into a 400. Compare `@Enumerated(STRING)` vs `ORDINAL` in JPA: the same rule holds, so **never depend on ordinal numbers** in a contract.

### 5. Generics and type erasure

Java erases generic types at runtime, so Jackson can't know the element type:

```java
List<User> a = mapper.readValue(json, List.class);          // gives List<LinkedHashMap>!
List<User> b = mapper.readValue(json, new TypeReference<List<User>>() {});   // correct
```

Spring handles this for you in `@RequestBody List<User>` because it reads the declared parameter type. You hit it when calling `mapper.readValue` yourself, and with `RestTemplate`/`RestClient` (`new ParameterizedTypeReference<List<User>>() {}`).

### 6. Entities: the real reason we use DTOs

This is where earlier warnings become concrete.

|Problem|What serialization does|
|---|---|
|**Bidirectional relationship** (`User` ↔ `Order`)|Jackson follows `user.orders[0].user.orders[0]...` forever → `StackOverflowError` / `HttpMessageNotWritableException`|
|**Lazy collections**|Jackson calls the getter after the session closed → `LazyInitializationException`; or inside a transaction, it triggers a **flood of hidden queries**|
|**Hibernate proxies**|A lazy `@ManyToOne` is a proxy subclass with hidden fields (`hibernateLazyInitializer`) → "No serializer found"|
|**All columns leak**|Every getter becomes JSON, including `passwordHash`|

Band-aids exist (`@JsonManagedReference`/`@JsonBackReference`, `@JsonIdentityInfo`, `@JsonIgnore`, the Hibernate module), but each one pollutes the entity with API concerns. The clean fix is the DTO split, with each side serialized from a class designed for it.

**On the input side**, deserializing JSON directly into an entity is **mass assignment**: the client can set any property the entity has (`id`, `role`, `version`).

### 7. Polymorphism and a security trap

```java
@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, property = "type")
@JsonSubTypes({
    @JsonSubTypes.Type(value = Card.class,   name = "card"),
    @JsonSubTypes.Type(value = PayPal.class, name = "paypal")
})
public interface Payment {}
```

`{"type":"card", ...}` becomes a `Card`. Always use an **explicit allow-list of names** like this. The dangerous variant is `enableDefaultTyping()` or `Id.CLASS`, where the JSON names a **Java class to instantiate**. An attacker who controls the JSON can then pick a class whose constructor or setters do harm. This class of bug has produced many real CVEs ("deserialization gadgets").

### 8. Custom serializers (when annotations aren't enough)

```java
public class MoneySerializer extends JsonSerializer<BigDecimal> {
    @Override
    public void serialize(BigDecimal v, JsonGenerator g, SerializerProvider p) throws IOException {
        g.writeString(v.setScale(2, RoundingMode.HALF_UP).toPlainString());
    }
}

@JsonSerialize(using = MoneySerializer.class)
private BigDecimal price;
```

Deserializers work the same way via `JsonDeserializer` and `@JsonDeserialize`. In Spring Boot, a class annotated `@JsonComponent` is registered automatically (renamed `@JacksonComponent` in newer Boot versions).

## Part 3: Java's built-in serialization (and why to avoid it)

Separate from JSON, Java has its own mechanism:

```java
public class Session implements Serializable {
    private static final long serialVersionUID = 1L;
    private String user;
    private transient String password;     // transient = skipped
}

try (var out = new ObjectOutputStream(new FileOutputStream("s.bin"))) {
    out.writeObject(session);
}
Session s = (Session) new ObjectInputStream(new FileInputStream("s.bin")).readObject();
```

|Piece|Meaning|
|---|---|
|`Serializable`|marker interface: "this class may be serialized"|
|`serialVersionUID`|version tag; a mismatch between writer and reader gives `InvalidClassException`|
|`transient`|field excluded|

Why it's discouraged:

1. **Security.** `readObject` rebuilds **whatever class the bytes name, without calling your constructors**. Crafted data can chain existing classes into code execution. This is one of the most notorious vulnerability families in Java, and Java itself now provides deserialization filters (`ObjectInputFilter`) as a mitigation. **Never deserialize untrusted bytes with it.**
2. **Brittle.** Renaming a field or class breaks old data.
3. **Java-only.** Angular can't read it.
4. Bloated, and slow compared with alternatives.

You still meet it indirectly: **HTTP sessions**, **Redis caches**, and **Spring Session** may serialize objects. For those, configure a **JSON serializer** (e.g. `GenericJackson2JsonRedisSerializer`) instead of the JDK default, so your cached data stays readable and safe.

**Note:** `Serializable` has **nothing to do with JSON**. Jackson doesn't require it. Entities sometimes implement it for composite keys or caching, which confuses people.

## The Spring Boot configuration you'll actually use

```properties
# application.properties
spring.jackson.default-property-inclusion=non_null
spring.jackson.property-naming-strategy=SNAKE_CASE
spring.jackson.deserialization.fail-on-unknown-properties=false   # Boot's default already
spring.jackson.serialization.write-dates-as-timestamps=false      # Boot's default already
spring.jackson.time-zone=UTC
```

Or in code, to customize without replacing Boot's auto-configured mapper:

```java
@Bean
Jackson2ObjectMapperBuilderCustomizer customizer() {
    return b -> b.featuresToDisable(SerializationFeature.FAIL_ON_EMPTY_BEANS);
}
```

**Important:** defining your own `ObjectMapper` bean _replaces_ Boot's defaults (dates, Java-time module, unknown-property tolerance), which causes surprising behavior changes. Prefer the customizer or properties.

**Version note:** Spring Boot 4 / Spring Framework 7 move to **Jackson 3**, where the core classes live in `tools.jackson.*` instead of `com.fasterxml.jackson.*` (annotations keep the old package). Check your Boot version in `pom.xml`, since older tutorials and some class names differ.

## Seeing it live on Debian

```bash
# Valid JSON in → deserialized
curl -i -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Ali","email":"a@b.com"}'

# Malformed JSON → deserialization failure → 400 (HttpMessageNotReadableException)
curl -i -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Ali",'

# Wrong type → also 400
curl -i -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Ali","age":"abc"}'

# Pretty-print the response (jq: sudo apt install jq)
curl -s http://localhost:8080/api/users/7 | jq
```

To experiment without Spring, open `jshell` (it ships with the JDK) and paste the `ObjectMapper` lines with the Jackson jars on the classpath, or write a tiny `main` in a Maven project.

## Which error means what

|Symptom|Stage|Usual cause|
|---|---|---|
|400 `HttpMessageNotReadableException`|**deserializing** the request|malformed JSON, wrong type, unknown enum, missing creator|
|415|before deserializing|no/wrong `Content-Type`|
|406|before serializing|`Accept` can't be satisfied|
|500 `HttpMessageNotWritableException`|**serializing** the response|recursion, lazy loading, no getters|
|500 `InvalidDefinitionException`|either|no way to construct the class / no serializer|

Note the asymmetry: failing to deserialize is the **client's** fault (4xx), while failing to serialize is **yours** (5xx). It's the status-category lesson applied directly.

## Nuances and gotchas

1. **Serialization is a contract.** Renaming a Java field changes the JSON key and breaks clients. Using `@JsonProperty` decouples the wire name from the Java name. This is why API fields are versioned, and why entities (whose fields change with the schema) shouldn't be serialized directly.
2. **Round trip ≠ identity.** `deserialize(serialize(x))` gives an _equal_ object, not the _same_ one. Transient state, identity, and shared references are lost. If two fields pointed to the same object, they become two copies.
3. **Never trust deserialized data.** Parsing succeeding only means the **shape** is right. Validation (`@Valid`) checks the **meaning**.
4. **Size limits.** A huge or deeply nested payload is a denial-of-service vector. Jackson has built-in limits (nesting depth, string length, document size in recent versions), and you should cap body size at the server or gateway too.
5. **Streaming for big data.** `ObjectMapper` loads everything into memory. For huge payloads, use the streaming API (`JsonParser`/`JsonGenerator`) or return `StreamingResponseBody`.
6. **Dependency on classpath.** Adding `jackson-dataformat-xml` makes XML work with no code change, because the converter machinery is format-agnostic.
7. **Performance.** Reflection-heavy at first use, then fast. The `ObjectMapper` is **thread-safe and expensive to create**: share one instance, never create it per request.
8. **Logging.** Don't log full request payloads in production; they contain personal data and secrets.

## Quick reference

|Question|Answer|
|---|---|
|Serialize|object → bytes/text|
|Deserialize|bytes/text → object|
|Which component in Spring MVC?|`HttpMessageConverter` using Jackson's `ObjectMapper`|
|What picks the format?|`Content-Type` for input, `Accept` for output|
|Hide a field|`@JsonIgnore` (or better, don't put it in the DTO)|
|Accept a password but never return it|`@JsonProperty(access = WRITE_ONLY)`|
|Rename a key|`@JsonProperty("x")`|
|Generic collections|`TypeReference`|
|Dates|ISO-8601, `Instant`/`OffsetDateTime`|
|Big IDs and money to JavaScript|send as strings|
|Failure on input / output|400 / 500|
|Avoid|Java native serialization of untrusted data, default typing, serializing entities|





[[Java]]
[[Spring Framework]]