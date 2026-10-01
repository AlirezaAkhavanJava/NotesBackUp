
Spring Boot is a general-purpose framework for building Java applications. It can *host* REST APIs, but it also supports many other kinds of APIs — and even inside a single Spring Boot app, you'll usually have several.

The key confusion is that Spring Boot makes it very easy to write HTTP endpoints, but **HTTP ≠ REST**. REST is a design style; Spring Boot is just a tool.

## What Spring Boot can expose

| Type | Spring Boot support | Is it REST? |
|------|---------------------|-------------|
| REST API | `@RestController`, Spring MVC/WebFlux | Yes, *if* designed RESTfully |
| Plain HTTP / RPC-style API | `@Controller`, `@RequestMapping` | No — it's just HTTP |
| Server-rendered web app | `@Controller` + Thymeleaf/JSP | No — it's a UI |
| SOAP web service | Spring Web Services | No |
| GraphQL API | Spring GraphQL | No |
| gRPC API | `grpc-spring-boot-starter` | No |
| WebSocket / STOMP | Spring WebSocket | No |
| Messaging API | Spring Kafka, JMS, AMQP, Spring Cloud Stream | No |
| Actuator endpoints | Spring Boot Actuator | HTTP, but not really REST |
| Internal Java API | `@Service`, interfaces, beans | No — not web at all |

## `@RestController` doesn't automatically mean REST

This is a common trap. You can write a `@RestController` that is *not* RESTful:

```java
@RestController
public class UserController {

    @PostMapping("/createUser")
    public String createUser(@RequestParam String name) {
        // ...
        return "created";
    }

    @GetMapping("/getUserById")
    public User getUserById(@RequestParam Long id) {
        // ...
    }
}
```

This is HTTP, but it's **RPC-style**, not REST. The URLs are verbs (`createUser`, `getUserById`), state is passed as query params instead of using resource paths, and it doesn't follow REST conventions.

A RESTful version would look like:

```java
@RestController
@RequestMapping("/users")
public class UserController {

    @PostMapping
    public ResponseEntity<User> create(@RequestBody User user) { ... }

    @GetMapping("/{id}")
    public ResponseEntity<User> get(@PathVariable Long id) { ... }
}
```

Same framework, same annotations — different design.

## Even in a "REST" Spring Boot app, not everything is REST

A typical Spring Boot application might contain:

- **REST controllers** — the public HTTP API
- **Service classes** — an internal Java API between layers
- **Repository interfaces** — a persistence API (Spring Data)
- **Feign clients** — code that *calls* someone else's REST API
- **Kafka listeners** — a messaging API
- **Actuator endpoints** — operational HTTP endpoints like `/health`, `/metrics`

Only the first category is a REST API, and even then only if it follows REST principles.

## Why this matters

If you assume "Spring Boot API = REST API," you'll:

- Design RPC-style endpoints and call them REST
- Miss that your app also exposes GraphQL, SOAP, or messaging
- Struggle to explain why your "REST API" doesn't behave like one

The framework doesn't enforce REST. It gives you the tools; you decide the style.

## TL;DR

Spring Boot is a framework, not a protocol. It can build REST APIs, but it can also build SOAP services, GraphQL APIs, gRPC services, messaging consumers, server-rendered web apps, and plain HTTP endpoints. **Only the parts you deliberately design as REST are REST.** The rest are just APIs — or just HTTP.


[[0 - Spring + Spring Boot]]