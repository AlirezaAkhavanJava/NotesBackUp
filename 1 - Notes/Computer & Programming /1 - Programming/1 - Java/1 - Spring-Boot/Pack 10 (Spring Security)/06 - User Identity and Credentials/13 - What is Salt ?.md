
A **salt** is a random value that you generate for each user and mix into their password before hashing it. The hash then depends on the password and the salt together, so two users with the same password get completely different stored hashes. In Spring Boot you almost never handle the salt yourself: a `PasswordEncoder` such as `BCryptPasswordEncoder` creates a fresh random salt on every `encode()` call and stores it inside the hash string.

This matters because a hash alone is not enough protection. Hashing is deterministic, so `SHA-256("password123")` always gives the same output. If your database leaks, an attacker can precompute hashes of common passwords once and compare them against every row. Salting breaks that attack, and you get it for free from the encoders Spring Security gives you.

## What goes wrong without a salt

Imagine three users, hashed with plain SHA-256 and no salt:

|user|password|stored hash (shortened)|
|---|---|---|
|ali|`password123`|`ef92b7...`|
|sara|`password123`|`ef92b7...`|
|omar|`Xk9#mP2q`|`a41c0e...`|

Two problems are visible right away:

1. Ali and Sara have identical hashes, so anyone reading the table knows they share a password. Crack one and you have cracked both.
2. The hash `ef92b7...` is the same for every system in the world that hashes `password123` with SHA-256. An attacker can use a **rainbow table** (a giant precomputed list of password → hash pairs) and look it up instantly.

Now the same users with a random salt per user:

|user|password|salt|stored = hash(salt + password)|
|---|---|---|---|
|ali|`password123`|`q8Zr..`|`7d03fa...`|
|sara|`password123`|`Lm41..`|`c9b2e8...`|
|omar|`Xk9#mP2q`|`T0vw..`|`5e61d4...`|

Ali and Sara now have different hashes. A precomputed table is useless, because the attacker would need a separate table for every possible salt. They must guess passwords one user at a time.

Notice what a salt does **not** do. It is not secret, and you store it right next to the hash. It does not make a weak password strong. It only removes the shortcuts (rainbow tables and "find duplicates").

## How salting works, step by step

```java
// Registration
salt   = randomBytes(16);                     // new for every user
hash   = slowHash(salt + password);
store(salt, hash);

// Login
(salt, hash) = loadFromDatabase(email);
candidate    = slowHash(salt + typedPassword); // reuse the stored salt
return candidate equals hash;
```

The salt must be **random** (from `SecureRandom`, not `Random`), **unique per password**, and **long enough** (16 bytes is a common choice). The important part is that login reuses the same salt that registration generated. That is why it has to be stored.

## Implementing it in Spring Boot

Here is the good news: you do not write the code above. Spring Security's encoders do it for you.

### Step 1: Declare a PasswordEncoder bean

```java
@Configuration
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

- `@Configuration` marks the class as a source of beans, the same configuration class you already know.
- `@Bean` registers the returned object in the container, so you can inject `PasswordEncoder` anywhere with `@Autowired` or constructor injection.
- `BCryptPasswordEncoder` generates a random 16-byte salt for every `encode()` call, and runs the slow bcrypt algorithm (cost factor 10 by default).

### Step 2: Encode the password when you register a user

```java
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public void register(RegisterRequest request) {
        User user = new User();
        user.setEmail(request.email());
        user.setPassword(passwordEncoder.encode(request.password()));
        userRepository.save(user);
    }
}
```

Line by line:

- `private final PasswordEncoder passwordEncoder;` is constructor injection (Lombok's `@RequiredArgsConstructor` writes the constructor). Spring supplies the bean from Step 1.
- `request.password()` is the raw password from your register record DTO. It is never saved.
- `passwordEncoder.encode(...)` creates a new salt, hashes, and returns one string containing everything. That string is what you save in the `password` column.

### Step 3: Let Spring Security verify it at login

You do not call `matches()` yourself in the normal flow. When you expose the `PasswordEncoder` bean, Spring Boot's `DaoAuthenticationProvider` picks it up and uses it inside the `AuthenticationManager` (the same manager from your JWT lab):

```java
authenticationManager.authenticate(
    new UsernamePasswordAuthenticationToken(request.email(), request.password())
);
```

Behind that call, the provider loads your `UserDetails`, then runs `passwordEncoder.matches(rawPassword, storedHash)`. If it returns `true`, the `Authentication` object is marked authenticated, and your `JwtService` can issue the token. Salting sits at the very start of that chain and the rest of your JWT flow does not change.

If you need to check a password manually, for example in a "change password" feature:

```java
boolean ok = passwordEncoder.matches(oldPasswordFromUser, user.getPassword());
```

`matches` reads the salt out of the stored hash, hashes the typed password with it, and compares. You never pass the salt in.

### Step 4: Make the column big enough

```java
@Column(nullable = false, length = 100)
private String password;
```

A bcrypt hash is always 60 characters. If you use `DelegatingPasswordEncoder` (below) it adds a prefix like `{bcrypt}`, so 100 is a safe length. A too-short column silently truncates or throws, and then nobody can log in.

## Where is the salt stored? Inside the hash

Because the salt lives inside the string, you do not need a `salt` column in your entity. Here is a real bcrypt output:

```
$2a$10$N9qo8uLOickgx2ZMRZoMye IjZAgcfl7p92ldGxad68LJZdL17lhWy
```

|part|meaning|
|---|---|
|`$2a$`|bcrypt algorithm version|
|`10$`|cost factor (2^10 = 1,024 rounds)|
|`N9qo8uLOickgx2ZMRZoMye`|the **22-character salt** (Base64 of 16 bytes)|
|the rest|the 31-character hash|

(The space above is only for readability. The real string has no space.)

Run the same password through `encode()` twice and the outputs differ:

```java
String a = encoder.encode("password123");
String b = encoder.encode("password123");

