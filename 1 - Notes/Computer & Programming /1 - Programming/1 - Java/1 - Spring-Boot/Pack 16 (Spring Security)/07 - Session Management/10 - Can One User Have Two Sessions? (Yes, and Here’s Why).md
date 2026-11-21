

## The problem it solves

You might picture the server thinking, "Alice is logged in, so Alice has a session." That picture is slightly off, and fixing it makes everything about sessions clearer.

> **A session belongs to a cookie jar, not to a person.**

The server never sees "Alice's browser." It only sees a cookie value. Each time a login happens, it creates a new session for that login. So if Alice logs in from two browsers, she gets two sessions.

## Short answer

**Yes.** Same user, two browsers means two separate logins, two session IDs, and two separate sessions on the server.

```
Chrome   (cookie jar A)  →  JSESSIONID = 7F3A...  ┐
                                                   ├→ both sessions say "user = alice"
Firefox  (cookie jar B)  →  JSESSIONID = C41D...  ┘
```

## Why this happens, step by step

**1. Every browser has its own cookie jar.**  
A cookie saved in Chrome is invisible to Firefox. They are separate programs with separate storage.

**2. Firefox has no ticket yet.**  
When you open the site in Firefox, it sends no `JSESSIONID`, so the server sees a stranger.

**3. You log in again.**  
The server checks your password, creates a **new** session, generates a **new** random ID, and sends it to Firefox with `Set-Cookie`.

**4. Now the server holds both.**

|Session ID|Stored data|Which browser has the ticket|
|---|---|---|
|`7F3A...`|`SecurityContext → alice`|Chrome|
|`C41D...`|`SecurityContext → alice`|Firefox|

Both sessions point to the same user, because the same person logged in twice. But as session objects, the two are **completely independent**.

## Who gets their own session?

|Situation|Same session or different?|
|---|---|
|Two **tabs** in the same browser|**Same** (they share one cookie jar)|
|Two **windows** of the same browser|**Same**|
|Chrome and Firefox|**Different**|
|Two **profiles** in Chrome|**Different** (each profile has its own jar)|
|Normal window and **incognito** window|**Different** (incognito starts with an empty jar)|
|Laptop and phone|**Different**|
|Your browser and `curl`|**Different**, unless you copy the cookie yourself|

The rule is simple: **same cookie jar, same session**. Different jar, different session.

## What "independent" means in practice

Because the two sessions are separate objects, they don't affect each other:

|What you do|Effect on the other session|
|---|---|
|Add an item to a cart stored **in the session** (Chrome)|Firefox doesn't see it|
|Log out in Chrome|Firefox stays logged in|
|Chrome's session times out|Firefox's session keeps living|
|Change a setting stored in the session|Only that session changes|

That second row surprises many people. Logging out is **per session**, not per user. If you log out on your laptop, your phone is still logged in.

This is also why a cart stored only in the session feels "lost" when you switch browsers. If something should follow the **user** everywhere (a saved cart, preferences), store it in the **database** under the user's id, not in the session.

## Seeing it yourself

You can reproduce two browsers with two cookie jars in `curl`:

```bash
# "Browser A"
curl -c a.txt -b a.txt -i http://localhost:8080/start

# "Browser B"
curl -c b.txt -b b.txt -i http://localhost:8080/start

cat a.txt
cat b.txt
```

Line by line:

- `-c a.txt` saves any cookie the server sends into `a.txt`.
- `-b a.txt` sends the cookies stored in `a.txt`.
- The second pair does the same with a different file, `b.txt`. That file is a second, separate "browser."

You'll see two different `JSESSIONID` values, one in each file. If you do the same with a login in both, the server holds two sessions for the same username.

## How you, as the developer, can control this

By default, Spring Security **allows unlimited sessions per user**. You choose what to do about it.

### Option 1: Allow it (the default)

Most websites do this. You can be logged in on your laptop, your phone, and a work computer at once, and each device has its own session.

### Option 2: Allow only one session per user

```java
@Bean
SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http.sessionManagement(session -> session
        .maximumSessions(1)
        .maxSessionsPreventsLogin(false));
    return http.build();
}

@Bean
HttpSessionEventPublisher httpSessionEventPublisher() {
    return new HttpSessionEventPublisher();
}
```

