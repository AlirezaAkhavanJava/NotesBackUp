

## The problem it solves

Every request needs an answer to "who is this?" But identity comes in many forms: a password, a token, an API key, a certificate, a "Sign in with Google" login. Spring Security needs **one way to ask the question** that works for all of them, and **one object to carry the answer**.

That's the authentication system. It has three jobs:

1. **Collect** whatever the client presented (password, token, key).
2. **Verify** it, using the right checker for that kind of credential.
3. **Record** the result so the rest of the app can ask "who is logged in?"

## The picture: a front desk with an ID check

|Front desk|Spring Security|
|---|---|
|You hand over your ID|The filter wraps your credential in an **unauthenticated `Authentication`**|
|The receptionist doesn't verify IDs personally|The **`AuthenticationManager`** only delegates|
|Different verifiers for passports, staff cards, visitor codes|**`AuthenticationProvider`s**, one per credential type|
|The staff directory the verifier looks you up in|**`UserDetailsService`**|
|Comparing your signature to the one on file|**`PasswordEncoder`**|
|You get a wristband that says who you are|An **authenticated `Authentication`** in the `SecurityContext`|
|You're turned away|An **`AuthenticationException`**|

## The map

```
Part 1:  The Authentication object      (what carries the answer)
Part 2:  Manager and providers          (who does the checking)
Part 3:  Users: UserDetails and UserDetailsService
Part 4:  Passwords and PasswordEncoder
Part 5:  A full PostgreSQL-backed login (JPA)
Part 6:  Writing your own provider      (API key example)
Part 7:  Results, events, and lockout
Part 8:  Logging in from your own code
Part 9:  Levels of "logged in"
Part 10: Security practices
Part 11: Testing
```

---

# Part 1: The `Authentication` object

This one object appears everywhere in Spring Security. It's used **twice** in a login, in two different states.

```java
public interface Authentication extends Principal {
    Object getPrincipal();                              // WHO
    Object getCredentials();                            // PROOF
    Collection<? extends GrantedAuthority> getAuthorities();  // WHAT THEY MAY DO
    Object getDetails();                                // EXTRA INFO
    boolean isAuthenticated();                          // verified yet?
}
```

|Method|Meaning|
|---|---|
|`getPrincipal()`|The identity. Before login: the typed username. After login: the **`UserDetails` object**.|
|`getCredentials()`|The proof, such as the password or the token. **Erased after login.**|
|`getAuthorities()`|Permissions such as `ROLE_ADMIN` or `orders:read`|
|`getDetails()`|Extra request info. For web logins, a `WebAuthenticationDetails` with the **remote IP and session ID**.|
|`isAuthenticated()`|`false` = "please check this", `true` = "already checked"|
|`getName()`|Convenience: the username|

## The two states

For a form login, here is the same object type before and after:

|Field|**Before** (what the filter builds)|**After** (what the provider returns)|
|---|---|---|
|Class|`UsernamePasswordAuthenticationToken`|`UsernamePasswordAuthenticationToken`|
|principal|`"alice"` (a String)|The `UserDetails` object for alice|
|credentials|`"secret"`|`null` (erased)|
|authorities|empty|`[ROLE_USER]`|
|authenticated|`false`|`true`|

You build them with two static factories:

```java
Authentication request  = UsernamePasswordAuthenticationToken.unauthenticated("alice", "secret");
Authentication verified = UsernamePasswordAuthenticationToken.authenticated(userDetails, null, authorities);
```

- `unauthenticated(...)` means "here is a claim, please check it."
- `authenticated(...)` means "this has been checked." Only trusted code should call it.

Because the **password is erased** after a successful login, `user.getPassword()` returns `null` in your controllers. That's deliberate: the object gets stored in the session, and you don't want password hashes sitting there.

## Different credentials, different token classes

The manager picks a provider by looking at the token's **class**:

|Token class|Created by|Carries|
|---|---|---|
|`UsernamePasswordAuthenticationToken`|Form login, HTTP Basic|Username and password|
|`BearerTokenAuthenticationToken`|Bearer filter (before verifying)|The raw JWT string|
|`JwtAuthenticationToken`|JWT provider (after verifying)|The decoded JWT and authorities|
|`OAuth2AuthenticationToken`|OAuth2 login|The OAuth2 user|
|`RememberMeAuthenticationToken`|Remember-me filter|The remembered user|
|`AnonymousAuthenticationToken`|`AnonymousAuthenticationFilter`|`anonymousUser`|

## `GrantedAuthority`: what you may do

An **authority** is a plain string wrapped in an object:

```java
new SimpleGrantedAuthority("ROLE_ADMIN")
new SimpleGrantedAuthority("orders:delete")
```

|Idea|Rule|
|---|---|
|**Role**|An authority that starts with `ROLE_`|
|`hasRole("ADMIN")`|Checks for the authority `ROLE_ADMIN` (adds the prefix for you)|
|`hasAuthority("ROLE_ADMIN")`|The same check, written out in full|
|`hasAuthority("orders:delete")`|A fine-grained permission with no prefix|

Mixing these up is a classic bug: storing `ADMIN` in the database and checking `hasRole("ADMIN")` fails, because the authority must be `ROLE_ADMIN`.

---

# Part 2: Who does the checking

## The chain of delegation

```
UsernamePasswordAuthenticationFilter
        │  authenticate(unauthenticated token)
        ▼
AuthenticationManager          ← an interface with ONE method
        │
        ▼
ProviderManager                ← the standard implementation: holds a LIST of providers
        │  "do you support this token class?"
        ├──▶ DaoAuthenticationProvider      (username + password, from a UserDetailsService)
        ├──▶ JwtAuthenticationProvider      (bearer tokens)
        └──▶ ...your own provider
        ▼
authenticated token  OR  AuthenticationException
```

