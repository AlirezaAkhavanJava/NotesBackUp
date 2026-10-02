

`StompHeaderAccessor` is basically the **specialized, STOMP-focused sibling** of `SimpMessageHeaderAccessor`. 🐐

It gives you **all the tools of `SimpMessageHeaderAccessor`** but adds **STOMP-specific features**, like handling `CONNECT`, `SUBSCRIBE`, `SEND`, `DISCONNECT` frames and STOMP headers like `ack`, `transaction`, etc.

---

### **Key Points**

- Class: `org.springframework.messaging.simp.stomp.StompHeaderAccessor`
    
- Extends `SimpMessageHeaderAccessor`.
    
- Use it when you need **STOMP-specific headers**, not just generic WebSocket headers.
    
- Can **read/write STOMP frames**, like `MESSAGE`, `CONNECT`, `SUBSCRIBE`, `UNSUBSCRIBE`, `DISCONNECT`.
    

---

### **Common Usage**

```java
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.Message;

public void handleMessage(Message<?> message) {
    StompHeaderAccessor accessor = StompHeaderAccessor.wrap(message);

    // STOMP-specific headers
    String subscriptionId = accessor.getSubscriptionId();
    String sessionId = accessor.getSessionId();
    String destination = accessor.getDestination();
    String ack = accessor.getAck();
    
    // You can also set headers
    accessor.setHeader("custom-header", "my-value");
}
```

---

### **STOMP-Specific Methods**

|Method|Purpose|
|---|---|
|`getCommand()`|Returns the STOMP command (`CONNECT`, `SEND`, etc.).|
|`setCommand(StompCommand cmd)`|Set STOMP command for sending frames.|
|`getSubscriptionId()`|Get subscription ID for `SUBSCRIBE` frames.|
|`getReceipt()`|Read `receipt` header if client requested acknowledgment.|
|`getAck()`|Read `ack` mode (`auto`, `client`, `client-individual`).|

---

### **When to Use `StompHeaderAccessor`**

- You need **frame-level control** in STOMP.
    
- Access STOMP commands, subscriptions, transactions, and acks.
    
- Want to **manipulate headers** before sending or responding to a client.
    

---



[[Read Projects]]