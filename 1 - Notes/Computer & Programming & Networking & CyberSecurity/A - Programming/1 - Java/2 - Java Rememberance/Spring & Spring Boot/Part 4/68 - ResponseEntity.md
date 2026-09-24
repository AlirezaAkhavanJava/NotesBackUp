
# ResponseEntity, @RestController, and @RequestMapping in Spring Boot

This is a complete guide covering the three annotations/classes you asked about. I will explain each one, why it exists, its parameters, and how they work together.

---

## 1. `ResponseEntity<T>`

### What is it?

`ResponseEntity<T>` is a class from `org.springframework.http` that represents the **entire HTTP response**: status code, headers, and body. You return it from a controller method when you want full control over the response.

```java
public class ResponseEntity<T> extends HttpEntity<T> {
    // T = the type of the body
}
```

Unlike returning a plain object (which Spring wraps into a 200 OK by default), `ResponseEntity` lets you say:

- What **status code** to return (200, 201, 204, 400, 404, 500, etc.)
- What **headers** to include (Location, Content-Type, custom headers, cookies)
- What **body** to include (or no body at all)

### Why use it?

Without `ResponseEntity`, you are stuck with defaults:

```java
@GetMapping("/users/{id}")
public User getUser(@PathVariable Long id) {
    return userService.findById(id); // always 200 OK, no headers, no custom status
}
```

Problems with the above:

- Cannot return 404 when the user does not exist (unless you throw an exception).
- Cannot return 201 Created with a `Location` header after a POST.
- Cannot return 204 No Content.
- Cannot add custom headers.
- Cannot signal "no body".

With `ResponseEntity`, all of that becomes explicit:

```java
@GetMapping("/users/{id}")
public ResponseEntity<UserDto> getUser(@PathVariable Long id) {
    return userService.findById(id)
        .map(ResponseEntity::ok)                // 200 OK with body
        .orElse(ResponseEntity.notFound().build()); // 404 No Content
}
```

### How to build a ResponseEntity

You usually build it with static factory methods, not `new`.

| Method | Meaning |
|---|---|
| `ResponseEntity.ok(body)` | 200 OK with body |
| `ResponseEntity.ok().build()` | 200 OK, no body |
| `ResponseEntity.created(uri).body(dto)` | 201 Created with `Location` header |
| `ResponseEntity.accepted().build()` | 202 Accepted |
| `ResponseEntity.noContent().build()` | 204 No Content |
| `ResponseEntity.badRequest().body(err)` | 400 Bad Request |
| `ResponseEntity.notFound().build()` | 404 Not Found |
| `ResponseEntity.status(HttpStatus.CONFLICT).body(err)` | any status |
| `ResponseEntity.internalServerError().body(err)` | 500 |

You can also use the fluent builder:

```java
return ResponseEntity
    .status(HttpStatus.CREATED)
    .header("X-Trace-Id", "abc123")
    .contentType(MediaType.APPLICATION_JSON)
    .body(userDto);
```

### Full example

```java
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/{id}")
    public ResponseEntity<UserDto> getById(@PathVariable Long id) {
        return userService.findById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<UserDto> create(@RequestBody @Valid CreateUserRequest request) {
        UserDto created = userService.create(request);
        URI location = URI.create("/api/users/" + created.getId());
        return ResponseEntity.created(location).body(created);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        userService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
```

### `ResponseEntity` vs `@ResponseStatus` vs plain return

| Approach | Use when |
|---|---|
| Plain return `UserDto` | Simple 200 OK response, no custom status or headers. |
| `@ResponseStatus(HttpStatus.CREATED)` on method | Fixed status, no headers, no body conditionals. |
| `ResponseEntity<UserDto>` | Full control: status, headers, body, conditional responses. |

### Best practices

- Use `ResponseEntity` when status/headers depend on runtime logic (e.g. 404, 201).
- Use plain return types when it is always 200 OK.
- Use `ResponseEntity<Void>` for no-body responses (204, 404).
- Never return `null`; use `ResponseEntity.noContent().build()` instead.
- For errors, prefer `@ControllerAdvice` + `@ExceptionHandler` over building error responses inline.

---

## 2. `@RestController`

### What is it?

