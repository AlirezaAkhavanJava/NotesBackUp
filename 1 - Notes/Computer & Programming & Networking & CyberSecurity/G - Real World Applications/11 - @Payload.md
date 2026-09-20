
## `@Payload` – **"Grab the message body automatically!"**

`@Payload` is a **Spring Messaging annotation** that **injects the message body** (payload) into a method parameter — **no manual parsing needed**.

> **Think of it as**:  
> *“Hey Spring, put the JSON/text from the WebSocket message right into this object.”*

---

### Where It Works

| Annotation | Context |
|----------|--------|
| `@MessageMapping` | STOMP over WebSocket |
| `@SubscribeMapping` | STOMP subscription |
| `@RabbitListener`, `@KafkaListener` | Message queues |
| Any `@Controller` with `SimpMessagingTemplate` | Spring Messaging |

---

## Basic Example: Chat App

```java
@Controller
public class ChatController {

    @MessageMapping("/chat.send")
    @SendTo("/topic/messages")
    public ChatMessage handle(@Payload ChatMessage message) {
        // `message` is auto-converted from JSON
        message.setTimestamp(Instant.now());
        return message;
    }
}
```

### Client sends:
```json
{"from": "Alice", "text": "Hi!"}
```

### Spring does:
```java
ChatMessage message = objectMapper.readValue(json, ChatMessage.class);
handle(message);  // @Payload injects it
```

---

## `@Payload` + Validation

```java
@MessageMapping("/user.register")
public void register(@Payload @Valid UserRegistration registration) {
    // If invalid → MethodArgumentNotValidException → ERROR frame
}
```

```java
public class UserRegistration {
    @NotBlank private String username;
    @Email private String email;
    // getters/setters
}
```

---

## `@Payload` with Custom Converter

By default: **Jackson JSON** (`MappingJackson2MessageConverter`)

### Want XML? Protobuf? String?

```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic");
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws").withSockJS();
    }

    @Override
    public void configureMessageConverters(List<MessageConverter> converters) {
        // Add custom converter (e.g., for String, XML, etc.)
        converters.add(new MappingJackson2MessageConverter());
    }
}
```

---

## Common Patterns

### 1. **Raw String Payload**

```java
@MessageMapping("/echo")
@SendTo("/topic/echo")
public String echo(@Payload String text) {
    return "Server says: " + text;
}
```

Client:
```js
stompClient.send("/app/echo", {}, "Hello");
```

---

### 2. **Binary Payload (e.g., Image)**

```java
@MessageMapping("/upload")
public void handleImage(@Payload byte[] imageData,
                        @Header("filename") String filename) {
    fileService.save(filename, imageData);
}
```

> Requires `content-type: application/octet-stream`

---

### 3. **With `@Header`**

```java
@MessageMapping("/greet")
@SendTo("/topic/greetings")
public String greet(@Payload String name,
                    @Header("lang") String language) {
    return language.equals("es") ? "Hola " + name : "Hello " + name;
}
```

Client:
```js
stompClient.send("/app/greet", {lang: "es"}, "Maria");
```

---

### 4. **With `SimpMessageHeaderAccessor`**

```java
@MessageMapping("/private")
public void sendPrivate(@Payload String text,
                        SimpMessageHeaderAccessor headers) {
    String sessionId = headers.getSessionId();
    String username = (String) headers.getSessionAttributes().get("user");
    // ...
}
```

---

## Full Flow

```
Client
  ↓ SEND /app/chat.send
  ↓ JSON: {"from":"Bob","text":"Hi"}
      ↓ @Payload → ChatMessage object
      ↓ @MessageMapping method runs
      ↓ @SendTo("/topic/messages") → broadcast
          ↓ All subscribers get JSON
```

---

## `@Payload` vs Manual Parsing

| Without `@Payload` | With `@Payload` |
|--------------------|-----------------|
| ```java

---

## Important Notes

| Rule | Details |
|------|--------|
| **One `@Payload` per method** | Only one parameter can have it |
| **Must match content-type** | JSON → `application/json`, etc. |
| **Validation works** | Use `@Valid` |
| **Null if no body** | Be careful with optional payloads |
| **Works with `@SubscribeMapping`** | Returns initial data on subscribe |

---

## Example: `@SubscribeMapping`

```java
@SubscribeMapping("/topic/news")
public List<News> getInitialNews() {
    return newsService.getLatest(10);
}
```

Client subscribes → gets initial list immediately.

---

## Summary

| Feature | `@Payload` |
|--------|-----------|
| **Injects** | Message body |
| **Auto-converts** | JSON → POJO (via Jackson) |
| **Works with** | `@MessageMapping`, `@SubscribeMapping` |
| **Supports** | `@Valid`, `@Header`, custom converters |
| **Zero boilerplate** | No `ObjectMapper` needed |

---

## Pro Tip

> **Always use `@Payload` + POJO + `@Valid`**  
> → Clean, type-safe, validated messaging




[[Read Projects]]