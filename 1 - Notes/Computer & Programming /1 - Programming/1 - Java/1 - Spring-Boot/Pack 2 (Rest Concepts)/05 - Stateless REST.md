

When people hear "REST is stateless," many take it to mean "REST APIs can't have any state." That isn't what it says. The stateless constraint is narrower: the server must not keep **client session state** between requests, so every request carries everything the server needs to understand it.

This tutorial covers what that means, what problem it solves, why it matters once you run more than one server, and how it looks in a Spring Boot application. By the end you'll know where the line falls between state that's fine (your database) and state that breaks the constraint (a server-side session map).

---

## 1. Start with the problem: a server that remembers you

Imagine a classic login flow:

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

The `GET /tasks` request doesn't say who you are. The server works it out from what it stored during `/login`. The meaning of the second request depends on the first request having happened, on that same server.

That's a **stateful** design. In Spring, it's what you get with `HttpSession`:

```java
@PostMapping("/login")
public void login(@RequestBody LoginRequest request, HttpSession session) {
    User user = authService.authenticate(request);
    session.setAttribute("userId", user.getId()); // server now remembers this client
}

@GetMapping("/tasks")
public List<Task> tasks(HttpSession session) {
    Long userId = (Long) session.getAttribute("userId"); // relies on earlier request
    return taskService.findByUser(userId);
}
```

With one server, this works fine. The trouble starts when you grow.

---

## 2. The stateless alternative

In a stateless design, each request is self-contained:

```text
GET /tasks
Authorization: Bearer eyJ...
```

```text
Client                         Server
  │                              │
  │ GET /tasks + token           │
  ├─────────────────────────────►│
  │                              │
  │                              │
  │◄─────────────────────────────┤
```

The server doesn't need to remember that "this client logged in 5 minutes ago." The token carries, or lets the server verify, the authentication context needed to handle the request.

The mental model to keep:

> **Every HTTP request should be understandable on its own.**

---

## 3. Why REST cares: scaling out

The main payoff shows up when you put several servers behind a load balancer:

```text
             Load Balancer
                  │
        ┌─────────┼─────────┐
        ▼         ▼         ▼
     Server A  Server B  Server C
```

**With a stateless API**, the balancer can send requests anywhere:

```text
Request 1 → Server A
Request 2 → Server C
Request 3 → Server B
```

No problem. Every server can process every request independently.

**With a stateful API**, suppose Server A stored this in memory:

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

Server C has never heard of you, so the request fails or logs you out. To fix it you need one of these:

```text
sticky sessions
        OR
shared session storage
        OR
replication between servers
```

Each one works, and each one adds complexity:

- **Sticky sessions** pin a client to one server. Load balancing becomes uneven, and if that server dies, the sessions die with it.
- **Shared session storage** (for example Redis) means a new piece of infrastructure to run, secure, and keep available.
- **Replication** means servers constantly copying state to each other.

Statelessness avoids all of this by not having the problem.

The same idea gives you a few other benefits:

- **Reliability:** if a server crashes mid-conversation, nothing is lost. The next request just goes to another server.
- **Visibility:** you can understand a request by looking at it alone, which makes debugging and monitoring easier.
- **Simplicity:** the server doesn't have to allocate, track, and clean up per-client memory.

---

## 4. The part people often get wrong

REST does **not** prohibit all state. Your database is full of it:

```text
PostgreSQL
├── users
├── tasks
├── habits
└── orders
```

That's completely fine. The distinction is between two kinds of state:

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

- **Resource state** is the data your API exists to manage: tasks, orders, users. It's the same no matter who asks, and it lives in the database. This is fine.
- **Client/session state** is the server's memory of a particular client's ongoing conversation: who is logged in, what step of a wizard they're on, what's in their in-memory cart. This is what the constraint rules out.

So your Spring Boot app can happily do this:

```java
Task task = taskRepository.findById(id);
```

You're reading persistent resource state, and nothing about the client's history is involved. What REST objects to is something like this:

```java
Map<String, UserSession> sessions; // server must remember each client's past requests
```

---

## 5. Stateless in Spring Boot

In Spring Security, you tell the framework not to create or use an `HttpSession`, and you authenticate each request from its token:

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())
            .oauth2ResourceServer(oauth -> oauth.jwt(Customizer.withDefaults()));
        return http.build();
    }
}
```

What each piece does:

- `SessionCreationPolicy.STATELESS` tells Spring Security never to create an HTTP session or use one to store the security context.
- `oauth2ResourceServer(... jwt ...)` makes Spring validate the `Authorization: Bearer ...` token on every request, so identity comes from the request itself.
- Disabling CSRF is common for APIs that send tokens in a header. If you authenticate with cookies instead, keep CSRF protection on.

Your controller no longer needs a session at all:

```java
@GetMapping("/tasks")
public List<Task> tasks(@AuthenticationPrincipal Jwt jwt) {
    String userId = jwt.getSubject(); // identity comes from this request's token
    return taskService.findByUser(userId);
}
```

---

## 6. Trade-offs to be aware of

Statelessness isn't free:

- **Requests get a bit bigger**, because they carry credentials every time.
- **Revoking access is harder.** A self-contained token (like a JWT) stays valid until it expires, even if the user logs out. Common answers are short expiry times plus refresh tokens, or a revocation list.
- **The server has less control** over what each client is doing.

For most web APIs, the scalability and simplicity are worth it, which is why stateless is the default recommendation.

---

## Quick recap

- The stateless constraint means the server doesn't remember client session state between requests.
- Each request must be understandable on its own.
- It makes scaling, failover, and debugging much simpler.
- Databases and other persistent resource state are fine.
- In Spring Boot, use `SessionCreationPolicy.STATELESS` and authenticate every request from its token.




[[Spring Framework]]