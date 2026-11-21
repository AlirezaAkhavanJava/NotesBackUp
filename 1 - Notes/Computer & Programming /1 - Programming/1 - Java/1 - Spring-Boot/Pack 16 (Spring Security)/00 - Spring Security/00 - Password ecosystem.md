A password ecosystem is every place a password touches your system, from the moment it arrives in a request body to the moment its hash sits in a database column, and everything that happens in between and afterwards: validation, hashing, login checks, upgrades, resets, and what you refuse to log. A secure hash function is one piece. Most real leaks come from the other pieces: a password printed in a log line, a hash returned in JSON, an unlimited login endpoint, or a reset token that never expires.

You already know why salt and slow hashing exist (your salt, rainbow table and bcrypt cost lessons). This lesson doesn't repeat that theory. It builds the whole pipeline in the order the data travels, and ties together your `User` entity, DTO, mapper, `UserDetails`, `AuthenticationManager` and exception handler lessons.

## The map

|Stage|Where|Job|
|---|---|---|
|1. Storage|Entity + Flyway column|Hold only the hash, never the password|
|2. Input|Request DTO + validation|Accept good passwords, reject abusive ones|
|3. Hashing|`PasswordEncoder` bean|Salt + slow hash, replaceable over time|
|4. Use|Service + `AuthenticationManager`|Register, log in, change|
|5. Upgrade|`UserDetailsPasswordService`|Re-hash old hashes when users log in|
|6. Defense|Throttling, uniform errors|Make guessing expensive|
|7. Recovery|Reset-token flow|Replace a password safely|

## 1. Storage: the entity and the column

```java
@Entity
@Table(name = "users")
@Getter @Setter
public class User extends Auditable implements UserDetails {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "users_seq_gen")
    @SequenceGenerator(name = "users_seq_gen", sequenceName = "users_seq", allocationSize = 50)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @ToString.Exclude
    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(name = "password_changed_at", nullable = false)
    private Instant passwordChangedAt = Instant.now();

    @Column(name = "failed_login_attempts", nullable = false)
    private int failedLoginAttempts;

    @Column(name = "locked_until")
    private Instant lockedUntil;

    @Override public String getPassword() { return passwordHash; }
    @Override public String getUsername() { return email; }
    @Override public boolean isAccountNonLocked() {
        return lockedUntil == null || lockedUntil.isBefore(Instant.now());
    }
    // authorities and the other UserDetails methods as in your UserDetails lesson
}
```

Decisions worth noticing:

- The field is `passwordHash`, not `password`. The name reminds everyone that the entity never holds a plain password.
- `@ToString.Exclude` keeps the hash out of any `toString()` (and so out of logs).
- `getPassword()` exists only because the `UserDetails` interface demands that name. Spring Security calls it to get the hash to compare against.
- `passwordChangedAt` lets you reject tokens issued before a password change. Without it, a stolen JWT keeps working after the victim changes the password.
- The failed-attempt and lock fields support stage 6.

The column must hold the hash plus any prefix, so don't size it for bcrypt's 60 characters only:

```sql
-- V6__users_password.sql
ALTER TABLE users
    ADD COLUMN password_hash          TEXT        NOT NULL,
    ADD COLUMN password_changed_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    ADD COLUMN failed_login_attempts  INT         NOT NULL DEFAULT 0,
    ADD COLUMN locked_until           TIMESTAMPTZ;
```

`TEXT` is fine here. The prefix and a longer Argon2 hash (roughly 100 to 120 characters) won't fit a tight `VARCHAR(60)`.

## 2. Input: request DTOs

```java
public record RegisterRequest(
    @NotBlank @Email String email,
    @NotBlank @Size(min = 12, max = 128) String password
) {
    @Override
    public String toString() {
        return "RegisterRequest[email=" + email + ", password=***]";
    }
}
```

Three details:

- **The `toString()` override matters.** A record generates a `toString()` containing every component, so a single `log.info("{}", request)` would print the password. Override it on every DTO that carries one.
- **Length rules, not composition rules.** Current guidance (NIST, OWASP) favors a minimum length and no "must contain a symbol" rules, which push people toward predictable patterns like `Password1!`. Optionally reject passwords that appear in known breach lists.
- **A maximum length protects you.** Slow hashing costs CPU (and, with Argon2, memory) per request, so an attacker sending a 10 MB "password" is a denial-of-service attack. With bcrypt, set the maximum to 72 bytes, because bcrypt only reads the first 72 bytes (non-ASCII characters count as several).

The response DTO never has a password field at all. In MapStruct, make the entity side explicit:

```java
@Mapping(target = "passwordHash", ignore = true)
@Mapping(target = "id", ignore = true)
User toEntity(RegisterRequest request);
```

