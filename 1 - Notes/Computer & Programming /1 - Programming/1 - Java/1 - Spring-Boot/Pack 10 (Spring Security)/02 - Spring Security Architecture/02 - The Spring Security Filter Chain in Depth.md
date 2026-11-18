

## The problem it solves

Security isn't one check. For every request, someone has to ask many questions, in the right order:

- Is this a forged request?
- Who is this person?
- Is that person allowed to do this?
- What should the response headers say?
- What if any answer is "no"?

If you wrote all of that inside your controllers, you'd repeat it everywhere and forget it somewhere. Spring Security puts each question in its own **filter**. A filter has one job, and the filters are lined up in a fixed order so each one can rely on the work of the ones before it.

> The filter chain is a row of small checkpoints that every request must walk through before it is allowed to reach the DispatcherServlet.

## The picture: airport security

|Airport|Filter chain|
|---|---|
|Every passenger passes the same checkpoints in the same order|Every request passes the same filters in the same order|
|One desk checks your passport, another scans your bag, another checks your boarding pass|One filter handles CSRF, another login, another authorization|
|Checking the boarding pass before checking the passport would make no sense|Authorization comes after authentication, so order matters|
|A guard can stop you at any desk|Any filter can stop the request and answer it directly|
|A supervisor handles the cases where someone is turned away|`ExceptionTranslationFilter` turns "denied" into a redirect or a 401/403|

## The map

```
Part 1: Where the chain lives     (Tomcat → DelegatingFilterProxy → FilterChainProxy)
Part 2: How one filter works      (before, chain.doFilter, after)
Part 3: The filters, in order     (what each one does and why it sits there)
Part 4: Three requests, traced    (anonymous, login, logged-in)
Part 5: Authentication inside     (AuthenticationManager, providers)
Part 6: Customizing               (multiple chains, your own filter, error handlers)
Part 7: Debugging and experiments
```

---

# Part 1: Where the chain lives

You know that Tomcat has its own filters and then hands the request to the DispatcherServlet. Spring Security plugs **one** filter into Tomcat. That filter contains the whole security world inside it.

```
Tomcat's filter chain
  ├─ CharacterEncodingFilter, other container-level filters...
  ├─ DelegatingFilterProxy  "springSecurityFilterChain"    ← the one door into Spring Security
  │       │
  │       ▼
  │   FilterChainProxy  (a Spring bean)
  │       │  1. HttpFirewall checks the request
  │       │  2. picks the FIRST matching SecurityFilterChain
  │       ▼
  │   SecurityFilterChain (a list of ~15 filters)
  │       DisableEncodeUrlFilter → ... → AuthorizationFilter
  │       │
  ├─ (more container filters)
  ▼
DispatcherServlet → your controller
```

|Piece|Job|
|---|---|
|**`DelegatingFilterProxy`**|A thin standard servlet filter. Tomcat creates filters _before_ Spring's beans exist, so this one looks up the real filter bean by name **later** and hands the request to it.|
|**`FilterChainProxy`**|The real entry point. A Spring bean that owns **all** your security chains and decides which one applies to this request.|
|**`SecurityFilterChain`**|One list of filters plus a **matcher** ("I handle `/api/**`"). You define these as beans.|
|**The individual filters**|Plain Java objects managed by `FilterChainProxy`. **Tomcat doesn't know they exist.**|

In Spring Boot, auto-configuration registers the `DelegatingFilterProxy` for you, with a high-priority order (`-100`), so it runs early.

## The firewall runs first

Before any chain is chosen, `FilterChainProxy` passes the request to the **`HttpFirewall`** (`StrictHttpFirewall` by default). It wraps the request and rejects suspicious ones: encoded slashes, `;` in the path, `..` tricks, odd control characters. A rejected request gets a `RequestRejectedException`, which is turned into a **400** response. This is why `/orders;jsessionid=abc` died in the earlier lesson, before any filter ran.

## How the chain is chosen

You can define several `SecurityFilterChain` beans. `FilterChainProxy` tries them **in order** and uses the **first one whose matcher accepts the request**. Only that chain's filters run.

```java
@Bean @Order(1)
SecurityFilterChain api(HttpSecurity http) throws Exception {
    http.securityMatcher("/api/**")
        ...;
    return http.build();
}

@Bean @Order(2)
SecurityFilterChain web(HttpSecurity http) throws Exception {
    http.authorizeHttpRequests(a -> a.anyRequest().authenticated())
        .formLogin(Customizer.withDefaults());
    return http.build();
}
```

Line by line:

- `@Order(1)` and `@Order(2)` set the trial order. Lower numbers are tried first.
- `securityMatcher("/api/**")` says "this chain only applies to URLs under `/api`."
- The second chain has **no** matcher, so it matches everything left over (the catch-all).
- `http.build()` assembles the filter list, in the correct fixed order, from what you configured.

