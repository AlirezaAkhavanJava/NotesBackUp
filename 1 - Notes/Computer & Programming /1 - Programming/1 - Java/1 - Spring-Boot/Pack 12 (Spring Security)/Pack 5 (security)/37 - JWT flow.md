JWT authentication in Spring Security works by splitting the job into two phases. First, the user logs in with a username and password, and the server verifies them once and hands back a signed token. Second, the user sends that token with every later request, and a filter that runs before your controllers checks the signature and sets up the security context so Spring knows who is calling. The server doesn't keep a session, so each request carries its own proof of identity. In this lesson we'll build that system step by step, and I'll explain what each piece does and why it exists.

![[JWT Flow in Spring Security 1.png]]


## The Big Picture

Here is the whole journey of a request, before we touch any code:

```
PHASE 1: LOGIN (happens once)
Client ──POST /api/auth/login {user, pass}──► AuthController
                                                  │
                                                  ▼
                                   AuthenticationManager.authenticate()
                                                  │
                                                  ▼
                                   DaoAuthenticationProvider
                                     ├─ UserDetailsService.loadUser()  (fetch user)
                                     └─ PasswordEncoder.matches()      (check password)
                                                  │ success
                                                  ▼
                                   JwtService.generateToken()  ──► signed JWT
Client ◄──────────── { "token": "eyJhbGci..." } ──┘

PHASE 2: EVERY LATER REQUEST
Client ──GET /api/orders   Authorization: Bearer eyJhbGci...──►
          │
          ▼
   JwtAuthenticationFilter
     ├─ read header, strip "Bearer "
     ├─ verify signature and expiry
     ├─ load user, build Authentication
     └─ store it in SecurityContextHolder
          │
          ▼
   AuthorizationFilter  (is this user allowed on /api/orders?)
          │
          ▼
   Controller runs  ──► response
```

Keep this diagram in mind. Each class we write maps onto one box in it.

## Step 1: Dependencies

Add these to your `pom.xml`:

```xml
<dependencies>
    <!-- Web MVC: REST controllers, JSON, embedded Tomcat -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <!-- Spring Security: filters, authentication, authorization -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>

    <!-- JJWT: a library for creating and verifying JWTs (three parts) -->
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
</dependencies>
```

JJWT is split into three artifacts on purpose. `jjwt-api` is the interface you compile against. `jjwt-impl` and `jjwt-jackson` are the implementation and the JSON library, and they're needed only at runtime, which is why they have `runtime` scope. Check the latest JJWT version on Maven Central before you copy this, since the number may have moved on.

Next, add the secret to `application.properties`:

```properties
# Secret used to sign tokens. Read from an environment variable so it never lives in source control.
app.jwt.secret=${JWT_SECRET:change-me-to-a-long-random-string-at-least-32-chars}
# Token lifetime: 1 hour, in milliseconds
app.jwt.expiration-ms=3600000
```

The `${JWT_SECRET:...}` syntax means "use the environment variable `JWT_SECRET` if it exists, otherwise use the fallback after the colon." In production, always set the real variable and never rely on the fallback. HS256 requires a key of at least 256 bits, which is 32 characters of random text.

## Step 2: The Token Service

This class is the only place that knows how tokens are built and checked. Everything else asks it questions.

```java
package com.example.app.security;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Service
public class JwtService {

    private final SecretKey key;
    private final long expirationMs;

    public JwtService(
            @Value("${app.jwt.secret}") String secret,
            @Value("${app.jwt.expiration-ms}") long expirationMs) {
        // Turn the secret text into a cryptographic key for HMAC-SHA256
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationMs = expirationMs;
    }

    // Called after a successful login
    public String generateToken(UserDetails user) {
        long now = System.currentTimeMillis();
        return Jwts.builder()
                .subject(user.getUsername())               // the "sub" claim: who this token belongs to
                .issuedAt(new Date(now))                   // the "iat" claim: when it was created
                .expiration(new Date(now + expirationMs))  // the "exp" claim: when it stops being valid
                .signWith(key)                             // sign with our secret, so it can't be forged
                .compact();                                // produce the final "xxx.yyy.zzz" string
    }

    // Returns the username inside the token, or throws if the token is invalid or expired
    public String extractUsername(String token) {
        return Jwts.parser()
                .verifyWith(key)                           // check the signature using our key
                .build()
                .parseSignedClaims(token)                  // also checks the "exp" date automatically
                .getPayload()
                .getSubject();
    }
}
```

