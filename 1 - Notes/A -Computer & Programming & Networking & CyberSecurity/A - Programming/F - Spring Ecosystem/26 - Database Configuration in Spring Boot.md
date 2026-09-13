Date : 2025-09-05


# Spring Boot `application.properties` – Complete Guide (Up to Spring Boot 3.5+)

This guide explains everything you can configure in **`application.properties`** (and `application.yml`) in Spring Boot, from core settings to advanced customization.

---

## 1. Introduction

- `application.properties` is the **default configuration file** in Spring Boot.
    
- Located in `src/main/resources/`.
    
- Uses **key=value** format.
    
- Alternative: `application.yml` (YAML format).
    

**Order of precedence:**

1. Command-line arguments
    
2. `application.properties` / `application.yml`
    
3. Profile-specific files (`application-dev.properties`)
    
4. Defaults inside JAR
    

---

## 2. Profiles

Enable different configs for environments (dev, test, prod).

```properties
spring.profiles.active=dev
```

Profile-specific file example:

- `application-dev.properties`
    
- `application-prod.properties`
    

---

## 3. Server Configuration

```properties
server.port=8081
server.servlet.context-path=/app
server.address=127.0.0.1
```

- `server.port=0` → Random free port.
    

---

## 4. Logging Configuration

```properties
logging.level.root=INFO
logging.level.com.example=DEBUG
logging.file.name=app.log
logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss} - %msg%n
```

- Control log levels per package/class.
    
- Customize console/file logs.
    

---

## 5. Database Configuration

### 5.1 JDBC with HikariCP (default pool)

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/mydb
spring.datasource.username=root
spring.datasource.password=secret
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

spring.datasource.hikari.maximum-pool-size=10
```

### 5.2 JPA / Hibernate

```properties
spring.jpa.show-sql=true
spring.jpa.hibernate.ddl-auto=update
spring.jpa.database-platform=org.hibernate.dialect.MySQLDialect
```

DDL auto values: `none`, `update`, `create`, `create-drop`, `validate`.

---

## 6. Spring MVC & Static Content

```properties
spring.mvc.view.prefix=/WEB-INF/views/
spring.mvc.view.suffix=.jsp
spring.web.resources.static-locations=classpath:/static/,classpath:/public/
```

---

## 7. Security

```properties
spring.security.user.name=admin
spring.security.user.password=secret
```

- Useful for quick prototypes.
    
- In production, use **real authentication providers**.
    

---

## 8. Mail

```properties
spring.mail.host=smtp.gmail.com
spring.mail.port=587
spring.mail.username=myemail@gmail.com
spring.mail.password=app-password
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true
```

---

## 9. File Upload

```properties
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=20MB
```

---

## 10. Actuator

```properties
management.endpoints.web.exposure.include=health,info,metrics
management.endpoint.health.show-details=always
```

- Exposes monitoring endpoints.
    

---

## 11. Caching

```properties
spring.cache.type=caffeine
spring.cache.caffeine.spec=maximumSize=100,expireAfterWrite=5m
```

---

## 12. Custom Properties

You can define your own:

```properties
app.name=MySpringApp
app.version=1.0.0
```

Then inject using `@Value`:

```java
@Value("${app.name}")
private String appName;
```

Or map into a config class:

```java
@ConfigurationProperties(prefix = "app")
public class AppConfig {
    private String name;
    private String version;
}
```

---

## 13. Profiles with YAML (Optional)

Example `application.yml`:

```yaml
spring:
  profiles:
    active: dev
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

## 14. Best Practices

1. **Use profiles** (`application-dev.properties`, etc.).
    
2. Never commit **secrets** (use environment variables or Vault).
    
3. Prefer **YAML** for complex configs.
    
4. Group custom properties with prefixes (`app.*`).
    
5. For large apps, consider **Spring Cloud Config**.
    

---

## 15. Summary

- `application.properties` is central to Spring Boot configuration.
    
- Covers **server, logging, DB, MVC, security, caching, mail, actuator, and custom settings**.
    
- Supports **profiles for environments**.
    
- Use best practices for **security, maintainability, and scalability**.
    

With this knowledge, you can **fully configure and tune a Spring Boot application**.


---

# Database Configuration in Spring Boot (PostgreSQL & H2)

## 1. PostgreSQL Configuration

PostgreSQL is a powerful, open-source relational database commonly used in production.

### Dependency (Maven)

```xml
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>
```

### application.properties

```properties
# PostgreSQL Config
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=myuser
spring.datasource.password=mypassword
spring.datasource.driver-class-name=org.postgresql.Driver

# JPA & Hibernate
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
spring.jpa.database-platform=org.hibernate.dialect.PostgresSQLDialect
```

### Notes

- `ddl-auto=update`: Automatically updates schema (use carefully in production).
    
- `create-drop`: Drops & recreates DB each time (use only in dev/testing).
    
- For production, prefer **Flyway** or **Liquibase** for schema migrations.
    

---

## 2. H2 Database Configuration

H2 is an in-memory (or file-based) lightweight DB, perfect for development/testing.

### Dependency (Maven)

```xml
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>runtime</scope>
</dependency>
```

### application.properties

```properties
# H2 Config
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=

# JPA & Hibernate
spring.jpa.hibernate.ddl-auto=create-drop
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect

# H2 Console (accessible via browser)
spring.h2.console.enabled=true
spring.h2.console.path=/h2-console
```

### Notes

- Default username: `sa`, password: empty.
    
- Console available at `http://localhost:8080/h2-console`.
    
- Useful for **unit tests** and quick prototyping.
    

---

## 3. Switching Between PostgreSQL & H2

Spring Profiles let you switch configurations for different environments.

### application.properties

```properties
spring.profiles.active=dev
```

### application-dev.properties (H2 for Dev)

```properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
```

### application-prod.properties (PostgreSQL for Prod)

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=myuser
spring.datasource.password=mypassword
spring.datasource.driver-class-name=org.postgresql.Driver
```

---

## 4. Best Practices

- Use **H2** for development/testing, PostgreSQL for production.
    
- Separate configurations with **Spring Profiles**.
    
- Avoid `ddl-auto=update` in production → use **migration tools**.
    
- Secure credentials → use environment variables or Vault.
    

---

✅ With this setup, you can easily run **H2 locally** for testing and switch to **PostgreSQL in production** without changing your code.


##### *Tags : [[0 - Spring Framework]]