Line by line:

- `maximumSessions(1)` says one user may have at most one live session.
- `maxSessionsPreventsLogin(false)` means the **newest login wins**. When Alice logs in on Firefox, the Chrome session is marked expired, and her next click in Chrome sends her back to login.
- Setting it to `true` flips the behavior: the **old session stays**, and the new login is **refused**.
- `HttpSessionEventPublisher` lets Spring Security hear when Tomcat creates or destroys sessions, so its count stays accurate. Without it, the limit can misbehave.

|Setting|Chrome (first)|Firefox (second login)|
|---|---|---|
|`maxSessionsPreventsLogin(false)`|Gets kicked out|Allowed|
|`maxSessionsPreventsLogin(true)`|Stays logged in|Login refused|

### Option 3: See and manage a user's sessions

Spring Security keeps a **`SessionRegistry`**, a list of who has which sessions. You can use it to build a "devices logged in" page, or to log a user out everywhere.

```java
@Bean
SessionRegistry sessionRegistry() {
    return new SessionRegistryImpl();
}
```

Tell the security config to use it:

```java
http.sessionManagement(session -> session
    .maximumSessions(-1)
    .sessionRegistry(sessionRegistry()));
```

- `maximumSessions(-1)` means unlimited. We still want the registry to **track** sessions without limiting them.
- `.sessionRegistry(...)` plugs in the registry bean so we can inject it elsewhere.

Now list and expire sessions:

```java
@Service
public class SessionService {

    private final SessionRegistry registry;

    public SessionService(SessionRegistry registry) {
        this.registry = registry;
    }

    public List<String> sessionIdsFor(Object principal) {
        return registry.getAllSessions(principal, false).stream()
                .map(SessionInformation::getSessionId)
                .toList();
    }

    public void logoutEverywhere(Object principal) {
        registry.getAllSessions(principal, false)
                .forEach(SessionInformation::expireNow);
    }
}
```

Line by line:

- `registry.getAllSessions(principal, false)` returns all sessions for that user. The `false` means "don't include sessions that have already expired."
- `SessionInformation` describes one session: its id, last request time, and whether it's expired.
- `expireNow()` marks the session expired. The next request carrying that ID is rejected and redirected to login. This is the "log me out of all devices" button.
- `principal` is the logged-in user object (what `@AuthenticationPrincipal` gives you). The registry matches users using `equals` and `hashCode`, so if you use your own user class, implement both properly. Spring's built-in `User` class already does.

A practical detail: the registry in this example lives in **one server's memory**. With many servers, you'd use **Spring Session with Redis**, which can look up sessions by username across all servers.

## Common questions

**"Is it a security problem that two sessions exist?"**  
No, it's normal. Each device getting its own ticket is actually the safer design. If a stolen ticket could only be invalidated by logging everyone out, that would be worse. With separate sessions, you can end one device's access without touching the others.

**"What if I want to know which session is which?"**  
The server doesn't know "Chrome" or "Firefox" on its own. It can read the `User-Agent` header and the IP address and store them when the session starts, which is how sites build a "Chrome on Windows, last active 5 minutes ago" list.

**"If Alice changes her password, do the other sessions die?"**  
Not automatically. The other sessions still hold a valid `SecurityContext`, so they keep working until they expire. That's why good apps expire all of a user's **other** sessions after a password change, using the `SessionRegistry` approach above.

## Related concept, briefly

**Multi-device login with tokens:** the same idea applies to JWTs and refresh tokens. Each login on each device receives its **own** token pair. The server tracks refresh tokens per device, which makes "log out this device only" and "log out everywhere" possible. The principle stays the same across approaches: **one login event creates one credential**, and one person can create many login events.

## The whole picture

|Question|Answer|
|---|---|
|Does a session belong to a user?|No, it belongs to one login (one cookie jar)|
|Two browsers, same user?|Two sessions, two IDs|
|Two tabs, same browser?|One session|
|Does logout in one affect the other?|No|
|Default limit on sessions per user?|None|
|How do I limit them?|`maximumSessions(n)`|
|How do I list or kill them?|`SessionRegistry`|
|Where do I keep data that should follow the user?|In the database, not the session|






[[Spring Security]]