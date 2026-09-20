
JMX (Java Management Extensions) is a Java technology for **monitoring and managing applications, system objects, devices, and service-oriented networks**. In Spring Boot, it integrates with Actuator to expose metrics and management operations via JMX. Here's the rundown:

---

### **1. What JMX Does**

- Lets you **expose beans (MBeans)** that represent your app’s components.
    
- Allows external tools (like JConsole, VisualVM, or Prometheus via JMX exporter) to **read metrics or invoke operations**.
    
- Useful for production monitoring without HTTP endpoints.
    

---

### **2. Enable JMX in Spring Boot**

Spring Boot can automatically register beans as JMX MBeans.

**In `application.properties` or `application.yml`:**

```yaml
spring:
  jmx:
    enabled: true
```

- Default domain: `org.springframework.boot`
    
- You can customize domain:
    

```yaml
spring:
  jmx:
    enabled: true
    default-domain: com.myapp
```

---

### **3. Accessing via JConsole**

1. Run your Spring Boot app.
    
2. Open **JConsole** (`jconsole` command in terminal).
    
3. Select your running app process.
    
4. Navigate to the **MBeans** tab.
    
5. Explore exposed beans, read attributes, and invoke operations.
    

---

### **4. Custom MBean Example**

You can create a custom managed bean:

```java
import org.springframework.jmx.export.annotation.ManagedAttribute;
import org.springframework.jmx.export.annotation.ManagedOperation;
import org.springframework.jmx.export.annotation.ManagedResource;
import org.springframework.stereotype.Component;

@Component
@ManagedResource(objectName = "com.myapp:type=Cache,name=MyCache", description = "Cache management")
public class CacheManager {

    private int cacheSize = 100;

    @ManagedAttribute
    public int getCacheSize() {
        return cacheSize;
    }

    @ManagedAttribute
    public void setCacheSize(int cacheSize) {
        this.cacheSize = cacheSize;
    }

    @ManagedOperation
    public void clearCache() {
        System.out.println("Cache cleared!");
    }
}
```

Now in JConsole, you can:

- Read/change `cacheSize`
    
- Invoke `clearCache()`
    

---

### **5. Integration with Actuator**

Spring Boot Actuator exposes many built-in beans via JMX automatically, e.g., `HealthEndpoint`, `MetricsEndpoint`. You can access them in the same way as custom MBeans.



In short, **JMX = Java’s remote management layer**, and Spring Boot + Actuator makes it easy to hook your app into it.


---


## **1. Enabling JMX**

```yaml
spring:
  jmx:
    enabled: true           # Enable JMX
    default-domain: myapp   # Optional custom domain
management:
  endpoints:
    jmx:
      exposure:
        include: "*"        # Expose all endpoints via JMX
```

- By default, Actuator endpoints are exposed as **MBeans** in the `org.springframework.boot` domain.
    
- Custom domain helps separate your app from other JMX beans.
    

---

## **2. Common Actuator Endpoints via JMX**

|Endpoint|JMX Bean Name Pattern|Description|
|---|---|---|
|`health`|`*:type=Health`|Application health status|
|`info`|`*:type=Info`|App info (version, description)|
|`metrics`|`*:type=Metrics,name=<metric>`|Metrics like memory, CPU, JVM stats|
|`loggers`|`*:type=Loggers,name=<logger>`|View/change logging levels|
|`threaddump`|`*:type=ThreadDump`|Dump all thread stacks|
|`env`|`*:type=Environment`|Environment properties and configs|
|`beans`|`*:type=Beans`|Lists all Spring beans|
|`httptrace`|`*:type=HttpTrace`|Recent HTTP request traces|

> Notes:
> 
> - `<metric>` and `<logger>` correspond to specific metrics/loggers.
>     
> - All endpoints exposed via JMX are **readable attributes** or **operations**.
>     

---

## **3. Accessing via JConsole**

1. Run your Spring Boot app.
    
2. Open terminal: `jconsole`.
    
3. Select your app process.
    
4. Go to **MBeans** tab → navigate by domain (`myapp` or `org.springframework.boot`).
    
5. Read attributes or invoke operations directly.
    

---

## **4. Custom MBeans**

You can expose your own management operations:

```java
@Component
@ManagedResource(objectName = "myapp:type=Cache,name=MyCache", description = "Cache management")
public class CacheManager {

    private int cacheSize = 100;

    @ManagedAttribute
    public int getCacheSize() { return cacheSize; }

    @ManagedAttribute
    public void setCacheSize(int cacheSize) { this.cacheSize = cacheSize; }

    @ManagedOperation
    public void clearCache() { System.out.println("Cache cleared!"); }
}
```

- `ManagedAttribute` → readable/writable properties
    
- `ManagedOperation` → callable methods
    
- Appears in JConsole under **MBeans → myapp → Cache → MyCache**
    

---

## **5. Tips**

- Combine **Actuator + JMX** to avoid exposing sensitive endpoints over HTTP in production.
    
- Use **JMX monitoring tools** (VisualVM, JConsole, Prometheus JMX exporter) for metrics collection.
    
- You can selectively expose endpoints to JMX via:
    

```yaml
management:
  endpoints:
    jmx:
      exposure:
        include: health,metrics
```

---

If you want, I can also make a **diagram showing HTTP vs JMX exposure of Actuator endpoints**, so you can visually see which endpoints are available over HTTP, JMX, or both. This is super handy for reference.



##### Tags ; [[0 - Spring Framework]]