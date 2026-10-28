

`Jwts` itself has only a few methods, but each one returns a bigger object with methods of its own, and those are the ones you use day to day. So "the methods of `Jwts`" really means three things: the **builder** (creates tokens), the **parser builder** (configures a checker for tokens), and the **result objects** (`Claims`, `Jws`, headers) that you read once a token is verified. This lesson walks through all of them in the order you meet them in real code.

Every method here is from jjwt **0.12.x**. If a method name looks unfamiliar, it's probably from an older tutorial, and the migration table in my last answer will translate it.

## The big picture

```
Jwts.builder()  ──►  JwtBuilder        ──► .compact()  ──► "xxx.yyy.zzz"

Jwts.parser()   ──►  JwtParserBuilder  ──► .build()    ──► JwtParser
                                                              │
                                    .parseSignedClaims(token) ▼
                                                           Jws<Claims>
                                                      .getPayload() ──► Claims
```

Tokens flow out through the top path. Incoming tokens flow through the bottom path.

## Part 1: `JwtBuilder` methods (writing a token)

### Registered claims

The JWT standard reserves a handful of short claim names. Each has its own method, so you never type the raw name by hand.

|Method|Claim|Meaning|Use it to|
|---|---|---|---|
|`.issuer(String)`|`iss`|Who created the token|Let other services reject tokens from unknown issuers|
|`.subject(String)`|`sub`|Who the token is about|Store the username or user id|
|`.audience().add(String).and()`|`aud`|Who the token is meant for|Stop a token for service A being accepted by service B|
|`.expiration(Date)`|`exp`|When it stops being valid|Limit the damage of a stolen token|
|`.notBefore(Date)`|`nbf`|When it starts being valid|Issue a token that activates later|
|`.issuedAt(Date)`|`iat`|When it was created|Audit, or reject tokens older than some cutoff|
|`.id(String)`|`jti`|Unique id of this token|Revoke one specific token via a blocklist|

Why use the named methods instead of `.claim("sub", ...)`? They check the type for you (dates must be `Date`), and a typo like `"exp "` can't sneak in. Here they are working together:

```java
Date now = new Date();

String token = Jwts.builder()
        .issuer("cineverse-api")
        .subject("alice")
        .audience().add("cineverse-web").and()
        .id(UUID.randomUUID().toString())
        .issuedAt(now)
        .notBefore(now)
        .expiration(new Date(now.getTime() + 15 * 60_000))
        .signWith(key)
        .compact();
```

Line by line:

- `.audience().add("cineverse-web")` opens a small collection, because a token can have several audiences. `.and()` closes it and returns you to the main builder. The `.and()` pattern appears whenever a method opens a sub-builder.
- `.id(UUID...)` gives every token a unique `jti`. Two tokens issued in the same second for the same user will still differ.
- `.notBefore(now)` means the token is valid from this moment. It is more useful when you set it a few minutes into the future.
- `.expiration(...)` adds 15 minutes in milliseconds. `60_000` is just `60000` with a readability underscore.

### Custom claims

For anything outside the registered names, you have two ways in:

```java
// One at a time
.claim("role", "ADMIN")
.claim("cinemaIds", List.of(3, 7, 9))

// Many at once
.claims(Map.of("role", "ADMIN", "tenant", "cinema-7"))

// Or through the sub-builder, which supports add() and chaining
.claims().add("role", "ADMIN").add("tenant", "cinema-7").and()
```

All three do the same job. Pick `claim(...)` for one or two values and `claims(map)` when the data is already in a map. Two rules apply to all of them:

- Values must be JSON-friendly: strings, numbers, booleans, lists and maps. Complex objects can be serialized, but keep tokens small.
- Every claim makes the token longer, and the token travels in every request header. Store ids and roles, not whole user profiles.

### Header methods

The header describes the token itself: its type and algorithm. jjwt fills in `alg` for you. The ones you might add yourself:

```java
.header()
    .keyId("key-2026-10")      // kid: which key signed this token
    .type("JWT")               // typ
    .add("app-version", "3")   // any custom header
    .and()
```

The `kid` is the important one. When you rotate keys, the parser reads `kid` from the header to choose the right key. You will see that in Part 2.

