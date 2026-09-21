


A **network protocol** is a **set of rules and conventions that define how networked devices communicate with each other**.

In simple terms:

> **A protocol tells devices what to send, how to send it, how to interpret it, and what to do when something goes wrong.**

Without protocols, two computers could send raw data to each other but wouldn't necessarily know **how to interpret or respond to that data**.

---

## 1. What does a protocol define?

A protocol can define things such as:

- **Message format** — What does the data look like?
    
- **Addressing** — Who is the sender and receiver?
    
- **Ordering** — In what order are messages processed?
    
- **Timing** — When can a device send data?
    
- **Error handling** — What happens when data is lost or corrupted?
    
- **Flow control** — How much data can be sent at once?
    
- **Connection management** — How is a connection established and terminated?
    

---

## 2. Example: HTTP

When your browser communicates with a web server, they can use **HTTP**.

A simplified HTTP request looks like:

```http
GET /users HTTP/1.1
Host: example.com
```

HTTP defines rules such as:

```text
Client → Server
        HTTP Request

Server → Client
         HTTP Response
```

The server understands:

```text
GET /users
```

because both sides follow the **HTTP protocol**.

---

## 3. Protocols exist at different layers

Networking uses multiple protocols, each responsible for a different part of communication.

For example, when you access:

```text
https://example.com
```

you might have something like:

```text
HTTP
 ↓
TLS
 ↓
TCP
 ↓
IP
 ↓
Ethernet / Wi-Fi
```

Each protocol solves a different problem:

|Protocol|Main responsibility|
|---|---|
|**HTTP**|Web/application communication|
|**TLS**|Encryption and authentication|
|**TCP**|Reliable transport|
|**UDP**|Lightweight datagram transport|
|**IP**|Addressing and routing|
|**Ethernet**|Local network communication|
|**Wi-Fi (802.11)**|Wireless LAN communication|
|**DNS**|Domain name → IP address|

---

## 4. Protocol ≠ Programming API

This distinction is important as a Java developer.

A **protocol** defines communication rules.

An **API** provides a programming interface for using something.

For example:

```java
HttpClient client = HttpClient.newHttpClient();
```

`HttpClient` is a **Java API**.

It can implement/use **HTTP**, which is the **network protocol**.

So:

```text
Java API
   ↓
HttpClient
   ↓
HTTP protocol
   ↓
TCP
   ↓
IP
   ↓
Network
```

---

## 5. The mental model

Think of a protocol as a **communication contract**:

```text
          NETWORK PROTOCOL
                 │
       ┌─────────┼─────────┐
       ↓         ↓         ↓
    Format    Rules     Behavior
       │         │         │
       ↓         ↓         ↓
   What data   How to    What to do
   looks like  exchange  on errors
```

For two machines to communicate correctly:

> **Both sides must understand and follow the same protocol.**

That's the fundamental idea behind networking protocols.


[[Networking]]