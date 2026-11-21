

## The problem it solves

Every session uses server memory, and every live session is a ticket someone could steal. So sessions can't live forever. They need a lifetime that is long enough to be convenient and short enough to be safe.

> By default, a session lives **30 minutes after your last activity**, unless something ends it sooner.

The key word is _last activity_. The clock doesn't count from login. It restarts every time you use the site.

## The two kinds of lifetime

|Type|The clock starts|Resets on activity?|Example|
|---|---|---|---|
|**Idle timeout** (sliding)|At your **last request**|**Yes**|"Logged out after 30 min of doing nothing"|
|**Absolute timeout**|At **login** (or session creation)|**No**|"Logged out 8 hours after login, no matter what"|

Servlet containers like Tomcat only give you the idle kind out of the box. The absolute kind you add yourself (shown below).

A small timeline, with a 30-minute idle timeout:

```
9:00  Log in                      → timer: 30 min
9:20  Click a page                → timer resets: 30 min
9:45  Click a page                → timer resets: 30 min
10:15 Walk away...
10:45 Timer hits zero             → session deleted
10:50 You click something         → server: "who are you?" → login page
```

You've been on the site for 1 hour 45 minutes, and the session was fine the whole time, because you kept being active.

---

# Part 1: The default and how to change it

In Spring Boot (with embedded Tomcat), the default is **30 minutes**. Change it in `application.properties`:

```properties
server.servlet.session.timeout=20m
```

|Value|Meaning|
|---|---|
|`20m`|20 minutes|
|`2h`|2 hours|
|`90s`|90 seconds, but see the note below|
|`1200`|Plain number = seconds (1200 s = 20 min)|

**Tomcat counts in whole minutes.** If you write `90s`, it's rounded up to 2 minutes, and anything under a minute becomes 1 minute. That's why testing with "10 seconds" doesn't work as expected.

### Changing it for one session only

```java
@GetMapping("/short-session")
public String shortSession(HttpSession session) {
    session.setMaxInactiveInterval(5 * 60);
    return "This session now expires after 5 idle minutes";
}
```

- `setMaxInactiveInterval(...)` takes **seconds**, not minutes. This is a common mix-up with the property above.
- It overrides the global default for **this session only**.
- A negative value means "never expire." Avoid it. It's a memory leak waiting to happen, and a security hole.

---

# Part 2: What resets the timer?

The timer resets whenever a request **uses the session**: the browser sends the cookie, and the server looks the session up. Some details:

