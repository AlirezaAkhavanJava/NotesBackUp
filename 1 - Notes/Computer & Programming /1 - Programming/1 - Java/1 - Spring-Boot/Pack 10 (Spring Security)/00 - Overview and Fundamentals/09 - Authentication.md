![[Spring Security Authentication Architecture.png]]

`Authentication` is the object Spring Security uses to represent **a person (or a machine) who is trying to log in, or who has already logged in**. It answers three questions in one place: _who are you_ (the principal), _what proof did you give_ (the credentials), and _what are you allowed to do_ (the authorities). Nearly every part of Spring Security either creates one, passes one along, or reads one.

It plays two roles, and this is the key to understanding it. **Before** login, it is a _request_: "here is a username and password, please check them." **After** login, it is a _result_: "this is Ahmed, he is trusted, and he has the USER role." The same type serves both, and a flag (`isAuthenticated()`) tells you which one you are holding. In the last lesson, `AuthenticationManager.authenticate(...)` took one in and returned one out. This lesson opens that object up.

---

## 1. The interface

```java
public interface Authentication extends Principal, Serializable {

    Collection<? extends GrantedAuthority> getAuthorities();   // what you may do
    Object getCredentials();                                    // proof (password, token)
    Object getDetails();                                        // extra info (IP, session id)
    Object getPrincipal();                                      // who you are
    boolean isAuthenticated();                                  // trusted yet?
    void setAuthenticated(boolean isAuthenticated);             // rarely used directly

    // inherited from java.security.Principal:
    // String getName();
}
```

Here is what each method returns for a user who logged in with a form and password:

|Method|Returns|Example value|
|---|---|---|
|`getPrincipal()`|The user. Usually a `UserDetails` after login, a `String` before.|`User [username=ahmed, ...]`|
|`getCredentials()`|The proof. The password before login, usually `null` after (erased).|`"1234"` then `null`|
|`getAuthorities()`|Collection of `GrantedAuthority`|`[ROLE_USER]`|
|`getDetails()`|Extra request info, set by the filter|`WebAuthenticationDetails [RemoteIpAddress=127.0.0.1, SessionId=ABC...]`|
|`isAuthenticated()`|Has it been verified?|`true`|
|`getName()`|A display name, taken from the principal|`"ahmed"`|

Because `Authentication` extends `java.security.Principal`, you can also receive it as a plain `Principal` in a controller, which gives you only `getName()`.

---

## 2. The family tree

You rarely meet `Authentication` itself. You meet one of its subclasses, and **which subclass you get depends on how the user logged in**.

```
Authentication (interface)
  └── AbstractAuthenticationToken (shared code: authorities, details, name, equals)
        ├── UsernamePasswordAuthenticationToken        form login, HTTP Basic
        ├── AnonymousAuthenticationToken               not logged in
        ├── RememberMeAuthenticationToken              "remember me" cookie
        ├── PreAuthenticatedAuthenticationToken        login done by something else (X.509, SiteMinder)
        ├── TestingAuthenticationToken                 unit tests
        ├── BearerTokenAuthenticationToken             an unverified bearer token (request side)
        ├── AbstractOAuth2TokenAuthenticationToken
        │     └── JwtAuthenticationToken               a verified JWT
        ├── OAuth2AuthenticationToken                  oauth2Login (OIDC and plain OAuth2)
        └── Saml2Authentication                        saml2Login
```

What you actually get in each login style:

|Login style|Class|`getPrincipal()`|`getCredentials()`|Typical authorities|
|---|---|---|---|---|
|Form / Basic|`UsernamePasswordAuthenticationToken`|`UserDetails`|`null` (erased)|`ROLE_USER`|
|Bearer JWT|`JwtAuthenticationToken`|`Jwt`|the token|`SCOPE_read` (or your mapped roles)|
|OIDC SSO|`OAuth2AuthenticationToken`|`OidcUser`|`""` (empty)|`OIDC_USER`, `SCOPE_openid`|
|SAML|`Saml2Authentication`|`Saml2AuthenticatedPrincipal`|the SAML response XML|your mapped authorities|
|Not logged in|`AnonymousAuthenticationToken`|`"anonymousUser"`|`""`|`ROLE_ANONYMOUS`|

So the **principal is not always the same type**. This is the most important practical fact in this lesson, and we handle it in section 4.

---

## 3. Two states, one class: how `UsernamePasswordAuthenticationToken` works

This is the token you will create and read the most. Its source shows the "request" and "result" idea clearly (simplified):

