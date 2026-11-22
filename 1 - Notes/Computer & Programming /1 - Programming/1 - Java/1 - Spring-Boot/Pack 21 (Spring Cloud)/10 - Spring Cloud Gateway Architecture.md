
Spring Cloud Gateway is the component you've referenced by name in nearly every lesson so far ("the Gateway routes to checkout-service, found via Eureka") without ever opening it up. Architecturally, it's not a simple reverse proxy with a routing table — it's built on a fully reactive, non-blocking stack (Spring WebFlux + Project Reactor + Netty), and that choice shapes almost everything about how it's structured and what it can and can't do.

## Why reactive, specifically — and what it rules out

A gateway sits in front of every request to your system, so its performance under high concurrent load matters more than almost any other component you'll build. A traditional servlet-based app handles one request per thread — under heavy concurrent load, that means a thread per in-flight request, and threads are expensive (memory, context-switching). Spring Cloud Gateway is built on Netty, an event-loop-based, non-blocking I/O runtime, so a small number of threads can hold thousands of in-flight requests simultaneously, each one just waiting on I/O (a downstream service responding) rather than blocking a dedicated thread for that whole duration.

The direct consequence: Spring Cloud Gateway requires the Netty runtime provided by Spring Boot and WebFlux, and it does not work in a traditional Servlet container or when packaged as a WAR. This isn't a minor deployment detail — it means a Gateway module in your project can't reuse synchronous, blocking code the way the rest of your Spring MVC services can. Familiar synchronous patterns and libraries you already know from elsewhere in Spring may not directly apply here, because the whole request path through the Gateway is reactive end to end.

## The three building blocks, precisely

A Route is the basic building block of the gateway, defined by an ID, a destination URI, a collection of predicates, and a collection of filters — a route is matched only if the combined predicate evaluates true. Concretely:

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: order_service_route
          uri: lb://order-service          # lb:// — resolved through LoadBalancer + Eureka, not a literal host
          predicates:
            - Path=/orders/**
            - Method=GET,POST
          filters:
            - StripPrefix=1
            - name: CircuitBreaker
              args:
                name: orderServiceCB
                fallbackUri: forward:/fallback/orders
```

`lb://order-service` is the detail that ties everything you already know into this: that scheme prefix tells the Gateway "don't treat this as a literal address — resolve it through the discovery/load-balancing chain," reusing the exact Eureka + LoadBalancer machinery from your earlier lessons rather than the Gateway having its own separate discovery logic.

A predicate is implemented as a Java functional interface over the request — in the reactive Gateway, a `Predicate<ServerWebExchange>`. Built-in factories cover the common cases you'd expect — `Path`, `Method`, `Header`, `Cookie`, `Host` — and these can be combined with logical AND to require several conditions to all hold before a route matches. You can write a custom one when none of the built-ins fit:

```java
@Component
public class ApiKeyPredicateFactory extends AbstractRoutePredicateFactory<ApiKeyPredicateFactory.Config> {

    public ApiKeyPredicateFactory() {
        super(Config.class);
    }

    @Override
    public Predicate<ServerWebExchange> apply(Config config) {
        return exchange -> {
            String key = exchange.getRequest().getHeaders().getFirst("X-API-Key");
            return config.getRequiredKey().equals(key);
        };
    }

    public static class Config {
        private String requiredKey;
        public String getRequiredKey() { return requiredKey; }
        public void setRequiredKey(String requiredKey) { this.requiredKey = requiredKey; }
    }
}
```

A Filter is an instance of GatewayFilter constructed by a specific factory, and it can modify the request or response before or after the proxy call is actually made. That "before or after" split isn't incidental phrasing — it's a structural feature of how every filter is written:

```java
@Component
public class RequestLoggingGatewayFilterFactory extends AbstractGatewayFilterFactory<Object> {

    @Override
    public GatewayFilter apply(Object config) {
        return (exchange, chain) -> {
            System.out.println("PRE: " + exchange.getRequest().getURI());  // runs before the proxy call

            return chain.filter(exchange)
                .then(Mono.fromRunnable(() ->
                    System.out.println("POST: " + exchange.getResponse().getStatusCode()) // runs after
                ));
        };
    }
}
```

Every "pre" filter's logic across the whole chain runs first, then the actual proxy request is sent, and only afterward does every filter's "post" logic run — which is why the single filter above has code both before and after the `chain.filter(exchange)` call rather than being split into two separate filter classes.

## The request's actual path through the Gateway

Clients make requests to the Gateway; if the Gateway Handler Mapping determines a request matches a route, it's sent to the Gateway Web Handler, which runs the request through a filter chain specific to that request. Spelled out as a sequence:

```
Client request
   ↓
Gateway Handler Mapping   — checks every configured route's predicates, finds the first match
   ↓
Gateway Web Handler       — builds the filter chain specific to THIS matched route
   ↓
[pre-filters run, in order]
   ↓
Proxy request sent to the resolved backend (via lb:// → LoadBalancer → Eureka)
   ↓
[post-filters run, in order]
   ↓
Response returned to client
```

This matching happens as part of Spring WebFlux's own HandlerMapping infrastructure — the Gateway isn't bolting routing on top of WebFlux from the outside, it's implemented as a WebFlux handler mapping itself, which is another consequence of the reactive foundation: routing, filtering, and the eventual proxy call are all non-blocking operations chained together with Reactor's `Mono`/`Flux` types, not sequential blocking steps.

## Global filters vs. per-route filters

The `StripPrefix` and `CircuitBreaker` filters in the YAML example above are scoped to one route. Some concerns — authentication, logging, correlation-ID propagation for tracing — need to run on _every_ route without repeating the same filter block in every route definition. `GlobalFilter` is the mechanism for that:

```java
@Component
public class CorrelationIdGlobalFilter implements GlobalFilter, Ordered {

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String correlationId = UUID.randomUUID().toString();
        ServerHttpRequest mutated = exchange.getRequest().mutate()
            .header("X-Correlation-Id", correlationId)
            .build();
        return chain.filter(exchange.mutate().request(mutated).build());
    }

    @Override
    public int getOrder() {
        return -1; // lower runs earlier; ordering across both global and per-route filters is explicit
    }
}
```

This is the kind of filter that ties directly back into your tracing lesson — attaching a correlation ID at the single entry point every external request passes through is exactly how a trace ID starts propagating through the rest of the call chain you mapped out in the microservices-together lesson.

## A related concept: Gateway Server MVC

Alongside the original reactive Gateway, there's a Gateway Server MVC variant built on the Spring WebMvc.fn functional style, where a route's predicate is a RequestPredicate over a ServerRequest and a filter is a HandlerFilterFunction, rather than the reactive types above. The architectural concepts — route, predicate, filter, pre/post filter chain — are identical; what changes is the runtime underneath: this variant runs on a traditional servlet container instead of requiring Netty/WebFlux, which matters specifically for teams whose existing codebase is blocking/servlet-based and don't want to introduce a second, reactive runtime model just for the Gateway module. You don't need to learn it in depth now — just recognize that if you see `spring-cloud-starter-gateway-mvc` instead of `spring-cloud-starter-gateway` in a project, it's the same concepts you just learned, running on the servlet stack instead of Netty.


[[Spring Framework]]