What's happening here: a JWT has three Base64 parts separated by dots, a header, a payload, and a signature. The payload holds claims like `sub` (subject) and `exp` (expiry). The signature is computed from the header and payload using your secret. Anyone can read the payload, because it is only encoded, not encrypted. What they can't do is change it without invalidating the signature. That's why `verifyWith(key)` matters: it's the check that stops someone from editing their username to `admin` and resubmitting the token.

Why `@Value` in the constructor? It keeps the configuration out of the code and makes the class easy to test, since you can pass in any secret.

## Step 3: The Filter That Reads Every Request

This is the heart of the stateless setup. It runs once for each incoming request and tries to log the caller in from their token.

```java
package com.example.app.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import io.jsonwebtoken.JwtException;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;

    public JwtAuthenticationFilter(JwtService jwtService, UserDetailsService userDetailsService) {
        this.jwtService = jwtService;
        this.userDetailsService = userDetailsService;
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        // 1. Read the Authorization header. Expected format: "Bearer eyJhbGci..."
        String header = request.getHeader("Authorization");

        // 2. No token? Pass the request along untouched. Public endpoints still work.
        if (header == null || !header.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        // 3. Remove the "Bearer " prefix (7 characters) to get the raw token
        String token = header.substring(7);

        try {
            // 4. Verify the signature and expiry, and get the username
            String username = jwtService.extractUsername(token);

            // 5. Only set authentication if nobody is logged in for this request yet
            if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {

                // 6. Load the full user (roles included) from the database or wherever users live
                UserDetails user = userDetailsService.loadUserByUsername(username);

                // 7. Build an Authentication object carrying the user's authorities (roles)
                UsernamePasswordAuthenticationToken auth =
                        new UsernamePasswordAuthenticationToken(
                                user,
                                null,                         // no password: the token already proved identity
                                user.getAuthorities());

                auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                // 8. Store it in the security context. From here on, Spring treats the caller as logged in.
                SecurityContextHolder.getContext().setAuthentication(auth);
            }
        } catch (JwtException e) {
            // 9. Bad signature, expired, or malformed token: log nobody in and keep going.
            //    The authorization rules will then reject the request with 401 if the route is protected.
            //    We don't throw here, because that would produce a confusing error page.
        }

        // 10. Always continue the chain, whether or not we authenticated the caller
        filterChain.doFilter(request, response);
    }
}
```

Walking through the important parts:

`OncePerRequestFilter` guarantees the code runs exactly once per request, even when the request is forwarded internally. Without it, the filter could run twice.

The filter doesn't reject bad tokens itself. It only tries to authenticate. Deciding whether a request is allowed is the job of the authorization rules in the next step. This separation is deliberate: the filter answers "who is this?", and the config answers "are they allowed here?"

The `null` password in step 7 looks odd but is correct. The password was checked at login. The token is the proof from then on, so storing or rechecking the password would be pointless.

`SecurityContextHolder` is a thread-local holder. Spring uses it to find the current user anywhere during the request. Inside a controller you could call `SecurityContextHolder.getContext().getAuthentication().getName()` to get the username.

## Step 4: Configuring the Security Rules

Now we tell Spring which URLs are public, which are protected, and where our filter fits in.

```java
package com.example.app.config;

import com.example.app.security.JwtAuthenticationFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtFilter;

    public SecurityConfig(JwtAuthenticationFilter jwtFilter) {
        this.jwtFilter = jwtFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // CSRF protection protects browser sessions that use cookies.
            // We send the token manually in a header, so there is no cookie to abuse. Turn it off.
            .csrf(csrf -> csrf.disable())

            // Don't create or use HTTP sessions. Every request must prove its identity itself.
            .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

            // URL rules, checked in order. The first match wins.
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()   // login and register are public
                .anyRequest().authenticated()                  // everything else needs a valid token
            )

            // Put our filter in front of the standard username/password filter.
            // Ours runs first, so the context is already filled when the rules are checked.
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    // Used by the login controller to verify credentials
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    // Hashes passwords with bcrypt. Plain-text passwords are never stored.
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

Key details:

`@EnableWebSecurity` switches on Spring Security's web support. `@Configuration` marks the class as a source of beans.

`SecurityFilterChain` is the modern way to configure security (Spring Security 6 and later). The older `WebSecurityConfigurerAdapter` is gone and shouldn't appear in new code.

`requestMatchers` followed by `permitAll()` or `authenticated()` defines the rules. Order matters, because the first match wins, so put specific rules before `anyRequest()`.

`STATELESS` tells Spring never to create a session. This is what makes JWT different from the classic cookie-session approach.

`addFilterBefore(...)` inserts our filter into the chain at the right position. Placing it before `UsernamePasswordAuthenticationFilter` means the token is processed before the authorization check.

`BCryptPasswordEncoder` is what the login uses to compare the typed password with the stored hash. It's slow on purpose, which makes brute-force attacks expensive.

## Step 5: The Login Endpoint

```java
package com.example.app.controller;

