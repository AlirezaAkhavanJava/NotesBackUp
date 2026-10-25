# HTTP in Java and Spring Boot: the tools and when to use each

Almost every real app talks over HTTP, either **receiving** requests (you're the server) or **sending** them (you're the client, calling someone else's API). Java and Spring have a lot of classes for this, and that's why it feels confusing. Once you sort them into "server side" and "client side", it gets much simpler.

|Side|What you're doing|Main tools|
|---|---|---|
|**Plain Java client**|Calling an API without Spring|`HttpURLConnection`, `java.net.http.HttpClient`, Apache HttpClient, OkHttp|
|**Spring server**|Receiving requests|`@RestController`, `ResponseEntity`, `HttpServletRequest`, `HttpHeaders`, `HttpStatus`|
|**Spring client**|Calling other APIs from your app|`RestClient`, `RestTemplate`, `WebClient`, HTTP Interfaces, OpenFeign|
|**Testing**|Checking your endpoints work|`MockMvc`, `TestRestTemplate`, `WebTestClient`|

---

## Part 1: Plain Java HTTP clients

### 1. `HttpURLConnection` (the old classic)

**The problem it solves:** It's built into Java since version 1.1, so you can call a URL with zero dependencies.

**The catch:** It's clunky. You manage streams, status codes and errors by hand, and it has no built-in JSON support. You'll see it in old code, but you shouldn't pick it for new code.

```java
URL url = new URL("https://api.example.com/users/1");
HttpURLConnection con = (HttpURLConnection) url.openConnection();
con.setRequestMethod("GET");
con.setRequestProperty("Accept", "application/json");

int status = con.getResponseCode();
try (BufferedReader in = new BufferedReader(
        new InputStreamReader(con.getInputStream()))) {
    String body = in.lines().collect(Collectors.joining("\n"));
    System.out.println(status + " " + body);
}
```

**Line by line:**

- `new URL(...)` describes where you want to go.
- `openConnection()` gives you a connection object. You cast it because it returns a generic type.
- `setRequestMethod` and `setRequestProperty` choose the verb and a header.
- `getResponseCode()` actually **sends** the request and returns the status, like `200`.
- The `try` block reads the response body line by line and closes the stream for you.

### 2. `java.net.http.HttpClient` (the modern built-in, Java 11+)

**The problem it solves:** It's a clean, modern client inside the JDK. It supports HTTP/2, async calls, timeouts and a builder-style API, with no extra dependencies. It's what I'd pick for plain Java.

```java
HttpClient client = HttpClient.newBuilder()
        .connectTimeout(Duration.ofSeconds(5))
        .build();

HttpRequest request = HttpRequest.newBuilder()
        .uri(URI.create("https://api.example.com/users"))
        .header("Content-Type", "application/json")
        .POST(HttpRequest.BodyPublishers.ofString("""
                {"name": "Ada", "email": "ada@example.com"}
                """))
        .build();

HttpResponse<String> response =
        client.send(request, HttpResponse.BodyHandlers.ofString());

System.out.println(response.statusCode());
System.out.println(response.body());
```

**Line by line:**

- `HttpClient` is the **reusable** engine. Create it once and share it, because it holds connection pools.
- `HttpRequest` describes **one** request. It's immutable, so you build it and send it.
- `BodyPublishers.ofString` turns your text into a request body.
- `BodyHandlers.ofString()` tells the client how to read the response, here as a `String`. Other handlers can save to a file or stream it.
- `send` blocks until the response arrives. Use `sendAsync` to get a `CompletableFuture` instead.

```java
client.sendAsync(request, HttpResponse.BodyHandlers.ofString())
      .thenApply(HttpResponse::body)
      .thenAccept(System.out::println);
```

### 3. Apache HttpClient 5 and OkHttp (popular third-party options)

**The problem they solve:** They add extras like connection pool tuning, interceptors (to log or add auth to every call) and retries. They were the go-to before Java 11, and Spring can use either one under the hood.

```java
// OkHttp
OkHttpClient client = new OkHttpClient();
Request request = new Request.Builder()
        .url("https://api.example.com/users/1")
        .build();

try (Response response = client.newCall(request).execute()) {
    System.out.println(response.body().string());
}
```

Here `OkHttpClient` is the reusable engine, `Request` describes the call, and `newCall(...).execute()` sends it. Closing the `Response` in the `try` releases the connection.

---

## Part 2: Spring Boot server side (receiving HTTP)

When you add `spring-boot-starter-web`, Spring runs an embedded server (Tomcat by default) and turns HTTP requests into method calls.

### 4. `@RestController` and the mapping annotations

**The problem it solves:** Without it, you'd parse raw requests and write raw responses yourself. With it, you write a normal method and Spring handles the HTTP plumbing and JSON conversion (via Jackson).

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService service;

    public UserController(UserService service) {
        this.service = service;
    }

    @GetMapping("/{id}")
    public User getUser(@PathVariable Long id) {
        return service.findById(id);
    }

    @GetMapping
    public List<User> search(@RequestParam(defaultValue = "") String name) {
        return service.searchByName(name);
    }

    @PostMapping
    public User create(@RequestBody User user) {
        return service.save(user);
    }
}
```

**Line by line:**

- `@RestController` marks the class as a web endpoint, and return values are written straight into the response body as JSON.
- `@RequestMapping("/api/users")` sets the shared URL prefix.
- `@GetMapping("/{id}")` handles `GET /api/users/5`. `@PathVariable` pulls the `5` out of the URL.
- `@RequestParam` reads query parameters, like `/api/users?name=ada`.
- `@RequestBody` converts the incoming JSON into a `User` object.

### 5. `ResponseEntity<T>`

**The problem it solves:** Returning a plain object always gives `200 OK`. `ResponseEntity` lets you control the **status, headers and body** together.

```java
@PostMapping
public ResponseEntity<User> create(@RequestBody User user) {
    User saved = service.save(user);
    return ResponseEntity
            .created(URI.create("/api/users/" + saved.getId()))
            .body(saved);
}

