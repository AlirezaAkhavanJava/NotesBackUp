
# ErrorDto — Complete Definition

An `ErrorDto` is the **standard response body** your API returns whenever something goes wrong. It is a plain data class whose only job is to describe an error in a machine-readable, consistent way.

It is not an exception, not a Spring type, not a framework class. It is **your** class, and it is part of your public API contract. Clients parse it. You must treat it like any other versioned API surface.

---

## 1. Why it exists

Without a shared error DTO:

```json
// Controller A
{ "message": "User not found" }

// Controller B
{ "error": "NOT_FOUND", "detail": "..." }

// Spring default
{ "timestamp": "...", "status": 500, "error": "Internal Server Error", "path": "/api/users/999" }
```

Three different shapes. Clients cannot parse them uniformly. Frontends end up with special-case code per endpoint.

With one `ErrorDto`:

```json
{
  "timestamp": "2026-09-24T10:00:00Z",
  "status": 404,
  "error": "Not Found",
  "code": "USER_NOT_FOUND",
  "message": "User 999 not found",
  "path": "/api/users/999",
  "fieldErrors": null,
  "traceId": "b7c1f3a2"
}
```

One shape everywhere. One parser on the client. One contract to version.

---

## 2. Design goals

A good `ErrorDto` is:

- **Machine-readable** — has a stable `code` field clients can switch on.
- **Human-readable** — has a `message` a developer or end user can read.
- **Self-describing** — includes status, path, and timestamp so logs and support can correlate.
- **Traceable** — includes a `traceId` that links the response to server logs.
- **Extensible** — has an optional `fieldErrors` map for validation failures.
- **Safe** — never contains stack traces, SQL, class names, or internal identifiers.
- **Immutable** — records or final fields, no setters.
- **Serializable** — Jackson-friendly, no cycles, no lazy proxies.

---

## 3. Canonical definition

### Using a record (Java 17+)

```java
package com.example.api.error;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.Instant;
import java.util.Map;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ErrorDto(
        Instant timestamp,
        int status,
        String error,
        String code,
        String message,
        String path,
        Map<String, String> fieldErrors,
        String traceId
) {
    public static ErrorDto of(int status, String error, String code, String message, String path) {
        return new ErrorDto(Instant.now(), status, error, code, message, path, null, null);
    }

    public ErrorDto withFieldErrors(Map<String, String> fieldErrors) {
        return new ErrorDto(timestamp, status, error, code, message, path, fieldErrors, traceId);
    }

    public ErrorDto withTraceId(String traceId) {
        return new ErrorDto(timestamp, status, error, code, message, path, fieldErrors, traceId);
    }
}
```

### Using a class (older Java or if you need mutability)

```java
public class ErrorDto {
    private final Instant timestamp;
    private final int status;
    private final String error;
    private final String code;
    private final String message;
    private final String path;
    private final Map<String, String> fieldErrors;
    private final String traceId;
    // constructor + getters
}
```

Prefer the record. It is immutable, concise, and Jackson serializes it correctly out of the box.

---

## 4. Field-by-field explanation

| Field | Type | Required | Purpose |
|---|---|---|---|
| `timestamp` | `Instant` | yes | When the error occurred. ISO-8601 UTC. Lets clients and logs correlate. |
| `status` | `int` | yes | HTTP status code, duplicated in the body for clients that only read JSON. |
| `error` | `String` | yes | HTTP reason phrase: `"Not Found"`, `"Bad Request"`, `"Conflict"`. |
| `code` | `String` | yes | **Your** stable application code: `USER_NOT_FOUND`, `EMAIL_ALREADY_USED`. This is what clients switch on. |
| `message` | `String` | yes | Human-readable description. Safe for clients. No stack traces. |
| `path` | `String` | yes | Request URI. Helps debugging. |
| `fieldErrors` | `Map<String, String>` | optional | Field name → validation message. Only present for validation failures. |
| `traceId` | `String` | optional | Correlation ID linking to server logs (Sleuth, Micrometer Tracing, MDC). |

### Why both `error` and `code`?

- `error` is the generic HTTP reason (`"Not Found"`). Coarse.
- `code` is your domain-specific identifier (`USER_NOT_FOUND`). Precise.

Clients should switch on `code`, not on `message` (messages change) and not on `error` (too coarse).

### Why `fieldErrors` is a map, not a list?

- Map key = field name, value = message. Easy for frontends to attach to form fields.
- List of objects (`[{field, message}]`) is an alternative; both work. The map is simpler when one message per field is enough.
- If a field can have multiple messages, use `Map<String, List<String>>` or `List<FieldErrorDto>`.

### Why `traceId`?

- Support and SRE teams need to find the exact log line for a customer complaint.
- Without it, debugging a production error is guesswork.
- Populate from MDC (`MDC.get("traceId")`) set by Micrometer Tracing or Sleuth.

---

## 5. Variants you will see in the wild

### Minimal

```java
public record ErrorDto(String code, String message) {}
```

```json
{ "code": "USER_NOT_FOUND", "message": "User 999 not found" }
```

Good for internal microservices. Too thin for public APIs.

### ProblemDetail (RFC 7807) — Spring 6 / Boot 3

