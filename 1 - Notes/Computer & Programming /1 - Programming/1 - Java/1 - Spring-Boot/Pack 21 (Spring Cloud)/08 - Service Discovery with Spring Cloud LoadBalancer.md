
Spring Cloud LoadBalancer is the piece you've seen mentioned twice now without ever looking at directly — the component that turns "Eureka gave me 3 addresses for order-service" into "call _this one_, specifically." It replaced Netflix Ribbon as Spring Cloud's load-balancing project; if you ever see Ribbon in older code or tutorials, treat it as the deprecated predecessor to everything below, not a different approach worth learning separately.

## What it actually sits between

LoadBalancer doesn't talk to Eureka directly, and it doesn't make HTTP calls itself. It sits in the middle of that chain:

```
DiscoveryClient (gets the list of instances from Eureka's cache)
        ↓
LoadBalancer (picks ONE instance from that list)
        ↓
RestTemplate / WebClient / Feign (makes the actual HTTP call to that one instance)
```

Everywhere you've already used Feign with a `name = "order-service"`, LoadBalancer was the thing silently doing the picking. This lesson is about controlling that pick explicitly, instead of accepting the default.

## Enabling it on RestTemplate and WebClient

Feign gets load balancing automatically. If you're using `RestTemplate` or `WebClient` directly, one annotation on the bean definition is what makes the service name resolvable at all:

```java
@Configuration
public class ClientConfig {

    @Bean
    @LoadBalanced
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    @Bean
    @LoadBalanced
    public WebClient.Builder loadBalancedWebClientBuilder() {
        return WebClient.builder();
    }
}
```

```java
@Service
public class CheckoutService {

    private final RestTemplate restTemplate;

    public CheckoutService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    public OrderDto getOrder(Long id) {
        // "order-service" here is NOT a real hostname — @LoadBalanced intercepts
        // this call and substitutes a real instance address before it ever hits the network
        return restTemplate.getForObject("http://order-service/orders/{id}", OrderDto.class, id);
    }
}
```

Without `@LoadBalanced`, `http://order-service/...` would just fail — there's no DNS entry for a logical service name. The annotation attaches an interceptor that rewrites the URI, replacing `order-service` with a real `host:port` chosen by the load-balancing algorithm, right before the request goes out.

## The default algorithm, and how to actually change it

Out of the box, LoadBalancer uses a round-robin strategy — each successive call to `order-service` cycles to the next instance in the list. Changing the algorithm means defining your own `ServiceInstanceListSupplier` or `ReactorLoadBalancer` bean, scoped to one specific service name using `@LoadBalancerClient`:

```java
@Configuration
@LoadBalancerClient(name = "order-service", configuration = OrderServiceLbConfig.class)
public class LoadBalancerConfig {
}

// a separate, NOT @Configuration-annotated class — kept out of the main
// component scan so it only applies where explicitly referenced above
public class OrderServiceLbConfig {

    @Bean
    public ReactorLoadBalancer<ServiceInstance> randomLoadBalancer(
            Environment environment,
            LoadBalancerClientFactory factory) {
        String serviceId = environment.getProperty(LoadBalancerClientFactory.PROPERTY_NAME);
        return new RandomLoadBalancer(
            factory.getLazyProvider(serviceId, ServiceInstanceListSupplier.class),
            serviceId
        );
    }
}
```

`RandomLoadBalancer` ships with Spring Cloud as an alternative to the default round-robin one — this swaps the algorithm for just `order-service`, leaving every other service on round-robin. The `OrderServiceLbConfig` class being deliberately _not_ annotated `@Configuration` is important: if it were, Spring would register this bean globally for every service, not just `order-service` — the scoping to one service happens entirely through the `name` attribute on `@LoadBalancerClient` picking it up as a nested context.

## Filtering the candidate list before picking: ServiceInstanceListSupplier

Before an algorithm picks _one_ instance, something has to decide which instances are even eligible candidates. That's a separate, composable step — a chain of `ServiceInstanceListSupplier`s, each narrowing the list:

