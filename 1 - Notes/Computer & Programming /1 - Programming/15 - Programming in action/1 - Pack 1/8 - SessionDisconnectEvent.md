
## `SessionDisconnectEvent` – **"A client just hung up!"**

This is a **Spring event** published **automatically** when a **STOMP/WebSocket client disconnects** (e.g., closes browser, network drop, `DISCONNECT` frame).

---

### When Is It Fired?

| Trigger | Event Published? |
|-------|------------------|
| Client sends `DISCONNECT` frame | Yes |
| Browser tab closed | Yes |
| Network failure / timeout | Yes |
| Server restarts | No (client may reconnect) |

> **Event source**: `SimpleBrokerMessageHandler` or `StompBrokerRelayMessageHandler`

---

## How to Listen to It

```java
@Component
public class WebSocketEventListener {

    @EventListener
    public void handleSessionDisconnect(SessionDisconnectEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());

        String sessionId = headerAccessor.getSessionId();
        String username = (String) headerAccessor.getSessionAttributes().get("username");

        System.out.println("User disconnected: " + username + " | Session: " + sessionId);

        // Broadcast "user left" to others
        messagingTemplate.convertAndSend("/topic/public", 
            new ChatMessage("System", username + " left the chat"));
    }

    @Autowired
    private SimpMessagingTemplate messagingTemplate;
}
```

---

## Key Info in `SessionDisconnectEvent`

| Field / Method | What You Get |
|----------------|-------------|
| `event.getMessage()` | Raw STOMP `DISCONNECT` frame |
| `event.getSessionId()` | WebSocket session ID |
| `event.getUser()` | `Principal` if authenticated |
| `event.getCloseStatus()` | `CloseStatus` (e.g., `NORMAL`, `GOING_AWAY`) |

---

### Access Session Attributes (e.g., username)

```java
@EventListener
public void onDisconnect(SessionDisconnectEvent event) {
    StompHeaderAccessor accessor = StompHeaderAccessor.wrap(event.getMessage());
    Map<String, Object> attrs = accessor.getSessionAttributes();

    String username = (String) attrs.get("username");
    if (username != null) {
        // Remove from online users
        onlineUsers.remove(username);

        // Notify others
        messagingTemplate.convertAndSend("/topic/status", 
            new StatusUpdate(username, "offline"));
    }
}
```

---

## Set Username During Connect

```java
@Override
public void registerStompEndpoints(StompEndpointRegistry registry) {
    registry.addEndpoint("/ws")
            .setHandshakeHandler(new UserHandshakeHandler())
            .withSockJS();
}
```

```java
public class UserHandshakeHandler extends DefaultHandshakeHandler {
    @Override
    protected Principal determineUser(...) {
        // Extract from query param: ws://localhost:8080/ws?user=alice
        String username = request.getParameter("user");
        return new UsernamePrincipal(username);
    }
}
```

Then in a `ChannelInterceptor`:

```java
@Override
public Message<?> preSend(Message<?> message, MessageChannel channel) {
    StompHeaderAccessor accessor = StompHeaderAccessor.wrap(message);
    if (StompCommand.CONNECT.equals(accessor.getCommand())) {
        Principal user = accessor.getUser();
        if (user != null) {
            accessor.getSessionAttributes().put("username", user.getName());
        }
    }
    return message;
}
```

---

## Common Use Cases

| Use Case | How |
|--------|-----|
| **Show "user left"** | Broadcast on disconnect |
| **Update online list** | Remove from `Set<String> onlineUsers` |
| **Cleanup resources** | Close DB connections, cancel tasks |
| **Log session duration** | Compare `CONNECT` time vs now |

---

## Example: Track Online Users

```java
@Component
public class PresenceService {

    private final Set<String> onlineUsers = ConcurrentHashMap.newKeySet();
    private final SimpMessagingTemplate template;

    @EventListener
    public void onConnect(SessionConnectEvent event) {
        String username = getUsername(event);
        if (username != null) {
            onlineUsers.add(username);
            broadcastOnlineList();
        }
    }

    @EventListener
    public void onDisconnect(SessionDisconnectEvent event) {
        String username = getUsername(event);
        if (username != null) {
            onlineUsers.remove(username);
            broadcastOnlineList();
        }
    }

    private void broadcastOnlineList() {
        template.convertAndSend("/topic/online", new ArrayList<>(onlineUsers));
    }

    private String getUsername(AbstractSubProtocolEvent event) {
        return (String) StompHeaderAccessor.wrap(event.getMessage())
                .getSessionAttributes().get("username");
    }
}
```

---

## `DISCONNECT` Frame (What Client Sends)

```stomp
DISCONNECT
receipt:123

^@
```

Server responds:

```stomp
RECEIPT
receipt-id:123

^@
```

Then closes TCP connection.

---

## Don’t Confuse With

| Event | When |
|------|------|
| `SessionConnectEvent` | After `CONNECT` frame |
| `SessionConnectedEvent` | After `CONNECTED` frame (handshake done) |
| `SessionSubscribeEvent` | On `SUBSCRIBE` |
| `SessionDisconnectEvent` | On `DISCONNECT` or abrupt close |

---

## Full Flow

```
Client → CONNECT
        ↓
Server → SessionConnectEvent
        ↓
Server → CONNECTED
        ↓
Server → SessionConnectedEvent
        ↓
... messaging ...
        ↓
Client → DISCONNECT
        ↓
Server → SessionDisconnectEvent
        ↓
Connection closed
```

---

## Summary

| Feature | `SessionDisconnectEvent` |
|-------|--------------------------|
| **Type** | Spring Application Event |
| **Triggered by** | `DISCONNECT` frame or socket close |
| **Contains** | Session ID, user, headers, attributes |
| **Use for** | Cleanup, presence, logging |

---

**Pro Tip**:  
Always **clean up session attributes** in `SessionDisconnectEvent` to avoid memory leaks.



[[Read Projects]]