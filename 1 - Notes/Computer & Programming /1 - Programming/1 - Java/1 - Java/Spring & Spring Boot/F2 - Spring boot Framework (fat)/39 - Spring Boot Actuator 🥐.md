
Spring Boot Actuator is a powerful module in Spring Boot that gives you production-ready features for monitoring and managing your application. It exposes endpoints that let you inspect the app’s health, metrics, configuration, and more. Here's a concise breakdown:

---

### **1. Adding Actuator**

Add the dependency in `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

---

### **2. Enable Endpoints**

By default, only a few endpoints (like `/actuator/health` and `/actuator/info`) are exposed. To expose more:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: "*"   # or comma-separated list: health,info,metrics
  endpoint:
    health:
      show-details: always  # detailed health info
```

---

### **3. Common Endpoints**

|Endpoint|Description|
|---|---|
|`/actuator/health`|Checks app health|
|`/actuator/info`|Displays app info (version, description, etc.)|
|`/actuator/metrics`|Shows app metrics (memory, CPU, etc.)|
|`/actuator/env`|Shows environment properties|
|`/actuator/loggers`|View/change logging levels at runtime|
|`/actuator/threaddump`|Thread dump of the app|
|`/actuator/httptrace`|Shows HTTP request traces|

---

### **4. Custom Health Indicators**

You can add your own health check:

```java
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;

@Component
public class DatabaseHealthIndicator implements HealthIndicator {
    @Override
    public Health health() {
        // custom check
        boolean dbUp = checkDatabase(); 
        return dbUp ? Health.up().build() : Health.down().withDetail("error", "DB not reachable").build();
    }
    
    private boolean checkDatabase() {
        // implement actual check
        return true;
    }
}
```

---

### **5. Security**

In production, secure your endpoints:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    health:
      show-details: never
spring:
  security:
    user:
      name: admin
      password: secret
```

---

Spring Boot Actuator is essentially the **health dashboard and metrics engine** for your app. Combine it with **Spring Boot Admin** for a full UI monitoring experience.



##### Tags : [[0 - Spring Framework]]