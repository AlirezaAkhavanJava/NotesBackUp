
In Spring Boot, there are several ways to activate a profile. The important property is:

```properties
spring.profiles.active=local
```

### 1. `application.properties`

```properties
spring.profiles.active=local
```

Or YAML:

```yaml
spring:
  profiles:
    active: local
```

Simple, but **usually not recommended for production**, because you're hard-coding the environment.

---

### 2. Command line — very common

```bash
java -jar app.jar --spring.profiles.active=prod
```

Or when using Maven:

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

This is useful because you don't need to modify the application files.

---

### 3. Environment variable — very common in production

Spring Boot maps:

```properties
spring.profiles.active
```

to:

```bash
SPRING_PROFILES_ACTIVE
```

So:

```bash
export SPRING_PROFILES_ACTIVE=prod
```

Then:

```bash
java -jar app.jar
```

Or in one command:

```bash
SPRING_PROFILES_ACTIVE=prod java -jar app.jar
```

This is especially common with **Docker, Kubernetes, CI/CD**, etc.

---

### 4. JVM system property

```bash
java -Dspring.profiles.active=prod -jar app.jar
```

Notice the difference:

```bash
--spring.profiles.active=prod
```

is a **Spring command-line argument**, while:

```bash
-Dspring.profiles.active=prod
```

is a **JVM system property**.

Both work.

---

### 5. IDE configuration

In IntelliJ, you can set:

```text
SPRING_PROFILES_ACTIVE=local
```

as an environment variable in your Run Configuration.

Or add VM options:

```text
-Dspring.profiles.active=local
```

---

### 6. Programmatically

You can set it from Java:

```java
SpringApplication app = new SpringApplication(MyApplication.class);

app.setAdditionalProfiles("local");

app.run(args);
```

Or:

```java
SpringApplication.run(MyApplication.class, args);
```

with an environment/system property controlling it.

This is generally **less desirable** than external configuration because your environment selection becomes coupled to application code.

---

## Profile-specific files

Once you activate:

```text
local
```

Spring Boot can load:

```text
application.properties
application-local.properties
```

For example:

```text
src/main/resources/
├── application.properties
├── application-local.properties
└── application-prod.properties
```

`application-local.properties`:

```properties
server.port=8080
spring.datasource.url=jdbc:postgresql://localhost:5432/doitlater
```

`application-prod.properties`:

```properties
server.port=8080
spring.datasource.url=jdbc:postgresql://prod-db:5432/doitlater
```

Then:

```bash
SPRING_PROFILES_ACTIVE=local
```

loads the local configuration.

### Professional approach

A typical deployment hierarchy is:

```text
application.properties
        ↓
profile-specific configuration
        ↓
environment variables / command-line arguments
```

For example:

```properties
# application.properties
spring.application.name=DoItLater
```

```properties
# application-local.properties
spring.datasource.url=jdbc:postgresql://localhost:5432/doitlater
```

```properties
# application-prod.properties
spring.datasource.url=${DB_URL}
```

Then production decides the profile externally:

```bash
SPRING_PROFILES_ACTIVE=prod
```




[[0 - Spring Framework]]