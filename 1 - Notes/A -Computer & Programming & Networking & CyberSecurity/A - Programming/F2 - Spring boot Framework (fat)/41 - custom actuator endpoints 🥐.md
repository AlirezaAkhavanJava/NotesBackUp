
In **Spring Boot**, you can create **custom Actuator endpoints** to expose specific metrics, health checks, or application info. Here's a clear guide:

---

### 1. **Enable Actuator**

Make sure your `pom.xml` has:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

In `application.properties` or `application.yml`:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: "*"   # or list specific endpoints like health, info, myEndpoint
```

---

### 2. **Creating a Custom Endpoint**

Spring Boot 3+ recommends **`@Endpoint`** or **`@RestControllerEndpoint`**.

#### Using `@Endpoint`

```java
import org.springframework.boot.actuate.endpoint.annotation.Endpoint;
import org.springframework.boot.actuate.endpoint.annotation.ReadOperation;
import org.springframework.stereotype.Component;

@Component
@Endpoint(id = "custom")  // endpoint will be /actuator/custom
public class CustomEndpoint {

    @ReadOperation
    public String customInfo() {
        return "Hello from custom actuator!";
    }
}
```

- `@ReadOperation` → GET
    
- `@WriteOperation` → POST
    
- `@DeleteOperation` → DELETE
    

#### Using `@RestControllerEndpoint`

This lets you create **REST-style endpoints**:

```java
import org.springframework.boot.actuate.endpoint.web.annotation.RestControllerEndpoint;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestControllerEndpoint(id = "restcustom") // /actuator/restcustom
public class RestCustomEndpoint {

    @GetMapping("/info")
    public String info() {
        return "REST custom actuator info";
    }
}
```

---

### 3. **Accessing Your Endpoint**

Once your app is running:

```
GET http://localhost:8080/actuator/custom
GET http://localhost:8080/actuator/restcustom/info
```

---

### 4. **Security & Exposure**

- Make sure to expose your custom endpoint in `application.properties`/`application.yml`.
    
- By default, sensitive endpoints like `/actuator/*` are **secured**.
    

```yaml
management:
  endpoints:
    web:
      exposure:
        include: custom, restcustom
```



##### Tags : [[0 - Spring Framework]]