|Piece|Job|
|---|---|
|**`AuthenticationManager`**|The contract: `Authentication authenticate(Authentication)`. It either returns an authenticated object or throws.|
|**`ProviderManager`**|The normal implementation. It tries providers **in order**.|
|**`AuthenticationProvider`**|Knows how to verify **one kind** of token. Two methods: `authenticate(...)` and `supports(Class<?>)`.|

## The rules `ProviderManager` follows

|Situation|What happens|
|---|---|
|A provider's `supports(...)` returns `false`|Skipped|
|A provider returns `null`|"I can't decide", so try the next one|
|A provider returns an authenticated token|**Done.** Credentials are erased, and the result is returned.|
|A provider throws a normal `AuthenticationException`|Remember it and **try the next provider**|
|A provider throws an _account status_ exception (locked, disabled, expired)|**Stop at once** and throw it|
|No provider succeeded|Ask the **parent** manager, if there is one, then throw the last exception|
|No provider supports the token class at all|`ProviderNotFoundException`|

A parent manager is how an app gets a **global** manager plus **per-chain** managers. When you call `http.authenticationProvider(...)` inside one chain, you add to that chain's manager, which falls back to the global one.

## Inside `DaoAuthenticationProvider`

This is the provider you use most often. Its steps, in order:

```
1. retrieveUser:                 userDetailsService.loadUserByUsername(name)
        └─ not found → (hidden by default) BadCredentialsException
2. preAuthenticationChecks:      is the account locked? disabled? expired?
3. additionalAuthenticationChecks: passwordEncoder.matches(typed, stored hash)
        └─ no match → BadCredentialsException
4. postAuthenticationChecks:     have the credentials expired?
5. (optional) upgrade the stored hash if the encoder says it's outdated
6. createSuccessAuthentication:  build the AUTHENTICATED token
```

Two security details are built in:

- **Hidden "user not found."** By default, an unknown username gives the same `BadCredentialsException` ("Bad credentials") as a wrong password, so attackers can't discover which usernames exist.
- **Timing protection.** If the user doesn't exist, the provider still hashes a dummy password, so the response takes about as long as a real check. Otherwise, "fast response means no such user" would leak the same information.

## The exceptions you'll see

All extend `AuthenticationException`:

|Exception|Meaning|
|---|---|
|`BadCredentialsException`|Wrong password (or unknown user, hidden)|
|`UsernameNotFoundException`|Thrown by _your_ `UserDetailsService` when the user isn't found|
|`DisabledException`|`isEnabled()` returned `false`|
|`LockedException`|`isAccountNonLocked()` returned `false`|
|`AccountExpiredException`|`isAccountNonExpired()` returned `false`|
|`CredentialsExpiredException`|`isCredentialsNonExpired()` returned `false`|
|`InsufficientAuthenticationException`|You're known, but not strongly enough (for example only remember-me)|
|`AuthenticationServiceException` / `InternalAuthenticationServiceException`|The check itself broke (database down), not "wrong answer"|
|`ProviderNotFoundException`|No provider handles this token type|

Mapping these to responses is `ExceptionTranslationFilter`'s and the failure handler's job (Part 7).

---

# Part 3: Users: `UserDetails` and `UserDetailsService`

## The problem it solves

`DaoAuthenticationProvider` has to look up "who is alice?" It can't know whether your users live in memory, PostgreSQL, or LDAP. So it asks an interface you control.

```java
public interface UserDetailsService {
    UserDetails loadUserByUsername(String username) throws UsernameNotFoundException;
}
```

One method: give me a name, I'll give you a user, or an exception.

## `UserDetails`: how Spring sees a user

|Method|Meaning|
|---|---|
|`getUsername()`|Login name|
|`getPassword()`|The **stored hash** (never the raw password)|
|`getAuthorities()`|Roles and permissions|
|`isEnabled()`|Is the account switched on?|
|`isAccountNonLocked()`|Not locked (for example after failed attempts)|
|`isAccountNonExpired()`|Account still valid|
|`isCredentialsNonExpired()`|Password not past its expiry|

These four status flags give you **disabling, locking, and expiry** with no extra code. `DaoAuthenticationProvider` checks them for you.

Spring ships a ready-made class, `User`, with a builder:

```java
UserDetails alice = User.withUsername("alice")
        .password("{bcrypt}$2a$10$...")
        .roles("USER", "ADMIN")
        .build();
```

- `.roles("USER", "ADMIN")` adds the `ROLE_` prefix for you, giving `ROLE_USER` and `ROLE_ADMIN`.
- `.authorities("orders:read")` adds them **as written**, with no prefix.

## Built-in stores

|Class|Stores users in|Use for|
|---|---|---|
|`InMemoryUserDetailsManager`|A map in memory|Demos and tests|
|`JdbcUserDetailsManager`|Database tables (`users`, `authorities`) with a default schema|Quick JDBC setups|
|**Your own `UserDetailsService`**|Wherever you like|Real apps (Part 5)|

And what Boot does when you add `spring-boot-starter-security` and configure nothing: it creates **one in-memory user** named `user`, with a random password printed in the startup log. **The moment you define your own `UserDetailsService` bean, that default user disappears.**

---

# Part 4: Passwords and `PasswordEncoder`

## The problem it solves

If your database leaks and passwords are stored as plain text, every account is gone, and probably the same people's accounts on other sites too. So you store a **hash**: a one-way scramble. You can check a password against it, but you can't reverse it.

