
# HTTP Interfaces in Spring: describe an API, don't code it

Calling an API with `RestClient` means writing the same chain again and again: `.get().uri(...).retrieve().body(...)`. It works, but with 15 endpoints it gets repetitive and hard to read.

**HTTP Interfaces let you write a plain Java interface instead.** You describe what the API looks like, and Spring writes the code that makes the real HTTP calls. You never write an implementation class.

If you've used Spring Data repositories, it's the same idea. There you declare `findByName(...)` and Spring builds the implementation. Here you declare `getUser(...)` and Spring builds the HTTP call.

---

## The big picture

```
Your code  ->  UserClient (interface)  ->  Spring-generated proxy  ->  RestClient  ->  HTTP request
```

|Piece|Job|
|---|---|
|**Your interface**|Describes the endpoints (path, verb, parameters, return type)|
|**Proxy**|A fake object Spring generates that implements your interface|
|**Adapter**|A bridge that connects the proxy to a real client (`RestClient`, `WebClient`, or `RestTemplate`)|
|**The client**|Does the real network work|

**Related concept, dynamic proxies:** A proxy is an object created at runtime that pretends to be your interface. When you call a method on it, it intercepts the call, reads the annotations on that method, and runs the logic you'd otherwise write by hand. Java has supported this for years (`java.lang.reflect.Proxy`), and Spring builds on it.

---

## Step 1: Define the interface

```java
@HttpExchange("/users")
public interface UserClient {

    @GetExchange("/{id}")
    User getUser(@PathVariable long id);

    @GetExchange
    List<User> search(@RequestParam String name);

    @PostExchange
    User create(@RequestBody User user);

    @PutExchange("/{id}")
    User update(@PathVariable long id, @RequestBody User user);

    @DeleteExchange("/{id}")
    void delete(@PathVariable long id);
}
```

**Line by line:**

- `@HttpExchange("/users")` on the interface sets a shared URL prefix. Every method starts with `/users`.
- `@GetExchange("/{id}")` means "send a GET to `/users/{id}`". The `{id}` is a placeholder.
- `@PathVariable long id` fills the placeholder. Call `getUser(5)` and the request goes to `/users/5`.
- `@GetExchange` with no path hits `/users` itself. `@RequestParam String name` adds `?name=...`.
- `@RequestBody User user` turns your object into JSON for the request body.
- `void delete(...)` means "I don't care about the response body".

The annotations match the controller ones you already know (`@PathVariable`, `@RequestParam`, `@RequestBody`), so there's very little new to learn.

---

## Step 2: Turn the interface into a working object

How you do this depends on your Spring version.

|Version|What's available|
|---|---|
|Spring 6.0 (Boot 3.0)|`HttpServiceProxyFactory` with `WebClient`|
|Spring 6.1 (Boot 3.2)|Adds `RestClient` support, so blocking apps can use it|
|Spring 7 (Boot 4)|`@ImportHttpServices` is new and registers client proxies with far less setup|

### Option A: Manual setup (works on Boot 3.2+)

```java
@Configuration
public class ClientConfig {

    @Bean
    UserClient userClient(RestClient.Builder builder) {
        RestClient restClient = builder
                .baseUrl("https://api.example.com")
                .build();

        RestClientAdapter adapter = RestClientAdapter.create(restClient);

        HttpServiceProxyFactory factory =
                HttpServiceProxyFactory.builderFor(adapter).build();

        return factory.createClient(UserClient.class);
    }
}
```

**Line by line:**

- Injecting `RestClient.Builder` gives you Boot's pre-configured builder, with JSON support already set up.
- `baseUrl(...)` is the host. Combined with `/users/{id}` from your interface, you get the full URL.
- `RestClientAdapter.create(...)` wraps the client so the factory can use it.
- `HttpServiceProxyFactory.builderFor(adapter).build()` creates the factory, the machine that makes proxies.
- `createClient(UserClient.class)` produces the proxy. Returning it from a `@Bean` method makes it injectable.

### Option B: The Spring 7 / Boot 4 way

With many clients, Option A means one `@Bean` method per interface. Spring 7 removes that. You list your interfaces, and Spring registers them as beans:

```java
@SpringBootApplication
@ImportHttpServices(group = "users", types = UserClient.class)
public class MyApp { }
```

Then set the base URL in `application.yml`:

```yaml
spring:
  http:
    serviceclient:
      users:
        base-url: https://api.example.com
```

**What's happening:**

- A **group** is a named bundle of interfaces that share one client setup (same base URL, same timeouts).
- `@ImportHttpServices` says "make a proxy bean for these interfaces, in this group".
- Spring Boot 4.0 applies client setup for each group automatically and offers group-specific properties, which is why a few YAML lines replace the whole config class.
- You can also scan a package with `basePackages = "com.myapp.clients.github"` instead of listing types.

One caution: the exact property keys were still being settled while this feature was developed, and sources I checked show slightly different names. Confirm them in the Spring Boot reference for your exact version.

**Need to customize a group?** Add a configurer bean. This one adds a header to every call in the `users` group:

```java
@Bean
RestClientHttpServiceGroupConfigurer groupConfigurer() {
    return groups -> groups.filterByName("users")
            .forEachClient((group, builder) ->
                    builder.defaultHeader("X-App-Name", "my-app"));
}
```

---

## Step 3: Use it

```java
@Service
public class UserService {

    private final UserClient userClient;

    public UserService(UserClient userClient) {
        this.userClient = userClient;
    }

    public String greet(long id) {
        User user = userClient.getUser(id);
        return "Hello, " + user.name() + "!";
    }
}
```

Look at what's missing: there are no URLs, no JSON parsing and no client code. It reads like calling a local method, and that's the benefit.

---

## What can you put on a method?

### Annotations that describe the request

|Annotation|Meaning|
|---|---|
|`@GetExchange` / `@PostExchange` / `@PutExchange` / `@PatchExchange` / `@DeleteExchange`|Shortcuts for a given HTTP verb|
|`@HttpExchange(method = "GET", url = "/x")`|The general form the shortcuts are built on|
|`contentType`, `accept` (attributes)|Set the `Content-Type` and `Accept` headers|

### Parameters that fill in the request

|Parameter|What it does|
|---|---|
|`@PathVariable`|Fills a `{placeholder}` in the URL|
|`@RequestParam`|Adds a query parameter. A `Map` adds many at once|
|`@RequestHeader`|Adds a header to this one call|
|`@RequestBody`|Becomes the JSON body|
|`@RequestPart`|One part of a multipart upload|
|`@CookieValue`|Sends a cookie|
|`URI`|Replaces the whole URL, useful for "next page" links|
|`HttpMethod`|Picks the verb at runtime|

**A small note on names:** `@PathVariable long id` relies on Java remembering parameter names. Spring Boot's Maven and Gradle plugins turn that on for you. If you ever see "name not specified" errors, write `@PathVariable("id")` explicitly.

### Return types: what do you want back?

|Return type|You get|
|---|---|
|`User`|Just the body, converted to your class|
|`List<User>`|A JSON array converted to a list|
|`void`|Nothing, but errors are still detected|
|`ResponseEntity<User>`|Status, headers **and** body|
|`ResponseEntity<Void>`|Status and headers only|
|`HttpHeaders`|Only the response headers|
|`Mono<User>` / `Flux<User>`|Reactive results (needs the `WebClient` adapter)|

Here's an example that reads more than the body:

```java
@PostExchange
ResponseEntity<User> createWithDetails(@RequestBody User user);
```

```java
ResponseEntity<User> response = userClient.createWithDetails(newUser);
URI location = response.getHeaders().getLocation();
HttpStatusCode status = response.getStatusCode();
User body = response.getBody();
```

Use `ResponseEntity` when the status code or a header matters, like the `Location` header after a creation.

---

## Headers, auth and per-call details

Per-call headers go in as parameters:

```java
@GetExchange("/me")
User me(@RequestHeader("Authorization") String bearerToken);
```

Headers that go on **every** call belong on the client builder, so you don't repeat them:

```java
RestClient restClient = builder
        .baseUrl("https://api.example.com")
        .defaultHeader("Accept", "application/json")
        .requestInterceptor((request, body, execution) -> {
            request.getHeaders().setBearerAuth(tokenProvider.getToken());
            return execution.execute(request, body);
        })
        .build();
```

