# REST Statelessness, Sessions, and State

## 1. The source of the confusion

Two words seem to contradict each other:

- **Stateless** → don't remember
    
- **Session** → remember
    

The key is that **"session" can mean different things**.

When discussing REST, what matters is specifically **server-side client session state**.

---

# 2. What is state?

**State is information about something that must be remembered to understand what happens next.**

Imagine:

```text
Request 1:
"I'm Alireza."

Request 2:
"What is my name?"
```

If the server remembers that the user is Alireza:

```text
Request 1
   ↓
Server remembers:
user = Alireza
   ↓
Request 2
   ↓
Server uses remembered information
```

The server is maintaining state about the client's interaction.

---

# 3. What is a session?

A **session** is a way of associating multiple requests with the same client/user and maintaining information about that interaction.

A traditional server-side session might look like:

```text
Client
   │
   │ Login
   ▼
Server
   │
   └── creates session
         sessionId = ABC123
         userId = 42
         loggedIn = true
```

The server stores:

```text
ABC123
   ↓
userId = 42
loggedIn = true
```

The client receives:

```text
SESSION=ABC123
```

Later:

```text
GET /profile
Cookie: SESSION=ABC123
```

The server looks up `ABC123`:

```text
ABC123
   ↓
userId = 42
loggedIn = true
```

The server is remembering information from the previous interaction.

Therefore:

```text
Server-side session
        ↓
Server remembers client state
        ↓
Stateful
```

---

# 4. What does stateless mean?

REST's **stateless constraint** means:

> Each request must contain all the information necessary for the server to understand and process that request.

The server should not have to remember the client's previous requests.

For example:

```http
GET /tasks

Authorization: Bearer <token>
```

The server receives this request and can determine who is making the request from the information provided with the request.

It does not need:

```text
"Let me check what this client did in the previous request."
```

Conceptually:

```text
Request 1
   ↓
Server processes it
   ↓
Request finished

Request 2
   ↓
Server processes it independently
   ↓
Request finished
```

---

# 5. Stateful vs Stateless

## Stateful

The server remembers information about the client's interaction.

```text
Request 1
   ↓
Server
   ↓
remember something
   ↓
Request 2
   ↓
Server uses remembered information
```

Example:

```text
sessionId = ABC123

ABC123 → userId=42
```

The meaning of the second request depends partly on information stored from the first request.

---

## Stateless

The server does not need to remember the client's previous interaction.

```text
Request 1
   ↓
Server processes it

Request 2
   ↓
Server processes it independently

Request 3
   ↓
Server processes it independently
```

Each request carries the information required to process it.

---

# 6. Why does REST want statelessness?

The biggest benefit is **scalability and simplicity**.

Imagine three servers:

```text
                 Load Balancer
                      │
             ┌────────┼────────┐
             ↓        ↓        ↓
          Server A Server B Server C
```

With a stateless API:

```text
Request 1 → Server A
Request 2 → Server C
Request 3 → Server B
Request 4 → Server A
```

Any server can process any request because it doesn't depend on client state stored in another server.

---

# 7. The problem with server-side sessions

Suppose Server A stores:

```text
ABC123 → userId=42
```

Now:

```text
Request 1 → Server A
```

Server A knows:

```text
ABC123 → user 42
```

But then:

```text
Request 2 → Server C
```

Server C doesn't have that session.

Now you need additional infrastructure.

### Option 1: Sticky sessions

The load balancer keeps sending the client to Server A:

```text
Client
   │
   ├──→ Server A
   ├──→ Server A
   └──→ Server A
```

This creates coupling between the client and a particular server.

### Option 2: Shared session storage

All servers use something like Redis:

```text
              Redis
             /     \
            /       \
       Server A   Server B
            \       /
             \     /
             Server C
```

Now every server can retrieve the session.

This works, but introduces additional infrastructure and complexity.

### Stateless approach

Instead:

```text
Client
   │
   │ request contains necessary context
   ▼
Load Balancer
   │
   ├──→ Server A
   ├──→ Server B
   └──→ Server C
```

Any server can handle the request.

