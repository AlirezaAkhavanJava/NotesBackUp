

A **session** is a server-side record that represents one client's ongoing interaction with the server. HTTP by itself has no memory: every request arrives as a stranger. A session fixes that. The server creates a small record (who you are, whether you're logged in, maybe your cart), stores it under a random ID, and gives you only the ID. On every later request you show the ID, and the server looks the record up and remembers you.

This is the key idea: **the data stays on the server, and the client carries only a key to it.** Sessions are the classic way to add _state_ on top of a stateless protocol, which is exactly why they come up when you study REST's stateless constraint and Spring Security. The rest of this tutorial covers the problem sessions solve, how they work step by step, how Spring handles them, where they hurt at scale, and how they compare with JWT.

---

## 1. The problem: HTTP forgets everything

HTTP is **stateless**: each request is processed independently, and the server keeps nothing between them. Consider this:

```text
POST /login      → "OK, credentials valid"
GET  /profile    → "Who are you?"
```

From the server's point of view, the second request has no connection to the first. Nothing says "this is the same person who logged in a second ago." Without some mechanism, you would have to send your username and password with **every** request, which is slow, unsafe, and clumsy.

We need a way to say: "this request belongs to that earlier conversation."

## 2. The idea: a coat-check ticket

Think of a coat check. You hand over your coat (your data), and they give you a numbered ticket (the session ID). You don't carry the coat around, only the ticket. Later you show the ticket, and they fetch the coat.

- The **coat** is the session data, stored on the server.
- The **ticket** is the session ID, stored in the client, usually in a cookie.
- The **coat-check desk** is the session store, which can be memory, Redis, or a database.

The ticket is meaningless on its own. It's just a random string, so stealing someone's _data_ from it is impossible, though stealing the _ticket itself_ is a real danger (more on that below).

## 3. Walking through a login, step by step

**Step 1: login.**

```text
POST /login
username=alireza&password=123
```

**Step 2: the server verifies and creates a session.**

```text
Session
────────────────
sessionId = abc123
userId    = 42
loggedIn  = true
```

It saves this in its session store.

**Step 3: the server hands back the ticket.**

```text
HTTP/1.1 200 OK
Set-Cookie: SESSION=abc123; HttpOnly; Secure; SameSite=Lax
```

**Step 4: the browser automatically attaches it from now on.** Browsers send matching cookies on every request to that site, with no JavaScript needed:

```text
GET /profile
Cookie: SESSION=abc123
```

**Step 5: the server looks it up.**

```text
abc123 → { userId: 42, loggedIn: true } → "This is Alireza."
```

Notice what the second request does _not_ contain: no `userId`, no `loggedIn`. Those facts live only on the server. The request carries just the key. That's what "stateful" means here: **the meaning of the request depends on something the server remembers.**

```text
Client                         Server
  │                              │
  │  Cookie: SESSION=abc123      │
  ├─────────────────────────────►│
  │                              │   ┌──────────────────┐
  │                              │   │ abc123           │
  │                              │   │ userId = 42      │
  │                              │   │ loggedIn = true  │
  │                              │   └──────────────────┘
  │◄─────────────────────────────┤
  │        200 OK (profile)      │
```

## 4. What the cookie flags are protecting you from

Since the session ID _is_ the proof of identity, anyone who steals it can impersonate you. This is **session hijacking**. The cookie flags exist to make that harder:

- **`HttpOnly`**: JavaScript can't read the cookie, so an XSS attack can't simply grab it.
- **`Secure`**: the cookie is only sent over HTTPS, so it can't be sniffed on the network.
- **`SameSite`**: limits when the browser attaches the cookie on cross-site requests, which helps against CSRF.

Also, session IDs must be long and random (unguessable), and sessions should **expire** (idle timeout, absolute timeout, and explicit logout that destroys the server-side record).

## 5. Sessions in Spring

In a Spring Boot web app on Tomcat, the servlet container manages sessions for you. The default cookie is called `JSESSIONID`, and you get at the session through `HttpSession`:

```java
@GetMapping("/visit")
public String visit(HttpSession session) {
    Integer count = (Integer) session.getAttribute("count");
    count = (count == null) ? 1 : count + 1;
    session.setAttribute("count", count);
    return "You've visited " + count + " times in this session";
}
```

The first call creates the session and sets the cookie. Later calls with that cookie find the same session, so the counter keeps climbing. Open a different browser and the count restarts, because it's a different ticket.

**Configuration** in `application.properties`:

