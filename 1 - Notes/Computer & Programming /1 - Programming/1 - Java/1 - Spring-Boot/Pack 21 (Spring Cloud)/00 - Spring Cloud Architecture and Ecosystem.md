

Spring Cloud is the umbrella project that bolts the missing pieces of **distributed systems engineering** onto Spring Boot. Spring Boot alone gives you one well-packaged application. The moment you split that into many services talking over the network, you inherit a pile of problems that have nothing to do with your business logic: where is service B right now, what happens when it's slow or down, how do all these services share configuration, how do you trace one request across five services, how do they talk to each other without hardcoding URLs everywhere. Spring Cloud is a collection of sub-projects, each solving exactly one of these problems, designed to be mixed and matched.

You've already learned four of the big pieces — the **API gateway**, **service registry (Eureka)**, **Config Server**, and **Zipkin/tracing** — and how they fit together. This lesson maps out the rest of the ecosystem around them, and ties the whole thing into one coherent architecture.

## The problem list every microservice architecture has to solve

Before naming projects, it helps to see the actual list of problems, because every Spring Cloud sub-project exists to answer exactly one line of this list:

1. **Where is the service I want to call?** → service discovery (Eureka — you know this)
2. **How do I call it without writing raw `RestTemplate`/`WebClient` boilerplate everywhere?** → declarative HTTP clients (OpenFeign)
3. **If there are 3 instances of that service, which one do I hit?** → client-side load balancing (Spring Cloud LoadBalancer)
4. **What happens when that service is slow or down?** → resilience patterns (Spring Cloud Circuit Breaker / Resilience4j)
5. **Where does shared config live, and how do all services get it without redeploying?** → Config Server (you know this)
6. **How do I push a config change to every running instance at once?** → Spring Cloud Bus
7. **How do external clients reach the right internal service through one door?** → API Gateway (you know this)
8. **How do I follow one request across five services when something breaks?** → distributed tracing (you know this)
9. **How do services communicate asynchronously instead of request/response?** → Spring Cloud Stream (messaging)
10. **How do I make sure a contract change in one service doesn't silently break its consumers?** → Spring Cloud Contract

Everything below is just this list, expanded.

## The pieces you already know, positioned on the map

Quick orientation, not a re-teach: **Eureka** answers "where is it," **Config Server** answers "what's my config," the **Gateway** answers "how does the outside world get in," and **Zipkin** answers "what happened to my request." These four are the skeleton. What follows fills in the muscle — the actual service-to-service communication and failure handling.

## Spring Cloud OpenFeign — declarative service-to-service calls

Without Feign, calling another service means writing `RestTemplate` or `WebClient` code by hand for every single call: building the URL, serializing the request, handling the response, catching exceptions. Feign lets you declare that call as a Java interface and Spring generates the implementation at runtime.

```java
@FeignClient(name = "order-service") // matches the app's Eureka registration name
public interface OrderClient {

    @GetMapping("/orders/{id}")
    OrderDto getOrder(@PathVariable("id") Long id);

    @PostMapping("/orders")
    OrderDto createOrder(@RequestBody CreateOrderRequest request);
}
```

```java
@Service
public class CheckoutService {

    private final OrderClient orderClient;

    public CheckoutService(OrderClient orderClient) {
        this.orderClient = orderClient;
    }

    public OrderDto placeOrder(CreateOrderRequest req) {
        return orderClient.createOrder(req); // looks like a local method call
    }
}
```

`name = "order-service"` is resolved through Eureka — Feign asks the registry "where is order-service," gets back a list of live instances, and sends the request. You write code that reads like a local method call; Feign handles the HTTP underneath. This is the layer that actually sits on top of service discovery — Eureka tells Feign _where_, Feign does the _calling_.

## Spring Cloud LoadBalancer — picking which instance

If `order-service` has three running instances registered in Eureka, something has to decide which one gets this particular call. That's Spring Cloud LoadBalancer. By default it round-robins across healthy instances, and it's the component Feign (and `WebClient`/`RestTemplate`, if you annotate them with `@LoadBalanced`) delegates to automatically. You rarely configure it directly — it's working silently every time Feign picks an instance — but it's worth knowing it's a distinct piece, because it's what makes "service discovery" actually useful instead of just a lookup table.

## Spring Cloud Circuit Breaker (Resilience4j) — surviving failure

This is the piece that stops one slow or dead service from taking down everything that calls it. Without it: if `order-service` hangs, every thread in `checkout-service` that's waiting on an order call piles up, and eventually `checkout-service` runs out of threads too — one failure cascades into many.

