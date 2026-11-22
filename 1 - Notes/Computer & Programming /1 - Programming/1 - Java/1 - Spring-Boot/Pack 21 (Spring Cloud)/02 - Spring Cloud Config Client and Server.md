
Config Server and Config Client are the two halves of the same mechanism — Config Server exposes configuration as a REST API backed by a source of truth (usually a Git repo), and Config Client is the Spring Boot machinery that pulls from that API and feeds the values into your app's `Environment` as if they'd been in `application.properties` all along. You already know _why_ this exists (centralized config). This is about how the two sides are actually wired.

## Config Server: turning a Git repo into a config API

A Config Server is a normal Spring Boot app with one annotation:

```java
@SpringBootApplication
@EnableConfigServer
public class ConfigServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(ConfigServerApplication.class, args);
    }
}
```

Its own `application.yml` points at the backend — the place the actual config files live:

```yaml
server:
  port: 8888

spring:
  cloud:
    config:
      server:
        git:
          uri: https://github.com/yourname/config-repo
          default-label: main
          clone-on-start: true
```

That Git repo is just a folder of property/YAML files, named by convention:

```
application.yml                 # shared by every client, every profile
application-prod.yml            # shared by every client, prod profile only
order-service.yml               # specific to the app named "order-service"
order-service-prod.yml          # order-service, prod profile only
```

The naming isn't arbitrary — it maps directly onto the URL the Config Server exposes:

```
GET /{application}/{profile}/{label}

GET /order-service/prod/main
→ merges application.yml + application-prod.yml + order-service.yml + order-service-prod.yml
  (more specific files win on conflicting keys)
```

`{application}` is the client's `spring.application.name`, `{profile}` is its active Spring profile, `{label}` is the Git branch or tag (defaults to `main`/`master`). You can hit that URL with `curl` directly and get back the merged JSON — which is useful for debugging a "why isn't my client getting this value" problem, because it tells you exactly what the server thinks it should be serving before you even involve a client app.

Git isn't the only backend. `spring.cloud.config.server.native.search-locations` serves from a plain local filesystem instead (handy for local dev without a repo), and there's JDBC and Vault backends too — the URL contract to clients stays identical regardless of which backend is behind it.

## Config Client: pulling that config into your app

On the client side, the modern way to connect is one property, set _before_ the rest of your config even loads:

```yaml
# order-service's application.yml
spring:
  application:
    name: order-service
  config:
    import: "configserver:http://localhost:8888"
  profiles:
    active: prod
```

That single `spring.config.import` line is what tells Boot "before you finish building my `Environment`, go fetch `/order-service/prod/main` from this Config Server and merge it in." Everything the server returns behaves exactly like local `application.properties` — `@Value`, `@ConfigurationProperties`, all of it, none the wiser about where the value actually came from.

Two properties matter for production robustness here:

```yaml
spring:
  cloud:
    config:
      fail-fast: true      # refuse to start if Config Server is unreachable, instead of starting with missing config
      retry:
        max-attempts: 6
        initial-interval: 1000
        multiplier: 1.5
```

Without `fail-fast`, a client whose Config Server happens to be down at startup will just boot with whatever defaults it has locally — silently missing values, which is a worse failure mode than refusing to start. `retry` softens the common case where Config Server is just mid-restart, not actually gone.

## Getting a value after startup: @RefreshScope and /actuator/refresh

Values pulled from Config Server are only read once, at startup, by default — a bean built with a `@Value` from Config Server won't update just because you changed the file in Git. `@RefreshScope` is what makes a bean rebuildable on demand instead of fixed for the app's lifetime:

```java
@RefreshScope
@RestController
public class PricingController {

    @Value("${discount.rate}")
    private double discountRate;

    @GetMapping("/discount")
    public double discount() {
        return discountRate;
    }
}
```

Hitting `POST /actuator/refresh` on that client tears down and rebuilds every `@RefreshScope` bean, re-reading current values from Config Server — no restart. This is exactly the manual version of what you learned **Spring Cloud Bus** automates: instead of calling `/actuator/refresh` on every instance one by one, Bus broadcasts a `RefreshRemoteApplicationEvent` over the message broker and every subscribed instance refreshes itself at once.

## Keeping secrets out of plain text: encryption

Config repos are often just public-ish Git repos, so putting a raw DB password in `order-service-prod.yml` is a real problem. Config Server has built-in `/encrypt` and `/decrypt` endpoints:

```bash
curl -X POST http://localhost:8888/encrypt -d "s3cr3tPassword"
# → 5f4a8d2e9b1c...  (ciphertext)
```

You store the ciphertext in the config file prefixed with `{cipher}`:

```yaml
spring:
  datasource:
    password: '{cipher}5f4a8d2e9b1c...'
```

When a client requests config, the server detects the `{cipher}` prefix and decrypts it server-side before the value ever goes out over the wire — clients always see plaintext, the Git repo never does. This needs either a symmetric key (`encrypt.key` on the server) or an asymmetric keystore for production use; the symmetric key is fine to learn with but a keystore is the real-deployment choice since a single leaked symmetric key decrypts every secret in the repo.


[[Spring Framework]]