A normal hash such as SHA-256 is **too fast**. An attacker with a stolen table can try billions of guesses per second. Password hashes are **deliberately slow** and **salted**:

|Idea|Meaning|
|---|---|
|**Salt**|A random value mixed in per user, so two users with the same password get different hashes and precomputed tables are useless|
|**Work factor**|A setting that makes each hash take, say, 100 ms, harmless for one login and crushing for billions of guesses|
|**Adaptive**|You can raise the work factor as computers get faster|

Spring's interface:

```java
public interface PasswordEncoder {
    String encode(CharSequence raw);
    boolean matches(CharSequence raw, String encoded);
    default boolean upgradeEncoding(String encoded) { return false; }
}
```

## The algorithms

|Encoder|Notes|
|---|---|
|`BCryptPasswordEncoder`|The classic default. Strength (log rounds) defaults to 10. Only the **first 72 bytes** of the password count.|
|`Argon2PasswordEncoder`|Modern, memory-hard (needs the BouncyCastle library on the classpath)|
|`SCryptPasswordEncoder`|Memory-hard, also needs BouncyCastle|
|`Pbkdf2PasswordEncoder`|Standards-friendly, no extra libraries|
|`NoOpPasswordEncoder`|Plain text. **Dev experiments only.**|

## The recommended bean: `DelegatingPasswordEncoder`

```java
@Bean
PasswordEncoder passwordEncoder() {
    return PasswordEncoderFactories.createDelegatingPasswordEncoder();
}
```

It stores a **label** in front of every hash:

```
{bcrypt}$2a$10$7EqJtq98hPqEX7fNZaFWoOa...
{argon2}$argon2id$v=19$m=16384,t=2,p=1$...
{noop}secret
```

How it works:

- `encode(...)` uses the **default** algorithm (bcrypt in current versions) and writes the label.
- `matches(...)` reads the label, picks that encoder, and verifies.

The benefit: you can **change algorithms later** without breaking old users. Old `{bcrypt}` hashes still verify, and new passwords use the new default.

### Silent upgrades

If you also expose a `UserDetailsPasswordService`, then after a **successful** login the provider checks `upgradeEncoding(...)`. If the stored hash is weaker than your current setting, it re-hashes the password it just verified, and your service saves the new hash. Users get stronger hashes without ever being asked.

### A famous error

```
java.lang.IllegalArgumentException: There is no PasswordEncoder mapped for the id "null"
```

It means a stored password has **no `{id}` prefix**, but you're using the delegating encoder. Either store the label, or use a plain `BCryptPasswordEncoder` bean (which expects unlabeled hashes).

### Checking for known-leaked passwords

Since Spring Security 6.3, a `CompromisedPasswordChecker` bean, for example `HaveIBeenPwnedRestApiPasswordChecker`, lets the provider reject passwords that appear in known breaches. It uses a k-anonymity API, so the full password or hash never leaves your server. It's a one-bean upgrade worth knowing about.

---

# Part 5: A full PostgreSQL-backed login

Let's connect everything. You'll store users in PostgreSQL through JPA and make Spring Security use them.

## The tables

```sql
create table app_user (
    id              bigserial primary key,
    username        varchar(50)  not null unique,
    password_hash   varchar(100) not null,
    enabled         boolean      not null default true,
    failed_attempts int          not null default 0,
    locked_until    timestamptz
);

create table app_user_role (
    user_id bigint      not null references app_user(id),
    role    varchar(30) not null,
    primary key (user_id, role)
);
```

Store usernames in a consistent form (for example lower case) and keep a **unique constraint**, so two simultaneous registrations can't both win.

## The entity

```java
@Entity
@Table(name = "app_user")
public class AppUser {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String username;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    private boolean enabled = true;
    private int failedAttempts;
    private Instant lockedUntil;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "app_user_role", joinColumns = @JoinColumn(name = "user_id"))
    @Column(name = "role")
    private Set<String> roles = new HashSet<>();

    // getters and setters
}
```

The roles part deserves a small explanation. `@ElementCollection` says "this is a collection of simple values, not of entities." `@CollectionTable` says where those values live:

|Annotation|Meaning|
|---|---|
|`@CollectionTable(name = "app_user_role", ...)`|The values go in a **separate table** with this name|
|`joinColumns = @JoinColumn(name = "user_id")`|That table points back to the owner through its `user_id` column|
|`@Column(name = "role")`|Each value is stored in this column|

So alice with roles `USER` and `ADMIN` becomes:

|user_id|role|
|---|---|
|1|USER|
|1|ADMIN|

`FetchType.EAGER` loads roles together with the user. That's what we want here, because the login code needs them immediately, and the list is tiny.

## The repository

```java
public interface AppUserRepository extends JpaRepository<AppUser, Long> {
    Optional<AppUser> findByUsername(String username);
}
```

## The `UserDetailsService`

```java
@Service
public class DbUserDetailsService implements UserDetailsService {

    private final AppUserRepository users;

    public DbUserDetailsService(AppUserRepository users) {
        this.users = users;
    }

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String username) {
        AppUser u = users.findByUsername(username.toLowerCase())
                .orElseThrow(() -> new UsernameNotFoundException("No such user"));

        boolean locked = u.getLockedUntil() != null
                && u.getLockedUntil().isAfter(Instant.now());

        return User.withUsername(u.getUsername())
                .password(u.getPasswordHash())
                .disabled(!u.isEnabled())
                .accountLocked(locked)
                .authorities(u.getRoles().stream()
                        .map(r -> new SimpleGrantedAuthority("ROLE_" + r))
                        .toList())
                .build();
    }
}
```

Line by line:

- `implements UserDetailsService` plus `@Service` makes it a bean. Boot's auto-configuration finds it and plugs it into a `DaoAuthenticationProvider` automatically.
- `findByUsername(username.toLowerCase())` keeps usernames case-insensitive. Do the same when registering.
- `orElseThrow(UsernameNotFoundException)` is the correct way to say "no such user." The provider converts it to a generic bad-credentials error for the client.
- `locked` is **computed from time**. A lock that has a `lockedUntil` date unlocks itself, with no cleanup job.
- `.disabled(!u.isEnabled())` and `.accountLocked(locked)` fill in the status flags from Part 3.
- `.authorities(...)` with `"ROLE_" + r` adds the prefix by hand, since `authorities(...)` doesn't add it. We store `USER` in the database and expose `ROLE_USER`.
- `.password(u.getPasswordHash())` passes the **stored hash**, which is exactly what the encoder will compare against.

## Registration

```java
@Service
public class RegistrationService {

    private final AppUserRepository users;
    private final PasswordEncoder encoder;

    public RegistrationService(AppUserRepository users, PasswordEncoder encoder) {
        this.users = users;
        this.encoder = encoder;
    }

    @Transactional
    public void register(String username, String rawPassword) {
        if (rawPassword.length() < 8 || rawPassword.length() > 64) {
            throw new IllegalArgumentException("Password must be 8 to 64 characters");
        }
        AppUser u = new AppUser();
        u.setUsername(username.toLowerCase());
        u.setPasswordHash(encoder.encode(rawPassword));
        u.getRoles().add("USER");
        users.save(u);   // the unique constraint rejects duplicates
    }
}
```

- `encoder.encode(...)` is the **only** place a raw password becomes a hash. The raw password is never stored or logged.
- The upper limit of 64 stays comfortably below bcrypt's 72-byte reach. Length matters more than complexity rules, so allow long passphrases.
- A duplicate username raises `DataIntegrityViolationException` from the database. Catch it in your controller and show a friendly message. Don't rely on a "check, then insert" sequence, which two simultaneous requests can both pass.

## The security configuration

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    PasswordEncoder passwordEncoder() {
        return PasswordEncoderFactories.createDelegatingPasswordEncoder();
    }

    @Bean
    SecurityFilterChain web(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(a -> a
                .requestMatchers("/register", "/login", "/error", "/css/**").permitAll()
                .anyRequest().authenticated())
            .formLogin(Customizer.withDefaults());
        return http.build();
    }
}
```

You don't mention `DbUserDetailsService` anywhere here. Spring finds the bean on its own and wires it, together with the `PasswordEncoder` bean, into the `DaoAuthenticationProvider` behind the global `AuthenticationManager`. That's **auto-wiring convention**: one `UserDetailsService` bean and one `PasswordEncoder` bean is the whole setup.

## Extra fields on the logged-in user

If controllers need more than the username, such as the database id, make your own principal class:

```java
public class AppPrincipal extends User {

    private static final long serialVersionUID = 1L;
    private final long id;

    public AppPrincipal(AppUser u, boolean locked, Collection<? extends GrantedAuthority> authorities) {
        super(u.getUsername(), u.getPasswordHash(), u.isEnabled(), true, true, !locked, authorities);
        this.id = u.getId();
    }

    public long getId() { return id; }
}
```

- It extends Spring's `User`, so everything keeps working.
- The `super(...)` constructor takes: username, password, enabled, accountNonExpired, credentialsNonExpired, accountNonLocked, authorities. Note that the **last** flag is "non-locked", so we pass `!locked`.
- `serialVersionUID` matters because the principal is **serialized into the session**. That is doubly true with Spring Session and Redis. Keep it small and serializable.

Return it from `loadUserByUsername`, and then:

```java
@GetMapping("/orders")
public List<Order> mine(@AuthenticationPrincipal AppPrincipal me) {
    return orders.findByOwnerId(me.getId());
}
```

---

# Part 6: Writing your own provider

Sometimes the built-in providers don't fit. Say you want machine clients to authenticate with an **API key**. The proper pattern keeps the filter dumb and the provider smart:

```
Filter:   reads X-API-Key → builds an UNAUTHENTICATED token → asks the manager
Provider: verifies the key → returns an AUTHENTICATED token (or throws)
```

## 1. A token class

```java
public class ApiKeyAuthenticationToken extends AbstractAuthenticationToken {

    private final String apiKey;      // used before verification
    private final String clientName;  // used after verification

    public ApiKeyAuthenticationToken(String apiKey) {            // "please check this"
        super(null);
        this.apiKey = apiKey;
        this.clientName = null;
        setAuthenticated(false);
    }

    public ApiKeyAuthenticationToken(String clientName,
                                     Collection<? extends GrantedAuthority> authorities) {  // "checked"
        super(authorities);
        this.apiKey = null;
        this.clientName = clientName;
        setAuthenticated(true);
    }

    @Override public Object getCredentials() { return apiKey; }
    @Override public Object getPrincipal()   { return clientName; }
}
```

- It has **two constructors for the two states** from Part 1. One carries the key, the other carries the verified identity.
- A distinct class lets `ProviderManager` route it to the right provider through `supports(...)`.
- `AbstractAuthenticationToken` handles authorities, details, and equality for us.

## 2. The provider

```java
public class ApiKeyAuthenticationProvider implements AuthenticationProvider {

    private final ApiClientRepository clients;

    public ApiKeyAuthenticationProvider(ApiClientRepository clients) {
        this.clients = clients;
    }