```java
public class UsernamePasswordAuthenticationToken extends AbstractAuthenticationToken {

    private final Object principal;
    private Object credentials;

    // --- Constructor 1: the REQUEST (not trusted) ---
    public UsernamePasswordAuthenticationToken(Object principal, Object credentials) {
        super(null);                       // no authorities yet
        this.principal = principal;        // the typed username (a String)
        this.credentials = credentials;    // the typed password
        setAuthenticated(false);
    }

    // --- Constructor 2: the RESULT (trusted) ---
    public UsernamePasswordAuthenticationToken(Object principal, Object credentials,
                                               Collection<? extends GrantedAuthority> authorities) {
        super(authorities);
        this.principal = principal;        // now the UserDetails object
        this.credentials = credentials;
        super.setAuthenticated(true);      // only the constructor may do this
    }

    // --- A guard: nobody can promote an untrusted token by hand ---
    @Override
    public void setAuthenticated(boolean isAuthenticated) {
        Assert.isTrue(!isAuthenticated,
            "Cannot set this token to trusted - use constructor which takes a GrantedAuthority list instead");
        super.setAuthenticated(false);
    }
}
```

Modern code uses two named factory methods, which are easier to read:

```java
// the request
Authentication request = UsernamePasswordAuthenticationToken.unauthenticated("ahmed", "1234");

// the result
Authentication result = UsernamePasswordAuthenticationToken.authenticated(
        userDetails, null, userDetails.getAuthorities());
```

Line by line:

- Constructor 1 passes `null` authorities and sets `authenticated = false`. Nobody has checked this yet.
- Constructor 2 takes the authorities, so it can safely say `authenticated = true`.
- The `setAuthenticated(true)` guard throws on purpose: **you cannot make a token trusted by flipping a flag.** The only way to get a trusted token is to build it from the constructor that carries authorities, which only code that has verified the user (a provider) should do.

The state lifecycle:

||`unauthenticated(...)`|`authenticated(...)`|
|---|---|---|
|Created by|The filter, from the form or header|The `AuthenticationProvider`, after checking the password|
|`isAuthenticated()`|`false`|`true`|
|`getPrincipal()`|`"ahmed"` (`String`)|`UserDetails`|
|`getAuthorities()`|empty|`[ROLE_USER]`|

---

## 4. Reading the principal safely

Since the principal's type changes with the login style, **never blindly cast it**.

```java
Authentication auth = SecurityContextHolder.getContext().getAuthentication();
UserDetails user = (UserDetails) auth.getPrincipal();   // ClassCastException when logged in by JWT or OIDC
```

Safer options:

### 4.1 Pattern matching (Java 21)

```java
String describe(Authentication auth) {
    return switch (auth.getPrincipal()) {
        case UserDetails u -> "Form/Basic user: " + u.getUsername();
        case OidcUser o    -> "OIDC user: " + o.getEmail();
        case OAuth2User o  -> "OAuth2 user: " + o.getName();
        case Jwt jwt       -> "JWT subject: " + jwt.getSubject();
        case String s      -> "Plain principal: " + s;          // "anonymousUser"
        default            -> "Unknown: " + auth.getPrincipal().getClass().getSimpleName();
    };
}
```

Order matters: `OidcUser` extends `OAuth2User`, so the more specific type goes first.

### 4.2 Use the annotation that matches your login style

```java
@GetMapping("/me")
String me(@AuthenticationPrincipal UserDetails user)  { return user.getUsername(); }   // form login

@GetMapping("/me")
String me(@AuthenticationPrincipal OidcUser user)     { return user.getEmail(); }      // oauth2Login

@GetMapping("/me")
String me(@AuthenticationPrincipal Jwt jwt)           { return jwt.getSubject(); }     // resource server
```

If the principal doesn't match the parameter type, `@AuthenticationPrincipal` injects `null`, which is a quiet bug. Add `errorOnInvalidType = true` to make it fail loudly:

```java
String me(@AuthenticationPrincipal(errorOnInvalidType = true) UserDetails user) { ... }
```

### 4.3 Pull one value with an expression

```java
@GetMapping("/name")
String name(@CurrentSecurityContext(expression = "authentication.name") String name) {
    return name;
}

@GetMapping("/email")
String email(@AuthenticationPrincipal(expression = "email") String email) {   // calls getEmail() on the principal
    return email;
}
```

### 4.4 Every way to get at it

