![[JWT Authentication Flow Infographic.png]]

A JWT is a small, signed piece of text that carries facts about a user, for example "this is Ahmed, he has the ADMIN role, and this proof expires in 15 minutes". Because it is **signed**, anyone who receives it can check that it was really issued by a trusted party and that nobody changed it along the way. The server doesn't need to remember anything about it: no session table, no lookup. The token itself is the proof.

You met JWTs in the SSO lesson, where the ID token and the access token were JWTs. Here we open one up. We will decode one by hand, sign and verify one with plain Java, then do it the Spring Security way, and finally cover the things that go wrong in real projects: revocation, refresh, storage, and attacks.

---

## 1. Anatomy: three parts, two dots

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhaG1lZCIsInJvbGVzIjpbIlVTRVIiXSwiZXhwIjoxNzkwMDAwMzAwfQ.k8vQ...
|_____________ header _____________| |_____________________ payload _____________________| |_ signature _|
```

|Part|What it holds|Example (decoded)|
|---|---|---|
|**Header**|How the token is signed|`{"alg":"HS256","typ":"JWT"}`|
|**Payload**|The claims (facts)|`{"sub":"ahmed","roles":["USER"],"exp":1790000300}`|
|**Signature**|Proof nobody changed header or payload|binary bytes, Base64URL encoded|

The first two parts are **just Base64URL-encoded JSON**. That is encoding, not encryption. **Anyone can read a JWT's payload**, so never put passwords or secrets inside.

### 1.1 Decode a token yourself

```java
import java.util.Base64;
import static java.nio.charset.StandardCharsets.UTF_8;

public class DecodeJwt {
    public static void main(String[] args) {
        String jwt = args[0];
        String[] parts = jwt.split("\\.");

        Base64.Decoder decoder = Base64.getUrlDecoder();
        System.out.println("HEADER : " + new String(decoder.decode(parts[0]), UTF_8));
        System.out.println("PAYLOAD: " + new String(decoder.decode(parts[1]), UTF_8));
        System.out.println("SIGNATURE bytes: " + decoder.decode(parts[2]).length);
    }
}
```

- `split("\\.")` : cuts the token at the dots (the dot must be escaped in a regex).
- `getUrlDecoder()` : JWT uses the **URL-safe** Base64 alphabet (`-` and `_` instead of `+` and `/`, no `=` padding). Using `getDecoder()` would fail.
- We never touch the signature as text, because it is raw bytes.

---

## 2. Claims: the facts inside

Some claim names are standardized (the "registered claims"). You can add your own.

|Claim|Name|Meaning|
|---|---|---|
|`iss`|Issuer|Who created the token|
|`sub`|Subject|Who the token is about (user id)|
|`aud`|Audience|Who the token is meant for|
|`exp`|Expiration|Unix time after which it is invalid|
|`nbf`|Not before|Unix time before which it is invalid|
|`iat`|Issued at|When it was created|
|`jti`|JWT ID|Unique id of this token (useful for revocation)|

Custom claims are free-form: `roles`, `email`, `tenantId`, and so on. Times are **seconds** since 1970, not milliseconds. That is a classic bug when you build tokens by hand.

---

## 3. Signing: what the signature really is

The signature is computed over the text `base64url(header) + "." + base64url(payload)`. Change one character of either part and the signature no longer matches.

### 3.1 Build and verify an HS256 token with plain Java (no libraries)

```java
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.security.MessageDigest;
import java.util.Base64;
import static java.nio.charset.StandardCharsets.UTF_8;

public class TinyJwt {

    private static final byte[] SECRET = "change-me-use-at-least-32-random-bytes!!".getBytes(UTF_8);

