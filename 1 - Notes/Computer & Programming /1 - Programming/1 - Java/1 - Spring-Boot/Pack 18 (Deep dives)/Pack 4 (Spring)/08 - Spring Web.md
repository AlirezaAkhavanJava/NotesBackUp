

Spring Web is the part of Spring that lets your application talk over HTTP. It receives requests from browsers, mobile apps, or other services, runs your Java code, and sends a response back, usually as JSON or HTML. When you create a project on Spring Initializr and tick the **Spring Web** box, this is what you get: a ready-to-run web server and a clean way to map URLs to Java methods.

The name covers a small family of pieces working together. The **`spring-web`** module holds the shared HTTP tools (message converters, HTTP clients, filters). The **`spring-webmvc`** module is the framework called **Spring MVC**, which gives you controllers and the `DispatcherServlet`. The starter **`spring-boot-starter-web`** bundles both with an embedded Tomcat server and Jackson (the JSON library), so one dependency gives you a working web app. In this lesson, we will go through all of it, from the first request to the last response.

---

## 1. What the starter gives you

Adding `spring-boot-starter-web` pulls in a stack like this:

```
spring-boot-starter-web
 ├── spring-boot-starter            (Spring Boot core, logging, auto-configuration)
 ├── spring-boot-starter-json       (Jackson for JSON)
 ├── spring-boot-starter-tomcat     (embedded Tomcat server)
 ├── spring-web                     (HTTP abstractions)
 └── spring-webmvc                  (Spring MVC)
```

|Piece|Job|
|---|---|
|Embedded **Tomcat**|Listens on a port (8080 by default) and speaks HTTP|
|**spring-webmvc**|Routes requests to your controller methods|
|**spring-web**|Shared HTTP types: `HttpEntity`, `HttpStatus`, message converters, clients|
|**Jackson**|Turns Java objects into JSON and back|
|**Spring Boot auto-configuration**|Wires all of it together with no setup from you|

This links straight to the modules lesson: `spring-webmvc` sits on top of `spring-context`, so it uses beans, SpEL, and proxies you already know. And since Spring Boot 3, everything uses `jakarta.servlet.*`, not `javax.servlet.*`, because Tomcat implements the Jakarta Servlet specification.

---

## 2. The journey of one request

This is the most important picture in Spring Web. Follow a `GET /api/books/7` request from start to finish.