import com.example.app.security.JwtService;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final UserDetailsService userDetailsService;
    private final JwtService jwtService;

    public AuthController(AuthenticationManager authenticationManager,
                          UserDetailsService userDetailsService,
                          JwtService jwtService) {
        this.authenticationManager = authenticationManager;
        this.userDetailsService = userDetailsService;
        this.jwtService = jwtService;
    }

    public record LoginRequest(String username, String password) {}

    @PostMapping("/login")
    public Map<String, String> login(@RequestBody LoginRequest request) {

        // 1. Ask Spring to verify the credentials. This loads the user and checks the password hash.
        //    If the password is wrong, it throws BadCredentialsException, which Spring turns into a 401.
        Authentication auth = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.username(), request.password()));

        // 2. Credentials are valid. Load the user details so we can put them in the token.
        UserDetails user = userDetailsService.loadUserByUsername(auth.getName());

        // 3. Create the token and send it back to the client
        String token = jwtService.generateToken(user);
        return Map.of("token", token);
    }
}
```

`@RequestBody` tells Spring to parse the JSON body into `LoginRequest`. A Java `record` is a short, immutable data class, perfect for this.

The `authenticate()` call is the crucial line. It doesn't just compare strings. It goes through the full pipeline: `DaoAuthenticationProvider` calls your `UserDetailsService`, then uses your `PasswordEncoder` to check the password against the stored hash. If anything fails, you never reach step 2.

Now, you still need a `UserDetailsService` bean so the pipeline knows where users come from. For a quick test, you can define one in memory in any `@Configuration` class:

```java
@Bean
public UserDetailsService userDetailsService(PasswordEncoder encoder) {
    UserDetails user = User.withUsername("alireza")
            .password(encoder.encode("secret123"))  // store the hash, never the raw password
            .roles("USER")
            .build();
    return new InMemoryUserDetailsManager(user);
}
```

This imports `org.springframework.security.core.userdetails.User`, `UserDetails`, `UserDetailsService`, and `org.springframework.security.provisioning.InMemoryUserDetailsManager`. In a real application, you'd replace it with a implementation that loads users from a database through a JPA repository.

## Step 6: Testing the Whole Flow

Start the application, then run these commands in a terminal. The first one logs in:

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"alireza","password":"secret123"}'
```

You'll get back something like `{"token":"eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhbGlyZXphIi..."}`. Copy the token, then call a protected endpoint with it:

```bash
curl http://localhost:8080/api/anything \
  -H "Authorization: Bearer PASTE_TOKEN_HERE"
```

Now try the same request without the header, and with a token you've altered by one character. You should get a 401 in both cases, which shows the signature check is working. A protected URL without a token is rejected because the filter logs nobody in and the `authenticated()` rule blocks the request.

## Common Pitfalls

**Forgetting `STATELESS`.** If you leave sessions on, Spring may still create a session cookie, and your JWT setup becomes muddled.

**Putting the filter in the wrong place.** If `addFilterBefore` is missing or misplaced, the context is empty when the authorization rules run, and every protected request fails even with a valid token.

**A weak secret.** A short or guessable secret lets attackers forge tokens. Use at least 32 random characters and keep them in an environment variable.

**Storing sensitive data in the payload.** The payload is readable by anyone who holds the token. Put only identifiers and roles there, never passwords or personal details.

**Expecting a token to be revocable.** A JWT stays valid until it expires, even if you "log out" on the client. For real logout or immediate revocation you need a blocklist, or short token lifetimes paired with refresh tokens. That's a good next topic.

**Using the wrong `UsernamePasswordAuthenticationToken` constructor.** The two-argument version marks the auth as not yet authenticated. The three-argument version, which includes authorities, marks it as authenticated. The filter uses the three-argument form for this reason.

## Summary

Login verifies a password once and issues a signed token. Every later request presents the token, and a filter placed before the authorization check verifies it and fills `SecurityContextHolder`. Stateless configuration ensures no server-side session exists, so the token is the only proof of identity.

[[Spring Security]]