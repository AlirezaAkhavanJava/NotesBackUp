
`SimpMessageHeaderAccessor` is a Spring **messaging helper class** that lets you **access and manipulate headers** in **STOMP/WebSocket messages**. Think of it as a toolbox for message metadata. 🐐

### Key Points:

- Part of **Spring Messaging** (`org.springframework.messaging.simp`).
    
- Works with STOMP headers like **destination, sessionId, user, native headers**.
    
- Useful for **adding custom headers**, reading **session info**, or controlling message routing.
    

---

### Example: Adding a custom header

```java
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessagingTemplate;

@Autowired
private SimpMessagingTemplate messagingTemplate;

public void sendMessage(String sessionId, String message) {
    SimpMessageHeaderAccessor headers = SimpMessageHeaderAccessor.create();
    headers.setSessionId(sessionId);
    headers.setLeaveMutable(true); // allow modifications
    headers.setHeader("custom-header", "my-value");

    messagingTemplate.convertAndSendToUser(
        sessionId, "/queue/reply", message, headers.getMessageHeaders()
    );
}
```

### Common Uses:

1. **Access session/user info:**
    
    ```java
    String sessionId = SimpMessageHeaderAccessor.getSessionId(message.getHeaders());
    Principal user = SimpMessageHeaderAccessor.getUser(message.getHeaders());
    ```
    
2. **Add custom headers before sending:**
    
    ```java
    headers.setHeader("role", "admin");
    ```
    
3. **Modify existing headers** (like `destination` or `content-type`) for advanced routing.
    

---

In short:  
🐐 **`SimpMessageHeaderAccessor` = your Swiss army knife for STOMP/WebSocket message headers in Spring.**

Here’s a **compact cheat sheet** for `SimpMessageHeaderAccessor` — your 🐐 guide for STOMP/WebSocket headers in Spring.

---

### **Creation Methods**

|Method|Use|
|---|---|
|`create()`|Creates a generic empty accessor.|
|`create(SimpMessageType type)`|Creates with a specific message type (`CONNECT`, `MESSAGE`, `SUBSCRIBE`, etc.).|
|`wrap(Message<?> message)`|Wraps an existing message so you can read/modify headers.|

---

### **Session & User**

|Method|Use|
|---|---|
|`getSessionId()`|Get WebSocket session ID.|
|`setSessionId(String id)`|Set WebSocket session ID.|
|`getUser()`|Get `Principal` user associated with the message.|
|`setUser(Principal user)`|Attach a user to the message.|

---

### **Destination & Message Info**

|Method|Use|
|---|---|
|`getDestination()`|Read message destination (e.g., `/topic/chat`).|
|`setDestination(String destination)`|Change message destination.|
|`getMessageType()`|Get message type (`CONNECT`, `MESSAGE`, `SUBSCRIBE`, etc.).|
|`setMessageType(SimpMessageType type)`|Set message type.|

---

### **Headers**

|Method|Use|
|---|---|
|`getHeader(String name)`|Read a specific header.|
|`setHeader(String name, Object value)`|Set a custom header.|
|`toMap()` / `getMessageHeaders()`|Get headers as a `Map` for sending via `SimpMessagingTemplate`.|

---

### **Misc**

|Method|Use|
|---|---|
|`setLeaveMutable(boolean flag)`|Allow further modifications to headers after creation.|
|`getSessionAttributes()`|Get WebSocket session attributes (stored in handshake).|

---

✅ **Typical Workflow**

1. Wrap or create accessor: `SimpMessageHeaderAccessor headers = SimpMessageHeaderAccessor.create();`
    
2. Modify headers: `headers.setHeader("role", "admin");`
    
3. Get headers map: `headers.getMessageHeaders()`
    
4. Send via `SimpMessagingTemplate`.
    

---



[[Read Projects]]