@GetMapping("/{id}")
public ResponseEntity<User> getUser(@PathVariable Long id) {
    return service.findOptional(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
}
```

The first method returns **201 Created** with a `Location` header pointing at the new resource. The second returns **200** with the user, or **404** with no body if nothing is found.

### 6. `HttpStatus` and `HttpHeaders`

These are two small helper classes. `HttpStatus` is an enum of status codes (`HttpStatus.NOT_FOUND`, `HttpStatus.CREATED`), so you never write magic numbers. `HttpHeaders` is a friendly map for headers.

```java
HttpHeaders headers = new HttpHeaders();
headers.setContentType(MediaType.APPLICATION_JSON);
headers.setBearerAuth("my-token");
headers.add("X-Request-Id", UUID.randomUUID().toString());

return new ResponseEntity<>(body, headers, HttpStatus.OK);
```

You'll also use `MediaType` for content types like `MediaType.APPLICATION_JSON`.

### 7. `HttpServletRequest` and `HttpServletResponse`

**The problem they solve:** Sometimes you need the raw low-level request, such as the client's IP, a cookie or a custom stream. Spring lets you add them as method parameters.

```java
@GetMapping("/whoami")
public String whoAmI(HttpServletRequest request) {
    return "IP: " + request.getRemoteAddr()
         + ", agent: " + request.getHeader("User-Agent");
}
```

These classes come from the Servlet API. Reach for them only when the annotations can't do the job.

### 8. Error handling: `@RestControllerAdvice` and `ProblemDetail`

**The problem it solves:** Without it, every controller repeats its own try/catch. One central class can turn exceptions into clean HTTP error responses.

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    public ProblemDetail handleNotFound(UserNotFoundException ex) {
        ProblemDetail problem = ProblemDetail.forStatus(HttpStatus.NOT_FOUND);
        problem.setTitle("User not found");
        problem.setDetail(ex.getMessage());
        return problem;
    }
}
```

`@ExceptionHandler` says "run this when that exception is thrown". `ProblemDetail` is Spring's built-in standard error format (RFC 9457), which clients can parse predictably.

---

## Part 3: Spring clients (calling other APIs)

This is where the most confusion lives, because Spring has gone through several generations of tools.

### 9. `RestTemplate` (the older workhorse)

**The problem it solves:** It wraps all the stream and parsing work from Part 1 into simple method calls. You'll see it in a huge amount of existing code.

**Status:** It's in maintenance mode and Spring has signaled it plans to phase it out, so use it for old code and prefer `RestClient` for new code.

```java
RestTemplate restTemplate = new RestTemplate();

User user = restTemplate.getForObject(
        "https://api.example.com/users/{id}", User.class, 1);

ResponseEntity<User> response = restTemplate.postForEntity(
        "https://api.example.com/users", newUser, User.class);
```

`getForObject` sends a GET, fills the `{id}` placeholder with `1`, and converts the JSON into a `User`. `postForEntity` sends your object as JSON and returns the full response, with status and headers included.

### 10. `RestClient` (the modern synchronous choice, Spring 6.1+)

**The problem it solves:** It's what `RestTemplate` should have been, with a fluent, readable style and the same blocking behavior. For a normal Spring MVC app, **this is the one I'd reach for first.**

```java
RestClient client = RestClient.builder()
        .baseUrl("https://api.example.com")
        .defaultHeader("Accept", "application/json")
        .build();

// GET
User user = client.get()
        .uri("/users/{id}", 1)
        .retrieve()
        .body(User.class);

// POST
User created = client.post()
        .uri("/users")
        .contentType(MediaType.APPLICATION_JSON)
        .body(new User("Ada", "ada@example.com"))
        .retrieve()
        .body(User.class);
```

**Line by line:**

- `builder().baseUrl(...)` sets the shared settings once, so you don't repeat the host every time.
- `.get()` picks the method and `.uri("/users/{id}", 1)` fills in the path.
- `.retrieve()` sends the request and gets ready to read the response.
- `.body(User.class)` converts the JSON into your class.

Handling errors is also tidy:

```java
User user = client.get()
        .uri("/users/{id}", 99)
        .retrieve()
        .onStatus(HttpStatusCode::is4xxClientError, (req, res) -> {
            throw new UserNotFoundException("No such user");
        })
        .body(User.class);
```

In a Spring Boot app, inject the auto-configured `RestClient.Builder` instead of calling `RestClient.builder()`, so Boot's settings and JSON setup apply.

### 11. `WebClient` (reactive and non-blocking)

**The problem it solves:** A blocking call makes a thread wait. `WebClient` doesn't block, so it's ideal for reactive apps (WebFlux) and for firing many calls at once. It needs `spring-boot-starter-webflux`.

```java
WebClient webClient = WebClient.builder()
        .baseUrl("https://api.example.com")
        .build();

Mono<User> userMono = webClient.get()
        .uri("/users/{id}", 1)
        .retrieve()
        .bodyToMono(User.class);

Flux<User> usersFlux = webClient.get()
        .uri("/users")
        .retrieve()
        .bodyToFlux(User.class);
```

It looks like `RestClient`, but returns `Mono` (zero or one item, later) and `Flux` (many items, over time). Nothing happens until someone **subscribes**, or you call `.block()` to wait for the result.

**Quick related concept, reactive streams:** `Mono` and `Flux` come from Project Reactor. Think of them as "a promise of a value" and "a promise of a stream of values", with operators like `map` and `flatMap` to transform results as they arrive.

### 12. HTTP Interface clients (`@HttpExchange`)

**The problem it solves:** Writing `client.get().uri(...).retrieve()...` for every endpoint gets repetitive. With this feature you describe the API as a Java **interface** and Spring generates the implementation for you.

```java
@HttpExchange("/users")
public interface UserClient {

    @GetExchange("/{id}")
    User getUser(@PathVariable long id);

    @GetExchange
    List<User> list(@RequestParam String name);

    @PostExchange
    User create(@RequestBody User user);
}
```

To get a working instance:

```java
@Bean
UserClient userClient(RestClient.Builder builder) {
    RestClient restClient = builder.baseUrl("https://api.example.com").build();
    RestClientAdapter adapter = RestClientAdapter.create(restClient);
    HttpServiceProxyFactory factory =
            HttpServiceProxyFactory.builderFor(adapter).build();
    return factory.createClient(UserClient.class);
}
```

The annotations mirror the controller ones you already know. The factory wraps your `RestClient` and builds a proxy object that implements the interface. Then you inject `UserClient` anywhere and call `userClient.getUser(1)` like a normal method. Newer Spring versions also offer extra configuration shortcuts for registering these clients, so check the docs for your version.

### 13. OpenFeign (Spring Cloud)

**The problem it solves:** It's the same "declare an interface" idea as above, but it comes from Spring Cloud and has been popular in microservices for years. It integrates with load balancing and service discovery.

```java
@FeignClient(name = "user-service", url = "https://api.example.com")
public interface UserFeignClient {

    @GetMapping("/users/{id}")
    User getUser(@PathVariable("id") Long id);
}
```

Add `spring-cloud-starter-openfeign` and `@EnableFeignClients` on your main class, then inject the interface. For new projects without Spring Cloud, the built-in HTTP Interfaces are usually enough.

---

## Part 4: Testing your HTTP layer

|Tool|What it does|Use it when|
|---|---|---|
|**`MockMvc`**|Simulates requests without starting a real server|Fast tests of controllers|
|**`TestRestTemplate`**|Makes real HTTP calls to your app on a random port|Full integration tests|
|**`WebTestClient`**|Fluent test client that also works for reactive apps|Reactive apps or fluent assertions|

```java
@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired MockMvc mockMvc;
    @MockitoBean UserService service;

    @Test
    void returnsUser() throws Exception {
        when(service.findById(1L)).thenReturn(new User(1L, "Ada"));

        mockMvc.perform(get("/api/users/1"))
               .andExpect(status().isOk())
               .andExpect(jsonPath("$.name").value("Ada"));
    }
}
```

`@WebMvcTest` loads only the web layer, so tests stay fast. `@MockitoBean` swaps the real service for a fake. `perform(get(...))` pretends to be a request, and `andExpect` checks the status and JSON. (On older Spring Boot versions this annotation is called `@MockBean`.)

---

## Quick decision guide

|Your situation|Pick|
|---|---|
|Plain Java, no Spring|`java.net.http.HttpClient`|
|Spring MVC app calling an API|**`RestClient`**|
|Many API calls, wanting a clean interface|**HTTP Interface** (`@HttpExchange`) on top of `RestClient`|
|Reactive (WebFlux) app|`WebClient`|
|Old code you're maintaining|`RestTemplate` (migrate when you can)|
|Spring Cloud microservices|OpenFeign|
|Receiving requests|`@RestController` plus `ResponseEntity`|

**The big picture:** `HttpClient` is the plain-Java engine. `RestClient` and `WebClient` are Spring's friendly wrappers around engines like it, one blocking and one non-blocking. HTTP Interfaces sit on top of both and turn an API into a Java interface.






[[Java Back-End]]