|Action|Resets the timer?|
|---|---|
|Clicking a link or submitting a form|Yes|
|An AJAX call to your API (with the cookie)|Yes|
|Typing in a form without submitting|**No** (the server doesn't see it)|
|Reading a long article on one page|**No**|
|A background poll every 10 seconds|**Yes**, and it quietly keeps the session alive forever|
|Static files that bypass security (images, CSS)|Usually not|

That polling row catches real projects. A dashboard that refreshes data every 30 seconds will never time out. If that's not what you want, make the polling endpoint not touch the session, or decide deliberately that it should.

The reverse also hurts: a user filling in a long form for 40 minutes, with no requests in between, comes back to a dead session and loses their work. Long forms often use a small "keep-alive" request or warn the user before expiry.

---

# Part 3: What ends a session

The timeout is only one of several ways a session dies.

|What happens|Who does it|Instant?|
|---|---|---|
|**Idle timeout**|Tomcat|See note below|
|**Logout** (`/logout`, `session.invalidate()`)|You or Spring Security|Yes|
|**Server restart or crash** (with in-memory sessions)|Nobody chose it|Yes, all sessions vanish|
|**Absolute timeout**|Your own filter|Yes|
|**`maximumSessions` kicks the old one out**|Spring Security|At the old session's next request|
|**`expireNow()` from the `SessionRegistry`**|Your admin code|At its next request|
|**Browser cookie deleted**|The user|The server session stays alive, but nobody holds its ticket|

That last row is interesting. When you clear cookies, the server-side session isn't destroyed. It becomes an **orphan** that nobody can reach, and it lives until its idle timeout and then gets cleaned up. That's one more reason to keep timeouts reasonable.

### Expiry is exact, but cleanup is lazy

Tomcat doesn't run a timer for every session. Two things happen:

1. **On access:** when a request arrives with an old ID, Tomcat checks the session's age first. If it's too old, it's treated as gone **immediately**, so security is exact.
2. **Background sweep:** a cleanup thread removes dead sessions from memory roughly **once a minute**.

So an expired session may sit in memory for up to a minute or so, but it can never be _used_ after it expires.

---

# Part 4: The cookie has its own, separate lifetime

You learned that two different things share the word "session." Their lifetimes are independent:

|Piece|Default lifetime|Ends when|
|---|---|---|
|**Server-side session**|30 min idle|Timeout, logout, restart|
|**Session cookie** in the browser|No expiry date = until the browser closes (usually)|Browser closes, or cookie cleared|

Four combinations can happen:

|Server session|Cookie|Result|
|---|---|---|
|Alive|Present|Logged in|
|Expired|Present|Cookie points to nothing, so you're sent to login|
|Alive|Gone|Orphan session, you must log in again|
|Expired|Gone|Clean slate|

You can set the cookie's lifetime too:

```properties
server.servlet.session.cookie.max-age=8h
```

This makes the cookie survive browser restarts, but it **doesn't extend the server session**. If the server session times out after 30 idle minutes, the cookie will point to nothing. To really stay logged in for days, you need a **remember-me token**, as covered in the earlier lesson.

---

# Part 5: Building an absolute timeout

A sliding timer lets someone stay logged in forever by staying active. For sensitive apps, you also want "no matter what, log in again after 8 hours." You add this with a small filter:

```java
@Component
public class AbsoluteTimeoutFilter extends OncePerRequestFilter {

    private static final long MAX_AGE_MS = Duration.ofHours(8).toMillis();

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session != null
                && System.currentTimeMillis() - session.getCreationTime() > MAX_AGE_MS) {
            session.invalidate();
            response.sendRedirect("/login?expired");
            return;
        }
        chain.doFilter(request, response);
    }
}
```

Line by line:

- `OncePerRequestFilter` is a Spring base class that guarantees the filter runs once per request.
- `MAX_AGE_MS` is the absolute limit, 8 hours in milliseconds. (`getCreationTime()` is in **milliseconds**, unlike `setMaxInactiveInterval`, which is in seconds.)
- `request.getSession(false)` looks at the existing session without creating one.
- `session.getCreationTime()` is when the session object was born. The filter compares it with now.
- If it's too old, `session.invalidate()` destroys it, and we redirect to login. `return` stops the chain so the request goes no further.
- Otherwise `chain.doFilter(...)` lets the request continue.

Two honest notes. First, `getCreationTime()` is when the session was _created_, which can be before login if the visitor had an anonymous session first. For a precise "8 hours since login," store a `loginTime` attribute when the user logs in. Second, `@Component` registers this filter for the whole app, and where it sits relative to Spring Security's filters depends on ordering. For tighter control, register it inside the security chain with `http.addFilterAfter(...)`.

---

# Part 6: With Spring Session and Redis

When sessions live in Redis, the lifetime is handled with Redis's own expiry feature (TTL, "time to live"):

```properties
spring.session.timeout=30m
```

If you don't set this, Spring Boot falls back to `server.servlet.session.timeout`.

- Every request that touches the session **resets the TTL**, giving the same sliding behavior.
- Redis deletes the key by itself when the time runs out. There's no sweeping code to write.
- Spring Session keeps the Redis key a few minutes **longer** than the timeout, so Redis can fire the expiry notification Spring needs. Your app still treats the session as expired on time.
- A restart of your app server **doesn't** lose sessions anymore, because they live in Redis. That's one of the biggest practical benefits.

---

# Part 7: Choosing a sensible lifetime

There's no universal number. It's a trade-off between convenience and risk:

|Kind of app|Common idle timeout|Why|
|---|---|---|
|Banking, payments, admin panels|5 to 15 min|Money and sensitive data at risk|
|Typical business web app|15 to 30 min|Balanced|
|Social media, news, shopping|Hours, or days via remember-me|Convenience matters more|
|Shared or public computers|Short|Someone else may sit down next|

Rules of thumb:

- Pair a **short session** with a **separate remember-me token** (with rotation) if you want convenience.
- For sensitive apps, add an **absolute timeout** too.
- Ask for the password again before dangerous actions (changing email, payments), regardless of session age.
- Show a "your session is about to expire" warning before cutting off a user in the middle of something.

---

# Try it yourself

**1. See the default:**

```java
@GetMapping("/ttl")
public String ttl(HttpSession session) {
    return "Idle timeout = " + session.getMaxInactiveInterval() + " seconds";
}
```

With no configuration, it prints `1800` (30 minutes).

**2. Watch it expire (use the minimum):**

```properties
server.servlet.session.timeout=1m
```

Then:

```bash
curl -c jar.txt -b jar.txt http://localhost:8080/visit   # count = 1
curl -c jar.txt -b jar.txt http://localhost:8080/visit   # count = 2
sleep 70
curl -c jar.txt -b jar.txt http://localhost:8080/visit   # count = 1 again
```

After 70 seconds, the count restarts. The old session is gone, so the server made a new one and sent a new `Set-Cookie`. Run `cat jar.txt` and you'll see the `JSESSIONID` changed.

**3. Prove the timer slides:**  
Call `/visit` every 40 seconds for two minutes. The count keeps climbing, because each call resets the 1-minute timer, even though the total time is past 1 minute.

**4. See last-access info:**

```java
@GetMapping("/times")
public String times(HttpSession s) {
    long idle = (System.currentTimeMillis() - s.getLastAccessedTime()) / 1000;
    return "Created: " + new Date(s.getCreationTime())
         + ", idle for " + idle + "s, max " + s.getMaxInactiveInterval() + "s";
}
```

`getLastAccessedTime()` and `getCreationTime()` both return milliseconds.

**5. See it in the browser:** log in to your Spring Boot app, wait out the timeout, then click a protected page. Open the Network tab and look at the response. You'll see a `302` redirect to `/login`, and a new `Set-Cookie` once you log in again.

---

## Related concept, briefly

**Sliding vs fixed expiration:** the same two ideas appear everywhere in security. A **sliding** expiration extends itself on every use (an idle session timeout). A **fixed** expiration is set once and never moves (a JWT's `exp`, or an absolute timeout). Sliding is friendly to users, and fixed is safer, because a stolen credential has a hard end date. Many systems combine them: slide within a fixed maximum.

---

## The whole picture

|Question|Answer|
|---|---|
|How long does a session live by default?|30 minutes of **inactivity**|
|Does the clock count from login?|No, it restarts on each request (idle timeout)|
|How do I change it?|`server.servlet.session.timeout=20m`, or `setMaxInactiveInterval(seconds)` for one session|
|Smallest value in Tomcat?|1 minute|
|What resets the timer?|Any request that uses the session|
|What else ends a session?|Logout, restart (in-memory), absolute timeout, session limits, admin expiry|
|Does the cookie's lifetime equal the session's?|No, they're separate|
|Is there a built-in absolute timeout?|No, add a small filter|
|How do sites keep me logged in for weeks?|A separate remember-me token creates new sessions|
|With Redis?|`spring.session.timeout`, and Redis TTL does the cleanup|




[[Spring Security]]