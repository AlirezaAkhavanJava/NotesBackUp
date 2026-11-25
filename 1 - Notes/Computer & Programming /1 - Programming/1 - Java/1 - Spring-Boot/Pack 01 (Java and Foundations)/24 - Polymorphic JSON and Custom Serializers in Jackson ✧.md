

[Jackson](https://www.youtube.com/watch?v=4cvP_qroLH4)

### What is JSON, and why does Java need help with it?

When your Spring Boot app **sends a response to a browser** or another service, it can't send a Java object directly — a `User` object living in the JVM's memory means nothing outside the JVM. It has to be converted into plain text that any program, in any language, can read. 
That plain text format is **JSON** (JavaScript Object Notation) — just a text structure made of keys and values:

```json
{ "id": 1, "name": "Ali" }
```

Going from a Java object to this text form is called **serialization**. Going the other way — text arriving from a client, turned back into a Java object — is **deserialization**. Your controller methods do this constantly without you writing the conversion code yourself:

```java
@GetMapping("/users/1")
public User getUser() {
    return new User(1L, "Ali");   // you return a Java object...
}
```

```json
// ...and the client receives this:
{ "id": 1, "name": "Ali" }
```

Something, somewhere, is doing that conversion. That something is **Jackson**.

## What Jackson actually is

Jackson is a library — not a Spring invention, just a Java library Spring Boot happens to include and wire up automatically — **whose whole job is converting between Java objects and JSON text.** When Spring Boot sees `spring-boot-starter-web` on your classpath, it configures a Jackson `ObjectMapper` (or `JsonMapper` in the newer version) bean for you behind the scenes. **Every time a controller method returns an object, that mapper turns it into JSON before it leaves your app**; **every time a `@RequestBody` arrives, that same mapper turns the incoming JSON back into a Java object**.

For simple objects, Jackson does this with zero configuration: it looks at the object's fields (or getters), and writes one JSON key per field, matching the name. No annotation, no setup. This is the default behavior, and it's what you've been relying on the entire time without knowing it had a name.

## Where the default behavior breaks down

Jackson's "one field, one JSON key" approach assumes something important: _it knows exactly which class it's building._ If your controller method signature says `Payment`, and `Payment` is one single concrete class, Jackson just builds a `Payment`. No ambiguity.

*But now imagine `Payment` isn't one class* — it's an umbrella term for several different kinds of payment:

```java
sealed interface Payment permits CardPayment, BankPayment {}
record CardPayment(String cardLast4, int amount) implements Payment {}
record BankPayment(String iban, int amount) implements Payment {}
```

A method declares it accepts a `Payment`:

```java
@PostMapping("/payments")
public String pay(@RequestBody Payment payment) {
    // ...
}
```

A request comes in:

```json
{ "cardLast4": "4417", "amount": 50 }
```

Jackson has to build _some_ real object — `Payment` itself is just an interface, you can't instantiate it. Is this JSON a `CardPayment`? It looks like one, sure, to a human reading it. But Jackson doesn't "look" at field shapes and guess by default — it's a text-to-object converter, not a mind reader. So it fails: _"cannot construct instance of Payment (abstract type)."_

The actual problem is worth naming precisely: **JSON text has no concept of "Java class" built into it at all.** A `{ }` block is just a bag of keys and values — nothing in the JSON spec lets you say "this bag of values is specifically a `CardPayment`." If you want Jackson to know which class to build, _you_ have to put that information into the JSON yourself, as an extra piece of data alongside the real fields.

## The fix, in plain terms

Add one extra field to the JSON whose entire purpose is to say "I am a card payment" or "I am a bank payment," and tell Jackson to read that field first before deciding what class to build:

```json
{ "type": "card", "cardLast4": "4417", "amount": 50 }
```

*That `"type": "card"` field isn't part of your actual data — it's a label glued onto the JSON purely so Jackson can tell the difference between a `CardPayment` and a `BankPayment` before it starts building either one.*

This "polymorphic JSON" problem has nothing to do with Java's own reference-type polymorphism underneath (interfaces, `instanceof`, a `List<Interface>` picking a strategy, and so on) except that it's solving a _parallel_ problem: Java can hold different implementations behind one reference type at runtime, but JSON text has no equivalent concept, so you have to fake one by hand with a tagging field.

## The annotations that implement the fix

```java
@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, property = "type")
@JsonSubTypes({
    @JsonSubTypes.Type(value = CardPayment.class, name = "card"),
    @JsonSubTypes.Type(value = BankPayment.class, name = "bank")
})
public sealed interface Payment permits CardPayment, BankPayment {}
```

|Piece|Meaning|
|---|---|
|`use = Id.NAME`|Identify the type by a logical name, not the Java class name|
|`property = "type"`|The JSON key holding that name|
|`@JsonSubTypes`|The registry mapping each name to a class|

Used in a controller, nothing changes about how you consume it — this is the payoff of doing the annotation work once:

```java
@PostMapping("/payments")
public String pay(@RequestBody Payment payment) {
    return switch (payment) {
        case CardPayment c -> "card ending " + c.cardLast4();
        case BankPayment b -> "bank " + b.iban();
    };
}
```

On input, Jackson reads `type` first, looks it up in the registry, then builds that class from the rest of the fields. On output it reverses the process and writes `type` for you — it's never a field you declare on the record itself. (`@JsonTypeInfo`/`@JsonSubTypes` live in `com.fasterxml.jackson.annotation`, unchanged between Jackson 2 and 3.)

## Where the tag can live

```java
// Sibling property (default, shown above)
@JsonTypeInfo(use = Id.NAME, include = As.PROPERTY, property = "type")
// { "type": "card", "amount": 50 }

// Wrapper object — the name becomes the key
@JsonTypeInfo(use = Id.NAME, include = As.WRAPPER_OBJECT)
// { "card": { "amount": 50 } }

// Wrapper array
@JsonTypeInfo(use = Id.NAME, include = As.WRAPPER_ARRAY)
// [ "card", { "amount": 50 } ]

// A real field already carries the tag
@JsonTypeInfo(use = Id.NAME, include = As.EXISTING_PROPERTY, property = "kind", visible = true)

// No tag at all — infer from which fields are present
@JsonTypeInfo(use = Id.DEDUCTION)
// { "cardLast4": "4417" } → CardPayment, since only it has that field
```

`DEDUCTION` suits third-party payloads you don't control, but breaks the moment two subtypes share a field set — then it's genuinely ambiguous and Jackson can't resolve it.

You can also put the name on the subclass instead of the registry: `@JsonTypeName("card")` on the record, letting the `@JsonSubTypes.Type` entry drop its `name`.

## Gotchas for polymorphic JSON

1. **Never use `Id.CLASS` or `Id.MINIMAL_CLASS` with untrusted input.** They let the _client_ name any Java class (`"type": "com.foo.Anything"`) — a deserialization gadget vulnerability. `Id.NAME` with an explicit registry is safe because only the classes you listed are reachable.
2. **Missing or unknown type id → `400`.** `InvalidTypeIdException` if `type` is absent or unrecognized; set `defaultImpl` on `@JsonTypeInfo` to tolerate it instead.
3. **Root-level generics are erased.** `readValue(json, List<Payment>.class)` isn't legal Java — use `new TypeReference<List<Payment>>() {}`. Spring handles this for you automatically inside `@RequestBody List<Payment>`.
4. **A lost static type loses the tag.** Writing a `List<CardPayment>` through a variable typed `List<Object>` can drop the type tag during serialization.
5. **Don't confuse with JPA's `@Inheritance`.** That controls entity-to-table mapping; `@JsonTypeInfo` controls JSON shape. DTOs carry the Jackson annotations, not entities.
6. **The name is a public contract.** Renaming the Java class never changes `"card"` — that's the entire point of `Id.NAME`. Never rename the string once a client depends on it.

## Custom serializers and deserializers

## Why you'd ever need one

Annotations like `@JsonTypeInfo` handle _which class_ to build. But sometimes the problem isn't "which class" — it's "this value needs a JSON shape no built-in annotation can produce." Reach for a custom serializer only after the simpler tools don't cover it:

|Need|Tool|
|---|---|
|Rename / hide / null-handling|`@JsonProperty`, `@JsonIgnore`, `@JsonInclude`|
|Date or number format|`@JsonFormat`|
|Whole object ↔ single string|`@JsonValue` + `@JsonCreator(DELEGATING)`|
|Anything else (custom format, legacy payload, masking, computed output)|custom serializer/deserializer|

A custom serializer is, in effect, you writing the conversion code Jackson normally writes for you automatically — but only for one specific type, where the default "one field, one key" behavior doesn't produce what you need.

## Jackson 3's renamed API

Every Boot-3-era tutorial uses the old names — this table is the map between them:

|Jackson 2|Jackson 3|
|---|---|
|`JsonSerializer<T>`|`ValueSerializer<T>`|
|`JsonDeserializer<T>`|`ValueDeserializer<T>`|
|`SerializerProvider`|`SerializationContext`|
|`com.fasterxml.jackson.databind.*`|`tools.jackson.databind.*`|
|`@JsonComponent`|`@JacksonComponent`|
|checked `IOException`/`JsonProcessingException`|unchecked `JacksonException`|

## Example: a `Money` value traveling as `"19.99 EUR"`

```java
public record Money(BigDecimal amount, String currency) {}
```

```java
import tools.jackson.core.JsonGenerator;
import tools.jackson.core.JsonParser;
import tools.jackson.databind.DeserializationContext;
import tools.jackson.databind.SerializationContext;
import tools.jackson.databind.ValueDeserializer;
import tools.jackson.databind.ValueSerializer;
import org.springframework.boot.jackson.JacksonComponent;

@JacksonComponent
public class MoneyJson {

    public static class Serializer extends ValueSerializer<Money> {
        @Override
        public void serialize(Money value, JsonGenerator gen, SerializationContext ctxt) {
            gen.writeString(value.amount().toPlainString() + " " + value.currency());
        }
    }

    public static class Deserializer extends ValueDeserializer<Money> {
        @Override
        public Money deserialize(JsonParser p, DeserializationContext ctxt) {
            String[] parts = p.getString().split(" ");
            return new Money(new BigDecimal(parts[0]), parts[1]);
        }
    }
}
```

Boot registers both nested classes automatically — every `Money` field, in every DTO, now serializes as `"19.99 EUR"`:

```java
public record OrderResponse(Long id, Money total) {}
// { "id": 1, "total": "19.99 EUR" }
```

Apply it per-field instead when the custom format is the exception rather than the rule:

```java
public record InvoiceLine(
    @JsonSerialize(using = MoneyJson.Serializer.class)
    @JsonDeserialize(using = MoneyJson.Deserializer.class)
    Money price,
    int quantity
) {}
```

## Why `@JacksonComponent` instead of a plain Jackson `Module`

Boot's shortcut scans for annotated beans and registers them with the auto-configured `JsonMapper` internally (via a `JacksonMixinModule`). Because these are real Spring beans, a serializer can inject other services through its constructor — a currency formatter or a masking service, for instance.

## Testing without starting the server

```java
@JsonTest
class MoneyJsonTest {

    @Autowired JsonMapper jsonMapper;

    @Test
    void roundTrip() {
        String json = jsonMapper.writeValueAsString(new Money(new BigDecimal("19.99"), "EUR"));
        assertThat(json).isEqualTo("\"19.99 EUR\"");
        assertThat(jsonMapper.readValue(json, Money.class))
            .isEqualTo(new Money(new BigDecimal("19.99"), "EUR"));
    }
}
```

Jackson 3's `JsonMapper` methods no longer declare checked exceptions, so this test stays clean without a `try/catch`.

## Gotchas for custom serializers

1. **Write both sides deliberately.** A serializer with no matching deserializer means your own API can't read back what it writes — fine if intentional, a bug if not.
2. **Handle bad input.** `null` doesn't reach a serializer by default, but a malformed string _does_ reach the deserializer — `"abc"` throws `ArrayIndexOutOfBounds` on `parts[1]` here. Wrap it so the client sees `400`, not `500`.
3. **Use the provided `JsonGenerator`/`JsonParser`.** Don't hand-build JSON strings inside a serializer — that's how escaping bugs creep in.
4. **No I/O inside a serializer.** It runs per-value, on the request thread — a database call inside one becomes a hidden N+1 problem.
5. **Global registration is global.** A `@JacksonComponent` on `String` or `LocalDate` silently rewrites every response _and_ every outgoing `RestClient` call, since they share one `JsonMapper`. Scope custom serializers to your own value types.
6. **Polymorphic + custom together need cooperation.** If a type also uses `@JsonTypeInfo`, a custom serializer must implement `serializeWithType` to preserve the type tag. Prefer annotations for the polymorphism, custom code only for leaf values.

## Where this fits in the request flow

Both pieces sit in the same two places as the rest of JSON handling: type resolution and deserialization happen during argument resolution (building `@RequestBody`, inside `HttpMessageConverter`); your serializer and the type tag get written during return-value handling, when the response is turned into JSON. Everything between those two points works with plain Java objects — which is why a `switch` over a sealed `Payment` in your service code never touches JSON at all.

## Decision guide

|Situation|Use|
|---|---|
|One field may hold several subclasses|`@JsonTypeInfo` + `@JsonSubTypes` (`Id.NAME`)|
|Third-party payload with no tag|`Id.DEDUCTION` or `defaultImpl`|
|A value type as one JSON string/number|`@JsonValue` + `@JsonCreator`, else a custom serializer|
|A format rule for one field|`@JsonSerialize(using=...)`|
|A format rule for a whole type, app-wide|`@JacksonComponent`|
|Untrusted input|Never `Id.CLASS` — always an explicit registry|



[[Spring Framework]]