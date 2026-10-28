

This method takes an `AppUser`, writes a few facts about them into a token (who they are, who issued it, when it was created, when it dies), signs the token with your secret key, and returns the finished `xxx.yyy.zzz` string. It is the "token factory" of your `JwtService`, and your login endpoint calls it after the username and password have been checked.

The whole thing is one long chain, which can look intimidating. It becomes easy once you see that the chain has three stages: **fill in the claims**, **sign**, **finish**. The `.and()` in the middle is the line between the first stage and the second.

## The three stages

```
Jwts.builder()
   │
   ├─ Stage 1: .claims() ... .and()     → write the payload
   │
   ├─ Stage 2: .signWith(generateKey()) → sign it
   │
   └─ Stage 3: .compact()               → produce the string
```

## Stage 1: the claims block

### `Map<String, Object> claims = new HashMap<>();`

This creates an empty map meant to hold extra, custom claims. Right now it is empty, so `.add(claims)` further down adds nothing. Authors usually leave it there so they can fill it later:

```java
claims.put("role", appUser.getRole());
claims.put("userId", appUser.getId());
```

Until you do that, the map and the `.add(claims)` call have no effect, and you can delete both.

### `Jwts.builder()`

This gives you a fresh `JwtBuilder`. Nothing is written yet.

### `.claims()`

This is the key line. It **opens a sub-builder** for the payload. Everything you call until `.and()` is written into the claims, and the sub-builder offers methods that match the registered claim names.

### `.add(claims)`

This pours every entry of your map into the payload. `add(Map)` adds many at once. There is also `add(String key, Object value)` for one at a time:

```java
.add("role", "ADMIN")
```

### `.subject(appUser.getUsername())`

This sets the `sub` claim, meaning who the token is about. Later, your filter reads it back with `claims.getSubject()` to find the user.

### `.issuer("ALIREZA")`

This sets the `iss` claim, meaning who created the token. If the parser uses `.requireIssuer("ALIREZA")`, tokens with a different issuer are rejected. Both sides must use the exact same text, so keep it in one constant instead of typing it twice.

### `.issuedAt(new Date(System.currentTimeMillis()))`

This sets `iat`, the creation time. `new Date(System.currentTimeMillis())` is the same as `new Date()`. It means "now."

### `.expiration(new Date(System.currentTimeMillis() + 60 * 10 * 1000))`

This sets `exp`, the time after which the token is invalid. The math is in milliseconds:

|Part|Meaning|Value|
|---|---|---|
|`60`|seconds in a minute|60|
|`10`|minutes|10|
|`1000`|milliseconds in a second|1000|
|**Result**|10 minutes|**600,000 ms**|

So the token lives for 10 minutes. After that, parsing it throws `ExpiredJwtException`.

### `.and()`

This **closes the claims sub-builder** and returns you to the main builder. Without it, the next call, `.signWith(...)`, wouldn't exist on the object you're holding, and the code wouldn't compile. Think of `.claims()` as opening a bracket and `.and()` as closing it.

## Stage 2 and 3: sign and finish

### `.signWith(generateKey())`

This signs the header and payload with your `SecretKey`. jjwt chooses the algorithm from the key size: HS256 for 32 bytes or more, HS384 for 48 or more, HS512 for 64 or more. It also writes the matching `alg` into the header for you.

### `.compact()`

This Base64URL-encodes the header and payload, adds the signature, joins the three parts with dots, and returns the `String`. This is the call that does the actual work, so errors such as a weak key appear here.

## What the token contains

If you decode the middle part of the finished token, you get this payload (the times are example values):

|Claim|Value|Source line|
|---|---|---|
|`sub`|`"alice"`|`.subject(...)`|
|`iss`|`"ALIREZA"`|`.issuer(...)`|
|`iat`|`1761570000`|`.issuedAt(...)`|
|`exp`|`1761570600`|`.expiration(...)`|

Dates are stored as **seconds** since 1970, not milliseconds. jjwt converts them for you, and the gap between `iat` and `exp` here is 600 seconds, which is the 10 minutes. Remember that anyone can read this payload, so never put a password or private data in it.

## `.claims().subject(...)` vs `.subject(...)`

In earlier lessons you saw `Jwts.builder().subject("alice")` directly. Both styles write to the same payload:

```java
// Style A: direct on the builder (shorter)
Jwts.builder()
        .subject("alice")
        .issuer("ALIREZA")
        .signWith(key)
        .compact();

// Style B: inside the claims block (what your code uses)
Jwts.builder()
        .claims()
            .subject("alice")
            .issuer("ALIREZA")
            .and()
        .signWith(key)
        .compact();
```

Style B is useful when you want to group the payload visually, or when you want to pass in a map with `.add(map)`. For a simple token, Style A is less noisy.

## A cleaner version of the same method

```java
private static final String ISSUER = "ALIREZA";
private static final long EXPIRATION_MS = 10 * 60 * 1000;   // 10 minutes

public String generateToken(AppUser appUser) {
    Date now = new Date();

    return Jwts.builder()
            .subject(appUser.getUsername())
            .issuer(ISSUER)
            .claim("role", appUser.getRole())
            .issuedAt(now)
            .expiration(new Date(now.getTime() + EXPIRATION_MS))
            .signWith(key)
            .compact();
}
```

What changed and why:

- **`now` is captured once.** Your version calls `System.currentTimeMillis()` twice, so `iat` and `exp` are computed from slightly different instants. The difference is a few milliseconds, which is harmless, but one `now` is cleaner and easier to read.
- **The empty map is gone.** A real claim (`role`) goes in with `.claim(...)` instead.
- **Constants replace magic numbers.** `ISSUER` and `EXPIRATION_MS` have names, and you can reuse `ISSUER` in `requireIssuer(...)` on the parser side.
- **`key` is a field.** It is built once in the constructor, instead of decoding the Base64 secret on every login.

## Common mistakes

- **Forgetting `.and()`.** The compiler complains that `signWith` can't be found, because you are still inside the claims sub-builder.
- **Putting `.signWith()` before the claims.** Signing is a finishing step. Set all claims first.
- **Mismatched issuer.** If the token is built with `"ALIREZA"` and the parser requires `"alireza"`, every token is rejected as `IncorrectClaimException`.
- **Mixing up milliseconds and seconds.** `Date` takes milliseconds. Writing `60 * 10` (600) instead of `60 * 10 * 1000` gives a token that expires in under a second.
- **Leaving out `expiration`.** The token would never expire.

## A related concept: the nested builder pattern and `.and()`

jjwt uses this pattern in several places. A method like `.claims()`, `.header()` or `.audience()` opens a focused mini-builder for one part of the token, and `.and()` brings you back to the main builder. It keeps related settings together, for example `.header().keyId("k1").type("JWT").and()`. If a chain stops compiling in the middle, check whether you have an open sub-builder that needs an `.and()`.






[[Spring Framework]]