|Step|Who does it|What happens|
|---|---|---|
|1|**Tomcat**|Accepts the connection and creates `HttpServletRequest` and `HttpServletResponse` objects|
|2|**Servlet filters**|Run first (Spring Security's filter chain, CORS, logging, your JWT filter)|
|3|**DispatcherServlet**|The single front door of Spring MVC; receives every request|
|4|**HandlerMapping**|Finds which controller method matches `GET /api/books/{id}`|
|5|**Interceptors** (`preHandle`)|Optional extra checks before the method|
|6|**HandlerAdapter**|Prepares the arguments (`@PathVariable`, `@RequestBody`, ...) and calls your method|
|7|**Your controller method**|Your code runs and returns an object|
|8|**HttpMessageConverter**|Turns the returned object into JSON|
|9|**Response goes back**|Through the interceptors and filters, then out to the client|

Two ideas to keep:

- The **`DispatcherServlet`** pattern is called _Front Controller_: one servlet handles everything, then dispatches to the right place. You rarely touch it, but everything flows through it.
- **Filters run before and after the `DispatcherServlet`**, and belong to the Servlet world. That is exactly where your JWT filter from Spring Security lives. **Interceptors** run inside Spring MVC, after the `DispatcherServlet` picked a handler.

---

## 3. Controllers: mapping URLs to methods

A controller is a bean whose methods answer HTTP requests.

```java
@RestController
@RequestMapping("/api/books")
public class BookController {

    private final BookService service;

    public BookController(BookService service) {
        this.service = service;
    }

    @GetMapping
    public List<BookResponse> all() {
        return service.findAll();
    }

    @GetMapping("/{id}")
    public BookResponse one(@PathVariable Long id) {
        return service.find(id);
    }

    @PostMapping
    public ResponseEntity<BookResponse> create(@Valid @RequestBody BookRequest req) {
        BookResponse saved = service.create(req);
        URI location = URI.create("/api/books/" + saved.id());
        return ResponseEntity.created(location).body(saved);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}
```

Line by line:

1. `@RestController` marks the class as a controller whose return values are written straight into the response body. It is a shortcut for `@Controller` plus `@ResponseBody`.
2. `@RequestMapping("/api/books")` sets a base path for every method in the class.
3. The constructor receives `BookService`. Spring injects it, as you learned in IoC and CDI.
4. `@GetMapping` answers `GET /api/books`. Returning a `List` makes Jackson write a JSON array.
5. `@GetMapping("/{id}")` answers `GET /api/books/7`. `{id}` is a **path variable**, and `@PathVariable Long id` receives `7`, converted from text to `Long`.
6. `@PostMapping` answers `POST /api/books`.
7. `@RequestBody` tells Spring to read the JSON in the request body and turn it into a `BookRequest`.
8. `@Valid` runs validation on that object before your method starts (see section 6).
9. `ResponseEntity.created(location)` builds a **201 Created** response with a `Location` header. Returning `ResponseEntity` gives you full control over status, headers, and body.
10. `@DeleteMapping` with `@ResponseStatus(NO_CONTENT)` returns **204** with an empty body.

The request and response types can be simple Java **records**:

```java
public record BookRequest(@NotBlank String title, @Positive int pages) {}
public record BookResponse(Long id, String title, int pages) {}
```

### `@Controller` vs `@RestController`

||`@Controller`|`@RestController`|
|---|---|---|
|Return value means|A **view name** (an HTML template like `"home"`)|The **response body** itself|
|Typical use|Server-rendered pages (Thymeleaf)|JSON APIs|
|Needs `@ResponseBody`?|Yes, to return data|No, already included|

---

## 4. Getting data out of the request

Spring reads different parts of the request using parameter annotations.

|Annotation|Reads from|Example request|Code|
|---|---|---|---|
|`@PathVariable`|The URL path|`/books/7`|`@PathVariable Long id`|
|`@RequestParam`|The query string or form field|`/books?page=2&size=10`|`@RequestParam int page`|
|`@RequestBody`|The request body (JSON)|`{"title":"Dune"}`|`@RequestBody BookRequest req`|
|`@RequestHeader`|A header|`Authorization: Bearer ...`|`@RequestHeader("Authorization") String auth`|
|`@CookieValue`|A cookie|`theme=dark`|`@CookieValue String theme`|
|`@ModelAttribute`|Form fields bound to an object|HTML form post|`@ModelAttribute BookForm form`|
|`@RequestPart`|One part of a multipart upload|File upload|`@RequestPart MultipartFile file`|

A few handy options:

```java
@GetMapping
public List<BookResponse> search(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(required = false) String author) {
    // author is null when the client does not send it
}
```

`defaultValue` fills in a missing value, and `required = false` lets the parameter be absent. You can also take `Optional<String>`.

You can also receive framework objects directly, such as `HttpServletRequest`, `Principal`, `Locale`, or `Pageable` (from Spring Data), and Spring will pass them in.

---

## 5. JSON: how objects become text

You return a Java object, and the client receives JSON. Who does the conversion?

An **`HttpMessageConverter`**. It lives in `spring-web`. After your method returns, Spring checks the client's `Accept` header, picks a matching converter, and writes the body.

|Converter|Handles|
|---|---|
|`MappingJackson2HttpMessageConverter`|`application/json` (the one you use most)|
|`StringHttpMessageConverter`|Plain text|
|`ByteArrayHttpMessageConverter`|Raw bytes|
|`ResourceHttpMessageConverter`|Files|
|`FormHttpMessageConverter`|Form data|

The same process works in reverse for `@RequestBody`: it reads the `Content-Type` header and picks a converter to build your object.

Useful Jackson settings in `application.properties`:

```properties
spring.jackson.property-naming-strategy=SNAKE_CASE
spring.jackson.default-property-inclusion=non_null
spring.jackson.serialization.write-dates-as-timestamps=false
```

And two annotations on your classes: `@JsonIgnore` hides a field, and `@JsonProperty("book_title")` renames one.

**Important habit:** return small **DTOs** (like `BookResponse`) rather than your database entities. This avoids leaking private fields such as password hashes, and avoids lazy-loading errors from JPA.

---

## 6. Validation

Validation uses the Jakarta Bean Validation annotations you met earlier (`@NotBlank`, `@Size`, `@Email`, `@Positive`). You need `spring-boot-starter-validation` in the project.

```java
public record BookRequest(
        @NotBlank(message = "title is required") String title,
        @Positive int pages) {}
```

Adding `@Valid` on the `@RequestBody` parameter makes Spring check the object **before** your method runs. If anything fails, Spring throws `MethodArgumentNotValidException`, and the client gets **400 Bad Request**.

For `@RequestParam` and `@PathVariable` values, put `@Validated` on the controller class, then use annotations right on the parameters:

```java
@Validated
@RestController
public class SearchController {
    @GetMapping("/search")
    public String find(@RequestParam @Size(min = 3) String q) { ... }
}
```

---

## 7. Error handling

Without help, an exception in your controller becomes an ugly 500 error. Spring gives you a clean way to handle errors in one place.

```java
@RestControllerAdvice
public class ApiErrors {

    @ExceptionHandler(BookNotFoundException.class)
    public ProblemDetail notFound(BookNotFoundException ex) {
        ProblemDetail pd = ProblemDetail.forStatusAndDetail(
                HttpStatus.NOT_FOUND, ex.getMessage());
        pd.setTitle("Book not found");
        return pd;
    }
}
```

1. `@RestControllerAdvice` makes this class apply **to every controller**. It is global error handling.
2. `@ExceptionHandler(BookNotFoundException.class)` says "when this exception escapes any controller, call this method".
3. `ProblemDetail` is Spring's built-in class for the standard **RFC 9457 "problem details"** error format (`type`, `title`, `status`, `detail`).
4. The client receives a **404** with a tidy JSON body, instead of a stack trace.

You can also throw `ResponseStatusException(HttpStatus.NOT_FOUND, "no such book")` directly for quick cases, or annotate your own exception class with `@ResponseStatus`.

Setting `spring.mvc.problemdetails.enabled=true` makes Spring's own errors (like validation failures) use the same `ProblemDetail` format.

---

## 8. Filters vs. interceptors

Both run around your controller, but they live in different worlds.

||Servlet **Filter**|MVC **HandlerInterceptor**|
|---|---|---|
|Belongs to|Jakarta Servlet|Spring MVC|
|Runs|Before the `DispatcherServlet`|After the handler is chosen|
|Knows which controller method?|No|Yes (receives the handler)|
|Can change the request/response body|Yes (with wrappers)|Not easily|
|Typical use|Security, JWT, CORS, logging, compression|Timing, auth checks per handler, adding model data|
|Methods|`doFilter`|`preHandle`, `postHandle`, `afterCompletion`|

Your `JwtAuthenticationFilter` is a filter because authentication must happen very early, before MVC is involved.

---

## 9. Calling other services: the HTTP clients

`spring-web` also holds clients for **making** HTTP calls to other APIs.

|Client|Style|Notes|
|---|---|---|
|`RestTemplate`|Blocking, older|In maintenance mode; still common in existing code|
|**`RestClient`**|Blocking, fluent|The modern choice (Spring 6.1+)|
|`WebClient`|Reactive or blocking|Comes from `spring-webflux`; best for non-blocking code|
|`@HttpExchange` interfaces|Declarative|Write an interface, Spring builds the client|

A `RestClient` example:

```java
RestClient client = RestClient.create("https://api.example.com");

BookResponse book = client.get()
        .uri("/books/{id}", 7)
        .header("Accept", "application/json")
        .retrieve()
        .body(BookResponse.class);
```

1. `RestClient.create(...)` builds a client with a base URL.
2. `.get().uri(...)` describes the request. `{id}` is filled with `7`.
3. `.retrieve()` sends it and checks the status (4xx and 5xx throw exceptions).
4. `.body(BookResponse.class)` reads the JSON reply into your object, using the same message converters.

---

## 10. Other things you get

|Feature|How to use it|
|---|---|
|**Static files**|Put files in `src/main/resources/static` and they are served from `/`|
|**HTML templates**|Add Thymeleaf; files go in `src/main/resources/templates`|
|**CORS**|`@CrossOrigin` on a controller, or a global `WebMvcConfigurer`|
|**File upload**|`MultipartFile` parameters; limits via `spring.servlet.multipart.max-file-size`|
|**Content negotiation**|`produces` and `consumes` in mappings, or the `Accept` header|
|**Async responses**|Return `Callable`, `DeferredResult`, or `CompletableFuture`|
|**Streaming**|`StreamingResponseBody`, `SseEmitter` (server-sent events)|
|**Custom config**|Implement `WebMvcConfigurer` (add interceptors, converters, CORS, formatters)|

Common server settings in `application.properties`:

```properties
server.port=9090
server.servlet.context-path=/app
server.compression.enabled=true
server.error.include-message=always
```

---

## 11. Related concept: Spring MVC vs. Spring WebFlux

Spring has **two** web stacks:

- **Spring MVC** (`spring-webmvc`) is built on the Servlet API with a **thread-per-request** model. One thread handles one request from start to finish. It is simple, easy to debug, and what you get with `spring-boot-starter-web`.
- **Spring WebFlux** (`spring-webflux`) is built on **reactive streams** (`Mono` and `Flux`) with a small number of threads handling many requests without blocking. It uses Netty by default. It suits very high-concurrency or streaming workloads, but the code style is quite different.

For most apps, MVC is the right choice. In recent Java versions, virtual threads (`spring.threads.virtual.enabled=true`) let MVC handle many more concurrent requests without switching to reactive code. Also, if both MVC and WebFlux are on the classpath, Spring Boot picks **MVC**.

---

## 12. Common mistakes

1. **Using `@Controller` and forgetting `@ResponseBody`.** You get a "view not found" error, because Spring looks for a template. Use `@RestController` for APIs.
2. **Returning entities directly.** This exposes sensitive fields and can trigger lazy-loading errors. Use DTOs.
3. **Missing the validation starter.** `@Valid` silently does nothing without `spring-boot-starter-validation`.
4. **Putting business logic in controllers.** Controllers should translate HTTP to method calls; logic belongs in services.
5. **Using `javax.servlet`.** Spring Boot 3+ needs `jakarta.servlet`.
6. **Wrong content type.** `@RequestBody` needs the client to send `Content-Type: application/json`, or you get a 415 error.
7. **Ambiguous mappings.** Two methods with the same path and HTTP method stop the app at startup.
8. **Forgetting that filters run first.** If a request is blocked with 401 or 403, your controller was never reached; check the security filter chain first.

---

## Summary

- Spring Web = `spring-web` (HTTP tools) + `spring-webmvc` (controllers) + embedded Tomcat + Jackson, bundled in `spring-boot-starter-web`.
- Every request goes through filters, then the `DispatcherServlet`, which finds a handler method, calls it, and converts the result to JSON with an `HttpMessageConverter`.
- Use `@RestController`, `@GetMapping`, `@PostMapping`, and parameter annotations like `@PathVariable`, `@RequestParam`, and `@RequestBody`.
- Validate with `@Valid`, and handle errors in one place with `@RestControllerAdvice` and `ProblemDetail`.
- Filters belong to the Servlet layer (security, JWT); interceptors belong to Spring MVC.
- `RestClient` (or `WebClient`) calls other services.
- MVC is the default stack; WebFlux is the reactive alternative.






[[Spring Framework]]