
# How Microservices, Gateway, Registry, Config Server, and Zipkin Work Together

Each tool you learned solves one specific question in a microservices system. The **API gateway** answers "where do clients send requests?" The **service registry** answers "where is each service running right now?" The **Config Server** answers "where do the settings come from?" And **Zipkin** answers "what happened to this one request across all services?" On their own they are separate projects. Together they form a standard Spring Cloud setup, where each one depends on the others in a specific order.

This lesson shows the whole system in one picture: which projects exist, what each one needs, what starts first, and what happens step by step when a single request goes through everything. If any piece is unclear, it links back to the lesson where you learned it.

---

## The whole system in one picture

```
                         ┌──────────────────────────┐
                         │ Git repo: config-repo    │
                         └────────────▲─────────────┘
                                      │ reads files
                         ┌────────────┴───────────── ┐
   (1) starts first ───► │ Config Server      :8888  │◄──────────────┐
                         └───────────────────────────┘               │ every service
                                                                     │ fetches settings
                         ┌───────────────────────────┐               │ at startup
   (2) starts second ──► │ Eureka (registry)  :8761  │◄──┐           │
                         └───────────────────────────┘   │ register  │
                                                         │ + lookup  │
                         ┌───────────────────────────┐   │           │
   (3) starts third ───► │ order-service      :8080  │───┤───────────┤
                         │ inventory-service  :8081  │───┘───────────┘
                         └───────────────────────────┘
                                     ▲
                         ┌───────────┴───────────────┐
   (4) starts last ────► │ API Gateway        :8000  │ ◄── clients
                         └───────────────────────────┘

        every service ──── spans ────► Zipkin :9411
```

There are **six running programs** here (Config Server, Eureka, Zipkin, gateway, and two business services), and the two business services are the only ones that contain your actual business logic. The other four are infrastructure.

|Project|Port|Role|Learned in|
|---|---|---|---|
|config-server|8888|Serves settings from Git|Config Server lesson|
|discovery-server (Eureka)|8761|Knows which instances are alive|Service registry lesson|
|api-gateway|8000|Single entry point, routes by path|API gateway lesson|
|order-service|8080|Business logic: orders|Microservices lesson|
|inventory-service|8081|Business logic: stock|Microservices lesson|
|zipkin|9411|Collects and shows traces|Zipkin lesson|

---

## What each project needs

The key idea is that **the infrastructure pieces are added to each service as dependencies and a few settings**. Your business code stays almost unchanged. This table shows which dependency goes where:

|Dependency|gateway|order|inventory|eureka|config|
|---|---|---|---|---|---|
|`spring-cloud-starter-config` (config client)|yes|yes|yes|optional|no|
|`spring-cloud-starter-netflix-eureka-client`|yes|yes|yes|no|no|
|`spring-cloud-starter-loadbalancer`|yes|yes|no|no|no|
|`spring-boot-starter-actuator` + tracing + zipkin-reporter|yes|yes|yes|no|no|
|`spring-cloud-starter-netflix-eureka-server`|no|no|no|yes|no|
|`spring-cloud-config-server`|no|no|no|no|yes|
|`spring-cloud-starter-gateway-server-webflux`|yes|no|no|no|no|
|`spring-boot-starter-web`|**no**|yes|yes|yes|yes|

Two details in that table are worth explaining:

- The **gateway uses WebFlux** (reactive), so it must **not** include `spring-boot-starter-web`. Mixing the two causes startup errors. The business services use the normal servlet-based `starter-web`.
- `spring-cloud-starter-loadbalancer` is what makes `lb://inventory-service` and `@LoadBalanced` work. Only the projects that **call** other services by name need it.

### One shared version for all Spring Cloud dependencies

Spring Cloud artifacts don't have individual versions in your `pom.xml`. They use a **BOM** (a list of compatible versions), imported once:

```xml
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>org.springframework.cloud</groupId>
      <artifactId>spring-cloud-dependencies</artifactId>
      <version>${spring-cloud.version}</version>
      <type>pom</type>
      <scope>import</scope>
    </dependency>
  </dependencies>
</dependencyManagement>
```

