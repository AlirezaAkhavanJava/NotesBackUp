
An **API Gateway** is a single entry point that sits in front of a set of microservices. Instead of a client calling `todo-service` directly and `user-service` directly and `order-service` directly — each with its own host, port and security logic — the client calls one address, and the gateway decides where each request actually goes. On top of that routing job, the gateway is also the natural place to put things every request needs anyway: checking a JWT, adding a tracking header, limiting how many requests per second a client can make, logging what came through. Doing that once at the gateway means none of your individual services have to repeat that logic themselves.

**Spring Cloud Gateway** is Spring's implementation of this idea. It's built on Spring WebFlux, meaning it's reactive and non-blocking by design — a gateway sits in the path of _every_ request in your system, so it needs to handle a lot of concurrent traffic without tying up a thread per request the way a traditional blocking servlet would.

## Routes: the core building block

Everything in Spring Cloud Gateway revolves around a **route**. A route is just: "if a request matches this condition, send it here, and optionally do these things to it along the way." You define routes in YAML:

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: todo-service
          uri: lb://todo-service
          predicates:
            - Path=/api/todos/**
          filters:
            - AddRequestHeader=X-Request-Source, Gateway
```

Each route has three parts:

- **`id`** — just a name for the route, for your own reference.
- **`predicates`** — the condition that decides whether this route applies. `Path=/api/todos/**` means "any request whose path starts with `/api/todos/`."
- **`filters`** — things done to the request (or response) as it passes through. `AddRequestHeader` tags the outgoing request with a header, which is useful downstream for knowing "this came through the gateway, not directly."

`uri: lb://todo-service` is where service discovery comes in: `lb://` tells the gateway "don't resolve this as a literal address — ask the load balancer (backed by Eureka) for a live instance of `todo-service`." This is why the gateway doesn't need to know IPs or ports; Eureka is already tracking where each service instance actually lives.

## Writing a custom filter: JWT validation

Built-in filters like `AddRequestHeader` only go so far. For something like validating a JWT on every incoming request, you write a custom `GatewayFilterFactory`:

```java
@Component
public class JwtFilter extends AbstractGatewayFilterFactory<JwtFilter.Config> {
    public JwtFilter() {
        super(Config.class);
    }

    @Override
    public GatewayFilter apply(Config config) {
        return (exchange, chain) -> {
            String authHeader = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
                return exchange.getResponse().setComplete();
            }

            String token = authHeader.substring(7);
            try {
                Jwts.parser().setSigningKey("secret-key".getBytes()).build().parseClaimsJws(token);
                return chain.filter(exchange);
            } catch (JwtException e) {
                exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
                return exchange.getResponse().setComplete();
            }
        };
    }

    public static class Config {}
}
```

A few things here are specific to writing gateway filters, as opposed to ordinary Spring code:

- **`exchange`** is a `ServerWebExchange` — in reactive WebFlux, this one object bundles both the request and the response together (instead of separate `HttpServletRequest`/`HttpServletResponse` objects like in blocking Spring MVC).
- **`chain.filter(exchange)`** is how you say "this request passed my check, let it continue to the next filter (or to the actual service)." If you don't call it, the request stops here — which is exactly what happens in both branches above when the token is missing or invalid: the response is completed immediately, and `chain.filter` is never reached.
- **The inner `Config` class** exists because `AbstractGatewayFilterFactory` is a generic factory — it lets you pass configuration arguments to the filter from YAML (e.g. `- JwtFilter: someArg`). Here it's empty because this filter doesn't need any config, but the factory pattern still requires the class to exist.

Once registered as a bean, you reference it by name in YAML, right alongside the built-in filters:

```yaml
filters:
  - AddRequestHeader=X-Request-Source, Gateway
  - JwtFilter
```

## Rate limiting and circuit breakers

Two more filters are common enough to be worth knowing by name:

**`RequestRateLimiter`** caps how many requests a client can send per second, backed by Redis:

```yaml
filters:
  - name: RequestRateLimiter
    args:
      redis-rate-limiter.replenishRate: 10
      redis-rate-limiter.burstCapacity: 20
```

`replenishRate` is the steady allowed rate (10/sec here); `burstCapacity` is how far above that a client can briefly spike before being throttled.

**`CircuitBreaker`** protects the gateway from a downstream service that's failing or slow, by routing to a fallback instead of waiting or erroring out:

```yaml
filters:
  - name: CircuitBreaker
    args:
      name: todoService
      fallbackUri: forward:/fallback
```

If calls to `todo-service` start failing past a threshold, the circuit "opens" and requests get redirected to `/fallback` instead of hitting the struggling service — this is the same circuit breaker pattern used generally in distributed systems (Resilience4j implements it here), not something gateway-specific.

## Putting the flow together

With routing, Eureka, and the JWT filter in place, a request's journey looks like this:

1. Client sends `POST /api/todos` to the gateway's address.
2. The gateway matches the path against its routes and finds the `todo-service` route.
3. The `JwtFilter` checks the `Authorization` header before anything else proceeds.
4. If valid, `lb://todo-service` is resolved via Eureka to an actual running instance.
5. The request is forwarded there, and the response flows back through the same filter chain to the client.

This is the same pattern you've already seen with Config Server and Eureka individually — the gateway is just another Spring Boot application that happens to register with Eureka _and_ consume it, while sitting in front of everything else.



[[Spring Framework]]