```java
@Bean
public ServiceInstanceListSupplier discoveryClientServiceInstanceListSupplier(
        ConfigurableApplicationContext context) {
    return ServiceInstanceListSupplier.builder()
        .withDiscoveryClient()        // base: pull the raw list from Eureka's cache
        .withHealthChecks()           // actively ping each instance's health endpoint, drop failing ones
        .withZonePreference()         // prefer instances in the caller's own zone
        .withCaching()                // cache the filtered result briefly instead of recomputing every call
        .build(context);
}
```

This chain runs _before_ the algorithm (round-robin/random/custom) ever sees the list — `.withHealthChecks()` is what prevents LoadBalancer from routing to an instance Eureka still thinks is `UP` but that's actually failing its own liveness check right now; `.withZonePreference()` is the mechanism behind the `prefer-same-zone-eureka` setting you saw in the Eureka lesson, expressed as an explicit filtering stage rather than a flag.

## Caching: why this matters for latency

`.withCaching()` exists because resolving a service name to an instance list isn't free — without caching, every single outgoing call re-runs the whole supplier chain (discovery lookup, health filtering, zone filtering) from scratch. Caching keeps the resolved candidate list warm for a short TTL:

```yaml
spring:
  cloud:
    loadbalancer:
      cache:
        ttl: 5s
        capacity: 256
```

A 5-second TTL means a brand-new instance that just registered might still take up to 5 seconds to show up in a _caller's_ candidate list even after Eureka's own registry already has it — stacking on top of the registry-fetch-interval delay you learned in the previous lesson. Both delays are real and compound: Eureka's client cache refresh (up to 30s) plus LoadBalancer's own instance-list cache (a few seconds) are two separate reasons "I just started, why no traffic yet" can take longer than people expect.

## Retrying failed calls against a different instance

A call can fail because the _specific instance_ LoadBalancer picked happens to be unhealthy right now, even though the service as a whole is fine. Pairing LoadBalancer with Spring Retry lets a failed call automatically retry against a _different_ instance rather than just failing outright:

```yaml
spring:
  cloud:
    loadbalancer:
      retry:
        enabled: true
```

```xml
<dependency>
    <groupId>org.springframework.retry</groupId>
    <artifactId>spring-retry</artifactId>
</dependency>
```

With this on, a failed call to instance A gets retried against instance B (a different instance from the candidate list) before the caller ever sees a failure — this is deliberately a narrower, cheaper safety net than the Circuit Breaker you already learned: retry handles "this one instance is flaky," while the circuit breaker handles "the whole service is down and I should stop trying altogether." They're meant to be used together, not as alternatives — retry first (try someone else), circuit breaker as the backstop (stop trying the whole service if failures keep piling up regardless of which instance you hit).

## Blocking vs. reactive: two separate implementations under one API

LoadBalancer ships two concrete strategy interfaces depending on which HTTP client you're pairing it with: `ReactorLoadBalancer` for reactive stacks (`WebClient`), and a blocking equivalent used with `RestTemplate`. You don't usually choose between them explicitly — which one gets wired in follows automatically from which client (`RestTemplate` vs `WebClient`) you declared `@LoadBalanced`. The custom-algorithm example above used `ReactorLoadBalancer` because `WebClient` is reactive; a `RestTemplate`-based custom algorithm bean would implement the blocking counterpart instead, with the same filtering-chain concepts applying either way.

## Pulling it together: what "complete" means here

Putting the full picture next to what you already know: Eureka answers _where is order-service_, its client-side cache controls _how fresh that answer is_, the `ServiceInstanceListSupplier` chain decides _which of those addresses are even eligible right now_ (health, zone), the algorithm (round-robin, random, or custom) decides _which eligible one gets this call_, and retry decides _what happens if that specific pick fails_. Every one of those is independently swappable — which is exactly why LoadBalancer is a separate project from Eureka rather than a feature bolted onto it: the discovery mechanism and the picking strategy are genuinely different concerns that different teams configure very differently in production.

[[Spring Framework]]