---

# 8. VERY IMPORTANT: REST does NOT mean "the application has no state"

This is probably the most important distinction.

A REST server can absolutely have state.

For example:

```text
PostgreSQL

users
tasks
habits
orders
products
```

Those are **resource states**.

REST does not say:

> "Your database must contain no state."

That would be ridiculous.

Instead, REST says the server should not maintain **client conversational state between requests**.

Think of the distinction:

```text
                    STATE
                      │
          ┌───────────┴───────────┐
          │                       │
    Resource State        Client Session State
          │                       │
      PostgreSQL             Server memory
          │                       │
       REST OK              REST violation
```

---

# 9. Resource state vs session state

Consider your task application.

The database contains:

```text
Task
────────────────────
id = 123
title = "Learn REST"
status = TODO
```

This is resource state.

That's perfectly normal.

But suppose your Spring Boot server contains:

```java
Map<String, UserSession> sessions;
```

and:

```text
ABC123 → User 42
```

Now the server is maintaining client session state.

That conflicts with REST's stateless constraint.

---

# 10. What about JWT?

A common stateless authentication design uses a token.

For example:

```http
GET /api/tasks

Authorization: Bearer eyJhbGciOi...
```

The request contains authentication information.

The server can process the request without looking up a traditional server-side session.

Conceptually:

```text
Request
   │
   ├── endpoint
   ├── HTTP method
   ├── authentication information
   └── other required data
   │
   ▼
Server
   │
   └── process request
```

There is no requirement for:

```text
sessionId → server-side session
```

---

# 11. A subtle but important point about JWT

JWT itself does **not magically make an application RESTful**.

For example, you could have:

```text
JWT
+
server-side session
```

The presence of JWT alone doesn't determine whether the architecture is stateless.

The real question is:

> **Does the server need to remember client conversational state between requests?**

If yes:

```text
Stateful
```

If no:

```text
Stateless
```

---

# 12. "Session" does not always mean server memory

This is where terminology causes confusion.

There is a difference between:

### A. A conceptual session

A sequence of interactions:

```text
Login
   ↓
GET /profile
   ↓
GET /tasks
   ↓
POST /tasks
```

You can call this a user session conceptually.

That alone does not violate REST.

### B. A server-side session

The server stores:

```text
sessionId → client information
```

and uses that stored information across requests.

That is the stateful mechanism REST's stateless constraint is concerned about.

Therefore:

```text
"session" as a concept
        ≠
server-side session state
```

---

# 13. The best mental model

Think about every HTTP request as a letter.

## Stateful server

You send:

```text
"Give me my tasks."
```

The server says:

```text
"Who are you?"
```

You say:

```text
"I'm Alireza."
```

Later:

```text
"Give me my habits."
```

The server says:

```text
"Ah, you're Alireza. I remember you."
```

The server is maintaining state.

---

## Stateless server

You send:

```text
"Give me Alireza's tasks.
Here is my authentication information."
```

Later:

```text
"Give me Alireza's habits.
Here is my authentication information."
```

The server doesn't need to remember the previous request.

Each request contains the necessary context.

---

# 14. The exact REST rule

The REST constraint is:

> **Each request from client to server must contain all of the information necessary to understand the request, and the server must not store client context between requests.**

This is why REST is called **stateless**.

Not:

```text
"There is no state anywhere."
```

But:

```text
"There is no stored client conversational state between requests."
```

---

# 15. Final mental model

Remember this:

```text
                    REST
                      │
                      ▼
                STATELESSNESS
                      │
                      ▼
       Server doesn't remember the
       client's conversational state
                      │
                      ▼
       Each request is independently
       understandable
```

And:

```text
Server-side session
        │
        ▼
Server remembers client context
        │
        ▼
Stateful interaction
        │
        ▼
Violates REST's stateless constraint
```

But:

```text
Database
   │
   ▼
Resource state
   │
   ▼
COMPLETELY FINE
```

## One sentence to remember

> **REST does not mean "the server has no state"; it means "the server does not remember client conversational state between requests."**

[[0 - Spring Framework]]