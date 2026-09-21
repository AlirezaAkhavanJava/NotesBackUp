
Bean is an object**, but `@Bean` is placed on a **method because the method is the factory that creates the object**.

### The key idea

```java
@Bean
public UserService userService() {
    return new UserService();
}
```

Here:

- `UserService` → the **class**
    
- `new UserService()` → creates an **object**
    
- `userService()` → a **method that creates/returns the object**
    
- `@Bean` → tells Spring: **"Take the object returned by this method and manage it as a Spring Bean."**
    

So conceptually:

```text
Spring
  │
  │ calls
  ▼
userService()
  │
  │ returns
  ▼
new UserService()
  │
  ▼
Spring ApplicationContext
  │
  └── manages this object as a Bean
```

### Why not put `@Bean` on the class?

Because Spring needs to know **how to construct the object**.

For example:

```java
@Bean
public PaymentService paymentService() {
    PaymentService service = new PaymentService();
    service.setCurrency("USD");
    service.setTimeout(5000);
    return service;
}
```

The method gives Spring both:

1. **The creation logic**
    
2. **The actual object to manage**
    

That's especially useful when you need to configure an object before giving it to Spring.

---

### `@Component` vs `@Bean`

This distinction is important:

```java
@Component
public class UserService {
}
```

Spring essentially says:

> "I discovered this class. I'll instantiate and manage it."

Whereas:

```java
@Configuration
public class AppConfig {

    @Bean
    public UserService userService() {
        return new UserService();
    }
}
```

You are saying:

> "Spring, use **this method** to create the object, and manage the returned object as a Bean."

So:

```text
@Component
    ↓
Spring discovers the CLASS
    ↓
Spring creates the OBJECT
    ↓
Bean


@Bean
    ↓
Spring discovers the METHOD
    ↓
Spring calls the METHOD
    ↓
METHOD returns OBJECT
    ↓
Bean
```

**The annotation is on the method because `@Bean` is describing the object-producing method, not the object itself.**


[[0 - Spring Framework]]
[[0 - Spring + Spring Boot]]