|Way|Code|Good for|
|---|---|---|
|Method parameter|`Authentication auth`|Controllers, you want the whole object|
|`Principal` parameter|`Principal p`|Only the name is needed|
|Annotation|`@AuthenticationPrincipal X x`|The principal in its real type|
|Static holder|`SecurityContextHolder.getContext().getAuthentication()`|Service or utility code with no parameters|
|Injected strategy|`SecurityContextHolderStrategy` bean|Same as above, but testable and recommended in newer code|
|Servlet API|`request.getUserPrincipal()` / `request.isUserInRole("ADMIN")`|Plain servlets and filters|

---

## 5. Where it lives: `SecurityContext`

After login, the `Authentication` is stored so that later code in the same request can find it:

```
SecurityContextHolder  (a ThreadLocal by default: one per request thread)
        └── SecurityContext
                └── Authentication   ← your user
```

```java
SecurityContext context = SecurityContextHolder.getContext();
Authentication auth = context.getAuthentication();

if (auth != null && auth.isAuthenticated()) {
    log.info("User {} has {}", auth.getName(), auth.getAuthorities());
}
```

For sessions, a filter (`SecurityContextHolderFilter`) loads the context from the HTTP session at the start of each request and clears it at the end. For JWTs, the bearer filter builds a fresh one on every request, because nothing is stored.

In newer code, inject the strategy rather than using the static methods. It behaves the same but is easier to test and to swap:

```java
@Service
class AuditService {

    private final SecurityContextHolderStrategy strategy = SecurityContextHolder.getContextHolderStrategy();

    String currentUser() {
        Authentication auth = strategy.getContext().getAuthentication();
        return auth != null ? auth.getName() : "system";
    }
}
```

---

## 6. The anonymous trap

When nobody is logged in, `getAuthentication()` is **not** `null` on a normal web request. Spring Security fills in an `AnonymousAuthenticationToken`:

```java
Authentication auth = SecurityContextHolder.getContext().getAuthentication();

auth.getClass();         // AnonymousAuthenticationToken
auth.getPrincipal();     // "anonymousUser"
auth.getAuthorities();   // [ROLE_ANONYMOUS]
auth.isAuthenticated();  // true  ← surprising
```

Yes, `isAuthenticated()` is **`true`** for an anonymous user. So this check is wrong:

```java
if (auth != null && auth.isAuthenticated()) {
    // anonymous visitors get in here too!
}
```

Use the trust resolver instead:

```java
private final AuthenticationTrustResolver trustResolver = new AuthenticationTrustResolverImpl();

boolean isLoggedIn(Authentication auth) {
    return auth != null && !trustResolver.isAnonymous(auth);
}
```

Or a quick type check: `auth instanceof AnonymousAuthenticationToken`. In Thymeleaf you use `sec:authorize="isAuthenticated()"`, which already handles this correctly. Also remember that `null` can still occur outside web requests, such as scheduled jobs and message listeners, so check for it there.

---

## 7. Authorities: the "what you may do" part

`getAuthorities()` returns `GrantedAuthority` objects. Each is just a string wrapped in a small interface:

```java
public interface GrantedAuthority extends Serializable {
    String getAuthority();     // "ROLE_ADMIN", "READ_REPORTS", "SCOPE_openid"
}
```

```java
auth.getAuthorities().forEach(a -> System.out.println(a.getAuthority()));
// ROLE_USER
// ROLE_ADMIN
```

The default implementation is `SimpleGrantedAuthority`. Roles and permissions are both stored as authorities, and the **only** difference is the `ROLE_` prefix:

|You write|Spring checks for the authority|
|---|---|
|`hasRole("ADMIN")`|`ROLE_ADMIN`|
|`hasAuthority("ROLE_ADMIN")`|`ROLE_ADMIN` (same thing)|
|`hasAuthority("REPORT_READ")`|`REPORT_READ`|
|`hasAnyRole("ADMIN", "MANAGER")`|`ROLE_ADMIN` or `ROLE_MANAGER`|

```java
// checking by hand
boolean isAdmin = auth.getAuthorities().stream()
        .map(GrantedAuthority::getAuthority)
        .anyMatch("ROLE_ADMIN"::equals);
```

The authorities in an `Authentication` are **fixed at login**. If an admin removes a role from the user in the database, the existing session or token keeps the old authorities until it expires or the user logs in again. Plan for that (short token lifetimes, or reload the user for sensitive operations).

---

## 8. `getDetails()`: the extra baggage

`details` holds information about the **request**, not the user. For web logins it is a `WebAuthenticationDetails`:

```java
WebAuthenticationDetails details = (WebAuthenticationDetails) auth.getDetails();
String ip = details.getRemoteAddress();
String sessionId = details.getSessionId();
```

A filter such as `UsernamePasswordAuthenticationFilter` fills it in through an `AuthenticationDetailsSource`. You can replace that source to attach your own data, for example a tenant header:

