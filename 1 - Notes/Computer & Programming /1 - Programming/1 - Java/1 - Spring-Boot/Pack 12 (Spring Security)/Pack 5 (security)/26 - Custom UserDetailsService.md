
A `UserDetailsService` is a tiny interface with one job: given a username, go and find that user and hand them back to Spring Security. It has a single method, `loadUserByUsername(String username)`, and it returns a `UserDetails` object, which is Spring Security's standard description of a user (name, password, roles, and account status). Spring Security doesn't care _where_ your users live. It only cares that you can answer the question "who is this username?"

A custom `UserDetailsService` is your own implementation of that interface, usually one that reads users from your database. You write the lookup. Spring Security does everything else: checking the password, building the login result, and remembering the user for the session. This is the most common first customization in any Spring Security project, so it's worth understanding well.

## 1. The cast of characters

Five pieces work together during a login. Knowing who does what makes the rest easy.

|Piece|Its job|Who writes it|
|---|---|---|
|`UserDetails`|Describes one user: username, encoded password, authorities, status flags|You (or use the built-in `User`)|
|`UserDetailsService`|Finds a `UserDetails` by username|**You**|
|`PasswordEncoder`|Hashes passwords and checks a raw password against a hash|You pick one (BCrypt)|
|`DaoAuthenticationProvider`|The worker that calls your service and checks the password|Spring Security|
|`AuthenticationManager`|The front desk that hands the login attempt to the right provider|Spring Security|

Notice that your service never checks the password. It only _loads_ the user. The provider does the checking. Keep that split in mind, because it explains almost every bug people hit.

## 2. Why you need your own

By default, Spring Boot gives you one in-memory user named `user` with a random password printed in the console. That's fine for a demo and useless for a real app. In a real app your users live in PostgreSQL (or SQLite), with your own columns like `email`, `enabled`, or `tenant_id`.

Spring Security can't guess your table layout. So you tell it how to fetch a user by writing the service. Once you do, Spring Boot notices your bean and automatically wires it in. You don't register it anywhere by hand, as long as it's the only `UserDetailsService` bean.

## 3. Building it, step by step

I'll assume Spring Boot 3 with Spring Data JPA. Each step is small.

### Step 1: the user entity

```java
@Entity
@Table(name = "app_users")
public class AppUser {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String username;

    @Column(nullable = false)
    private String password;   // stores the BCrypt hash, never plain text

    private boolean enabled = true;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "app_user_roles", joinColumns = @JoinColumn(name = "user_id"))
    @Column(name = "role")
    private Set<String> roles = new HashSet<>();

    // getters and setters
}
```

Walkthrough of the parts that matter:

- `username` is `unique`, because the login lookup depends on it returning at most one user.
- `password` holds the **hash**. The word "password" in the column name is misleading, so remember: plain text must never reach this field.
- `FetchType.EAGER` on roles is deliberate. Spring Security reads the roles _after_ your service method finishes, when the database session may already be closed. A lazy collection would throw `LazyInitializationException` at login.

### Step 2: the repository

```java
public interface AppUserRepository extends JpaRepository<AppUser, Long> {
    Optional<AppUser> findByUsername(String username);
}
```

Spring Data builds the query from the method name. It returns an `Optional` so "no such user" is a normal case, not a crash.

### Step 3: the `UserDetails` wrapper

```java
public class AppUserDetails implements UserDetails {

    private final AppUser user;

    public AppUserDetails(AppUser user) {
        this.user = Objects.requireNonNull(user, "user must not be null");
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return user.getRoles().stream()
                .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
                .toList();
    }

    @Override public String getPassword()  { return user.getPassword(); }
    @Override public String getUsername()  { return user.getUsername(); }
    @Override public boolean isEnabled()   { return user.isEnabled(); }

    @Override public boolean isAccountNonExpired()     { return true; }
    @Override public boolean isAccountNonLocked()      { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
}
```

Walkthrough:

- The constructor wraps your entity. `Objects.requireNonNull` makes sure you never build a half-empty user (the same fail-fast idea from the last lesson).
- `getAuthorities()` converts each role string into a `GrantedAuthority`. The `"ROLE_"` prefix matters: `hasRole("ADMIN")` in your security rules looks for the authority `ROLE_ADMIN`. Without the prefix, role checks silently fail.
- `getPassword()` returns the stored hash. The provider will compare against this.
- The four status methods let Spring Security block a user _before_ it even checks the password. I explain them in section 5.

### Step 4: the service itself

```java
@Service
public class AppUserDetailsService implements UserDetailsService {

    private final AppUserRepository repository;

    public AppUserDetailsService(AppUserRepository repository) {
        this.repository = repository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        AppUser user = repository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));
        return new AppUserDetails(user);
    }
}
```

Walkthrough:

- `@Service` makes it a Spring bean, so Spring Boot can find and use it.
- `repository.findByUsername(username)` runs your database query.
- `.orElseThrow(...)` throws `UsernameNotFoundException` when nothing matches. This is the exception Spring Security expects. Never return `null`, because the contract says to throw.
- `new AppUserDetails(user)` wraps the entity and returns it.

