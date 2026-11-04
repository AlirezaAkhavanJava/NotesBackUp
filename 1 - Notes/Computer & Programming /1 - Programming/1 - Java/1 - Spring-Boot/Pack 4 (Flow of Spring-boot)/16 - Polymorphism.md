
# Polymorphism (`@JsonTypeInfo`, `@JsonSubTypes`) and custom (de)serializers (`@JacksonComponent`)

Everything so far assumed one JSON shape maps to one Java class. This topic covers two situations where that breaks:

1. **One field can hold several different classes** (polymorphism).
2. **A value needs a JSON form no annotation can express** (custom serializers).

## 1. Core intuition

**Polymorphism analogy:** you receive a box with no label and must decide whether to unpack a laptop or a toaster. You can't, unless someone stuck a **tag** on it. JSON has no concept of "class," so the tag must be written into the JSON itself.

```java
sealed interface Payment permits CardPayment, BankPayment {}
record CardPayment(String cardLast4, int amount) implements Payment {}
record BankPayment(String iban, int amount) implements Payment {}
```

```json
{ "cardLast4": "4417", "amount": 50 }
```

Is that a `CardPayment`? It looks like it, but Jackson doesn't guess. Deserializing into `Payment` fails with _"cannot construct instance of Payment (abstract type)"_. The fix is to add a **type id**.

**Custom serializer analogy:** annotations are _settings on a translator_. A custom serializer is _replacing the translator for one word_ when no setting is enough.

## 2. Polymorphism: the basic recipe

```java
@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, property = "type")
@JsonSubTypes({
    @JsonSubTypes.Type(value = CardPayment.class, name = "card"),
    @JsonSubTypes.Type(value = BankPayment.class, name = "bank")
})
public sealed interface Payment permits CardPayment, BankPayment {}

public record CardPayment(String cardLast4, int amount) implements Payment {}
public record BankPayment(String iban, int amount) implements Payment {}
```

Now the tag is part of the JSON:

```json
{ "type": "card", "cardLast4": "4417", "amount": 50 }
```

Each piece does one job:

|Piece|Meaning|
|---|---|
|`use = Id.NAME`|Identify the type with a **logical name**, not the Java class name|
|`property = "type"`|The JSON key that carries the tag|
|`@JsonSubTypes`|The **registry**: which name maps to which class|

Use it in a controller exactly as before:

```java
@PostMapping("/payments")
public String pay(@RequestBody Payment payment) {
    return switch (payment) {                 // pattern matching on the sealed type
        case CardPayment c -> "card ending " + c.cardLast4();
        case BankPayment b -> "bank " + b.iban();
    };
}
```

The `@JsonTypeInfo`/`@JsonSubTypes` annotations live in `com.fasterxml.jackson.annotation`. That package did **not** move in Jackson 3, so this code is identical in Boot 3 and Boot 4.

**Why it works this way:** on **input**, Jackson reads the `type` value first, looks it up in the registry, then deserializes the rest into that class. On **output**, it does the reverse and writes `type` for you. The tag never has to be a field in your records.

## 3. Variants: where the tag lives

```java
// 1. Default: sibling property (shown above)
@JsonTypeInfo(use = Id.NAME, include = As.PROPERTY, property = "type")
// { "type": "card", "amount": 50 }

// 2. Wrapper object: the name becomes the key
@JsonTypeInfo(use = Id.NAME, include = As.WRAPPER_OBJECT)
// { "card": { "amount": 50 } }

// 3. Wrapper array
@JsonTypeInfo(use = Id.NAME, include = As.WRAPPER_ARRAY)
// [ "card", { "amount": 50 } ]

// 4. The tag already exists as a real field
@JsonTypeInfo(use = Id.NAME, include = As.EXISTING_PROPERTY, property = "kind", visible = true)
// a "kind" field in your class IS the tag; Jackson reads but doesn't duplicate it

// 5. No tag at all: infer from which fields are present
@JsonTypeInfo(use = Id.DEDUCTION)
// { "cardLast4": "4417" }  → CardPayment (only it has cardLast4)
```

`DEDUCTION` is handy for APIs you don't control. It is fragile if two subtypes share the same field set, because then it is genuinely ambiguous.

You can also put the name on the subclass instead of the registry:

```java
@JsonTypeName("card")
public record CardPayment(String cardLast4, int amount) implements Payment {}
```

(The `@JsonSubTypes.Type` entry can then omit `name`.)

## 4. Gotchas for polymorphism

1. **Never use `Id.CLASS` or `Id.MINIMAL_CLASS` with untrusted input.** They let the _client_ choose any Java class by name (`"type": "com.foo.Anything"`), which is the classic **deserialization gadget** vulnerability. `Id.NAME` with an explicit registry is the safe option, because only the classes you listed are possible. Spring Security 7 also leaves default global typing off and adds a `PolymorphicTypeValidator` for the same reason.
2. **Missing or unknown type id → `400`.** If the client omits `type` or sends `"type": "crypto"`, Jackson throws `InvalidTypeIdException`, which Spring surfaces as `400 Bad Request`. To tolerate it, set a fallback with `@JsonTypeInfo(defaultImpl = UnknownPayment.class)`.
3. **Root-level generics are erased.** `jsonMapper.readValue(json, List<Payment>.class)` isn't legal Java. Use `new TypeReference<List<Payment>>() {}`. Inside a `@RequestBody List<Payment>` Spring handles it for you.
4. **Serializing a list from a raw collection** can lose the type tag if the static type is lost. When writing a `List<CardPayment>` through a variable typed `List<Object>`, annotate it or use a typed wrapper.
5. **Don't confuse with JPA inheritance.** `@Inheritance` controls how entities map to tables. `@JsonTypeInfo` controls JSON. They solve different problems, and your DTOs should carry the Jackson annotations, not your entities.
6. **Name stability is a public contract.** Renaming a Java class doesn't change `"card"`, which is the whole point of `Id.NAME`. Never rename the string once clients use it.

