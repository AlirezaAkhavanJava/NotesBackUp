



## The problem it solves

With a session ID, the server must **look you up** on every request. That works well with one server. With many servers or services, they all need access to the same session store, and every request costs a lookup.

A JWT removes the lookup. It's a token that **carries the facts about you inside itself** (who you are, what you may do, when the token expires), plus a **signature** that proves nobody tampered with those facts.

> A session ID says "look me up, I'm number 7F3A." A JWT says "here's everything you need to know about me, and here's a stamp proving it's genuine."

## The passport picture

Think of a passport at border control:

|Passport|JWT|
|---|---|
|Holds your name, nationality, expiry date|**Payload** (claims)|
|Says what kind of document it is and how it's secured|**Header**|
|The government's official stamp and security features|**Signature**|
|The officer checks the stamp **without phoning the government**|The server checks the signature **without a database lookup**|
|A forged or edited passport fails the check|A tampered token fails the check|
|Anyone can read the printed details|Anyone can decode the payload, since it isn't secret|
|If someone steals it, they can pretend to be you until it expires|A stolen token works until `exp`|

That last pair matters most: **a JWT is tamper-proof, not secret.**

---

# Part 1: The structure

A JWT is three pieces joined by dots. Here is a real, well-known sample token (from jwt.io), split across lines so you can see the parts:

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
.
eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ
.
SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

On the wire, it's one string with no line breaks:

```
header.payload.signature
```

|Part|Contains|Looks like when decoded|
|---|---|---|
|**Header**|How the token is signed|`{"alg":"HS256","typ":"JWT"}`|
|**Payload**|The claims (facts)|`{"sub":"1234567890","name":"John Doe","iat":1516239022}`|
|**Signature**|Proof of integrity|Raw bytes, shown as text|

### What is Base64URL?

The header and payload are JSON text turned into a URL-safe string with **Base64URL**. It exists because raw JSON has characters (`{`, `"`, spaces) that can break headers and URLs.

||Base64|Base64URL (used by JWT)|
|---|---|---|
|Characters `+` and `/`|Used|Replaced by `-` and `_`|
|Padding `=` at the end|Used|**Removed**|

Remember this: **Base64 is an encoding, not encryption.** Anyone can reverse it in one command. That's the foundation of the rule "never put secrets in a JWT."

---

# Part 2: Claims, the facts inside

A **claim** is one statement in the payload: a key and a value. The standard defines a few **registered claims** with agreed names:

|Claim|Name|Meaning|Example|
|---|---|---|---|
|`iss`|Issuer|Who created the token|`https://auth.example.com`|
|`sub`|Subject|Who the token is about (usually a user id)|`user-42`|
|`aud`|Audience|Who the token is meant for|`orders-api`|
|`exp`|Expiration|When it stops being valid|`1761200900`|
|`nbf`|Not before|Not valid before this time|`1761200000`|
|`iat`|Issued at|When it was created|`1761200000`|
|`jti`|JWT ID|A unique id for this token|`b7e1-...`|

You can add your own claims too (`roles`, `email`, `tenant`). A realistic payload:

```json
{
  "iss": "https://auth.example.com",
  "sub": "user-42",
  "aud": "orders-api",
  "iat": 1761200000,
  "exp": 1761200900,
  "jti": "b7e1c0de-5a2f-4c1e-9f0a-3d2e8b6c1a77",
  "roles": ["USER"]
}
```

### Details that trip people up

**Time values are in seconds, not milliseconds.** `exp` is a Unix timestamp in **seconds** since 1970. Java's `System.currentTimeMillis()` returns milliseconds, so forgetting to divide by 1000 creates tokens that expire thousands of years from now. A very common bug.

**Clocks disagree a little.** Two servers' clocks might differ by a few seconds, so verifiers usually allow a small **leeway** (30 to 60 seconds) when checking `exp` and `nbf`.

**Keep payloads small.** The token travels in a header on **every request**. Many servers and proxies limit total header size to around 8 KB, and a bloated token (a hundred permissions, say) wastes bandwidth and can break requests. Put identity and a few key facts in it, and load the rest from your database.

