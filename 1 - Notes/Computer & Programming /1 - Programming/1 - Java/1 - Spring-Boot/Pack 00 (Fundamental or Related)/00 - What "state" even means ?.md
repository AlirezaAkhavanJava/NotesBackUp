
Let's start from zero. **State** just means: _information that got remembered from before, which affects what happens next._

That's it. That's the whole idea. Nothing fancier than that.

## The simplest possible example

```java
int counter = 0;

void increment() {
    counter = counter + 1;
}
```

Call `increment()` three times. `counter` goes `0 → 1 → 2 → 3`. Each call _depends on what happened last time_ — the value isn't reset between calls. That remembered value, `counter`, **is state**. If `increment()` had no `counter` variable and just always returned `1` no matter how many times you called it, there'd be no state involved at all — every call would be independent, with zero memory of the past.

So state = "something is being remembered between steps." No state = "every step starts fresh, with no memory of anything before it."

## Now apply that to servers

A web server handles requests one at a time, over and over, from lots of different people. The question "stateful vs stateless" is really just asking: **does the server remember anything about _you_ between your requests, or does it forget you completely the second it finishes responding?**

### Stateful

The server keeps something around in memory (or a database) that's tied to _you specifically_, and uses it on your next request.

Classic example: logging in with a session.

```java
@PostMapping("/login")
public void login(HttpSession session, @RequestBody LoginRequest req) {
    User user = authenticate(req);
    session.setAttribute("userId", user.getId()); // ← state gets created here
}

@GetMapping("/profile")
public User profile(HttpSession session) {
    Long userId = (Long) session.getAttribute("userId"); // ← state gets read here
    return userRepository.findById(userId);
}
```

When you log in, the server creates a `session` object and stores your `userId` inside it, in the server's own memory. It gives your browser a cookie containing just a session ID — a pointer to that stored data. On your _next_ request, the server looks up that session ID, finds the stored `userId`, and now it "remembers who you are" without you having to prove it again. That stored session **is** the state. The server is holding onto something about you between requests.

### Stateless

The server keeps _nothing_ about you. Every single request has to carry everything the server needs to understand it, as if it's the very first request it's ever seen from you.

Classic example: JWT.

```java
@GetMapping("/profile")
public User profile(@RequestHeader("Authorization") String authHeader) {
    String token = authHeader.replace("Bearer ", "");
    Claims claims = jwtService.parseAndValidate(token); // proves who you are, right now
    Long userId = claims.get("userId", Long.class);
    return userRepository.findById(userId);
}
```

Notice: there's no `HttpSession` anywhere. The server didn't store anything when you logged in. Instead, at login time it handed _you_ a signed token containing your `userId`, and you send that whole token back on every single request. The server doesn't remember you — you remind it, every time, by attaching proof. If the server crashes and restarts right now, it loses nothing about you, because it never had anything about you in the first place. Each request stands completely on its own.

## Why this distinction matters so much

Say you have 3 server instances behind a load balancer (common in real production setups).

- **Stateful**: if your session got created on Server A, and your next request randomly lands on Server B, Server B has no idea who you are — it never saw that session get created. You'd need "sticky sessions" (always route the same user to the same server) or a shared session store, both of which add complexity.
- **Stateless**: it doesn't matter which server handles your request. Any server can read and validate your JWT by itself, with no shared memory needed. This is exactly why JWT-based auth (which you've already learned) is the standard choice for scalable REST APIs, and why Spring Security has a literal setting for it:

```java
http.sessionManagement(session -> 
    session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
);
```

That one line is you telling Spring: "don't create or use `HttpSession` at all — I'm handling identity statelessly, via tokens, on every request."

## One related idea, briefly

You already know **idempotency** from your REST API design note — don't mix it up with statelessness, they sound similar but aren't the same thing. Idempotency is about a _single endpoint_: calling it twice with the same input produces the same result (useful for retries). Statelessness is about the _server's memory_: whether it remembers anything about you across different requests. An endpoint can be stateless and still not idempotent (e.g. a stateless `POST /orders` that creates a new order every time you call it).


[[Spring Framework]]