An **interceptor** is a small piece of code that runs on every request. Here it adds a fresh token before the call goes out. Logging and retries work the same way.

---

## Handling errors

By default, a 4xx or 5xx response makes the call **throw an exception**, the same behavior as `RestClient`:

```java
try {
    userClient.getUser(99);
} catch (HttpClientErrorException.NotFound e) {
    // 404: no such user
} catch (HttpServerErrorException e) {
    // 5xx: the other server is having trouble
}
```

To translate errors in one place, set a handler on the builder:

```java
RestClient restClient = builder
        .baseUrl("https://api.example.com")
        .defaultStatusHandler(HttpStatusCode::is4xxClientError, (req, res) -> {
            throw new ApiException("Client error: " + res.getStatusCode());
        })
        .build();
```

Then the rest of your app deals with your own `ApiException` and doesn't need to know HTTP details.

---

## Timeouts

A client with no timeout can hang your app when the other side is slow, so always set them. In Boot 4, group-level properties cover this. Another option is to configure the builder yourself, using a request factory with connect and read timeouts. Spring's reference docs have exact examples for your version.

---

## Testing

Because your client is just an **interface**, testing is easy. The simplest approach mocks it:

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock UserClient userClient;
    @InjectMocks UserService userService;

    @Test
    void greetsUser() {
        when(userClient.getUser(1L)).thenReturn(new User(1L, "Ada"));
        assertEquals("Hello, Ada!", userService.greet(1L));
    }
}
```

To check that the HTTP details are right (URL, JSON, headers), use `MockRestServiceServer`:

```java
RestClient.Builder builder = RestClient.builder().baseUrl("http://localhost");
MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();

server.expect(requestTo("http://localhost/users/1"))
      .andRespond(withSuccess("""
              {"id": 1, "name": "Ada"}
              """, MediaType.APPLICATION_JSON));

UserClient client = HttpServiceProxyFactory
        .builderFor(RestClientAdapter.create(builder.build()))
        .build()
        .createClient(UserClient.class);

assertEquals("Ada", client.getUser(1).name());
server.verify();
```

You build the client against a fake server that returns the JSON you chose, so your test never touches the network.

---

## Reactive version

With WebFlux, swap the adapter and return `Mono` or `Flux`:

```java
WebClient webClient = WebClient.builder()
        .baseUrl("https://api.example.com")
        .build();

HttpServiceProxyFactory factory = HttpServiceProxyFactory
        .builderFor(WebClientAdapter.create(webClient))
        .build();
```

```java
@HttpExchange("/users")
public interface ReactiveUserClient {

    @GetExchange("/{id}")
    Mono<User> getUser(@PathVariable long id);

    @GetExchange
    Flux<User> all();
}
```

The interface style stays the same. Only the return types and the adapter change.

---

## Common questions and pitfalls

- **Can the server and client share one interface?** Yes, because `@HttpExchange` annotations can be shared between client and server. Teams sometimes put the interface in a shared module, but be careful about coupling services too tightly.
- **Is it good for load balancing and circuit breakers?** Spring Cloud 2025.1 supports load-balancing and circuit-breaking for HTTP service groups.
- **Is this replacing OpenFeign?** For new projects, mostly yes. Spring's recommended direction is to move to the built-in HTTP Service Client. Feign still works in existing Spring Cloud projects, so there's no rush to rewrite working code.
- **Is `RestTemplate` still the foundation?** No. Spring Framework 7 deprecates `RestTemplate` in favor of `RestClient`, and HTTP Interfaces sit on top of the modern clients.
- **Is it a good fit for everything?** If you need unusual streaming behavior or very fine control over one request, drop down to `RestClient` directly. The two work well side by side.

---

## Quick recap

1. **Declare** an interface with `@HttpExchange` and the verb shortcuts.
2. **Create** the proxy: manually with `HttpServiceProxyFactory` on Boot 3.2+, or with `@ImportHttpServices` on Boot 4.
3. **Inject** it and call it like any other Java method.
4. **Choose** the return type based on what you need: body only, or `ResponseEntity` for status and headers.
5. **Configure** auth, timeouts and error handling once, on the client.




[[Java Back-End]]