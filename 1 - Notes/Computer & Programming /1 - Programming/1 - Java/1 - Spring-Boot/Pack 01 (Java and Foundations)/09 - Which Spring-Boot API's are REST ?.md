
Spring Boot is a general-purpose application framework — it gives you a way to wire up beans, start an embedded server, and expose endpoints over HTTP, messaging, or other protocols. REST, on the other hand, is an _architectural style_ for designing APIs: a set of conventions about how URLs, verbs, and status codes should behave. These are two different layers entirely, and the central thing to understand is that **Spring Boot never forces you into that style** — it just makes it easy to write HTTP endpoints, RESTful or not. Writing `@RestController` tells Spring "serialize responses as JSON/XML instead of rendering a view" — it says nothing about whether the API you build underneath is actually REST.

## Spring Boot can expose many things — only some are REST

A single Spring Boot application typically contains several different kinds of "API" at once, and conflating them is where the confusion starts:

|What it exposes|Mechanism|REST?|
|---|---|---|
|REST API|`@RestController` + Spring MVC/WebFlux, _designed RESTfully_|Yes, conditionally|
|RPC-style HTTP endpoints|`@RestController` with verb-shaped URLs|No — still just HTTP|
|Server-rendered pages|`@Controller` + Thymeleaf|No — returns HTML views|
|SOAP service|Spring Web Services|No|
|GraphQL API|Spring GraphQL|No|
|gRPC service|`grpc-spring-boot-starter`|No|
|WebSocket/STOMP|Spring WebSocket|No|
|Messaging consumer|Spring Kafka, JMS, AMQP|No|
|Actuator endpoints|Spring Boot Actuator|HTTP, not REST|
|Internal service layer|plain beans, interfaces|No — not networked at all|

Only the first row is REST, and even it isn't automatically — which is the part most people get wrong.

## `@RestController` is not a REST guarantee

`@RestController` is purely a serialization decision: it tells Spring to write the return value straight into the HTTP response body (as JSON, typically) instead of resolving a view template. It carries zero opinion about URL design or verb usage. You can write a fully non-RESTful API with it:

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

This works, returns JSON, and runs over HTTP — but it's RPC dressed as HTTP, not REST. Two tells: the URL path contains a verb (`createUser`, `getUserById`) instead of naming a resource, and the identifying data (`id`) travels as a query parameter instead of being part of the resource's path.

The RESTful version of the same functionality:

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

Nothing about the framework changed — same annotations, same dependencies. What changed is the design: the URL now identifies a **resource** (`/users/{id}`), and the HTTP verb (`GET`, `POST`) carries the meaning that used to be baked into the path's verb. That shift — from "function name in the URL" to "noun in the URL, verb in the HTTP method" — _is_ the defining difference between RPC-style HTTP and REST.

## Inside one "REST" app, most of the code isn't REST

Even an application whose public face is a REST API is mostly made of non-REST pieces internally:

- **REST controllers** — the actual external contract; this is the only REST part
- **Service classes** — a plain internal Java API, no HTTP involved
- **Repository interfaces** (Spring Data) — a persistence API, also not HTTP
- **Feign clients** — HTTP code that _consumes_ someone else's API; being a client of a REST API doesn't make your app's own boundary RESTful
- **Kafka/JMS listeners** — an asynchronous messaging API, a completely different paradigm from request/response
- **Actuator endpoints** (`/health`, `/metrics`) — operational HTTP, built for machine monitoring, not for resource manipulation

Calling all of this "the REST API" is a category error — it collapses "runs inside a Spring Boot app" and "is REST" into the same thing, when only the controller layer (and only if it's designed right) earns that label.

## Why the distinction matters in practice

Treating "Spring Boot API" and "REST API" as synonyms tends to cause three specific problems: you design RPC-shaped endpoints while believing you're doing REST, you overlook that your app is simultaneously exposing GraphQL or messaging interfaces that follow entirely different rules, and you end up unable to explain why your "REST API" doesn't behave the way REST is supposed to — caching badly, clients unable to retry safely, and so on — because it was never actually following REST's rules in the first place.

## In short

Spring Boot is a toolkit, not a protocol enforcer. It can produce REST APIs, SOAP services, GraphQL endpoints, gRPC services, messaging consumers, and server-rendered pages — all from the same framework, often in the same application. **Only the parts you deliberately design according to REST's conventions (resource-shaped URLs, correct verb semantics, proper status codes) are REST.** Everything else running through Spring Boot is just HTTP, or just code — not REST by default.


[[Spring Framework]]