**Claims go stale.** If Alice's role changes, her existing token still says the old role until it expires. That's the price of not looking things up.

---

# Part 3: The signature, the clever part

## What it does

The signature answers one question: **"Has anyone changed this header or payload since the issuer created it?"**

The issuer computes it like this:

```
signingInput = base64url(header) + "." + base64url(payload)
signature    = SIGN(signingInput, key)
token        = signingInput + "." + base64url(signature)
```

## Why tampering fails

Imagine an attacker changes `"roles":["USER"]` to `"roles":["ADMIN"]`:

```
1. Attacker decodes the payload (easy, it's just Base64URL)
2. Edits roles to ADMIN
3. Re-encodes the payload
4. Keeps the OLD signature (they can't make a new one without the key)

Server verifies:
   recompute SIGN(newHeader.newPayload, key)  → gives signature X
   compare with the token's signature         → different!
   → REJECT
```

Changing even one character of the payload produces a completely different signature, and the attacker doesn't have the key needed to produce the right one.

## Two ways to sign

### Style 1: Symmetric (HS256), one shared secret

**HMAC** (Hash-based Message Authentication Code) mixes the data with a secret key through a hash function (SHA-256). The same secret **signs and verifies**.

```
Issuer:    HMAC-SHA256(data, secret) → signature
Verifier:  HMAC-SHA256(data, secret) → compare
```

Simple, fast, and a fine choice when **one app** both creates and checks its own tokens. The weakness: **everyone who can verify can also forge.** If you hand the secret to ten microservices, any of them being hacked lets an attacker mint tokens.

### Style 2: Asymmetric (RS256, ES256), a key pair

This uses the public and private key idea from the TLS lesson:

```
Issuer (auth server):  SIGN(data, PRIVATE key) → signature
Verifier (any API):    VERIFY(data, signature, PUBLIC key) → true / false
```

|Key|Who holds it|Power|
|---|---|---|
|**Private key**|Only the auth server|Can **create** tokens|
|**Public key**|Anyone, even published openly|Can only **verify** tokens|

This is the right design for many services. Your orders API can verify tokens from the auth server but can never forge one, even if the orders API is completely compromised.

### The algorithm families

|`alg`|Type|Notes|
|---|---|---|
|`HS256`|Symmetric (HMAC + SHA-256)|One shared secret of at least 256 bits|
|`RS256`|Asymmetric (RSA)|Very widely supported, larger keys and signatures|
|`ES256`|Asymmetric (elliptic curve)|Smaller and faster than RSA, popular choice today|
|`EdDSA`|Asymmetric (Ed25519)|Modern, compact, fast|
|`none`|**No signature**|**Dangerous. Reject always.** (More below.)|

## Where does the verifier get the public key? JWKS

An auth server publishes its public keys at a URL, as a **JWK Set** (JSON Web Key Set):

```json
{
  "keys": [
    {
      "kty": "RSA",
      "kid": "2026-10-key",
      "use": "sig",
      "alg": "RS256",
      "n": "0vx7agoebGcQSuu...",
      "e": "AQAB"
    }
  ]
}
```

|Field|Meaning|
|---|---|
|`kty`|Key type (`RSA`, `EC`)|
|`kid`|**Key ID**, a label for this key|
|`use`|`sig` means used for signatures|
|`n`, `e`|The RSA public key's numbers|

The token's header carries a matching `kid`:

```json
{ "alg": "RS256", "typ": "JWT", "kid": "2026-10-key" }
```

The verifier reads `kid`, finds that key in the JWKS, and verifies. This makes **key rotation** painless. The auth server adds a new key, starts signing with it, and keeps the old one in the set until old tokens expire. Nobody has to redeploy.

---

# Part 4: Verification, the full checklist

Checking the signature is only the **first** step. A signature proves the token is genuine, not that it's **right for you, right now**.

