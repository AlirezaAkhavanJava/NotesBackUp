

## `WebSocketSession` – **The Raw WebSocket Connection Object**

`WebSocketSession` is a **Spring abstraction** that represents **one active WebSocket connection** between a **client and server**.

> **Think of it as**:  
> *"The phone line to a single user — with their ID, attributes, and ability to send messages."*

---

### Package
```java
org.springframework.web.socket.WebSocketSession
```

---

## Where It Comes From

| Source | How You Get It |
|-------|----------------|
| `@Controller` with `@SubscribeMapping`, `@MessageMapping` | Not directly — use `SimpMessageHeaderAccessor` |
| **Low-level handler** (`WebSocketHandler`) | `afterConnectionEstablished(WebSocketSession session)` |
| `SessionConnectEvent`, `SessionDisconnectEvent` | `event.getSessionId()` → lookup via `SimpUserRegistry` |

---

## Core Methods

| Method | Purpose |
|-------|--------|
| `getId()` | Unique session ID (e.g., `ws-abc123`) |
| `getRemoteAddress()` | Client IP + port |
| `getPrincipal()` | Authenticated user (`Principal`) |
| `getAttributes()` | `Map<String, Object>` for custom data |
| `sendMessage(WebSocketMessage<?> message)` | Send **text or binary** |
| `isOpen()` | `true` if connection alive |
| `close()` / `close(CloseStatus)` | Terminate connection |
| `getUri()` | Original handshake URL (`/ws?token=xyz`) |
| `getExtensions()` | Negotiated WebSocket extensions |

---

## When to Use `WebSocketSession`

| Use Case | Use `WebSocketSession`? |
|--------|-------------------------|
| **STOMP + `@MessageMapping`** | No — use `SimpMessagingTemplate` |
| **Raw WebSocket (no STOMP)** | Yes — full control |
| **Push to one user** | Yes — if you have the session |
| **Track online users** | Yes — store in a `ConcurrentHashMap<String, WebSocketSession>` |

---

## Example 1: Raw WebSocket Handler (No STOMP)

```java
@Component
public class MyWebSocketHandler implements WebSocketHandler {

    private final Map<String, WebSocketSession> sessions = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        sessions.put(session.getId(), session);
        System.out.println("Connected: " + session.getId());
    }

    @Override
    public void handleMessage(WebSocketSession session, WebSocketMessage<?> message) {
        String payload = (String) message.getPayload();
        System.out.println("Received: " + payload);

        // Echo back
        session.sendMessage(new TextMessage("Echo: " + payload));
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable ex) {
        System.out.println("Error: " + ex.getMessage());
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        sessions.remove(session.getId());
        System.out.println("Disconnected: " + session.getId());
    }

    @Override
    public boolean supportsPartialMessages() {
        return false;
    }

    // Helper: send to all
    public void broadcast(String message) {
        TextMessage msg = new TextMessage(message);
        sessions.values().stream()
                .filter(WebSocketSession::isOpen)
                .forEach(session -> {
                    try {
                        session.sendMessage(msg);
                    } catch (IOException e) {
                        // ignore
                    }
                });
    }
}
```

---

## Register Handler

```java
@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    @Autowired
    private MyWebSocketHandler handler;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(handler, "/raw-ws")
                .setAllowedOrigins("*");
    }
}
```

Client:
```js
const ws = new WebSocket("ws://localhost:8080/raw-ws");
ws.onmessage = e => console.log(e.data);
ws.send("Hello");
```

---

## Example 2: Get `WebSocketSession` from STOMP Event

```java
@EventListener
public void handleSessionConnected(SessionConnectedEvent event) {
    StompHeaderAccessor accessor = StompHeaderAccessor.wrap(event.getMessage());
    String sessionId = accessor.getSessionId();

    // Find session via registry
    WebSocketSession session = findSessionById(sessionId);
    if (session != null) {
        session.getAttributes().put("connectedAt", System.currentTimeMillis());
    }
}
```

---

## Example 3: Push to Specific User (STOMP + Raw)

```java
@Service
public class NotificationService {

    private final SimpUserRegistry userRegistry;
    private final SimpMessagingTemplate messagingTemplate;

    // For raw sessions
    private final Map<String, WebSocketSession> rawSessions = new ConcurrentHashMap<>();

    // Send via STOMP (preferred)
    public void sendToUser(String username, String message) {
        messagingTemplate.convertAndSendToUser(username, "/queue/notifications", message);
    }

    // Send via raw session
    public void sendRaw(String sessionId, String message) {
        WebSocketSession session = rawSessions.get(sessionId);
        if (session != null && session.isOpen()) {
            try {
                session.sendMessage(new TextMessage(message));
            } catch (IOException e) {
                // handle
            }
        }
    }
}
```

---

## `WebSocketSession` vs `SimpUser` vs `SimpSession`

| Concept | Scope | Use |
|--------|-------|-----|
| `WebSocketSession` | **1 TCP connection** | Raw WebSocket |
| `SimpSession` | **1 STOMP session** (can have multiple subscriptions) | STOMP-level |
| `SimpUser` | **1 authenticated user** (can have multiple sessions) | User-level messaging |

```java
SimpUser user = userRegistry.getUser("alice");
for (SimpSession s : user.getSessions()) {
    String sessionId = s.getId();
    // send to all devices of alice
}
```

---

## Common Patterns

### 1. Store Session on Connect

```java
@EventListener
public void onConnect(SessionConnectEvent event) {
    String sessionId = event.getSessionId();
    // Store in service
    sessionService.addSession(sessionId, event.getWebSocketSession());
}
```

### 2. Clean Up on Disconnect

```java
@EventListener
public void onDisconnect(SessionDisconnectEvent event) {
    String sessionId = event.getSessionId();
    sessionService.removeSession(sessionId);
}
```

---

## Important Notes

| Warning | Details |
|-------|--------|
| **Thread Safety** | `WebSocketSession` is **not thread-safe** — don’t share across threads |
| **Don’t Hold Forever** | Sessions can be closed — always check `isOpen()` |
| **Memory Leak Risk** | Always remove from maps on `afterConnectionClosed` |
| **STOMP vs Raw** | Prefer STOMP + `SimpMessagingTemplate` unless you need binary/control |

---

## Summary

| Feature | `WebSocketSession` |
|-------|---------------------|
| Represents | One WebSocket connection |
| Use with | `WebSocketHandler`, events |
| Send message | `sendMessage(new TextMessage("hi"))` |
| Get user | `getPrincipal()` |
| Get IP | `getRemoteAddress()` |
| Best for | Raw WebSocket, custom protocols |

---

## Pro Tip

> **Use `SimpMessagingTemplate` for STOMP apps**  
> **Use `WebSocketSession` only when you need raw control**




[[Read Projects]]