```java
public class TenantAuthenticationDetails extends WebAuthenticationDetails {

    private final String tenant;

    public TenantAuthenticationDetails(HttpServletRequest request) {
        super(request);
        this.tenant = request.getHeader("X-Tenant");
    }

    public String getTenant() { return tenant; }
}

@Component
class TenantDetailsSource implements AuthenticationDetailsSource<HttpServletRequest, TenantAuthenticationDetails> {
    @Override
    public TenantAuthenticationDetails buildDetails(HttpServletRequest request) {
        return new TenantAuthenticationDetails(request);
    }
}
```

```java
http.formLogin(form -> form.authenticationDetailsSource(tenantDetailsSource));
```

Then, in a custom `AuthenticationProvider`, `((TenantAuthenticationDetails) authentication.getDetails()).getTenant()` is available during the password check. The manager also copies the details from the request token onto the result (that was the `copyDetails` call in the last lesson).

---

## 9. Putting your own data on the principal

Often you want the database id of the user available everywhere, without a lookup on each request. The principal can be **your own class**:

```java
public class AppUser extends User {          // org.springframework.security.core.userdetails.User

    private final Long id;
    private final String displayName;

    public AppUser(Long id, String username, String passwordHash, String displayName,
                   Collection<? extends GrantedAuthority> authorities) {
        super(username, passwordHash, authorities);
        this.id = id;
        this.displayName = displayName;
    }

    public Long getId() { return id; }
    public String getDisplayName() { return displayName; }
}
```

```java
@Service
class DbUserDetailsService implements UserDetailsService {

    private final AppUserRepository repo;

    DbUserDetailsService(AppUserRepository repo) { this.repo = repo; }

    @Override
    public UserDetails loadUserByUsername(String username) {
        UserEntity e = repo.findByUsername(username)
            .orElseThrow(() -> new UsernameNotFoundException(username));

        return new AppUser(e.getId(), e.getUsername(), e.getPasswordHash(), e.getDisplayName(),
                List.of(new SimpleGrantedAuthority("ROLE_" + e.getRole())));
    }
}
```

```java
@GetMapping("/orders")
List<Order> myOrders(@AuthenticationPrincipal AppUser user) {
    return orderService.findByUserId(user.getId());
}
```

After login, `authentication.getPrincipal()` **is** your `AppUser`, because `DaoAuthenticationProvider` puts whatever `UserDetails` you returned into the result. This works for password login. With JWT login the principal is the `Jwt`, so there you read `jwt.getClaim("userId")` instead (or write a custom converter that builds your own principal).

---

## 10. Creating and setting an `Authentication` yourself

You need this for background jobs, tests, and custom login endpoints.

```java
@Component
class NightlyJob {

    @Scheduled(cron = "0 0 2 * * *")
    void run() {
        Authentication systemAuth = UsernamePasswordAuthenticationToken.authenticated(
                "system", null, List.of(new SimpleGrantedAuthority("ROLE_SYSTEM")));

        SecurityContext context = SecurityContextHolder.createEmptyContext();   // new, never reuse the shared one
        context.setAuthentication(systemAuth);
        SecurityContextHolder.setContext(context);
        try {
            reportService.generateAll();          // @PreAuthorize("hasRole('SYSTEM')") passes now
        } finally {
            SecurityContextHolder.clearContext(); // always clean up the thread
        }
    }
}
```

- `createEmptyContext()` : avoids changing a context other code might be using.
- `authenticated(...)` : a trusted token, built with its authorities.
- `finally { clearContext(); }` : server threads are reused. If you leave the context behind, the next request on that thread inherits it, which is a serious security bug.

### 10.1 Threads: the context does not follow you automatically

The holder uses a `ThreadLocal`, so **work on another thread sees no user**:

```java
@Async
void sendReport() {
    SecurityContextHolder.getContext().getAuthentication();   // null or anonymous in the new thread
}
```

Fix it by wrapping the executor so the context is copied across:

```java
@Bean
Executor taskExecutor() {
    ThreadPoolTaskExecutor delegate = new ThreadPoolTaskExecutor();
    delegate.setCorePoolSize(4);
    delegate.initialize();
    return new DelegatingSecurityContextAsyncTaskExecutor(delegate);
}
```

For a one-off, `new DelegatingSecurityContextRunnable(task)` or `DelegatingSecurityContextExecutorService` do the same. The alternative `SecurityContextHolder.setStrategyName(MODE_INHERITABLETHREADLOCAL)` copies the context to child threads, but not to pooled threads, so the wrapping approach is the reliable one.