```java
@Service
public class CheckoutService {

    private final OrderClient orderClient;
    private final CircuitBreaker circuitBreaker;

    public CheckoutService(OrderClient orderClient, CircuitBreakerFactory cbFactory) {
        this.orderClient = orderClient;
        this.circuitBreaker = cbFactory.create("orderService");
    }

    public OrderDto placeOrder(CreateOrderRequest req) {
        return circuitBreaker.run(
            () -> orderClient.createOrder(req),
            throwable -> fallbackOrder(req) // runs if the call fails or times out
        );
    }

    private OrderDto fallbackOrder(CreateOrderRequest req) {
        return OrderDto.pending(req); // degrade gracefully instead of crashing
    }
}
```

The circuit breaker tracks failure rate. Below a threshold, calls go through normally (**closed**). Once failures spike, it stops even trying to call the failing service for a while and goes straight to the fallback (**open**) — saving the caller's threads instead of letting them pile up waiting on a dead service. After a cooldown it lets a few requests through to test recovery (**half-open**), and closes again if they succeed. Resilience4j is the library that implements this; Spring Cloud Circuit Breaker is the thin abstraction so your code isn't locked to one implementation.

## Spring Cloud Stream — asynchronous, message-driven communication

Everything above (Feign, LoadBalancer, Circuit Breaker) is **synchronous**: service A calls service B and waits. Sometimes that's wrong — if `order-service` needs to notify `email-service`, `inventory-service`, and `analytics-service` that an order happened, making it call all three synchronously means it's now coupled to all three, and if one is slow, the order is slow.

Spring Cloud Stream lets a service publish an event to a message broker (Kafka or RabbitMQ underneath) without knowing who's listening:

```java
@Service
public class OrderService {

    private final StreamBridge streamBridge;

    public void placeOrder(Order order) {
        // ...save the order...
        streamBridge.send("orderPlaced-out-0", order); // fire and forget
    }
}
```

```java
@Bean
public Consumer<Order> inventoryUpdate() {
    return order -> { /* react to the event, independently */ };
}
```

The publisher doesn't call the consumers — it just announces the event happened. Any number of other services can listen without the publisher ever knowing they exist. This is how you avoid turning your whole system into one giant synchronous call chain.

## Spring Cloud Bus — broadcasting config changes

You know Config Server serves config from a central place. But if you change a value in the config repo, every running instance still has the _old_ value cached until it restarts or re-pulls. Spring Cloud Bus connects all your service instances to the same message broker (same Kafka/RabbitMQ as Stream, usually) just for this purpose: hit one refresh endpoint, and Bus broadcasts "config changed" to every instance at once, which then re-pulls from Config Server. It's the missing link between "config is centralized" and "config updates everywhere, instantly."

## Spring Cloud Contract — catching breaking changes before they ship

With services calling each other through Feign, a quiet danger appears: `order-service`'s team changes the shape of `/orders/{id}`'s response, and nobody on the `checkout-service` team finds out until it breaks in production. Spring Cloud Contract lets the provider (`order-service`) define a contract — "given this request, I promise this exact response shape" — and generates tests on both sides from it: the provider's build fails if it stops honoring the contract, and the consumer can run against a generated stub of the provider without the real service even being up. It's testing infrastructure specifically for the seams between services.

## How a request actually flows through all of this

Putting it together, a single checkout request moves like this: the client hits the **Gateway**, which routes it to `checkout-service` (found via **Eureka**). `checkout-service` needs order data, so it calls an **OpenFeign** client, which asks **Eureka** for `order-service` instances and **LoadBalancer** picks one. That call is wrapped in a **Circuit Breaker** in case `order-service` is unhealthy. Once the order is placed, `checkout-service` publishes an event through **Spring Cloud Stream** so `email-service` and `inventory-service` can react independently. The whole trip is stitched together by **tracing** (a trace ID riding along through the Gateway, the Feign call, and the event), and every one of these services pulled its configuration from **Config Server**, kept fresh by **Bus**.

## A related concept worth a mention: Kubernetes overlap

A lot of what Spring Cloud does — service discovery, config, load balancing — has an equivalent at the infrastructure layer if you deploy on Kubernetes (K8s has its own service discovery via DNS, its own ConfigMaps/Secrets, its own load balancing via Services). When teams move to Kubernetes, they sometimes drop Eureka and Config Server in favor of Kubernetes-native equivalents, using **Spring Cloud Kubernetes** as the glue. It's not something you need to act on now — just know that "Spring Cloud" and "Kubernetes" solve overlapping problems at different layers, and in a K8s-based production setup you'd choose which layer owns each concern rather than running both.



[[Spring Framework]]
