

When REST says:

> **Client and server must be separated.**

It does **not** mean:

> "The client and server must run on different computers."

It means **separation of responsibilities and concerns**, not necessarily physical/network separation.

### Think about these two concepts separately

**Physical separation:**

```text
Computer A                     Computer B
┌──────────────┐              ┌──────────────┐
│    Client    │ ──────────── │    Server    │
│   Browser    │    HTTP      │ Spring Boot  │
└──────────────┘              └──────────────┘
```

Very obviously separated.

But you can also have:

```text
Same computer
┌─────────────────────────────────────┐
│                                     │
│  Client                 Server      │
│  Browser              Spring Boot   │
│     │                     ▲         │
│     └──── HTTP ───────────┘         │
│                                     │
└─────────────────────────────────────┘
```

They're still **logically separate components**.

---

## So what does REST actually require?

REST's **client-server constraint** says roughly:

> The client is responsible for the user-facing interaction, while the server is responsible for storing/managing resources and providing services to the client.

The important property is that the two have **separate concerns**.

For example:

```text
Angular application
        │
        │ HTTP
        ▼
Spring Boot API
        │
        ▼
PostgreSQL
```

Angular doesn't need to know how Spring Boot implements:

```java
taskRepository.findById(id);
```

And Spring Boot doesn't need to know whether the client is:

- Angular
    
- React
    
- a mobile app
    
- another backend
    
- `curl`
    
- a Python script
    

That's the separation REST cares about.

---

## Why call it a "constraint" then?

Because REST is describing an **architectural style**.

REST says:

```text
Client
   ↓
interface
   ↓
Server
```

The server should not depend on the internal implementation of the client, and vice versa.

For example, your `DoItLater` backend could serve:

```text
Angular ───────┐
               │
React ─────────┤
               │
Android ───────┼──→ Spring Boot REST API
               │
curl ──────────┤
               │
another server ┘
```

That's powerful precisely because the API establishes a boundary.

---

### And here's the key distinction

**"Client and server are separated" ≠ "Client and server are on different machines."**

Instead:

```text
Separation of responsibility
        ↓
Client ≠ Server
        ↓
independent components
        ↓
communicate through an interface
```

They **can** be on:

```text
same process          ❌ usually not meaningful client/server architecture
same machine          ✅
same network           ✅
different networks     ✅
different countries    ✅
different continents   ✅
```

The REST constraint is about the **architecture**, not geography.

And this is why saying _"REST APIs work because the client and server are on different computers"_ is fundamentally wrong. **HTTP/networking already gives you communication across machines; REST's client-server constraint is about architectural separation of concerns.**



[[0 - Spring Framework]]