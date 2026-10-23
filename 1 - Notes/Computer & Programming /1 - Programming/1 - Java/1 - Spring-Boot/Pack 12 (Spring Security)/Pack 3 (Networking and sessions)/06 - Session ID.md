
# Session IDs: How They Work and How You Use Them




## The problem it solves

HTTP has no memory. Every request arrives as a stranger. When you log in and then click "My orders", the server sees a second request that has nothing to do with the first. Nothing in HTTP says "this is the same person who just logged in."

A session ID fixes that. It gives the server a way to say, "Ah, you again."

## The coat check

The easiest picture is a coat check at a theater.

1. You hand over your coat. The attendant keeps it in the back.
2. They give you a **numbered ticket**.
3. Later, you show the ticket and get your coat.

The ticket isn't your coat. It's a small, meaningless number that points to your coat. A session works the same way:

|Coat check|Web session|
|---|---|
|Your coat|Your session data (who you are, your cart, your roles)|
|The back room|Server memory, or a store like Redis or a database|
|The ticket number|The **session ID**|
|Showing the ticket|The browser sending the cookie|
|Someone stealing your ticket|Session hijacking|

The key idea: **the data stays on the server, and only the ID travels.** The ID is just a long random string with no meaning of its own. If someone intercepts it, they learn nothing about you, but they can _use_ it to claim your coat. That's why we protect it carefully.

---

## What really happens, step by step

```
1. Browser → Server:  GET /login            (no cookie yet)
2. Browser → Server:  POST /login           (username + password)
3. Server: checks the password ✓
           creates a session, stores "alice, ROLE_USER" in it
           generates a random ID: 7F3A9C...
4. Server → Browser:  200 OK
                      Set-Cookie: JSESSIONID=7F3A9C...; HttpOnly; Secure; SameSite=Lax
5. Browser: saves the cookie
6. Browser → Server:  GET /orders
                      Cookie: JSESSIONID=7F3A9C...
7. Server: looks up 7F3A9C... → finds alice → serves her orders
```

Two things happen automatically, and you rarely write code for them:

- **The server** sends the ID once, with `Set-Cookie`.
- **The browser** attaches it to every later request to that site. You never write JavaScript for this.

In Tomcat (the default server in Spring Boot), the cookie is named `JSESSIONID`. The ID is long and random, so nobody can guess one.

### See it yourself in the Network tab

Open the Network tab, turn on **Preserve log**, and log in to any site you've built:

- Click the login `POST` and look at **Response Headers** for `set-cookie: JSESSIONID=...`.
- Click the next request and look at **Request Headers** for `cookie: JSESSIONID=...`. It's the same value.
- In **Application → Cookies**, you'll see it with its `HttpOnly`, `Secure`, and `SameSite` flags.

Seeing that one value travel back and forth makes the whole concept click.

---

## Working with sessions in Spring Boot

You'll use sessions at two levels. First the **plain** one, `HttpSession`. Then the **Spring Security** level, where most real apps live.

### Level 1: `HttpSession` directly

Here's a small visit counter:

```java
@RestController
public class VisitController {

    @GetMapping("/visit")
    public String visit(HttpSession session) {
        Integer count = (Integer) session.getAttribute("count");
        count = (count == null) ? 1 : count + 1;
        session.setAttribute("count", count);
        return "Visit number " + count;
    }
}
```

Line by line:

- `HttpSession session` as a parameter: Spring hands you the current user's session. If this user has none yet, **one is created** and a `Set-Cookie` is queued.
- `session.getAttribute("count")` reads a value from this user's back room. It returns `null` if nothing is stored yet, so we check for that.
- `count = (count == null) ? 1 : count + 1` starts at 1 on the first visit, otherwise adds one.
- `session.setAttribute("count", count)` saves the new value. Each user has their own `count`, because each has their own session.

Refresh the page and the number goes up. Open a private window and you start at 1 again, because that's a different cookie, so a different session.

### The methods you'll use most

|Method|What it does|
|---|---|
|`getAttribute(name)` / `setAttribute(name, value)`|Read and write data|
|`removeAttribute(name)`|Delete one value|
|`getId()`|The session ID (useful for debugging, not for showing to users)|
|`isNew()`|True if created during this request|
|`invalidate()`|Destroys the session, which is what logout does|
|`setMaxInactiveInterval(seconds)`|Sets this session's idle timeout|