```
1. Split into 3 parts; reject if it isn't exactly 3
2. Look at the header's alg and kid
      → alg must be one YOU expect (never trust the token to choose)
3. Find the key (by kid, from your trusted configured source)
4. Verify the signature                         → bad = REJECT
5. exp: has it expired? (allow small leeway)     → expired = REJECT
6. nbf: is it valid yet?                         → too early = REJECT
7. iss: is the issuer one you trust?             → no = REJECT
8. aud: is the token meant for THIS service?     → no = REJECT
9. Now trust the claims and use them (sub, roles...)
```

Why steps 7 and 8 matter: imagine two services, both trusting the same auth server. A token issued for the **chat API** has a valid signature, but if the **payments API** accepts it, an attacker with a chat token can call payments. The `aud` check stops that. Skipping claim checks is one of the most common real-world JWT mistakes.

---

# Part 5: JWT in the whole login picture

Here's how it fits with what you've learned:

```
1. Client → Auth server:  POST /login   (username + password, over HTTPS)
2. Auth server:           checks credentials in the database
3. Auth server → Client:  { "access_token": "eyJ...", "refresh_token": "d4f9...", "expires_in": 900 }

4. Client → API:          GET /orders
                          Authorization: Bearer eyJ...
5. API:                   verifies signature + exp + iss + aud   (no database!)
6. API → Client:          200 OK + orders

...15 minutes later, the access token expires...

7. API → Client:          401 Unauthorized
8. Client → Auth server:  POST /token  (sends the refresh token)
9. Auth server → Client:  a new access token (and often a new refresh token)
```

Connecting it to earlier lessons:

|Earlier idea|Where it shows up here|
|---|---|
|`Authorization` header (manual carrier)|Step 4, the JWT travels as `Bearer <token>`|
|Access vs refresh tokens|Steps 3 and 8, a short-lived JWT and a long-lived renewer|
|Opaque tokens|The **refresh token** is usually opaque, stored in the database, so it _can_ be revoked|
|401 vs 403|Bad or expired token gives 401, valid token with insufficient rights gives 403|
|CORS preflight|The `Authorization` header triggers one, so your server must allow it|

So real systems are usually a **hybrid**: stateless JWT access tokens for speed, with stateful refresh tokens for control.

## Where should the client keep it?

(Recap from the token lesson, since this is where JWT choices matter most.)

|Storage|Pros|Cons|
|---|---|---|
|`localStorage`|Easy to use|**Any XSS can read it**|
|Memory only (JS variable)|Harder to steal|Lost on page refresh|
|`HttpOnly` cookie|JavaScript can't read it|Sent automatically, so you need CSRF protection and `SameSite`|
|Mobile secure storage (Keychain/Keystore)|The right choice for mobile apps|Platform-specific|

A good pattern for browser apps: put the **refresh token** in an `HttpOnly`, `Secure`, `SameSite` cookie, keep the **access token** in memory, and refresh on page load.

---

# Part 6: The big weakness, revocation

A session can be killed instantly by deleting it. A JWT is valid until `exp`, and the server has no list to cross it off. If a token is stolen, or a user is fired, or an admin role is removed, the old token keeps working.

Your options, from simple to strict:

|Approach|How it works|Trade-off|
|---|---|---|
|**Short expiry** (5 to 15 min)|Damage window is tiny|Needs refresh tokens|
|**Revoke the refresh token**|Stops new access tokens from being issued|Access token still works until it expires|
|**Denylist by `jti`**|Server keeps a list (in Redis) of revoked token ids and checks it|Brings back a lookup, partly defeating "stateless"|
|**Token version number**|Store `tokenVersion` in the user row and in the token. Bump it to invalidate all old tokens|One cheap lookup per request|
|**Refresh token rotation**|New refresh token each use. Reuse of an old one signals theft, so revoke the whole family|Needs server-side tracking|
|**Opaque tokens + introspection**|Use a random token and ask the auth server "is this valid?" each time|Back to a lookup, but with full control|

There's no free lunch. **The more instantly you can revoke, the more you remember on the server.**

---

# Part 7: Attacks and how to stop them