### Step 5: the security configuration

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/register", "/css/**").permitAll()
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated())
            .formLogin(Customizer.withDefaults());
        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

Walkthrough:

- The `SecurityFilterChain` bean defines which URLs are public and which need a login.
- `hasRole("ADMIN")` checks for the authority `ROLE_ADMIN`, which is why Step 3 added the prefix.
- `PasswordEncoder` is a bean so Spring Security finds it automatically. Your `UserDetailsService` bean and `PasswordEncoder` bean are picked up and combined into a `DaoAuthenticationProvider` for you.

### Step 6: save users with an encoded password

```java
public void register(String username, String rawPassword) {
    AppUser user = new AppUser();
    user.setUsername(username);
    user.setPassword(passwordEncoder.encode(rawPassword));
    user.getRoles().add("USER");
    repository.save(user);
}
```

`passwordEncoder.encode(...)` turns `"secret123"` into something like `$2a$10$...`. If you skip this and store plain text, login will always fail, because the provider expects a hash.

## 4. The login flow

Here is what happens when someone submits the login form with a username and password.

```
Browser: POST /login  (username + password)
   │
   ▼
UsernamePasswordAuthenticationFilter
   │  wraps the input in an unauthenticated token
   ▼
AuthenticationManager (ProviderManager)
   │  picks a provider that supports this token
   ▼
DaoAuthenticationProvider
   │
   ├─1─► YourUserDetailsService.loadUserByUsername(username)
   │          └─► database query ──► returns UserDetails
   │
   ├─2─► checks account status flags
   │          (enabled, locked, expired)
   │
   ├─3─► PasswordEncoder.matches(rawPassword, userDetails.getPassword())
   │
   └─4─► builds a fully authenticated Authentication object
   │
   ▼
SecurityContextHolder stores the Authentication
   │
   ▼
Session remembers it ──► user is now "logged in"
```

In plain words:

1. The filter catches the login request and wraps your input in an _unauthenticated_ token. It's just a note saying "someone claims to be this user."
2. The `AuthenticationManager` passes the note to a provider that knows how to handle username and password.
3. The provider calls **your** `loadUserByUsername`. This is the only moment your code runs in the flow.
4. The provider checks the status flags, then asks the encoder whether the typed password matches the stored hash.
5. If everything passes, the provider builds an _authenticated_ token containing the user and their authorities.
6. That token goes into the `SecurityContextHolder`, and the session keeps it for later requests. On the next request, the user isn't loaded again from the database by default. The session restores the saved context.

### What happens when it fails

|What went wrong|What you throw or what the provider does|What the user sees|
|---|---|---|
|Username doesn't exist|You throw `UsernameNotFoundException`|"Bad credentials"|
|Password is wrong|Provider throws `BadCredentialsException`|"Bad credentials"|
|`isEnabled()` is false|`DisabledException`|"User is disabled"|
|`isAccountNonLocked()` is false|`LockedException`|"User account is locked"|
|`isAccountNonExpired()` is false|`AccountExpiredException`|"User account has expired"|
|`isCredentialsNonExpired()` is false|`CredentialsExpiredException`|"User credentials have expired"|

Look at the first two rows. The user sees the _same_ message for "no such user" and "wrong password." That's on purpose. By default Spring Security converts `UsernameNotFoundException` into `BadCredentialsException`, so an attacker can't use the login form to find out which usernames exist.

## 5. The four status flags

These let you block a user without deleting them.

|Method|Typical use|
|---|---|
|`isEnabled()`|Admin disabled the account, or email not yet verified|
|`isAccountNonLocked()`|Too many failed attempts, temporary lockout|
|`isAccountNonExpired()`|Trial or contract account that ended|
|`isCredentialsNonExpired()`|Password must be changed every N days|

In Step 3 I returned `true` for three of them to keep things simple. When you add real columns (`locked`, `expires_at`), you map them here.

## 6. Common mistakes

- **Plain-text passwords in the database.** The provider compares a raw password against a hash. A plain value never matches.
- **Missing `ROLE_` prefix.** `hasRole("ADMIN")` fails even though the user "is" an admin.
- **Lazy-loaded roles.** You get `LazyInitializationException` during login. Use `EAGER` or a fetch join in your query.
- **Returning `null` instead of throwing.** Always throw `UsernameNotFoundException`.
- **Checking the password inside `loadUserByUsername`.** Don't. Only load. The provider verifies.
- **Two `UserDetailsService` beans.** Spring Boot's auto-wiring stops working, so you'd have to wire a provider by hand.

## 7. Related concepts, in short

- **`AuthenticationProvider`**: the interface behind `DaoAuthenticationProvider`. Write your own when login isn't "username + password from a database," for example API keys or an external identity system. Most apps never need to.
- **`UserDetailsPasswordService`**: an optional interface your service can also implement. When a user logs in with an old, weaker hash, Spring Security hands you a freshly upgraded hash to save. It's how you migrate hashing strength over time without forcing resets.
- **JWT apps**: with tokens, you still often use a `UserDetailsService`, but inside your JWT filter. The filter reads the username from the token, calls `loadUserByUsername`, and builds the authentication from the result, so no password check happens on every request.





[[Spring Security]]