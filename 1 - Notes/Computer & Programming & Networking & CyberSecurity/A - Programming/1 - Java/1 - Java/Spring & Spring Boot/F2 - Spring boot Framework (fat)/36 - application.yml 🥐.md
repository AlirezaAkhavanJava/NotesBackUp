


`application.yml` is one of the main configuration files in Spring Boot. It’s an alternative to `application.properties`, but uses **YAML** syntax, which is cleaner for hierarchical configurations.

---

### **Why use `application.yml`?**

1. **Hierarchical structure**  
    YAML supports nested structures natively, making complex configurations readable.
    
    ```yaml
    server:
      port: 8080
      servlet:
        context-path: /api
    spring:
      datasource:
        url: jdbc:mysql://localhost:3306/db
        username: root
        password: secret
    ```
    
    Compare with `application.properties`:
    
    ```
    server.port=8080
    server.servlet.context-path=/api
    spring.datasource.url=jdbc:mysql://localhost:3306/db
    spring.datasource.username=root
    spring.datasource.password=secret
    ```
    
    ✅ YAML is much cleaner for nested stuff.
    
2. **Profiles support**  
    You can define environment-specific configs easily:
    
    ```yaml
    spring:
      profiles:
        active: dev
    
    ---
    spring:
      profiles: dev
      datasource:
        url: jdbc:mysql://localhost:3306/dev_db
    
    ---
    spring:
      profiles: prod
      datasource:
        url: jdbc:mysql://localhost:3306/prod_db
    ```
    
    Spring automatically picks the right section based on the active profile.
    
3. **Lists and complex structures**  
    YAML makes it easy to define lists and maps:
    
    ```yaml
    app:
      servers:
        - host: server1
          port: 8080
        - host: server2
          port: 8081
    ```
    
4. **Better readability**  
    No repeated dots and equals signs. It’s visually cleaner and easier to maintain as configs grow.
    

---

### **How it ties with `@Value`**

```yaml
app:
  name: UltimateArcade
  max-users: 100
```

```java
@Value("${app.name}")
private String appName;

@Value("${app.max-users}")
private int maxUsers;
```

---

💡 **Rule of thumb:**

- Use `application.properties` for **simple apps** or **single-value configs**.
    
- Use `application.yml` for **complex, nested configs**, especially with multiple profiles.
    

---


### **1. Key-Value Pairs**

Basic assignment:

```yaml
appName: UltimateArcade
maxUsers: 100
```

Equivalent in `properties`:

```
appName=UltimateArcade
maxUsers=100
```

---

### **2. Nested Properties (Hierarchy)**

Use **indentation** (spaces, not tabs):

```yaml
server:
  port: 8080
  servlet:
    context-path: /api
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/db
    username: root
    password: secret
```

✅ Each level is indented by 2 spaces (convention).

---

### **3. Lists**

Define arrays with a dash:

```yaml
app:
  servers:
    - host: server1
      port: 8080
    - host: server2
      port: 8081
```

Or a simple list:

```yaml
features:
  - login
  - signup
  - leaderboard
```

---

### **4. Environment Profiles**

You can separate configurations per environment:

```yaml
spring:
  profiles:
    active: dev

---
spring:
  profiles: dev
  datasource:
    url: jdbc:mysql://localhost:3306/dev_db

---
spring:
  profiles: prod
  datasource:
    url: jdbc:mysql://localhost:3306/prod_db
```

Spring will automatically pick the section matching the active profile.

---

### **5. Using `${}` for placeholders**

You can reference other properties:

```yaml
app:
  name: UltimateArcade
  welcomeMessage: "Welcome to ${app.name}!"
```

Then inject it in Java:

```java
@Value("${app.welcomeMessage}")
private String message;
```

Result: `"Welcome to UltimateArcade!"`

---

### **6. Important Rules**

- **No tabs**: YAML uses spaces only.
    
- **Indent consistently** (usually 2 spaces per level).
    
- **Dashes** indicate list items.
    
- **Colon followed by space** separates key and value: `key: value`.
    

---




##### Tags : [[0 - Spring Framework]]