|Attack|What the attacker does|Defense|
|---|---|---|
|**`alg: none`**|Edits the header to `"alg":"none"`, removes the signature, hoping the library skips verification|Your code decides which algorithms are allowed. Reject `none`. Modern libraries refuse it, but never write your own parser.|
|**Algorithm confusion**|Your server uses an RSA public key to verify. The attacker sets `alg: HS256` and signs with that **public key** as the HMAC secret. A naive library obeys the header and "verifies" it.|**Pin the expected algorithm** to each key. Never let the token choose.|
|**Weak HS256 secret**|Captures one token, then guesses secrets offline (e.g., `secret123`) until the signature matches|Use a random secret of at least 256 bits (32 bytes). Better yet, use asymmetric keys.|
|**Malicious header fields**|Sets `jku`, `x5u`, or `jwk` in the header to point at the attacker's own key, or abuses `kid` (path traversal, SQL injection)|**Ignore header-supplied key locations.** Use only keys from your own configured JWKS. Treat `kid` as an untrusted lookup string.|
|**Skipped claim checks**|Reuses a valid token from another service or tenant|Always validate `iss`, `aud`, `exp`|
|**Token theft via XSS**|Reads it from `localStorage`|Prevent XSS (output encoding, CSP), or use `HttpOnly` cookies|
|**Token in URL**|Token ends up in logs, history, `Referer`|Use headers only, never `?token=...`|
|**Replay**|Reuses a captured token|HTTPS everywhere, short expiry. Advanced systems bind tokens to a client (DPoP, mTLS).|
|**Secrets in payload**|Just base64-decodes your token and reads|Never put passwords, keys, or sensitive personal data in it|
|**ID token as access token**|Uses the login proof to call an API|Keep roles separate: the access token is for APIs and the ID token is for your app|

The first two attacks share a root cause: **the token is attacker-controlled input, including its header.** Treat the header like any other untrusted data.

---

# Part 8: Signed vs encrypted (JWS vs JWE)

"JWT" is really a _container format_. It comes in two forms:

|Form|Name|Parts|Protects against|
|---|---|---|---|
|**Signed**|**JWS**|3 (header.payload.signature)|**Tampering.** Anyone can still read it.|
|**Encrypted**|**JWE**|5 parts|**Reading** too. Only the key holder can see the claims.|

Nearly all JWTs you'll meet are JWS, the three-part ones. Use JWE only when claims truly must be hidden from the client holding the token. Most of the time, the simpler answer is better: **just don't put secrets in the token.**

---

# Part 9: Try it yourself on Debian

## Experiment 1: Decode a token, no tools but bash

First, a small helper that handles Base64URL (it swaps the characters back and restores padding):

```bash
b64d() {
  local s="$1"
  s="${s//-/+}"; s="${s//_//}"
  while (( ${#s} % 4 )); do s+="="; done
  printf '%s' "$s" | base64 -d
}
```

Line by line:

- `${s//-/+}` replaces every `-` with `+`, and `${s//_//}` replaces every `_` with `/`. This undoes Base64URL.
- The `while` loop adds `=` until the length is a multiple of 4, restoring the padding.
- `base64 -d` decodes it.

Use it:

```bash
TOKEN='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c'
b64d "$(echo "$TOKEN" | cut -d. -f1)"; echo
b64d "$(echo "$TOKEN" | cut -d. -f2)"; echo
```

`cut -d. -f1` splits on dots and takes part 1 (the header), and `-f2` takes part 2 (the payload). You'll see the JSON. Nothing was secret.

## Experiment 2: Build and sign a token yourself

```bash
b64url() { base64 -w0 | tr '+/' '-_' | tr -d '='; }

SECRET='your-256-bit-secret'
HEADER=$(printf '%s' '{"alg":"HS256","typ":"JWT"}' | b64url)
PAYLOAD=$(printf '%s' '{"sub":"1234567890","name":"John Doe","iat":1516239022}' | b64url)
SIG=$(printf '%s' "$HEADER.$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" -binary | b64url)

echo "$HEADER.$PAYLOAD.$SIG"
```

Line by line:

- `b64url` is the reverse helper: encode, swap `+/` to `-_`, and strip `=`.
- `HEADER` and `PAYLOAD` are the JSON texts encoded.
- `openssl dgst -sha256 -hmac "$SECRET" -binary` computes the HMAC over `header.payload`. `-binary` outputs raw bytes so we can encode them ourselves.
- The last line joins the three parts with dots.