### Signing and encrypting methods

|Method|What it does|
|---|---|
|`.signWith(key)`|Signs, and picks the algorithm from the key (HS256/384/512 for HMAC)|
|`.signWith(key, Jwts.SIG.HS512)`|Signs with an algorithm you choose explicitly|
|`.encryptWith(key, keyAlg, encAlg)`|Makes an encrypted token (JWE) so the payload is hidden, not just signed|
|`.compressWith(Jwts.ZIP.DEF)`|Compresses the payload before encoding, for large tokens|

Most apps only ever use `signWith(key)`. Reach for `encryptWith` only if the payload truly must be unreadable to the client. Usually the better advice is to put less in the payload.

### The finishing move: `compact()`

`compact()` Base64URL-encodes the header and payload, signs them, joins the parts with dots and returns the string. Nothing is validated before this call, so errors like a weak key appear here, not earlier.

There is also a rarer path, `.content(bytes)`, which puts arbitrary bytes in the payload instead of JSON claims. You would read that back with `parseSignedContent`. Ignore it unless you have a special use.

## Part 2: `JwtParserBuilder` methods (preparing a checker)

You configure the parser once, call `build()`, and reuse the result for every request. Each configuration method below is a rule that a token must pass.

|Method|The rule it adds|Why you'd want it|
|---|---|---|
|`.verifyWith(SecretKey / PublicKey)`|Signature must match this key|The core security check. Mandatory.|
|`.requireIssuer("x")`|`iss` must equal `x`|Reject tokens from other systems that share a key|
|`.requireSubject("x")`|`sub` must equal `x`|Rare, but useful in tests or special endpoints|
|`.requireAudience("x")`|`aud` must contain `x`|Make sure the token was meant for this service|
|`.require("role", "ADMIN")`|Any custom claim must match|Quick guards without extra code|
|`.clockSkewSeconds(30)`|Allow 30 s of clock difference on `exp`/`nbf`|Servers' clocks are never perfectly in sync|
|`.keyLocator(locator)`|Choose the key per token, using its header|Key rotation with `kid`|
|`.decryptWith(key)`|Key for encrypted tokens|Only for JWE|
|`.build()`|Freeze everything into a `JwtParser`|Always the last call|

A realistic parser, built once in a field:

```java
private final JwtParser parser = Jwts.parser()
        .verifyWith(key)
        .requireIssuer("cineverse-api")
        .requireAudience("cineverse-web")
        .clockSkewSeconds(30)
        .build();
```

Line by line:

- `verifyWith(key)` is the foundation. Without it, jjwt refuses to parse a signed token.
- `requireIssuer` and `requireAudience` make the parser throw `MissingClaimException` or `IncorrectClaimException` if the claim is absent or different. That saves you from writing `if` checks in your own code.
- `clockSkewSeconds(30)` stops a token being rejected as "expired" because your auth server's clock is 2 seconds ahead of the API's.
- `build()` returns the thread-safe `JwtParser`, so one instance serves every request.

### Key rotation with `keyLocator`

A key locator lets the parser pick the key from the token's header. This is the payoff of the `kid` you set in the builder.

```java
Map<String, SecretKey> keys = Map.of(
        "key-2026-09", oldKey,
        "key-2026-10", newKey);

JwtParser parser = Jwts.parser()
        .keyLocator(new LocatorAdapter<Key>() {
            @Override
            protected Key locate(JwsHeader header) {
                return keys.get(header.getKeyId());   // look up by kid
            }
        })
        .build();
```

New tokens are signed with `key-2026-10`, but tokens signed with last month's key still verify until they expire. After that, you delete the old key from the map. Nobody gets logged out at the moment of rotation.

## Part 3: Parsing methods and what they return

The parse method states what you expect to receive:

|Method|Expects|Returns|
|---|---|---|
|`parseSignedClaims(token)`|Signed token with JSON claims|`Jws<Claims>`|
|`parseSignedContent(token)`|Signed token with raw bytes|`Jws<byte[]>`|
|`parseEncryptedClaims(token)`|Encrypted token|`Jwe<Claims>`|
|`parseUnsecuredClaims(token)`|Unsigned token (needs `.unsecured()` on the builder)|`Jwt<Header, Claims>`|
|`parse(token)`|Anything|`Jwt<?, ?>`|

