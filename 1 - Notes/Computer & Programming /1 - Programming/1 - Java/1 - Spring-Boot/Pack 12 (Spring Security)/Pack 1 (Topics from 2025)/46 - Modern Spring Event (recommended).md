

#  **Modern Spring Event (recommended)**

**No `ApplicationEvent` required.**  
Use **any POJO** or **record**.

### Event

```java
public record UserRegisteredEvent(Long userId) {}
```

### Publisher

```java
@Autowired
private ApplicationEventPublisher publisher;

public void registerUser(Long id) {
    publisher.publishEvent(new UserRegisteredEvent(id));
}
```

### Listener

```java
@Component
public class UserEventsListener {

    @EventListener
    public void handle(UserRegisteredEvent event) {
        System.out.println("User registered: " + event.userId());
    }
}
```

**Simple. Modern. Clean.**  
This is how Spring wants you to build events since Spring 4.2+.

---

# ❌ **Legacy event (NOT recommended)**

Uses `ApplicationEvent`, the thing you asked about.

### Event

```java
import org.springframework.context.ApplicationEvent;

public class UserRegisteredEventLegacy extends ApplicationEvent {
    private final Long userId;

    public UserRegisteredEventLegacy(Object source, Long userId) {
        super(source);
        this.userId = userId;
    }

    public Long getUserId() {
        return userId;
    }
}
```

### Publisher

```java
publisher.publishEvent(new UserRegisteredEventLegacy(this, id));
```

### Listener

```java
@EventListener
public void handle(UserRegisteredEventLegacy event) {
    System.out.println("User registered (legacy): " + event.getUserId());
}
```

**Why legacy sucks:**

- Requires extending a base class
    
- Requires passing `source` to super()
    
- More boilerplate
    
- No benefit
    

---

# 💬 Which one should _you_ use?

You (Ethan) are building modern Spring + Spring Security projects →  
**Use the modern POJO event. The legacy one only exists for backward compatibility and Spring Security internals.**

---

###### Tags : [[1 - Spring Security 🍌]]