### Getting a session _without_ creating one

Asking for `HttpSession` creates one if it's missing. Sometimes you only want to check. Use the request:

```java
HttpSession session = request.getSession(false);
if (session == null) {
    // user has no session yet
}
```

`false` means "don't create one." This matters because every session costs server memory, so don't create them for visitors who don't need one (search engine bots, health checks, public pages).

### Timeouts

Sessions can't live forever. By default, a session expires after **30 minutes of inactivity**. Every request resets the timer. You can change it:

```properties
server.servlet.session.timeout=30m
```

When a session expires, the server deletes the data. The browser still has the old ticket, but the server says "I don't know that number," and the user is treated as logged out.

### What belongs in a session, and what doesn't

|Good to store|Avoid storing|
|---|---|
|User id, username, roles|Big objects (whole lists of database entities)|
|Small preferences|Anything that changes in the database often (it goes stale)|
|A shopping cart (small)|Passwords or secrets in plain form|
|A one-time message ("Saved!")|Objects that aren't `Serializable`|

The reason for "keep it small and serializable": sessions use memory on every request, and when you scale out or use Redis, sessions have to be converted to bytes. Store **ids**, and load the heavy data from your database when needed.

---

### Level 2: Sessions with Spring Security

Once you add Spring Security, you mostly **stop touching `HttpSession` yourself**. Spring Security manages it for you:

1. You submit the login form.
2. Spring Security checks the password.
3. It builds an `Authentication` object (who you are plus your roles).
4. It stores it in the **SecurityContext**, which is saved **inside the HttpSession**.
5. On every later request, a filter reads the session, finds the SecurityContext, and puts you back in as "logged in alice."

So in practice, your login state _is_ a value inside the session. Reading the current user in a controller looks like this:

```java
@GetMapping("/me")
public String me(@AuthenticationPrincipal UserDetails user) {
    return "Hello, " + user.getUsername();
}
```

- `@AuthenticationPrincipal` asks Spring to pull the logged-in user out of the SecurityContext (which came from the session) and pass it in.
- If nobody is logged in, security rules would have already blocked the request before this method runs.

### Session-related security features you can configure

```java
http.sessionManagement(session -> session
    .sessionFixation(fix -> fix.changeSessionId())
    .maximumSessions(1)
);
```

Line by line:

- `sessionManagement(...)` opens the settings area for sessions.
- `sessionFixation(fix -> fix.changeSessionId())`: **the attack it stops:** an attacker visits the site, gets a session ID, and tricks you into using it (for example through a crafted link). If you log in and the ID stays the same, the attacker now holds a logged-in ID. With `changeSessionId()`, Spring **swaps in a fresh ID at login**, so the attacker's ID is worthless. This is already the default, so you're showing it here to understand it.
- `maximumSessions(1)`: one account can have only one active session. A second login ends the first. Handy for "one device at a time" rules.

For that last feature to count sessions correctly, register this bean so Spring Security hears when sessions are destroyed:

```java
@Bean
HttpSessionEventPublisher httpSessionEventPublisher() {
    return new HttpSessionEventPublisher();
}
```

### Choosing whether sessions exist at all

```java
http.sessionManagement(s -> s
    .sessionCreationPolicy(SessionCreationPolicy.STATELESS));
```

|Policy|Meaning|Typical use|
|---|---|---|
|`IF_REQUIRED` (default)|Create a session when needed|Normal web apps|
|`ALWAYS`|Always create one|Rare|
|`NEVER`|Don't create, but use one if it exists|Rare|
|`STATELESS`|Never create or use a session|Token-based APIs (JWT)|

### Logout

Logout is more than deleting the cookie. Spring Security's `/logout` invalidates the session on the **server** (the important part, because the coat is gone, so the ticket is useless), clears the SecurityContext, and can delete the cookie. If you ever write logout by hand, call `session.invalidate()`. Just clearing the browser cookie leaves the session alive on the server until it times out.

---

## Cookie settings you should always know

The session ID is only as safe as the cookie that carries it:

