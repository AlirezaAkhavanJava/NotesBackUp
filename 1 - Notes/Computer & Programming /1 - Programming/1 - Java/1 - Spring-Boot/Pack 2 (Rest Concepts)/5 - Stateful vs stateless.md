

**REST does not say "state is bad." REST says the server should not keep _client session state_ between requests.**

This is the **stateless constraint**.

### Stateful server

Imagine:

```text
Client                         Server
  │                              │
  │ POST /login                  │
  ├─────────────────────────────►│
  │                              │
  │                              │ stores:
  │                              │ session = user123
  │                              │
  │ GET /tasks                   │
  ├─────────────────────────────►│
  │                              │
  │                              │ "Ah, I remember
  │                              │  this client."
  │◄─────────────────────────────┤
```

The server needs to remember what happened in previous requests.

That's **stateful**.

---

### RESTful/stateless approach

Each request contains everything the server needs to understand it:

```text
GET /tasks

Authorization: Bearer eyJ...
```

Then:

```text
Client                         Server
  │                              │
  │ GET /tasks + token           │
  ├─────────────────────────────►│
  │                              │
  │                              │
  │◄─────────────────────────────┤
```

The server doesn't need to remember:

> "This client logged in 5 minutes ago."

The token itself carries/identifies the necessary authentication context.

---

## Why does REST care?

Because statelessness makes the server easier to scale.

Imagine:

```text
             Load Balancer
                  │
        ┌─────────┼─────────┐
        ▼         ▼         ▼
     Server A  Server B  Server C
```

With a stateless API:

```text
Request 1 → Server A
Request 2 → Server C
Request 3 → Server B
```

No problem.

Every server can independently process every request.

But suppose Server A stores:

```text
session:
    user = Alireza
    cart = [...]
```

Then:

```text
Request 1 → Server A
              ↑
          state exists

Request 2 → Server C
              ↑
          state doesn't exist
```

Now you have a problem.

You need something like:

```text
sticky sessions
        OR
shared session storage
        OR
replication between servers
```

Those add complexity.

---

## But here's the part people often get wrong

**REST does NOT prohibit all state.**

Your database obviously contains state:

```text
PostgreSQL
├── users
├── tasks
├── habits
└── orders
```

That's completely fine.

The distinction is:

```text
                    STATE
                      │
          ┌───────────┴───────────┐
          │                       │
    Resource state          Client/session state
          │                       │
       Database             Server remembers
          │                       │
       ✅ REST                  ❌ violates
                              statelessness
```

So your Spring Boot application can absolutely have:

```java
Task task = taskRepository.findById(id);
```

The server is managing persistent **resource state**.

What REST's stateless constraint objects to is something like:

```java
Map<String, UserSession> sessions;
```

where the server must remember the client's conversational state from previous requests.

### The mental model

Think:

> **Every HTTP request should be understandable on its own.**

Not:

> "The server must contain zero state."

That's the crucial distinction.


[[Spring Framework]]