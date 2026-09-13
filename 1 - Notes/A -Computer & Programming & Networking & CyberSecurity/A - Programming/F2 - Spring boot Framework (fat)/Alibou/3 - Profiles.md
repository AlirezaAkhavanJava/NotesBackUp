

# **What Spring Profiles Are**

Spring Profiles let you **activate different configurations for different environments**, such as:

- **dev** (local development)
    
- **test** (unit/integration testing)
    
- **prod** (production)
    
- **stage** (staging)
    

Each profile contains its own beans or config section.  
Spring will only load the beans/config that belong to the _active_ profile.

---

# **What Problems Profiles Solve**

They help you:

- Use **different databases** in dev vs prod
    
- Turn on/off **debug beans**
    
- Change **security settings**
    
- Load different **application.properties/yml** files
    
- Avoid hard-coding environment-specific values in code
    

Profiles = _environment separation_.

---

# **1. How to Activate a Profile**

### **A) application.properties**

```
spring.profiles.active=dev
```

### **B) Command line**

```
java -jar app.jar --spring.profiles.active=prod
```

### **C) Environment variable**

```
export SPRING_PROFILES_ACTIVE=test
```

---

# **2. application-{profile}.properties**

Spring automatically loads config based on profile name.

Example:

```
application-dev.properties
application-prod.properties
```

Inside each:

**application-dev.properties**

```
server.port=8081
debug=true
```

**application-prod.properties**

```
server.port=8080
debug=false
```

---

# **3. @Profile Annotation**

Use it to load beans for specific environments.

### **Example: Two DataSources**

```java
@Configuration
@Profile("dev")
public class DevDBConfig {
    @Bean
    public DataSource dataSource() {
        return new HikariDataSource(... dev settings ...);
    }
}
```

```java
@Configuration
@Profile("prod")
public class ProdDBConfig {
    @Bean
    public DataSource dataSource() {
        return new HikariDataSource(... prod settings ...);
    }
}
```

Only one of these configs loads depending on the active profile.

---

# **4. @Profile on Components**

```java
@Component
@Profile("dev")
public class DebugLogger implements MyLogger {}
```

```java
@Component
@Profile("prod")
public class ProdLogger implements MyLogger {}
```

Now Spring automatically chooses correct implementation.

---

# **5. @Profile Multiple Values**

```java
@Profile({"dev", "test"})
```

Bean loads if **either** profile is active.

---

# **6. Default Profile**

If nothing is set:

```
spring.profiles.default=dev
```

Spring will use **default** when no active profile is defined.

---

# **7. When You Truly Need Profiles**

Use profiles when:

- You switch between **H2 / MySQL / PostgreSQL**
    
- You need different **logging** levels
    
- You want separate **security configs** (open for dev, strict for prod)
    
- You have external services (Redis, RabbitMQ, OAuth provider)
    
- You deploy to multiple environments (local, staging, prod)
    

---

# **8. Short Workflow (For Real Projects)**

**Local dev** → run with dev profile  
**GitHub Actions tests** → run with test profile  
**Production deploy** → set prod profile in Docker/Server

Example Docker command:

```
docker run -e SPRING_PROFILES_ACTIVE=prod myapp:1.0
```

---

# **Direct Summary**

|Concept|Meaning|
|---|---|
|Profile|A named environment (dev/test/prod)|
|How to enable|`spring.profiles.active=dev`|
|File naming|`application-dev.properties`|
|Profile-specific beans|`@Profile("dev")`|
|Multiple|`@Profile({"dev","test"})`|
|Default profile|`spring.profiles.default=dev`|

---



# ✅ **What This Code Does**

```java
SpringApplication app = new SpringApplication(GamonApplication.class);
app.setDefaultProperties(Collections.singletonMap("spring.profiles.active", "dev"));
ApplicationContext context = app.run(args);
```

## **1. Creates a SpringApplication object**

You’re manually controlling the Spring Boot startup instead of using:

```java
SpringApplication.run(GamonApplication.class, args);
```

This allows you to configure things **before** the application starts.

---

## **2. Sets default properties for the app**

```java
app.setDefaultProperties(...)
```

You’re telling Spring Boot:

> “If no profile is set elsewhere, use the `dev` profile.”

Equivalent to having this in `application.properties`:

```
spring.profiles.active=dev
```

BUT only as a **default**, meaning:

- CLI arguments override it
    
- Environment variables override it (`SPRING_PROFILES_ACTIVE`)
    
- JVM args override it (`-Dspring.profiles.active=prod`)
    
- application.properties also overrides it
    

So this is the **lowest priority** way to set a profile.

---

## **3. Starts the application**

```java
ApplicationContext context = app.run(args);
```

Same as usual but with your custom profile setting applied.

---

# ✅ When This Approach Is Useful

- **In custom launchers**  
    (e.g., starting Spring from a library or integration framework)
    
- **When you want a default environment for devs**  
    without forcing them to modify properties
    
- **When writing tests or quick prototypes**
    
- **When you want one environment baked into the JAR**  
    but still overridable by command-line/env variables
    

---

# ⚠️ When Not To Use This

This is NOT recommended for **production apps** because:

- It hides profile configuration inside code
    
- It becomes harder to change environments in CI/CD
    
- It violates “configuration outside of code” best practice
    

Production should use ENV variables:

```
SPRING_PROFILES_ACTIVE=prod
```

Or application-level config:

```
spring.profiles.active=prod
```

---

# 🔥 Professional Best Practice

### **Development machine**

```
spring.profiles.active=dev
```

### **Production machine**

Environment variable:

```
export SPRING_PROFILES_ACTIVE=prod
```

### **Avoid setting profiles in code**

unless you are doing something very special.

---

# Summary (Direct & Clear)

|Line|Meaning|
|---|---|
|`new SpringApplication`|Custom app startup|
|`setDefaultProperties`|Sets default profile (lowest priority)|
|`"spring.profiles.active","dev"`|Runs app in `dev` unless overridden|
|`app.run(args)`|Start Spring Boot|

---



###### Tags : [[0 - Spring Framework]]