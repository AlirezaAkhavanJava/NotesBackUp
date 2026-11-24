
An **API** (Application Programming Interface) is a defined set of rules and endpoints that lets one piece of software talk to another without either side needing to know the other's internal implementation. It's a contract: here are the operations you can call, here's what you need to send, and here's what you'll get back.

You already work with APIs constantly without necessarily labeling them that way — every public method in a Java class is a tiny API, every Spring Data repository interface is an API over your database, and every `@RestController` endpoint you write is a web API that some other program (a frontend, a mobile app, another service) can call over HTTP.

Let's go through the main shapes an API takes, since "API" means something slightly different depending on the level you're looking at.

## 1. Library/Class-level API (in-process)

This is the simplest form: the public methods and classes a library exposes for you to call directly in your code.

```java
List<String> names = new ArrayList<>();
names.add("Alice");
names.add("Bob");
Collections.sort(names);
```

Here, `ArrayList` and `Collections` are part of the Java Collections Framework's API. You never see how `ArrayList` manages its internal backing array, and you don't need to — the API (`add`, `sort`, `get`, etc.) is the only thing you're allowed to depend on. The implementation can change between JDK versions, and your code keeps working as long as the API contract stays the same.

## 2. Web API (network-level, client/server)

This is usually what people mean when they just say "API" in a backend context — a way for a client (a browser, a mobile app, another backend service) to talk to your server over HTTP.

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    @GetMapping("/{id}")
    public ResponseEntity<UserDto> getUser(@PathVariable Long id) {
        // fetch and return
    }

    @PostMapping
    public ResponseEntity<UserDto> createUser(@RequestBody CreateUserRequest request) {
        // create and return
    }
}
```

A client never sees what's running behind your API — not that it's Spring Boot, not that PostgreSQL is the database, not how your service layer is organized. All it sees is three things: where to send the request (a URL like `/api/users/5`), how to send it (an HTTP method like `GET`), and what comes back (JSON shaped like a `UserDto`). That's the whole contract. REST is just one way of shaping that contract — GraphQL, gRPC, and SOAP are other ways of shaping the same client-server handshake, each with different rules for how the request and response look.

## 3. Third-party/external API

This is the same idea as #2, but it's someone else's server. If you call a weather service's API to get a forecast, or Stripe's API to charge a card, you're a _client_ making requests to someone else's web API. You get an API key, read their documentation for the available endpoints, and call them — again, without any knowledge of their internal server code.

#### The core idea across all three

In every case, an API draws a line: everything behind the line can change freely; everything in front of the line (the method signatures, the endpoints, the request/response formats) is the stable surface other code depends on. This is also exactly why interfaces, DTOs, and layered architecture matter in the Spring Boot code you've been working through — your `@RestController` methods, your repository interfaces, even your entity-to-DTO mappers are all ways of defining and protecting an API boundary so that changes on one side don't break the other side.


[[Spring Framework]]