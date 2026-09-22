
## Spring Boot `application.properties` — Complete Guide

This is the **single most important configuration file** in a Spring Boot app. Spring Boot auto-loads it from `src/main/resources/` at startup. Let's go from syntax → structure → the codes you'll actually use.

---

## 1. Two Formats: `.properties` vs `.yml`

Spring Boot supports both. Pick one per project — don't mix.

### `.properties` (flat key-value)
```properties
server.port=8081
spring.datasource.url=jdbc:mysql://localhost:3306/mydb
spring.datasource.username=root
```

### `.yml` / `.yaml` (hierarchical, indentation-based)
```yaml
server:
  port: 8081
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/mydb
    username: root
```

**Key differences:**

| Aspect | `.properties` | `.yml` |
|---|---|---|
| Structure | Flat, dotted keys | Nested via indentation |
| Repetition | Repeats full prefix | Prefix written once |
| Lists | `app.hosts[0]=a` | `- a` on new lines |
| Readability | Verbose | Cleaner for deep config |
| Indentation | Not required | **Must use spaces, never tabs** |

> **Rule:** YAML requires **2 spaces** per level, no tabs, and a space after `:`.

---

## 2. Syntax Rules

### Properties file
```properties
# Comment (single line)
key=value
key.with.dots=value
key:value          # colon also works as separator
app.name = My App  # spaces around = are trimmed
```

### YAML file
```yaml
# Comment
server:
  port: 8081                # string, number, boolean auto-typed
  servlet:
    context-path: /api

app:
  name: My App
  hosts:                    # list
    - host1.com
    - host2.com
  features:
    cache: true             # boolean
    timeout: 30s            # duration
```

### Value types Spring Boot understands

| Type | Example |
|---|---|
| String | `app.name=MyApp` |
| Integer | `server.port=8081` |
| Boolean | `feature.enabled=true` |
| Duration | `timeout=30s`, `5m`, `1h`, `500ms` |
| Data size | `max-size=10MB`, `2GB` |
| List | `app.hosts=a,b,c` |
| List (YAML) | `hosts: [a, b, c]` or `- a` items |
| Map (YAML) | `db: {host: x, port: 5432}` |

---

## 3. File Loading Order & Profiles

Spring Boot loads config files in this priority (later overrides earlier):

```
1. application.properties
2. application-{profile}.properties   ← overrides defaults
3. OS environment variables
4. Java system properties (-Dkey=value)
5. Command-line args (--key=value)    ← highest priority
```

### Profiles — the killer feature

Create **`application-dev.properties`**, **`application-prod.properties`**, etc.

```properties
# application.properties (common defaults)
spring.application.name=demo
server.port=8080

# application-dev.properties
server.port=8081
spring.datasource.url=jdbc:h2:mem:testdb

# application-prod.properties
server.port=80
spring.datasource.url=jdbc:mysql://prod-host:3306/mydb
```

**Activate a profile:**
```properties
# in application.properties
spring.profiles.active=dev
```
Or at runtime:
```bash
java -jar app.jar --spring.profiles.active=prod
```

**YAML multi-document form (all-in-one):**
```yaml
spring:
  application:
    name: demo
---
spring:
  config:
    activate:
      on-profile: dev
server:
  port: 8081
---
spring:
  config:
    activate:
      on-profile: prod
server:
  port: 80
```

---

## 4. Common Properties — Cheat Sheet

### Core / Server

```properties
spring.application.name=my-app
server.port=8080
server.servlet.context-path=/api
server.servlet.session.timeout=30m
server.error.include-message=always
server.error.include-stacktrace=never
server.compression.enabled=true
server.compression.mime-types=application/json,text/html
```

### Logging

```properties
logging.level.root=INFO
logging.level.com.example=DEBUG
logging.level.org.springframework.web=DEBUG
logging.level.org.hibernate.SQL=DEBUG
logging.file.name=logs/app.log
logging.file.path=/var/log/myapp
logging.pattern.console=%d{HH:mm:ss} %-5level %logger{36} - %msg%n
```

### Database — MySQL

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/mydb?useSSL=false&serverTimezone=UTC
spring.datasource.username=root
spring.datasource.password=secret
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQL8Dialect
spring.jpa.properties.hibernate.format_sql=true
```

### Database — PostgreSQL

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=postgres
spring.datasource.password=secret
spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect
```

### Database — H2 (in-memory, great for tests/dev)

```properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.h2.console.enabled=true
spring.h2.console.path=/h2-console
spring.jpa.hibernate.ddl-auto=create-drop
```

### Connection Pool (HikariCP — default)

```properties
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.idle-timeout=600000
spring.datasource.hikari.max-lifetime=1800000
```

### JPA / Hibernate

```properties
spring.jpa.hibernate.ddl-auto=update          # none | validate | update | create | create-drop
spring.jpa.show-sql=true
spring.jpa.open-in-view=false                 # recommended to disable
spring.jpa.properties.hibernate.format_sql=true
spring.jpa.properties.hibernate.jdbc.batch_size=20
spring.jpa.properties.hibernate.order_inserts=true
```

### JSON / Jackson

```properties
spring.jackson.default-property-inclusion=non_null
spring.jackson.serialization.write-dates-as-timestamps=false
spring.jackson.date-format=yyyy-MM-dd HH:mm:ss
spring.jackson.time-zone=UTC
spring.jackson.serialization.fail-on-empty-beans=false
```

### File Upload (Multipart)

```properties
spring.servlet.multipart.enabled=true
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=10MB
```

### Security (basic)

```properties
spring.security.user.name=admin
spring.security.user.password=secret
spring.security.user.roles=ADMIN
```

### Thymeleaf

