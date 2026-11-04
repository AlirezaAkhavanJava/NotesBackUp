

`JwtService` is the one class in your app that knows how JWTs work. It creates tokens when users log in, and it reads and checks tokens when requests arrive. Everything else, such as your login controller and your `JwtAuthenticationFilter`, only asks it simple questions: "give me a token for this user," "who does this token belong to?" and "is this token good for this user?" Keeping all the cryptography in one class means the rest of your code never touches keys, signatures or claim names.

This lesson follows the order you asked for. First, **what the class must do and why**. Then **the classes** involved, one by one. Then **a better way** to build it, with complete code and a test. I'm using your pasted code only as a list of the topics that confuse you, so nothing here is a review of it.

## Part 1: What `JwtService` must do, and why

The class has four jobs. Each one answers a question that your app has to answer.

|Job|The question|Who calls it|
|---|---|---|
|**Hold the key**|"What secret proves a token is ours?"|Used inside the class only|
|**Create a token**|"How does a logged-in user get proof of login?"|`AuthController` after login|
|**Read a token**|"Who is this token about?"|`JwtAuthenticationFilter`|
|**Validate a token**|"Is this token good for this user, right now?"|`JwtAuthenticationFilter`|

Here is how the two callers use it:

```
LOGIN                                   EVERY LATER REQUEST
AuthController                          JwtAuthenticationFilter
   │ generateToken(appUser)                │ extractUserName(token)
   ▼                                       │ isTokenValid(token, userDetails)
JwtService ──► "xxx.yyy.zzz"               ▼
                                        JwtService ──► username / true or false
```

### Why a separate class at all?

- **One place for secrets.** The key and the signing rules live in one file, so a change touches one file.
- **A small filter.** The filter only decides what to do with an answer. It never learns how a signature is computed.
- **Easy testing.** You can test `JwtService` alone, with no web server and no database.
- **Swappable.** If you later move to RSA keys, only this class changes.

### The build order, and why each step comes first

**Step 1: Create the key once, from configuration.** Every other step needs the key, so it comes first. It must be Base64 text of at least 32 random bytes, read from an environment variable, and turned into a `SecretKey` object. You do this once at startup, because the result never changes.

**Step 2: Write `generateToken`.** This puts facts about the user into the payload (who, from whom, when, until when) and signs it with the key. Do it second, because you can test it right away by printing a token.

**Step 3: Write one method that verifies and returns the claims.** This is the most important method of the class. It checks the signature and the expiry, and returns the payload only if both pass. Every read operation goes through it, so verification can't be skipped by accident.

**Step 4: Write small extract methods on top of it.** `extractUserName` and any other accessors are one-liners that ask step 3 for the claims and pick one value. A generic helper makes each new accessor a single line.

**Step 5: Write `isTokenValid`.** This decides whether the token is acceptable for a specific user. It must **never return `true` by default**. A validation method that approves everything would let anyone in, and it is the line that most deserves a test.

**Step 6: Decide who handles errors.** A bad token (forged, expired, malformed) makes the parser throw. Choose one rule and keep it: the `extract...` methods throw, `isTokenValid` catches and returns `false`, and the filter wraps its calls in a `try/catch` so the request continues unauthenticated.

## Part 2: The classes, one by one

### `@Service`

A Spring annotation that marks the class as a bean in the **service layer**. It behaves like `@Component`, with a name that tells readers what the class is. Spring creates **one instance** (a singleton) at startup and injects it wherever it is asked for. Because there is one shared instance, any fields it holds, like the key, are shared by all requests. That is fine when they are immutable (`final`), and it is the reason to build them once.

### `Jwts`

The front door of jjwt, covered in an earlier lesson. In this class you use three of its entry points:

|Entry point|Returns|Used for|
|---|---|---|
|`Jwts.builder()`|`JwtBuilder`|Creating a token|
|`Jwts.parser()`|`JwtParserBuilder`|Configuring a token checker|
|`Jwts.SIG`|Algorithm constants|Generating keys, choosing an algorithm|

