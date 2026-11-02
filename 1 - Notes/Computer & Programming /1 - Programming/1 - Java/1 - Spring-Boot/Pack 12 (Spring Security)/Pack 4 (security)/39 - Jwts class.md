

`io.jsonwebtoken.Jwts` is the front door of the jjwt library. It is a small utility class with static methods, and you never create an instance of it. You call it to get the objects that do the real work: a builder that creates tokens, a parser that reads and verifies them, and a set of ready-made algorithm constants. Every jjwt example starts with `Jwts.`, so understanding this class gives you a map of the whole library.

Think of `Jwts` as a factory counter. You ask it for a builder, a parser, or an algorithm, and it hands you the right object, already set up. This lesson uses the jjwt **0.12.x** API, which renamed many methods compared with 0.11 and older. The last section covers that, since most tutorials online still use the old names.

## The members of `Jwts` at a glance

|Member|Returns|Used for|
|---|---|---|
|`Jwts.builder()`|`JwtBuilder`|Creating and signing a token|
|`Jwts.parser()`|`JwtParserBuilder`|Configuring a parser to read and verify tokens|
|`Jwts.SIG`|Signature algorithms|`HS256`, `HS512`, `RS256`, `ES256`, and so on|
|`Jwts.claims()`|`ClaimsBuilder`|Building a claims set separately|
|`Jwts.header()`|`HeaderBuilder`|Building a header separately|
|`Jwts.ENC`, `Jwts.KEY`, `Jwts.ZIP`|Algorithms|Encrypted tokens (JWE) and compression, which you will rarely need|

## 1. `Jwts.builder()`: creating a token

This returns a `JwtBuilder`. You chain methods on it, and the last call, `compact()`, produces the final `xxx.yyy.zzz` string.

```java
String token = Jwts.builder()
        .issuer("cineverse-api")
        .subject("alice")
        .claim("role", "ADMIN")
        .id(UUID.randomUUID().toString())
        .issuedAt(new Date())
        .expiration(new Date(System.currentTimeMillis() + 15 * 60 * 1000))
        .signWith(key)
        .compact();
```

Read it line by line:

- `.issuer(...)` sets the `iss` claim, which says who created the token.
- `.subject(...)` sets `sub`, which says who the token is about. This is usually the username or user id.
- `.claim("role", "ADMIN")` adds a custom claim of your own. Use it for anything the registered names don't cover.
- `.id(...)` sets `jti`, a unique id for this token. It is useful if you ever need to revoke a single token.
- `.issuedAt(...)` sets `iat`, the time of creation.
- `.expiration(...)` sets `exp`, the time after which the token is invalid. Always set this.
- `.signWith(key)` signs the token with your secret key. jjwt looks at the key's size and picks the algorithm: HS256 for 32 bytes or more, HS384 for 48 or more, HS512 for 64 or more.
- `.compact()` Base64URL-encodes the header and payload, signs them, joins the three parts with dots, and returns the string.

You can also add several claims at once with a map:

```java
Map<String, Object> extra = Map.of("role", "ADMIN", "tenant", "cinema-7");

Jwts.builder()
        .claims(extra)          // adds all entries
        .subject("alice")
        .signWith(key)
        .compact();
```

Be aware that in 0.12, calling `.claims(map)` adds to the existing claims, so the order of calls doesn't wipe out what you already set.

## 2. `Jwts.parser()`: reading and verifying a token

This returns a `JwtParserBuilder`. You configure it once, call `build()` to get the real `JwtParser`, and then use it to parse tokens.

```java
Claims claims = Jwts.parser()
        .verifyWith(key)                 // which key checks the signature
        .requireIssuer("cineverse-api")  // optional: reject tokens from other issuers
        .clockSkewSeconds(30)            // optional: tolerate small clock differences
        .build()                         // freeze the configuration
        .parseSignedClaims(token)        // verify and decode
        .getPayload();                   // get the Claims object

String user = claims.getSubject();
String role = claims.get("role", String.class);
```

Line by line:

- `.verifyWith(key)` gives the parser the key. If you pass a `SecretKey`, only HMAC tokens are accepted. If you pass a `PublicKey`, only matching asymmetric tokens are accepted. Because the key type fixes the algorithm family, the `"alg": "none"` trick doesn't work.
- `.requireIssuer(...)` makes the parser throw if the `iss` claim is missing or different. There are matching `require...` methods for other claims.
- `.clockSkewSeconds(30)` allows 30 seconds of difference between servers' clocks when checking `exp` and `nbf`.
- `.build()` produces an immutable, thread-safe `JwtParser`.
- `.parseSignedClaims(token)` checks the signature and the expiry, then returns a `Jws<Claims>` object holding the header and payload.
- `.getPayload()` returns the `Claims`, which works like a map with typed getters.