---

## 11. Credentials erasure

`AbstractAuthenticationToken` implements `CredentialsContainer`, which has `eraseCredentials()`. After a successful login the `ProviderManager` calls it, so the raw password doesn't stay in memory or in the session:

```java
Authentication result = manager.authenticate(request);
result.getCredentials();     // null: erased
```

For the user object itself, `User.eraseCredentials()` clears the stored password hash. This also means you **cannot** re-verify the password later from the `Authentication`. If you need that (for example "confirm your password to delete the account"), ask for it again and call the manager again.

---

## 12. Testing with a fake `Authentication`

```java
@WebMvcTest(ReportController.class)
class ReportControllerTest {

    @Autowired MockMvc mvc;

    // 1. the shortcut annotation: Spring builds a UsernamePasswordAuthenticationToken for you
    @Test
    @WithMockUser(username = "ahmed", roles = "USER")
    void userCanReadOwnReport() throws Exception {
        mvc.perform(get("/reports/mine")).andExpect(status().isOk());
    }

    // 2. build the object yourself and plug it in
    @Test
    void adminCanSeeAll() throws Exception {
        Authentication admin = UsernamePasswordAuthenticationToken.authenticated(
                "boss", null, List.of(new SimpleGrantedAuthority("ROLE_ADMIN")));

        mvc.perform(get("/reports/all").with(SecurityMockMvcRequestPostProcessors.authentication(admin)))
           .andExpect(status().isOk());
    }

    // 3. a lightweight token meant for tests
    @Test
    void usingTestingToken() {
        var token = new TestingAuthenticationToken("ahmed", "pw", "ROLE_USER");
        assertThat(token.isAuthenticated()).isTrue();   // TestingAuthenticationToken is created trusted when given authorities
    }
}
```

With `@WithMockUser`, the principal is a `User` object, not your `AppUser`. If your controller uses `@AuthenticationPrincipal AppUser`, use `@WithUserDetails("ahmed")` (loads through your real `UserDetailsService`) or the `authentication(...)` post-processor with your own principal.

---

## 13. Common mistakes

|Mistake|What happens|Fix|
|---|---|---|
|`(UserDetails) auth.getPrincipal()` everywhere|`ClassCastException` for JWT / OIDC logins|Pattern matching or the correct `@AuthenticationPrincipal` type|
|`auth.isAuthenticated()` to mean "logged in"|Anonymous users pass|`AuthenticationTrustResolver` or an `instanceof AnonymousAuthenticationToken` check|
|Calling `auth.setAuthenticated(true)` on a request token|`IllegalArgumentException`|Build a new token with authorities via `authenticated(...)`|
|Reading the password from `getCredentials()` after login|`null`|It was erased. Re-prompt and re-authenticate.|
|Using the context in `@Async` or a new thread|No user there|Wrap the executor with the `DelegatingSecurityContext...` classes|
|Not clearing the context in manual code|The next request on that thread runs as your user|`try/finally` with `clearContext()`|
|Assuming roles update live|Old roles stay until re-login or token expiry|Short lifetimes, or reload for sensitive actions|
|Putting large objects in the principal|Big sessions, slow serialization (`Authentication` is `Serializable`)|Keep the principal small: id, username, a few fields|
|`@AuthenticationPrincipal` gives `null`|Principal type didn't match|Use `errorOnInvalidType = true` and check the login style|

---

## Related concepts, in short

- **`Principal`:** the plain Java interface (`getName()`) that `Authentication` extends. It only knows a name.
- **`UserDetails`:** Spring Security's description of a user (username, password hash, authorities, enabled/locked flags). It is the usual _content_ of the principal.
- **`GrantedAuthority`:** one permission or role string. A user has many.
- **`SecurityContext`:** a tiny holder around one `Authentication`. `SecurityContextHolder` finds it for the current thread.
- **`AuthenticationManager`:** the service that turns an unauthenticated `Authentication` into an authenticated one (last lesson).

## What to practice next

1. Log in with form login, then print `auth.getClass()`, `getPrincipal().getClass()`, `getAuthorities()`, and `getDetails()` in a controller. Repeat with JWT and with `oauth2Login` and compare using the table in section 2.
2. Hit a public page and print `isAuthenticated()` for the anonymous user to see the surprise yourself.
3. Build the `AppUser` principal from section 9 and read its id with `@AuthenticationPrincipal`.
4. Write a `@Scheduled` job that sets its own `Authentication` (section 10) and calls a `@PreAuthorize` method.
5. Add a custom `AuthenticationDetailsSource` and read the tenant header in a provider.




[[Spring Security]]