- `import` scope tells Maven, "take the version list from this POM."
- The Spring Cloud version **must match your Spring Boot version**. Each Spring Cloud release train supports specific Boot versions, so check the compatibility table on spring.io before choosing. A mismatch is the number one cause of strange startup errors in this setup.

---

## The configuration, written once

This is where Config Server pays off. The settings that **every** service needs live in one shared file in the Git repository, so you write them once:

```yaml
# config-repo/application.yml  (shared by every service)
eureka:
  client:
    service-url:
      defaultZone: ${EUREKA_URL:http://localhost:8761/eureka/}

management:
  tracing:
    sampling:
      probability: 1.0
  zipkin:
    tracing:
      endpoint: ${ZIPKIN_URL:http://localhost:9411/api/v2/spans}
  endpoints:
    web:
      exposure:
        include: health,info,refresh
```

Line by line:

- `eureka.client.service-url.defaultZone` is where every service registers and looks up others.
- `${EUREKA_URL:http://localhost:8761/eureka/}` is a placeholder with a **default**. On your machine, the default (`localhost`) is used. In Docker, you set an environment variable `EUREKA_URL=http://discovery-server:8761/eureka/` and it overrides the default. This is the same `${name:default}` syntax from your `@Value` and properties lessons, and it is what lets one file work in every environment.
- The two `management.tracing` and `zipkin` blocks are the Zipkin settings from the previous lesson, written once instead of in five projects.
- `exposure.include` opens the health and refresh endpoints from the Config Server lesson.

Then each service has **service-specific** files:

```yaml
# config-repo/order-service.yml
server:
  port: 8080
app:
  stock-timeout-seconds: 3
```

```yaml
# config-repo/inventory-service.yml
server:
  port: 0
```

`port: 0` means "pick any free port." This lets you start several copies of inventory-service on one machine. It works **because of the registry**: each copy registers its random port with Eureka, so callers never need to know it. (This is an important example of the pieces working together.)

### What stays inside each project

Because the shared settings moved to Git, each service's local `application.yml` becomes tiny:

```yaml
# order-service/src/main/resources/application.yml
spring:
  application:
    name: order-service
  config:
    import: "optional:configserver:http://localhost:8888"
```

- `spring.application.name` does **three jobs at once**. It chooses which file the Config Server sends (`order-service.yml`), it is the name registered in Eureka (the name other services call), and it is the service name shown in Zipkin. One name, three systems. A typo here breaks all three.
- `spring.config.import` is the one hard-coded address left, because a service can't ask for its settings from a server it doesn't know about yet.

---

## The Eureka server and the Config Server

Both are tiny. This is the Eureka server:

```java
@SpringBootApplication
@EnableEurekaServer
public class DiscoveryServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(DiscoveryServerApplication.class, args);
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

And this is the Config Server:

```java
@SpringBootApplication
@EnableConfigServer
public class ConfigServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(ConfigServerApplication.class, args);
    }
}
```

```yaml
server:
  port: 8888
spring:
  cloud:
    config:
      server:
        git:
          uri: file:///home/you/config-repo
```

The Config Server's own settings are **local**, because it can't fetch from itself. The Eureka server's settings are also local for the same reason. All the other services get their settings from the Config Server.

---

## The gateway: routes that use the registry

The gateway's route list is now very short, because it uses service names:

```yaml
# config-repo/api-gateway.yml
server:
  port: 8000