```properties
server.servlet.session.timeout=30m
server.servlet.session.cookie.http-only=true
server.servlet.session.cookie.secure=true
server.servlet.session.cookie.same-site=lax
```

### Sessions and Spring Security

With Spring Security, login ties directly into the session. After successful authentication, an `Authentication` object is placed in a `SecurityContext`, and that context is saved **in the HTTP session**. On each later request, Spring Security's filter chain reloads the context from the session, so `SecurityContextHolder.getContext().getAuthentication()` works inside your controllers without you doing anything.

Spring Security also defends against **session fixation**: an attacker plants a known session ID in your browser _before_ you log in, then uses it after you authenticate. By default, Spring Security changes the session ID at login (`changeSessionId`), so the pre-login ID becomes worthless.

You control session behavior in the security config:

```java
@Bean
SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(a -> a.anyRequest().authenticated())
        .formLogin(Customizer.withDefaults())
        .sessionManagement(s -> s
            .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED) // default
            .maximumSessions(1)); // optional: one login per user
    return http.build();
}
```

`SessionCreationPolicy.STATELESS` tells Spring Security to never create or use a session, which is what you'd choose for a JWT-based API.

## 6. The scaling problem

Sessions have a cost: **the server must store them**. By default they live in the memory of one server instance. Run two instances behind a load balancer and this happens:

```text
Request 1 → Server A  (creates session abc123)
Request 2 → Server B  ("abc123? Never heard of it.") → logged out!
```

There are three common answers:

1. **Sticky sessions**: the load balancer always routes a client to the same server. It's simple, but if that server dies, its sessions die with it, and load can become uneven.
2. **Session replication**: servers copy sessions to each other. It works, but gets heavy as you grow.
3. **Externalized session store**: all instances keep sessions in a shared place like Redis. This is the usual modern answer, and Spring supports it with **Spring Session**.

With Spring Boot, using Redis for sessions is mostly a dependency plus connection config:

```xml
<dependency>
    <groupId>org.springframework.session</groupId>
    <artifactId>spring-session-data-redis</artifactId>
</dependency>
```

```properties
spring.data.redis.host=localhost
spring.data.redis.port=6379
```

Your code still uses `HttpSession` exactly as before. Spring Session transparently swaps the storage underneath, so any instance can serve any request. The app servers themselves become effectively stateless, while the state lives in Redis.

## 7. Sessions vs. JWT vs. "stateless REST"

Here is the comparison from your notes, filled out. With a **JWT**, the token itself contains the identity claims, signed by the server:

```text
GET /profile
Authorization: Bearer <JWT>
```

The server verifies the signature and reads the claims directly. It doesn't need to look anything up, so there is **no server-side session storage**.

||Session|JWT|
|---|---|---|
|Where state lives|Server (store)|Inside the token, on the client|
|What the client holds|An opaque ID|A signed, self-contained token|
|Revoking access|Easy: delete the session|Hard: token is valid until it expires (needs a denylist or short lifetimes)|
|Scaling|Needs shared store or stickiness|Naturally horizontal|
|Typical fit|Server-rendered apps, browsers|APIs, mobile clients, service-to-service|

This is why sessions matter for REST: Roy Fielding's **stateless constraint** says each request must contain everything the server needs to understand it. A server-side session violates that in the strict sense, because the request alone isn't enough, the server must remember something. In practice many real systems use sessions anyway and accept the trade-off. "Stateless" is a design goal with costs on both sides, not a rule that sessions are bad.

## 8. Common gotchas

- **Don't stuff big objects into sessions.** Every request loads them, and with Redis they get serialized over the network. Store IDs and small flags, not entity graphs.
- **Serializable matters.** With Redis or replication, session attributes must be serializable.
- **Sessions and CSRF go together.** Because browsers attach the cookie automatically, cookie-based sessions are vulnerable to CSRF. Spring Security enables CSRF protection by default for this reason. Don't disable it casually when you use sessions.
- **Memory growth.** Too many long-lived sessions can exhaust memory. Set sensible timeouts.
- **Logout must invalidate server-side.** Deleting the cookie in the browser isn't enough; the server record should be destroyed (`session.invalidate()`, which Spring Security's logout does for you).

## Recap

A session is the server's memory of a client: **opaque ID on the client, real data on the server**. It solves HTTP's forgetfulness, at the cost of server-side state that you have to protect (cookie flags, fixation defense, CSRF) and scale (Redis via Spring Session). JWT flips the trade-off by putting the state in the token, gaining scalability and losing easy revocation. Knowing both lets you pick the right one instead of following a trend.




[[Spring Framework]]
[[Networking]]