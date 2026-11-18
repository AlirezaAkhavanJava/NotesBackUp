

`io.jsonwebtoken.Claims` is the object jjwt gives you after it has read and verified a token. It represents the **payload** of the JWT, the middle part, as a Java object. Each fact in the payload, such as the username, the issuer or the expiry time, is one **claim**, and `Claims` is the collection of all of them. Whenever you write `claims.getSubject()` or `claims.getExpiration()`, you are asking this object for one of those facts.

It is useful because it is two things at once. It is a normal Java `Map<String, Object>`, so you can read any claim by name. It also has **typed getters** for the standard claims, so `getExpiration()` returns a real `Date` and you don't have to convert numbers yourself. This lesson covers both sides, where `Claims` comes from, how your `JwtService` should use it, and what changed in jjwt 0.12.

## From JSON to `Claims`

When your server builds a token, the payload is a small JSON object. This is what the payload of your `generateToken` looks like once decoded:

```json
{
  "sub": "alice",
  "iss": "ALIREZA",
  "role": "USER",
  "iat": 1761570000,
  "exp": 1761570600
}
```

After `parseSignedClaims(token).getPayload()`, jjwt hands you a `Claims` object holding exactly those entries:

|Claim name|Stored value|Typed getter|
|---|---|---|
|`sub`|`"alice"`|`getSubject()` returns `String`|
|`iss`|`"ALIREZA"`|`getIssuer()` returns `String`|
|`iat`|`1761570000`|`getIssuedAt()` returns `Date`|
|`exp`|`1761570600`|`getExpiration()` returns `Date`|
|`role`|`"USER"`|no typed getter, use `get("role", String.class)`|

The dates are stored as seconds since 1970 in the JSON. The typed getters convert them to `Date` for you.

## Where a `Claims` object comes from

```java
Claims claims = Jwts.parser()
        .verifyWith(key)
        .build()
        .parseSignedClaims(token)    // returns Jws<Claims>
        .getPayload();               // returns Claims
```

The chain has three layers, and each one is a different type:

|Call|Returns|What it holds|
|---|---|---|
|`parseSignedClaims(token)`|`Jws<Claims>`|The whole verified token: header, payload, signature|
|`.getHeader()`|`JwsHeader`|`alg`, `kid`, `typ`|
|`.getPayload()`|`Claims`|Your data|

The important rule: **`Claims` is only trustworthy because the parser verified the signature first.** If you decode the middle part of a token by hand, you also get the JSON, but nothing has proven it wasn't edited.

## Reading claims: three ways

### 1. Typed getters for the registered claims

The JWT standard reserves seven short names. `Claims` has a method for each:

|Claim|Meaning|Method|Returns|
|---|---|---|---|
|`iss`|Who issued the token|`getIssuer()`|`String`|
|`sub`|Who the token is about|`getSubject()`|`String`|
|`aud`|Who it is meant for|`getAudience()`|`Set<String>`|
|`exp`|Expiry time|`getExpiration()`|`Date`|
|`nbf`|Not valid before|`getNotBefore()`|`Date`|
|`iat`|Issued at|`getIssuedAt()`|`Date`|
|`jti`|Unique token id|`getId()`|`String`|

A missing claim returns `null`, so `getExpiration()` on a token with no `exp` gives `null`. Check before calling methods on the result.

### 2. `get(name, type)` for your own claims

Anything outside the standard seven is a **custom claim**. You read it by name and tell jjwt what type you expect:

```java
String role = claims.get("role", String.class);
Integer age = claims.get("age", Integer.class);
```

If the claim doesn't exist, you get `null`. If it exists with a different type, such as asking for a `String` when the value is a number, jjwt throws `RequiredTypeException`. That strictness protects you from a silent wrong cast.

Lists need one extra step, because Java erases the element type:

```java
@SuppressWarnings("unchecked")
List<String> roles = claims.get("roles", List.class);
```

For numbers, the safest habit is to go through `Number`, since JSON may deliver a whole number as `Integer` or `Long`:

```java
long userId = ((Number) claims.get("userId")).longValue();
```

### 3. Plain `Map` methods

Because `Claims extends Map<String, Object>`, everything a map can do works here:

```java
claims.containsKey("role");        // true or false
claims.keySet();                   // all claim names
claims.size();                     // how many claims
claims.get("role");                // raw Object
claims.forEach((k, v) -> System.out.println(k + " = " + v));
```

The map view is handy for debugging, for example printing every claim of a token you received.

## The `extractClaim` pattern in a `JwtService`

Most Spring JWT projects, including the one your `extractUserName` and `isTokenValid` come from, use one small generic method so every claim is read the same way:

```java
private Claims extractAllClaims(String token) {
    return Jwts.parser()
            .verifyWith(key)
            .build()
            .parseSignedClaims(token)
            .getPayload();
}

private <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
    Claims claims = extractAllClaims(token);
    return claimsResolver.apply(claims);
}

public String extractUserName(String token) {
    return extractClaim(token, Claims::getSubject);
}

public Date extractExpiration(String token) {
    return extractClaim(token, Claims::getExpiration);
}

public String extractRole(String token) {
    return extractClaim(token, c -> c.get("role", String.class));
}
```