The service sets the hash by hand, so a mapper can never copy a raw password into the hash column by accident.

## 3. Hashing: the PasswordEncoder bean

Salt and slowness are built into the algorithms, so you don't implement them yourself. Bcrypt, Argon2, scrypt and PBKDF2 each generate a random salt for every `encode()` call and store it inside the output string. That's why you need no salt column, and why two users with the same password get different hashes. The slow part is a tunable cost, which is your defense against GPU guessing.

Which algorithm:

|Algorithm|Spring class|Slows attackers by|Notes|
|---|---|---|---|
|bcrypt|`BCryptPasswordEncoder`|CPU time|Battle-tested, 72-byte limit, no extra dependency|
|Argon2id|`Argon2PasswordEncoder`|CPU **and memory**|Modern first choice; needs the Bouncy Castle library on the classpath|
|scrypt|`SCryptPasswordEncoder`|CPU and memory|Fine, less common|
|PBKDF2|`Pbkdf2PasswordEncoder`|CPU time|Pick it when a standard (FIPS) requires it|

Memory-hardness is why Argon2id is preferred: GPUs have lots of cores but limited memory per core, so requiring memory per guess blunts them in a way pure CPU cost can't.

Don't pick one encoder and hard-wire it. Use `DelegatingPasswordEncoder`, which writes the algorithm name in front of the hash (`{argon2}$argon2id$...`) so several algorithms can coexist in one table:

```java
@Bean
PasswordEncoder passwordEncoder() {
    Map<String, PasswordEncoder> encoders = new HashMap<>();
    encoders.put("argon2", Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8());
    encoders.put("bcrypt", new BCryptPasswordEncoder(12));

    DelegatingPasswordEncoder encoder = new DelegatingPasswordEncoder("argon2", encoders);
    encoder.setDefaultPasswordEncoderForMatches(new BCryptPasswordEncoder());  // old hashes with no prefix
    return encoder;
}
```

- `"argon2"` is the algorithm used for every **new** hash.
- `bcrypt` stays registered so existing `{bcrypt}...` hashes still verify.
- `setDefaultPasswordEncoderForMatches` handles legacy rows stored without any prefix (plain `$2a$...`), common when you migrate an older system.

**Tuning the cost.** Don't copy numbers from a tutorial. Measure on your production-class hardware and aim for something noticeable but affordable per login, commonly in the low hundreds of milliseconds:

```java
long start = System.nanoTime();
encoder.encode("benchmark-password");
System.out.println((System.nanoTime() - start) / 1_000_000 + " ms");
```

For bcrypt each `+1` of strength doubles the time (the cost factor from your bcrypt lesson). For Argon2id, OWASP's published minimum is around 19 MiB of memory, 2 iterations, parallelism 1, and the Spring defaults sit near it. Check their current numbers when you decide, then raise them as your hardware allows.

## 4. Use: register, log in, change

**Register.** Normalize the email, check duplicates, hash, save:

```java
@Transactional
public UserResponse register(RegisterRequest request) {
    String email = request.email().trim().toLowerCase();
    if (users.existsByEmail(email)) {
        throw new DuplicateResourceException("Email already registered");
    }
    User user = mapper.toEntity(request);
    user.setEmail(email);
    user.setPasswordHash(passwordEncoder.encode(request.password()));
    return mapper.toResponse(users.save(user));
}
```

Hash exactly once, in the service. The controller passes the DTO through untouched, and the entity never sees a raw password. As in your return-types lesson, the unique constraint is still the real guard against two simultaneous signups.

**Log in.** Let Spring Security do the comparison:

```java
Authentication auth = authenticationManager.authenticate(
        new UsernamePasswordAuthenticationToken(request.email(), request.password()));
```

Behind that call, `DaoAuthenticationProvider` loads your `UserDetails`, then calls `passwordEncoder.matches(raw, hash)`. Never compare with `equals`, because the hash of the same password is different each time. Two behaviors you get for free: when the user doesn't exist, it still hashes a dummy password so response time doesn't reveal which emails are registered, and it throws one `BadCredentialsException` for "no such user" and "wrong password" alike.

**Change password.**

```java
@Transactional
public void changePassword(User user, ChangePasswordRequest request) {
    if (!passwordEncoder.matches(request.currentPassword(), user.getPasswordHash())) {
        throw new BadCredentialsException("Current password is incorrect");
    }
    user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
    user.setPasswordChangedAt(Instant.now());   // invalidates older tokens
}
```