    @Override
    public Authentication authenticate(Authentication authentication) {
        String presented = (String) authentication.getCredentials();

        ApiClient client = clients.findByKeyHash(sha256Hex(presented))
                .orElseThrow(() -> new BadCredentialsException("Invalid API key"));

        if (!client.isActive()) {
            throw new DisabledException("Client disabled");
        }
        return new ApiKeyAuthenticationToken(
                client.getName(), List.of(new SimpleGrantedAuthority("ROLE_API")));
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return ApiKeyAuthenticationToken.class.isAssignableFrom(authentication);
    }

    private static String sha256Hex(String s) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(s.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
```

Line by line:

- `authenticate(...)` takes the unauthenticated token, verifies it, and returns a **new** authenticated token. It either returns a valid answer or throws. It never returns a half-checked token.
- We store only the **hash** of each key. If the table leaks, the keys don't.
- A **fast** SHA-256 is fine here, but not for passwords. API keys are long random strings (say 32 random bytes), which can't be guessed even at billions of tries per second. Human-chosen passwords can be guessed, so they need the slow, salted algorithms from Part 4.
- `supports(...)` is what makes the manager choose this provider only for `ApiKeyAuthenticationToken`. Without it, the provider would get tokens it can't read.
- `DisabledException` is an account-status exception, so `ProviderManager` stops immediately instead of trying other providers.

## 3. The filter

```java
public class ApiKeyAuthenticationFilter extends OncePerRequestFilter {

    private final AuthenticationManager manager;
    private final AuthenticationEntryPoint entryPoint;

    public ApiKeyAuthenticationFilter(AuthenticationManager manager,
                                      AuthenticationEntryPoint entryPoint) {
        this.manager = manager;
        this.entryPoint = entryPoint;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String key = request.getHeader("X-API-Key");
        if (key == null) {
            chain.doFilter(request, response);   // not my credential: pass through
            return;
        }
        try {
            Authentication result = manager.authenticate(new ApiKeyAuthenticationToken(key));
            SecurityContext context = SecurityContextHolder.createEmptyContext();
            context.setAuthentication(result);
            SecurityContextHolder.setContext(context);
        } catch (AuthenticationException ex) {
            SecurityContextHolder.clearContext();
            entryPoint.commence(request, response, ex);
            return;
        }
        chain.doFilter(request, response);
    }
}
```

- **No key** means "not my business", so it passes the request on. That keeps other login methods working side by side.
- **Bad key** means clear the context and call the entry point, which answers 401. The chain stops.
- **Good key** means store the verified identity in a fresh context and continue.
- Compared with the filter in the earlier lesson, the filter no longer decides what a valid key is. All checking lives in the provider, where it's testable.

## 4. Wiring it into a chain

```java
@Bean @Order(1)
SecurityFilterChain api(HttpSecurity http, ApiClientRepository clients) throws Exception {
    ProviderManager manager = new ProviderManager(new ApiKeyAuthenticationProvider(clients));

    AuthenticationEntryPoint entryPoint = (req, res, ex) -> {
        res.setStatus(401);
        res.setContentType("application/json");
        res.getWriter().write("{\"error\":\"invalid API key\"}");
    };

    http
        .securityMatcher("/api/**")
        .authenticationManager(manager)
        .csrf(c -> c.disable())
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .addFilterBefore(new ApiKeyAuthenticationFilter(manager, entryPoint),
                         UsernamePasswordAuthenticationFilter.class)
        .authorizeHttpRequests(a -> a.anyRequest().hasRole("API"))
        .exceptionHandling(e -> e.authenticationEntryPoint(entryPoint));
    return http.build();
}
```

- `new ProviderManager(provider)` builds a small manager just for this chain.
- `http.authenticationManager(manager)` makes this chain use it.
- The filter and provider are created with `new`, not declared as beans. That avoids two traps at once:
    - A filter that is a bean also gets registered in Tomcat's chain, so it runs twice.
    - **A single `AuthenticationProvider` bean replaces Boot's automatic `UserDetailsService` wiring.** Your form login would suddenly stop working, with confusing errors. Keep custom providers out of the bean container unless you configure the global manager yourself.

---

# Part 7: Results, events, and lockout

## Success and failure handlers

After the manager answers, the authentication filter decides what the client sees:

```java
http.formLogin(f -> f
    .loginPage("/login")
    .loginProcessingUrl("/login")
    .usernameParameter("username")
    .passwordParameter("password")
    .defaultSuccessUrl("/home", false)
    .failureUrl("/login?error"));
```

|Setting|Meaning|
|---|---|
|`loginPage`|Your own page instead of the built-in one|
|`loginProcessingUrl`|Where the form POSTs|
|`usernameParameter` / `passwordParameter`|The form field names (change them for an email login)|
|`defaultSuccessUrl("/home", false)`|Go to `/home` **only if** there was no saved request. `false` keeps the "return to the page you wanted" behavior.|
|`failureUrl`|Where to go after failure|

For a JSON front end, use handlers instead of URLs:

```java
http.formLogin(f -> f
    .successHandler((req, res, auth) -> res.setStatus(200))
    .failureHandler((req, res, ex) -> {
        res.setStatus(401);
        res.setContentType("application/json");
        res.getWriter().write("{\"error\":\"invalid credentials\"}");
    }));
```

Note the failure message is **fixed**. Never echo `ex.getMessage()` or say which part was wrong.

## Extra request data: `AuthenticationDetailsSource`

`getDetails()` normally holds the client IP and session ID. You can capture more, such as the user agent, by providing your own `AuthenticationDetailsSource` through `formLogin(f -> f.authenticationDetailsSource(...))`. That's how "Chrome on Windows" gets into your "active devices" list.

## Events

Every authentication outcome publishes a Spring event. Boot configures the publisher for you. Listen with `@EventListener`:

|Event|When|
|---|---|
|`AuthenticationSuccessEvent`|A provider succeeded|
|`AuthenticationFailureBadCredentialsEvent`|Wrong password or unknown user|
|`AuthenticationFailureLockedEvent`|Account locked|
|`AuthenticationFailureDisabledEvent`|Account disabled|
|`AuthenticationFailureExpiredEvent` / `...CredentialsExpiredEvent`|Expiry|
|`AbstractAuthenticationFailureEvent`|The parent of all failure events|

Here is a **lockout after 5 failures** that uses the columns from Part 5:

```java
@Component
public class LoginAttemptListener {

    private static final int MAX_FAILURES = 5;
    private final AppUserRepository users;

    public LoginAttemptListener(AppUserRepository users) {
        this.users = users;
    }

    @EventListener
    @Transactional
    public void onBadCredentials(AuthenticationFailureBadCredentialsEvent event) {
        users.findByUsername(event.getAuthentication().getName().toLowerCase())
             .ifPresent(u -> {
                 u.setFailedAttempts(u.getFailedAttempts() + 1);
                 if (u.getFailedAttempts() >= MAX_FAILURES) {
                     u.setLockedUntil(Instant.now().plus(Duration.ofMinutes(15)));
                     u.setFailedAttempts(0);
                 }
             });
    }

    @EventListener
    @Transactional
    public void onSuccess(AuthenticationSuccessEvent event) {
        users.findByUsername(event.getAuthentication().getName().toLowerCase())
             .ifPresent(u -> u.setFailedAttempts(0));
    }
}
```

Line by line:

- `@EventListener` on a method with an event parameter subscribes it.
- `event.getAuthentication().getName()` is the typed username. For an unknown user, `findByUsername` returns empty and nothing happens, with no difference visible to the client.
- On the fifth failure, the lock time is set 15 minutes ahead. Our `UserDetailsService` from Part 5 reads it and reports the account as locked.
- A successful login resets the counter.
- `@Transactional` makes the entity changes save automatically, without an explicit `save(...)`.

Honest caveats about this design:

- **Attackers can lock real users out.** Anyone can type five wrong passwords for "alice." Temporary locks (not permanent ones), per-IP rate limiting, and notifying the real user soften this.
- A counter in the database is correct across many servers. A counter in a `HashMap` is not.
- For **stateless** setups (Basic or bearer tokens), `AuthenticationSuccessEvent` fires on **every request**, not just at login. Don't put heavy work in that listener.

---

# Part 8: Logging in from your own code

Sometimes the login doesn't come from a form: a JSON `/api/login`, a "log in after sign-up" step, or a password-reset flow. You do what the filter would do.

First, expose the manager:

```java
@Bean
AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
    return config.getAuthenticationManager();
}
```

Then:

```java
@RestController
public class LoginController {

