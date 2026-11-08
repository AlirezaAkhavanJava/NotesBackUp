# Config Server

A Config Server is a small, separate application whose only job is to hold the configuration files for all your services and hand them out over HTTP. Instead of each service keeping its own `application.yml` inside its JAR, the services ask the Config Server for their settings when they start. The Config Server itself usually reads those settings from a Git repository, so your configuration is versioned just like code.

It matters because a microservices system has many services, each with many settings (database URLs, ports, feature flags, timeouts) and each running in several environments (dev, test, prod). Without a central place, you end up editing and rebuilding many JARs every time a setting changes. With a Config Server, you change a file in one Git repository, and the services pick it up. In Spring this is provided by **Spring Cloud Config**.

---

## What goes wrong without it

Think about the services from the earlier lessons: order-service, inventory-service, the gateway, and the registry. Each has its own `application.yml`. Now suppose all of them share the same Eureka address and the same logging level:

```yaml
# order-service/application.yml
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
logging:
  level:
    root: INFO
```

```yaml
# inventory-service/application.yml
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
logging:
  level:
    root: INFO
```

The same lines are copied into every service. If the registry moves to another host, you must edit every project, rebuild every JAR, and redeploy every service. And because the config is packed inside the JAR, you can't change a value in production without a new build.

|Problem|Why it hurts|
|---|---|
|Copy-pasted settings|One change means editing N projects|
|Config inside the JAR|Changing a value means rebuild + redeploy|
|Secrets in each project|Passwords spread across many repositories|
|No history|You can't easily see who changed a value, or roll it back|

---

## How it works

There are two sides: the **Config Server** and the **Config Clients** (your services).

```
                     ┌────────────────────────┐
                     │  Git repository        │
                     │  order-service.yml     │
                     │  inventory-service.yml │
                     │  application.yml       │
                     └───────────▲────────────┘
                                 │ reads
                     ┌───────────┴────────────┐
                     │  Config Server (8888)  │
                     └───▲───────▲────────▲───┘
                         │       │        │  GET /order-service/dev
                   order-svc  inventory  gateway
```

1. A client starts and tells the Config Server its **name** (`spring.application.name`) and its **profile** (`dev`, `prod`).
2. The Config Server finds the matching files in the Git repository.
3. It returns the settings as JSON, and the client adds them to its Spring `Environment`.
4. Your normal code (`@Value`, `@ConfigurationProperties`) reads them as if they were in a local `application.yml`.

The key point is step 3. From your code's point of view nothing changes. The settings just arrive from somewhere else. This is the same `Environment` and the same property sources you saw in the `@PropertySource` and `@ConfigurationProperties` lessons. The Config Server is simply one more property source.

---

## Building the Config Server

It is its own Spring Boot project.

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-config-server</artifactId>
</dependency>
```

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
          uri: https://github.com/your-name/config-repo
          default-label: main
```

Line by line:

- `@EnableConfigServer` switches the Config Server feature on, the same way `@EnableEurekaServer` did for the registry.
- `port: 8888` is the conventional Config Server port.
- `git.uri` is the repository that holds the config files. It can be a GitHub URL or a local path such as `file:///home/you/config-repo`, which is handy on your Debian machine while learning.
- `default-label: main` is the Git branch to read.

### The config repository

The repository is just a folder of YAML (or properties) files:

```
config-repo/
├── application.yml              # shared by every service
├── order-service.yml            # only for order-service
├── order-service-dev.yml        # order-service in the dev profile
├── order-service-prod.yml       # order-service in the prod profile
└── inventory-service.yml
```

The file name follows the pattern `{application}-{profile}.yml`, which is exactly the naming you know from Spring profiles. Here is an example:

```yaml
# application.yml  (shared by all)
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

```yaml
# order-service-dev.yml
server:
  port: 8080
app:
  stock-timeout-seconds: 3
```

```yaml
# order-service-prod.yml
server:
  port: 8080
app:
  stock-timeout-seconds: 1
```

The shared Eureka address now lives in **one** place. Each service only has its own differences.

### Checking it with a browser

Start the Config Server and open:

```
http://localhost:8888/order-service/dev
```

You get JSON like this:

```json
{
  "name": "order-service",
  "profiles": ["dev"],
  "propertySources": [
    { "name": ".../order-service-dev.yml",
      "source": { "server.port": 8080, "app.stock-timeout-seconds": 3 } },
    { "name": ".../application.yml",
      "source": { "eureka.client.service-url.defaultZone": "http://localhost:8761/eureka/" } }
  ]
}
```

The URL pattern is `/{application}/{profile}`. Notice the order: the more specific file (`order-service-dev.yml`) comes first, and the shared `application.yml` comes after it. **The first one wins**, so specific settings override shared ones.

|URL|What you get|
|---|---|
|`/order-service/dev`|order-service settings for dev|
|`/order-service/prod`|order-service settings for prod|
|`/order-service/dev/main`|same, from the `main` branch|
|`/order-service-dev.yml`|one merged file, as YAML|

---

## Building a Config Client

In order-service, add the client dependency:

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-config</artifactId>
</dependency>
```

Then the **local** `application.yml` shrinks to almost nothing:

```yaml
spring:
  application:
    name: order-service
  profiles:
    active: dev
  config:
    import: "configserver:http://localhost:8888"
```

Line by line:

- `spring.application.name` tells the Config Server **which files to send**. It must match the file name (`order-service`).
- `profiles.active: dev` picks `order-service-dev.yml`.
- `spring.config.import: "configserver:http://localhost:8888"` tells Spring Boot, "while building the `Environment`, also load settings from this Config Server." This is the modern way to connect a client (older tutorials use a `bootstrap.yml`, which you can skip).

