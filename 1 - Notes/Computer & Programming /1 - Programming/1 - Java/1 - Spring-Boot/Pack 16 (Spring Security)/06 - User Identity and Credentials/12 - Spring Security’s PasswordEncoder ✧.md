

Everything we've covered about passwords (hashing, salting, slow algorithms) comes together in one small Spring interface. Once you know how `PasswordEncoder` works, you can add safe password storage to any Spring app in a few lines, and swap algorithms later without breaking your users.

## What it is

`PasswordEncoder` is the interface Spring Security uses whenever it needs to handle a password. It has two jobs you care about:

```java
public interface PasswordEncoder {
    String encode(CharSequence rawPassword);
    boolean matches(CharSequence rawPassword, String encodedPassword);

    default boolean upgradeEncoding(String encodedPassword) {
        return false;
    }
}
```

- **`encode`** turns a raw password into a salted, slow hash. You call it at **signup** or password change.
- **`matches`** checks whether a typed password fits a stored hash. Spring calls it at **login**.
- **`upgradeEncoding`** answers "is this stored hash out of date?" (more on this below).

Notice what's missing: there's no `decode`. The interface is one-way by design, just like hashing.

## The two methods in action

```java
PasswordEncoder encoder = new BCryptPasswordEncoder();

String hash = encoder.encode("myS3cretPassword");
// $2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy

encoder.matches("myS3cretPassword", hash); // true
encoder.matches("wrongPassword", hash);    // false
```

Two things happen for you behind the scenes:

- `encode` generates a **fresh random salt** every time, so encoding the same password twice gives two different strings.
- The salt and cost factor are **packed inside the hash string**. That's why `matches` only needs the raw password and the stored string. It reads the salt out of the hash, re-hashes the typed password, and compares.

This is also why you never use `equals` on hashes. Two correct hashes of the same password look different.

## Where Spring uses it

You rarely call `matches` yourself. You register one `PasswordEncoder` bean, and Spring's authentication machinery picks it up:

```java
@Configuration
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

Here's the flow at login:

1. The user submits a username and password.
2. Spring loads the user through your `UserDetailsService`, which includes the **stored hash**.
3. Spring's `DaoAuthenticationProvider` calls `passwordEncoder.matches(typedPassword, storedHash)`.
4. If it returns `true`, the user is authenticated.

Your own code only needs `encode`, at signup:

```java
@Service
public class RegistrationService {

    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;

    public RegistrationService(UserRepository users, PasswordEncoder passwordEncoder) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
    }

    public void register(String username, String rawPassword) {
        User user = new User();
        user.setUsername(username);
        user.setPasswordHash(passwordEncoder.encode(rawPassword)); // hash, never raw
        users.save(user);
    }
}
```

Make sure the database column is wide enough. A bcrypt hash is 60 characters, and Argon2 hashes are longer, so `VARCHAR(255)` is a comfortable choice.

## The built-in implementations

Spring ships several encoders. Here are the ones worth knowing:

|Class|Algorithm|Notes|
|---|---|---|
|`BCryptPasswordEncoder`|bcrypt|A solid, widely used default. Cost is adjustable: `new BCryptPasswordEncoder(12)`.|
|`Argon2PasswordEncoder`|Argon2|The modern recommendation. Needs the Bouncy Castle library on the classpath.|
|`SCryptPasswordEncoder`|scrypt|Memory-hard. Also needs Bouncy Castle.|
|`Pbkdf2PasswordEncoder`|PBKDF2|Use only if a standard requires it.|
|`DelegatingPasswordEncoder`|(chooses by prefix)|Lets you support several algorithms at once.|

You'll also find old classes like `NoOpPasswordEncoder`, `MessageDigestPasswordEncoder`, and `StandardPasswordEncoder`. They're **deprecated, and unsafe for real use**. `NoOpPasswordEncoder` stores plain text, which breaks Rule 1. You may see it in old tutorials. Skip it.

## Tuning the work factor

For bcrypt, the number you pass is the **cost**. Each +1 doubles the work:

```java
new BCryptPasswordEncoder();    // cost 10 (the default)
new BCryptPasswordEncoder(12);  // 4x slower than cost 10
```

A good target is a hash that takes roughly **100 to 500 milliseconds** on your production hardware. Too fast and attackers benefit. Too slow and your login endpoint becomes easy to overload. Measure on your real server, not just your laptop.

For Argon2, Spring gives you recommended defaults:

```java
PasswordEncoder encoder = Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8();
```

## The recommended choice: `DelegatingPasswordEncoder`

Here's a problem. Algorithms age. In five years you may want to move from bcrypt to something newer. But your database already holds thousands of bcrypt hashes, and you can't convert them, because you don't have the original passwords.

Spring's answer is `DelegatingPasswordEncoder`. It writes the algorithm's name as a **prefix** on every hash:

```
{bcrypt}$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
{argon2@SpringSecurity_v5_8}$argon2id$v=19$m=16384,t=2,p=1$...
```

When it verifies a password, it reads the `{prefix}`, picks the matching algorithm, and checks. When it encodes a new password, it uses your current default. Old and new hashes live side by side.

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return PasswordEncoderFactories.createDelegatingPasswordEncoder();
}
```

