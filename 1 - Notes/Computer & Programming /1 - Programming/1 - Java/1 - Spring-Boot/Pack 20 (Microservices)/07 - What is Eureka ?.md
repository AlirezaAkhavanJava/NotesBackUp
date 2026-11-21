

**Eureka** is Netflix's implementation of a **service registry** — the concrete tool that does what you already learned a service registry _conceptually_ does: let microservices find each other by name instead of hardcoded IP/port. Eureka itself is a Spring Cloud Netflix component, split into two roles: the **Eureka Server** (the registry itself) and **Eureka Clients** (the microservices that register with it and query it).

### How it actually works

Every microservice that wants to be discoverable runs as a Eureka Client. On startup, it sends a registration request to the Eureka Server containing its service name (an "app ID"), host, port, and health-check URL. From then on, it sends a **heartbeat** every 30 seconds by default to say "I'm still alive."

```properties
# Eureka Server application.properties
server.port=8761
eureka.client.register-with-eureka=false
eureka.client.fetch-registry=false
```

```java
// Eureka Server main class
@SpringBootApplication
@EnableEurekaServer
public class RegistryApplication {
    public static void main(String[] args) {
        SpringApplication.run(RegistryApplication.class, args);
    }
}
```

That's the whole server — `@EnableEurekaServer` boots up a registry with a dashboard at `localhost:8761`.

On the client side (e.g. an `order-service`):

```properties
spring.application.name=order-service
eureka.client.service-url.defaultZone=http://localhost:8761/eureka/
```

```java
@SpringBootApplication
@EnableEurekaClient
public class OrderServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(OrderServiceApplication.class, args);
    }
}
```

`spring.application.name` is important — that's the name the service registers under, and the name other services will use to find it.

### Looking another service up

Once registered, a service can ask Eureka "where is `payment-service` right now?" instead of you hardcoding `http://192.168.1.5:8082`. This is usually done through a load-balanced client:

```java
@Bean
@LoadBalanced
RestClient.Builder restClientBuilder() {
    return RestClient.builder();
}
```

```java
restClientBuilder.build()
    .get()
    .uri("http://payment-service/api/payments/123")
    .retrieve();
```

Notice `payment-service` isn't a real hostname — it's the registered app ID. The `@LoadBalanced` client resolves it against Eureka's current list of instances and picks one, which also gives you client-side load balancing for free when there are multiple instances of `payment-service` running.

### Self-preservation mode

One Eureka-specific detail worth knowing: if too many clients stop sending heartbeats at once (often a network partition, not real service deaths), Eureka assumes _it's_ the one with the problem and stops evicting instances from the registry, rather than wiping out its whole registry on bad information. This trades a bit of staleness for availability — consistent with Eureka favoring **AP** (availability over strict consistency) in CAP terms, unlike something like ZooKeeper which favors consistency.


[[Spring Framework]]