```properties
spring.thymeleaf.cache=false
spring.thymeleaf.prefix=classpath:/templates/
spring.thymeleaf.suffix=.html
spring.thymeleaf.mode=HTML
```

### Caching

```properties
spring.cache.type=simple         # simple | redis | caffeine | ehcache
spring.cache.cache-names=users,products
spring.cache.redis.time-to-live=600000
```

### Email (SMTP)

```properties
spring.mail.host=smtp.gmail.com
spring.mail.port=587
spring.mail.username=me@gmail.com
spring.mail.password=app-password
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true
```

### Actuator (monitoring)

```properties
management.endpoints.web.exposure.include=health,info,metrics
management.endpoint.health.show-details=always
management.server.port=8081
info.app.name=My App
info.app.version=1.0.0
```

### Flyway / Liquibase

```properties
spring.flyway.enabled=true
spring.flyway.locations=classpath:db/migration
spring.flyway.baseline-on-migrate=true
```

### Scheduling / Async

```properties
spring.task.scheduling.pool.size=5
spring.task.execution.pool.core-size=10
spring.task.execution.pool.max-size=50
```

---

## 5. Custom Properties (Your Own Config)

Define anything you want with a namespace:

```properties
app.name=My Application
app.version=1.0.0
app.features.cache-enabled=true
app.hosts=host1.com,host2.com
app.security.jwt-secret=abc123
app.security.expiration=3600
```

### Access them with `@Value`

```java
@Component
public class AppConfig {

    @Value("${app.name}")
    private String appName;

    @Value("${app.features.cache-enabled:false}")   // default = false
    private boolean cacheEnabled;

    @Value("${app.hosts}")                           // comma-separated → List
    private List<String> hosts;
}
```

### Or better — type-safe `@ConfigurationProperties`

```java
@ConfigurationProperties(prefix = "app")
@Component
public class AppProperties {
    private String name;
    private String version;
    private Features features = new Features();
    private List<String> hosts;
    private Security security = new Security();

    // getters + setters ...

    public static class Features {
        private boolean cacheEnabled;
        // getters + setters
    }
    public static class Security {
        private String jwtSecret;
        private long expiration;
        // getters + setters
    }
}
```

Inject anywhere:
```java
@Service
public class MyService {
    private final AppProperties props;
    public MyService(AppProperties props) { this.props = props; }
}
```

Enable it once with `@EnableConfigurationProperties` or `@ConfigurationPropertiesScan` on the main class.

### YAML equivalent

```yaml
app:
  name: My Application
  version: 1.0.0
  features:
    cache-enabled: true
  hosts:
    - host1.com
    - host2.com
  security:
    jwt-secret: abc123
    expiration: 3600
```

---

## 6. Placeholders & SpEL

Reference other properties:

```properties
app.host=localhost
app.port=8080
app.url=http://${app.host}:${app.port}
app.greeting=Hello from ${spring.application.name}
```

Random values (useful for secrets, ports, IDs):

```properties
app.secret=${random.value}
app.number=${random.int}
app.port=${random.int[1024,9999]}
app.uuid=${random.uuid}
```

---

## 7. Environment Variables (Production Best Practice)

Never commit secrets. Override at runtime. Spring Boot maps env vars to properties via **relaxed binding**:

| Property | Env var |
|---|---|
| `spring.datasource.password` | `SPRING_DATASOURCE_PASSWORD` |
| `server.port` | `SERVER_PORT` |
| `app.security.jwt-secret` | `APP_SECURITY_JWTSECRET` |

```bash
export SPRING_DATASOURCE_PASSWORD=supersecret
export SPRING_PROFILES_ACTIVE=prod
java -jar app.jar
```

**Rule:** uppercase, dots → underscores, dashes removed.

---

## 8. Externalizing the Config File

Spring Boot also looks for config **outside** the JAR (higher priority):

```
1. ./config/application.properties         ← highest
2. ./application.properties
3. classpath:/config/application.properties
4. classpath:/application.properties       ← lowest
```

Point to a specific file:
```bash
java -jar app.jar --spring.config.location=file:/etc/myapp/application.properties
```

---

## 9. Command-Line Overrides (Highest Priority)

```bash
java -jar app.jar --server.port=9090 --spring.profiles.active=prod
```

---

## 10. Quick Reference — Most Used Properties at a Glance

```properties
# ── App identity ──
spring.application.name=my-app

# ── Server ──
server.port=8080
server.servlet.context-path=/api

# ── Profiles ──
spring.profiles.active=dev

# ── Datasource ──
spring.datasource.url=jdbc:mysql://localhost:3306/mydb
spring.datasource.username=root
spring.datasource.password=secret

# ── JPA ──
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true

# ── Logging ──
logging.level.root=INFO
logging.level.com.example=DEBUG

# ── JSON ──
spring.jackson.default-property-inclusion=non_null

# ── Upload ──
spring.servlet.multipart.max-file-size=10MB

# ── Actuator ──
management.endpoints.web.exposure.include=health,info

# ── Custom ──
app.feature.enabled=true
```

---

## Key Takeaways

1. **One file, huge power** — `application.properties` (or `.yml`) drives nearly all Spring Boot behavior.
2. **Prefer YAML for nested config**, properties for simple flat config.
3. **Use profiles** (`application-dev.yml`, `application-prod.yml`) — never hardcode environment differences.
4. **Never commit secrets** — use env vars or an external config file.
5. **Use `@ConfigurationProperties`** over scattered `@Value` for grouped config.
6. **Relaxed binding** means `app.myKey`, `app.my-key`, `APP_MYKEY` all resolve to the same property.
7. **Override priority:** command-line args > env vars > profile file > default file.

Master these and you'll configure 95% of Spring Boot apps without ever touching Java config.

[[Java]]
[[0 - Spring Framework]]