`@RestController` is a convenience annotation that combines `@Controller` and `@ResponseBody`.

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Controller
@ResponseBody
public @interface RestController {
    @AliasFor(annotation = Controller.class)
    String value() default "";
}
```

What this means:

- `@Controller` — the class is a Spring MVC controller, a bean that handles HTTP requests.
- `@ResponseBody` — every method return value is serialized directly into the HTTP response body (usually as JSON via Jackson), instead of being treated as a view name.

Before `@RestController`, you had to write:

```java
@Controller
@ResponseBody
public class UserController { ... }
```

Or annotate every method with `@ResponseBody`. `@RestController` removes that repetition.

### Parameters

`@RestController` has just one optional parameter:

```java
@RestController("customBeanName")
```

| Parameter | Type | Meaning |
|---|---|---|
| `value` | `String` | Optional bean name for the controller. Rarely used. |

That's it. The real configuration happens on the request-mapping annotations.

### What Spring does with a `@RestController`

1. Component scanning registers the class as a Spring bean.
2. Spring MVC detects it and wires its methods to URL patterns.
3. When a request matches, Spring calls the method.
4. The return value is converted by a `HttpMessageConverter` (Jackson for JSON) and written to the response body.
5. If the return type is `ResponseEntity`, Spring uses its status/headers/body directly.

### Example

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    @GetMapping
    public List<UserDto> all() {
        return userService.findAll(); // auto-serialized to JSON
    }
}
```

### `@RestController` vs `@Controller`

| Aspect | `@RestController` | `@Controller` |
|---|---|---|
| Returns | Data serialized into response body | View name resolved by a view resolver |
| Typical use | REST APIs returning JSON/XML | Server-rendered HTML (Thymeleaf, JSP) |
| `@ResponseBody` needed? | No, already applied | Yes, per class or per method |
| Common in microservices | Yes | No |

---

## 3. `@RequestMapping` and its specialized variants

### What is it?

`@RequestMapping` maps HTTP requests to handler methods or controller classes. It is the parent of all other mapping annotations.

```java
@Target({ ElementType.TYPE, ElementType.METHOD })
public @interface RequestMapping {
    String name() default "";
    String[] value() default {};
    String[] path() default {};
    RequestMethod[] method() default {};
    String[] params() default {};
    String[] headers() default {};
    String[] consumes() default {};
    String[] produces() default {};
}
```

### Parameters explained

| Attribute | Meaning | Example |
|---|---|---|
| `value` / `path` | URL pattern(s) | `"/users"`, `"/users/{id}"` |
| `method` | HTTP methods allowed | `RequestMethod.GET`, `POST`, `PUT`, `DELETE`, `PATCH` |
| `params` | Required request parameters | `params = "type=admin"`, `params = "!debug"` |
| `headers` | Required request headers | `headers = "X-API-VERSION=2"` |
| `consumes` | Allowed request `Content-Type` | `consumes = "application/json"` |
| `produces` | Response `Content-Type` | `produces = "application/json"` |
| `name` | Optional name for the mapping | `name = "getUser"` |

### Class-level vs method-level

- **Class-level** `@RequestMapping("/api/users")` sets a common prefix for all methods.
- **Method-level** `@RequestMapping` adds a suffix and HTTP method.

```java
@RestController
@RequestMapping("/api/users")           // prefix
public class UserController {

    @RequestMapping(value = "/{id}", method = RequestMethod.GET)
    public ResponseEntity<UserDto> get(@PathVariable Long id) { ... }

    @RequestMapping(value = "", method = RequestMethod.POST, consumes = "application/json")
    public ResponseEntity<UserDto> create(@RequestBody CreateUserRequest req) { ... }
}
```

### Shortcut annotations

Spring provides shortcuts that already set `method`:

| Shortcut | Equivalent |
|---|---|
| `@GetMapping` | `@RequestMapping(method = GET)` |
| `@PostMapping` | `@RequestMapping(method = POST)` |
| `@PutMapping` | `@RequestMapping(method = PUT)` |
| `@DeleteMapping` | `@RequestMapping(method = DELETE)` |
| `@PatchMapping` | `@RequestMapping(method = PATCH)` |

They support the same parameters except `method`:

```java
@GetMapping(value = "/{id}", produces = "application/json")
public ResponseEntity<UserDto> get(@PathVariable Long id) { ... }

@PostMapping(consumes = "application/json", produces = "application/json")
public ResponseEntity<UserDto> create(@RequestBody @Valid CreateUserRequest req) { ... }
```

### Path variables and query parameters

Inside the URL pattern:

- `{id}` is a **path variable**, bound with `@PathVariable`.
- Query parameters like `?page=1&size=20` are bound with `@RequestParam`.
- Request body is bound with `@RequestBody`.
- Headers are bound with `@RequestHeader`.
- Cookies are bound with `@CookieValue`.

Example combining everything:

```java
@GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
public ResponseEntity<UserDto> get(
        @PathVariable Long id,
        @RequestParam(defaultValue = "false") boolean detailed,
        @RequestHeader(value = "X-Trace-Id", required = false) String traceId) {

    UserDto dto = userService.findById(id, detailed);
    return ResponseEntity.ok()
        .header("X-Trace-Id", traceId)
        .body(dto);
}
```

### Regex and multiple paths

```java
@GetMapping("/users/{id:[0-9]+}")        // id must be digits
@GetMapping({"/users", "/people"})       // matches both
```

