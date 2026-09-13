


### **What are Profiles?**

Profiles let you define **different configurations for different environments**, e.g., `dev`, `test`, `prod`.

Instead of changing configs manually, Spring picks the right one based on the **active profile**.

---

### **1. Setting the Active Profile**

**In `application.yml`:**

```yaml
spring:
  profiles:
    active: dev
```

**Or via command line:**

```bash
java -jar app.jar --spring.profiles.active=prod
```

---

### **2. Defining Profile-Specific Configurations**

You separate sections with `---` and assign a profile:

```yaml
# Default configs
server:
  port: 8080

spring:
  datasource:
    username: root
    password: secret

---
# Dev profile
spring:
  profiles: dev
  datasource:
    url: jdbc:mysql://localhost:3306/dev_db

---
# Prod profile
spring:
  profiles: prod
  datasource:
    url: jdbc:mysql://localhost:3306/prod_db
```

✅ Spring only loads the section matching the active profile (and the default section).

---

### **3. Using `@Profile` in Code**

You can also make beans active **only for specific profiles**:

```java
@Configuration
@Profile("dev")
public class DevConfig {
    @Bean
    public String devBean() {
        return "I only exist in dev";
    }
}

@Configuration
@Profile("prod")
public class ProdConfig {
    @Bean
    public String prodBean() {
        return "I only exist in prod";
    }
}
```

---

### **4. Hierarchy / Overrides**

- Properties in a **profile section** override the default section.
    
- You can **combine multiple profiles** with a comma:
    

```yaml
spring:
  profiles:
    active: dev,featureX
```

Spring merges configurations from both profiles.

---

💡 **Rule of thumb:**

- Use **default section** for common configs.
    
- Use **profile-specific sections** for environment differences (DB, ports, feature toggles).
    

---


# Complete Guide: Spring Boot 3+ Profile Configuration  
## **New `application.yml` Syntax (2025 Edition)**  
> For **Spring Boot 3.0+** (including 3.5.7) – **Old `spring.profiles` is REMOVED**

---

**Save this file as:** `SPRING_BOOT_3_PROFILE_GUIDE.md`

---

## 1. The Problem (What Broke?)

```yaml
spring:
  profiles: dev        # INVALID in Spring Boot 3+
  profiles.active: dev # ALSO INVALID
```

**Error you saw:**
```
InvalidConfigDataPropertyException: Property 'spring.profiles' ... 
should be replaced with 'spring.config.activate.on-profile'
```

> `spring.profiles` was **deprecated in 2.4**, **removed in 3.0**.

---

## 2. The NEW Correct Syntax

### Use: `spring.config.activate.on-profile`

```yaml
spring:
  config:
    activate:
      on-profile: dev
```

---

## 3. FULL WORKING `application.yml` (Multi-Profile)

```yaml
# ========================================
# application.yml – Spring Boot 3.5+
# ========================================

# Default settings (applies to ALL profiles)
server:
  port: 8080

logging:
  level:
    root: INFO

# Optional: default welcome message
welcome:
  message: "The Application is running"

# ========================================
# DEVELOPMENT PROFILE
# ========================================
---
spring:
  config:
    activate:
      on-profile: dev

  application:
    name: UltimateArcadeBoot-DEV

  datasource:
    url: jdbc:postgresql://localhost:5432/Ultimate
    username: ethan
    password: ${DB_PASSWORD:9908}  # Use env var in prod!
    driver-class-name: org.postgresql.Driver

  jpa:
    hibernate:
      ddl-auto: update
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: true
    show-sql: true

logging:
  level:
    com.arcade: DEBUG

welcome:
  message: "DEVELOPMENT MODE ACTIVE"

# ========================================
# QA PROFILE
# ========================================
---
spring:
  config:
    activate:
      on-profile: qa

  application:
    name: UltimateArcadeBoot-QA

  datasource:
    url: jdbc:postgresql://localhost:5432/ultimate_qa
    username: ethan
    password: ${DB_PASSWORD:9908}
    driver-class-name: org.postgresql.Driver

  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false

logging:
  level:
    com.arcade: INFO

welcome:
  message: "QA ENVIRONMENT"

# ========================================
# PRODUCTION PROFILE
# ========================================
---
spring:
  config:
    activate:
      on-profile: prod

  application:
    name: UltimateArcadeBoot

  datasource:
    url: jdbc:postgresql://prod-db:5432/ultimate_prod
    username: ${DB_USER}
    password: ${DB_PASSWORD}
    driver-class-name: org.postgresql.Driver

  jpa:
    hibernate:
      ddl-auto: none
    properties:
      hibernate:
        show_sql: false
        format_sql: false

logging:
  level:
    root: WARN
    com.arcade: INFO

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics

welcome:
  message: "PRODUCTION LIVE"
```

---

## 4. How to ACTIVATE a Profile

| Method | Command |
|-------|--------|
| **Maven** | `./mvnw spring-boot:run -Dspring-boot.run.profiles=dev` |
| **Gradle** | `./gradlew bootRun --args='--spring.profiles.active=qa'` |
| **JAR** | `java -jar app.jar --spring.profiles.active=prod` |
| **IntelliJ** | Add to **VM Options**: `-Dspring.profiles.active=dev` |
| **Environment** | `export SPRING_PROFILES_ACTIVE=qa` |

> **Never hardcode active profile in `application.yml`**

---

## 5. Security Best Practices

```yaml
password: ${DB_PASSWORD}           # Good
password: 9908                     # NEVER commit!
```

Use:
- `.env` files (with `spring-boot-dotenv`)
- OS environment variables
- Docker secrets
- Vault / AWS Parameter Store

---

## 6. Common Mistakes (DON'T DO)

```yaml
spring.profiles: dev                 # REMOVED
spring.profiles.active: dev          # DON'T put here
spring:
  profiles:
    include: dev                     # Also gone
```

---

## 7. Alternative: Separate Files (Optional)

You can split into:
- `application.yml` → default
- `application-dev.yml`
- `application-qa.yml`
- `application-prod.yml`

Each **must** contain:

```yaml
spring:
  config:
    activate:
      on-profile: dev
```

> But **single `application.yml` with `---` is cleaner**

---

## 8. Verify It Works

Run:
```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

Check log:
```
The following profiles are active: dev
```

And you’ll see:
```
DEVELOPMENT MODE ACTIVE
```

---

## 9. Quick Reference Cheat Sheet

| Purpose | Old (2.x) | New (3.x) |
|--------|----------|----------|
| Define profile | `spring.profiles: dev` | `spring.config.activate.on-profile: dev` |
| Activate profile | `spring.profiles.active` | `--spring.profiles.active=dev` |
| Include profile | `spring.profiles.include` | Use `@Profile` in code |
| Multi-document | `---` | Still supported |

---

## 10. Final Checklist

- [ ] Removed all `spring.profiles`
- [ ] Added `spring.config.activate.on-profile`
- [ ] Activate profile **externally**
- [ ] Never commit passwords
- [ ] Use `---` to separate profiles
- [ ] Test with `dev`, `qa`, `prod`

---

**You are now Spring Boot 3+ profile compliant!**

*Saved: November 11, 2025 – Baku, Azerbaijan*  
*For: UltimateArcadeBoot Project*  
*Author: Ethan (with Grok)*

--- 

**Pro Tip**: Add this to your project’s `docs/` folder:
```
docs/spring-boot-3-profiles.md
```

And never see that error again!

##### Tags : [[0 - Spring Framework]]