Since the built parser is thread-safe, build it once and reuse it. In the `JwtService` from the previous lesson, you could hold it in a field instead of rebuilding it for every request:

```java
private final JwtParser parser;

public JwtService(@Value("${jwt.secret}") String base64Secret) {
    this.key = Keys.hmacShaKeyFor(Decoders.BASE64.decode(base64Secret));
    this.parser = Jwts.parser().verifyWith(key).build();
}
```

### Choosing the right `parse...` method

The parse method you call is a promise about what kind of token you expect. If the token is something else, jjwt throws instead of quietly accepting it.

|Method|Accepts|Returns|
|---|---|---|
|`parseSignedClaims(token)`|Signed token with claims|`Jws<Claims>`|
|`parseSignedContent(token)`|Signed token with a non-JSON payload|`Jws<byte[]>`|
|`parseEncryptedClaims(token)`|Encrypted token (JWE)|`Jwe<Claims>`|
|`parseUnsecuredClaims(token)`|Unsigned token|`Jwt<Header, Claims>`|
|`parse(token)`|Anything|Generic `Jwt`|

For everyday work, use `parseSignedClaims`. It guarantees the token was signed, so someone cannot slip an unsigned token past you.

## 3. `Jwts.SIG`: algorithm constants

`SIG` holds the signature algorithms as constants. It is also a handy way to generate a strong key without touching `openssl`:

```java
SecretKey key = Jwts.SIG.HS512.key().build();   // 64 random bytes, ready to use
String base64 = Encoders.BASE64.encode(key.getEncoded());
System.out.println(base64);                      // save this into JWT_SECRET once
```

Run that once, store the output in your environment variable, and don't regenerate it on every startup. If you do, every old token becomes invalid after each restart.

You can also force a specific algorithm instead of letting jjwt choose by key size:

```java
.signWith(key, Jwts.SIG.HS512)
```

The key must still be long enough for the algorithm you ask for. If it isn't, you get a `WeakKeyException`.

## 4. `Jwts.claims()` and `Jwts.header()`

These build the two parts of a token separately. They matter when the same claims or header are reused in several places:

```java
Claims base = Jwts.claims()
        .issuer("cineverse-api")
        .add("tenant", "cinema-7")
        .build();

String token = Jwts.builder()
        .claims(base)
        .subject("alice")
        .header().keyId("key-2026-10").and()   // adds a kid for key rotation
        .signWith(key)
        .compact();
```

The `.header()` call opens a header sub-builder, and `.and()` closes it and returns you to the main builder. That `kid` value is what makes key rotation possible later.

## What the exceptions mean

Everything thrown while parsing extends `JwtException`, so one `catch` covers all failures. When you need to tell them apart, here are the common ones:

|Exception|Cause|
|---|---|
|`ExpiredJwtException`|`exp` is in the past|
|`SignatureException`|The signature doesn't match, so the token was altered or signed with a different key|
|`MalformedJwtException`|The string isn't a valid JWT structure|
|`UnsupportedJwtException`|The token type doesn't match the parse method you called|
|`WeakKeyException`|The key is too short for the algorithm|
|`IllegalArgumentException`|The token string is null or empty|

A common mistake is to catch all of them and return the same error. A good filter can return "token expired" so that the client knows to refresh, and a plain "invalid token" for the rest.

## Migrating from 0.11 and older

If you copy code from older tutorials, this table translates it:

|Old (0.11 and earlier)|New (0.12)|
|---|---|
|`Jwts.parserBuilder()`|`Jwts.parser()`|
|`.setSigningKey(key)`|`.verifyWith(key)`|
|`.parseClaimsJws(token)`|`.parseSignedClaims(token)`|
|`.getBody()`|`.getPayload()`|
|`.setSubject(...)`, `.setIssuedAt(...)`, `.setExpiration(...)`|`.subject(...)`, `.issuedAt(...)`, `.expiration(...)`|
|`.signWith(key, SignatureAlgorithm.HS256)`|`.signWith(key)` or `.signWith(key, Jwts.SIG.HS256)`|
|`SignatureAlgorithm.HS256`|`Jwts.SIG.HS256`|

The old methods still exist in some versions but are deprecated, and they are removed in newer ones. If you see a method that doesn't compile, check this table first.

## A related concept: the `Keys` helper

`Jwts` makes tokens, and a second small class, `io.jsonwebtoken.security.Keys`, makes keys. `Keys.hmacShaKeyFor(bytes)` wraps raw bytes into a `SecretKey` and checks that the length is enough, which is why you saw it in the `JwtService` constructor. In 0.12 you can also skip it and use `Jwts.SIG.HS512.key().build()` to generate a key directly. Use `Keys.hmacShaKeyFor` when you already have the secret as bytes, for example from an environment variable.





[[Spring Security]]