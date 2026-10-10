


## 1. Mental model: a post office with sorting clerks

You already know Jackson converts objects and JSON. The new idea here is **who decides to call it**. In Spring MVC you never call Jackson yourself. A set of **clerks** (called `HttpMessageConverter`s) sit at the controller's door, and each clerk handles one kind of content. Spring picks the right clerk based on the HTTP headers.

```
Request body  ──▶ [Content-Type header] ──▶ pick clerk ──▶ deserialize ──▶ your method parameter
Return value  ──▶ [Accept header]       ──▶ pick clerk ──▶ serialize   ──▶ response body
```

## 2. Scenario: one request, with the hidden machinery

1. A request arrives: `POST /persons`, header `Content-Type: application/json`, and a JSON body.
2. `DispatcherServlet` finds your controller method and sees the `@RequestBody` parameter.
3. Spring asks the list of converters: "who can read `application/json` into `CreatePersonRequest`?" Jackson's converter answers.
4. The converter streams the body bytes into Jackson, and you get an object. If this fails, your method never runs.
5. Your method returns a `PersonResponse`.
6. Spring reads the request's `Accept` header (default: anything), and again asks the converters who can write this type as JSON.
7. Jackson's converter writes the JSON straight to the response's `OutputStream`, with `Content-Type: application/json`.

This is the byte-stream layer from earlier. The converter is the border guard, and the servlet streams are the road.

## 3. Clerks other than Jackson

The converter list is ordered, and the **first one that supports the type and media type wins**:

|Return type|Clerk|Result|
|---|---|---|
|`String`|`StringHttpMessageConverter`|Written as-is, **not** quoted as JSON|
|`byte[]` / `Resource`|byte-array / resource converters|Raw bytes (file downloads)|
|Any object|Jackson converter|JSON|

Gotcha: returning a `String` such as `"hello"` sends `hello`, not `"hello"`. If a client expects valid JSON, return an object, or `ResponseEntity.ok(Map.of("message","hello"))`.

## 4. Controlling the output (no custom code first)

Boot builds the `ObjectMapper` for you, and you tune it in `application.properties`:

```properties
spring.jackson.default-property-inclusion=non_null
spring.jackson.property-naming-strategy=SNAKE_CASE
spring.jackson.serialization.write-dates-as-timestamps=false
spring.jackson.deserialization.fail-on-unknown-properties=false
```

Rule of thumb for where to configure:

1. **Global behavior** → properties above.
2. **One class or field** → annotations (`@JsonProperty`, `@JsonIgnore`, `@JsonFormat`).
3. **A whole type, everywhere** → a custom serializer registered globally (`@JsonComponent`, renamed `@JacksonComponent` in newer Boot).
4. **Anything else on the mapper** → a customizer bean.

```java
@Bean
Jackson2ObjectMapperBuilderCustomizer jsonCustomizer() {   // Boot 3 / Jackson 2
    return builder -> builder.featuresToDisable(SerializationFeature.FAIL_ON_EMPTY_BEANS);
}
```

Version note: Boot 4 moved to Jackson 3, where the customizer is the Jackson 3 builder-customizer type. The idea is identical, only the type name and imports change, so check your Boot version. The key habit: **inject or customize Boot's mapper, never create your own** with `new ObjectMapper()`, or you lose the Spring configuration (dates, modules, the properties above).

## 5. Selecting what each endpoint exposes

```java
public record PersonResponse(
        Long id,
        String name,
        @JsonInclude(JsonInclude.Include.NON_NULL) String nickname) {}
```

Keep the rule from before: the **DTO decides the fields**. `@JsonIgnore` on an entity is a patch, whereas a DTO that simply doesn't contain `passwordHash` cannot leak it.

For per-request control over the whole response, use `ResponseEntity`:

```java
return ResponseEntity.status(HttpStatus.CREATED)
        .header("Location", "/persons/" + id)
        .body(dto);              // body still goes through the converter
```

## 6. What happens when serialization fails

The failure type tells you which step broke, and Spring maps each one to a status code:

|Problem|Exception|Status|
|---|---|---|
|Malformed JSON, wrong type (`"age":"abc"` for an `int`)|`HttpMessageNotReadableException`|**400**|
|Client sent a `Content-Type` nobody can read|`HttpMediaTypeNotSupportedException`|**415**|
|Client's `Accept` asks for a format you can't produce|`HttpMediaTypeNotAcceptableException`|**406**|
|`@Valid` rule violated|`MethodArgumentNotValidException`|**400**|
|Jackson fails while _writing_ the response|`HttpMessageNotWritableException`|**500**|

The last row is the dangerous one: the failure is on your side, and it can happen **after** the status line is chosen. A common cause is returning a JPA entity with a lazy relation or a bidirectional reference.

Handle these centrally:

```java
@RestControllerAdvice
class ApiErrors {
    @ExceptionHandler(HttpMessageNotReadableException.class)
    ResponseEntity<Map<String,String>> badJson(HttpMessageNotReadableException e) {
        return ResponseEntity.badRequest().body(Map.of("error", "Malformed or invalid JSON"));
    }
}
```

Don't echo the raw Jackson message to clients, because it can reveal class names and internals.

## 7. Serialization beyond controllers

Spring Boot serializes in more places than HTTP, and the format is often a **different default**:

|Place|Default format|Needs `Serializable`?|Better practice|
|---|---|---|---|
|REST controllers|JSON (Jackson)|No|Keep it|
|`RestClient` / `WebClient`|JSON (Jackson)|No|Same DTO idea on the client side|
|Spring Data Redis / `@Cacheable` with Redis|**JDK native** by default|**Yes**|Switch to a JSON serializer|
|`HttpSession` replication|JDK native|Yes|Keep session data small and simple|
|Kafka|String/bytes, configurable|No|JSON or Avro/Protobuf with a schema|
|JPA / database|ORM mapping, not serialization|No|Entities map to columns|

The Redis row is the classic surprise. You add `@Cacheable`, and suddenly you get `NotSerializableException`, because the default cache serializer is native Java. You can either add `implements Serializable` to the cached class or switch to JSON, which is preferred since it avoids the native-serialization security and versioning problems we covered.

Kafka note: with Spring's `JsonDeserializer` you must declare trusted packages (`spring.json.trusted.packages`). That setting is the same "sender must not choose arbitrary classes" protection we discussed for native serialization.

## 8. Gotchas

- **`LazyInitializationException` while serializing:** Jackson touches a lazy field after the transaction ended. Fix it with DTOs, not by loading everything.
- **Date formats:** keep `write-dates-as-timestamps=false` (Boot's default) and use `Instant`/`LocalDate`, so clients receive ISO-8601 strings.
- **Large numbers:** a `Long` above 2^53 loses precision in JavaScript, so send such IDs as strings.
- **Performance:** serializing a huge list in one response holds it all in memory. For big exports, stream it (`StreamingResponseBody`) or paginate.
- **Content negotiation by accident:** adding Jackson's XML module makes endpoints able to return XML when a client sends `Accept: application/xml`. Add modules deliberately.
- **Testing:** use `@JsonTest` to check a DTO's JSON in isolation, and `MockMvc` to check a full request round trip. Serialization bugs (a renamed field, a null) are much cheaper to catch there than in production.

## 9. Compact summary

```
Request:   bytes ─▶ Content-Type picks clerk ─▶ Jackson ─▶ DTO parameter
Response:  DTO return ─▶ Accept picks clerk ─▶ Jackson ─▶ bytes
Config:    properties → annotations → global serializers → builder customizer
Outside HTTP: check each integration's default format (Redis = JDK native!)
```




[[Serialization]]