### `produces` and content negotiation

```java
@GetMapping(value = "/users", produces = MediaType.APPLICATION_JSON_VALUE)
@GetMapping(value = "/users", produces = MediaType.APPLICATION_XML_VALUE)
```

Spring picks the method based on the client's `Accept` header.

---

## 4. How they all work together

```text
Client
  |  POST /api/users  (JSON body)
  v
+---------------------------------------------------------------+
| Spring Boot Server                                            |
|                                                               |
|  DispatcherServlet                                            |
|      |                                                        |
|      | uses HandlerMapping to match @RequestMapping            |
|      v                                                        |
|  @RestController UserController                               |
|      @RequestMapping("/api/users")                            |
|      @PostMapping(consumes="application/json")                |
|          |                                                    |
|          | @RequestBody -> CreateUserRequest DTO (Jackson)    |
|          v                                                    |
|      UserService.create(request)                              |
|          |                                                    |
|          | DTO Mapper.fromDto(request) -> User entity         |
|          | MyBatis Mapper.insert(user) -> DB                  |
|          | DTO Mapper.toDto(user) -> UserResponse DTO         |
|          v                                                    |
|      returns ResponseEntity<UserDto>                          |
|          |  status 201, Location header, body JSON           |
|          v                                                    |
|  HttpMessageConverter (Jackson) -> JSON                       |
+---------------------------------------------------------------+
  |
  |  HTTP 201 Created
  |  Location: /api/users/42
  |  { "id": 42, "name": "Ana" }
  v
Client
```

### Division of responsibility

| Component | Responsibility |
|---|---|
| `@RestController` | Marks the class as a REST controller that returns data, not views. |
| `@RequestMapping` (class-level) | Sets the base URL for all endpoints in the controller. |
| `@GetMapping` / `@PostMapping` / etc. | Binds a specific HTTP method + path to a handler method. |
| `@RequestBody` / `@PathVariable` / `@RequestParam` | Bind request data to method arguments. |
| `ResponseEntity<T>` | Gives full control over status, headers, and body. |
| Service layer | Business logic, transactions, calls DTO mapper and MyBatis mapper. |
| DTO Mapper | Converts DTO <-> Entity. |
| MyBatis Mapper | Converts Entity <-> DB rows and executes SQL. |

---

## 5. Complete working example

```java
// DTO
public record CreateUserRequest(@NotBlank String name, @Email String email) {}
public record UserDto(Long id, String name, String email) {}

// Entity
public class User {
    private Long id;
    private String name;
    private String email;
    // getters/setters
}

// MyBatis mapper (persistence layer)
@Mapper
public interface UserMapper {
    @Select("SELECT id, name, email FROM users WHERE id = #{id}")
    Optional<User> findById(Long id);

    @Insert("INSERT INTO users(name, email) VALUES(#{name}, #{email})")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    void insert(User user);
}

// DTO mapper
@Mapper(componentModel = "spring")
public interface UserDtoMapper {
    UserDto toDto(User user);

    @Mapping(target = "id", ignore = true)
    User fromDto(CreateUserRequest request);
}

// Service
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;
    private final UserDtoMapper dtoMapper;

    @Transactional
    public UserDto create(CreateUserRequest request) {
        User user = dtoMapper.fromDto(request);
        userMapper.insert(user);
        return dtoMapper.toDto(user);
    }

    @Transactional(readOnly = true)
    public Optional<UserDto> findById(Long id) {
        return userMapper.findById(id).map(dtoMapper::toDto);
    }
}

// Controller
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE,
                 produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<UserDto> create(@RequestBody @Valid CreateUserRequest request) {
        UserDto created = userService.create(request);
        URI location = URI.create("/api/users/" + created.id());
        return ResponseEntity.created(location).body(created);
    }

    @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<UserDto> getById(@PathVariable Long id) {
        return userService.findById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }
}
```

---

## 6. Cheat sheet

| Goal | Use |
|---|---|
| Return plain data with 200 OK | `@RestController` + plain return type |
| Return custom status | `ResponseEntity.status(...).body(...)` |
| Return 201 with Location | `ResponseEntity.created(uri).body(dto)` |
| Return 204 with no body | `ResponseEntity.noContent().build()` |
| Return 404 | `ResponseEntity.notFound().build()` |
| Group endpoints under a prefix | Class-level `@RequestMapping("/api/x")` |
| Bind URL segments | `@PathVariable` |
| Bind query params | `@RequestParam` |
| Bind request body | `@RequestBody` |
| Bind headers | `@RequestHeader` |
| Restrict content type | `consumes` / `produces` |
| Restrict HTTP method | `@GetMapping`, `@PostMapping`, etc. |




[[Java]]
[[0 - Spring Framework]]