How it works, step by step:

- `extractAllClaims` does the one expensive job: it verifies the signature and returns the `Claims`.
- `extractClaim` takes the token and a **`Function<Claims, T>`**, which is "a recipe that turns a `Claims` into something of type `T`."
- `<T>` makes the method generic. If the recipe returns a `String`, `extractClaim` returns a `String`. If it returns a `Date`, it returns a `Date`.
- `Claims::getSubject` is a **method reference**. It is shorthand for `claims -> claims.getSubject()`.
- For a custom claim, you pass a small lambda, as in `extractRole`.

The benefit is that adding a new accessor is one line, and the parsing code lives in one place.

A note on `isTokenValid`: tutorials often write `!extractExpiration(token).before(new Date())`. With the jjwt 0.12 parser, an expired token **throws `ExpiredJwtException` while parsing**, before that line is ever reached. The explicit date check is harmless but redundant. What matters is that the exception is caught somewhere, such as in `isTokenValid` or in your filter.

## Reading claims from an expired token

`ExpiredJwtException` carries the claims that were inside the token. That is useful when you want to know **who** the expired token belonged to, for example to decide whether to allow a refresh:

```java
try {
    parser.parseSignedClaims(token);
} catch (ExpiredJwtException e) {
    Claims expired = e.getClaims();
    String who = expired.getSubject();   // readable, but the token is NOT valid
}
```

The signature was still checked before the expiry error was raised, so the data is genuine. The token simply can't be used for authentication anymore.

## Building a `Claims` object yourself

In jjwt 0.12, a `Claims` object is **read-only**. Calling `claims.put(...)` throws `UnsupportedOperationException`. When you need to create one, you use a builder:

```java
Claims base = Jwts.claims()
        .issuer("ALIREZA")
        .add("tenant", "cinema-7")
        .build();
```

You can then pass it into a token with `Jwts.builder().claims(base)`. You will more often write claims directly into the token, as in your `generateToken` method:

```java
Jwts.builder()
        .claims()
            .add(extraClaims)               // a Map<String, Object>
            .subject(appUser.getUsername())
            .issuer("ALIREZA")
        .and()
        .signWith(key)
        .compact();
```

The `extraClaims` map is where your custom claims go, like `role`. Anything you put into that map comes back out through `get("role", String.class)` on the reading side. Both sides must agree on the claim name and type.

## Exceptions you can meet

|Exception|When|
|---|---|
|`ExpiredJwtException`|`exp` has passed (it carries the `Claims`)|
|`SignatureException`|The payload was changed, or the wrong key was used|
|`MalformedJwtException`|The string isn't a valid JWT|
|`RequiredTypeException`|`get("x", Type.class)` found a different type|
|`MissingClaimException` / `IncorrectClaimException`|A `require...` rule on the parser failed|
|`UnsupportedOperationException`|You tried to modify a read-only `Claims`|

All the JWT-specific ones extend `JwtException`, so one `catch (JwtException e)` covers them.

## Common mistakes

- **Putting secrets in claims.** The payload is Base64URL text that anyone can decode. Never store passwords or private data.
- **Trusting claims without verification.** Use `parseSignedClaims`. Reading the payload by hand skips the signature check.
- **Calling methods on a missing claim.** `claims.getExpiration().getTime()` throws `NullPointerException` when `exp` is absent.
- **Wrong type in `get`.** Asking for `Integer.class` when you stored a string throws `RequiredTypeException`.
- **Mismatched claim names.** Writing `"Role"` and reading `"role"` gives `null`. Keep names in constants.
- **Putting big objects in claims.** Every claim makes the token longer, and the token is sent with every request.
- **Trusting a role claim forever.** If an admin removes a user's role, the old token still says `ADMIN` until it expires. Short expiry limits this, and loading the user from the database, as your filter does, covers it.

## Migrating old code

Old tutorials use the 0.11 API. This table translates the `Claims`-related parts:

|0.11 and older|0.12|
|---|---|
|`.parseClaimsJws(token).getBody()`|`.parseSignedClaims(token).getPayload()`|
|`Jws<Claims>` from `parseClaimsJws`|`Jws<Claims>` from `parseSignedClaims`|
|`claims.setSubject("x")`|read-only, use `Jwts.claims().subject("x").build()`|
|`claims.getAudience()` returned `String`|`getAudience()` returns `Set<String>`|
|`Jwts.claims().setSubject(...)`|`Jwts.claims().subject(...)`|
|`.setClaims(map)`|`.claims(map)`|

## A related concept: `Jwt`, `Jws` and `Jwe`

`Claims` is only the payload, and jjwt wraps it in a type that says what kind of token it was. `Jwt<H, P>` is the general parent, `Jws<P>` is a **signed** token (the kind you use), and `Jwe<P>` is an **encrypted** token. Each has `getHeader()` and `getPayload()`, and `Jws` adds `getDigest()` for the signature bytes. The parse method you choose, such as `parseSignedClaims`, fixes which wrapper you get, and that guarantees the token has the properties you expect.





[[Spring Security]]