

## The problem it solves

You already know what a session is. The question now is how to run sessions in a real app: how to create them only when needed, protect them from theft, limit them, expire them, share them across servers, and end them cleanly.

Spring Security does most of this with a few settings. Your work is mostly **choosing the policy** and avoiding a few traps.

> Spring Security doesn't replace Tomcat's `HttpSession`. It sits on top of it and decides **when to use it, what to store in it, and how to defend it.**

## The map: a session's life, and who handles each stage

|Stage|The question|Where you control it|
|---|---|---|
|**1. Create**|When does a session come into being?|`sessionCreationPolicy`|
|**2. Fill**|What is stored in it?|`SecurityContextRepository`|
|**3. Protect**|How do we stop theft and fixation?|`sessionFixation`, cookie flags|
|**4. Limit**|How many per user?|`sessionConcurrency`, `SessionRegistry`|
|**5. Expire**|When does it die by itself?|Idle and absolute timeouts|
|**6. React**|What does the user see after it dies?|`invalidSessionUrl`, `expiredUrl`|
|**7. Share**|How do many servers use the same sessions?|Spring Session (Redis or JDBC)|
|**8. End**|How does logout work?|`logout(...)`|

We'll go through them in order, then put everything into one configuration.

---

# Part 1: What Spring Security stores in the session

After a successful login, Spring Security keeps **one thing** in the session: the `SecurityContext`, which holds your `Authentication` (who you are plus your authorities). It's saved under the attribute `SPRING_SECURITY_CONTEXT`.

Two classes do the work:

|Class|Job|
|---|---|
|`SecurityContextHolderFilter`|At the **start** of each request, **loads** the context from the session|
|`SecurityContextRepository`|The storage behind it (by default `HttpSessionSecurityContextRepository`)|

The flow on each request:

```
Cookie: JSESSIONID=...
   → Tomcat finds the HttpSession
   → SecurityContextHolderFilter asks the repository: "any context in this session?"
   → yes: it goes onto the current thread (ThreadLocal), so @AuthenticationPrincipal works
   → request ends: the ThreadLocal is cleared
```

Two details that matter in Spring Security 6 and later:

- **Loading is lazy.** The session is only touched if someone actually asks for the context, so public pages don't create or refresh sessions needlessly.
- **Saving is explicit.** The filter never saves the context at the end. The thing that **logs you in** saves it. The built-in form login does this for you. If you write your own login endpoint, **you** must call `securityContextRepository.saveContext(...)`, or the user is logged out on the very next request. (The code is in the filter-chain lesson, section 6.3.)

You can read the current user in your code in three ways:

```java
@GetMapping("/me")
public String me(@AuthenticationPrincipal UserDetails user, Authentication auth) {
    Authentication same = SecurityContextHolder.getContext().getAuthentication();
    return user.getUsername() + " has " + auth.getAuthorities();
}
```

- `@AuthenticationPrincipal` gives you the user object.
- `Authentication` as a parameter gives you the whole login object.
- `SecurityContextHolder` is the static way, useful in service classes. It works only on the request's own thread.

---

# Part 2: Stage 1, when is a session created?

This is the `SessionCreationPolicy`:

```java
http.sessionManagement(s -> s
    .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED));
```

|Policy|Spring Security **creates** a session?|**Uses** an existing one?|Typical use|
|---|---|---|---|
|`IF_REQUIRED` (default)|Only when needed (for example at login)|Yes|Normal web apps|
|`ALWAYS`|On every request|Yes|Rare|
|`NEVER`|**Never**|Yes, if one already exists|Rare|
|`STATELESS`|**Never**|**Never** (not even to read the login)|Token APIs (JWT)|

Two traps:

1. **`STATELESS` only controls Spring Security.** If your own code calls `request.getSession()` or takes an `HttpSession` parameter, a session is created anyway.
2. **CSRF can create sessions quietly.** By default, the CSRF token is stored in the session. A page that renders a form will create one. For cookie-less stateless APIs you usually turn CSRF off. For SPAs you can store the token in a cookie with `CookieCsrfTokenRepository`.

A good habit: choose `IF_REQUIRED` for browser apps and `STATELESS` for token APIs, and define them as **two separate security chains** if you have both.

---

# Part 3: Stage 3, protect against session fixation

Recall the attack: the attacker plants a known session ID, you log in, and the ID stays the same, so the attacker is now logged in too. Spring Security prevents this by changing the ID **at login**.