This factory method defaults to bcrypt for new passwords, and it can read many other formats. It's the safest starting point, and it's what Spring Security uses by default when you don't configure anything.

### The famous error

If you ever see this:

```
java.lang.IllegalArgumentException: There is no PasswordEncoder mapped for the id "null"
```

it means Spring is using a `DelegatingPasswordEncoder`, but the stored password has **no `{prefix}`**. This often happens when you insert a user by hand with a bare bcrypt string. You have two fixes:

- Store the hash with its prefix: `{bcrypt}$2a$10$...`
- Or register a specific encoder, like `new BCryptPasswordEncoder()`, so no prefix is expected.

## Upgrading old hashes at login

`upgradeEncoding` lets you improve hashes quietly over time. Say you raise bcrypt's cost from 10 to 12. Existing users still have cost-10 hashes. At their next successful login, you hold the raw password for a brief moment, so you can re-hash it with the stronger settings:

```java
if (passwordEncoder.matches(typedPassword, user.getPasswordHash())
        && passwordEncoder.upgradeEncoding(user.getPasswordHash())) {
    user.setPasswordHash(passwordEncoder.encode(typedPassword));
    users.save(user);
}
```

Spring Security can do this automatically through `UserDetailsPasswordService` if you implement it. It's an elegant way to move your whole user base to a stronger algorithm without ever asking anyone to reset a password.

## Testing it

Because hashes are salted, a test can't compare them with `assertEquals`. Test with `matches`:

```java
@Test
void passwordIsHashedAndVerifiable() {
    PasswordEncoder encoder = new BCryptPasswordEncoder();

    String hash = encoder.encode("secret");

    assertNotEquals("secret", hash);               // not stored raw
    assertTrue(encoder.matches("secret", hash));   // correct password passes
    assertFalse(encoder.matches("nope", hash));    // wrong password fails
}
```

## Mistakes to avoid

- **Creating a new encoder with a different type than the one that made the hashes.** Hashes made by one algorithm won't verify under another, unless you use the delegating encoder.
- **Calling `equals` on hashes.** Always use `matches`.
- **Encoding the password twice.** If you encode at signup and again in a JPA setter or listener, you'll hash the hash and nobody can log in.
- **Using `NoOpPasswordEncoder`** outside a throwaway demo.
- **Logging the raw password**, even at debug level.
- **Forgetting about bcrypt's 72-byte limit.** Bcrypt ignores anything past about 72 bytes, so don't pre-process long passwords in clever ways. Just accept them as they are.

## Summary

- `PasswordEncoder` is Spring Security's single interface for password hashing, with `encode` (signup) and `matches` (login). There is no decode.
- Implementations like `BCryptPasswordEncoder` and `Argon2PasswordEncoder` give you hashing, random salting, and slow work factors automatically.
- Register one as a `@Bean` and Spring uses it during login.
- `DelegatingPasswordEncoder` stores a `{prefix}` so you can change algorithms later without breaking old hashes.
- Never use `NoOpPasswordEncoder`, and never compare hashes with `equals`.





[[Spring Security]]