You never write `new Jwts()`. You call its static methods.

### `Decoders`

`io.jsonwebtoken.io.Decoders` converts **text into bytes**. `Decoders.BASE64.decode("...")` takes Base64 text and returns a `byte[]`. A secret key is raw random bytes, which can't be typed into a config file, so it is stored as Base64 text and decoded at startup. The reverse class is `Encoders`, which turns bytes into text.

### `Keys`

`io.jsonwebtoken.security.Keys` is a helper that creates key objects. `Keys.hmacShaKeyFor(byte[])` wraps your bytes in a `SecretKey` for HMAC signing, and it **checks the length**. With fewer than 32 bytes it throws `WeakKeyException`, and that check is your safety net against weak secrets.

### `SecretKey`

`javax.crypto.SecretKey` is the standard Java type for a key used for both signing and verifying (a _symmetric_ key). It is an interface with three methods you may meet:

|Method|Returns|
|---|---|
|`getAlgorithm()`|A name like `HmacSHA256` or `HmacSHA512`|
|`getEncoded()`|The raw bytes (treat them like a password)|
|`getFormat()`|`RAW` for these keys|

You pass the `SecretKey` to `signWith(key)` to sign and to `verifyWith(key)` to check.

### `Claims`

The read-only object representing the token's payload, taught in the last lesson. It comes from `parseSignedClaims(token).getPayload()`, and its getters (`getSubject()`, `getExpiration()`) are what the extract methods call.

### `Function<T, R>`

`java.util.function.Function` is a standard Java interface for "something that takes an `T` and returns an `R`." It has one method, `apply`. In `JwtService` it lets one generic method read any claim:

```java
public <T> T extractClaim(String token, Function<Claims, T> resolver) {
    return resolver.apply(extractAllClaims(token));
}
```

You pass the "recipe" as a **method reference** or a **lambda**:

```java
extractClaim(token, Claims::getSubject);                    // method reference
extractClaim(token, claims -> claims.get("role", String.class));   // lambda
```

`Claims::getSubject` is just a short way to write `claims -> claims.getSubject()`. The `<T>` before the return type makes the method generic, so the return type follows whatever the recipe returns.

### `Map` and `HashMap`

`Map<String, Object>` is Java's key-to-value structure, and `HashMap` is its most common implementation. A JWT payload is a set of named values, so a map is the natural way to hand over **extra claims**:

```java
Map<String, Object> extra = new HashMap<>();
extra.put("role", "ADMIN");
```

An empty map does nothing, so add one only when you have claims to put in it. For a few fixed claims, `.claim("role", value)` is simpler.

### `Date`, and its modern relatives `Instant` and `Duration`

jjwt's `issuedAt(...)` and `expiration(...)` take a `java.util.Date`, which is an older Java type that stores a moment in milliseconds. Modern Java code prefers `Instant` (a moment) and `Duration` (a length of time), because they are clearer and harder to misuse. You can bridge them: `Date.from(instant)`.

|Old style|Modern style|
|---|---|
|`new Date(System.currentTimeMillis())`|`Instant.now()`|
|`60 * 10 * 1000` (what is this?)|`Duration.ofMinutes(10)`|
|`new Date(now + 600000)`|`Date.from(now.plus(duration))`|

`Duration.ofMinutes(10)` explains itself, while `60 * 10 * 1000` needs a comment and invites mistakes with seconds versus milliseconds.

### `UserDetails`

The Spring Security interface describing one user (`getUsername()`, `getAuthorities()`, and so on). `isTokenValid` receives one so it can compare the token's subject with the user the filter loaded from the database.

### `AppUser`

Your own entity class. `generateToken` reads a few fields from it (the username, and the role if you add one). Only `JwtService` knows how those fields become claims.

## Part 3: A better way

The usual tutorial version of this class has four weaknesses. Here is each, with the fix.

