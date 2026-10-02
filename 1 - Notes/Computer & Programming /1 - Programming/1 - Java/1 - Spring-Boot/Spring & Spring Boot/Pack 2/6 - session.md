
A **session** is a server-side way of saying:

> **"I know this particular client, and I remember information about its ongoing interaction with me."**

It's basically a **temporary conversation record between a client and server**.

### Simple example

You log into a website:

```text
POST /login
username=alireza
password=123
```

The server verifies you and creates:

```text
Session
────────────────
sessionId = abc123
userId    = 42
loggedIn  = true
```

The server stores that somewhere, often in memory or Redis/database.

Then it sends the client:

```text
Set-Cookie: SESSION=abc123
```

Your browser stores that cookie.

Now you request:

```text
GET /profile
Cookie: SESSION=abc123
```

The server receives `abc123` and looks it up:

```text
abc123
   ↓
userId = 42
loggedIn = true
   ↓
"Oh, this is Alireza."
```

That's a **session**.

---

### The important part

Notice what happened:

The second request:

```text
GET /profile
```

doesn't contain:

```text
userId=42
loggedIn=true
```

Instead, it says:

```text
SESSION=abc123
```

And the **server remembers what `abc123` means**.

That's state.

```text
Client                         Server
  │                              │
  │ SESSION=abc123               │
  ├─────────────────────────────►│
  │                              │
  │                         ┌──────────────┐
  │                         │ abc123       │
  │                         │ userId = 42  │
  │                         │ loggedIn=true│
  │                         └──────────────┘
```

### Compare that with a stateless API

A JWT-based API might do:

```text
GET /profile
Authorization: Bearer <JWT>
```

The request contains the authentication information needed to identify the user.

The server doesn't need:

```text
abc123 → userId 42
```

stored as a session.

So:

**Session = server-maintained state representing a client's ongoing interaction.**

And this is why sessions are relevant when learning REST's **stateless constraint**.


[[Spring Framework]]