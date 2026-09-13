
![[Pasted image 20251113121104.png]]

### Key Differences Between HTTP and WebSocket

| Aspect                  | **HTTP** (HyperText Transfer Protocol) | **WebSocket** |
|-------------------------|----------------------------------------|---------------|
| **Communication Model** | **Request-Response** (stateless): Client sends a request, server responds once, then connection closes (or persists briefly in HTTP/1.1 keep-alive). | **Full-Duplex** (bidirectional): After handshake, both client and server can send messages **at any time** over a single, long-lived connection. |
| **Connection Type**     | Short-lived (typically closed after response). HTTP/2+ allows multiplexing but still request-response. | Persistent, long-lived TCP connection. |
| **Initiation**          | Client initiates with `GET`, `POST`, etc. Server cannot push without client request (except Server-Sent Events or polling). | Starts with an **HTTP handshake** (`Upgrade: websocket`), then upgrades to WebSocket protocol (`ws://` or `wss://`). |
| **Data Flow**           | Unidirectional per request: Client → Server → Client. | Bidirectional: Client ↔ Server simultaneously. |
| **Overhead**            | High: Each request has headers (cookies, auth, etc.). Repeated for polling. | Low after handshake: Minimal framing overhead; efficient for frequent messages. |
| **Use Cases**           | Fetching web pages, APIs, form submissions, file downloads. | Real-time apps: chat, live notifications, gaming, stock tickers, collaborative editing. |
| **Protocol**            | `http://` or `https://` | `ws://` or `wss://` (WebSocket over TLS) |
| **Latency**             | Higher for real-time (requires polling or long-polling). | Lower: instant push from server without client polling. |
| **Statefulness**        | Stateless by design (state managed via cookies/sessions). | Stateful: connection remains open; server knows client is connected. |
| **Fallbacks**           | Long-polling, Server-Sent Events (SSE) for pseudo-real-time. | Falls back to polling if WebSocket fails (e.g., behind proxies). |

---

### How WebSocket Works (Simplified)
1. Client sends an HTTP request with:
   ```
   GET /chat HTTP/1.1
   Upgrade: websocket
   Connection: Upgrade
   Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==
   ```
2. Server responds:
   ```
   HTTP/1.1 101 Switching Protocols
   Upgrade: websocket
   Sec-WebSocket-Accept: HSmrc0sMlYUkAGmm5OPpG2HaGWk=
   ```
3. Connection upgrades → now uses **WebSocket protocol** (not HTTP).
4. Both sides send **frames** (text/binary) freely.

---

### Analogy
- **HTTP**: Like sending letters (you mail a request, wait for a reply, then mail again).
- **WebSocket**: Like a phone call (open line, talk back and forth instantly).

---

### Summary
Use **HTTP** for traditional web requests.  
Use **WebSocket** when you need **real-time, two-way communication** with low latency.

[[Read Projects]]