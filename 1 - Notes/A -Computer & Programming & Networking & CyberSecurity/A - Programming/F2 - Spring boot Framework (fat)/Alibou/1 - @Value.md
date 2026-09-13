

# **@Value in Spring Boot (Full Explanation)**

## **1. What `@Value` Is**

`@Value` is a Spring annotation that injects values into fields, constructor parameters, or method parameters.  
These values usually come from:

- `application.properties` / `application.yml`
    
- Environment variables
    
- System properties
    
- Inline literal values
    
- SpEL (Spring Expression Language)
    

---

# **2. Where You Can Use It**

You can put it on:

```java
@Value("${app.title}")
private String title;
```

or on constructor/method parameters:

```java
public MyService(@Value("${app.count}") int count) {
    this.count = count;
}
```

---

# **3. Syntax Patterns**

### **Literal value**

```java
@Value("Hello")
```

### **From properties**

```java
@Value("${server.port}")
```

### **Default value**

```java
@Value("${app.timeout:5000}")
private int timeout;
```

### **Environment variable**

```java
@Value("${HOME}")
```

### **SpEL**

```java
@Value("#{2 + 3}") // 5
```

### **Reading lists**

```java
@Value("${app.items}")
private List<String> items;
```

And in `application.properties`:

```
app.items=a,b,c
```

---

# **4. Common Use Cases**

## **(A) Injecting config values**

```java
@Value("${jwt.secret}")
private String secret;
```

## **(B) Injecting file resources**

```java
@Value("classpath:data.json")
private Resource resource;
```

## **(C) Injecting expressions**

```java
@Value("#{T(java.lang.Math).random() * 100}")
private double randomValue;
```

---

# **5. Professional Warning (Important)**

For **multiple related fields**, do _NOT_ use `@Value` everywhere.  
Use **@ConfigurationProperties** — cleaner and more scalable.

### This is bad (scattered config):

```java
@Value("${user.minAge}")
int minAge;

@Value("${user.maxAge}")
int maxAge;
```

### This is professional:

```java
@ConfigurationProperties(prefix="user")
public class UserConfig {
    private int minAge;
    private int maxAge;
}
```

---

# **6. Quick Example**

### **application.properties**

```
app.name=ArcadeProject
app.version=1.0.2
```

### **Java**

```java
@Component
public class InfoService {

    @Value("${app.name}")
    private String name;

    @Value("${app.version}")
    private String version;

    public void print() {
        System.out.println(name + " " + version);
    }
}
```

---

# **7. Summary (Direct and Clear)**

|Purpose|Example|
|---|---|
|Inject config|`@Value("${key}")`|
|Default value|`@Value("${key:default}")`|
|Literal|`@Value("Hello")`|
|SpEL|`@Value("#{1 + 1}")`|
|Resource|`@Value("classpath:file.txt")`|


###### Tags : [[0 - Spring Framework]]