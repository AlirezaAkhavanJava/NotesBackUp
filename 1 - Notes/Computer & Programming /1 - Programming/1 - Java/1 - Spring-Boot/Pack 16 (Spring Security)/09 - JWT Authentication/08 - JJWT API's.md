


JJWT is a Java library for creating and reading **JSON Web Tokens (JWT)**. A JWT is a compact, signed string that carries information (called _claims_) such as a username and an expiration time. Spring Boot apps often use JWTs to keep users logged in without storing sessions on the server.

JJWT is split into three artifacts. Each has a different job.

## What each artifact is

**`jjwt-api`** contains the public classes and interfaces you write code against, such as `Jwts`, `Claims`, and `Keys`. Your code compiles against this artifact.

**`jjwt-impl`** contains the actual logic that creates signatures, encodes and decodes tokens, and validates them. You never import its classes directly. JJWT finds it at runtime through Java's `ServiceLoader` mechanism, so its scope is `runtime`.

**`jjwt-jackson`** is a bridge to the Jackson library, which converts Java objects to JSON and back. JWT payloads are JSON, so JJWT needs a JSON library to work. This artifact tells JJWT to use Jackson. It is also `runtime` scope.

The split lets the API stay stable while the implementation details are swapped out. For example, `jjwt-gson` can replace `jjwt-jackson` if you prefer Gson.

## Adding the dependencies

**Maven (`pom.xml`):**

```xml
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-api</artifactId>
    <version>0.12.6</version>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-impl</artifactId>
    <version>0.12.6</version>
    <scope>runtime</scope>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-jackson</artifactId>
    <version>0.12.6</version>
    <scope>runtime</scope>
</dependency>
```

**Gradle (`build.gradle`):**

```groovy
implementation 'io.jsonwebtoken:jjwt-api:0.12.6'
runtimeOnly 'io.jsonwebtoken:jjwt-impl:0.12.6'
runtimeOnly 'io.jsonwebtoken:jjwt-jackson:0.12.6'
```

Spring Boot's parent POM does not manage JJWT versions, so you must specify one. Check Maven Central for the latest release. The examples below use the 0.12 API. Many older tutorials use `parserBuilder()` and `setSubject()`, which are deprecated in 0.12.

## Example 1: Creating a signing key

```java
import io.jsonwebtoken.security.Keys;
import javax.crypto.SecretKey;

SecretKey key = Keys.secretKeyFor(SignatureAlgorithm.HS256); // older style
// or, in 0.12:
SecretKey key = Jwts.SIG.HS256.key().build();
```

**What it does:** Creates a random secret key for the HS256 algorithm. HS256 is an HMAC signature that uses one shared secret for both signing and verifying.

**Why it matters:** The key must be at least 256 bits (32 bytes) for HS256. The key is what makes a token trustworthy. Anyone who knows the key can create valid tokens, so in a real app you should load it from configuration, not generate it at startup. A random key also changes on every restart, which invalidates all existing tokens.

In a Spring Boot app, you would load the secret from `application.properties`:

```properties
jwt.secret=replace-this-with-a-long-random-string-at-least-32-characters
```

Then convert it into a key:

```java
byte[] keyBytes = secretString.getBytes(StandardCharsets.UTF_8);
SecretKey key = Keys.hmacShaKeyFor(keyBytes);
```

`Keys.hmacShaKeyFor` builds a `SecretKey` from raw bytes. It checks that the key is long enough for the chosen algorithm and throws an exception if it is not.

## Example 2: Creating a token

```java
import io.jsonwebtoken.Jwts;
import java.util.Date;

String token = Jwts.builder()
        .subject("alireza")
        .claim("role", "USER")
        .issuedAt(new Date())
        .expiration(new Date(System.currentTimeMillis() + 3_600_000))
        .signWith(key)
        .compact();
```

**What each part does:**

- `Jwts.builder()` starts building a token.
- `.subject("alireza")` sets the standard `sub` claim, which usually identifies the user.
- `.claim("role", "USER")` adds a custom claim. Claims are the data stored in the token's payload.
- `.issuedAt(...)` sets the `iat` claim, the time the token was created.
- `.expiration(...)` sets the `exp` claim, the time after which the token is no longer valid. Here it is one hour later, measured in milliseconds.
- `.signWith(key)` signs the token. JJWT chooses the algorithm from the key's type.
- `.compact()` produces the final string, which has three parts separated by dots: `header.payload.signature`.

**Why the JSON library matters here:** Claims are stored as JSON in the payload. `jjwt-jackson` is what converts the claims into JSON text. Without it at runtime, you get an error saying JJWT could not find a JSON serializer.

## Example 3: Reading and verifying a token

```java
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;

Claims claims = Jwts.parser()
        .verifyWith(key)
        .build()
        .parseSignedClaims(token)
        .getPayload();

String username = claims.getSubject();
String role = claims.get("role", String.class);
```

**What each part does:**

- `Jwts.parser()` starts building a parser.
- `.verifyWith(key)` tells the parser which key to check the signature against. This is the security step. If the token was changed or signed with a different key, verification fails.
- `.parseSignedClaims(token)` checks the signature, checks the expiration time, and decodes the payload. It throws an exception if anything is wrong.
- `.getPayload()` returns the `Claims` object.
- `claims.get("role", String.class)` reads a custom claim and converts it to the type you ask for. Jackson does the conversion.

**Handling errors:** Invalid tokens throw exceptions that all extend `JwtException`:

```java
try {
    Claims claims = Jwts.parser().verifyWith(key).build()
            .parseSignedClaims(token).getPayload();
} catch (ExpiredJwtException e) {
    // token is past its exp time
} catch (JwtException | IllegalArgumentException e) {
    // bad signature, malformed token, or empty input
}
```

Catching these exceptions is how you reject requests with expired or forged tokens.

## Putting it together in a Spring Boot service

```java
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Service
public class JwtService {

    private final SecretKey key;

    public JwtService(@Value("${jwt.secret}") String secret) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public String generateToken(String username) {
        return Jwts.builder()
                .subject(username)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + 3_600_000))
                .signWith(key)
                .compact();
    }

    public String extractUsername(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
        return claims.getSubject();
    }
}
```

**What each annotation does:**

- `@Service` tells Spring to create one instance of this class and manage it. You can inject it anywhere.
- `@Value("${jwt.secret}")` reads the `jwt.secret` value from `application.properties` and passes it into the constructor.

**Why the key is built in the constructor:** The key is created once when the application starts, not on every request. This is faster and keeps the secret in one place.

## Quick summary

|Artifact|Role|Scope|You import from it?|
|---|---|---|---|
|`jjwt-api`|Public interfaces and builders you write code against|compile (default)|Yes|
|`jjwt-impl`|The real signing and parsing logic|runtime|No|
|`jjwt-jackson`|Connects JJWT to Jackson for JSON|runtime|No|





[[Spring Security]]
