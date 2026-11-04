![[JWT Authentication and Spring Security Flow.png]]

# `AuthenticationManager` and `AuthenticationConfiguration`

This is the line from the JWT lab:

```java
@Bean
AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
    return config.getAuthenticationManager();
}
```

It looks tiny, but it connects the whole "check the password" side of Spring Security to your own code. An **`AuthenticationManager`** is the object that answers one question: "are these credentials valid?" You hand it a username and password, and it either returns a fully authenticated user or throws an exception. **`AuthenticationConfiguration`** is the Spring Security class that already **builds** that manager for you, from the `UserDetailsService` and `PasswordEncoder` beans you declared. Your `@Bean` method just takes the manager out of that configuration and makes it injectable, so a controller like `/auth/login` can call it.

In this lesson we start from the one-method interface, follow a real `authenticate(...)` call down to the password comparison, then see how `AuthenticationConfiguration` assembles the manager, and finally look at your alternatives and the errors you will hit.

---

## 1. The interface is one method

```java
public interface AuthenticationManager {
    Authentication authenticate(Authentication authentication) throws AuthenticationException;
}
```

That's all of it. Three things to notice:

- It takes an `Authentication` object **in** and gives an `Authentication` object **out**.
- The one you pass in is **unauthenticated** (it holds only what the user typed).
- The one you get back is **authenticated** (it holds the user, their authorities, and `isAuthenticated() == true`).

```java
// BEFORE: what the user typed
Authentication request = UsernamePasswordAuthenticationToken.unauthenticated("ahmed", "1234");
request.isAuthenticated();     // false
request.getPrincipal();        // "ahmed"  (a String)
request.getCredentials();      // "1234"

// AFTER: what the manager returns
Authentication result = authenticationManager.authenticate(request);
result.isAuthenticated();      // true
result.getPrincipal();         // UserDetails object for ahmed
result.getCredentials();       // null  (erased for safety)
result.getAuthorities();       // [ROLE_USER]
```

||Before `authenticate`|After `authenticate`|
|---|---|---|
|`isAuthenticated()`|`false`|`true`|
|`getPrincipal()`|the username `String`|the `UserDetails`|
|`getCredentials()`|the raw password|`null` (erased)|
|`getAuthorities()`|empty|the user's roles|

The three outcomes are:

|Outcome|Meaning|
|---|---|
|Returns an `Authentication`|Success|
|Throws `AuthenticationException`|Failure (wrong password, locked account, and so on)|
|Returns `null`|"I can't decide this type of request" (only providers return this)|

---

## 2. Who really does the work: `ProviderManager` and its providers

`AuthenticationManager` is only the contract. The implementation you almost always get is **`ProviderManager`**, which holds a **list of `AuthenticationProvider`s** and asks each one in turn.

```java
public interface AuthenticationProvider {
    Authentication authenticate(Authentication authentication) throws AuthenticationException;
    boolean supports(Class<?> authentication);
}
```

```
authenticationManager.authenticate(token)
        |
   ProviderManager
        |-- DaoAuthenticationProvider        supports UsernamePasswordAuthenticationToken
        |-- JwtAuthenticationProvider        supports BearerTokenAuthenticationToken
        |-- MyApiKeyAuthenticationProvider   supports ApiKeyAuthenticationToken
        '-- parent (another AuthenticationManager)   fallback if nobody handled it
```

Here is a simplified version of `ProviderManager.authenticate`:

```java
public Authentication authenticate(Authentication authentication) throws AuthenticationException {
    Class<? extends Authentication> toTest = authentication.getClass();
    AuthenticationException lastException = null;
    Authentication result = null;

    for (AuthenticationProvider provider : getProviders()) {
        if (!provider.supports(toTest)) {
            continue;                                   // not my kind of token, skip
        }
        try {
            result = provider.authenticate(authentication);
            if (result != null) {
                copyDetails(authentication, result);    // keep IP / session id info
                break;                                  // first success wins
            }
        } catch (AccountStatusException | InternalAuthenticationServiceException e) {
            throw e;                                    // locked/disabled: stop right away
        } catch (AuthenticationException e) {
            lastException = e;                          // wrong password: remember it, try next provider
        }
    }

    if (result == null && parent != null) {
        result = parent.authenticate(authentication);   // ask the parent manager
    }

    if (result != null) {
        if (eraseCredentialsAfterAuthentication && result instanceof CredentialsContainer c) {
            c.eraseCredentials();                       // wipe the password from the result
        }
        eventPublisher.publishAuthenticationSuccess(result);
        return result;
    }

    if (lastException == null) {
        lastException = new ProviderNotFoundException("No AuthenticationProvider found for " + toTest.getName());
    }
    eventPublisher.publishAuthenticationFailure(lastException, authentication);
    throw lastException;
}
```

Walkthrough:

- `supports(toTest)` : a provider announces which `Authentication` class it understands. This is how one manager can handle passwords, JWTs, and API keys without mixing them up.
- **First success wins.** A normal "bad password" is remembered and the next provider is tried. A **locked or disabled account** (`AccountStatusException`) stops the loop immediately, because trying other providers wouldn't make sense.
- `parent` : if no provider here succeeded, the parent manager gets a turn. This is how your global manager sits behind each filter chain's local one (section 4).
- `eraseCredentials` : the password is removed from the returned object, which is why `getCredentials()` is `null` afterwards.
- Success and failure **events** are published, so you can listen with `@EventListener` for login auditing.

---

## 3. The provider you use every day: `DaoAuthenticationProvider`

When you declare a `UserDetailsService` and a `PasswordEncoder`, this is the provider Spring builds. It is the one that actually checks the password.

```java
// Simplified from AbstractUserDetailsAuthenticationProvider + DaoAuthenticationProvider
public Authentication authenticate(Authentication authentication) {
    String username = authentication.getName();

    // 1. Load the user
    UserDetails user;
    try {
        user = userDetailsService.loadUserByUsername(username);
    } catch (UsernameNotFoundException ex) {
        if (hideUserNotFoundExceptions) {
            throw new BadCredentialsException("Bad credentials");   // do not reveal "no such user"
        }
        throw ex;
    }

    // 2. Pre-checks: is the account usable at all?
    //    locked -> LockedException, disabled -> DisabledException, expired -> AccountExpiredException
    preAuthenticationChecks.check(user);

    // 3. Compare the password
    String raw = authentication.getCredentials().toString();
    if (!passwordEncoder.matches(raw, user.getPassword())) {
        throw new BadCredentialsException("Bad credentials");
    }

    // 4. Post-check: is the password expired?
    postAuthenticationChecks.check(user);          // CredentialsExpiredException

    // 5. Build the success result
    return UsernamePasswordAuthenticationToken.authenticated(user, authentication.getCredentials(), user.getAuthorities());
}
```

|Step|Code|Fails with|
|---|---|---|
|Load|`loadUserByUsername`|`UsernameNotFoundException` (hidden as `BadCredentialsException`)|
|Pre-check|`isAccountNonLocked()`, `isEnabled()`, `isAccountNonExpired()`|`LockedException`, `DisabledException`, `AccountExpiredException`|
|Password|`passwordEncoder.matches(raw, stored)`|`BadCredentialsException`|
|Post-check|`isCredentialsNonExpired()`|`CredentialsExpiredException`|

Two details worth knowing:

- **Why the user-not-found exception is hidden:** if "no such user" and "wrong password" gave different messages, an attacker could discover which usernames exist.
- **`passwordEncoder.matches(raw, stored)`** : never compare strings with `equals`. BCrypt stores a random salt inside the hash, so you must let the encoder do the comparison. Also, `DaoAuthenticationProvider` quietly runs a dummy hash when the user isn't found, so timing doesn't leak whether the user exists.

A matching minimal setup:

```java
@Bean
PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
}

@Bean
UserDetailsService userDetailsService(PasswordEncoder encoder) {
    return new InMemoryUserDetailsManager(
        User.withUsername("ahmed").password(encoder.encode("1234")).roles("USER").build());
}
```

