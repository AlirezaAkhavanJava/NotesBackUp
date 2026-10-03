

### What is "State"?

**State** = **memory of what happened before**.

In the context of web applications, **state** usually means:

- Is the user logged in?
- What items are in their shopping cart?
- What page they were on last?
- Any preferences they set (e.g., dark mode)?

The key question is: **where is this state stored**?

### Stateful vs. Stateless

| Term          | Meaning                                                                 | Where is the state stored?                     | Example in real apps                     |
|---------------|-------------------------------------------------------------------------|------------------------------------------------|------------------------------------------|
| **Stateful**  | The **server remembers** information about the user between requests.   | Server-side (session, database, Redis, etc.)   | Traditional web apps (Spring MVC, PHP)   |
| **Stateless** | The **server does NOT remember** anything between requests.            | Client-side (cookies, JWT token, localStorage) | Modern REST APIs, microservices, JWT     |

### Stateful (State-ful) = "Server remembers"

| Characteristic                       | Description                                                                 |
|--------------------------------------|-----------------------------------------------------------------------------|
| Server keeps track of user state     | Uses `HttpSession` (in Java) or similar mechanisms                          |
| Each request is linked to the user   | Via a **session ID** (usually sent in a cookie like `JSESSIONID`)          |
| Server stores data                   | In memory, database, Redis, etc.                                            |
| Typical authentication               | Form login → session cookie → server checks session on every request        |
| Logout                               | Server invalidates the session                                              |
| Pros                                 | Easy to implement, works well for traditional web apps, easy to logout      |
| Cons                                 | Harder to scale (need session replication or shared store like Redis)      |
| CSRF protection                      | Required (because server trusts the cookie)                                 |

**Example (Stateful – Spring Security default)**

```
User logs in → server creates session → sends JSESSIONID cookie
Next request → browser sends JSESSIONID → server loads session → knows user is logged in
```

### Stateless (State-less) = "Server forgets"

| Characteristic                       | Description                                                                 |
|--------------------------------------|-----------------------------------------------------------------------------|
| Server does NOT keep user state      | No session, no memory between requests                                      |
| All information sent with every request | Usually in a **JWT token** (JSON Web Token) in `Authorization: Bearer` header |
| Authentication                       | Client sends token → server verifies signature → trusts the claims inside   |
| Logout                               | Client discards token (server usually does nothing)                         |
| Pros                                 | Extremely scalable (no server state → easy horizontal scaling)              |
| Cons                                 | Harder to logout (tokens can be used until they expire), larger requests    |
| CSRF protection                      | Usually not needed (no cookies, token in header)                            |

**Example (Stateless – JWT)**

```
User logs in → server returns JWT token
Next request → browser sends JWT in header → server verifies token → knows user is logged in
No session stored on server
```

### Quick Comparison Table

| Feature                        | Stateful (Session)                          | Stateless (JWT/OAuth2)                     |
|--------------------------------|---------------------------------------------|--------------------------------------------|
| State stored                   | Server (session)                            | Client (token)                             |
| Scaling                        | Needs Redis/database for distributed sessions | Naturally scales (no server state)         |
| Request size                   | Small (just session ID cookie)              | Larger (JWT token ~ few hundred bytes)     |
| Logout                         | Easy (invalidate session)                   | Harder (token valid until expiry)          |
| CSRF risk                      | High (needs CSRF protection)                | Low (no cookies)                           |
| Typical use                    | Traditional web apps (forms, pages)         | APIs, SPAs (React, Angular), microservices |
| Spring Security support        | Default (form login + session)              | `.oauth2ResourceServer()` or `.jwt()`      |

### Real-World Examples

| App Type                       | Usually Stateful or Stateless? |
|--------------------------------|--------------------------------|
| Classic web app (e.g., Spring MVC with Thymeleaf) | Stateful (sessions)            |
| Single Page Application (React/Vue + REST API)    | Stateless (JWT)                |
| Microservices API              | Stateless (JWT/OAuth2)         |
| Mobile app backend             | Stateless (JWT)                |
| Banking app with high security | Often stateful (sessions + extra checks) |

### Summary – One-liner

- **Stateful** = **Server remembers** (using sessions) → easier for traditional web apps, but harder to scale.
- **Stateless** = **Server forgets** (client sends all info every time) → perfect for APIs and microservices, scales easily.

Spring Security supports **both** perfectly — you choose based on your app type!  
- Web app with pages → go **stateful** (default).  
- REST API or SPA → go **stateless** (JWT/OAuth2).

#### Tags [[1 - Spring Security 🍌]]