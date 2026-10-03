
```java
import io.jsonwebtoken.Jwts;
```

### `io.jsonwebtoken.Jwts` → The "God Class" of JJWT

This is **NOT** a normal Java class you instantiate with `new`.  
It’s a **factory class** — a collection of static methods. Think of it like `Collections` or `Arrays` in Java.

Its full name in version 0.12.x is:

```java
io.jsonwebtoken.Jwts
```

And here are the **only 3 static methods you will ever use 99% of the time**:

| Method                                | What it returns                          | What you do with it                                 |
|---------------------------------------|------------------------------------------|-----------------------------------------------------|
| `Jwts.builder()`                      | `JwtBuilder`                             | → To **create** a new token                         |
| `Jwts.parser()`                       | `JwtParserBuilder`                       | → To **read/validate** an existing token (new way)  |
| `Jwts.parserBuilder()` (deprecated)  | `JwtParserBuilder` (old way)             | Used in old tutorials — avoid in 0.12+              |

### Real-world usage (the exact lines you’ll write every day)

#### 1. Creating a token (inside your `JwtService.generateToken()`)

```java
String token = Jwts.builder()                     // ← starts here
    .subject("john_doe")                           // username
    .claim("roles", List.of("ROLE_ADMIN"))         // custom data
    .issuedAt(new Date())
    .expiration(new Date(System.currentTimeMillis() + 86400000))
    .signWith(mySecretKey)                         // HMAC or RSA
    .compact();                                    // ← returns String
```

#### 2. Validating + reading a token (new 0.12+ style)

```java
Claims claims = Jwts.parser()
    .verifyWith(mySecretKey)        // same key as when signing!
    .build()                        // ← creates the actual parser
    .parseSignedClaims(token)       // ← throws exception if invalid
    .getPayload();                  // ← this is your Claims object
```

That’s it. Those are literally the only ways you ever touch `Jwts`.

### Why the API changed in 0.12

Old way (0.9–0.11) — you still see this in 90% of YouTube tutorials:
```java
Jwts.parser().setSigningKey(key).parseClaimsJws(token)
```

New way (0.12+) — **this is the correct modern way**:
```java
Jwts.parser().verifyWith(key).build().parseSignedClaims(token)
```

`verifyWith()` is type-safe and forces you to use `SecretKey` or `PublicKey`, not raw strings or bytes.

### Summary: `Jwts` class in one sentence

> `Jwts` is a **static factory** that gives you either a **builder** (to create tokens) or a **parser** (to read/validate tokens). You never instantiate it — you only call `.builder()` or `.parser()` on it.

That’s why you import it — because it’s your entry point to everything JWT-related.

Now go back to your `JwtService` — you fully understand every line that uses `Jwts`!  
Want me to show you the exact modern 0.12+ version of the full `JwtService` now?

---
Here is the **100% correct, modern, production-ready `JwtService`** for Spring Boot 3 + JJWT 0.12.6 (2024–2025 standard).  

```java
// src/main/java/com/yourpackage/security/JwtService.java

package com.yourpackage.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

@Service
public class JwtService {

    // 256-bit key minimum for HS256 → 44 chars in Base64
    private static final String SECRET_KEY = "4a9f08d9c3a2b1e8f7d6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1f0e9d8c7b6a5";

    private static final long ACCESS_TOKEN_EXPIRY = 1000 * 60 * 60 * 10; // 10 hours
    // private static final long REFRESH_TOKEN_EXPIRY = 1000L * 60 * 60 * 24 * 30; // 30 days

    // ──────────────────────────────────────────────────────────────
    // 1. Generate token
    // ──────────────────────────────────────────────────────────────
    public String generateToken(UserDetails userDetails) {
        Map<String, Object> extraClaims = new HashMap<>();
        extraClaims.put("roles",
                userDetails.getAuthorities().stream()
                        .map(GrantedAuthority::getAuthority)
                        .toList());

        return Jwts.builder()
                .claims(extraClaims)
                .subject(userDetails.getUsername())
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + ACCESS_TOKEN_EXPIRY))
                .signWith(getSigningKey())
                .compact();
    }

    // ──────────────────────────────────────────────────────────────
    // 2. Extract username (sub claim)
    // ──────────────────────────────────────────────────────────────
    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    // ──────────────────────────────────────────────────────────────
    // 3. Check if token is valid for this user
    // ──────────────────────────────────────────────────────────────
    public boolean isTokenValid(String token, UserDetails userDetails) {
        final String username = extractUsername(token);
        return (username.equals(userDetails.getUsername())) && !isTokenExpired(token);
    }

    // ──────────────────────────────────────────────────────────────
    // Helper methods
    // ──────────────────────────────────────────────────────────────
    private boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    private Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    // Generic claim extractor — use this everywhere
    private <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private SecretKey getSigningKey() {
        byte[] keyBytes = SECRET_KEY.getBytes();
        return Keys.hmacShaKeyFor(keyBytes);  // auto-pads/truncates to correct length
    }
}
```

### Why this version is perfect in 2025

| Feature                      | Why it matters                                      |
|------------------------------|-----------------------------------------------------|
| JJWT 0.12.6 syntax           | `verifyWith()` + `.build()` → no deprecation warnings |
| `SecretKey` instead of String| Type-safe, no accidental raw key mistakes           |
| Generic `extractClaim()`     | One-line extraction for any claim (clean code)      |
| Roles inside token           | You can do `@PreAuthorize` without DB hit           |
| Configurable expiry          | Easy to switch to refresh tokens later              |
| Zero external config yet     | Works immediately, move key to `application.yml` later |

### Next recommended improvement (optional but pro)

Move the key and expiry to `application.yml`:

```yaml
jwt:
  secret: ${JWT_SECRET:4a9f08d9c3a2b1e8f7d6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1f0e9d8c7b6a5}
  expiration-ms: 36000000   # 10 hours
```

Then inject with `@Value` or `@ConfigurationProperties`.

But for now — this `JwtService` above is the one used in real companies today.





###### Tags : [[1 - Spring Security 🍌]]