And a database-backed one for a PostgreSQL project:

```java
@Service
class DbUserDetailsService implements UserDetailsService {

    private final AppUserRepository users;

    DbUserDetailsService(AppUserRepository users) {
        this.users = users;
    }

    @Override
    public UserDetails loadUserByUsername(String username) {
        AppUser u = users.findByUsername(username)
            .orElseThrow(() -> new UsernameNotFoundException("No user " + username));

        return User.withUsername(u.getUsername())
            .password(u.getPasswordHash())          // the BCrypt hash from the column
            .roles(u.getRole())
            .disabled(!u.isActive())
            .build();
    }
}
```

---

## 4. What `AuthenticationConfiguration` does for you

`AuthenticationConfiguration` is a normal `@Configuration` class that is imported when you use `@EnableWebSecurity`. Its job is to **assemble the global `AuthenticationManager` from the beans it finds in your application**.

The rules, in plain steps:

1. If you declared an **`AuthenticationProvider` bean**, use it.
2. Otherwise, if there is exactly **one `UserDetailsService` bean**, build a `DaoAuthenticationProvider` from it. If a `PasswordEncoder` bean exists, plug that in too.
3. Put the result into a `ProviderManager`.

|Beans you declared|Manager Spring builds|
|---|---|
|`UserDetailsService` + `PasswordEncoder`|`ProviderManager` with a `DaoAuthenticationProvider`|
|Only `UserDetailsService`|Same, with the default delegating encoder (passwords need a prefix like `{bcrypt}`)|
|An `AuthenticationProvider` bean|`ProviderManager` with that provider|
|An `AuthenticationProvider` **and** a `UserDetailsService`|The provider wins, and a warning says the `UserDetailsService` is ignored|
|Two or more `UserDetailsService` beans, nothing else|Nothing is built automatically|

When you call `config.getAuthenticationManager()` you receive that assembled manager.

### 4.1 Why you have to expose it yourself

The manager lives **inside** `AuthenticationConfiguration`; it is **not** a bean by itself. If a controller asks for it:

```java
AuthController(AuthenticationManager authenticationManager) { ... }
```

Spring answers:

```
Parameter 0 of constructor in AuthController required a bean of type
'org.springframework.security.authentication.AuthenticationManager' that could not be found.
```

Your `@Bean` method is the bridge:

```java
@Bean
AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
    return config.getAuthenticationManager();
}
```

- Spring injects the `AuthenticationConfiguration` parameter.
- `getAuthenticationManager()` returns the assembled `ProviderManager` (the first call builds it, later calls return the same one).
- Returning it from a `@Bean` method registers it, so any class can now inject it.

### 4.2 A side effect: Boot's default user switches off

Spring Boot normally creates a user named `user` with a random password printed in the log. It does this **only if no `AuthenticationManager`, `AuthenticationProvider`, or `UserDetailsService` bean exists** (and a few more such types). Declaring your own removes that default, which is what you want.

### 4.3 Local vs global managers

Each `SecurityFilterChain` gets its own **local** manager built from `HttpSecurity`, and the global one from `AuthenticationConfiguration` is its **parent**. That is the `parent` field you saw in `ProviderManager`.

```
Filter chain A (/api/**)    local manager: [JwtAuthenticationProvider]           -> parent: global
Filter chain B (website)    local manager: [] (uses parent)                      -> parent: global
Global (AuthenticationConfiguration):  [DaoAuthenticationProvider]
```

This explains something from the JWT lab: the **bearer token filter** uses a **separate** manager that contains `JwtAuthenticationProvider`, while the **`/auth/login` endpoint** uses the **global password manager**. They never mix.

---

## 5. Using the manager in code

### 5.1 Stateless login (the JWT lab)

```java
@PostMapping("/login")
TokenResponse login(@RequestBody LoginRequest req) {
    Authentication auth = authenticationManager.authenticate(
        UsernamePasswordAuthenticationToken.unauthenticated(req.username(), req.password()));

    return new TokenResponse(tokenService.createAccessToken(auth), "Bearer", 900);
}
```