Two traps here:

1. A chain **without** a matcher matches **everything**. If it has the lowest `@Order` number, the chains after it will never be used.
2. If **no** chain matches a request, the request goes through with **no security at all**. Always end with a catch-all.

---

# Part 2: How one filter works

Every filter implements the servlet `Filter` interface (usually by extending Spring's `OncePerRequestFilter`). The contract is the same everywhere:

```java
protected void doFilterInternal(HttpServletRequest request,
                                HttpServletResponse response,
                                FilterChain chain) throws ServletException, IOException {

    // 1. BEFORE: look at the request, maybe do something

    chain.doFilter(request, response);   // 2. pass it on to the next filter

    // 3. AFTER: the response is on its way back, maybe do something
}
```

A filter can do one of three things:

|Choice|What it looks like|Example|
|---|---|---|
|**Let it pass**|Calls `chain.doFilter(...)`|A request with a valid CSRF token|
|**Stop it and answer directly**|Writes a response and **doesn't** call `chain.doFilter`|CSRF check failed, so it answers 403|
|**Wrap it**|Passes modified request or response objects down the chain|`SecurityContextHolderAwareRequestFilter`|

Because each filter wraps the rest, the chain behaves like an **onion**:

```
Request  ─▶ [ F1 ─▶ [ F2 ─▶ [ F3 ─▶ ... controller ... ] ◀─ F3 ] ◀─ F2 ] ◀─ F1 ─▶ Response
```

Code after `chain.doFilter(...)` runs on the **way back**, in reverse order. That's how `SecurityContextHolderFilter` can clean up at the end, and how `ExceptionTranslationFilter` can catch problems from filters **after** it.

---

# Part 3: The filters, in order

The order is fixed by Spring Security. It's not the order you write things in your configuration. Here are the filters you'll meet, in their real order. **Which ones are present depends on what you enabled.** For example, `UsernamePasswordAuthenticationFilter` exists only if you enabled `formLogin`.

|#|Filter|Present when|Its one job|
|---|---|---|---|
|1|`DisableEncodeUrlFilter`|default|Stops `;jsessionid=...` from being added to URLs|
|2|`WebAsyncManagerIntegrationFilter`|default|Carries the security context into async request handling|
|3|**`SecurityContextHolderFilter`**|default|**Loads** "who is logged in" from the session onto this thread|
|4|`HeaderWriterFilter`|default|Adds security headers (HSTS, `X-Content-Type-Options`, ...)|
|5|`CorsFilter`|`http.cors(...)`|Answers CORS preflights before authentication|
|6|**`CsrfFilter`**|default|Rejects forged state-changing requests|
|7|`LogoutFilter`|default|Handles `POST /logout`|
|8|OAuth2 / SAML filters|`oauth2Login()` etc.|"Sign in with Google" redirects and callbacks|
|9|**`UsernamePasswordAuthenticationFilter`**|`formLogin()`|Handles `POST /login`|
|10|`DefaultLoginPageGeneratingFilter`|`formLogin()` without a custom page|Draws the built-in login page|
|11|`BearerTokenAuthenticationFilter`|`oauth2ResourceServer()`|Reads `Authorization: Bearer ...` (JWT)|
|12|**`BasicAuthenticationFilter`**|`httpBasic()`|Reads `Authorization: Basic ...`|
|13|`RequestCacheAwareFilter`|default|After login, replays the page you originally wanted|
|14|`SecurityContextHolderAwareRequestFilter`|default|Makes `request.getUserPrincipal()` and `isUserInRole()` work|
|15|`RememberMeAuthenticationFilter`|`rememberMe()`|Logs you in from the remember-me cookie|
|16|**`AnonymousAuthenticationFilter`**|default|Gives not-logged-in users an "anonymous" identity|
|17|`SessionManagementFilter`|default|Session-related checks (for example, an invalid session)|
|18|**`ExceptionTranslationFilter`**|default|Turns security exceptions into redirects, 401, or 403|
|19|**`AuthorizationFilter`**|default|**The final gate**: may this user access this URL?|

(The real list has a few more entries for rare features such as X.509, CAS, and switch-user. Version 7 may shift small details. Part 7 shows how to print the exact list for **your** app.)

Now let's go through the important ones, in groups.

## Group A: Setting the stage

### `SecurityContextHolderFilter` (#3): "who is this?"

**The problem it solves:** every later filter and your controllers need to ask "who is the current user?" without passing a parameter around.

What it does:

1. Asks a **`SecurityContextRepository`** to load the saved login. The default one reads the **HttpSession** attribute `SPRING_SECURITY_CONTEXT`, the thing you studied in the sessions lesson.
2. Puts the result into **`SecurityContextHolder`**, which stores it in a **ThreadLocal** (a variable that belongs to the current thread, which is the current request's thread).
3. Calls the rest of the chain.
4. **Clears** the holder on the way back, so the next request that reuses this thread doesn't see the old user.

Two details worth knowing:

- The loading is **lazy** (deferred). The session is only touched if someone actually asks for the context. That's why public pages don't create sessions or reset timers needlessly.
- In Spring Security 6 and later, this filter **only loads**. It does **not save** the context at the end. Saving is done explicitly by whoever logs the user in. (This matters for custom login code. See Part 6.)

With `SessionCreationPolicy.STATELESS`, the repository is swapped for one that keeps the context only for this single request, so sessions are never read or written.

### `HeaderWriterFilter` (#4)

Adds the security headers you met in earlier lessons: `X-Content-Type-Options`, `X-Frame-Options`, `Cache-Control`, and `Strict-Transport-Security` (only on HTTPS requests). It arranges for them to be written just before the response is committed, so they're present even if a later filter or controller writes the response.

### `CorsFilter` (#5)

Present only if you call `http.cors(...)`. It sits **before** authentication on purpose. A CORS preflight (`OPTIONS`) carries no credentials, so if authentication came first, every preflight would fail with 401, and the real request would never be sent.

## Group B: Attack protection

### `CsrfFilter` (#6)

**The problem it solves:** forged requests that ride on automatic cookies.

```
Request arrives
  ├─ method is GET, HEAD, TRACE, or OPTIONS?  → safe, skip the check
  └─ otherwise:
        expected token = the one stored for this session
        actual token   = header X-CSRF-TOKEN, or form field _csrf
        match?   YES → continue down the chain
                 NO  → AccessDeniedHandler → 403
```

Notes:

- The token is generated lazily, and since Spring Security 6 it's **masked** with a random value on each response (protection against the BREACH compression attack), so the string in your page changes on every load, though they all validate.
- This is why `GET` must never change data. The filter doesn't check it.
- A rejected token never reaches your controller, which makes it a nice 403 to find in the logs.

### `LogoutFilter` (#7)

Matches `POST /logout` (a POST, so it's covered by CSRF). It runs a list of **logout handlers**: invalidate the HttpSession, clear the SecurityContext, delete cookies you listed, and delete remember-me tokens. Then it runs the logout success handler (a redirect to `/login?logout`). Requests that don't match pass straight through.

## Group C: Authentication filters

These are the filters that **create** a login. Each knows one kind of credential. They follow the same pattern:

```
1. Does this request carry MY kind of credential?   no → pass through untouched
2. Wrap the credential in an UNAUTHENTICATED Authentication object
3. Hand it to the AuthenticationManager
4. SUCCESS → put the authenticated result into the SecurityContext
   FAILURE → clear the context, call the failure handler or entry point
```

### `UsernamePasswordAuthenticationFilter` (#9): form login

It only reacts to `POST /login`. It reads the `username` and `password` form fields and builds an unauthenticated token. After a **successful** authentication, it does these things, in this order:

1. **Session strategy:** this is where **session fixation protection** happens (new session ID) and `maximumSessions` is enforced.
2. **Sets the context** into the `SecurityContextHolder`.
3. **Saves the context** to the repository, which stores it in the HttpSession.
4. Runs remember-me's login-success hook, if enabled.
5. Calls the **success handler**, which redirects you to the page you first requested (found via the request cache), or to `/`.

On **failure**, it clears the context and the failure handler redirects to `/login?error`.

### `BasicAuthenticationFilter` (#12)

Looks for `Authorization: Basic base64(user:pass)` on **any** request, not only `/login`. On success, it sets the context for this request (and, if sessions are allowed, it can be stored). On failure, it uses the entry point, which answers **401** with `WWW-Authenticate: Basic realm="Realm"`. Always use it with HTTPS.

### `BearerTokenAuthenticationFilter` (#11)

Looks for `Authorization: Bearer <JWT>`. It builds a `BearerTokenAuthenticationToken` and sends it to the authentication manager, where a JWT provider verifies the signature, `exp`, and so on (the checklist from the JWT lesson). On failure: **401** with `WWW-Authenticate: Bearer`.

### `RememberMeAuthenticationFilter` (#15)

Runs **only if nobody is logged in yet**. It looks for the remember-me cookie, validates the token, and creates a new authenticated context (and new session) as in the earlier lesson.

> **Why many authentication filters can coexist:** each ignores requests that don't carry its credential. A request with a Bearer header is ignored by the form filter and handled by the bearer filter. A request with neither goes on to the anonymous filter.

## Group D: Housekeeping before the gate

### `RequestCacheAwareFilter` (#13)

**The problem it solves:** you click `/orders/42`, get sent to the login page, log in, and expect to land on `/orders/42`, not the home page.

When an unauthenticated user is turned away, `ExceptionTranslationFilter` saves the original request in a **request cache** (the HttpSession by default). After login, this filter replays it. By default, only `GET` requests that look like page navigations are saved, not API/AJAX calls.

### `SecurityContextHolderAwareRequestFilter` (#14)

Wraps the request so old-style servlet calls work: `request.getUserPrincipal()`, `request.isUserInRole("ADMIN")`, `request.getRemoteUser()`, and `request.login(...)`.

### `AnonymousAuthenticationFilter` (#16)

**The problem it solves:** later code would need constant `if (auth == null)` checks. Instead, if the context is **empty** at this point, this filter fills in an **anonymous** identity:

|Field|Value|
|---|---|
|Principal|`"anonymousUser"`|
|Authorities|`ROLE_ANONYMOUS`|
|`isAuthenticated()`|technically `true`, but treated as "not logged in" by rules like `authenticated()`|

So "not logged in" really means "logged in as anonymous." Rules like `permitAll()` and `authenticated()` use that distinction.

### `SessionManagementFilter` (#17)

Handles session-related situations, such as redirecting when a request arrives with an invalid or expired session ID (if you configured `invalidSessionUrl`). In Spring Security 6+, the heavy lifting of fixation protection has moved to the authentication filters themselves, as described above.

## Group E: The last two, and the most important

These two sit at the end on purpose. The first catches the second's complaints.

### `AuthorizationFilter` (#19): the gate

This is where `authorizeHttpRequests(...)` rules are enforced. It asks an `AuthorizationManager` the question: **"may this Authentication access this request?"**

```java
http.authorizeHttpRequests(auth -> auth
    .requestMatchers("/public/**").permitAll()
    .requestMatchers("/admin/**").hasRole("ADMIN")
    .anyRequest().authenticated());
```

How the rules are used:

- They are checked **top to bottom, and the first match wins**.
- If **no** rule matches, access is denied (which is why you always end with `anyRequest()`).
- `permitAll()` still lets the request travel through **every filter**, such as CSRF, headers, and the anonymous filter. It just allows the final gate to open. That's different from `web.ignoring()`, which skips the chain completely (and loses the headers). Prefer `permitAll()`.

If the answer is "no," the filter **throws** an `AccessDeniedException`. It doesn't write the response itself. It hands the problem back up the onion, to...

### `ExceptionTranslationFilter` (#18): the supervisor

This one is a **try/catch wrapped around everything after it** (including `AuthorizationFilter` and your whole controller):

```java
try {
    chain.doFilter(request, response);       // everything below
} catch (AuthenticationException ex) { ... }
  catch (AccessDeniedException ex)   { ... }
```

It decides what the client sees:

```
AccessDeniedException caught
   ├─ is the user anonymous (or remember-me only)?
   │       YES → "you need to log in"  → save the request, call the ENTRY POINT
   └─ NO (really logged in)
           → "you're known but not allowed" → ACCESS DENIED HANDLER → 403

AuthenticationException caught
   → clear the context, save the request, call the ENTRY POINT
```

|Component|Meaning|Default behavior|
|---|---|---|
|**`AuthenticationEntryPoint`**|"Start authentication"|`formLogin` → **302 redirect to `/login`**. `httpBasic` → **401** + `WWW-Authenticate: Basic`. Bearer → **401** + `WWW-Authenticate: Bearer`. With no mechanism configured → **403**.|
|**`AccessDeniedHandler`**|"Logged in, but no"|**403 Forbidden**|

This is where the 401 vs 403 distinction from the HTTP lesson gets decided. And it explains an earlier rule: **it can only catch exceptions from filters placed after it.** An exception in `CsrfFilter` (earlier in the chain) is handled by that filter's own access denied handler, not by this one.

---

# Part 4: Three requests, traced

## Request 1: an anonymous user asks for a protected page

`GET /orders` with no cookie, app has `formLogin`.

```
1. FilterChainProxy: firewall OK → picks the chain
2. DisableEncodeUrlFilter, WebAsyncManagerIntegrationFilter   (pass)
3. SecurityContextHolderFilter: no session → empty context
4. HeaderWriterFilter: arranges security headers
5. CsrfFilter: GET is safe → pass
6. LogoutFilter: not /logout → pass
7. UsernamePasswordAuthenticationFilter: not POST /login → pass
8. RequestCacheAwareFilter: nothing saved → pass
9. AnonymousAuthenticationFilter: context empty → set anonymousUser
10. ExceptionTranslationFilter: wraps what follows in try/catch
11. AuthorizationFilter: /orders requires authenticated() → anonymous is NOT enough
        → throws AccessDeniedException
12. ExceptionTranslationFilter catches: user is anonymous
        → saves "GET /orders" in the request cache
        → entry point: 302 Location: /login
```

The DispatcherServlet and your controller were **never reached**. The browser follows the redirect to `/login`, and `DefaultLoginPageGeneratingFilter` draws the page.

## Request 2: the login form is submitted

`POST /login` with `username`, `password`, and `_csrf`.

```
1. SecurityContextHolderFilter: empty context
2. CsrfFilter: token present and matches → pass
3. UsernamePasswordAuthenticationFilter: matches POST /login
     a. builds UsernamePasswordAuthenticationToken (unauthenticated)
     b. AuthenticationManager → checks the password → returns an AUTHENTICATED token
     c. session strategy: change session ID (fixation protection)
     d. context set in the holder, saved into the HttpSession
     e. success handler: looks up the saved request "/orders"
        → 302 Location: /orders
        + Set-Cookie: JSESSIONID=<new id>
```

The chain **ends here**. This filter answers directly, so no later filters or controller run.

## Request 3: the browser follows the redirect to `/orders`

`GET /orders` with `Cookie: JSESSIONID=<new id>`.

```
1. SecurityContextHolderFilter: reads the session → finds SecurityContext(alice, ROLE_USER)
        → puts it in the ThreadLocal
2. ...pass...
3. AnonymousAuthenticationFilter: context is NOT empty → does nothing
4. ExceptionTranslationFilter: wraps the rest
5. AuthorizationFilter: authenticated() → alice qualifies → ALLOW
6. → DispatcherServlet → OrdersController → response
7. On the way back: SecurityContextHolderFilter CLEARS the ThreadLocal
```

Notice that the **same chain** produced three different outcomes, depending only on what the request carried. That's the design.

---

# Part 5: What happens inside "the AuthenticationManager"

The authentication filters don't check passwords themselves. They delegate:

```
UsernamePasswordAuthenticationFilter
        │  authenticate(unauthenticated token)
        ▼
ProviderManager                      (the usual AuthenticationManager)
        │  asks each provider: "do you support this token type?"
        ▼
DaoAuthenticationProvider
        │  1. userDetailsService.loadUserByUsername("alice")
        │  2. checks the account is enabled, not locked, not expired
        │  3. passwordEncoder.matches(typedPassword, storedHash)
        ▼
AUTHENTICATED token (principal, authorities)  or  AuthenticationException
```

|Part|Job|
|---|---|
|**`AuthenticationManager`**|One method: `authenticate(...)`. The contract.|
|**`ProviderManager`**|The standard implementation. It tries a **list** of providers.|
|**`AuthenticationProvider`**|Knows how to check one kind of credential (database password, JWT, LDAP...).|
|**`UserDetailsService`**|Your code or a built-in: "find the user named X."|
|**`PasswordEncoder`**|Compares a typed password with the stored hash.|

Failure cases map to exceptions you may have seen: `BadCredentialsException` (wrong password), `LockedException`, `DisabledException`, `AccountExpiredException`, `UsernameNotFoundException`. By default, Spring hides whether the username or the password was wrong, so attackers can't enumerate valid usernames.

You normally won't build this yourself. Defining a `UserDetailsService` bean and a `PasswordEncoder` bean is enough, and Spring Boot wires the rest.

---

# Part 6: Customizing the chain

## 6.1 Adding your own filter

You can insert a filter at a position **relative** to a known one:

|Method|Meaning|
|---|---|
|`addFilterBefore(filter, X.class)`|Run just before filter X|
|`addFilterAfter(filter, X.class)`|Run just after filter X|
|`addFilterAt(filter, X.class)`|Take X's position (it doesn't replace X, both run)|

Here's a complete example: an API that accepts a secret key in a header.

```java
public class ApiKeyFilter extends OncePerRequestFilter {

    private final byte[] expectedKey;

    public ApiKeyFilter(String expectedKey) {
        this.expectedKey = expectedKey.getBytes(StandardCharsets.UTF_8);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {

        String supplied = request.getHeader("X-API-Key");

        if (supplied != null && MessageDigest.isEqual(
                supplied.getBytes(StandardCharsets.UTF_8), expectedKey)) {

            Authentication auth = UsernamePasswordAuthenticationToken.authenticated(
                    "api-client", null, List.of(new SimpleGrantedAuthority("ROLE_API")));

            SecurityContext context = SecurityContextHolder.createEmptyContext();
            context.setAuthentication(auth);
            SecurityContextHolder.setContext(context);
        }

        chain.doFilter(request, response);
    }
}
```

Line by line:

- `OncePerRequestFilter` guarantees the filter runs once per request, even with forwards.
- The constructor stores the secret as bytes so we can compare them safely later.
- `request.getHeader("X-API-Key")` reads the credential. If it's missing, we simply do nothing and **let the request continue**, as a polite authentication filter should. Later filters will treat the user as anonymous and the gate will refuse.
- `MessageDigest.isEqual(...)` compares in **constant time**, so response timing can't leak how many characters matched.
- `UsernamePasswordAuthenticationToken.authenticated(...)` builds an **already authenticated** token with a name and one authority. The `null` is the credentials, which we don't need to keep.
- `createEmptyContext()` then `setAuthentication(...)` and `setContext(...)` creates a **fresh** context instead of mutating a shared one, which is the recommended pattern.
- `chain.doFilter(...)` passes the request on, now carrying an identity.
- We never save into a session. Each request proves itself, so this is stateless.

Register it:

```java
@Bean
SecurityFilterChain api(HttpSecurity http,
                        @Value("${app.api-key}") String apiKey) throws Exception {
    http
        .securityMatcher("/api/**")
        .csrf(c -> c.disable())
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .addFilterBefore(new ApiKeyFilter(apiKey), UsernamePasswordAuthenticationFilter.class)
        .authorizeHttpRequests(a -> a.anyRequest().hasRole("API"))
        .exceptionHandling(e -> e
            .authenticationEntryPoint((req, res, ex) -> {
                res.setStatus(401);
                res.setContentType("application/json");
                res.getWriter().write("{\"error\":\"missing or invalid API key\"}");
            })
            .accessDeniedHandler((req, res, ex) -> {
                res.setStatus(403);
                res.setContentType("application/json");
                res.getWriter().write("{\"error\":\"forbidden\"}");
            }));
    return http.build();
}
```

Line by line:

- `securityMatcher("/api/**")` limits this chain to API URLs.
- `csrf(c -> c.disable())` is acceptable here because there's no automatic cookie to abuse (the "no automatic credential, no CSRF" rule).
- `STATELESS` means no sessions. The key must be sent every time.
- `addFilterBefore(..., UsernamePasswordAuthenticationFilter.class)` places our filter **after** `SecurityContextHolderFilter` (so our context isn't overwritten) and **before** the authorization gate. Using this class as a position marker works even when form login isn't enabled.
- `hasRole("API")` matches the `ROLE_API` authority we granted.
- `authenticationEntryPoint(...)` answers **401 in JSON** when someone isn't authenticated. Without it, a chain with no login mechanism answers a bare 403.
- `accessDeniedHandler(...)` answers **403 in JSON** when someone is known but not allowed.

## 6.2 The duplicate-filter trap

> **Never declare your security filter as a Spring bean (`@Component`, `@Bean`) unless you also prevent Boot from registering it.**

Spring Boot automatically registers every `Filter` bean it finds in **Tomcat's** filter chain. If your `ApiKeyFilter` is also in the **security** chain, it runs **twice** per request, once in Tomcat's chain (outside security, possibly before the context is even set up) and once in the security chain. That produces confusing bugs.

That's why the example above uses `new ApiKeyFilter(apiKey)` instead of a bean. If you do need a bean, add this to keep it out of Tomcat's chain:

```java
@Bean
FilterRegistrationBean<ApiKeyFilter> apiKeyFilterRegistration(ApiKeyFilter filter) {
    FilterRegistrationBean<ApiKeyFilter> reg = new FilterRegistrationBean<>(filter);
    reg.setEnabled(false);
    return reg;
}
```

`setEnabled(false)` tells Boot "don't put this in Tomcat's chain." It stays a bean that you can inject into the security chain.

## 6.3 Custom login endpoints need an explicit save

In Spring Security 6 and later, `SecurityContextHolderFilter` **doesn't save** the context for you. If you write your own `/api/login` controller that authenticates manually and sets the context, the user will be logged out on the next request unless you also save it:

```java
private final SecurityContextRepository repo = new HttpSessionSecurityContextRepository();

@PostMapping("/api/login")
public void login(@RequestBody LoginRequest body,
                  HttpServletRequest request, HttpServletResponse response) {

    Authentication token = UsernamePasswordAuthenticationToken
            .unauthenticated(body.username(), body.password());
    Authentication result = authenticationManager.authenticate(token);

    SecurityContext context = SecurityContextHolder.createEmptyContext();
    context.setAuthentication(result);
    SecurityContextHolder.setContext(context);
    repo.saveContext(context, request, response);
}
```

- `unauthenticated(...)` builds the "please check this" token.
- `authenticationManager.authenticate(...)` does the real check and throws if it fails.
- The next three lines build and set the context for this request.
- `repo.saveContext(...)` writes it into the HttpSession. **This is the step people forget.** Without it, the login lasts exactly one request.

## 6.4 Public pages and the `/error` page

Two gotchas that look like bugs:

- The `AuthorizationFilter` applies to **all dispatcher types** in Spring Security 6+, including the **error dispatch**. When your controller throws an exception, Tomcat forwards to `/error`, which is **also** checked. If `/error` isn't permitted, a real 500 error turns into a confusing **401 or 403**. Add `.requestMatchers("/error").permitAll()`.
- A path-matching mistake (a rule that matches more or less than you think) can leave something open. Prefer `anyRequest().authenticated()` as the last rule so that anything forgotten is **closed**, not open.

---

# Part 7: See it for yourself

## 7.1 Print the real filter list

Spring Boot logs your chain at startup (at INFO). Look for a line like this:

```
o.s.s.web.DefaultSecurityFilterChain : Will secure any request with
[DisableEncodeUrlFilter, WebAsyncManagerIntegrationFilter, SecurityContextHolderFilter,
 HeaderWriterFilter, CsrfFilter, LogoutFilter, UsernamePasswordAuthenticationFilter,
 DefaultLoginPageGeneratingFilter, DefaultLogoutPageGeneratingFilter, BasicAuthenticationFilter,
 RequestCacheAwareFilter, SecurityContextHolderAwareRequestFilter, AnonymousAuthenticationFilter,
 SessionManagementFilter, ExceptionTranslationFilter, AuthorizationFilter]
```

That's the truth for **your** version and configuration. Compare it with the table in Part 3.

## 7.2 Watch each filter run

```properties
logging.level.org.springframework.security=TRACE
```

Now make a request. You'll see lines like:

```
Securing GET /orders
Invoking DisableEncodeUrlFilter (1/16)
Invoking WebAsyncManagerIntegrationFilter (2/16)
Invoking SecurityContextHolderFilter (3/16)
...
Set SecurityContextHolder to anonymous SecurityContext
Failed to authorize ... with attributes authenticated
Sending AnonymousAuthenticationToken to authentication entry point since access is denied
```

The `(3/16)` counter shows position in the chain. Turn TRACE off afterwards, since it's very noisy.

## 7.3 Experiments with `curl` on Debian

Create a minimal Boot app with `spring-boot-starter-web` and `spring-boot-starter-security`, a simple `@GetMapping("/hello")`, and no custom config. The default user is `user`, and the password is printed in the startup log (`Using generated security password: ...`).

**1. See the entry point redirect (Request 1 above):**

```bash
curl -i http://localhost:8080/hello
```

You'll see `302` with `Location: http://localhost:8080/login`. Your controller never ran.

**2. See the 401 from Basic:**

```bash
curl -i -H "Accept: application/json" http://localhost:8080/hello
```

Depending on your version and config, the default entry point may answer `401` for non-HTML clients. Then try credentials:

```bash
curl -i -u user:PASTE_PASSWORD_HERE http://localhost:8080/hello
```

`-u` builds the `Authorization: Basic ...` header for you. You get `200`, and you've watched `BasicAuthenticationFilter` do its job.

**3. Walk through form login with curl (Requests 2 and 3):**

```bash
# 1. Get the login page and save the session cookie, extract the CSRF token
TOKEN=$(curl -s -c jar.txt http://localhost:8080/login | grep -oP 'name="_csrf"[^>]*value="\K[^"]+')
echo "$TOKEN"

# 2. Submit the login form
curl -i -b jar.txt -c jar.txt \
  -d "username=user&password=PASTE_PASSWORD_HERE&_csrf=$TOKEN" \
  http://localhost:8080/login

# 3. Use the new session
curl -i -b jar.txt http://localhost:8080/hello
```

Notes on each step:

- In step 1, `-c jar.txt` saves the cookie, and `grep -oP ... \K` pulls the token out of the HTML (if your version's HTML differs, adjust the pattern).
- In step 2, you'll see `302` and a **new** `Set-Cookie: JSESSIONID=...`. That's the session fixation protection from the sessions lesson.
- In step 3, the response is `200`. The `SecurityContextHolderFilter` loaded your identity from the session.

**4. Break the CSRF filter on purpose:**

```bash
curl -i -b jar.txt -X POST http://localhost:8080/login -d "username=user&password=x"
```

`403`, with no token. The request died at filter #6, long before login logic ran.

**5. See the firewall:**

```bash
curl -i "http://localhost:8080/hello;jsessionid=abc"
```

Rejected before any filter ran.

## 7.4 Prove the order with a logging filter

```java
public class TraceFilter extends OncePerRequestFilter {
    private final String name;
    public TraceFilter(String name) { this.name = name; }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res,
                                    FilterChain chain) throws ServletException, IOException {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        System.out.println(name + " IN  -> user = " + (a == null ? "none" : a.getName()));
        chain.doFilter(req, res);
        System.out.println(name + " OUT");
    }
}
```

```java
http
    .addFilterBefore(new TraceFilter("before-anonymous"), AnonymousAuthenticationFilter.class)
    .addFilterAfter(new TraceFilter("after-anonymous"), AnonymousAuthenticationFilter.class)
```

Call a page without logging in. You'll see `user = none` printed by the first filter and `anonymousUser` printed by the second. It's a direct demonstration of what `AnonymousAuthenticationFilter` does, and of the IN/OUT onion order.

## 7.5 Use a debugger

Put a breakpoint inside your controller and read the call stack. Under your method you'll find `DispatcherServlet`, and under that a long run of `...Filter.doFilter` frames from the chain, with `FilterChainProxy$VirtualFilterChain` calling each one in turn. It's the whole lesson in one stack trace.

---

# Common mistakes

|Mistake|Why it hurts|Fix|
|---|---|---|
|Expecting `@ControllerAdvice` to catch security errors|Security filters run before the DispatcherServlet|Use `AuthenticationEntryPoint` and `AccessDeniedHandler`|
|Chain without a matcher placed first|It matches everything, so other chains never run|Put specific chains first with lower `@Order` numbers|
|No catch-all chain or `anyRequest()` rule|Requests slip through unprotected or unmatched|End with `anyRequest().authenticated()` (or `denyAll()`)|
|Rule order wrong (`anyRequest()` before specific rules)|First match wins, so later rules are ignored|Specific rules first, general last|
|Making a security filter a Spring bean without disabling its registration|It runs twice|`new` it inside the chain, or `FilterRegistrationBean.setEnabled(false)`|
|Using `web.ignoring()` for public pages|Skips all filters, including security headers|`permitAll()`|
|Custom login endpoint that doesn't save the context|User is logged out on the next request|Call `securityContextRepository.saveContext(...)`|
|`/error` not permitted|Real errors become 401 or 403|`requestMatchers("/error").permitAll()`|
|Placing a custom auth filter before `SecurityContextHolderFilter`|Your context gets overwritten or lost|Add it after, for example before `UsernamePasswordAuthenticationFilter`|
|An auth filter that rejects instead of passing on when its credential is missing|Breaks other mechanisms (basic, bearer, form)|If your credential is absent, just call `chain.doFilter(...)`|
|Disabling CSRF on cookie-based apps|Opens the forged-request hole|Only disable it for stateless, header-token APIs|
|Reading `SecurityContextHolder` in a new thread|ThreadLocal is empty there, so the user looks anonymous|Use `DelegatingSecurityContextExecutor` or similar helpers|
|Trusting `X-Forwarded-*` or other headers for decisions|The client controls them|Only trust them from your own proxy|
|Assuming an exception in `CsrfFilter` reaches `ExceptionTranslationFilter`|It sits earlier, so it can't catch it|CSRF failures use their own access-denied handler|

---

## Related concept, briefly

**Method security is not in the filter chain.** `@PreAuthorize`, `@PostAuthorize`, and `@Secured` work through **AOP proxies** around your beans. The proxy checks the rule, using the same `SecurityContext` the filters established, right before your method body runs. So the order is: **filters** (URL-level checks) → DispatcherServlet → controller → **proxy** (method-level checks) → your service code. The two layers give you defense in depth: URL rules catch whole sections of your site, and method rules protect logic that can be reached from several places (controllers, jobs, message listeners).

---

## The whole picture

|Question|Answer|
|---|---|
|What is the filter chain?|An ordered list of single-purpose filters that every request passes before the DispatcherServlet|
|How does it connect to Tomcat?|`DelegatingFilterProxy` → `FilterChainProxy` → the matching `SecurityFilterChain`|
|Who picks the chain?|`FilterChainProxy`: the first matching `securityMatcher` wins|
|What runs before any filter?|The `HttpFirewall`|
|Who loads "who is logged in"?|`SecurityContextHolderFilter` (from the session, into a ThreadLocal)|
|Who creates a login?|The authentication filters (form, basic, bearer, remember-me, OAuth2)|
|Who checks the password or token?|`AuthenticationManager` → `ProviderManager` → providers|
|Who stops forged requests?|`CsrfFilter`|
|Who makes "not logged in" an identity?|`AnonymousAuthenticationFilter`|
|Who enforces URL rules?|`AuthorizationFilter` (throws `AccessDeniedException`)|
|Who turns exceptions into responses?|`ExceptionTranslationFilter`: entry point (login or 401) vs access-denied handler (403)|
|Where does your code join in?|`addFilterBefore/After/At`, entry points, handlers, and your own `SecurityFilterChain` beans|
|How do I see my exact chain?|The startup INFO log, and TRACE logging for per-request flow|
|Where does method security fit?|After the DispatcherServlet, through AOP proxies|




[[Spring Security]]