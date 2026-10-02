
In **Spring Framework**, `@SendTo` is used in **messaging**, typically with **Spring WebSocket / STOMP** or **Spring Messaging**. It defines **where to send the return value** of a message-handling method.

Here’s the breakdown:

- **Context:** Often used with `@MessageMapping`, which handles messages from clients (like WebSocket clients).
    
- **Purpose:** After processing a message, you can automatically forward the result to a destination (topic) that subscribers can listen to.
    

### Example:

```java
@Controller
public class ChatController {

    @MessageMapping("/chat")   // listens to messages sent to /app/chat
    @SendTo("/topic/messages") // sends the return value to /topic/messages
    public Message send(Message message) {
        // process message
        return message; // automatically forwarded to /topic/messages
    }
}
```

- Client subscribes to `/topic/messages` to receive messages.
    
- When a message is sent to `/app/chat`, the controller handles it and sends the response to `/topic/messages`.
    

💡 **Tip:** `@SendTo` is optional. If you don’t use it, you can manually send messages using `SimpMessagingTemplate`.

---
## `@SendTo` – **"Send the method’s return value to this destination!"**

`@SendTo` is a **Spring Messaging annotation** that **automatically sends the return value** of a `@MessageMapping` method to a **specific STOMP destination** (like `/topic/chat`).

> **Think of it as**:  
> *“Run this method → take what it returns → broadcast to everyone subscribed here.”*

---

### Where It Works

| Annotation | Context |
|----------|--------|
| `@MessageMapping` | STOMP over WebSocket |
| `@SubscribeMapping` | Initial data on subscribe |
| Any method in `@Controller` with `@EnableWebSocketMessageBroker` | Spring Messaging |

---

## Basic Syntax

```java
@MessageMapping("/chat.send")
@SendTo("/topic/messages")
public ChatMessage send(@Payload ChatMessage msg) {
    msg.setTimestamp(Instant.now());
    return msg;  // ← This goes to /topic/messages
}
```

---

## Full Flow

```
Client A
  ↓ SEND /app/chat.send
  ↓ {"from":"Alice","text":"Hi"}
      ↓ @MessageMapping → method runs
      ↓ return ChatMessage
          ↓ @SendTo("/topic/messages")
              ↓ Broker → /topic/messages
                  ↓ Client A, B, C... (all subscribers)
```

---

## Key Features

| Feature | Example |
|-------|--------|
| **Auto-serialize return** | POJO → JSON (via Jackson) |
| **Broadcast** | One-to-many |
| **Path variables** | `@SendTo("/topic/game/{id}")` |
| **Dynamic destinations** | Use `SimpMessagingTemplate` instead |
| **Works with `@SubscribeMapping`** | Return initial state |

---

## 1. **Broadcast to All**

```java
@MessageMapping("/shout")
@SendTo("/topic/shouts")
public String shout(@Payload String text) {
    return "SERVER SHOUTS: " + text.toUpperCase();
}
```

All subscribers to `/topic/shouts` get the message.

---

## 2. **Path Variables in `@SendTo`**

```java
@MessageMapping("/game/{id}/move")
@SendTo("/topic/game/{id}")
public GameState makeMove(
        @DestinationVariable("id") String gameId,
        @Payload Move move) {
    return gameService.applyMove(gameId, move);
}
```

→ Response sent to **different topics per game**.

---

## 3. **With `@SubscribeMapping`**

```java
@SubscribeMapping("/topic/stock/{symbol}")
public StockPrice getCurrentPrice(@DestinationVariable String symbol) {
    return stockService.getLatest(symbol);
}
```

Client subscribes → gets **initial price immediately**.

---

## 4. **Return `void`?** → Nothing sent

```java
@MessageMapping("/log")
@SendTo("/topic/logs")
public void log(@Payload String msg) {
    // No return → nothing sent
    logger.info(msg);
}
```

Use `SimpMessagingTemplate` if you want to send from `void`.

---

## 5. **Send to Multiple Destinations?**

Not directly. Use `SimpMessagingTemplate`:

