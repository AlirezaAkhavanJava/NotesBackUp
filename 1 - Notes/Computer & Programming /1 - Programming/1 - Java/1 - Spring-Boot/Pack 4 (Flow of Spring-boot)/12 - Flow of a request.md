

## 1. The mental model: an onion

Forget the list of class names for a moment. Picture an **onion**. The request travels inward through each layer to your code at the center, then the response travels back **outward through the same layers in reverse**.

```
┌─────────────────────────────────────────────┐
│ Tomcat                                      │
│  ┌───────────────────────────────────────┐  │
│  │ Filters (Security, CORS, logging)     │  │
│  │  ┌─────────────────────────────────┐  │  │
│  │  │ DispatcherServlet               │  │  │
│  │  │  ┌───────────────────────────┐  │  │  │
│  │  │  │ Interceptors              │  │  │  │
│  │  │  │  ┌─────────────────────┐  │  │  │  │
│  │  │  │  │ Controller → Service│  │  │  │  │
│  │  │  │  │ → Repository → DB   │  │  │  │  │
│  │  │  │  └─────────────────────┘  │  │  │  │
│  │  │  └───────────────────────────┘  │  │  │
│  │  └─────────────────────────────────┘  │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

Any layer can **stop the trip early** and answer on its own (Security says `401`, an interceptor says no, validation fails). That's the key idea behind most errors you'll see.

## 2. One concrete request, followed from start to finish

Here is the endpoint we'll trace:

```java
@PostMapping("/users")
public ResponseEntity<UserResponse> create(@Valid @RequestBody CreateUserRequest req) {
    UserResponse created = service.create(req);
    return ResponseEntity.status(201).body(created);
}
```

The client sends:

```
POST /users
Content-Type: application/json

{ "username": "ali", "email": "ali@example.com", "password": "secret123" }
```

### Going IN

|#|Who|What happens|
|---|---|---|
|1|**Tomcat**|Receives raw bytes from the network and wraps them in an `HttpServletRequest` object. A thread from the pool is assigned to this request.|
|2|**Filters**|The request passes through each filter in order. Spring Security checks "is this person allowed?" Rejected here means `401`/`403`, and nothing further runs.|
|3|**DispatcherServlet**|The front desk receives it and starts routing.|
|4|**HandlerMapping**|Looks up `POST /users` and finds `UserController.create(...)`. No match means `404`.|
|5|**Interceptors**|`preHandle()` runs. Returning `false` stops everything.|
|6|**Argument resolution**|The adapter must supply the `req` parameter. Jackson reads the JSON body and builds a `CreateUserRequest` (your `@JsonProperty`, `@JsonCreator`, `@JsonFormat` apply here). Bad JSON means `400`.|
|7|**Validation**|`@Valid` checks `@NotBlank`, `@Email`, `@Size`. Failure means `400`, and **your method never runs.**|

### The center

|#|Who|What happens|
|---|---|---|
|8|**Controller**|Your method is finally called with a clean, validated object.|
|9|**Service**|Business logic: build the entity, hash the password.|
|10|**Repository → DB**|Saves the entity and returns it with a generated `id`.|

### Going OUT (the reverse trip)

|#|Who|What happens|
|---|---|---|
|11|**Controller**|Returns `ResponseEntity` with status `201` and a `UserResponse` DTO.|
|12|**Return value handler**|Jackson converts the `UserResponse` object into JSON text (your `@JsonInclude`, `@JsonIgnore` apply here). The status and headers are set.|
|13|**Interceptors**|`postHandle()`, then `afterCompletion()`.|
|14|**Filters**|The response passes back out through the filters (they can add headers, such as CORS).|
|15|**Tomcat**|Writes the bytes to the network and releases the thread.|

The client receives:

```
HTTP/1.1 201
Content-Type: application/json

{ "id": 7, "username": "ali", "email": "ali@example.com" }
```

## 3. The two translations

Across all those steps, only **two** conversions of data really happen, and they mirror each other:

```
raw bytes → HttpServletRequest → JSON text → CreateUserRequest   (step 6: deserialize)
UserResponse → JSON text → bytes → client                         (step 12: serialize)
```

Everything between those two points is plain Java objects. That is why your service and repository code never touch JSON or HTTP, which keeps them clean.

## 4. What happens when something fails

Failures don't crash the flow. They **short-circuit** it and take a different route outward:

```
Exception thrown anywhere inside the DispatcherServlet
        ↓
HandlerExceptionResolver finds a handler
        ↓
Your @RestControllerAdvice / @ExceptionHandler (or Spring's default)
        ↓
Builds an error response ──▶ then goes OUT through interceptors, filters, Tomcat as normal
```

|Failure point|Result|
|---|---|
|Security filter (step 2)|`401`/`403`, bypasses `@ControllerAdvice` entirely|
|No mapping (step 4)|`404`|
|Bad JSON (step 6)|`400`|
|Validation (step 7)|`400`|
|Your service throws `UserNotFoundException` (step 9)|Whatever your `@ExceptionHandler` returns, such as `404`|
|Unhandled exception|`500`|

The step number tells you **which tool can catch it**. Filter-level failures happen before the dispatcher exists, so `@ControllerAdvice` can't see them.

## 5. The one sentence to remember

> **Tomcat receives it → Filters guard it → DispatcherServlet routes it → Jackson and `@Valid` prepare the input → your code runs → Jackson formats the output → everything unwinds in reverse.**

## 6. Gotchas

1. **One request, one thread, for the entire trip.** Steps 1 to 15 all run on the same thread, so a slow database query or a slow outgoing `RestClient` call holds that thread for its whole duration.
2. **Your controller may never run.** Many problems (`400`, `401`, `404`) are decided in steps 2 to 7. When debugging, first ask "did my method even get called?" A breakpoint or log line on its first line answers it.
3. **Filters see the request before Spring understands it.** They only have raw HTTP, with no knowledge of which controller will handle it.
4. **`@Transactional` is not part of this flow by itself.** It is applied around your **service** methods (steps 9 to 10) through a proxy, so the transaction opens and closes inside the center, not around the whole trip. Spring Boot's "open session in view" setting can stretch lazy loading further out, which is another reason to return DTOs.

## 7. Try it yourself

Add these to `application.properties`, send a request, and watch the order in the console:

```properties
logging.level.org.springframework.web=DEBUG
```

You'll see the mapping decision, the argument resolution, and the response handling printed in the same sequence as the table above.





[[Spring Framework]]