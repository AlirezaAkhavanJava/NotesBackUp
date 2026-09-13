

## WebSocket Handshake – Step-by-Step

The **handshake** is the **initial HTTP exchange** that upgrades a normal HTTP connection into a **persistent WebSocket** connection.

---

### 1. Client → Server (HTTP Upgrade Request)

```http
GET /chat HTTP/1.1
Host: example.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13
Origin: https://example.com
```

| Header | Purpose |
|--------|---------|
| `GET ...` | Standard HTTP method + path |
| `Upgrade: websocket` | Tells server: “switch to WebSocket” |
| `Connection: Upgrade` | Required with `Upgrade` |
| `Sec-WebSocket-Key` | Random base64-encoded 16-byte value (nonce) |
| `Sec-WebSocket-Version: 13` | WebSocket protocol version (RFC 6455) |
| `Origin` | (Optional) Helps prevent CSWSH attacks |

---

### 2. Server → Client (HTTP 101 Switching Protocols)

```http
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: HSmrc0sMlYUkAGmm5OPpG2HaGWk=
```

| Header | Purpose |
|--------|---------|
| `101 Switching Protocols` | Confirms upgrade |
| `Sec-WebSocket-Accept` | **Signed version** of client’s `Sec-WebSocket-Key` |

---

### How `Sec-WebSocket-Accept` is Generated (Server Side)

1. Take the client’s `Sec-WebSocket-Key`
2. Append the **magic string**: `258EAFA5-E914-47DA-95CA-C5AB0DC85B11`
3. Compute **SHA-1 hash**
4. **Base64-encode** the result

#### Example (Node.js / Python style)

```js
const crypto = require('crypto');
const key = "dGhlIHNhbXBsZSBub25jZQ==";
const magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

const hash = crypto.createHash('sha1')
                   .update(key + magic)
                   .digest('base64');

console.log(hash); // → HSmrc0sMlYUkAGmm5OPpG2HaGWk=
```

---

### 3. After Handshake → WebSocket Frames

Once `101` is received:

- **No more HTTP headers**
- Data is sent in **WebSocket frames** (text or binary)
- Connection stays open **until closed explicitly**

```text
Client ──text frame ("Hello")──▶ Server
Client ◀──text frame ("Hi!")──── Server
```

---

### Visual Flow

```
HTTP Request (with Upgrade)
        ▼
Server validates key → generates Accept
        ▼
HTTP 101 Response
        ▼
🔗 WebSocket connection established
        ↔ Full-duplex messaging
```

---

### Common Errors

| Code | Meaning |
|------|--------|
| `400 Bad Request` | Missing/invalid headers |
| `401 Unauthorized` | Auth required |
| `403 Forbidden` | Origin not allowed |
| `426 Upgrade Required` | Client used old version |

---

### Summary

| Step | Who | What |
|------|-----|------|
| 1 | Client | Sends HTTP `GET` with `Upgrade: websocket` |
| 2 | Server | Validates, computes `Sec-WebSocket-Accept`, replies `101` |
| 3 | Both | Now speak **WebSocket protocol** over same TCP socket |

> **Think of it as**:  
> *“Hey server, let’s switch from letters (HTTP) to a phone call (WebSocket)”* — and the handshake is the **“hello, upgrade accepted”** moment.




[[Read Projects]]