Now your code reads the values normally:

```java
@ConfigurationProperties(prefix = "app")
public record AppProperties(int stockTimeoutSeconds) {}
```

```java
@Service
public class StockClient {

    private final AppProperties props;

    public StockClient(AppProperties props) {
        this.props = props;
    }

    public int timeout() {
        return props.stockTimeoutSeconds();
    }
}
```

- `@ConfigurationProperties(prefix = "app")` binds `app.stock-timeout-seconds` to `stockTimeoutSeconds`, using relaxed binding.
- The record has no idea whether the value came from a local file or from the Config Server. It is still `3` in dev and `1` in prod.

---

## Config Server with the other pieces

The Config Server must start **before** the services that depend on it, because the services need their settings to start at all. This creates a startup order for your whole system:

```
1. Config Server   (8888)
2. Service registry (8761)   ← its address can come from the Config Server too
3. Gateway, order-service, inventory-service
```

In Docker Compose you express this with `depends_on`, as in the microservices lesson. You can also make a client retry instead of failing immediately:

```yaml
spring:
  config:
    import: "optional:configserver:http://localhost:8888"
```

`optional:` means "if the Config Server is unreachable, start anyway with local settings." That is useful in development, but in production you usually want the service to fail fast instead, so it never runs with the wrong configuration.

---

## Refreshing config without a restart

By default a client reads its settings **once at startup**. If you change a file in Git, a running service does not notice. Spring Boot Actuator offers a refresh:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

```yaml
management:
  endpoints:
    web:
      exposure:
        include: refresh
```

```java
@Service
@RefreshScope
public class StockClient {

    @Value("${app.stock-timeout-seconds}")
    private int timeout;
}
```

- `@RefreshScope` marks a bean to be **rebuilt** when a refresh happens. It is a special bean scope, in the same family as the `@Scope` options you learned earlier, and it works through a proxy.
- Call `POST /actuator/refresh` on the service. It re-reads the Config Server, and `@RefreshScope` beans are recreated with the new values.
- Beans without `@RefreshScope` keep their old values.
- `@ConfigurationProperties` beans are refreshed automatically, but `@Value` fields in normal beans are not.

Doing this on every service one by one is tedious, which is why larger systems add **Spring Cloud Bus**, a message-based way to broadcast "refresh" to all services at once.

---

## Secrets and security

Putting plain passwords in Git is a bad idea. Config Server offers two common options:

**Encryption:** the server can store encrypted values and decrypt them for clients.

```yaml
# in the config repo
spring:
  datasource:
    password: "{cipher}AQB3f8c1..."
```

The `{cipher}` prefix tells the Config Server to decrypt the value before sending it. You set the key on the server with `encrypt.key` (or use a key store).

**Protecting the server itself:** Config Server returns settings to anyone who can reach it, so add Spring Security with basic authentication, and have clients send the credentials:

```yaml
spring:
  config:
    import: "configserver:http://localhost:8888"
  cloud:
    config:
      username: config-user
      password: ${CONFIG_PASSWORD}
```

`${CONFIG_PASSWORD}` is read from an environment variable, so the password isn't written in the project at all. This connects to your earlier Spring Security learning, because the Config Server is just another Spring Boot application you can secure.

---

## Config Server vs the alternatives

|Approach|Good for|Weakness|
|---|---|---|
|Local `application.yml` in each JAR|One service, one environment|Duplication, rebuild on every change|
|Environment variables|Containers, secrets, 12-factor apps|Hard to manage many values, no history|
|**Spring Cloud Config Server**|Many Spring services sharing settings, versioned in Git|Another service to run and protect|
|Consul KV / Kubernetes ConfigMaps|Non-Spring or Kubernetes-based setups|Different tooling to learn|

If you deploy to Kubernetes, ConfigMaps and Secrets often replace the need for Config Server, similar to how Kubernetes replaces Eureka for service discovery.

---

## Costs and gotchas

- **It is a critical service.** If the Config Server is down, new instances can't start. Run more than one copy, and consider caching or fail-fast behavior.
- **Names must match exactly.** A typo in `spring.application.name` means the client silently gets only `application.yml`.
- **Priority order surprises people.** Environment variables and command-line arguments usually override Config Server values. This is helpful for emergencies, but it can confuse you while debugging.
- **Don't put business data here.** It is for settings, not for things that change per request.

---

## A related concept, very briefly

**Spring Cloud Bus:** a lightweight link between services, using a message broker such as RabbitMQ or Kafka. When one `POST /actuator/busrefresh` is sent to any service, the Bus broadcasts the refresh event so **all** services reload their configuration. Together with Config Server and `@RefreshScope`, it gives you "change a Git file, and the whole system updates" without restarts.

---

## Summary

- A Config Server is a central application that serves configuration to your services, usually from a Git repository.
- Files follow `{application}-{profile}.yml`, and `application.yml` is shared by all services. The URL pattern is `/{application}/{profile}`.
- The server uses `@EnableConfigServer` and `spring.cloud.config.server.git.uri`. Clients use `spring-cloud-starter-config` and `spring.config.import: "configserver:..."`.
- Your code still uses `@Value` and `@ConfigurationProperties`, because the values simply join the normal `Environment`.
- `@RefreshScope` plus `/actuator/refresh` lets values change without a restart, and Spring Cloud Bus broadcasts that to every service.
- Protect the server with Spring Security, and keep secrets encrypted or in environment variables.





[[Spring Framework]]