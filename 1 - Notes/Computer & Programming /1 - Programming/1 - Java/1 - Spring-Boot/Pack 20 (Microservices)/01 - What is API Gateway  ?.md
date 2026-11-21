
# API Gateway

An API gateway is a single entry point that sits in front of all your backend services. Instead of a client (a browser, a mobile app) knowing the address of every service and calling each one directly, the client talks to one address: the gateway. The gateway looks at each incoming request, decides which service should handle it, forwards it, and sends the response back.

It matters because once you have many services (as in the microservices lesson), you need one place to handle the things every request needs: routing, authentication, rate limiting, logging. Without a gateway, every service would have to repeat that work, and every client would need to know your internal layout.

---

## The picture

Without a gateway, the client must know every service:

```
Client ──► order-service     (localhost:8080)
Client ──► inventory-service (localhost:8081)
Client ──► user-service      (localhost:8082)
```

With a gateway, the client knows one address:

```
                          ┌──► order-service     (8080)
Client ──► Gateway (80) ──┼──► inventory-service (8081)
                          └──► user-service      (8082)
```

The client calls `GET /stock/ABC123` on the gateway. The gateway sees the path starts with `/stock`, forwards it to inventory-service, and returns the answer. The client never learns that port 8081 exists.

Two things follow from this:

- You can move, rename, split, or scale services without changing any client.
- Your internal services can be hidden from the internet, and only the gateway is exposed.

---

## What a gateway does

**1. Routing.** Match a URL pattern and forward to the right service. This is the core job.

**2. Authentication.** Check the JWT once at the gateway, instead of in every service. This links back to your JWT filter chain: the same idea, but placed at the front door. Valid requests pass through, and invalid ones get a `401` before they ever reach a service.

**3. Rate limiting.** Stop one client from sending 10,000 requests per second.

**4. Load balancing.** If there are three copies of inventory-service, spread the requests between them.

**5. Cross-cutting concerns.** CORS headers, logging, adding a request ID to trace a call across services, and so on.

**6. Aggregation (sometimes).** One client request becomes several internal calls, and the gateway merges the results. This saves a mobile app from making five round trips.

---

## Spring Cloud Gateway in code

Spring Cloud Gateway is the standard gateway in the Spring world. It is its own Spring Boot project. Add the dependency:

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-gateway-server-webflux</artifactId>
</dependency>
```

(The artifact name has changed between Spring Cloud versions, so check the one that matches your Spring Boot version.)

### Routes in `application.yml`

```yaml
server:
  port: 8000

spring:
  cloud:
    gateway:
      routes:
        - id: order-route
          uri: http://localhost:8080
          predicates:
            - Path=/orders/**

        - id: inventory-route
          uri: http://localhost:8081
          predicates:
            - Path=/stock/**
```

Reading it line by line:

- `server.port: 8000` is the one port clients use.
- Each entry under `routes` is one rule.
- `id` is just a name for the route.
- `uri` is where matching requests are sent.
- `predicates` are the conditions. `Path=/orders/**` means "any URL that starts with `/orders`". `**` matches any remaining path.

So `GET http://localhost:8000/stock/ABC123` is forwarded to `http://localhost:8081/stock/ABC123`.

### Filters

A **predicate** decides _whether_ a route matches. A **filter** changes the request or response _on the way through_:

```yaml
        - id: order-route
          uri: http://localhost:8080
          predicates:
            - Path=/api/orders/**
          filters:
            - StripPrefix=1
            - AddRequestHeader=X-Source, gateway
```

- `StripPrefix=1` removes the first path segment. The client calls `/api/orders/5`, but order-service receives `/orders/5`. This lets you use a public `/api` prefix without changing your services.
- `AddRequestHeader` adds a header to every forwarded request, so the service knows the call came through the gateway.

### The same route in Java

You can define routes in code instead of YAML:

```java
@Configuration
public class GatewayConfig {

    @Bean
    public RouteLocator routes(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("order-route", r -> r
                        .path("/orders/**")
                        .uri("http://localhost:8080"))
                .route("inventory-route", r -> r
                        .path("/stock/**")
                        .uri("http://localhost:8081"))
                .build();
    }
}
```

- `@Configuration` and `@Bean` are the same ideas you know from the configuration class lesson. The `RouteLocator` bean is what the gateway reads to learn its routes.
- `r.path(...).uri(...)` is the Java version of `predicates` and `uri` from the YAML.

Use YAML for simple routing, and Java when you need logic that YAML can't express.

### A custom filter for JWT

Here is a simple global filter that rejects requests without a bearer token:

```java
@Component
public class AuthFilter implements GlobalFilter, Ordered {

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String header = exchange.getRequest()
                .getHeaders()
                .getFirst(HttpHeaders.AUTHORIZATION);

        if (header == null || !header.startsWith("Bearer ")) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }

        return chain.filter(exchange);
    }

    @Override
    public int getOrder() {
        return -1;
    }
}
```

- `GlobalFilter` means this filter runs for **every** route.
- `ServerWebExchange` holds both the request and the response. Spring Cloud Gateway is reactive (built on WebFlux), so it uses this instead of `HttpServletRequest`.
- We read the `Authorization` header. If it is missing or isn't `Bearer ...`, we set status `401` and finish the response. The request never reaches a service.
- `chain.filter(exchange)` passes the request on to the next filter, and eventually to the service.
- `Mono<Void>` is the reactive "this will complete later" type. You don't need to master it yet. Just know the filter returns it instead of `void`.
- `getOrder() = -1` makes this run early.

A real version would also **validate** the token's signature with your `JwtService` logic, not only check that the header exists.

---

## Gateway vs the other things it gets confused with

||What it does|
|---|---|
|**API Gateway**|Routes and protects requests to _your own_ services. Works at the application level (paths, headers, tokens).|
|**Reverse proxy (Nginx)**|Forwards requests to a server. A gateway is a reverse proxy with more application awareness. Nginx can do simple gateway work.|
|**Load balancer**|Spreads traffic across copies of the _same_ service. A gateway often does this too, but its main job is choosing _which service_.|

In practice they are often stacked: Nginx at the edge for TLS and static files, then Spring Cloud Gateway behind it for routing and auth.

---

## The costs

- **A single point of failure.** If the gateway is down, everything is down. You usually run several copies of it.
- **An extra network hop.** Every request is a little slower.
- **A bottleneck risk.** If you put too much logic in the gateway, it turns into a mini monolith. Keep it to routing and cross-cutting concerns, and leave business logic in the services.

---

## Two related concepts, very briefly

**Backend for Frontend (BFF):** Instead of one gateway for everyone, you build one gateway per client type, such as one for the web app and one for the mobile app. Each returns exactly the data shape that client wants.

**Service discovery:** Instead of writing `http://localhost:8081` in the route, you write `lb://inventory-service`, and the gateway asks a registry (such as Eureka) where that service currently lives. This is what lets you add and remove copies of services without editing routes.

---

## Summary

- An API gateway is the single front door to your microservices.
- Its core job is routing by URL, and it also handles authentication, rate limiting, load balancing, and logging.
- In Spring, you use Spring Cloud Gateway, with routes made of an `id`, a `uri`, `predicates` (when to match), and `filters` (what to change).
- It is similar to Nginx but understands your application, and the two are often used together.
- Keep it thin: routing and shared concerns only.





[[Spring Framework]]