    static String b64(byte[] bytes) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    static byte[] hmac(String data) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(SECRET, "HmacSHA256"));
        return mac.doFinal(data.getBytes(UTF_8));
    }

    static String create(String json) throws Exception {
        String header  = b64("{\"alg\":\"HS256\",\"typ\":\"JWT\"}".getBytes(UTF_8));
        String payload = b64(json.getBytes(UTF_8));
        String signingInput = header + "." + payload;
        return signingInput + "." + b64(hmac(signingInput));
    }

    static boolean verify(String jwt) throws Exception {
        String[] p = jwt.split("\\.");
        if (p.length != 3) return false;

        byte[] expected = hmac(p[0] + "." + p[1]);
        byte[] actual   = Base64.getUrlDecoder().decode(p[2]);
        return MessageDigest.isEqual(expected, actual);   // constant-time comparison
    }

    public static void main(String[] args) throws Exception {
        long exp = System.currentTimeMillis() / 1000 + 900;   // seconds, +15 min
        String token = create("{\"sub\":\"ahmed\",\"roles\":[\"USER\"],\"exp\":" + exp + "}");

        System.out.println(token);
        System.out.println("valid?    " + verify(token));

        String[] p = token.split("\\.");
        String forged = p[0] + "." + b64("{\"sub\":\"ahmed\",\"roles\":[\"ADMIN\"]}".getBytes(UTF_8)) + "." + p[2];
        System.out.println("forged ok? " + verify(forged));    // false
    }
}
```

Walkthrough:

- `hmac(...)` : HMAC-SHA256 mixes the secret with the data. Without the secret, nobody can produce a matching signature.
- `create(...)` : header, dot, payload, dot, signature. This is the complete JWT algorithm.
- `verify(...)` : recompute the signature and compare. We use `MessageDigest.isEqual` instead of `Arrays.equals` because it takes constant time, which prevents timing attacks.
- The forged token swaps `USER` for `ADMIN` but keeps the old signature, so `verify` returns `false`.

This is not production code. It does not check `exp`, `iss`, or `aud`, and it trusts the header. Real libraries handle that. It just shows that **a JWT is not magic**.

### 3.2 Which algorithm?

|Algorithm|Type|Who has which key|Use when|
|---|---|---|---|
|**HS256**|Symmetric (HMAC)|The same secret signs **and** verifies|One app issues and checks its own tokens|
|**RS256**|Asymmetric (RSA)|Private key signs, public key verifies|Many services verify tokens from one issuer (SSO!)|
|**ES256**|Asymmetric (ECDSA)|Same as RSA, smaller keys and tokens|Same as RS256, newer systems|

The key idea: with HS256, **everyone who can verify can also forge**. With RS256, the resource servers get only the public key, so they cannot mint tokens. That is why Keycloak, Okta, and Google use RS256. They publish their public keys at a **JWKS URL**, which is exactly what Spring downloads in the SSO lesson.

---

## 4. The Spring Security way: a complete working lab

We build an app that **issues** JWTs at `/auth/login` and **validates** them on `/api/**`. This uses RS256 so the design matches real SSO systems.

### 4.1 Dependencies

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-security</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
</dependency>
```

The resource-server starter brings in Nimbus JOSE + JWT, which Spring uses for encoding and decoding.

### 4.2 Create an RSA key pair

```bash
openssl genrsa -out keypair.pem 2048
openssl rsa -in keypair.pem -pubout -out src/main/resources/public.pem
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in keypair.pem -out src/main/resources/private.pem
rm keypair.pem
```

Spring wants the private key in **PKCS#8** format, which is why the third command exists. Never commit `private.pem` to Git (add it to `.gitignore` and mount it in production).

```yaml
jwt:
  public-key: classpath:public.pem
  private-key: classpath:private.pem
```

### 4.3 Encoder and decoder beans

```java
@Configuration
public class JwtConfig {

    @Value("${jwt.public-key}")  RSAPublicKey publicKey;
    @Value("${jwt.private-key}") RSAPrivateKey privateKey;

    @Bean
    JwtEncoder jwtEncoder() {
        JWK jwk = new RSAKey.Builder(publicKey).privateKey(privateKey).build();
        return new NimbusJwtEncoder(new ImmutableJWKSet<>(new JWKSet(jwk)));
    }

    @Bean
    JwtDecoder jwtDecoder() {
        return NimbusJwtDecoder.withPublicKey(publicKey).build();
    }
}
```

- `JwtEncoder` **creates** tokens and needs the private key.
- `JwtDecoder` **verifies** tokens and needs only the public key. Spring injects `RSAPublicKey` and `RSAPrivateKey` straight from the PEM files.
- By default `NimbusJwtDecoder` validates the signature and the timestamps (`exp`, `nbf`). It does **not** check `iss` or `aud`. Section 6 adds that.

### 4.4 A service that issues tokens

```java
@Service
public class TokenService {

    private final JwtEncoder encoder;

    public TokenService(JwtEncoder encoder) {
        this.encoder = encoder;
    }

    public String createAccessToken(Authentication auth) {
        Instant now = Instant.now();

        List<String> roles = auth.getAuthorities().stream()
            .map(GrantedAuthority::getAuthority)          // "ROLE_USER"
            .map(r -> r.replace("ROLE_", ""))             // "USER"
            .toList();

        JwtClaimsSet claims = JwtClaimsSet.builder()
            .issuer("https://my-app.example.com")
            .subject(auth.getName())
            .audience(List.of("my-api"))
            .issuedAt(now)
            .expiresAt(now.plus(15, ChronoUnit.MINUTES))
            .id(UUID.randomUUID().toString())
            .claim("roles", roles)
            .build();

        JwsHeader header = JwsHeader.with(SignatureAlgorithm.RS256).build();

        return encoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
    }
}
```

Line by line:

- `auth.getAuthorities()` : the user's authorities after they passed the password check.
- `.issuer` / `.audience` : who made it and who it is for. We validate both later.
- `.expiresAt(now.plus(15, MINUTES))` : **keep access tokens short.** A stolen token is only useful for 15 minutes.
- `.id(UUID...)` : the `jti`, a unique id we can later put on a denylist.
- `.claim("roles", roles)` : our custom claim.
- `JwsHeader.with(RS256)` : tells the world which algorithm was used.
- `encoder.encode(...)` : signs with the private key and gives back the compact `a.b.c` string.

### 4.5 The login endpoint

```java
record LoginRequest(String username, String password) {}
record TokenResponse(String accessToken, String tokenType, long expiresIn) {}

@RestController
@RequestMapping("/auth")
class AuthController {

    private final AuthenticationManager authenticationManager;
    private final TokenService tokenService;

    AuthController(AuthenticationManager am, TokenService ts) {
        this.authenticationManager = am;
        this.tokenService = ts;
    }

    @PostMapping("/login")
    TokenResponse login(@RequestBody LoginRequest req) {
        Authentication auth = authenticationManager.authenticate(
            UsernamePasswordAuthenticationToken.unauthenticated(req.username(), req.password()));

        return new TokenResponse(tokenService.createAccessToken(auth), "Bearer", 900);
    }
}
```

`authenticate(...)` throws `BadCredentialsException` for wrong passwords. Spring has already checked the password with BCrypt, so we only issue a token on success. The response shape (`tokenType`, `expiresIn`) mirrors OAuth2.

### 4.6 The security configuration

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())                          // no cookies, no CSRF
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/auth/login").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated())
            .oauth2ResourceServer(oauth -> oauth
                .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter())));
        return http.build();
    }

    @Bean
    JwtAuthenticationConverter jwtAuthenticationConverter() {
        var authorities = new JwtGrantedAuthoritiesConverter();
        authorities.setAuthoritiesClaimName("roles");   // read our custom claim
        authorities.setAuthorityPrefix("ROLE_");         // USER -> ROLE_USER

        var converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(authorities);
        return converter;
    }

    // ----- users for the lab (use a database in real life) -----
    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    UserDetailsService users(PasswordEncoder encoder) {
        return new InMemoryUserDetailsManager(
            User.withUsername("ahmed").password(encoder.encode("1234")).roles("USER").build(),
            User.withUsername("admin").password(encoder.encode("admin")).roles("ADMIN", "USER").build());
    }

    @Bean
    AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }
}
```

What the important lines do:

- `STATELESS` : Spring never creates an `HttpSession`. Every request must carry its token.
- `csrf.disable()` : CSRF attacks rely on the browser sending cookies automatically. A bearer token in an `Authorization` header is not sent automatically, so this is safe **as long as you don't keep the token in a cookie** (see section 8).
- `oauth2ResourceServer(...jwt...)` : installs `BearerTokenAuthenticationFilter`, which reads the header, calls your `JwtDecoder`, and builds the `Authentication`.
- `JwtGrantedAuthoritiesConverter` : by default Spring reads the `scope` claim and creates `SCOPE_x` authorities. We point it at our `roles` claim and add the `ROLE_` prefix, so `hasRole("ADMIN")` works.

### 4.7 Protected endpoints

```java
@RestController
@RequestMapping("/api")
class ApiController {

    @GetMapping("/me")
    Map<String, Object> me(@AuthenticationPrincipal Jwt jwt) {
        return Map.of(
            "user", jwt.getSubject(),
            "roles", jwt.getClaimAsStringList("roles"),
            "expiresAt", jwt.getExpiresAt(),
            "tokenId", jwt.getId());
    }

    @GetMapping("/admin/stats")
    Map<String, Object> stats() {
        return Map.of("users", 42);
    }
}
```

### 4.8 Try it

```bash
# 1. Log in and keep the token
TOKEN=$(curl -s -X POST localhost:8080/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"ahmed","password":"1234"}' | jq -r .accessToken)

# 2. Call a protected endpoint
curl -H "Authorization: Bearer $TOKEN" localhost:8080/api/me

# 3. A USER trying an admin endpoint
curl -i -H "Authorization: Bearer $TOKEN" localhost:8080/api/admin/stats     # 403

# 4. No token at all
curl -i localhost:8080/api/me                                               # 401
```

**401 vs 403:** 401 means "I don't know who you are" (missing or invalid token). 403 means "I know who you are, but you are not allowed."

### 4.9 What happens inside on every request

```
Authorization: Bearer eyJ...
   ↓
BearerTokenAuthenticationFilter     reads the header
   ↓
JwtAuthenticationProvider           calls jwtDecoder.decode(token)
   ↓
NimbusJwtDecoder                    1) parse  2) verify signature  3) run validators (exp, nbf, ...)
   ↓
JwtAuthenticationConverter          Jwt → authorities → JwtAuthenticationToken
   ↓
SecurityContextHolder               controller can now use @AuthenticationPrincipal Jwt
```

No database or session is touched. That is the benefit, and also the root of the revocation problem in section 7.

---

## 5. Using a library directly: jjwt (when you are not using Spring's encoder)

Many projects use the `io.jsonwebtoken:jjwt` library. This shows the same idea with HS256:

```java
SecretKey key = Keys.hmacShaKeyFor(secretBytes);          // 32+ bytes for HS256

String jwt = Jwts.builder()
    .subject("ahmed")
    .claim("roles", List.of("USER"))
    .issuedAt(new Date())
    .expiration(Date.from(Instant.now().plus(15, ChronoUnit.MINUTES)))
    .signWith(key)                                        // algorithm chosen from the key size
    .compact();

Claims claims = Jwts.parser()
    .verifyWith(key)
    .build()
    .parseSignedClaims(jwt)                               // throws on bad signature or expiry
    .getPayload();

String user = claims.getSubject();
```

The calls above are for jjwt 0.12 and later. Older tutorials use `parseClaimsJws` and `setSubject`, which are deprecated. If you already use Spring Security's resource server, prefer its built-in Nimbus classes so you write less security code.

---

## 6. Validation: do not stop at the signature

A valid signature only proves the token was issued by someone holding the key. You still decide whether **this token is acceptable here**.

```java
@Bean
JwtDecoder jwtDecoder() {
    NimbusJwtDecoder decoder = NimbusJwtDecoder.withPublicKey(publicKey).build();

    OAuth2TokenValidator<Jwt> withIssuer = JwtValidators.createDefaultWithIssuer("https://my-app.example.com");

    OAuth2TokenValidator<Jwt> withAudience = jwt ->
        jwt.getAudience().contains("my-api")
            ? OAuth2TokenValidatorResult.success()
            : OAuth2TokenValidatorResult.failure(
                new OAuth2Error("invalid_token", "Wrong audience", null));

    decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(withIssuer, withAudience));
    return decoder;
}
```

|Validator|Stops this attack|
|---|---|
|`exp` / `nbf` (default)|Using an old token|
|Issuer|A token from a different system that happens to use the same key type|
|Audience|A token meant for API A being replayed against API B|

---

## 7. Revocation, logout, and refresh tokens

JWTs are **stateless**: the server remembers nothing, so it can't "delete" one. A token stays valid until `exp`. You have three practical tools.

### 7.1 Keep access tokens short, and add a refresh token

|Token|Lifetime|Where it goes|Format|
|---|---|---|---|
|**Access token**|5 to 15 minutes|Sent with every API call|JWT|
|**Refresh token**|Days or weeks|Sent only to `/auth/refresh`|Random string stored in the database|

```java
@Entity
class RefreshToken {
    @Id @GeneratedValue Long id;
    String tokenHash;      // store a SHA-256 hash, never the raw token
    String username;
    Instant expiresAt;
    boolean used;
}
```

```java
@PostMapping("/refresh")
TokenResponse refresh(@RequestBody RefreshRequest req) {
    RefreshToken stored = refreshRepo.findByTokenHash(sha256(req.refreshToken()))
        .filter(t -> !t.used && t.expiresAt.isAfter(Instant.now()))
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));

    stored.used = true;                                   // rotation: each refresh token works once
    refreshRepo.save(stored);

    UserDetails user = userDetailsService.loadUserByUsername(stored.username);
    var auth = UsernamePasswordAuthenticationToken.authenticated(user, null, user.getAuthorities());

    String newRefresh = createAndStoreRefreshToken(user.getUsername());   // returned along with the new access token
    return new TokenResponse(tokenService.createAccessToken(auth), "Bearer", 900);
}
```

Why this design works: the refresh token **is** looked up in the database, so you **can** revoke it. Logging a user out means deleting their refresh tokens, and their access token dies within minutes. Using a refresh token twice (`used` is already true) is a sign of theft, so you can invalidate the whole family.

### 7.2 A denylist on `jti` for instant revocation

When 15 minutes is too long (admin disabled, password changed), store the revoked token ids until they expire and check them on every request:

```java
@Component
class RevocationValidator implements OAuth2TokenValidator<Jwt> {

    private final Set<String> revoked = ConcurrentHashMap.newKeySet();   // use Redis with a TTL in real systems

    void revoke(String jti) { revoked.add(jti); }

    @Override
    public OAuth2TokenValidatorResult validate(Jwt jwt) {
        return revoked.contains(jwt.getId())
            ? OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token", "Token revoked", null))
            : OAuth2TokenValidatorResult.success();
    }
}
```

Add it to the `DelegatingOAuth2TokenValidator` from section 6. Remember what this means: you added state and a lookup per request. A Redis `SET key EX ttl` with the token's remaining lifetime as the TTL fits this need well, so entries clean themselves up.

---

## 8. Where does the browser keep the token?

|Storage|Stolen by XSS (injected JavaScript)?|Sent automatically (CSRF risk)?|
|---|---|---|
|`localStorage` / `sessionStorage`|**Yes**, JS can read it|No|
|`HttpOnly; Secure; SameSite` cookie|**No**, JS can't read it|Yes, so keep CSRF protection on|
|In memory (JS variable)|Harder, but lost on refresh|No|

A common good pattern: access token in memory, refresh token in an `HttpOnly` cookie limited to the `/auth/refresh` path. For classic server-rendered sites, plain sessions (as in the SSO `oauth2Login` lesson) are often simpler and safer than JWTs in the browser.

---

## 9. Attacks and mistakes to avoid

|Mistake|Why it is dangerous|Fix|
|---|---|---|
|Accepting `"alg":"none"`|Attacker sends an unsigned token and the server believes it|Use a library that rejects it. Always pin the expected algorithm.|
|Algorithm confusion (RS256 vs HS256)|Attacker signs with HS256 using your **public** key as the secret, and a careless verifier accepts it|`NimbusJwtDecoder.withPublicKey(...)` is pinned to RSA. Never choose the algorithm from the token header.|
|Weak HS256 secret (`"secret"`)|Can be brute-forced offline from any token|32+ random bytes, kept in a secret store|
|No `exp`|Token lives forever|Always set it, and keep it short|
|Skipping `iss` / `aud` checks|Tokens meant for other apps are accepted|Section 6|
|Personal data or secrets in payload|Payload is readable by anyone|Keep claims minimal|
|Trusting claims for big decisions without checking|A role may have changed since the token was issued|Short lifetimes, or load fresh roles from the database for critical actions|
|Logging tokens|Logs become a credential store|Mask the `Authorization` header|
|Using JWT as a session replacement without a plan for logout|Stolen tokens stay valid|Sections 7.1 and 7.2|

---

## 10. Testing

```java
@WebMvcTest(ApiController.class)
@Import(SecurityConfig.class)
class ApiControllerTest {

    @Autowired MockMvc mvc;
    @MockitoBean JwtDecoder jwtDecoder;      // we skip real decoding in tests

    @Test
    void meReturnsSubject() throws Exception {
        mvc.perform(get("/api/me")
                .with(jwt().jwt(j -> j.subject("ahmed").claim("roles", List.of("USER")))
                           .authorities(new SimpleGrantedAuthority("ROLE_USER"))))
           .andExpect(status().isOk())
           .andExpect(jsonPath("$.user").value("ahmed"));
    }

    @Test
    void userCannotSeeAdminStats() throws Exception {
        mvc.perform(get("/api/admin/stats")
                .with(jwt().authorities(new SimpleGrantedAuthority("ROLE_USER"))))
           .andExpect(status().isForbidden());
    }

    @Test
    void noTokenMeansUnauthorized() throws Exception {
        mvc.perform(get("/api/me")).andExpect(status().isUnauthorized());
    }
}
```

`@MockitoBean` replaces the older `@MockBean` in current Spring Boot versions. The `jwt()` post-processor builds a fake authenticated request, so you don't have to generate real tokens.

---

## Related concepts, in short

- **JWS vs JWE:** a normal JWT is a **JWS** (signed, readable). A **JWE** is encrypted, so the payload is hidden too. Almost everything you meet is a JWS.
- **JWK and JWKS:** a JWK is a public key written as JSON. A JWKS is a list of them served at a URL, and it is how resource servers fetch the issuer's keys and rotate them using the `kid` header.
- **Opaque tokens:** random strings with no content. The resource server asks the IdP "is this valid?" each time. That is slower, but revocation is instant.
- **ID token vs access token:** the ID token says who logged in and is for **your app**. The access token is for **APIs**. Don't send ID tokens to APIs.
- **Bearer token:** anyone holding the token can use it, like cash. This is why HTTPS and short lifetimes matter.

## What to practice next

1. Run the decode and `TinyJwt` programs, then change one character in a token and watch `verify` fail.
2. Build the lab in section 4 and call it with `curl`. Paste your token into a decoder such as jwt.io to see the claims you wrote.
3. Add the issuer and audience validators, then try a token with the wrong `aud`.
4. Add the refresh endpoint with a PostgreSQL table, with rotation.
5. Add the `jti` denylist, backed by Redis once you reach that lesson.




[[Spring Security]]