## 5. Custom serializers and deserializers

### When you need one

Try the simple tools first, in this order:

|Need|Tool (already learned)|
|---|---|
|Rename / hide / null-handling|`@JsonProperty`, `@JsonIgnore`, `@JsonInclude`|
|Date or number format|`@JsonFormat`|
|Whole object ↔ single string|`@JsonValue` + `@JsonCreator(DELEGATING)`|
|**Anything else** (custom format, legacy payloads, masking, computed output)|**custom serializer/deserializer**|

### The Jackson 3 API

The class names changed in Jackson 3, which affects every tutorial written for Boot 3:

|Jackson 2|Jackson 3|
|---|---|
|`JsonSerializer<T>`|`ValueSerializer<T>`|
|`JsonDeserializer<T>`|`ValueDeserializer<T>`|
|`SerializerProvider`|`SerializationContext`|
|`com.fasterxml.jackson.databind.*`|`tools.jackson.databind.*`|
|`@JsonComponent`|`@JacksonComponent`|
|checked `IOException` / `JsonProcessingException`|unchecked `JacksonException`|

Spring's documentation for Boot 4 describes exactly this: you can annotate `ValueSerializer`, `ValueDeserializer`, or `KeyDeserializer` implementations with `@JacksonComponent`, and Boot registers them for you.

### Example: a `Money` value that travels as `"19.99 EUR"`

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

That's the whole setup. Boot registers both nested classes automatically, and **every** `Money` in **every** DTO now travels as `"19.99 EUR"`:

```java
public record OrderResponse(Long id, Money total) {}
// { "id": 1, "total": "19.99 EUR" }
```

I'm confident about the class names and the registration mechanism (from the docs above), but Jackson 3 also renamed many small methods on `JsonParser`/`JsonGenerator` (for example `getText()` → `getString()`). If your IDE flags a method, check the Jackson 3 migration notes rather than copying Boot 3 snippets.

### Applying it to a single field only

```java
public record InvoiceLine(
    @JsonSerialize(using = MoneyJson.Serializer.class)
    @JsonDeserialize(using = MoneyJson.Deserializer.class)
    Money price,
    int quantity
) {}
```

In Jackson 3 these two annotations live under `tools.jackson.databind.annotation`. Use per-field when the format is an exception. Use `@JacksonComponent` when it's the rule everywhere.

### Why `@JacksonComponent` and not a module?

Plain Jackson registers custom code through a **Module**. `@JacksonComponent` is Boot's shortcut: it scans for annotated beans and registers them with the auto-configured `JsonMapper` (internally through a `JacksonMixinModule`). Because they are Spring beans, a serializer can even **inject services** through its constructor, for example a currency formatter or a masking service.

### Testing it without starting the server

```java
@JsonTest   // from spring-boot-starter-jackson-test
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

Note that `JsonMapper` methods no longer declare checked exceptions in Jackson 3, so tests are cleaner.

## 6. Gotchas for custom (de)serializers

1. **Write both sides or one on purpose.** A serializer without a deserializer means your own API can't read what it writes. Make sure that's intended.
2. **Handle `null` and bad input.** By default, `null` values don't reach a serializer, but malformed strings do reach the deserializer. `"abc"` makes `parts[1]` throw `ArrayIndexOutOfBounds`. Wrap it in a clear exception, because the client should see `400`, not `500`.
3. **Don't swallow Jackson's context.** Use the provided `JsonGenerator`/`JsonParser`; don't build JSON strings by hand, or escaping bugs follow.
4. **Don't do I/O in a serializer.** It runs on the request thread for every value, so a database call inside one becomes an N+1 problem.
5. **Global custom serializers change everything.** A `@JacksonComponent` on `String` or `LocalDate` would silently rewrite every response and every outgoing `RestClient` call, because they share the same `JsonMapper`. Keep them to your own value types.
6. **Polymorphic + custom:** if a type uses `@JsonTypeInfo`, a custom serializer must also cooperate with type information (`serializeWithType`). Prefer annotations for polymorphism and custom code for leaf values.

## 7. Connecting it to the request flow

Both features live in the **same two places** you've already mapped:

- **Step 6 of the flow** (argument resolution): `@JsonSubTypes` picks the class, and your `Deserializer` builds the value, both inside `HttpMessageConverter` while building `@RequestBody`.
- **Step 12** (return-value handling): your `Serializer` and the type tag are written when the response is turned into JSON.

Everything in between works with plain Java objects, which is why a `switch` on a sealed `Payment` in your service never sees JSON.

## 8. Decision guide

|Situation|Use|
|---|---|
|One field may hold several subclasses|`@JsonTypeInfo` + `@JsonSubTypes` (`Id.NAME`)|
|Third-party payload with no tag|`Id.DEDUCTION` or `defaultImpl`|
|A value type as one JSON string/number|`@JsonValue` + `@JsonCreator`, else a custom serializer|
|A format rule for one field|`@JsonSerialize(using=...)`|
|A format rule for a whole type, app-wide|`@JacksonComponent`|
|Untrusted input|Never `Id.CLASS`; always an explicit registry|





[[Spring Framework]]