# Service Registry

A service registry is a database of the services that are currently running, and where each one can be reached. Every service tells the registry its name and its network address when it starts, and removes itself (or is removed) when it stops. Any other service or gateway can then ask the registry, "Where is `inventory-service` right now?" and get back a live list of addresses.

It matters because in a microservices system, addresses are not fixed. Services are started, stopped, scaled to several copies, and moved between machines or containers. If you hard-code `http://localhost:8081` like we did in the microservices and API gateway lessons, every change means editing code or config. A registry removes that problem: callers use a **name**, and the registry supplies the **address**.

---

## The problem with hard-coded addresses

Here is the line from the `order-service` in the microservices lesson:

```java
.baseUrl("http://inventory-service:8081")
```

This works only while exactly one inventory-service exists at exactly that address. Now imagine you run three copies:

|Instance|Address|
|---|---|
|inventory-service #1|10.0.0.5:8081|
|inventory-service #2|10.0.0.6:8081|
|inventory-service #3|10.0.0.7:8081|

Which one should order-service call? What if #2 crashes? What if you add #4 during a busy hour? A hard-coded URL can't answer any of these. A registry can.

---

## How it works: three actions

A registry setup has two sides: the **registry server**, and the **clients** (your services). Everything happens through three actions.

**1. Register.** When a service starts, it sends its name and address to the registry.

```
inventory-service  →  Registry: "I'm inventory-service at 10.0.0.5:8081"
```

**2. Heartbeat.** The service keeps sending a small "I'm still alive" message, every 30 seconds by default in Eureka. If the heartbeats stop, the registry removes that instance after a timeout. This is how crashed services disappear from the list automatically.

**3. Look up.** When a caller needs a service, it asks the registry by name and receives the list of live instances.

```
order-service  →  Registry: "Who is inventory-service?"
Registry       →  order-service: [10.0.0.5:8081, 10.0.0.7:8081]
```

Notice that #2 is missing from the answer, because its heartbeats stopped. The caller never has to know that it crashed.

Callers also keep a local **cache** of the registry's answer, so they don't ask on every request. This means a short outage of the registry doesn't stop your system, though the cached list may be a little out of date.

---

## Registry in code: Eureka

Spring Cloud's standard registry is **Eureka**. It has a server project and client dependencies.

### 1. The registry server

A small, separate Spring Boot project:

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
</dependency>
```

```java
@SpringBootApplication
@EnableEurekaServer
public class RegistryApplication {
    public static void main(String[] args) {
        SpringApplication.run(RegistryApplication.class, args);
    }
}
```

```yaml
server:
  port: 8761

eureka:
  client:
    register-with-eureka: false
    fetch-registry: false
```

Line by line:

- `@EnableEurekaServer` turns this application into a registry. It is like `@SpringBootApplication` plus a registry feature switched on.
- `port: 8761` is the conventional Eureka port. Open `http://localhost:8761` and you get a dashboard that lists registered services.
- `register-with-eureka: false` means the registry should not register itself as a service. It _is_ the registry.
- `fetch-registry: false` means it does not need to download the list from another registry. (In production you might run several registries that replicate each other, and then you would turn these on.)

### 2. A service that registers itself

In `inventory-service`, add the client dependency:

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

```yaml
spring:
  application:
    name: inventory-service

server:
  port: 8081

eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

Line by line:

- `spring.application.name` is the **name** this service registers under. It is the most important line here, because every caller will use this exact name.
- `defaultZone` is the address of the registry. The client sends registrations and heartbeats there.
- With the client dependency on the classpath, Spring Boot registers the service automatically on startup. No annotation is needed in recent versions.

Start two copies on different ports (`--server.port=8081` and `--server.port=8082`) and the dashboard shows **one** service name with **two** instances.

### 3. A caller that uses the name

In `order-service`, add the same Eureka client dependency and give it a name. Then replace the hard-coded address with a service name and mark the client as load balanced:

```java
@Configuration
public class ClientConfig {

    @Bean
    @LoadBalanced
    public RestClient.Builder restClientBuilder() {
        return RestClient.builder();
    }
}
```

```java
public OrderController(RestClient.Builder builder) {
    this.inventoryClient = builder
            .baseUrl("http://inventory-service")
            .build();
}
```

Line by line:

- `@LoadBalanced` tells Spring Cloud to intercept calls made by this builder. When it sees a host name like `inventory-service`, it does not do a normal DNS lookup. It asks the registry for the instances, picks one, and sends the request there.
- `http://inventory-service` has **no port**. The port comes from the registry entry, so each instance can use a different one.
- Each call can go to a different instance, in round-robin order by default. This gives you load balancing without writing any extra code.
- The `@Configuration` and `@Bean` pattern here is the same as in the configuration class lesson, and the builder is injected by constructor, as in the dependency injection lessons.

---

## The gateway connection

In the API gateway lesson, we wrote routes like this:

```yaml
uri: http://localhost:8081
```

With a registry, the route becomes:

```yaml
uri: lb://inventory-service
```

`lb://` means "load balanced, resolve this name through the registry." Now the gateway always routes to live instances, and you can add or remove copies without editing the gateway. That is the full picture: **the gateway is the front door for clients, and the registry is the phone book the gateway uses to find your services.**

---

## Two ways to discover services

||Client-side discovery|Server-side discovery|
|---|---|---|
|Who asks the registry?|The caller (order-service)|A load balancer or platform in front|
|Who picks the instance?|The caller|The load balancer|
|Example|Eureka + Spring Cloud LoadBalancer|Kubernetes Services, AWS load balancers|
|Caller's code|Knows about the registry|Just calls a stable name|

What we built above is **client-side discovery**: the caller itself looks up and chooses. Platforms like Kubernetes use **server-side discovery**: the platform keeps its own registry, and gives each service a stable name (such as `http://inventory-service`) that already spreads traffic across the instances. If you deploy to Kubernetes later, you often don't need Eureka at all, because the platform provides the registry for you.

---

## Registry options

|Tool|Notes|
|---|---|
|**Eureka**|Spring Cloud's classic choice. Easy to start, favors availability.|
|**Consul**|Registry plus health checks and a key-value store. Works with many languages.|
|**ZooKeeper**|Older, strongly consistent coordination service. Used by Kafka historically.|
|**Kubernetes**|Built-in discovery through DNS names for Services.|

---

## Costs and gotchas

- **The registry is critical infrastructure.** Run more than one copy in production.
- **Stale data is possible.** A crashed instance may stay in the list until its heartbeat timeout passes, so calls to it can fail briefly. This is why timeouts and retries (from the microservices lesson) still matter.
- **Names must match exactly.** A typo in `spring.application.name` means the caller can't find the service.
- **Extra moving part.** For two or three services, a registry may be more work than it saves.

---

## A related concept, very briefly

**Health checks:** A registry is only useful if its list is truthful. Beyond heartbeats, services can expose a health endpoint (Spring Boot Actuator gives you `/actuator/health`), and the registry or load balancer can check it. An instance that is running but unhealthy, for example one that can't reach its database, can then be taken out of rotation.

---

## Summary

- A service registry stores the names and live addresses of your running services.
- Services **register** on startup, send **heartbeats** while alive, and are removed when heartbeats stop. Callers **look up** by name.
- In Spring, Eureka is the common registry: `@EnableEurekaServer` for the server, the Eureka client dependency plus `spring.application.name` for services.
- `@LoadBalanced` lets a `RestClient` call `http://inventory-service` by name, and `lb://inventory-service` does the same in the gateway.
- Kubernetes and similar platforms often replace Eureka with their own built-in discovery.






[[Spring Framework]]