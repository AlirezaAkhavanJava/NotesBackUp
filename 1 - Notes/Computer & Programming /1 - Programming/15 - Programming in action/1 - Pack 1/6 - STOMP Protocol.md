

## **STOMP Protocol**  
**Simple (or Streaming) Text Oriented Messaging Protocol**

A **lightweight, text-based messaging protocol** that runs **over WebSocket** (or raw TCP) to enable **real-time, bidirectional communication** using a **publish-subscribe (pub/sub)** model.

---

### Core Idea
> **"Send human-readable commands like `SEND`, `SUBSCRIBE`, `MESSAGE` over a frame-based protocol."**

Think of it as **"HTTP-like headers + body"** but for **messaging**, not requests.

---

## STOMP Frame Format

```
COMMAND
header1:value1
header2:value2

body^@   (null byte terminates frame)
```

> **Note**: Frame ends with a **null byte (`\0`)** — not `\n`.

---

## Key STOMP Commands

| Command | Direction | Purpose |
|--------|-----------|--------|
| `CONNECT` | Client → Server | Start session |
| `CONNECTED` | Server → Client | Handshake response |
| `SEND` | Client → Server | Publish message to a destination |
| `SUBSCRIBE` | Client → Server | Listen to a destination |
| `UNSUBSCRIBE` | Client → Server | Stop listening |
| `MESSAGE` | Server → Client | Deliver message to subscriber |
| `ACK` / `NACK` | Client → Server | Confirm receipt (QoS) |
| `DISCONNECT` | Client → Server | Close session |
| `ERROR` | Server → Client | Something went wrong |

---

## Example: Client Connects & Sends Message

### 1. `CONNECT`

```stomp
CONNECT
accept-version:1.2
host:localhost

^@
```

### 2. `CONNECTED`

```stomp
CONNECTED
version:1.2
session:abc123
server:Spring-STOMP/2.0

^@
```

### 3. `SUBSCRIBE` to `/topic/chat`

```stomp
SUBSCRIBE
id:sub-1
destination:/topic/chat

^@
```

### 4. `SEND` to `/app/chat.send`

```stomp
SEND
destination:/app/chat.send
content-type:application/json

{"from":"Alice","text":"Hi!"}
^@
```

### 5. `MESSAGE` (delivered to all subscribers)

```stomp
MESSAGE
destination:/topic/chat
message-id:msg-123
subscription:sub-1
content-type:application/json

{"from":"Alice","text":"Hi!"}
^@
```

---

## Destinations (Like URLs)

| Prefix | Meaning |
|-------|--------|
| `/topic/...` | **Broadcast** (one-to-many) |
| `/queue/...` | **Point-to-point** (one-to-one) |
| `/app/...` | **Application-processed** (goes to `@MessageMapping`) |
| `/user/...` | **User-specific** (e.g., `/user/queue/private`) |

---

## STOMP over WebSocket (How It Works)

1. **WebSocket handshake** (`/ws`)
2. After `101 Switching Protocols`, send **STOMP frames** as **text messages**
3. No more HTTP — just STOMP commands

```js
// JavaScript (SockJS + STOMP)
const socket = new SockJS('/ws');
const client = Stomp.over(socket);

client.connect({}, () => {
    client.subscribe('/topic/chat', msg => {
        console.log(JSON.parse(msg.body));
    });

    client.send('/app/chat.send', {}, JSON.stringify({from: 'Bob', text: 'Hey!'}));
});
```

---

## STOMP Headers (Important Ones)

| Header | Example | Purpose |
|-------|--------|--------|
| `destination` | `/topic/news` | Where message goes |
| `content-type` | `application/json` | Body format |
| `content-length` | `25` | Optional (if no null byte) |
| `receipt` | `rec-123` | Request receipt |
| `id` | `sub-1` | Subscription ID |
| `ack` | `client` / `auto` | Message acknowledgment mode |

---

## Message Acknowledgment (QoS)

```stomp
SUBSCRIBE
id:sub-1
destination:/queue/orders
ack:client   ← client must ACK each message
```

Then for each `MESSAGE`:

```stomp
ACK
id:msg-456
subscription:sub-1
```

> Prevents message loss in unreliable networks.

---

## STOMP vs WebSocket (Raw)

| Feature | Raw WebSocket | STOMP over WebSocket |
|--------|----------------|------------------------|
| Protocol | Binary/Text frames | Structured frames (`SEND`, `SUBSCRIBE`) |
| Routing | You code it | Built-in `destination` routing |
| Pub/Sub | Manual | Automatic via broker |
| Interoperability | Low | High (many clients/servers) |
| Debugging | Hard (binary) | Easy (text frames) |

---

## STOMP Clients (All Languages)

| Language | Client Library |
|--------|----------------|
| JavaScript | `stompjs`, `@stomp/stompjs` |
| Java | Spring Messaging, `stomp-client` |
| Python | `stomp.py` |
| .NET | `STOMP.Client` |
| Go | `go-stomp` |
| Ruby | `stomp` gem |

---

## STOMP Brokers

| Broker | Use With Spring |
|--------|------------------|
| **In-memory** (SimpleBroker) | `enableSimpleBroker("/topic")` |
| **RabbitMQ** | `enableStompBrokerRelay(...)` |
| **ActiveMQ** | Same |
| **Artemis** | Same |

---

## Spring Boot + STOMP Example

```java
@EnableWebSocketMessageBroker
@Configuration
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws").withSockJS();
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic", "/queue");
        registry.setApplicationDestinationPrefixes("/app");
    }
}
```

```java
@Controller
public class ChatController {

    @MessageMapping("/chat.send")
    @SendTo("/topic/messages")
    public Message send(Message msg) {
        return msg;
    }
}
```

---

## Summary: Why Use STOMP?

| You Want | Use STOMP |
|---------|----------|
| Simple pub/sub | Yes |
| Works with many clients | Yes |
| Human-readable in logs | Yes |
| Built-in routing & QoS | Yes |
| Interop with RabbitMQ/ActiveMQ | Yes |

> **STOMP = "Pub/Sub over WebSocket with structure"**




[[Read Projects]]