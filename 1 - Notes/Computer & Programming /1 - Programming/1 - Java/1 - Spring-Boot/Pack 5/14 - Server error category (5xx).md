
Read this first : [[11 - HTTP Response (Status) Codes]]
## Mental model

HTTP status codes tell the client **whose fault** a failure was:

|Range|Meaning|Analogy at a restaurant|
|---|---|---|
|**4xx**|**Client** error: the request was wrong|You ordered a dish that isn't on the menu|
|**5xx**|**Server** error: the request was fine, but the server failed|The menu is fine, but the kitchen is on fire|

The client did nothing wrong, so it may retry later. With 4xx, retrying the same request never helps.

## The codes that matter

|Code|Name|Meaning|Typical cause|
|---|---|---|---|
|**500**|Internal Server Error|Generic "something broke in my code"|Unhandled exception: `NullPointerException`, bug, failed serialization|
|**501**|Not Implemented|Server doesn't support this feature or method|Rare in Spring apps|
|**502**|Bad Gateway|A gateway or proxy got an invalid reply from the server behind it|nginx in front of a crashed or restarting Spring app|
|**503**|Service Unavailable|Temporarily can't serve|Overloaded, in maintenance, DB pool exhausted, starting up|
|**504**|Gateway Timeout|The gateway waited too long for the server behind it|Slow query, hung downstream call|

Rarer ones: 505 (HTTP version not supported), 507 (insufficient storage), 508 (loop detected), 511 (network authentication required).

## The gateway trio (502, 503, 504) is where people get confused

```
Client ──► nginx / load balancer ──► Spring Boot app ──► Database
```

- **500**: your app ran and threw an exception.
- **502**: nginx reached out and your app was **dead or sent garbage**.
- **503**: your app (or the balancer) says **"I'm alive but can't handle this right now"**.
- **504**: nginx waited and your app **never answered in time**.

If you see 502/504, look at infrastructure and timeouts first. If you see 500, look at your application logs.

## How a 500 happens in Spring

Any exception that nothing handles travels up the resolver chain (the order from the `@ResponseStatus` lesson) and ends as 500:

```java
@GetMapping("/{id}")
public ProductResponse getOne(@PathVariable Long id) {
    Product p = repo.findById(id).get();   // empty Optional → NoSuchElementException → 500
    return mapper.toResponse(p);
}
```

The client wanted product 999, which doesn't exist. That is the **client's** situation, not a server malfunction, so it should be a 404. The mistake of letting a 4xx situation become a 500 is very common:

|Situation|Wrong (500 by accident)|Right|
|---|---|---|
|ID not found|`.get()` on empty Optional|404 via custom exception|
|Duplicate email (unique constraint)|`DataIntegrityViolationException`|409 Conflict|
|Bad input that slipped past validation|`IllegalArgumentException`|400|
|Real bug, DB down, null where it shouldn't be||500 is correct|

**Decision test:** _"Could the client have avoided this by sending a different request?"_ If yes, it's 4xx. If no, it's 5xx.

## Handling 5xx properly: a catch-all handler

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    // 4xx cases handled by specific handlers elsewhere...

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ProblemDetail conflict(DataIntegrityViolationException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, "Resource already exists");
    }

    // Last resort: anything unexpected
    @ExceptionHandler(Exception.class)
    public ProblemDetail unexpected(Exception ex) {
        String errorId = UUID.randomUUID().toString();
        log.error("Unhandled exception, errorId={}", errorId, ex);   // full stack trace in the LOG
        ProblemDetail pd = ProblemDetail.forStatusAndDetail(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "An unexpected error occurred");                     // vague text to the CLIENT
        pd.setProperty("errorId", errorId);
        return pd;
    }
}
```

**Why this design:**

- **Log everything, show little.** The stack trace goes to your logs. The client gets a generic message plus an `errorId` they can quote to support, and you search your logs for it.
- Without the catch-all, Spring Boot's default `/error` page responds, which is OK but inconsistent with the rest of your API's error format.
- Spring picks the **most specific** matching `@ExceptionHandler`, so the `Exception.class` one only catches what's left.

## Causing 503 and 504 deliberately

Your app is often the one who knows a dependency failed:

```java
@ExceptionHandler(CannotGetJdbcConnectionException.class)
public ResponseEntity<ProblemDetail> dbDown(CannotGetJdbcConnectionException ex) {
    ProblemDetail pd = ProblemDetail.forStatusAndDetail(
            HttpStatus.SERVICE_UNAVAILABLE, "Database temporarily unavailable");
    return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
            .header(HttpHeaders.RETRY_AFTER, "30")      // "try again in 30 seconds"
            .body(pd);
}
```

`Retry-After` is the standard header for 503: it tells well-behaved clients when to come back, instead of hammering a struggling server.

When **your** app calls another service, translate its failures:

```java
try {
    return paymentClient.charge(req);
} catch (ResourceAccessException e) {          // timeout / connection refused
    throw new ResponseStatusException(HttpStatus.GATEWAY_TIMEOUT, "Payment provider timed out");
} catch (HttpServerErrorException e) {         // downstream returned 5xx
    throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Payment provider failed");
}
```

Here your app acts as a gateway: 502 means "the service I depend on gave a bad answer", 504 means "it didn't answer in time".

## What the client sees by default in Spring Boot

```bash
curl -i http://localhost:8080/api/products/abc-broken
```

```
HTTP/1.1 500
Content-Type: application/json