    private final AuthenticationManager manager;
    private final SecurityContextRepository repository = new HttpSessionSecurityContextRepository();

    public LoginController(AuthenticationManager manager) {
        this.manager = manager;
    }

    @PostMapping("/api/login")
    public ResponseEntity<Void> login(@RequestBody LoginRequest body,
                                      HttpServletRequest request,
                                      HttpServletResponse response) {
        Authentication result = manager.authenticate(
                UsernamePasswordAuthenticationToken.unauthenticated(body.username(), body.password()));

        SecurityContext context = SecurityContextHolder.createEmptyContext();
        context.setAuthentication(result);
        SecurityContextHolder.setContext(context);
        repository.saveContext(context, request, response);

        request.changeSessionId();
        return ResponseEntity.noContent().build();
    }
}
```

Line by line:

- `manager.authenticate(...)` runs the whole Part 2 flow. A wrong password throws `BadCredentialsException`, and you map it to a 401 with an `@ExceptionHandler`.
- The next three lines build a **fresh** context and set it for this request.
- `repository.saveContext(...)` writes it into the `HttpSession`. **Skip this and the user is logged out on the next request.** That's the difference from earlier Spring Security versions, where saving was automatic.
- `request.changeSessionId()` is **session fixation protection**, which you'd get for free with the built-in filter. If a session already exists, do this by hand. Calling it when no session exists throws `IllegalStateException`, so make sure one has been created first (the save above creates it).
- Hand-written login code skips other protections too: the lockout events still fire (they come from the manager), but the **success handler, session limits, and request cache** don't run. Prefer the standard filter unless you truly need custom login.

---

# Part 9: Levels of "logged in"

Not every identity is equally trustworthy. There are three levels, and rules can tell them apart:

|Level|How you got it|Token class|
|---|---|---|
|**Anonymous**|No credentials at all|`AnonymousAuthenticationToken`|
|**Remember-me**|A long-lived cookie, no password typed this visit|`RememberMeAuthenticationToken`|
|**Fully authenticated**|You proved yourself in this session|`UsernamePasswordAuthenticationToken` etc.|

|Rule|Allows|
|---|---|
|`permitAll()`|Everyone|
|`authenticated()`|Remember-me and fully authenticated (not anonymous)|
|`fullyAuthenticated()`|**Only** fully authenticated|
|`anonymous()`|Only not-logged-in visitors (a login page for guests)|
|`rememberMe()`|Only remember-me logins|

A sensible pattern is to let remember-me users browse but **ask for the password again** for sensitive pages:

```java
.requestMatchers("/account/security/**", "/payments/**").fullyAuthenticated()
.anyRequest().authenticated()
```

When a remember-me user hits a `fullyAuthenticated()` rule, Spring Security redirects to the login page, and they type their password once more.

---

# Part 10: Security practices

|Practice|Why|
|---|---|
|**Same message for every login failure**|Don't reveal "no such user" versus "wrong password".|
|Keep `hideUserNotFoundExceptions` at its default (`true`)|Same reason, built in|
|Hash with the delegating encoder and a slow algorithm|Stolen tables stay stolen tables, not stolen passwords|
|Allow long passwords (8 to 64 or more characters), and don't force odd symbol rules|Length helps more than complexity rules|
|Check for breached passwords|`CompromisedPasswordChecker` (6.3+)|
|Rate-limit login attempts|Spring Security doesn't throttle by itself: use lockouts, a gateway, or a library like Bucket4j|
|Never log passwords, tokens, or full `Authentication` credentials|Logs travel far and live long|
|Use HTTPS for every login|A password in plain HTTP is a password given away|
|Rotate the session ID at login|Fixation protection (default)|
|Don't use HTTP Basic with bcrypt on every request|See below|
|Add a second factor for important accounts|Passwords alone get phished|
|Make password reset flows as strong as login|Reset links are a **second front door**|

### HTTP Basic plus bcrypt on every request is slow

With sessions, the password check happens **once** at login. With HTTP Basic, the password arrives on **every request**, so every request pays the bcrypt cost (about 100 ms of CPU by design). A busy API quickly burns its CPU. Use Basic only for tools and testing, and use **tokens** for APIs: verifying a JWT signature costs microseconds.

### Multi-factor authentication, briefly

Something you **know** (password), something you **have** (phone, passkey), something you **are** (fingerprint). Two different kinds make phishing a stolen password far less useful. In Spring Security, passkeys (WebAuthn) and one-time-token login exist in newer versions, and Spring Security 7 adds first-class multi-factor support. The exact API is changing, so check the reference documentation for your version before building on it.

---

# Part 11: Testing authentication

```java
@SpringBootTest
@AutoConfigureMockMvc
class AuthTests {