It requires the current password (so a hijacked session can't silently take over the account), and it records the change time. Your JWT filter should then refuse tokens whose `iat` claim is earlier than `passwordChangedAt`.

## 5. Upgrade: moving old hashes forward

Algorithms and costs age. You can't re-hash everyone in one go, because you don't know their passwords. The moment you _do_ know a password is during a successful login. Spring supports this directly:

```java
@Service
@RequiredArgsConstructor
public class AppUserDetailsService implements UserDetailsService, UserDetailsPasswordService {

    private final UserRepository users;

    @Override
    public UserDetails loadUserByUsername(String email) {
        return users.findByEmail(email.toLowerCase())
                    .orElseThrow(() -> new UsernameNotFoundException("Invalid credentials"));
    }

    @Override
    @Transactional
    public UserDetails updatePassword(UserDetails user, String newEncodedPassword) {
        User entity = users.findByEmail(user.getUsername()).orElseThrow();
        entity.setPasswordHash(newEncodedPassword);   // already encoded by Spring
        entity.setPasswordChangedAt(Instant.now());
        return entity;
    }
}
```

After a successful match, the provider asks `encoder.upgradeEncoding(storedHash)`. It returns `true` when the hash uses a non-default algorithm (say `{bcrypt}` while your default is now `argon2`) or a weaker cost. In that case Spring re-encodes the password it just verified and calls `updatePassword`. In the standard Boot setup a `UserDetailsPasswordService` bean is picked up automatically. If you build your own `DaoAuthenticationProvider`, call `setUserDetailsPasswordService`. Result: raise your cost or switch algorithms, and active users migrate silently on their next login.

## 6. Defense: make guessing expensive

Slow hashing slows attackers who stole the table. Online guessing against your login endpoint needs its own limits:

```java
@Component
@RequiredArgsConstructor
class LoginAttemptListener {

    private final UserRepository users;

    @EventListener
    @Transactional
    void onFailure(AuthenticationFailureBadCredentialsEvent event) {
        users.findByEmail(event.getAuthentication().getName().toLowerCase()).ifPresent(u -> {
            u.setFailedLoginAttempts(u.getFailedLoginAttempts() + 1);
            if (u.getFailedLoginAttempts() >= 5) {
                u.setLockedUntil(Instant.now().plus(Duration.ofMinutes(15)));
            }
        });
    }

    @EventListener
    @Transactional
    void onSuccess(AuthenticationSuccessEvent event) {
        users.findByEmail(event.getAuthentication().getName().toLowerCase())
             .ifPresent(u -> u.setFailedLoginAttempts(0));
    }
}
```

`isAccountNonLocked()` in your entity makes Spring Security refuse a locked account. Two cautions: a hard lock lets an attacker lock out real users on purpose, so prefer short, growing delays; and also rate-limit by IP address at the gateway or with a filter. Every login attempt costs you a full hash, so unthrottled endpoints are also a CPU-exhaustion risk.

Keep the error message identical for every failure: "Invalid email or password". Your `@RestControllerAdvice` should turn `BadCredentialsException` into a `401` `ProblemDetail` with that one message. Always serve everything over HTTPS; hashing doesn't protect a password sent in plain text.

## 7. Recovery: password reset

Never email a password, and never make reset tokens guessable.

```java
public void requestReset(String email) {
    users.findByEmail(email.trim().toLowerCase()).ifPresent(user -> {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);

        tokens.save(new ResetToken(sha256(token), user.getId(), Instant.now().plus(Duration.ofMinutes(30))));
        mailer.sendResetLink(user.getEmail(), token);
    });
    // always return the same response, whether or not the email exists
}
```

- The token comes from `SecureRandom` (256 bits), so it can't be guessed.
- You store only its SHA-256 hash, just like a password. A database leak then can't be used to reset accounts. A fast hash is fine here because the token is random and high-entropy, unlike a human password.
- It expires (about 30 minutes) and is single-use: mark it used when it succeeds.
- On submit, validate the token, then call the same `encode` path as registration, set `passwordChangedAt`, and delete the user's other tokens.
- The request endpoint answers identically for unknown emails, so it can't be used to discover who has an account.

## Things that never belong in the system

- A password or hash in a log line, a `toString()`, a response, an exception message, a URL, or a JWT claim. Watch request-body logging filters and `DEBUG` loggers especially.
- Reversible encryption instead of hashing, or a fast hash (`MD5`, `SHA-256` alone) for passwords.
- Calling `encode()` twice (hashing a hash) or comparing hashes with `equals`.
- Your own custom salt code or your own algorithm.

## Related concepts, briefly

- **Pepper:** a secret value (an HMAC key) mixed in before hashing and stored outside the database, such as in a secrets manager. If only the database leaks, the attacker still lacks the pepper. The cost is rotation complexity, so add it only when you can manage the key properly.
- **Passkeys / WebAuthn and MFA:** passwords stop being the single point of failure. Spring Security 6.4+ includes WebAuthn support, and adding a second factor does more for account safety than raising a bcrypt cost.


[[Spring Security]]