{"timestamp":"2026-10-03T10:15:30.123+00:00","status":500,
 "error":"Internal Server Error","path":"/api/products/1"}
```

Spring Boot 3 hides the exception message and stack trace by default (`server.error.include-message=never`, `include-stacktrace=never`).

```properties
# application.properties: keep these safe in production
server.error.include-stacktrace=never
server.error.include-message=never
```

For local debugging you may set them to `always`, but **never ship that to production**.

## Why the 4xx vs 5xx distinction matters in production

1. **Monitoring and alerts.** Operations teams alert on the **5xx rate**. A 4xx spike means clients are misbehaving, but a 5xx spike means _you_ are broken. If you let client mistakes become 500s, your alerts fire constantly (or get ignored), and real outages hide in the noise.
2. **Retries.** Clients and gateways automatically retry on 502/503/504, because the problem is probably temporary. They never retry on 4xx. A wrong status code triggers the wrong behavior.
3. **Security.** A 500 with a stack trace leaks class names, library versions, SQL, and file paths, which is gold for an attacker.
4. **Debugging.** A correct code tells the front-end developer immediately whether to fix their request (4xx) or call you (5xx).

## Nuances and gotchas

**1. 500 and retries.** Retrying after a 500 is risky for non-idempotent operations. A `POST /orders` that returned 500 might have actually saved the order before failing, which is the exact problem the `Idempotency-Key` header from the earlier example protects against.

**2. Exceptions after the response has started.** If serialization fails midway through writing a large body, the status line is already sent. The client sees a truncated response with a status that looks like success. This is another reason to return simple DTOs.

**3. Common Spring exceptions that are legitimately 500:**

|Exception|Meaning|
|---|---|
|`HttpMessageNotWritableException`|Couldn't serialize your return value (e.g., infinite recursion from entity relationships)|
|`MissingPathVariableException`|Your mapping has `{id}` but the method has no matching parameter: a programmer bug|
|`ConversionNotSupportedException`|Spring can't convert to the type your code asked for: a programmer bug|

These are the **developer's** errors, not the client's, which is why Spring marks them 500.

**4. `AsyncRequestTimeoutException` is 503.** Spring maps it that way for async requests that time out.

**5. Startup and shutdown.** During deployment, a balancer may answer 503 or 502 until your app is ready. Spring Boot Actuator's health endpoints (`/actuator/health`) and graceful shutdown (`server.shutdown=graceful`) exist so the balancer knows when to send traffic.

**6. Don't invent your own 5xx for business rules.** "Insufficient stock" is not a server error. It's 409 or 422.

**7. Test your error paths.** Many apps only test the happy path, then discover in production that the catch-all handler itself throws, which gives an unhelpful default 500.

## Quick reference

|You want to say|Status|
|---|---|
|"Bug or unexpected failure in my code"|500|
|"Feature not supported"|501|
|"A service I depend on gave me garbage"|502|
|"I'm temporarily unable, try later" (add `Retry-After`)|503|
|"A service I depend on was too slow"|504|

## The two categories side by side

```
4xx → "Fix your request."          → client should NOT retry unchanged
5xx → "I failed. Not your fault."  → client MAY retry (especially 502/503/504)
```

---





[[Spring Framework]]
[[Networking]]