If the password is wrong, `authenticate` throws `BadCredentialsException`. You should turn that into a 401 instead of a 500:

```java
@RestControllerAdvice
class AuthExceptionHandler {

    @ExceptionHandler(BadCredentialsException.class)
    ResponseEntity<Map<String, String>> badCredentials() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Invalid username or password"));
    }

    @ExceptionHandler({DisabledException.class, LockedException.class})
    ResponseEntity<Map<String, String>> blocked(AuthenticationException e) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Account unavailable"));
    }
}
```

### 5.2 Session login (you must save the result yourself)

If you want a normal cookie session instead of a token, a successful `authenticate` is **not enough**. The returned object must be placed in the `SecurityContext` and saved:

```java
private final SecurityContextRepository contextRepository = new HttpSessionSecurityContextRepository();

@PostMapping("/session-login")
void login(@RequestBody LoginRequest req, HttpServletRequest request, HttpServletResponse response) {
    Authentication auth = authenticationManager.authenticate(
        UsernamePasswordAuthenticationToken.unauthenticated(req.username(), req.password()));

    SecurityContext context = SecurityContextHolder.createEmptyContext();   // new, not the shared one
    context.setAuthentication(auth);
    SecurityContextHolder.setContext(context);
    contextRepository.saveContext(context, request, response);              // writes it into the HTTP session
}
```

The last line is required in Spring Security 6 and later, because the framework no longer saves the context automatically. Forgetting it is a classic "login worked but the next request is anonymous" bug.

### 5.3 Where Spring itself calls the manager

You usually don't call it, because the built-in filters do:

|Filter|Triggered by|Calls the manager with|
|---|---|---|
|`UsernamePasswordAuthenticationFilter`|`formLogin()` POST `/login`|`UsernamePasswordAuthenticationToken`|
|`BasicAuthenticationFilter`|`httpBasic()` header|`UsernamePasswordAuthenticationToken`|
|`BearerTokenAuthenticationFilter`|`oauth2ResourceServer()`|`BearerTokenAuthenticationToken`|
|`OAuth2LoginAuthenticationFilter`|`oauth2Login()` callback|`OAuth2LoginAuthenticationToken`|

Same manager contract, different token type, and a different provider picks it up. That's the design.

---

## 6. Your options for providing the manager

### Option A: from `AuthenticationConfiguration` (what we did)

Best when you have one user store and just need to inject the manager.

### Option B: build your own `ProviderManager`

Best when you want full control and explicit wiring, and no hidden auto-assembly:

```java
@Bean
AuthenticationManager authenticationManager(UserDetailsService userDetailsService, PasswordEncoder passwordEncoder) {
    DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
    provider.setUserDetailsService(userDetailsService);
    provider.setPasswordEncoder(passwordEncoder);
    return new ProviderManager(provider);
}
```

Newer Spring Security versions also offer a `DaoAuthenticationProvider` constructor that takes the `UserDetailsService` directly, so check which one your version prefers. Because you declared a manager bean, Spring Boot's default user is switched off, and the `AuthenticationConfiguration` does **not** use your `UserDetailsService` for the global manager. You are in full control.

### Option C: the manager from `HttpSecurity` (a local manager)

Best when one filter chain needs different providers:

```java
@Bean
SecurityFilterChain apiChain(HttpSecurity http) throws Exception {
    AuthenticationManagerBuilder builder = http.getSharedObject(AuthenticationManagerBuilder.class);
    builder.authenticationProvider(new ApiKeyAuthenticationProvider());

    http.authenticationManager(builder.build())
        .securityMatcher("/api/**")
        .authorizeHttpRequests(a -> a.anyRequest().authenticated());
    return http.build();
}
```

Or, more directly, give the chain its own manager:

```java
http.authenticationManager(new ProviderManager(new ApiKeyAuthenticationProvider()));
```

### Old style that no longer exists

Tutorials from before Spring Security 5.7 do this, and it **no longer compiles** in current versions:

```java
// REMOVED: WebSecurityConfigurerAdapter is gone
@Override
protected void configure(AuthenticationManagerBuilder auth) throws Exception {
    auth.userDetailsService(uds).passwordEncoder(encoder);
}

@Override @Bean
public AuthenticationManager authenticationManagerBean() throws Exception {
    return super.authenticationManagerBean();
}
```

The `AuthenticationConfiguration` bean method from this lesson is the modern replacement.

---

## 7. Writing your own `AuthenticationProvider`

Here is a real example: an API-key login for machine clients, using a custom token type.

```java
// 1. The token type: the same class is used before and after authentication
public class ApiKeyAuthenticationToken extends AbstractAuthenticationToken {

    private final String apiKey;
    private final Object principal;

    // unauthenticated: only the key
    public ApiKeyAuthenticationToken(String apiKey) {
        super(null);
        this.apiKey = apiKey;
        this.principal = null;
        setAuthenticated(false);
    }

    // authenticated: principal and authorities
    public ApiKeyAuthenticationToken(Object principal, Collection<? extends GrantedAuthority> authorities) {
        super(authorities);
        this.apiKey = null;
        this.principal = principal;
        setAuthenticated(true);
    }

    @Override public Object getCredentials() { return apiKey; }
    @Override public Object getPrincipal()   { return principal; }
}
```

```java
// 2. The provider: decides if the key is valid
@Component
public class ApiKeyAuthenticationProvider implements AuthenticationProvider {

    private final ApiClientRepository clients;

    public ApiKeyAuthenticationProvider(ApiClientRepository clients) {
        this.clients = clients;
    }

    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        String key = (String) authentication.getCredentials();

        ApiClient client = clients.findByKeyHash(sha256(key))
            .orElseThrow(() -> new BadCredentialsException("Invalid API key"));

        if (!client.isActive()) {
            throw new DisabledException("API client disabled");
        }

        return new ApiKeyAuthenticationToken(client.getName(),
            List.of(new SimpleGrantedAuthority("ROLE_" + client.getRole())));
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return ApiKeyAuthenticationToken.class.isAssignableFrom(authentication);
    }
}
```

```java
// 3. The filter: reads the header and calls the manager
public class ApiKeyAuthenticationFilter extends OncePerRequestFilter {

    private final AuthenticationManager authenticationManager;

    public ApiKeyAuthenticationFilter(AuthenticationManager authenticationManager) {
        this.authenticationManager = authenticationManager;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {

        String key = request.getHeader("X-API-Key");
        if (key != null) {
            try {
                Authentication result = authenticationManager.authenticate(new ApiKeyAuthenticationToken(key));
                SecurityContext context = SecurityContextHolder.createEmptyContext();
                context.setAuthentication(result);
                SecurityContextHolder.setContext(context);
            } catch (AuthenticationException e) {
                SecurityContextHolder.clearContext();
                response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Invalid API key");
                return;
            }
        }
        chain.doFilter(request, response);
    }
}
```

```java
// 4. Wire it together
@Bean
AuthenticationManager authenticationManager(ApiKeyAuthenticationProvider apiKeyProvider,
                                            DaoAuthenticationProvider daoProvider) {
    return new ProviderManager(daoProvider, apiKeyProvider);       // two providers, one manager
}

@Bean
SecurityFilterChain chain(HttpSecurity http, AuthenticationManager manager) throws Exception {
    http
        .addFilterBefore(new ApiKeyAuthenticationFilter(manager), UsernamePasswordAuthenticationFilter.class)
        .authorizeHttpRequests(a -> a.anyRequest().authenticated());
    return http.build();
}
```

The manager sends a password token to the DAO provider and an API-key token to the API-key provider. Both go through `supports(...)`, which is the whole point of that method.

---

## 8. Testing it

