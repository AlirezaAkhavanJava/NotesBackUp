![[6a951148-8a50-4482-9587-fa937ff85752.png]]


A **credentials entity** is the small database record that answers one question: "can this person prove who they are?" It holds the identifier they log in with (email, username) and a _hash_ of their password. Nothing else. Names, avatars, bios and habits belong in a separate profile entity, because the credentials row is the most sensitive data you own, and you want as few classes as possible touching it.

Around that one entity you need four helpers, and each does a different job. **Bean Validation** checks that input is well-formed. **PasswordEncoder** turns a password into a hash and later checks a login attempt against it. **UserDetailsService** finds the stored user. **AuthenticationManager** is the boss that coordinates the last three when someone logs in. You will build them in that order, then see how they connect.

## The big picture: what happens at login

Read this once now, and come back to it at the end. Every class below is one box in this flow:

```
POST /api/auth/login  { identifier, password }
        │
        ▼
AuthService.login()
        │  authenticationManager.authenticate(token)
        ▼
ProviderManager                      ← the AuthenticationManager
        │
        ▼
DaoAuthenticationProvider
   1. userDetailsService.loadUserByUsername(identifier)   → finds the row
   2. checks: enabled? locked?                            → UserDetails flags
   3. passwordEncoder.matches(rawPassword, storedHash)    → compares
        │
        ▼
Authenticated Authentication object (or an exception)
```

Registration is simpler: validate → check duplicates → `passwordEncoder.encode()` → save.

## Part 1: The credentials entity

```java
@Entity
@Table(name = "user_credentials",
       uniqueConstraints = {
           @UniqueConstraint(name = "uk_credentials_email",    columnNames = "email"),
           @UniqueConstraint(name = "uk_credentials_username", columnNames = "username")
       })
@Getter @Setter @NoArgsConstructor
public class UserCredentials {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Setter(AccessLevel.NONE)               // nobody should change the id
    private Long id;

    @Column(nullable = false, length = 254)
    private String email;

    @Column(nullable = false, length = 30)
    private String username;

    @Column(name = "password_hash", nullable = false, length = 100)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Role role = Role.USER;

    @Column(nullable = false)
    private boolean enabled = true;  // becomes false-until-verified if you add email verification

    @Column(nullable = false)
    private boolean locked = false;

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}
```

Walkthrough of the choices that matter:

|Choice|Reason|
|---|---|
|Field is `passwordHash`, not `password`|The name reminds every future reader (and you) that this is never the real password.|
|`length = 100`|A BCrypt hash is 60 characters; with a `{bcrypt}` prefix it is about 68. 100 leaves room if you change algorithms.|
|`uniqueConstraints` at table level|The database is the final judge of uniqueness. Your Java checks can race; the constraint cannot.|
|`length = 254` for email|254 is the practical maximum length of a valid email address.|
|`enabled` and `locked`|`UserDetails` has these flags, and Spring Security checks them _for you_ during login.|
|`Instant createdAt`|Handy for audits and later for expiring unverified accounts.|

Two design rules to keep:

1. **Normalize before you store.** Trim and lowercase both email and username in the service. Otherwise `Ali@Mail.com` and `ali@mail.com` become two accounts (PostgreSQL's unique constraint is case-sensitive).
2. **Usernames must not contain `@`.** Later you will let people log in with "email or username". If usernames can't contain `@`, the two can never collide.

## Part 2: Validation, in three layers

Validation is not one thing. Each layer catches a different kind of mistake:

|Layer|Question it asks|Tool|Example|
|---|---|---|---|
|Request DTO|Is the input shaped correctly?|Bean Validation annotations|Email looks like an email|
|Service|Does it make sense for our data?|Your Java code|Email is not already taken|
|Database|Can bad data ever get stored?|Constraints|`UNIQUE`, `NOT NULL`, `length`|

### Layer 1: the DTO

```java
public record RegisterRequest(

    @NotBlank(message = "Email is required")
    @Email(message = "Email is not valid")
    @Size(max = 254)
    String email,

    @NotBlank(message = "Username is required")
    @Size(min = 3, max = 30, message = "Username must be 3 to 30 characters")
    @Pattern(regexp = "^[a-zA-Z0-9_]+$",
             message = "Username may contain only letters, digits and underscore")
    String username,

    @NotBlank(message = "Password is required")
    @Size(min = 8, max = 72, message = "Password must be 8 to 72 characters")
    @Pattern(regexp = "^(?=.*[A-Za-z])(?=.*\\d).+$",
             message = "Password must contain a letter and a digit")
    String password
) {}
```

```java
public record LoginRequest(
    @NotBlank String identifier,     // email OR username
    @NotBlank String password
) {}
```

Things worth knowing:

- **The password rules live on the DTO, never on the entity.** The entity holds the _hash_, which is always 60+ random-looking characters. If you put `@Size(min=8, max=72)` on the entity, it would validate the hash and be meaningless (or break).
- **`max = 72` is deliberate.** BCrypt only uses the first 72 _bytes_ of a password. Capping the length avoids silent truncation (and very long inputs used to waste your CPU).
- **Hibernate's `@Email` is lenient.** It accepts `a@b` with no dot. Add a `@Pattern` if you want it stricter, but remember the only real proof an email is valid is sending something to it (see Part 4).
- **`LoginRequest` only checks `@NotBlank`.** Don't apply strength or format rules at login. That would teach attackers your rules and would lock out older users whose passwords predate the rules.

Activate it with `@Valid` in the controller:

```java
@PostMapping("/register")
public ResponseEntity<Void> register(@Valid @RequestBody RegisterRequest req) {
    authService.register(req);
    return ResponseEntity.status(HttpStatus.CREATED).build();
}
```

When validation fails, Spring throws `MethodArgumentNotValidException`; handle it in one `@RestControllerAdvice` and return the field messages as JSON.

## Part 3: PasswordEncoder, the hashing tool

A **hash** is a one-way scramble. You can turn a password into a hash, but you can never turn the hash back into the password. That is the whole point: if your database leaks, attackers get hashes, not passwords.

`PasswordEncoder` has two methods you will use:

```java
String encode(CharSequence rawPassword);                       // at registration
boolean matches(CharSequence rawPassword, String storedHash);  // at login
```

```java
@Configuration
public class PasswordConfig {
    @Bean
    public PasswordEncoder passwordEncoder() {
        return PasswordEncoderFactories.createDelegatingPasswordEncoder();
    }
}
```

This returns a `DelegatingPasswordEncoder`. It stores hashes with an algorithm label in front, like `{bcrypt}$2a$10$...`. That label lets you switch to a stronger algorithm in the future while old users still log in. If you want the simplest option, `new BCryptPasswordEncoder()` is also fine; it is what the delegating encoder uses by default.

**Salt, in small words.** A salt is random data mixed into the password before hashing. BCrypt makes one automatically and stores it _inside_ the hash string. So the same password gives a different hash each time:

|Call|Result|
|---|---|
|`encode("Hello123")`|`{bcrypt}$2a$10$aaaa...`|
|`encode("Hello123")` again|`{bcrypt}$2a$10$zzzz...` (different!)|
|`matches("Hello123", firstHash)`|`true`|
|`matches("Hello123", secondHash)`|`true`|

That is why you must never do `encoder.encode(raw).equals(stored)`. It will always be `false`. Always use `matches()`, which reads the salt back out of the stored hash.

**What is inside a BCrypt hash:**

|Part|Meaning|
|---|---|
|`$2a$`|BCrypt version|
|`10`|Cost factor: 2^10 rounds of work. Higher is slower for attackers (and for you).|
|next 22 characters|The salt|
|last 31 characters|The actual hash|

## Part 4: Verifying email and username

"Verifying" can mean four different things. Knowing which one you mean tells you which tool to use:

|Job|Question|Tool|
|---|---|---|
|Format check|Does it look like an email?|Bean Validation on the DTO (done in Part 2)|
|Availability|Is it already taken?|`existsBy...` in the service plus the DB unique constraint|
|Lookup at login|Which stored user is this?|**`UserDetailsService`**|
|Ownership proof|Does this person really own this email?|An emailed verification token (the "thing you may not know")|

### The repository

```java
public interface UserCredentialsRepository extends JpaRepository<UserCredentials, Long> {
    boolean existsByEmail(String email);
    boolean existsByUsername(String username);
    Optional<UserCredentials> findByEmailOrUsername(String email, String username);
}
```

### Availability, in the registration service

```java
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserCredentialsRepository repository;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public void register(RegisterRequest req) {
        String email    = req.email().trim().toLowerCase();
        String username = req.username().trim().toLowerCase();

        if (repository.existsByEmail(email))       throw new DuplicateCredentialException("Email already in use");
        if (repository.existsByUsername(username)) throw new DuplicateCredentialException("Username already taken");

        UserCredentials c = new UserCredentials();
        c.setEmail(email);
        c.setUsername(username);
        c.setPasswordHash(passwordEncoder.encode(req.password()));   // hash here, once
        try {
            repository.save(c);
        } catch (DataIntegrityViolationException e) {                // two requests raced past the checks
            throw new DuplicateCredentialException("Email or username already in use");
        }
    }
}
```

Line by line:

- The first two lines normalize, so comparisons are consistent.
- The `exists` checks give a friendly message in the common case.
- `passwordEncoder.encode(...)` is the only place the raw password is ever touched. After this line, it is gone.
- The `try/catch` handles the rare race: two people register the same email in the same millisecond, both pass the checks, and the database's unique constraint rejects the second. The constraint is your real safety net.

One honest trade-off: telling someone "email already in use" reveals that the email has an account. Most apps accept this for usability. Very sensitive apps respond with a neutral message and send an email instead.

### The UserDetailsService, the lookup at login

First the wrapper that turns your entity into something Spring understands:

```java
public class AppUserDetails implements UserDetails {

    private final UserCredentials credentials;

    public AppUserDetails(UserCredentials credentials) { this.credentials = credentials; }

    public UserCredentials getCredentials() { return credentials; }

    @Override public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + credentials.getRole().name()));
    }
    @Override public String  getPassword()  { return credentials.getPasswordHash(); }
    @Override public String  getUsername()  { return credentials.getEmail(); }   // email is the canonical login name
    @Override public boolean isEnabled()               { return credentials.isEnabled(); }
    @Override public boolean isAccountNonLocked()      { return !credentials.isLocked(); }
    @Override public boolean isAccountNonExpired()     { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
}
```

Then the service itself:

```java
@Service
@RequiredArgsConstructor
public class AppUserDetailsService implements UserDetailsService {

    private final UserCredentialsRepository repository;

    @Override
    public UserDetails loadUserByUsername(String identifier) throws UsernameNotFoundException {
        String id = identifier.trim().toLowerCase();
        return repository.findByEmailOrUsername(id, id)
                .map(AppUserDetails::new)
                .orElseThrow(() -> new UsernameNotFoundException("Invalid credentials"));
    }
}
```

Walkthrough: Spring Security calls `loadUserByUsername` with whatever the person typed in the login box. The method name says "username", but it is just "the identifier." You pass the same text as both email and username, so one query supports both styles of login.

Notice what this class does **not** do: it does not check the password. It only _loads_. The password comparison is `DaoAuthenticationProvider`'s job, which is why the `UserDetails` carries the hash.

### Account flags: free checks you get for `enabled` and `locked`

Because `AppUserDetails` reports `isEnabled()` and `isAccountNonLocked()`, `DaoAuthenticationProvider` checks them automatically and throws the right exception. You write no `if` statements.

## Part 5: Creating the AuthenticationManager

`AuthenticationManager` is an interface with one method: `authenticate(Authentication)`. Its usual implementation, `ProviderManager`, holds a list of `AuthenticationProvider`s and asks each one "can you handle this?". For username and password, the provider is `DaoAuthenticationProvider`, which uses your `UserDetailsService` and `PasswordEncoder`.

You have two ways to create it.

**Option A: let Spring build it (least code)**

```java
@Bean
public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
    return config.getAuthenticationManager();
}
```

Spring Boot notices that your app has one `UserDetailsService` bean and one `PasswordEncoder` bean, builds a `DaoAuthenticationProvider` from them, and wraps it in a `ProviderManager`. This is the method from your JWT lab.

**Option B: build it yourself (shows every piece)**

```java
@Bean
public AuthenticationProvider authenticationProvider(AppUserDetailsService userDetailsService,
                                                     PasswordEncoder passwordEncoder) {
    DaoAuthenticationProvider provider = new DaoAuthenticationProvider(userDetailsService);
    provider.setPasswordEncoder(passwordEncoder);
    return provider;
}

@Bean
public AuthenticationManager authenticationManager(AuthenticationProvider provider) {
    return new ProviderManager(provider);
}
```

Walkthrough: the first bean wires the two helpers into the provider. The second wraps the provider in a manager. (Passing the `UserDetailsService` to the constructor is the form current Spring Security versions expect. If your IDE says the constructor doesn't exist, you are on an older 6.x, so use the no-arg constructor plus `setUserDetailsService(...)`.)

I would start with Option B while you are learning, because you can _see_ the chain. Switch to A later if you want less code.

### Using it: the login method

```java
public AuthResponse login(LoginRequest req) {
    Authentication auth = authenticationManager.authenticate(
        new UsernamePasswordAuthenticationToken(
            req.identifier().trim().toLowerCase(), req.password()));

    AppUserDetails principal = (AppUserDetails) auth.getPrincipal();
    return new AuthResponse(jwtService.generateToken(principal));
}
```

The token you pass in is _unauthenticated_ (just identifier plus password). The one that comes back is _authenticated_ (principal plus authorities). If anything is wrong, an exception is thrown and the next line never runs.

### Which exception means what

|Exception|Cause|Reply|
|---|---|---|
|`BadCredentialsException`|Wrong password **or** unknown user (Spring hides "user not found" by converting it to this)|401, "Invalid credentials"|
|`DisabledException`|`isEnabled()` is false|403, "Account disabled"|
|`LockedException`|`isAccountNonLocked()` is false|403, "Account locked"|

Handle them in your `@RestControllerAdvice`. Always give the same message for wrong password and unknown user, so attackers cannot test which emails exist.

## Part 6: Quick checks that each piece works

1. Register with a bad email. You should get a 400 with your message (DTO validation).
2. Register a valid user, then look at the `password_hash` column in PostgreSQL. It should start with `{bcrypt}$2a$`.
3. Register the same email again. You should get your duplicate error.
4. Log in with the email, then with the username. Both should succeed.
5. Log in with a wrong password. You should get 401 with the generic message.

## Pitfalls to avoid

- **Logging or returning the password**, even hashed. Never put the entity in a response, and be careful with Lombok `@ToString` on the entity (exclude `passwordHash`).
- **Hashing twice.** If the entity or mapper also encodes, you will store a hash of a hash and login will always fail.
- **Skipping normalization.** It leads to duplicate accounts and "my login doesn't work" bugs.
- **Trusting the exists-check alone.** Keep the database constraints.

## A related concept in brief: email verification

Right now anyone can register with someone else's email. To fix that, create the account with `enabled = false`, generate a random token, store it with an expiry date, and email the person a link containing it. When they click, you find the token, set `enabled = true`, and delete the token. Because `DaoAuthenticationProvider` already checks `isEnabled()`, unverified users simply cannot log in, with no extra code in the login path.




[[Spring Security]]