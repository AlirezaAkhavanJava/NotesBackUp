

A JWT (JSON Web Token) has three parts: a header, a payload with your claims (like the username and expiry time), and a signature. The secret key is what produces that signature. When your server creates a token, it runs the header and payload through a signing algorithm (usually HMAC-SHA256) together with the secret key. When the token comes back later, the server repeats the calculation and compares the result with the signature on the token. If they match, nobody changed the token, and only someone holding the key could have made it.

The key doesn't hide anything. The payload of a JWT is only Base64URL-encoded, so anyone can decode and read it. The secret key gives you **integrity and authenticity**, not **secrecy**. If someone steals your key, they can mint a token saying `"sub": "admin"` and your server will accept it, so protecting the key is the most important part of working with JWTs.

## How the signature works

Here is a token split into its parts:

```
eyJhbGciOiJIUzI1NiJ9 . eyJzdWIiOiJhbGljZSIsImV4cCI6MTc2MTU3MDAwMH0 . 3kQ9...x7A
      header                          payload                         signature
```

The server computes the signature like this:

```
signature = HMAC-SHA256( base64url(header) + "." + base64url(payload), secretKey )
```

Suppose an attacker edits the payload to say `"sub": "admin"`. The signature no longer matches the new payload, and they can't compute a new one without the key, so your server rejects the token.

## Symmetric vs asymmetric keys

This is the first design choice you'll make.

||HMAC (HS256/HS384/HS512)|RSA / ECDSA (RS256, ES256)|
|---|---|---|
|Keys|One shared secret|Private key signs, public key verifies|
|Who can create tokens|Anyone with the secret|Only the private key holder|
|Who can verify tokens|Anyone with the secret|Anyone with the public key|
|Best for|One app, or one backend that both issues and checks tokens|Multiple services, or a separate auth server (SSO)|

A single Spring Boot app that issues and validates its own tokens is a good fit for HMAC. If many services need to verify tokens but only one should issue them, use asymmetric keys. Then the other services only ever hold the public key, which is safe to share.

## What makes a good secret

- **It must be long and random.** HS256 needs at least 256 bits (32 bytes). The jjwt library refuses weaker keys. For HS512, use 64 bytes.
- **It must not be a human-written phrase.** A string like `"mySecret123"` can be brute-forced offline. An attacker can take one of your tokens and guess keys until the signature matches.
- **It should differ per environment.** Dev, staging and production each get their own key, so a leaked dev key can't forge production tokens.

Generate one on your Debian machine:

```bash
openssl rand -base64 64
```

On Windows PowerShell, this gives you 64 random bytes in Base64:

```powershell
[Convert]::ToBase64String((1..64 | ForEach-Object { Get-Random -Maximum 256 }))
```

## Where to keep it

Don't hardcode it in your source, and don't commit it to Git. Even if you delete it later, it stays in the history. Put it in an environment variable and let Spring read it:

```properties
# application.properties
jwt.secret=${JWT_SECRET}
```

```bash
# Debian
export JWT_SECRET="paste-your-generated-base64-here"
```

```powershell
# Windows (open a new terminal afterwards)
setx JWT_SECRET "paste-your-generated-base64-here"
```

In production, use a real secrets manager (HashiCorp Vault, AWS Secrets Manager, Kubernetes Secrets, and so on).

## Using it in Spring Boot with jjwt

This uses the jjwt 0.12.x API. Read it line by line:

```java
@Service
public class JwtService {

    private static final long EXPIRATION_MS = 15 * 60 * 1000; // 15 minutes

    private final SecretKey key;

    public JwtService(@Value("${jwt.secret}") String base64Secret) {
        // Turn the Base64 text back into raw bytes, then into a proper HMAC key object
        this.key = Keys.hmacShaKeyFor(Decoders.BASE64.decode(base64Secret));
    }

    public String generateToken(UserDetails user) {
        Date now = new Date();
        return Jwts.builder()
                .subject(user.getUsername())
                .issuedAt(now)
                .expiration(new Date(now.getTime() + EXPIRATION_MS))
                .signWith(key)          // signs with the secret; algorithm is picked from key size
                .compact();             // builds the final "xxx.yyy.zzz" string
    }

    public String extractUsername(String token) {
        return parseClaims(token).getSubject();
    }

    public boolean isValid(String token, UserDetails user) {
        try {
            Claims claims = parseClaims(token);
            return claims.getSubject().equals(user.getUsername());
        } catch (JwtException | IllegalArgumentException e) {
            return false; // bad signature, expired, malformed, etc.
        }
    }

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(key)        // recomputes the signature and compares
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
```

- The constructor builds the `SecretKey` once, so you don't decode it on every request.
- `signWith(key)` signs the token. With a 64-byte key, jjwt chooses HS512 automatically.
- `verifyWith(key)` does the check. If the signature is wrong, it throws a `SignatureException`. If the token is expired, it throws an `ExpiredJwtException`. Both extend `JwtException`, which is why one `catch` covers them.

## Good habits

- **Keep expiry short.** A stolen token is dangerous until it expires, so use minutes for access tokens, and add refresh tokens if users need long sessions.
- **Never put sensitive data in the payload.** No passwords, card numbers or personal data, because anyone can read it.
- **Never log the key or full tokens.**
- **Let the library pin the algorithm.** Passing a `SecretKey` to `verifyWith` means only HMAC tokens are accepted. This blocks the classic attack where a forged token declares `"alg": "none"`.
- **Plan for rotation.** If a key leaks, you must replace it, and every existing token then becomes invalid, so users log in again. For a smoother rotation, add a `kid` (key id) header and keep the old key for verification only until old tokens expire.

## A related concept: key rotation and JWKS

If you move to asymmetric keys later, auth servers publish their public keys at a URL called a **JWKS endpoint** (JSON Web Key Set). Each key has a `kid`, and a token's header names the `kid` it was signed with. Services download the key set, pick the right key, and verify. This is how rotation works at scale, and it's what Spring Security's resource server does for you with OAuth2 and SSO.





[[Spring Security]]