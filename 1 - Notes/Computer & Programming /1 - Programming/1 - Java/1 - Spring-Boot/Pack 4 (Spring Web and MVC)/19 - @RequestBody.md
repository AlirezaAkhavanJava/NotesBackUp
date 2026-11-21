

## Simple mental model

An HTTP request is like a **parcel**:

- The **label on the outside** is the URL, the headers, and the query string.
- The **contents inside the box** are the body.

`@RequestBody` tells Spring: _"Open the box, take the contents (usually JSON text), and rebuild them as a Java object for me."_

```
Client sends:                           Spring gives you:
POST /api/users                         UserDto dto
Content-Type: application/json          ├─ name  = "Alireza"
                                         └─ email = "ali@mail.com"
{ "name": "Alireza",
  "email": "ali@mail.com" }
```

## Definition

`@RequestBody` is a parameter annotation that binds the **HTTP request body** to a method parameter. Spring picks an `HttpMessageConverter` based on the request's `Content-Type` header to convert the raw bytes into your Java type. For `application/json`, that converter uses **Jackson**, which is what Spring Boot includes by default.

```java
@PostMapping("/api/users")
public User create(@RequestBody UserDto dto) {
    return service.create(dto);
}
```

```java
public record UserDto(String name, String email) {}
```

Test it from your Debian terminal:

```bash
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alireza","email":"ali@mail.com"}'
```

## What happens step by step

1. The request arrives. Spring finds the method via the mapping (`path`, `method`, etc.).
2. Spring reads the `Content-Type` header (`application/json`).
3. It picks the matching converter (Jackson).
4. Jackson reads the JSON text and matches **JSON keys to Java field names**.
5. It creates the object and passes it into your parameter.
6. If anything fails, Spring never calls your method and returns an error response.

## The only parameter: `required`

```java
@RequestBody(required = true)   // default
@RequestBody(required = false)  // body may be missing → dto is null
```

With the default, an **empty or missing body → 400 Bad Request**.

## What types can you bind to?

```java
@RequestBody UserDto dto               // your own class/record (most common)
@RequestBody List<UserDto> dtos        // JSON array: [ {...}, {...} ]
@RequestBody Map<String, Object> map   // arbitrary JSON, no class needed
@RequestBody String raw                // the raw body text, unparsed
@RequestBody byte[] bytes              // raw bytes
```

## How Jackson matches JSON to your class (the "why it works this way")

- **Keys ↔ field names.** `"email"` in JSON goes into the `email` property. Names must match (case-sensitive) unless you use `@JsonProperty("user_email")`.
- **Extra JSON keys are ignored.** Spring Boot turns off Jackson's `FAIL_ON_UNKNOWN_PROPERTIES`, so unknown keys don't cause errors.
- **Missing keys become `null`** (or `0`/`false` for primitives).
- **Wrong types fail.** `"age": "abc"` for an `int` → 400.
- **Your class must be constructible by Jackson:** a record, a class with a no-arg constructor plus setters, or a constructor Jackson can use (Spring Boot enables `-parameters` support for this).

Renaming example:

```java
public record UserDto(
        String name,
        @JsonProperty("user_email") String email) {}
```

## Combining with validation

```java
@PostMapping
public User create(@Valid @RequestBody UserDto dto) { ... }
```

Order of events: the body is first **parsed** (bad JSON → `HttpMessageNotReadableException` → 400), then **validated** (`@NotBlank` etc. → `MethodArgumentNotValidException` → 400).

## Nuances and gotchas

**1. The `Content-Type` header is mandatory.** If you forget `-H "Content-Type: application/json"`, Spring doesn't know how to read the body and returns **415 Unsupported Media Type**. This is the most common beginner mistake.

**2. Only one `@RequestBody` per method.** The body is a stream that can be read only once. If you need multiple pieces of data, wrap them in one DTO.

**3. It's different from `@RequestParam`.**

||`@RequestBody`|`@RequestParam`|
|---|---|---|
|Reads from|body (JSON/XML)|query string or form fields|
|Converts with|`HttpMessageConverter` (Jackson)|simple type conversion|
|Best for|complex objects|single simple values|

**4. HTML form submissions are not `@RequestBody`.** A form sends `application/x-www-form-urlencoded`, not JSON. For that, use `@RequestParam` or `@ModelAttribute`.

**5. Dates need care.** `LocalDate` expects ISO format (`"2026-10-03"`) by default.

**6. Don't bind to a JPA entity directly.** A client could send fields you never intended to be set (like `id` or `role`). This is called _mass assignment_. Bind to a DTO and copy only the allowed fields.

**7. Avoid bodies on GET.** Many proxies and clients drop them. Use query params.

**8. Malformed JSON → 400, not 500.** Spring handles it for you. You can customize the message in a `@RestControllerAdvice` by catching `HttpMessageNotReadableException`.

## Its counterpart

`@RequestBody` is for **incoming** data. The outgoing direction is `@ResponseBody` (already included in `@RestController`), which converts your returned Java object back into JSON. Same converter machinery, opposite direction.

---


[[Spring Framework]]