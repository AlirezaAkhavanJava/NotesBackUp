

REST is not a technology or a library. It's a set of design rules for building web APIs, from Roy Fielding's 2000 dissertation. An API that follows them is called RESTful. The rules sound abstract, but each one exists to solve a concrete problem, and once you see the problem, the rule is easy to remember.

In Spring Boot, you mostly get REST by following a few habits: nouns in URLs, the right HTTP method, the right status code, and no server-side memory between requests. We'll build a small `/api/users` API to show each one.

---

## The rules, as problems they solve

|Rule|Problem it solves|
|---|---|
|**Client-server split**|Frontend and backend can change independently|
|**Stateless**|Server memory per user makes scaling hard|
|**Resources as nouns**|Every API invents its own URL style (`/getUser`, `/fetchUserById`)|
|**Uniform methods**|Clients have to learn each API's verbs from scratch|
|**Representations**|The database row stays private; clients get a JSON snapshot|
|**Cacheable + layered**|Repeated fetches waste time; proxies and load balancers should be invisible|

**The memory trick:** URLs are nouns, methods are verbs, every request stands alone.

---

## Rule by rule, in Spring Boot

### Resources and methods: the controller

```java
@RestController
@RequestMapping("/api/users")          // the noun: users
public class UserController {

    private final UserService service;

    public UserController(UserService service) { this.service = service; }

    @GetMapping                         // GET /api/users
    public List<UserResponse> list() { return service.findAll(); }

    @GetMapping("/{id}")                // GET /api/users/42
    public UserResponse get(@PathVariable long id) { return service.findById(id); }

    @PostMapping                        // POST /api/users
    public ResponseEntity<UserResponse> create(@Valid @RequestBody CreateUserRequest req) {
        UserResponse created = service.create(req);
        return ResponseEntity
                .created(URI.create("/api/users/" + created.id()))   // 201 + Location
                .body(created);
    }

    @PutMapping("/{id}")                // PUT = replace the whole resource
    public UserResponse replace(@PathVariable long id, @Valid @RequestBody CreateUserRequest req) {
        return service.replace(id, req);
    }

    @DeleteMapping("/{id}")             // DELETE /api/users/42
    @ResponseStatus(HttpStatus.NO_CONTENT)   // 204
    public void delete(@PathVariable long id) { service.delete(id); }

    @GetMapping("/{id}/posts")          // sub-resource: posts of user 42
    public List<PostResponse> posts(@PathVariable long id) { return service.postsOf(id); }
}
```

Notice there is no `/getUser` or `/deletePost` anywhere. The URL names the thing, and the annotation names the action.

### Representations: DTOs, not entities

```java
public record CreateUserRequest(@NotBlank String name, @Email String email) {}
public record UserResponse(long id, String name, String email) {}
```

The client gets a snapshot (`UserResponse`), never your database entity. That way a table change doesn't silently become an API change.

### Status codes: the error half of the contract

```java
@RestControllerAdvice
class ApiExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    ProblemDetail notFound(UserNotFoundException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());  // 404
    }
}
```

`@Valid` failures already return `400` automatically. Quick reference:

- **2xx:** `200` here's your data, `201` created, `204` done with nothing to return
- **4xx (client's fault):** `400` bad request, `401` who are you?, `403` I know you, but no, `404` not found, `429` slow down
- **5xx (server's fault):** `500` bug, `503` temporarily unavailable

### Statelessness: send the token every time

If the server remembers you between requests, every server in your fleet must share that memory. If each request carries its own proof (a token), any server can answer any request, and you can scale by just adding servers.

```java
@Bean
SecurityFilterChain security(HttpSecurity http) throws Exception {
    return http
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .oauth2ResourceServer(o -> o.jwt(Customizer.withDefaults()))
        .authorizeHttpRequests(a -> a.anyRequest().authenticated())
        .build();
}
```

`STATELESS` tells Spring not to create an HTTP session. The client sends `Authorization: Bearer <token>` on every call.

### Cacheability: let clients skip repeat fetches

```java
@GetMapping("/{id}")
public ResponseEntity<UserResponse> get(@PathVariable long id) {
    return ResponseEntity.ok()
            .cacheControl(CacheControl.maxAge(Duration.ofSeconds(60)))
            .body(service.findById(id));
}
```

Caches, proxies, and load balancers in between can now reuse this response for 60 seconds. This is the layered system at work: the client neither knows nor cares who answered.

---

## HATEOAS: the rule most APIs skip

Fielding's full vision is that responses include links telling the client what it can do next, like hyperlinks on a web page. Spring supports this with the `spring-boot-starter-hateoas` dependency:

```java
@GetMapping("/{id}")
public EntityModel<UserResponse> get(@PathVariable long id) {
    UserResponse user = service.findById(id);
    return EntityModel.of(user,
        linkTo(methodOn(UserController.class).get(id)).withSelfRel(),
        linkTo(methodOn(UserController.class).posts(id)).withRel("posts"));
}
```

The JSON now includes `_links` with `self` and `posts`. In practice, most teams skip this, which is why "REST" today often just means "sane HTTP + JSON." Know it exists, but don't feel bad skipping it.

---

## Common confusions

- **REST is not HTTP.** HTTP is just the usual transport.
- **REST is not JSON.** JSON is a popular representation, but XML or HTML also work.
- **JSON over HTTP is not automatically REST.** `/getUserById?id=42` is RPC-style, not RESTful.
- **REST is not GraphQL or SOAP.** Those are different approaches.

## Worth learning next

- **Idempotency:** `GET`, `PUT`, and `DELETE` can be safely repeated with the same effect, while `POST` usually can't. This matters for retries.
- **`PATCH`:** partial updates, where `PUT` replaces everything.
- **Pagination:** `GET /api/users?page=0&size=20` (Spring Data's `Pageable` handles it).
- **Versioning:** `/api/v1/users`, so you can change the contract later without breaking clients.

---

**One-line summary:** REST means URLs are nouns, HTTP methods are verbs, status codes report the outcome, and every request carries everything the server needs.


[[Spring Framework]]
[[Rest-API]]