
## `@MessageMapping` – **"Route WebSocket Messages Like HTTP Endpoints!"**

`@MessageMapping` is a **Spring Messaging annotation** that maps **STOMP messages** sent to a **destination** (like `/app/chat.send`) to a **method in your `@Controller`**.

> **Think of it as**:  
> `@RequestMapping` for **WebSocket/STOMP** instead of HTTP.

---

### Where It Works

| Requirement | Details |
|-----------|--------|
| `@EnableWebSocketMessageBroker` | Must be in config |
| `implements WebSocketMessageBrokerConfigurer` | Optional, for config |
| `@Controller` (or `@Component`) | Class must be Spring bean |
| Client sends to `/app/...` | Set via `setApplicationDestinationPrefixes("/app")` |

---

## Basic Syntax

```java
@Controller
public class ChatController {

    @MessageMapping("/chat.send")
    @SendTo("/topic/messages")
    public ChatMessage sendMessage(@Payload ChatMessage message) {
        message.setTimestamp(Instant.now());
        return message;
    }
}
```

---

## Full Flow

```
Client
  ↓ SEND /app/chat.send
  ↓ JSON: {"from":"Alice","text":"Hi!"}
      ↓ @MessageMapping("/chat.send")
      ↓ method runs
      ↓ @SendTo("/topic/messages") → broadcast
          ↓ All subscribers to /topic/messages get JSON
```

---

## Key Annotations Used With `@MessageMapping`

| Annotation | Purpose |
|----------|--------|
| `@Payload` | Inject message body (auto-converted) |
| `@Header` / `@Headers` | Inject STOMP headers |
| `@DestinationVariable` | Extract path variables |
| `@SendTo` | Where to send response |
| `@SendToUser` | Send only to sender |
| `SimpMessageHeaderAccessor` | Full access to headers/session |

---

## 1. **Simple Echo**

```java
@MessageMapping("/echo")
@SendTo("/topic/echo")
public String echo(@Payload String text) {
    return "Server echoes: " + text;
}
```

Client:
```js
stompClient.send("/app/echo", {}, "Hello");
```

---

## 2. **Path Variables** (`@DestinationVariable`)

```java
@MessageMapping("/game/{gameId}/move")
@SendTo("/topic/game/{gameId}")
public MoveResponse makeMove(
        @DestinationVariable String gameId,
        @Payload Move move) {
    return gameService.processMove(gameId, move);
}
```

Client:
```js
stompClient.send("/app/game/123/move", {}, JSON.stringify({from:1, to:2}));
```

---

## 3. **Private Response** (`@SendToUser`)

```java
@MessageMapping("/private.message")
@SendToUser("/queue/reply")
public String handlePrivate(@Payload String msg, Principal user) {
    return "Hi " + user.getName() + ", you said: " + msg;
}
```

→ Only sender gets reply at `/user/queue/reply`

---

## 4. **Headers Access**

```java
@MessageMapping("/greet")
@SendTo("/topic/greetings")
public String greet(
        @Payload String name,
        @Header("lang") String lang,
        @Header("session-id") String sessionId) {
    
    return lang.equals("es") ? "Hola " + name : "Hello " + name;
}
```

Client:
```js
stompClient.send("/app/greet", {lang: "es"}, "Juan");
```

---

## 5. **Full Control with `SimpMessageHeaderAccessor`**

```java
@MessageMapping("/track")
public void trackEvent(@Payload Event event,
                       SimpMessageHeaderAccessor headers) {
    String sessionId = headers.getSessionId();
    String username = (String) headers.getSessionAttributes().get("user");
    analytics.log(sessionId, username, event);
}
```

---

## 6. **Return `void` + Manual Send**

```java
@MessageMapping("/notify")
public void notifyAdmins(@Payload Alert alert,
                         SimpMessagingTemplate template) {
    template.convertAndSendToUser("admin", "/queue/alerts", alert);
}
```

---

## 7. **Validation**

```java
@MessageMapping("/user.register")
public void register(@Valid @Payload UserRegistration user) {
    userService.save(user);
}
```

→ Invalid → `MessageDeliveryException` → `ERROR` frame to client

---

## Configuration (Required)

```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws").withSockJS();
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/queue");
        config.setApplicationDestinationPrefixes("/app");  // Critical!
    }
}
```

> **All `@MessageMapping` paths are prefixed with `/app`**

---

## Destination Mapping Rules

| Client Sends To | Mapped To |
|----------------|----------|
| `/app/chat.send` | `@MessageMapping("/chat.send")` |
| `/app/game/123/move` | `@MessageMapping("/game/{id}/move")` |
| `/app/user/register` | `@MessageMapping("/user.register")` |

---

## `@MessageMapping` vs `@SubscribeMapping`

| Annotation | When |
|----------|------|
| `@MessageMapping` | Client **sends** (`SEND`) |
| `@SubscribeMapping` | Client **subscribes** (`SUBSCRIBE`) → get initial data |

```java
@SubscribeMapping("/topic/news")
public List<News> getNews() {
    return newsService.getLatest();
}
```

---

## Exception Handling

```java
@ControllerAdvice
public class WebSocketExceptionHandler {

    @ExceptionHandler(ValidationException.class)
    @SendToUser("/queue/errors")
    public ErrorResponse handleValidation(ValidationException ex) {
        return new ErrorResponse("Invalid data", ex.getMessage());
    }
}
```

---

## Summary Table

| Feature | `@MessageMapping` |
|-------|-------------------|
| Maps | `/app/...` → method |
| Payload | Auto-converted via `@Payload` |
| Return | Sent to `@SendTo` or `@SendToUser` |
| Path vars | `@DestinationVariable` |
| Headers | `@Header` |
| Validation | `@Valid` |
| Async | Return `Mono`/`Flux` (with WebFlux) |

---

## Pro Tips

| Tip | Why |
|-----|-----|
| **Always use `/app` prefix** | Set in `configureMessageBroker` |
| **Use POJOs + `@Payload` + `@Valid`** | Type-safe, clean |
| **Use `@SendToUser` for private replies** | Security + efficiency |
| **Avoid blocking calls** | Use `@Async` or reactive |

---

## Full Working Example

```java
@Controller
public class GameController {

    @MessageMapping("/game/{id}/join")
    @SendTo("/topic/game/{id}")
    public GameState joinGame(
            @DestinationVariable String id,
            @Payload String username,
            Principal user) {
        return gameService.addPlayer(id, username);
    }

    @MessageMapping("/game/{id}/move")
    @SendTo("/topic/game/{id}")
    public GameState makeMove(
            @DestinationVariable String id,
            @Payload Move move,
            Principal user) {
        return gameService.move(id, user.getName(), move);
    }
}
```

---




[[Read Projects]]