System.out.println(a.equals(b));                       // false, different salts
System.out.println(encoder.matches("password123", a)); // true
System.out.println(encoder.matches("password123", b)); // true
```

That is salting in one test: different hashes, both valid.

## Other encoders you can choose

```java
new Argon2PasswordEncoder(16, 32, 1, 1 << 14, 3);          // needs BouncyCastle
Pbkdf2PasswordEncoder.defaultsForSpringSecurity_v5_8();
SCryptPasswordEncoder.defaultsForSpringSecurity_v5_8();
```

All of them salt automatically. They differ in how they make hashing slow and expensive (bcrypt is CPU-bound, scrypt and Argon2 also use memory, which hurts GPU attackers more). For most apps, BCrypt is a solid default.

### DelegatingPasswordEncoder (recommended for long-lived apps)

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return PasswordEncoderFactories.createDelegatingPasswordEncoder();
}
```

This stores hashes like `{bcrypt}$2a$10$...`. The prefix tells Spring which algorithm to use when verifying. Later you can switch the default to Argon2 and old users still log in. You can upgrade them on their next login using `encoder.upgradeEncoding(hash)`.

## Doing it by hand (to see what the encoder hides)

You should not do this in production, but it shows the idea:

```java
SecureRandom random = new SecureRandom();
byte[] salt = new byte[16];
random.nextBytes(salt);

PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt, 210_000, 256);
byte[] hash = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
                              .generateSecret(spec).getEncoded();
```

- `SecureRandom` gives cryptographically strong random bytes for the salt.
- `PBEKeySpec(password, salt, iterations, keyLength)` holds the inputs. 210,000 iterations is the slow part.
- You would then have to store `salt` and `hash` yourself (two columns), and compare in constant time. That extra work is exactly what `PasswordEncoder` removes.

## Common mistakes

- **Using `MessageDigest` / plain SHA-256 or MD5 for passwords.** These are fast, so even with a salt an attacker can try billions of guesses per second. Use a slow, purpose-built encoder.
- **One global salt for everyone.** It stops precomputed tables but still leaves duplicates detectable. The salt must be unique per password.
- **Using `NoOpPasswordEncoder`.** It stores plain text and is deprecated. Never ship it.
- **Calling `encode()` and comparing with `equals()`.** Because the salt changes each time, this always fails. Use `matches()`.
- **Encoding the password twice**, once in the service and once in a setter or mapper, then wondering why login fails. Encode in exactly one place.
- **Forgetting the 72-byte bcrypt limit.** Bcrypt ignores everything after 72 bytes of the password, which matters if you allow very long passphrases.

## Related concepts, briefly

- **Pepper:** a secret value mixed into the hash but kept outside the database (for example in an environment variable). Unlike a salt, it is secret and shared across users, so a leaked database alone is not enough to crack hashes.
- **Key stretching / work factor:** deliberately making each hash slow (bcrypt's cost, PBKDF2's iterations). Salt stops precomputation, and stretching makes each individual guess expensive. You need both.
- **Rainbow table:** a precomputed lookup table of password → hash pairs. Unique salts make it useless.

## Quick recap

Salt is a random, per-password value stored with the hash. It defeats rainbow tables and hides duplicate passwords. In Spring Boot, expose one `PasswordEncoder` bean (BCrypt or the delegating one), call `encode()` once when saving the password, and let the authentication flow call `matches()` for you. You never create, store or pass a salt yourself.



[[Spring Security]]