|Weakness|Why it hurts|Better way|
|---|---|---|
|The secret is written in the source code|It ends up in Git, and anyone with the code can forge tokens|Read it from an environment variable|
|The key is rebuilt on every call|Wasted work, and a bad secret is found late|Build it once in the constructor|
|The issuer and lifetime are typed in the middle of a method|Hard to find, hard to change, easy to mismatch|Put them in configuration|
|A validation method that returns a fixed answer, or errors that escape|A security hole, or a confusing 500 error|Real checks, with a clear rule about exceptions|

### Step A: Typed configuration

Use a `record` bound to your properties. It is typed, immutable and fails at startup if something is missing.

```properties
# application.properties
jwt.secret=${JWT_SECRET}
jwt.issuer=ALIREZA
jwt.expiration=10m
```

```java
@ConfigurationProperties(prefix = "jwt")
public record JwtProperties(String secret, String issuer, Duration expiration) {}
```

Enable it once, on your main class:

```java
@SpringBootApplication
@ConfigurationPropertiesScan
public class DemoApplication { ... }
```

Spring converts `10m` into a `Duration` of ten minutes automatically. It understands `ms`, `s`, `m`, `h` and `d`. If `JWT_SECRET` isn't set, the application refuses to start, which is what you want.

### Step B: The service

```java
@Service
public class JwtService {

    private final SecretKey key;
    private final JwtParser parser;
    private final String issuer;
    private final Duration expiration;

    public JwtService(JwtProperties props) {
        this.key = Keys.hmacShaKeyFor(Decoders.BASE64.decode(props.secret()));
        this.issuer = props.issuer();
        this.expiration = props.expiration();
        this.parser = Jwts.parser()
                .verifyWith(key)
                .requireIssuer(issuer)
                .clockSkewSeconds(30)
                .build();
    }

    public String generateToken(AppUser appUser) {
        Instant now = Instant.now();

        return Jwts.builder()
                .subject(appUser.getUsername())
                .issuer(issuer)
                .claim("role", appUser.getRole())
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plus(expiration)))
                .signWith(key)
                .compact();
    }

    public String extractUserName(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public <T> T extractClaim(String token, Function<Claims, T> resolver) {
        return resolver.apply(extractAllClaims(token));
    }

    private Claims extractAllClaims(String token) {
        return parser.parseSignedClaims(token).getPayload();
    }

    public boolean isTokenValid(String token, UserDetails userDetails) {
        try {
            return userDetails.getUsername().equals(extractUserName(token));
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }
}
```

### Why each choice is better

**The constructor builds the key and parser once.** Fields are `final`, so the shared singleton is safe across threads. If the secret is weak or malformed, `hmacShaKeyFor` throws at startup, so you find out in seconds, not at the first login.

**The parser is configured with rules, not `if` statements.** `requireIssuer` rejects tokens from any other issuer. `clockSkewSeconds(30)` tolerates small clock differences between servers. And because it was built with `verifyWith(key)` using a `SecretKey`, it only accepts HMAC-signed tokens, which blocks the `"alg": "none"` trick.

**One verification path.** `extractAllClaims` is the only place that calls `parseSignedClaims`, and every accessor goes through it. Nobody can read a payload without the signature being checked.

**Expiry needs no separate check.** The parser throws `ExpiredJwtException` for an expired token, so a token that passes `parseSignedClaims` is already unexpired. A hand-written date comparison would never see a failing case.

**`now` is captured once.** `issuedAt` and `expiration` come from the same instant, so the gap is exactly the configured duration.

**The error rule is clear.** `extract...` methods throw. `isTokenValid` never throws, and it returns `false` for any bad token. The filter calls `extractUserName` before `isTokenValid`, so it still wraps that call in `try/catch`, as in the corrected filter from the earlier lesson.

**`isTokenValid` compares the subject with the user.** A signed, unexpired token is not enough. It must also belong to the user the filter loaded. That comparison is the last line of defence, so it must be a real check.