```java
@MessageMapping("/alert")
public void sendAlert(@Payload Alert alert,
                      SimpMessagingTemplate template) {
    template.convertAndSend("/topic/admins", alert);
    template.convertAndSend("/topic/users", new UserAlert(alert));
}
```

---

## 6. **Private Reply?** → Use `@SendToUser`

```java
@MessageMapping("/private.ping")
@SendToUser("/queue/pong")
public String pong(Principal user) {
    return "Pong to " + user.getName();
}
```

→ Only sender gets reply at `/user/queue/pong`

---

## `@SendTo` vs `@SendToUser`

| Annotation | Sends To | Use Case |
|----------|---------|--------|
| `@SendTo("/topic/x")` | **All subscribers** | Chat, live updates |
| `@SendToUser("/queue/x")` | **Only the sender** | Private replies, errors |

---

## Configuration (Required)

```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/queue");  // Enables @SendTo
        config.setApplicationDestinationPrefixes("/app");
        config.setUserDestinationPrefix("/user");      // For @SendToUser
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws").withSockJS();
    }
}
```

---

## Return Types Supported

| Type | Sent As |
|------|--------|
| `String` | Raw text |
| `POJO` | JSON (via `MappingJackson2MessageConverter`) |
| `byte[]` | Binary frame |
| `Mono<T>`, `Flux<T>` | Reactive (WebFlux) |
| `null` | No message sent |

---

## Example: Live Clock

```java
@Controller
public class ClockController {

    @MessageMapping("/clock.start")
    @SendTo("/topic/clock")
    public String startClock() {
        return LocalDateTime.now().toString();
    }
}
```

→ Every client that sends `/app/clock.start` triggers a broadcast.

---

## Example: Game State

```java
@MessageMapping("/game/{id}/join")
@SendTo("/topic/game/{id}")
public GameState join(
        @DestinationVariable String id,
        @Payload String playerName) {
    return gameService.addPlayer(id, playerName);
}
```

→ All players in game `id` see updated state.

---

## Don’t Do This

```java
@MessageMapping("/chat")
@SendTo("/topic/chat")
public void bad() {
    // No return → nothing sent!
}
```

---

## Pro Tips

| Tip | Why |
|-----|-----|
| **Use `@SendTo` for simple broadcast** | Clean, declarative |
| **Use `SimpMessagingTemplate` for logic** | Dynamic destinations, multiple sends |
| **Use `@SendToUser` for private data** | Security |
| **Return POJOs** | Auto-JSON, type-safe |
| **Avoid blocking** | Use `Mono`/`Flux` in WebFlux |

---

## Full Working Example

```java
@Controller
public class ChatController {

    private final Set<String> online = ConcurrentHashMap.newKeySet();

    @MessageMapping("/user.join")
    @SendTo("/topic/online")
    public Set<String> join(@Payload String username,
                            SimpMessageHeaderAccessor headers) {
        String sessionId = headers.getSessionId();
        headers.getSessionAttributes().put("username", username);
        online.add(username);
        return online;
    }

    @MessageMapping("/chat.send")
    @SendTo("/topic/messages")
    public ChatMessage send(@Payload ChatMessage msg) {
        return msg;
    }

    @EventListener
    public void onDisconnect(SessionDisconnectEvent event) {
        String username = (String) StompHeaderAccessor.wrap(event.getMessage())
                .getSessionAttributes().get("username");
        if (username != null) {
            online.remove(username);
            // Manual send since no @MessageMapping
            messagingTemplate.convertAndSend("/topic/online", online);
        }
    }

    @Autowired
    private SimpMessagingTemplate messagingTemplate;
}
```

---

## Summary

| Feature | `@SendTo` |
|-------|----------|
| **Sends** | Return value |
| **To** | Fixed destination |
| **Auto** | Serializes POJO → JSON |
| **With** | `@MessageMapping`, `@SubscribeMapping` |
| **Broadcast** | Yes |
| **Private** | No → use `@SendToUser` |

---


[[Read Projects]]