```properties
server.servlet.session.cookie.name=JSESSIONID
server.servlet.session.cookie.http-only=true
server.servlet.session.cookie.secure=true
server.servlet.session.cookie.same-site=lax
server.servlet.session.tracking-modes=cookie
```

|Setting|What it protects against|
|---|---|
|`http-only`|JavaScript can't read the ID, so XSS can't steal it|
|`secure`|Only sent over HTTPS, so Wi-Fi snoopers can't see it|
|`same-site=lax`|Not sent on most cross-site requests, which helps against CSRF|
|`tracking-modes=cookie`|Never put the ID in the URL (`;jsessionid=...`), where it leaks through logs, history, and Referer headers|

---

## When you have more than one server

This part surprises many developers. By default, sessions live in the **memory of one server**. Imagine two copies of your app behind a load balancer:

```
You log in    → Server A (creates the session in A's memory)
Next request  → Server B (never heard of you → you're logged out!)
```

There are two ways to solve this:

|Approach|How it works|Trade-off|
|---|---|---|
|**Sticky sessions**|The load balancer always sends you to the same server|Simple, but if that server dies, you lose your session|
|**Shared session store**|All servers keep sessions in one place (Redis or a database)|Needs extra infrastructure, but is robust and common|

Spring has a project for the second approach called **Spring Session**. You add a dependency (for example `spring-session-data-redis`) and point it at Redis. Spring Boot auto-configures it, and `HttpSession` keeps working exactly as before. Your code doesn't change. Only where the data lives changes. Sessions in Redis also expire automatically, which is a natural fit for Redis's built-in expiry.

---

## Common mistakes

|Mistake|Why it hurts|
|---|---|
|Putting the session ID in a URL|It leaks via browser history, logs, and shared links|
|Not using HTTPS|The ID can be sniffed (this is what Firesheep did)|
|Storing big objects in the session|Memory pressure and slow replication|
|Keeping the same ID after login|Session fixation|
|Clearing only the cookie at logout|The session lives on the server|
|Trusting the session for data that changes|A role changed in the database won't show up until the session refreshes|
|Showing the session ID to users or in logs|Anyone who sees it can use it|

---

## Try it yourself

1. **Run the visit counter** above and call it with `curl`, saving cookies:
    
    ```bash
    curl -c jar.txt -b jar.txt http://localhost:8080/visit
    curl -c jar.txt -b jar.txt http://localhost:8080/visit
    ```
    
    `-c jar.txt` saves cookies to a file, and `-b jar.txt` sends them back. You'll see the count go 1, 2. Without `-b`, you'd always see 1, because there's no ticket.
    
2. **Look inside the jar:** `cat jar.txt` shows your `JSESSIONID`.
    
3. **Steal your own session on purpose:** copy that value into a second `curl` with `-H "Cookie: JSESSIONID=..."` and watch the server treat you as the same person. That's exactly why the ID must be protected.
    
4. **Watch fixation protection:** with Spring Security on, note your `JSESSIONID` before logging in and after. It will be different.
    
5. **Test timeouts:** set `server.servlet.session.timeout=1m`, wait, then reload to see yourself logged out. (Tomcat's minimum granularity is one minute.)
    

---

## Related concept, briefly: sessions vs JWT

A **JWT** is the other common way to remember users. A session stores the data on the **server** and sends a meaningless ticket. A JWT puts the data **inside the token** (signed), so the server stores nothing.

||Session|JWT|
|---|---|---|
|Where data lives|Server|Inside the token|
|Easy to revoke|Yes, delete the session|Hard, since it's valid until expiry|
|Scaling|Needs a shared store|Naturally stateless|
|Best for|Browser apps with one backend|APIs and many services|

Neither is "better." For a classic web app, sessions are simple and safe. For APIs used by many clients, JWTs often fit better.

---

## Putting it together

|Piece|Job|
|---|---|
|**Session ID**|The ticket, a random string in a cookie|
|**Session data**|The coat, stored on the server|
|**`HttpSession`**|Your Java handle for reading and writing that data|
|**SecurityContext**|Where Spring Security keeps "who you are" inside the session|
|**Cookie flags**|Protect the ticket from theft|
|**Spring Session + Redis**|One shared back room for many servers|




[[Spring Security]]