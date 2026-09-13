

## **1. Core Endpoint Annotation**

|Annotation|Usage|
|---|---|
|`@Endpoint`|Marks a class as a **custom actuator endpoint**. Use with `@ReadOperation`, `@WriteOperation`, etc.|
|`@EndpointExtension`|Adds extra operations to an existing endpoint (less commonly used).|
|`@WebEndpoint`|Internal, used by Spring Boot for web exposure; rarely used directly.|
|`@RestControllerEndpoint`|Creates a **REST-style actuator endpoint** using Spring MVC annotations (`@GetMapping`, etc.).|

---

## **2. Operation Annotations** (inside `@Endpoint` classes)

|Annotation|HTTP Mapping|Purpose|
|---|---|---|
|`@ReadOperation`|GET|Read data from the endpoint.|
|`@WriteOperation`|POST|Modify or trigger actions.|
|`@DeleteOperation`|DELETE|Remove resources.|
|`@Selector`|N/A|Marks a method parameter as part of the endpoint path (like `/endpoint/{id}`).|

**Example:**

```java
@Endpoint(id = "example")
public class ExampleEndpoint {

    @ReadOperation
    public String read() { return "reading"; }

    @WriteOperation
    public String write(@Selector String name) { return "writing " + name; }

    @DeleteOperation
    public String delete(@Selector String name) { return "deleted " + name; }
}
```

This gives you:

```
GET /actuator/example
POST /actuator/example/{name}
DELETE /actuator/example/{name}
```

---

## **3. Supporting/Meta Annotations**

|Annotation|Purpose|
|---|---|
|`@Component`|Needed to register your endpoint as a Spring bean.|
|`@ReadOperation`, `@WriteOperation`, `@DeleteOperation`|Already covered above.|
|`@Selector`|Used to define path variables for dynamic operations.|

---

## **4. Notes on `@RestControllerEndpoint`**

- Annotated classes are **regular REST controllers** under `/actuator/{id}`.
    
- You can use standard Spring MVC annotations (`@GetMapping`, `@PostMapping`, etc.).
    
- Example:
    

```java
@RestControllerEndpoint(id = "stats")
public class StatsEndpoint {

    @GetMapping("/activeUsers")
    public int activeUsers() { return 42; }
}
```

Access: `/actuator/stats/activeUsers`.

---

✅ **TL;DR Cheat Sheet:**

- **@Endpoint** → custom actuator endpoint
    
- **@RestControllerEndpoint** → REST-style actuator endpoint
    
- **@ReadOperation / @WriteOperation / @DeleteOperation** → define endpoint methods
    
- **@Selector** → path variable in endpoint
    
- **@EndpointExtension** → extend existing endpoint
    



##### Tags : [[0 - Spring Framework]]