### Optional upgrades, once this works

- **Roles in the token.** You already write `role` into the claims. The filter can read it with `extractClaim(token, c -> c.get("role", String.class))` and build authorities from it, skipping the database lookup per request. The cost is that a role change takes effect only when the token expires.
- **A token id.** Add `.id(UUID.randomUUID().toString())` so you can later block a single token.
- **A `Clock` for tests.** Inject a `java.time.Clock` and call `Instant.now(clock)`, so a test can fix the time and check expiry without waiting.

## Part 4: Test it without Spring

Because the constructor takes plain values, you can test the class with a normal unit test:

```java
class JwtServiceTest {

    private static String newSecret() {
        SecretKey k = Jwts.SIG.HS512.key().build();
        return Encoders.BASE64.encode(k.getEncoded());
    }

    private final JwtService service = new JwtService(
            new JwtProperties(newSecret(), "ALIREZA", Duration.ofMinutes(10)));

    private final UserDetails alice =
            User.withUsername("alice").password("x").roles("USER").build();

    private AppUser appUser(String name) {
        AppUser u = new AppUser();
        u.setUsername(name);
        u.setRole("USER");
        return u;
    }

    @Test
    void tokenRoundTrip() {
        String token = service.generateToken(appUser("alice"));
        assertEquals("alice", service.extractUserName(token));
        assertTrue(service.isTokenValid(token, alice));
    }

    @Test
    void tokenForAnotherUserIsRejected() {
        String token = service.generateToken(appUser("bob"));
        assertFalse(service.isTokenValid(token, alice));
    }

    @Test
    void tamperedTokenIsRejected() {
        String token = service.generateToken(appUser("alice")) + "x";
        assertFalse(service.isTokenValid(token, alice));
    }

    @Test
    void expiredTokenIsRejected() {
        JwtService shortLived = new JwtService(
                new JwtProperties(newSecret(), "ALIREZA", Duration.ofSeconds(-1)));
        String token = shortLived.generateToken(appUser("alice"));
        assertFalse(shortLived.isTokenValid(token, alice));
    }
}
```

Each test pins down one promise: a round trip works, a token for another user fails, a changed token fails, and an expired token fails. The expired test uses a **negative** duration, so the token is already dead when it is created, which avoids waiting. Notice that these tests exist only because the class was built with a constructor and plain inputs.

## Common mistakes

- **Hardcoding the secret.** It lands in Git, and a key that appears in any public place, chat or log should be treated as leaked and replaced.
- **Regenerating a random key on startup.** Every restart then invalidates all tokens.
- **A validation method that returns a constant.** It would accept every token, including forged ones.
- **Forgetting to return a value.** A method that builds the parser chain but never `return`s it won't compile, and one that returns `null` fails later in confusing ways.
- **Parsing in several places.** If some code decodes the token without the verified parser, that path has no signature check.
- **Catching `Exception` everywhere.** It hides real bugs. Catch `JwtException` and `IllegalArgumentException`.
- **Making the service stateful.** Don't store the "current token" or "current user" in a field. The service is a shared singleton, and request data in a field leaks between users.

## One more thing about your reference code

Two things in the code you pasted need attention, even though this lesson isn't a review of it. The secret key is written in it in plain text, and you have now shared it, so treat that exact key as exposed and generate a new one (the earlier lesson shows how). And a `isTokenValid` that returns `true` without checking anything would accept any token, so replace it with the real check above before running the app anywhere.

## A related concept: `@Value` vs `@ConfigurationProperties`

Both read settings from `application.properties`. `@Value("${jwt.secret}")` injects one setting into one field or parameter, which is quick for a single value. `@ConfigurationProperties` binds a whole group of related settings, like everything under `jwt.`, into one typed object, with automatic conversion (`10m` into a `Duration`) and one place to see all of them. Once a class needs two or three settings, the grouped version is the cleaner choice.




[[Spring Security]]