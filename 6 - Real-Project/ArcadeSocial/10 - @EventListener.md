

## `@EventListener` – **"React to Anything in Spring!"**

`@EventListener` is a **Spring annotation** that lets any **Spring-managed bean** (like `@Component`, `@Service`, `@Controller`) **listen to application events** — **without boilerplate**.

> **Think of it as**:  
> *“When X happens, run this method.”*

---

### Works With
- **Built-in Spring events** (`ContextRefreshedEvent`, `SessionDisconnectEvent`, etc.)
- **Custom events** you define
- **WebSocket/STOMP events** (`SessionConnectEvent`, `SessionDisconnectEvent`)
- **Transactional events** (`@TransactionalEventListener`)

---

## Basic Syntax

```java
@Component
public class MyListener {

    @EventListener
    public void handleUserRegistered(UserRegisteredEvent event) {
        System.out.println("New user: " + event.getUsername());
    }
}
```

Spring **automatically calls** this method when a `UserRegisteredEvent` is published.

---

## How It Works (Behind the Scenes)

1. Spring scans `@EventListener` methods at startup
2. Registers them with `ApplicationEventMulticaster`
3. When `applicationContext.publishEvent(event)` is called → method runs

---

## Key Features

| Feature | Example |
|--------|--------|
| **Multiple event types** | `@EventListener({EventA.class, EventB.class})` |
| **Conditional execution** | `@EventListener(condition = "#event.active")` |
| **SpEL filtering** | `@EventListener(condition = "#event.username == 'admin'")` |
| **Async execution** | `@EventListener + @Async` |
| **Order control** | `@Order(1)` or implement `Ordered` |
| **Transactional** | `@TransactionalEventListener` |

---

## 1. Listen to **WebSocket Events**

```java
@Component
public class WebSocketEventListener {

    @EventListener
    public void onConnect(SessionConnectEvent event) {
        String sessionId = event.getSessionId();
        System.out.println("Connected: " + sessionId);
    }

    @EventListener
    public void onDisconnect(SessionDisconnectEvent event) {
        StompHeaderAccessor accessor = StompHeaderAccessor.wrap(event.getMessage());
        String username = (String) accessor.getSessionAttributes().get("username");
        System.out.println(username + " disconnected");
    }
}
```

---

## 2. **Custom Event**

```java
// 1. Define event
public class OrderCreatedEvent extends ApplicationEvent {
    private final String orderId;
    private final double amount;

    public OrderCreatedEvent(Object source, String orderId, double amount) {
        super(source);
        this.orderId = orderId;
        this.amount = amount;
    }

    // getters...
}
```

```java
// 2. Publish it
@Service
public class OrderService {

    @Autowired
    private ApplicationEventPublisher publisher;

    public void createOrder(String id, double amount) {
        // ... save order
        publisher.publishEvent(new OrderCreatedEvent(this, id, amount));
    }
}
```

```java
// 3. Listen
@Component
public class OrderListener {

    @EventListener
    public void sendEmail(OrderCreatedEvent event) {
        emailService.send("Order " + event.getOrderId() + " created!");
    }

    @EventListener
    @Async  // Runs in background
    public void logAudit(OrderCreatedEvent event) {
        auditLog.save("Order " + event.getOrderId());
    }
}
```

---

## 3. **Conditional Listening**

```java
@EventListener(condition = "#event.amount > 1000")
public void alertBigOrder(OrderCreatedEvent event) {
    alertService.highValueOrder(event.getOrderId());
}
```

---

## 4. **Transactional Events** (After Commit!)

```java
@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
public void onOrderConfirmed(OrderConfirmedEvent event) {
    // Safe: DB transaction is committed
    externalApi.notify(event.getOrderId());
}
```

> Use when you **don’t want to send email if transaction rolls back**.

---

## 5. **Multiple Events in One Method**

```java
@EventListener
public void handleAny(AbstractSubProtocolEvent event) {
    // Works for SessionConnectEvent, SessionDisconnectEvent, etc.
}
```

---

## 6. **Async + Ordered**

```java
@Component
@Order(1)
public class PriorityListener {

    @EventListener
    @Async
    public void fastResponse(UserLoginEvent event) {
        cache.update(event.getUserId());
    }
}
```

> Requires `@EnableAsync` in config.

---

## Common Built-in Events

| Event | When Fired |
|------|-----------|
| `ContextRefreshedEvent` | App startup complete |
| `ContextStartedEvent` | `context.start()` |
| `ContextStoppedEvent` | `context.stop()` |
| `ContextClosedEvent` | `context.close()` |
| `RequestHandledEvent` | After HTTP request |
| `SessionCreatedEvent` | HTTP session created |

---

## WebSocket/STOMP Events You Can Listen To

| Event | Trigger |
|------|--------|
| `SessionConnectEvent` | After `CONNECT` frame |
| `SessionConnectedEvent` | After `CONNECTED` frame |
| `SessionSubscribeEvent` | On `SUBSCRIBE` |
| `SessionUnsubscribeEvent` | On `UNSUBSCRIBE` |
| `SessionDisconnectEvent` | On `DISCONNECT` or close |

---

## Full Example: User Presence

```java
@Component
public class PresenceEventListener {

    private final Set<String> online = ConcurrentHashMap.newKeySet();
    private final SimpMessagingTemplate template;

    @EventListener
    public void onConnect(SessionConnectEvent event) {
        String username = getUsername(event);
        if (username != null) {
            online.add(username);
            broadcastOnlineUsers();
        }
    }

    @EventListener
    public void onDisconnect(SessionDisconnectEvent event) {
        String username = getUsername(event);
        if (username != null) {
            online.remove(username);
            broadcastOnlineUsers();
        }
    }

    private void broadcastOnlineUsers() {
        template.convertAndSend("/topic/online", new ArrayList<>(online));
    }

    private String getUsername(AbstractSubProtocolEvent event) {
        return (String) StompHeaderAccessor.wrap(event.getMessage())
                .getSessionAttributes().get("username");
    }
}
```

---

## Enable Async (If Needed)

```java
@Configuration
@EnableAsync
public class AsyncConfig { }
```

---

## Summary

| Feature | `@EventListener` |
|--------|------------------|
| **Zero config** | Just add to any `@Component` |
| **No interface** | No need to implement `ApplicationListener` |
| **Flexible** | SpEL, async, transactional, ordering |
| **Perfect for** | WebSocket presence, audit, notifications |

---

## Pro Tips

| Tip | Why |
|-----|-----|
| Use `@TransactionalEventListener` | Avoid sending emails on rollback |
| Use `@Async` | Don’t block main thread |
| Use `condition` | Avoid unnecessary logic |
| Use custom events | Decouple services |

---




[[Read Projects]]