If you typed the JSON exactly as shown, you should get the very same token as the sample at the top of this lesson, which proves a JWT has no magic in it.

## Experiment 3: Tamper with it

```bash
EVIL=$(printf '%s' '{"sub":"1234567890","name":"Admin","iat":1516239022}' | b64url)
echo "$HEADER.$EVIL.$SIG"
```

You've swapped in a new payload but kept the old signature. Now recompute the signature the server would expect:

```bash
printf '%s' "$HEADER.$EVIL" | openssl dgst -sha256 -hmac "$SECRET" -binary | b64url; echo
```

The result differs from `$SIG`, so the server would reject your forged token. Only someone with the secret can produce the matching one.

## Experiment 4: The same thing in plain Java

This teaches the mechanics. It's for learning, **not production**:

```java
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;

public class TinyJwt {

    private static final Base64.Encoder B64 = Base64.getUrlEncoder().withoutPadding();

    static String hmac(String data, byte[] secret) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secret, "HmacSHA256"));
        byte[] raw = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
        return B64.encodeToString(raw);
    }

    static String create(String payloadJson, byte[] secret) throws Exception {
        String header = B64.encodeToString(
                "{\"alg\":\"HS256\",\"typ\":\"JWT\"}".getBytes(StandardCharsets.UTF_8));
        String payload = B64.encodeToString(payloadJson.getBytes(StandardCharsets.UTF_8));
        String signingInput = header + "." + payload;
        return signingInput + "." + hmac(signingInput, secret);
    }

    static boolean verify(String token, byte[] secret) throws Exception {
        String[] parts = token.split("\\.");
        if (parts.length != 3) return false;
        String expected = hmac(parts[0] + "." + parts[1], secret);
        return MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.UTF_8),
                parts[2].getBytes(StandardCharsets.UTF_8));
    }

    public static void main(String[] args) throws Exception {
        byte[] secret = "a-very-long-random-secret-at-least-32-bytes!".getBytes(StandardCharsets.UTF_8);
        String token = create("{\"sub\":\"alice\",\"roles\":[\"USER\"]}", secret);
        System.out.println(token);
        System.out.println("valid? " + verify(token, secret));
        System.out.println("tampered valid? " + verify(token.replace('a', 'b'), secret));
    }
}
```

Line by line:

- `Base64.getUrlEncoder().withoutPadding()` is Java's built-in Base64URL, exactly the JWT format.
- `Mac.getInstance("HmacSHA256")` gets Java's HMAC-SHA256 engine, and `mac.init(...)` loads the secret key into it.
- `mac.doFinal(...)` computes the signature bytes, which we encode as Base64URL text.
- `create` builds `header.payload`, signs it, and appends the signature. The header is **hardcoded** as HS256, so we never read the algorithm from a token.
- `verify` recomputes the expected signature and compares it with the one in the token.
- `MessageDigest.isEqual` compares in **constant time**. A normal `equals` stops at the first mismatch, and tiny timing differences can leak information to a patient attacker.
- This version **doesn't check `exp`, `iss`, or `aud`**, and doesn't parse JSON. Real code needs all of that, which is why you use a library.

## Experiment 5: Do it properly with a library

**Nimbus JOSE + JWT** is the library Spring Security uses internally. Add it to your `pom.xml` (look up the latest version on Maven Central):

```xml
<dependency>
    <groupId>com.nimbusds</groupId>
    <artifactId>nimbus-jose-jwt</artifactId>
</dependency>
```

If you're in a Spring Boot project that already has the OAuth2 resource server starter, it's already on your classpath.

**Creating a token:**

```java
byte[] secret = new byte[32];
new SecureRandom().nextBytes(secret);

JWTClaimsSet claims = new JWTClaimsSet.Builder()
        .issuer("https://auth.example.com")
        .subject("user-42")
        .audience("orders-api")
        .issueTime(new Date())
        .expirationTime(new Date(System.currentTimeMillis() + 15 * 60 * 1000))
        .jwtID(UUID.randomUUID().toString())
        .claim("roles", List.of("USER"))
        .build();

SignedJWT jwt = new SignedJWT(new JWSHeader(JWSAlgorithm.HS256), claims);
jwt.sign(new MACSigner(secret));
String token = jwt.serialize();
```

