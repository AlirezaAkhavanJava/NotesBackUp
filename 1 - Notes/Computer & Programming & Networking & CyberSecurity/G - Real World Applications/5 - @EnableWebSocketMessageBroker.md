
`@EnableWebSocketMessageBroker` is a **Spring Framework annotation** (from **Spring WebSocket**) that **enables a WebSocket message broker** using the **STOMP protocol** over WebSocket.

It turns your Spring application into a **real-time messaging server** (like a chat app, live notifications, etc.) using a **publish-subscribe (pub/sub)** model.

---

### What It Does

When you add `@EnableWebSocketMessageBroker` to a `@Configuration` class:

```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig {
    // ...
}
```

It:

1. **Enables WebSocket** support
2. **Activates STOMP** (Simple Text Oriented Messaging Protocol) over WebSocket
3. Sets up a **message broker** for routing messages between clients
4. Allows **@MessageMapping** controllers (like `@RequestMapping` but for WebSocket)

---

### Required: Implement `WebSocketMessageBrokerConfigurer`

```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/queue");  // Server → Client
        config.setApplicationDestinationPrefixes("/app"); // Client → Server
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws").withSockJS(); // WebSocket handshake endpoint
    }
}
```

---

### Breakdown of Key Methods

| Method | Purpose |
|-------|--------|
| `enableSimpleBroker("/topic", "/queue")` | Enables **in-memory broker** for destinations starting with `/topic` (broadcast) and `/queue` (point-to-point) |
| `setApplicationDestinationPrefixes("/app")` | Messages sent to `/app/...` go to **@MessageMapping methods** in your controllers |
| `addEndpoint("/ws")` | The **WebSocket handshake URL**: `ws://localhost:8080/ws` |
| `.withSockJS()` | Fallback for browsers/proxies that don’t support WebSocket (uses long-polling) |

---

### Example: Chat Application

#### 1. Controller (handles messages)

```java
@Controller
public class ChatController {

    @MessageMapping("/chat.send")
    @SendTo("/topic/messages")
    public ChatMessage send(ChatMessage message) {
        return new ChatMessage(message.getFrom(), message.getText());
    }
}
```

#### 2. Client (JavaScript with **SockJS + STOMP**)

```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/sockjs-client/1.6.1/sockjs.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/stomp.js/5.4.0/stomp.min.js"></script>

<script>
    const socket = new SockJS('/ws');
    const stompClient = Stomp.over(socket);

    stompClient.connect({}, function(frame) {
        stompClient.subscribe('/topic/messages', function(msg) {
            const chat = JSON.parse(msg.body);
            console.log(chat.from + ": " + chat.text);
        });

        stompClient.send("/app/chat.send", {}, JSON.stringify({
            from: "Alice",
            text: "Hello!"
        }));
    });
</script>
```

---

### Message Flow

```
Client A
   ↓ (STOMP over WebSocket)
   → /app/chat.send
       ↓
   @MessageMapping("/chat.send")
       ↓
   @SendTo("/topic/messages")
       ↓
Broker → /topic/messages → All subscribed clients (Client A, B, C...)
```

---

### Common Destinations

| Prefix | Meaning | Use Case |
|-------|--------|---------|
| `/app` | Application (processed by `@MessageMapping`) | Client → Server logic |
| `/topic` | Broadcast (one-to-many) | Chat rooms, live updates |
| `/queue` | Point-to-point | Private messages |
| `/user` | User-specific (with Spring Security) | `/user/queue/notifications` |

---

### Dependencies (Maven)

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-websocket</artifactId>
</dependency>
```

---

### Summary

| Feature | With `@EnableWebSocketMessageBroker` |
|--------|-------------------------------------|
| WebSocket | Yes |
| STOMP Protocol | Yes |
| Pub/Sub Messaging | Yes |
| In-memory Broker | Yes (`enableSimpleBroker`) |
| External Broker (RabbitMQ, ActiveMQ) | Yes (`config.enableStompBrokerRelay(...)`) |
| Fallback (SockJS) | Yes |

---

### Pro Tip: Use External Broker (Production)

```java
config.enableStompBrokerRelay("/topic", "/queue")
      .setRelayHost("rabbitmq")
      .setRelayPort(61613);
```




[[Read Projects]]