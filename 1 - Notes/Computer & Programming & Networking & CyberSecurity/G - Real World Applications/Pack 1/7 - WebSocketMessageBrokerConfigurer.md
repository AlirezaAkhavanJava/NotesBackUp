

## `WebSocketMessageBrokerConfigurer` – The **Spring WebSocket Configuration Interface**

This is a **callback interface** used with `@EnableWebSocketMessageBroker` to **customize** how STOMP over WebSocket works in a Spring application.

---

### Purpose

> **"Let me configure the message broker, endpoints, and client inbound/outbound channels."**

When you annotate a config class with:

```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer { ... }
```

…you gain full control over:

| Area | What You Can Customize |
|------|------------------------|
| **Endpoints** | Where clients connect (`/ws`, `/socket`, etc.) |
| **Message Broker** | In-memory vs RabbitMQ/ActiveMQ, prefixes |
| **Channels** | Interceptors, authentication, logging |
| **Serialization** | JSON, custom message converters |

---

## Key Methods (You Override These)

| Method | Purpose | Example |
|-------|--------|--------|
| `registerStompEndpoints()` | Define **WebSocket handshake URLs** | `/ws`, `/chat` |
| `configureMessageBroker()` | Set up **broker & prefixes** | `/topic`, `/app` |
| `configureClientInboundChannel()` | Intercept **messages from client** | Add auth, logging |
| `configureClientOutboundChannel()` | Intercept **messages to client** | Rate limiting |
| `configureWebSocketTransport()` | Tune **WebSocket settings** | Message size, timeouts |

---

### 1. `registerStompEndpoints(StompEndpointRegistry registry)`

```java
@Override
public void registerStompEndpoints(StompEndpointRegistry registry) {
    registry.addEndpoint("/ws")           // ws://localhost:8080/ws
            .setAllowedOriginPatterns("*") // CORS
            .withSockJS();                 // Fallback for old browsers
}
```

- `.addEndpoint("/ws")` → Client connects via `new SockJS('/ws')`
- `.withSockJS()` → Enables fallback (long-polling) if WebSocket fails
- `.setAllowedOriginPatterns("*")` → Allow any origin (or restrict)

---

### 2. `configureMessageBroker(MessageBrokerRegistry config)`

```java
@Override
public void configureMessageBroker(MessageBrokerRegistry config) {
    config.enableSimpleBroker("/topic", "/queue");     // In-memory broker
    config.setApplicationDestinationPrefixes("/app"); // @MessageMapping prefix
    config.setUserDestinationPrefix("/user");         // /user/queue/reply
}
```

| Setting | Meaning |
|-------|--------|
| `enableSimpleBroker("/topic")` | Server can push to `/topic/...` |
| `setApplicationDestinationPrefixes("/app")` | Client sends to `/app/...` → goes to `@MessageMapping` |
| `setUserDestinationPrefix("/user")` | Enables `/user/{session}/queue/...` |

---

### 3. `configureClientInboundChannel()` – From Client

```java
@Override
public void configureClientInboundChannel(ChannelRegistration registration) {
    registration.interceptors(new MyAuthInterceptor());
}
```

Use case: **Authenticate every STOMP message**

```java
public class MyAuthInterceptor implements ChannelInterceptor {
    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = StompHeaderAccessor.wrap(message);
        if (StompCommand.SEND.equals(accessor.getCommand())) {
            String token = accessor.getFirstNativeHeader("Auth");
            if (!isValidToken(token)) throw new SecurityException("Bad token");
        }
        return message;
    }
}
```

---

### 4. `configureClientOutboundChannel()` – To Client

```java
@Override
public void configureClientOutboundChannel(ChannelRegistration registration) {
    registration.taskExecutor(outboundExecutor());
}

private TaskExecutor outboundExecutor() {
    ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
    executor.setCorePoolSize(4);
    return executor;
}
```

Use case: **Scale message delivery**, prevent blocking

---

### 5. `configureWebSocketTransport()` – Low-level Tuning

```java
@Override
public void configureWebSocketTransport(WebSocketTransportRegistration registration) {
    registration.setMessageSizeLimit(128 * 1024);     // 128 KB
    registration.setSendTimeLimit(15 * 1000);         // 15 sec
    registration.setSendBufferSizeLimit(512 * 1024);  // 512 KB
}
```

Prevents OOM from large messages.

---

## Full Example: Production-Ready Config

```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("https://mydomain.com")
                .withSockJS();
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        // Use RabbitMQ in production
        registry.enableStompBrokerRelay("/topic", "/queue")
                .setRelayHost("rabbitmq")
                .setRelayPort(61613)
                .setClientLogin("guest")
                .setClientPasscode("guest");

        registry.setApplicationDestinationPrefixes("/app");
        registry.setUserDestinationPrefix("/user");
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration reg) {
        reg.interceptors(new AuthChannelInterceptor());
    }

    @Override
    public void configureWebSocketTransport(WebSocketTransportRegistration reg) {
        reg.setMessageSizeLimit(64 * 1024);
        reg.setSendBufferSizeLimit(512 * 1024);
    }
}
```

---

## Message Flow with Config

```
Client
  ↓ CONNECT → /ws
  ↓ SEND → /app/chat.send
      ↓ @MessageMapping("/chat.send")
      ↓ @SendTo("/topic/public")
          ↓ Broker → /topic/public
              ↓ All subscribers
```

---

## Common Patterns

| Goal | How |
|------|-----|
| **Private messages** | Use `/user/{username}/queue/private` |
| **Presence tracking** | Subscribe to `/topic/online`, send `CONNECT`/`DISCONNECT` |
| **Heartbeats** | Enable in `registerStompEndpoints().setHandshakeHandler(...)` |
| **Rate limiting** | Add interceptor in `inboundChannel` |

---

## Dependencies (Maven)

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-websocket</artifactId>
</dependency>
```

---

## Summary

| You Want To… | Override This Method |
|--------------|------------------------|
| Define `/ws` endpoint | `registerStompEndpoints()` |
| Use RabbitMQ | `configureMessageBroker()` |
| Add JWT auth | `configureClientInboundChannel()` |
| Scale sending | `configureClientOutboundChannel()` |
| Limit message size | `configureWebSocketTransport()` |

---

**Pro Tip**:  
Use **`@EnableWebSocketMessageBroker` + `WebSocketMessageBrokerConfigurer`** = Full control over real-time messaging.

---



[[Read Projects]]