Use `parseSignedClaims` for ordinary login tokens. Because it only accepts signed tokens, an attacker can't send you an unsigned one.

The returned `Jws<Claims>` has three parts:

```java
Jws<Claims> jws = parser.parseSignedClaims(token);

JwsHeader header = jws.getHeader();     // alg, kid, typ
Claims claims    = jws.getPayload();    // your data
String signature = jws.getDigest() == null ? null
        : Encoders.BASE64URL.encode(jws.getDigest());  // rarely needed
```

Most of the time you chain straight to `.getPayload()`.

## Part 4: Reading `Claims`

`Claims` behaves like a `Map<String, Object>` with typed getters on top.

|Method|Returns|
|---|---|
|`getSubject()`, `getIssuer()`, `getId()`|`String`|
|`getAudience()`|`Set<String>`|
|`getExpiration()`, `getIssuedAt()`, `getNotBefore()`|`Date`|
|`get("role", String.class)`|Your custom claim, cast to the type you give|
|`get("cinemaIds", List.class)`|Lists come back as raw `List`|
|`containsKey("role")`|`boolean`|

```java
Claims c = parser.parseSignedClaims(token).getPayload();

String user  = c.getSubject();
String role  = c.get("role", String.class);   // null if absent
Date expires = c.getExpiration();
boolean soon = expires.getTime() - System.currentTimeMillis() < 60_000;
```

A small trap: `get("age", Integer.class)` works when the value really is an integer, but numbers that came through JSON as longs can throw a cast error. If you store numbers, test the round trip.

## Part 5: Putting the methods into a complete service

```java
@Service
public class JwtService {

    private static final long EXPIRATION_MS = 15 * 60_000;

    private final SecretKey key;
    private final JwtParser parser;

    public JwtService(@Value("${jwt.secret}") String base64Secret) {
        this.key = Keys.hmacShaKeyFor(Decoders.BASE64.decode(base64Secret));
        this.parser = Jwts.parser()
                .verifyWith(key)
                .requireIssuer("cineverse-api")
                .clockSkewSeconds(30)
                .build();
    }

    public String generate(UserDetails user) {
        Date now = new Date();
        String role = user.getAuthorities().iterator().next().getAuthority();

        return Jwts.builder()
                .issuer("cineverse-api")
                .subject(user.getUsername())
                .claim("role", role)
                .id(UUID.randomUUID().toString())
                .issuedAt(now)
                .expiration(new Date(now.getTime() + EXPIRATION_MS))
                .signWith(key)
                .compact();
    }

    public Claims parse(String token) {
        return parser.parseSignedClaims(token).getPayload();
    }

    public boolean isValid(String token, UserDetails user) {
        try {
            return parse(token).getSubject().equals(user.getUsername());
        } catch (ExpiredJwtException e) {
            return false;                  // expired: client should refresh
        } catch (JwtException | IllegalArgumentException e) {
            return false;                  // tampered or malformed
        }
    }
}
```

Notes on the choices:

- The key and parser are built once in the constructor, so a request only pays for the signature check.
- `parse` has one job, returning verified claims. `isValid` decides what counts as valid for your app.
- `ExpiredJwtException` is caught first because it is more specific than `JwtException`. In a real filter, you'd let that one through to return a distinct "token expired" response.

## Common mistakes to avoid

- **Trusting claims before verification.** Never decode the payload by hand (Base64) and use it. Always go through `parseSignedClaims`.
- **Rebuilding the parser per request.** It works, but it wastes work and makes the code harder to read.
- **Skipping `exp`.** A token without an expiry is valid forever.
- **Using `parse(token)` for everything.** It accepts every token type, so it weakens the guarantee you get from `parseSignedClaims`.
- **Putting sensitive data in claims.** Signed is not secret.

## A related concept: `Keys` and key generation, in short

`Keys.hmacShaKeyFor(bytes)` wraps raw bytes into a `SecretKey` and rejects keys that are too short. `Jwts.SIG.HS512.key().build()` generates a fresh random key. Use the first when your key comes from configuration, and the second only once, to create the secret you then store.





[[Spring Security]]