spring:
  cloud:
    gateway:
      routes:
        - id: order-route
          uri: lb://order-service
          predicates:
            - Path=/orders/**

        - id: inventory-route
          uri: lb://inventory-service
          predicates:
            - Path=/stock/**
```

- `lb://order-service` means "ask Eureka for live instances of `order-service`, pick one, and forward there."
- If you start a third copy of inventory-service, **no route changes**. Eureka learns about it, and the gateway starts sending it traffic.

Spring Cloud Gateway can even create these routes automatically from the registry:

```yaml
spring:
  cloud:
    gateway:
      discovery:
        locator:
          enabled: true
```

With that setting, `GET /inventory-service/stock/ABC` is routed to inventory-service automatically (the first path segment is the service name). It is convenient while learning, but explicit routes give you cleaner public URLs, so most real systems write them by hand.

---

## The business services: almost no new code

order-service calls inventory-service **by name**, using the load-balanced builder from the registry lesson:

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
@RestController
@RequestMapping("/orders")
public class OrderController {

    private final RestClient inventoryClient;

    public OrderController(RestClient.Builder builder) {
        this.inventoryClient = builder
                .baseUrl("http://inventory-service")
                .build();
    }

    @PostMapping
    public ResponseEntity<String> placeOrder(@RequestBody OrderRequest request) {
        StockResponse stock = inventoryClient.get()
                .uri("/stock/{sku}", request.sku())
                .retrieve()
                .body(StockResponse.class);

        if (stock == null || stock.quantity() < request.quantity()) {
            return ResponseEntity.status(409).body("Not enough stock");
        }
        return ResponseEntity.ok("Order placed");
    }
}
```

This one small class uses **three of the tools at once**, without any visible code for them:

- `http://inventory-service` is resolved through **Eureka** (the `@LoadBalanced` annotation).
- The builder is injected by Spring, so **Micrometer Tracing** adds the trace headers to the outgoing call. If you had used `RestClient.create()`, the trace would break here.
- If you later move `app.stock-timeout-seconds` into the Config Server, an `@ConfigurationProperties` record reads it, and **Config Server** supplies it.

That is the main lesson: **the business code does not mention Zipkin, Eureka, or the Config Server at all.** They work through dependencies, settings, and Spring's auto-configuration.

---

## Startup order

The order matters, because each piece depends on the one before it:

|Step|Start|Why this order|
|---|---|---|
|1|Zipkin|Others send spans to it. Spans sent earlier are simply lost, not fatal.|
|2|Config Server|Every other service needs it for its settings.|
|3|Eureka|Services register here as they start.|
|4|order-service, inventory-service|They fetch config, then register with Eureka.|
|5|API gateway|It needs Eureka's list to route.|

The chain is: **a service can't start without its config, and can't be found without the registry, and can't be reached without the gateway.** Docker Compose can express this:

```yaml
services:
  zipkin:
    image: openzipkin/zipkin
    ports: ["9411:9411"]

  config-server:
    build: ./config-server
    ports: ["8888:8888"]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8888/actuator/health"]
      interval: 5s
      retries: 10

  discovery-server:
    build: ./discovery-server
    ports: ["8761:8761"]
    depends_on:
      config-server:
        condition: service_healthy

  inventory-service:
    build: ./inventory-service
    environment:
      SPRING_CONFIG_IMPORT: "configserver:http://config-server:8888"
      EUREKA_URL: "http://discovery-server:8761/eureka/"
      ZIPKIN_URL: "http://zipkin:9411/api/v2/spans"
    depends_on:
      discovery-server:
        condition: service_started

  api-gateway:
    build: ./api-gateway
    ports: ["8000:8000"]
    environment:
      SPRING_CONFIG_IMPORT: "configserver:http://config-server:8888"
      EUREKA_URL: "http://discovery-server:8761/eureka/"
      ZIPKIN_URL: "http://zipkin:9411/api/v2/spans"
    depends_on:
      discovery-server:
        condition: service_started
```

Line by line:

- `healthcheck` makes Docker test the Config Server's health endpoint. `condition: service_healthy` then waits until it passes, which is stronger than plain `depends_on` (that only waits for the container to _start_, not for Spring to be _ready_). The image needs `curl` installed for this exact test.
- Inside Docker, `localhost` means "this container," so the three environment variables replace the `localhost` defaults with **container names** (`config-server`, `discovery-server`, `zipkin`). Docker resolves those names through its own network.
- `SPRING_CONFIG_IMPORT` overrides `spring.config.import` through Spring Boot's relaxed binding of environment variables. This matches the profile and property-source order you know.
- Only the gateway publishes a port to the outside. In a real deployment, the business services would not be reachable from the internet at all.

One more setting helps in containers. A service can register with a hostname Docker can't resolve, so tell Eureka to use the IP address instead:

```yaml
eureka:
  instance:
    prefer-ip-address: true
```

---

## One request, step by step

Here is exactly what happens when a client sends `POST http://localhost:8000/orders`:

1. **Gateway receives it.** Micrometer Tracing creates a **new trace ID** and a root span, because this is the first service to see the request.
2. **Gateway matches a route.** `Path=/orders/**` matches `order-route`, whose target is `lb://order-service`.
3. **Gateway asks Eureka** (from its local cache) for live instances of `order-service`, and picks one.
4. **Gateway forwards the request** with the `traceparent` header added. If you added the JWT filter, the token was checked **before** this step.
5. **order-service handles it.** It reads the header, keeps the same trace ID, and creates a child span.
6. **order-service calls `http://inventory-service/stock/ABC`.** `@LoadBalanced` asks Eureka for instances of inventory-service, picks one, and sends the call with the trace header again.
7. **inventory-service queries its own database** and replies. The SQL query becomes another span.
8. **The responses travel back** up the same path.
9. **In the background**, every service sends its spans to Zipkin. You open `localhost:9411` and see all five spans of this one request as a single waterfall, including which service took the longest.
10. **Meanwhile**, every service sends heartbeats to Eureka, and if you change a value in the Git repo and call `/actuator/refresh`, a service with `@RefreshScope` beans picks up the new setting without restarting.

Notice how the tools hand off to each other: the **gateway uses the registry**, the **registry's address comes from the config server**, and the **trace ID connects the gateway and the services**. Each tool is simple, but they depend on each other through the **service name** and the **shared settings**.

---

## What breaks, and which tool to check

|Symptom|Most likely cause|Check|
|---|---|---|
|Service fails at startup with config error|Config Server not running or unreachable|`http://localhost:8888/order-service/default`|
|Service starts but ignores shared settings|`spring.application.name` doesn't match the file name|Config Server URL for that name|
|Gateway returns `503` for a route|Service not registered, or name typo in `lb://`|Eureka dashboard at `:8761`|
|Gateway returns `503` right after a service starts|Gateway's registry cache not yet refreshed (up to about 30 seconds)|Wait, then retry|
|Calls work but Zipkin is empty|Sampling at 10%, or wrong Zipkin URL|`sampling.probability` and `ZIPKIN_URL`|
|Trace stops halfway|HTTP client created with `new` or `create()`|Use the injected `RestClient.Builder`|
|Works locally, fails in Docker|`localhost` used inside a container|Environment variable overrides|
|Old config value still used|No refresh, or value overridden by an environment variable|`/actuator/refresh`, env vars|

A good habit is to check these in order: **Config Server, then Eureka dashboard, then gateway route, then Zipkin.** That is also the dependency order, so you find the first broken link.

---

## A related concept, very briefly

**Circuit breaker (Resilience4j):** With all these network calls, one slow service can make its callers wait, and then their callers, until everything is stuck. A circuit breaker watches the failure rate of calls to a service, and after too many failures it **opens**: calls fail immediately (or return a fallback) instead of waiting, and it periodically tests whether the service has recovered. In Spring Cloud it plugs into the gateway and into `RestClient` calls. Zipkin shows you which calls are slow, and the circuit breaker is the tool that reacts to them.

---

## Summary

- **Gateway** is the front door, **registry** knows where instances are, **Config Server** supplies shared settings, and **Zipkin** traces requests across services.
- Business services need only dependencies and a few settings. Their code does not mention these tools.
- `spring.application.name` is the key that ties everything together: config file name, Eureka name, and Zipkin service name.
- Startup order is Config Server, then Eureka, then services, then gateway, with Zipkin anywhere before them.
- Shared settings (Eureka address, tracing, actuator) live once in the Config Server's `application.yml`, using `${NAME:default}` placeholders so the same file works locally and in Docker.
- The gateway routes with `lb://service-name`, `@LoadBalanced` does the same for service-to-service calls, and the injected `RestClient.Builder` keeps the trace connected.
- When something breaks, check in dependency order: Config Server, Eureka, gateway, Zipkin.




[[Spring Framework]]