Line by line:

- `new SecureRandom().nextBytes(secret)` makes a random 32-byte (256-bit) key. In a real app, you'd load it from configuration, not generate a new one at every start, or old tokens would stop working.
- `JWTClaimsSet.Builder` assembles the claims. Each method matches a registered claim name from Part 2.
- `expirationTime(new Date(now + 15 * 60 * 1000))` is 15 minutes ahead. `Date` uses **milliseconds**, and the library converts to seconds when writing the token.
- `.claim("roles", ...)` adds a custom claim.
- `new JWSHeader(JWSAlgorithm.HS256)` creates the header. `jwt.sign(new MACSigner(secret))` signs it. `MACSigner` rejects secrets shorter than 256 bits for HS256, which saves you from weak keys.
- `jwt.serialize()` produces the final `header.payload.signature` string.

**Verifying a token:**

```java
SignedJWT parsed = SignedJWT.parse(token);

if (!JWSAlgorithm.HS256.equals(parsed.getHeader().getAlgorithm())) {
    throw new SecurityException("Unexpected algorithm");
}
if (!parsed.verify(new MACVerifier(secret))) {
    throw new SecurityException("Bad signature");
}

JWTClaimsSet c = parsed.getJWTClaimsSet();
Date now = new Date();
if (c.getExpirationTime() == null || c.getExpirationTime().before(now)) {
    throw new SecurityException("Expired");
}
if (!"https://auth.example.com".equals(c.getIssuer())) {
    throw new SecurityException("Wrong issuer");
}
if (!c.getAudience().contains("orders-api")) {
    throw new SecurityException("Wrong audience");
}
List<String> roles = (List<String>) c.getClaim("roles");
```

Line by line:

- `SignedJWT.parse(token)` splits and decodes the token. **Parsing doesn't verify anything.** It's the same as decoding by hand.
- The first `if` pins the algorithm, the defense against `none` and algorithm confusion.
- `parsed.verify(new MACVerifier(secret))` is the real signature check.
- Only **after** that do we read the claims and check `exp`, `iss`, and `aud`. Notice the order: verify first, trust second.
- `getClaim("roles")` gives back the custom claim, already parsed from JSON.

**The asymmetric version** (private key signs, public key verifies):

```java
RSAKey rsaKey = new RSAKeyGenerator(2048).keyID("2026-10-key").generate();

SignedJWT jwt = new SignedJWT(
        new JWSHeader.Builder(JWSAlgorithm.RS256).keyID(rsaKey.getKeyID()).build(),
        claims);
jwt.sign(new RSASSASigner(rsaKey));

boolean ok = jwt.verify(new RSASSAVerifier(rsaKey.toRSAPublicKey()));
```