```java
@SpringBootTest
class AuthenticationManagerTest {

    @Autowired AuthenticationManager manager;

    @Test
    void validCredentialsAuthenticate() {
        Authentication result = manager.authenticate(
            UsernamePasswordAuthenticationToken.unauthenticated("ahmed", "1234"));

        assertThat(result.isAuthenticated()).isTrue();
        assertThat(result.getAuthorities()).extracting(GrantedAuthority::getAuthority).contains("ROLE_USER");
        assertThat(result.getCredentials()).isNull();               // erased
    }

    @Test
    void wrongPasswordThrows() {
        assertThatThrownBy(() -> manager.authenticate(
                UsernamePasswordAuthenticationToken.unauthenticated("ahmed", "wrong")))
            .isInstanceOf(BadCredentialsException.class);
    }

    @Test
    void unknownUserLooksLikeBadCredentials() {
        assertThatThrownBy(() -> manager.authenticate(
                UsernamePasswordAuthenticationToken.unauthenticated("nobody", "x")))
            .isInstanceOf(BadCredentialsException.class);           // not UsernameNotFoundException
    }
}
```

For a unit test of one provider, skip Spring and call it directly:

```java
var provider = new ApiKeyAuthenticationProvider(fakeRepo);
Authentication result = provider.authenticate(new ApiKeyAuthenticationToken("good-key"));
```

---

## 9. Errors you will meet, and the fix

|Message|Cause|Fix|
|---|---|---|
|`required a bean of type ...AuthenticationManager`|The manager isn't a bean|Add the `@Bean` method from this lesson|
|`ProviderNotFoundException: No AuthenticationProvider found for ...`|No provider `supports` that token type|Register the right provider, or check `supports(...)`|
|`BadCredentialsException` with the right password|Stored password is plain text, or hashed with a different encoder|Store `encoder.encode(...)` output. For tests only: `{noop}1234`|
|`There is no PasswordEncoder mapped for the id "null"`|Stored password has no `{id}` prefix and you didn't declare a `PasswordEncoder` bean|Declare `PasswordEncoder` as a bean, or store `{bcrypt}$2a$...`|
|Log: `Global AuthenticationManager configured with an AuthenticationProvider bean. UserDetailsService beans will not be used`|You have both|Remove one, or wire the provider with the `UserDetailsService` yourself|
|Login passes, next request is anonymous|The result wasn't saved to the context|Section 5.2|
|`BeanCurrentlyInCreationException` / circular reference|The manager bean depends on a bean that needs the manager (often a `UserDetailsService` that injects it)|Don't inject the manager into the `UserDetailsService`. Break the cycle with `@Lazy` if you must|
|`InternalAuthenticationServiceException`|Your `loadUserByUsername` threw something that is not an `AuthenticationException` (for example a database error or `NullPointerException`)|Fix the underlying exception. It is deliberately not treated as "bad credentials"|

To watch the manager work, turn on:

```yaml
logging:
  level:
    org.springframework.security.authentication: TRACE
    org.springframework.security.web.authentication: TRACE
```

---

## Related concepts, in short

- **`Authentication`:** the object that carries "who" (principal), "proof" (credentials), and "what they may do" (authorities). It is both the input and output of the manager.
- **`SecurityContext` / `SecurityContextHolder`:** where the authenticated `Authentication` is kept for the current request (a `ThreadLocal`). The manager creates it, but it doesn't store it.
- **`UserDetailsService`:** the user lookup that `DaoAuthenticationProvider` calls. One method: `loadUserByUsername`.
- **`PasswordEncoder`:** hashes and compares passwords. BCrypt is the usual choice. `DelegatingPasswordEncoder` reads the `{bcrypt}` style prefix to support several algorithms.
- **`AuthenticationManagerResolver`:** picks a manager per request (for example per tenant or per URL). Used in multi-tenant resource servers.

## What to practice next

1. Run the JWT lab and put a breakpoint in `ProviderManager.authenticate`. Step into `DaoAuthenticationProvider` and watch `passwordEncoder.matches`.
2. Replace the in-memory users with `DbUserDetailsService` and a PostgreSQL table.
3. Swap Option A for Option B (your own `ProviderManager` bean) and see what changes in the startup log.
4. Add the API-key provider from section 7 and call an endpoint with `X-API-Key`.
5. Add an `@EventListener` for `AuthenticationFailureBadCredentialsEvent` and count failed logins per user, which is the start of a lockout feature.






[[Spring Security]]