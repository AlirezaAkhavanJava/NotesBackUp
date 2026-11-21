
The **algorithm version** and the **cost factor** are the first two fields of a bcrypt hash. Together they answer two questions a verifier needs before it can check a password: _which edition of bcrypt made this hash_, and _how many rounds of work did it use_. This time I'll go deeper than the quick answer, covering what happens inside bcrypt, why several versions exist, and how Spring Security reads and uses both fields.

Both fields are stored inside the hash string, next to the salt. That single design choice is why you can change your settings later without breaking any existing user, and why your database needs only one `password` column.

## 1. The full anatomy of a bcrypt string

```
$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
```

|position|text|length|meaning|
|---|---|---|---|
|1|`$2a$`|4|algorithm version|
|2|`10$`|3|cost factor, always two digits|
|3|`N9qo8uLOickgx2ZMRZoMye`|22|salt (16 bytes, Base64-style)|
|4|`IjZAgcfl7p92ldGxad68LJZdL17lhWy`|31|the hash itself (23 bytes, Base64-style)|

The total is always **60 characters**. The cost is zero-padded, so cost 4 appears as `$04$`.

You can pull the fields apart yourself:

```java
String hash = new BCryptPasswordEncoder().encode("password123");

String[] parts = hash.split("\\$");          // ["", "2a", "10", "N9qo...rest"]
String version = parts[1];                   // "2a"
int cost       = Integer.parseInt(parts[2]); // 10
String salt    = parts[3].substring(0, 22);  // first 22 chars
String digest  = parts[3].substring(22);     // remaining 31 chars
```

- `hash.split("\\$")` cuts at every `$`. The string starts with `$`, so index 0 is an empty string.
- `parts[1]` and `parts[2]` are the version and the cost.
- `parts[3]` holds the salt and the digest glued together, so you slice at character 22.

Spring does the same thing with a regular expression. The pattern in `BCryptPasswordEncoder` is essentially:

```java
\A\$2(a|y|b)?\$(\d\d)\$[./0-9A-Za-z]{53}
```

Read it piece by piece: `$2` then an optional `a`, `y` or `b`, then `$`, then **two digits** (the cost), then `$`, then exactly **53** characters from bcrypt's alphabet (22 salt + 31 hash). If a stored string does not match this shape, `matches()` logs a warning ("Encoded password does not look like BCrypt") and returns `false`. This is a common reason for failed logins when someone stores a plain-text or truncated value.

## 2. The cost factor, from the inside

To understand cost, you need to see what bcrypt actually does. Bcrypt is built on the Blowfish cipher, and it replaces Blowfish's normal key setup with a deliberately expensive one called **Eksblowfish** ("expensive key schedule Blowfish"). In pseudocode:

```
state = InitState()                      // Blowfish's starting tables
state = ExpandKey(state, salt, password) // mixes salt + password into the state

repeat 2^cost times:
    state = ExpandKey(state, 0, password)
    state = ExpandKey(state, 0, salt)

ciphertext = encrypt "OrpheanBeholderScryDoubt" 64 times using state
hash = ciphertext (first 23 bytes)
```

Line by line:

- `InitState()` loads Blowfish's constant tables.
- The first `ExpandKey` mixes your salt and password into those tables. This is the only step where the salt is used directly, so two different salts give two completely different states.
- The `repeat` loop is the cost. `ExpandKey` is slow by design, because it rewrites the cipher's internal tables. The loop runs `2^cost` times, so cost 10 means 1,024 repetitions and cost 12 means 4,096.
- The final step encrypts a fixed 24-byte text many times with the finished state. The result is your hash.

That explains the table you saw before, with the doubling written out:

|cost|`2^cost` repetitions|relative work|
|---|---|---|
|4|16|tiny (the minimum Spring accepts)|
|10|1,024|1x (Spring's default)|
|12|4,096|4x|
|14|16,384|16x|
|31|2,147,483,648|the maximum, far too slow for real use|

Because the work is memory-table rewriting, it is awkward to speed up on a GPU. This is why bcrypt resists mass guessing better than a plain fast hash, though newer algorithms such as Argon2 resist it further by also demanding lots of memory.

### What you control in Spring

```java
new BCryptPasswordEncoder();      // cost 10
new BCryptPasswordEncoder(12);    // cost 12
new BCryptPasswordEncoder(3);     // throws IllegalArgumentException (valid range is 4 to 31)
```

### Changing the cost per environment (link to your Spring Profiles lesson)

Tests that register hundreds of users get slow at cost 12. You can use the profile feature to keep tests fast and production strong:

```java
@Configuration
public class PasswordConfig {

    @Bean
    @Profile("dev")
    public PasswordEncoder devPasswordEncoder() {
        return new BCryptPasswordEncoder(4);
    }

    @Bean
    @Profile("prod")
    public PasswordEncoder prodPasswordEncoder() {
        return new BCryptPasswordEncoder(12);
    }
}
```

Exactly one of these beans exists, depending on `spring.profiles.active`, and `@Autowired` injects whichever it is. Alternatively, bind the number from your properties with `@ConfigurationProperties`, so operations can raise it without touching code.

### Old hashes keep working, and you can upgrade them

```java
var weak   = new BCryptPasswordEncoder(4);
var strong = new BCryptPasswordEncoder(12);

String old = weak.encode("pw");            // "$2a$04$..."

strong.matches("pw", old);                 // true, cost 4 is read from the string
strong.upgradeEncoding(old);               // true, stored cost is lower than 12
```

- `matches` ignores the encoder's own cost and uses the `04` inside the stored hash. This is what keeps old users logged in when you raise your setting.
- `upgradeEncoding` compares the stored cost with the encoder's cost and returns `true` when the stored one is **lower**. When it is `true`, you re-hash during login (while you still hold the raw password) and save the new hash. If your `UserDetailsService` also implements `UserDetailsPasswordService`, Spring Security's `DaoAuthenticationProvider` does this step automatically.

## 3. The algorithm version, and why there are several

The version marker exists because bcrypt's _specification_ was fixed several times. Each fix changed how some inputs are turned into bytes, which changes the resulting hash. A verifier must know which behaviour created a hash, or a correct password would fail.

|marker|year|what changed|
|---|---|---|
|`$2$`|1999|the original. It did not define how to handle non-ASCII text or a trailing null terminator.|
|`$2a$`|2001|the spec was revised: passwords must be UTF-8 encoded and a null terminator included.|
|`$2x$`|2011|a label for hashes made by a **buggy** version of the PHP-based `crypt_blowfish` library, which mishandled characters above ASCII (sign extension). It exists so those old hashes can still be verified the buggy way.|
|`$2y$`|2011|the same library's label for hashes made **after** that bug was fixed. For correct input it gives the same result as `$2a$`.|
|`$2b$`|2014|OpenBSD fixed a bug with very long passwords (a counter that wrapped around past 255 characters).|

What this means in practice:

- For normal passwords, `$2a$`, `$2y$` and `$2b$` all give the same result, and Spring's regex accepts all three.
- The markers `$2$` and `$2x$` are not accepted by Spring's pattern, so such hashes (for example from an old PHP system) must be migrated differently.
- Spring writes `$2a$` by default. You can choose another:

```java
new BCryptPasswordEncoder(BCryptPasswordEncoder.BCryptVersion.$2B, 12);
```

Hashes with a different version prefix still verify, because the version comes from the stored string.

### The 72-byte limit applies to every version

Bcrypt only reads the first 72 bytes of the password (the key schedule's key size limit). Two passwords that share their first 72 bytes produce the same hash. Most users never type that much, but if you allow long passphrases, remember the limit. A common workaround is pre-hashing the password with SHA-256 and Base64-encoding it before bcrypt, though that has its own pitfalls, so consider Argon2 instead if long inputs matter.

## 4. How it all fits into the Spring Security login flow

From your earlier lessons: the login request builds a `UsernamePasswordAuthenticationToken`, the `AuthenticationManager` hands it to `DaoAuthenticationProvider`, and that provider loads your `UserDetails` and calls `passwordEncoder.matches(raw, storedHash)`.

Inside `matches` for bcrypt, the order is:

1. Check the stored string against the regex (version, cost, 53 characters).
2. Read the **salt** and **cost** from the string.
3. Run Eksblowfish with `2^cost` repetitions on the raw password and that salt.
4. Compare the new hash with the stored one.

Version and cost are the setup values for that computation, and the salt is the third. All three travel together in the string, so verification never needs any other input.

## 5. Common mistakes

- **Cost too low in production.** Cost 4 is only for tests. OWASP's guidance is a work factor of at least 10 for bcrypt, and many teams use 12.
- **Cost too high.** At cost 14 or more, each login can take a second or longer, and many parallel logins can overload your CPU.
- **A password column shorter than 60 characters**, which truncates the hash. The login then fails with a "does not look like BCrypt" warning.
- **Editing the stored string by hand**, for example to "change" `10` to `12`. The hash was computed with 1,024 repetitions, so the number is just a label. Changing it makes verification fail.
- **Assuming the version changes how strong the hash is.** `$2b$` versus `$2a$` fixes edge cases, and it does not make normal passwords harder to crack. Only the cost does that.

## Related concepts, briefly

- **Blowfish and Eksblowfish:** Blowfish is a block cipher. Eksblowfish keeps the same cipher and makes only its key setup expensive and salt-aware, which is the actual secret behind bcrypt.
- **Argon2 parameters:** instead of one cost number, Argon2 takes memory size, iteration count and parallelism, so it makes attackers pay for memory as well as time.
- **PBKDF2 iteration count:** the same role as bcrypt's cost, but a plain number (for example 210,000) instead of an exponent, so doubling the work means doubling the number.

## Quick recap

The version is a label for which bcrypt specification produced the hash, because the algorithm's byte handling was corrected several times. The cost is an exponent: the key setup repeats `2^cost` times, so each +1 doubles the work. Both sit in the hash string beside the salt, so Spring reads them back during `matches()`, old hashes keep verifying after you change your settings, and `upgradeEncoding()` tells you which users to re-hash at their next login.


[[Spring Framework]]