    @Autowired MockMvc mockMvc;

    @Test
    void goodPasswordLogsIn() throws Exception {
        mockMvc.perform(formLogin().user("alice").password("secret-password"))
               .andExpect(authenticated().withUsername("alice"));
    }

    @Test
    void wrongPasswordFails() throws Exception {
        mockMvc.perform(formLogin().user("alice").password("wrong"))
               .andExpect(unauthenticated());
    }

    @Test
    @WithMockUser(username = "bob", roles = "ADMIN")
    void adminPageWorksForAdmin() throws Exception {
        mockMvc.perform(get("/admin")).andExpect(status().isOk());
    }

    @Test
    @WithUserDetails("alice")
    void loadsRealUserFromUserDetailsService() throws Exception {
        mockMvc.perform(get("/orders")).andExpect(status().isOk());
    }
}
```

- `formLogin().user(...).password(...)` simulates the real form POST, including CSRF handling. It exercises your **actual** provider, encoder, and database.
- `authenticated()` and `unauthenticated()` check the resulting login state.
- `@WithMockUser` **skips authentication** and fakes a logged-in user. It's good for testing authorization rules, but it proves nothing about your login.
- `@WithUserDetails("alice")` runs your real `UserDetailsService` to build the user, so roles and your custom principal class are real.

For your custom provider, test it **without Spring at all**:

```java
@Test
void unknownKeyIsRejected() {
    var provider = new ApiKeyAuthenticationProvider(fakeRepositoryReturningEmpty());
    assertThrows(BadCredentialsException.class,
        () -> provider.authenticate(new ApiKeyAuthenticationToken("nope")));
}
```

A provider is just a class with one method, which is why this design is so easy to test.

---

# Try it yourself

For these experiments, add `.httpBasic(Customizer.withDefaults())` to your chain so `curl -u` works, and run PostgreSQL on your Debian machine.

**1. Create a user with a hash you made yourself:**

```bash
sudo apt install apache2-utils
HASH=$(htpasswd -bnBC 10 "" 'secret-password' | tr -d ':\n' | sed 's/^\$2y/\$2a/')
echo "{bcrypt}$HASH"
```

- `htpasswd -bnBC 10` creates a bcrypt hash with 10 rounds, in batch mode, printing to the screen.
- `tr -d ':\n'` removes the leading colon and newline.
- `sed` changes the `$2y` prefix to `$2a` for compatibility.
- The `{bcrypt}` prefix is what the delegating encoder wants.

```sql
insert into app_user(username, password_hash) values ('alice', '{bcrypt}$2a$10$...paste...');
insert into app_user_role(user_id, role) values (1, 'USER');
```

**2. Log in with Basic auth:**

```bash
curl -i -u alice:secret-password http://localhost:8080/whoami
curl -i -u alice:wrong           http://localhost:8080/whoami
```

You get 200, then 401 with `WWW-Authenticate: Basic`.

**3. Look at the `Authentication` object itself:**

```java
@GetMapping("/whoami")
public Map<String, String> whoami(Authentication auth) {
    return Map.of(
        "name", auth.getName(),
        "authorities", auth.getAuthorities().toString(),
        "principalClass", auth.getPrincipal().getClass().getSimpleName(),
        "credentials", String.valueOf(auth.getCredentials()),
        "details", String.valueOf(auth.getDetails()));
}
```

You'll see `credentials` is `null` (erased), `principalClass` is `User`, and `details` shows the remote address and session ID.

**4. Compare unknown user and wrong password:**

```bash
curl -s -o /dev/null -w "%{http_code} %{time_total}s\n" -u nobody:whatever http://localhost:8080/whoami
curl -s -o /dev/null -w "%{http_code} %{time_total}s\n" -u alice:wrong     http://localhost:8080/whoami
```

Both answer 401 in about the same time. That's the dummy-hash timing protection at work.

**5. Watch the manager think:**

```properties
logging.level.org.springframework.security=TRACE
```

Look for lines about `Authenticating`, the provider chosen, and the failure or success.

**6. Use the debugger (the best lesson):** put breakpoints on `ProviderManager.authenticate`, `DaoAuthenticationProvider.additionalAuthenticationChecks`, and your `loadUserByUsername`. Log in and step through. You'll see Part 2's steps in order, plus the `Authentication` object change shape.

**7. Test the lockout:** send five wrong passwords, then the **right** one:

```bash
for i in 1 2 3 4 5; do curl -s -o /dev/null -w "%{http_code} " -u alice:bad http://localhost:8080/whoami; done; echo
curl -i -u alice:secret-password http://localhost:8080/whoami
```

The last request is refused, even with the correct password, because `locked_until` is in the future. Check the table with `select username, failed_attempts, locked_until from app_user;`.

**8. Try the API key chain:**

```bash
curl -i -H "X-API-Key: not-a-real-key" http://localhost:8080/api/ping     # 401 JSON
```

Insert a hashed key into `api_client` (`echo -n 'my-test-key' | sha256sum`), then repeat with the real value to get 200.

**9. See the hash upgrade idea:** store a user with `{noop}secret-password`, log in, and notice it works. Then think about how `upgradeEncoding(...)` and a `UserDetailsPasswordService` would let a successful login rewrite that hash as bcrypt automatically.

---

# Common mistakes

|Mistake|Why it hurts|Fix|
|---|---|---|
|Stored passwords with no `{id}` prefix under the delegating encoder|"no PasswordEncoder mapped for the id null"|Store the prefix, or use a plain `BCryptPasswordEncoder`|
|`{noop}` passwords outside demos|Plain-text passwords|Always hash with a slow encoder|
|Storing `ADMIN` but checking `hasRole("ADMIN")`|The authority must be `ROLE_ADMIN`|Add the prefix when building authorities|
|Declaring one `AuthenticationProvider` as a bean|Switches off the automatic `UserDetailsService` wiring|Build it with `new` in a chain-specific `ProviderManager`, or configure the global manager on purpose|
|Making your authentication filter a bean without disabling its Tomcat registration|It runs twice|`new` it in the chain, or `FilterRegistrationBean.setEnabled(false)`|
|Custom login that doesn't call `saveContext(...)`|Logged out on the next request|Save with a `SecurityContextRepository`|
|Calling `authenticated(...)` on something you didn't verify|You've just made anyone "logged in"|Only providers create authenticated tokens|
|A filter that rejects when its credential is missing|Breaks every other login method|If it's not your credential, pass the request on|
|Revealing "no such user"|Username enumeration|One fixed error message|
|Throwing `UsernameNotFoundException` and catching it to return custom text|Reintroduces enumeration|Let the framework convert it|
|Trusting `@WithMockUser` to test login|It bypasses authentication|Use `formLogin()` and `@WithUserDetails`|
|bcrypt with very long passwords|Only 72 bytes count|Cap length (for example 64) or pre-hash with care|
|HTTP Basic plus bcrypt on every API request|CPU melts|Tokens for APIs|
|A lockout counter in a `HashMap`|Wrong across servers and lost on restart|Persist it|
|Permanent lockouts|Anyone can lock anyone out|Temporary locks plus rate limiting|
|Principal class that isn't serializable (with sessions in Redis)|Serialization errors on login|Keep it small, with `serialVersionUID`|
|Expecting a role change in the database to apply instantly|The live session holds old authorities|Expire that user's sessions (see the sessions lesson)|
|Logging `Authentication.toString()` carelessly|Can leak session IDs or details|Log the username only|

---

## Related concept, briefly

**Authentication vs "identity federation":** everything above is **local** authentication, where your app owns the users and checks their passwords. With **OAuth2 / OIDC** ("Sign in with Google," company single sign-on), another system verifies the user, and your app only receives a signed result. Spring Security models this with the **same objects**: an `Authentication` in the `SecurityContext`, created by a provider (`OAuth2LoginAuthenticationProvider`). The difference is _who checked the password_, not how the app represents the answer. That's why everything you learned here carries over.

---

## The whole picture

|Question|Answer|
|---|---|
|What carries "who is this"?|The `Authentication` object (principal, credentials, authorities, details)|
|Its two states?|**Unauthenticated** (a claim) and **authenticated** (verified)|
|Who verifies it?|`AuthenticationManager` → `ProviderManager` → `AuthenticationProvider`s|
|How is a provider chosen?|By `supports(tokenClass)`, tried in order|
|What does `DaoAuthenticationProvider` do?|Load the user, check status flags, compare the password hash, build the result|
|Where do users come from?|Your `UserDetailsService` (a database, in your case)|
|How are passwords stored?|Slow, salted hashes through `PasswordEncoder` (`DelegatingPasswordEncoder` recommended)|
|What happens to the raw password afterward?|It's erased from the `Authentication`|
|How do I add locking and disabling?|The four `UserDetails` status flags|
|How do I count failed logins?|`AuthenticationFailure...Event` listeners|
|How do I support a new credential type?|A token class, a provider, and a filter that passes through when it's not their credential|
|How do I log in from my own code?|`manager.authenticate(...)` then set **and save** the context|
|What is "fully authenticated"?|A login that is not anonymous and not remember-me|
|What must never differ for a client?|The error message for unknown user versus wrong password|
|How do I test it?|`formLogin()`, `@WithUserDetails`, and plain unit tests for providers|




[[Spring Security]]