- `RSAKeyGenerator(2048)` creates a 2048-bit RSA key pair, and `keyID(...)` sets the `kid` label.
- `RSASSASigner(rsaKey)` signs with the **private** key (the auth server's job).
- `RSASSAVerifier(rsaKey.toRSAPublicKey())` verifies with only the **public** key (any API's job). This is the setup that makes microservices safe.
- `rsaKey.toPublicJWK()` gives you the JSON you'd publish at a JWKS URL.

---

# Part 10: A small preview of JWT in Spring Security

This is just enough to connect the dots. The deep dive comes later.

```properties
spring.security.oauth2.resourceserver.jwt.jwk-set-uri=https://auth.example.com/.well-known/jwks.json
spring.security.oauth2.resourceserver.jwt.issuer-uri=https://auth.example.com
```

```java
@Bean
SecurityFilterChain api(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(a -> a.anyRequest().authenticated())
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .oauth2ResourceServer(o -> o.jwt(Customizer.withDefaults()));
    return http.build();
}
```

What each piece does:

- `jwk-set-uri` tells Spring where to fetch the **public keys** (Part 3). It caches them and finds the right one by `kid`.
- `issuer-uri` makes Spring check the `iss` claim, and can discover the JWKS URL for you.
- `STATELESS` means "never create a session." Every request must carry its own token.
- `oauth2ResourceServer(... jwt ...)` adds the filter that reads `Authorization: Bearer`, verifies signature, `exp`, and `nbf`, and builds the logged-in user from the claims. Audience checks you add yourself with a custom validator.
- By default, Spring turns the `scope` claim into authorities named `SCOPE_read` and so on. If your roles live in a `roles` claim, you map them yourself:

```java
JwtGrantedAuthoritiesConverter granted = new JwtGrantedAuthoritiesConverter();
granted.setAuthoritiesClaimName("roles");
granted.setAuthorityPrefix("ROLE_");

JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
converter.setJwtGrantedAuthoritiesConverter(granted);
```

You'd then pass it with `o.jwt(j -> j.jwtAuthenticationConverter(converter))`. After that, `hasRole("USER")` works against the token's `roles` claim.

CSRF is normally turned off for such an API, because there's no automatic cookie to abuse. That follows the rule from the CSRF lesson: no automatic credential, no CSRF.

---

# Common mistakes

|Mistake|Why it hurts|Fix|
|---|---|---|
|Thinking JWT is encrypted|Anyone can read the payload|No secrets in it. Use JWE only if you truly need hiding.|
|Verifying nothing but the signature|Tokens from other services or expired ones get accepted|Check `exp`, `iss`, `aud`|
|Letting the token's `alg` choose the method|`none` and algorithm confusion attacks|Pin the algorithm in your code|
|Short or guessable HS256 secret|Offline brute force|32+ random bytes, or use RS256/ES256|
|Hardcoding the secret in source code|It leaks through Git|Load from environment or a secrets manager|
|Very long-lived access tokens (days)|A stolen token stays useful|5 to 15 minutes, plus refresh tokens|
|Treating JWT as a session replacement without a revocation plan|Can't log out or ban users promptly|Short expiry, refresh rotation, denylist or version number|
|Stuffing lots of data into claims|Huge headers, stale data|Small tokens, load details from the database|
|Storing tokens in `localStorage` with weak XSS defenses|One XSS bug leaks every token|Strong CSP and encoding, or `HttpOnly` cookies|
|Writing your own JWT parser|Subtle security bugs|Use Nimbus, jjwt, or Spring's built-in support|
|Confusing seconds and milliseconds|Wrong expiry times|`exp` is in seconds|

---

## Related concept, briefly

**Token introspection (RFC 7662):** this is the middle path between JWT and sessions. The token is **opaque** (a random string), and the API asks the auth server "is this token valid, and who is it for?" through an introspection endpoint. You pay one network call per check (often cached), but you can revoke instantly and keep claims fresh. Spring Security supports it with `o.opaqueToken(...)`. Choose JWT for speed and independence between services, and choose opaque tokens when immediate control matters more.

---

## The whole picture

|Question|Answer|
|---|---|
|What is a JWT?|A signed string carrying claims: `header.payload.signature`|
|Is it secret?|**No.** Base64URL is encoding, so anyone can read it.|
|What does the signature prove?|The content hasn't been changed, and a key holder made it|
|HS256 vs RS256?|One shared secret (signs and verifies) vs private key signs, public key verifies|
|What must a verifier check?|Algorithm, signature, `exp`, `nbf`, `iss`, `aud`|
|How is it sent?|`Authorization: Bearer <token>`|
|What's JWT's main strength?|No lookup, so it scales across services|
|What's its main weakness?|Hard to revoke before `exp`|
|How do real systems cope?|Short access tokens plus rotating, server-tracked refresh tokens|
|Biggest attacks?|`alg: none`, algorithm confusion, weak secrets, skipped claim checks, XSS theft|
|Which library should you use?|Nimbus or jjwt in plain Java, Spring Security's resource server in Spring|

You now have the full foundation: networking, HTTP, cookies, sessions, and tokens. Everything in Spring Security is built from these pieces. 


[[Spring Security]]