```java
ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, "User 999 not found");
pd.setTitle("User not found");
pd.setType(URI.create("https://api.example.com/errors/user-not-found"));
pd.setProperty("code", "USER_NOT_FOUND");
pd.setProperty("traceId", "b7c1f3a2");
return pd;
```

Serialized:

```json
{
  "type": "https://api.example.com/errors/user-not-found",
  "title": "User not found",
  "status": 404,
  "detail": "User 999 not found",
  "instance": "/api/users/999",
  "code": "USER_NOT_FOUND",
  "traceId": "b7c1f3a2"
}
```

This is the standard format. If your clients or gateway expect RFC 7807, use `ProblemDetail`. Otherwise, a custom `ErrorDto` gives you full control.

### Field-error object variant

```java
public record FieldErrorDto(String field, String message, Object rejectedValue) {}

public record ErrorDto(
        Instant timestamp, int status, String code, String message,
        String path, List<FieldErrorDto> fieldErrors, String traceId) {}
```

Better when you want to include the rejected value and multiple errors per field.

---

## 6. How it is produced

`ErrorDto` is almost always built inside a `@RestControllerAdvice`. It is never built inside a controller method.

```java
@RestControllerAdvice
@RequiredArgsConstructor
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ErrorDto> handle(UserNotFoundException ex, HttpServletRequest req) {
        ErrorDto body = ErrorDto.of(
                HttpStatus.NOT_FOUND.value(),
                HttpStatus.NOT_FOUND.getReasonPhrase(),
                "USER_NOT_FOUND",
                ex.getMessage(),
                req.getRequestURI()
        ).withTraceId(MDC.get("traceId"));

        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(body);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorDto> handleValidation(MethodArgumentNotValidException ex,
                                                     HttpServletRequest req) {
        Map<String, String> fields = ex.getBindingResult().getFieldErrors().stream()
                .collect(Collectors.toMap(
                        FieldError::getField,
                        fe -> fe.getDefaultMessage() == null ? "invalid" : fe.getDefaultMessage(),
                        (a, b) -> a
                ));

        ErrorDto body = ErrorDto.of(
                HttpStatus.BAD_REQUEST.value(),
                HttpStatus.BAD_REQUEST.getReasonPhrase(),
                "VALIDATION_FAILED",
                "Validation failed",
                req.getRequestURI()
        ).withFieldErrors(fields).withTraceId(MDC.get("traceId"));

        return ResponseEntity.badRequest().body(body);
    }
}
```

To avoid duplicating the constructor calls, add a small factory:

```java
public final class ErrorDtoFactory {

    public static ResponseEntity<ErrorDto> build(HttpStatus status, String code,
                                                 String message, HttpServletRequest req) {
        ErrorDto body = new ErrorDto(
                Instant.now(),
                status.value(),
                status.getReasonPhrase(),
                code,
                message,
                req.getRequestURI(),
                null,
                MDC.get("traceId")
        );
        return ResponseEntity.status(status).body(body);
    }
}
```

Then handlers become one-liners:

```java
return ErrorDtoFactory.build(HttpStatus.NOT_FOUND, "USER_NOT_FOUND", ex.getMessage(), req);
```

---

## 7. Rules and best practices

1. **One ErrorDto for the whole API.** Not one per controller, not one per exception.
2. **`code` is your stable contract.** Never change an existing code. Add new ones instead.
3. **`message` is for humans.** It can change. Clients must not parse it.
4. **Never leak internals.** No stack traces, no SQL, no class names, no internal IDs.
5. **Always include a trace ID.** Support cannot debug without it.
6. **`fieldErrors` only on validation errors.** Set it to `null` (and hide it with `@JsonInclude(NON_NULL)`) elsewhere.
7. **Return the correct HTTP status.** The body `status` must match the response status.
8. **Immutable.** Use a record or final fields. No setters.
9. **Test the shape.** MockMvc assertions on `$.code`, `$.message`, `$.fieldErrors`.
10. **Version it if it changes.** A breaking change to `ErrorDto` is an API breaking change.
11. **Do not reuse ErrorDto for success responses.** Keep success and error DTOs separate.
12. **Localize `message` if your product needs it.** Keep `code` stable and untranslated.

---

## 8. Example client-side handling

```javascript
const res = await fetch("/api/users/999");
if (!res.ok) {
  const err = await res.json();
  switch (err.code) {
    case "USER_NOT_FOUND":    showToast("User does not exist"); break;
    case "VALIDATION_FAILED": setFieldErrors(err.fieldErrors); break;
    default:
      console.error("Unhandled error", err.code, err.traceId);
      showToast("Unexpected error. Reference: " + err.traceId);
  }
}
```

This is why `code` and `fieldErrors` matter: the client can act without parsing `message`.

---

## 9. Summary

**ErrorDto is the single, immutable, machine-readable JSON body your API returns on failure. It carries a stable `code` for logic, a `message` for humans, an HTTP `status`, the request `path`, optional `fieldErrors` for validation, and a `traceId` for observability. It is produced by `@RestControllerAdvice` handlers and consumed by clients as a versioned contract.**





[[Java]]
[[0 - Spring Framework]]