```java
http.sessionManagement(s -> s
    .sessionFixation(f -> f.changeSessionId()));
```

|Strategy|What happens at login|
|---|---|
|`changeSessionId()` (**default**)|Calls `request.changeSessionId()`. Same session and data, **new ID**. Fast.|
|`newSession()`|Makes a new session and copies **nothing** from the old one|
|`migrateSession()`|Makes a new session and **copies** the old attributes|
|`none()`|No protection. **Never use.**|

Choose `changeSessionId()` unless you have a specific reason not to. Use `newSession()` if you want a clean slate (for example, you don't trust anything stored before login).

**A related habit:** when someone's privilege level changes in the middle of a session (for example after re-entering a password to access an admin area), you can rotate the ID yourself:

```java
request.changeSessionId();
```

---

# Part 4: Stage 4, limit sessions per user

By default, one user may have unlimited sessions (laptop, phone, work PC). To limit them, use the **concurrency control** settings (available as `sessionConcurrency` in Spring Security 6.1 and later; older tutorials chain `.maximumSessions(...)` directly):

```java
http.sessionManagement(s -> s
    .sessionConcurrency(c -> c
        .maximumSessions(1)
        .maxSessionsPreventsLogin(false)
        .expiredUrl("/login?expired")));
```

Line by line:

- `maximumSessions(1)` allows one live session per user. Use `-1` for unlimited (useful when you only want tracking).
- `maxSessionsPreventsLogin(false)` means **the newest login wins**: the older session is marked expired. With `true`, the **new login is refused** while the old session lives.
- `expiredUrl("/login?expired")` is where an expired session's next request is sent.

|Setting|Laptop (first login)|Phone (second login)|
|---|---|---|
|`maxSessionsPreventsLogin(false)`|Kicked out at its next click|Allowed|
|`maxSessionsPreventsLogin(true)`|Stays logged in|Login refused|

### Two things it needs to work

```java
@Bean
SessionRegistry sessionRegistry() {
    return new SessionRegistryImpl();
}

@Bean
HttpSessionEventPublisher httpSessionEventPublisher() {
    return new HttpSessionEventPublisher();
}
```

- **`SessionRegistry`** is the list of "which user has which sessions." Concurrency control uses one internally, but declaring your own bean lets **you** use it too (Part 10).
- **`HttpSessionEventPublisher`** tells Spring Security when Tomcat destroys a session (timeout or logout). Without it, the registry never learns that sessions ended, and with `maxSessionsPreventsLogin(true)` users can get **locked out by their own dead sessions**. This is the most common bug with this feature.

Also, the principal object must have working `equals` and `hashCode`, because the registry keys sessions by it. Spring's built-in `User` class has them. If you write your own `UserDetails`, base them on the username or id.

How the "kick out" really happens: nothing is destroyed immediately. The old session is **marked expired**, and on its next request, the `ConcurrentSessionFilter` (added to the chain when you configure this) sees the mark, logs the session out, and redirects to `expiredUrl`.

---

# Part 5: Stage 6, what the user sees when a session dies

Two different "dead session" situations exist, and they have separate settings:

|Situation|What happened|Setting|
|---|---|---|
|**Invalid session**|The cookie holds an ID the server doesn't know (timed out, restarted, forged)|`invalidSessionUrl(...)`|
|**Expired session**|The session exists but was **marked expired** (by `maximumSessions` or by an admin)|`expiredUrl(...)`|

```java
http.sessionManagement(s -> s
    .invalidSessionUrl("/login?invalid")
    .sessionConcurrency(c -> c
        .maximumSessions(1)
        .expiredUrl("/login?expired")));
```

Notes:

- If you set **neither**, a user with a dead session is simply treated as anonymous and redirected to the login page by the normal entry point. That's often good enough.
- `invalidSessionUrl` has a known quirk: it can fire when someone returns after **logout** with a stale cookie, showing a "session invalid" message when "you logged out" would be more accurate. Delete the cookie at logout (Part 8) to reduce this.
- For **JSON APIs and AJAX**, a redirect to a login page is useless. Use a strategy that answers with a status code instead:

```java
.invalidSessionStrategy((request, response) -> {
    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
    response.setContentType("application/json");
    response.getWriter().write("{\"error\":\"session expired\"}");
})
```

- `invalidSessionStrategy(...)` replaces the URL version with code you control.
- The 401 tells your front end "log in again", and your JavaScript can show the login screen.

---

# Part 6: Stage 5, timeouts

There are two kinds, as you learned in the session lifetime lesson.

### Idle timeout (built in)

```properties
server.servlet.session.timeout=20m
```

The session dies after 20 minutes without a request. Any request using the session resets the timer. Tomcat counts in whole minutes.

### Absolute timeout (you add it)

"No matter how active you are, log in again after 8 hours." Spring Security has no built-in setting, so you add a small piece.

First, stamp the login time when a login succeeds:

```java
@Bean
AuthenticationSuccessHandler stampLoginTime() {
    SavedRequestAwareAuthenticationSuccessHandler delegate =
            new SavedRequestAwareAuthenticationSuccessHandler();
    return (request, response, auth) -> {
        request.getSession().setAttribute("LOGIN_TIME", Instant.now());
        delegate.onAuthenticationSuccess(request, response, auth);
    };
}
```

- The built-in handler remembers the page you originally wanted and redirects there after login. We wrap it, so we **keep that behavior** and just add one line.
- By the time this handler runs, the fixation protection has already changed the session ID, and the attributes are kept, so `LOGIN_TIME` lives in the new session.

Then a filter checks it:

```java
public class AbsoluteTimeoutFilter extends OncePerRequestFilter {

    private final Duration maxAge;

    public AbsoluteTimeoutFilter(Duration maxAge) {
        this.maxAge = maxAge;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session != null) {
            Instant login = (Instant) session.getAttribute("LOGIN_TIME");
            if (login != null && Duration.between(login, Instant.now()).compareTo(maxAge) > 0) {
                session.invalidate();
                response.sendRedirect(request.getContextPath() + "/login?expired");
                return;
            }
        }
        chain.doFilter(request, response);
    }
}
```

- `getSession(false)` looks at the session **without creating one**.
- If `LOGIN_TIME` is older than the limit, the session is destroyed and the user is redirected. `return` stops the chain.
- Otherwise the request continues.

Register it, and wire the handler into form login:

```java
http
    .formLogin(f -> f.successHandler(stampLoginTime()))
    .addFilterAfter(new AbsoluteTimeoutFilter(Duration.ofHours(8)),
                    SecurityContextHolderFilter.class);
```

Use `new` here, not a Spring bean, to avoid the **double registration trap** from the filter-chain lesson. With Spring Session and Redis, the same code works unchanged.

---

# Part 7: Cookie hardening

The session cookie is the key to the whole building. Set its rules in `application.properties`:

```properties
server.servlet.session.cookie.name=JSESSIONID
server.servlet.session.cookie.http-only=true
server.servlet.session.cookie.secure=true
server.servlet.session.cookie.same-site=lax
server.servlet.session.cookie.path=/
server.servlet.session.tracking-modes=cookie
```

|Setting|Protects against|
|---|---|
|`http-only`|XSS reading the ID|
|`secure`|Sniffing on plain HTTP|
|`same-site=lax`|Most cross-site sends (CSRF defense in depth)|
|`tracking-modes=cookie`|The ID leaking through URLs|

For extra strength, name the cookie `__Host-JSESSIONID`. The browser then **enforces** `Secure`, `Path=/`, and no `Domain`, so a sibling subdomain can't overwrite it. If you do, update `deleteCookies(...)` in your logout to match.

---

# Part 8: Stage 8, logout

Logout must destroy the **server-side** session, not only the cookie. Spring Security does this for you:

```java
http.logout(l -> l
    .logoutUrl("/logout")
    .invalidateHttpSession(true)
    .clearAuthentication(true)
    .deleteCookies("JSESSIONID")
    .logoutSuccessUrl("/login?logout"));
```

|Setting|What it does|
|---|---|
|`logoutUrl("/logout")`|Which URL triggers it. It matches **POST** by default (CSRF-protected).|
|`invalidateHttpSession(true)`|Destroys the session in Tomcat or Redis. **The one that matters.** (Default)|
|`clearAuthentication(true)`|Empties the `SecurityContext`. (Default)|
|`deleteCookies("JSESSIONID")`|Tells the browser to delete its copy. Tidy, not essential.|
|`logoutSuccessUrl(...)`|Where to go afterward|

Your logout button must send a POST with the CSRF token:

```html
<form th:action="@{/logout}" method="post">
  <button>Log out</button>
</form>
```

`th:action` makes Thymeleaf add the hidden `_csrf` field automatically.

For a JSON API with sessions, replace the redirect with a status:

```java
.logoutSuccessHandler((req, res, auth) -> res.setStatus(HttpServletResponse.SC_NO_CONTENT))
```

If you also use remember-me, logout deletes its token too.

---

# Part 9: Stage 7, sharing sessions across servers

Tomcat keeps sessions in **one server's memory**. With two or more servers, a user who logged in on server A is a stranger on server B, and a restart logs everyone out.

**Spring Session** moves the storage out of Tomcat into a shared store, **without changing your code**. `HttpSession` and Spring Security keep working as before.

Add the dependency:

```xml
<dependency>
    <groupId>org.springframework.session</groupId>
    <artifactId>spring-session-data-redis</artifactId>
</dependency>
```

And settings:

```properties
spring.data.redis.host=localhost
spring.data.redis.port=6379
spring.session.timeout=30m
spring.session.redis.namespace=myapp:session
```

What changes:

|Before (Tomcat memory)|After (Spring Session + Redis)|
|---|---|
|Session lives in one server|Session lives in Redis, every server can read it|
|Restart = everyone logged out|Restart keeps sessions|
|Cookie `JSESSIONID`|Cookie `SESSION` (its value is Base64-encoded, so it doesn't look identical to the real ID)|
|Tomcat sweeps old sessions|Redis expires them with a TTL|
|Timeout set by `server.servlet.session.timeout`|`spring.session.timeout` (falls back to the server setting if unset)|

Since the cookie is named differently, `deleteCookies("JSESSIONID")` in your logout should become `deleteCookies("SESSION")`. This is an easy one to miss.

If you use **JDBC** instead of Redis (you already know PostgreSQL), add `spring-session-jdbc`, and sessions go into tables (`SPRING_SESSION`, `SPRING_SESSION_ATTRIBUTES`). It's simpler to operate but slower than Redis.

### Concurrency control with Spring Session

The in-memory `SessionRegistryImpl` only knows about **one server's** sessions. Use the registry backed by the shared store instead:

```java
@Configuration
public class SessionConfig<S extends Session> {

    @Bean
    SpringSessionBackedSessionRegistry<S> sessionRegistry(
            FindByIndexNameSessionRepository<S> repository) {
        return new SpringSessionBackedSessionRegistry<>(repository);
    }
}
```

- `FindByIndexNameSessionRepository` can **look sessions up by username**. Spring Session indexes each session by principal name.
- `SpringSessionBackedSessionRegistry` adapts that to the `SessionRegistry` interface, so `maximumSessions(...)` and your own admin code work across all servers.

### Peeking inside Redis (Debian)

```bash
redis-cli --scan --pattern 'myapp:session:*'
```

You'll see keys such as:

|Key pattern|Holds|
|---|---|
|`...:sessions:<id>`|A hash with the session's attributes and times|
|`...:sessions:expires:<id>`|A marker key whose TTL drives expiry|
|`...:expirations:<time>`|A set of sessions expiring around that minute|
|`...:index:...PRINCIPAL_NAME_INDEX_NAME:alice`|The set of session IDs belonging to `alice`|

Use `--scan`, not `KEYS *`, because `KEYS` blocks Redis on big datasets.

---

# Part 10: Managing sessions from your own code

With the `SessionRegistry` bean, you can build admin features.

```java
@Service
public class SessionService {

    private final SessionRegistry registry;

    public SessionService(SessionRegistry registry) {
        this.registry = registry;
    }

    public List<SessionInformation> sessionsOf(Object principal) {
        return registry.getAllSessions(principal, false);
    }

    public void logoutEverywhere(Object principal) {
        registry.getAllSessions(principal, false)
                .forEach(SessionInformation::expireNow);
    }

    public void expireOthers(Object principal, String currentSessionId) {
        registry.getAllSessions(principal, false).stream()
                .filter(s -> !s.getSessionId().equals(currentSessionId))
                .forEach(SessionInformation::expireNow);
    }
}
```

Line by line:

- `getAllSessions(principal, false)` returns that user's sessions. `false` means "exclude already-expired ones."
- `SessionInformation` holds the session ID, last request time, and expired flag. It does **not** contain device names. If you want "Chrome on Windows", store the `User-Agent` and IP in a session attribute at login.
- `expireNow()` marks the session expired. Its owner is sent to `expiredUrl` at the next request.
- `expireOthers` keeps the current session alive while killing the rest, which is what "log out of other devices" buttons do.

### Situations where you need this

|Event|What to do|
|---|---|
|User **changes password**|`expireOthers(...)`, so stolen sessions die|
|Admin **disables an account**|`logoutEverywhere(...)`. `UserDetails.isEnabled()` is only checked at login, so existing sessions keep working.|
|Admin **changes someone's roles**|Same, because the live session holds the **old** authorities|
|Suspicious activity detected|Same, and optionally notify the user|
|"Active devices" page|`sessionsOf(...)` plus your stored device info|

---

# Part 11: Everything together

A solid starting configuration for a classic web app (Spring Security 6.1+):

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain web(HttpSecurity http,
                            SessionRegistry registry,
                            AuthenticationSuccessHandler stampLoginTime) throws Exception {
        http
            .authorizeHttpRequests(a -> a
                .requestMatchers("/login", "/error", "/css/**").permitAll()
                .anyRequest().authenticated())
            .formLogin(f -> f.successHandler(stampLoginTime))
            .sessionManagement(s -> s
                .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
                .sessionFixation(f -> f.changeSessionId())
                .invalidSessionUrl("/login?invalid")
                .sessionConcurrency(c -> c
                    .maximumSessions(3)
                    .maxSessionsPreventsLogin(false)
                    .expiredUrl("/login?expired")
                    .sessionRegistry(registry)))
            .addFilterAfter(new AbsoluteTimeoutFilter(Duration.ofHours(8)),
                            SecurityContextHolderFilter.class)
            .logout(l -> l
                .logoutUrl("/logout")
                .invalidateHttpSession(true)
                .clearAuthentication(true)
                .deleteCookies("JSESSIONID")
                .logoutSuccessUrl("/login?logout"));
        return http.build();
    }

    @Bean
    SessionRegistry sessionRegistry() {
        return new SessionRegistryImpl();
    }

    @Bean
    HttpSessionEventPublisher httpSessionEventPublisher() {
        return new HttpSessionEventPublisher();
    }
}
```

```properties
server.servlet.session.timeout=20m
server.servlet.session.cookie.http-only=true
server.servlet.session.cookie.secure=true
server.servlet.session.cookie.same-site=lax
server.servlet.session.tracking-modes=cookie
```

Remember that `stampLoginTime` (from Part 6) is a bean you define in the same class or another `@Configuration`. When you move to Redis, swap `SessionRegistryImpl` for `SpringSessionBackedSessionRegistry`, change the cookie name in `deleteCookies`, and drop `HttpSessionEventPublisher` only if you've confirmed Spring Session's own events keep your registry accurate.

---

# Try it yourself

First, a small helper for logging in with `curl` against a form-login app (you've seen the pieces before):

```bash
login() {   # usage: login <cookie-jar> <user> <password>
  local jar=$1
  local token
  token=$(curl -s -c "$jar" http://localhost:8080/login | grep -oP 'name="_csrf"[^>]*value="\K[^"]+')
  curl -s -o /dev/null -w "%{http_code} -> %{redirect_url}\n" -b "$jar" -c "$jar" \
       -d "username=$2&password=$3&_csrf=$token" http://localhost:8080/login
}
```

- The first `curl` fetches the login page, saves the pre-login cookie, and extracts the CSRF token from the HTML.
- The second `curl` submits the form. `-w` prints the status and redirect target, so you can see `302 -> http://localhost:8080/`.

**1. Watch fixation protection:**

```bash
curl -s -c a.txt http://localhost:8080/login > /dev/null
grep SESSION a.txt            # the pre-login ID
login a.txt alice secret
grep SESSION a.txt            # a different ID after login
```

The value changes, which is `changeSessionId()` at work.

**2. Try concurrency control (set `maximumSessions(1)`):**

```bash
login a.txt alice secret
login b.txt alice secret                                 # second "browser"
curl -i -b a.txt http://localhost:8080/hello             # a.txt is now expired → redirect to /login?expired
curl -i -b b.txt http://localhost:8080/hello             # b.txt works
```

Then flip to `maxSessionsPreventsLogin(true)` and watch the **second** login get refused instead.

**3. Watch an idle timeout:**  
Set `server.servlet.session.timeout=1m`, log in, wait 70 seconds, then request a protected page with the same jar. You'll be redirected to the login page (or to `invalidSessionUrl`).

**4. Prove logout kills the server session:**

```bash
login a.txt alice secret
cp a.txt old.txt
# log out using a.txt (POST with a CSRF token), then:
curl -i -b old.txt http://localhost:8080/hello
```

The old cookie no longer works, even though you still hold it. The coat is gone.

**5. Kill sessions from code:** add a small endpoint calling `logoutEverywhere(...)`, call it, and watch the other jar get redirected.

**6. Confirm STATELESS:** for a token API chain, call an endpoint and check that **no `Set-Cookie`** appears in `curl -i`.

**7. Test it in code:**

```java
@Test
void loginCreatesUsableSession() throws Exception {
    MvcResult login = mockMvc.perform(post("/login")
                    .param("username", "alice").param("password", "secret").with(csrf()))
            .andExpect(status().is3xxRedirection())
            .andReturn();

    MockHttpSession session = (MockHttpSession) login.getRequest().getSession(false);

    mockMvc.perform(get("/orders").session(session))
            .andExpect(status().isOk());
}
```

- `.with(csrf())` adds a valid CSRF token to the fake request.
- `getSession(false)` retrieves the session created by login, the same way a browser would keep its cookie.
- `.session(session)` replays it on the next request. This tests the whole "login once, stay logged in" path.

---

# Common mistakes

|Mistake|Why it hurts|Fix|
|---|---|---|
|Missing `HttpSessionEventPublisher` with `maximumSessions`|The registry never sees ended sessions, so users get locked out|Register the bean|
|`STATELESS`, but your code calls `getSession()`|Sessions are created anyway|Use `getSession(false)`, or don't touch sessions|
|Custom login endpoint that doesn't save the context|Login lasts one request|Call `securityContextRepository.saveContext(...)`|
|`sessionFixation().none()`|Reopens the fixation hole|Keep `changeSessionId()`|
|Storing big objects in the session|Memory (or Redis) blow-up|Store ids, load from the database|
|Expecting role changes to apply instantly|The live session holds old authorities|Expire that user's sessions|
|`invalidSessionUrl` redirect for AJAX calls|The front end receives HTML|Use `invalidSessionStrategy` returning 401|
|Forgetting that `SESSION` replaces `JSESSIONID` with Spring Session|Logout doesn't delete the cookie|Update `deleteCookies(...)`|
|Using in-memory `SessionRegistryImpl` on multiple servers|Each server counts only its own sessions|`SpringSessionBackedSessionRegistry`|
|Custom `UserDetails` without `equals` and `hashCode`|The registry can't group sessions by user|Implement both|
|A polling endpoint that touches the session|The idle timeout never fires|Exclude it from session use, or accept it|
|Keeping the session ID in the URL|Leaks through logs and `Referer`|`tracking-modes=cookie`|
|Clearing only the cookie at logout|The server session lives on|`invalidateHttpSession(true)`|
|Making the security filter a bean without disabling its Tomcat registration|It runs twice|`new` it inside the chain|

---

## Related concept, briefly

**`@SessionAttributes` and session-scoped beans:** these are Spring MVC and Spring core tools for storing **your own data** in the session. `@SessionAttributes("cart")` on a controller keeps a model attribute in the session between requests (useful for multi-step wizards), and a bean declared with `@SessionScope` gets one instance per user session. Both ride on the same `HttpSession`, so they share its timeout, its cookie, and its Redis storage. Treat them like any session data: keep them small and serializable.

---

## The whole picture

|Question|Answer|
|---|---|
|What does Spring Security store in the session?|The `SecurityContext` (who you are) under `SPRING_SECURITY_CONTEXT`|
|Who loads it each request?|`SecurityContextHolderFilter`, using `SecurityContextRepository`|
|Who saves it?|Whatever performs the login (form login does; custom code must call `saveContext`)|
|When is a session created?|Controlled by `sessionCreationPolicy` (`IF_REQUIRED` by default)|
|How do I stop fixation?|`sessionFixation().changeSessionId()` (default)|
|How do I limit sessions per user?|`sessionConcurrency(c -> c.maximumSessions(n))` plus `HttpSessionEventPublisher`|
|Which new login wins?|`maxSessionsPreventsLogin(false)` = newest wins|
|How do I list or kill sessions?|A `SessionRegistry` bean and `expireNow()`|
|Idle timeout?|`server.servlet.session.timeout` (or `spring.session.timeout`)|
|Absolute timeout?|Your own small filter plus a login-time attribute|
|What do users see when a session dies?|`invalidSessionUrl` / `invalidSessionStrategy` and `expiredUrl`|
|Many servers?|Spring Session with Redis or JDBC|
|Cookie safety?|`HttpOnly`, `Secure`, `SameSite`, cookie-only tracking, maybe `__Host-`|
|Logout?|`invalidateHttpSession(true)`, a POST with a CSRF token|
|No sessions at all?|`STATELESS` plus tokens (JWT)|




[[Spring Security]]