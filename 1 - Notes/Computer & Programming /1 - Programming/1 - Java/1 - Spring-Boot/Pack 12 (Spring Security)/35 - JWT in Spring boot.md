
# 1️⃣ **Definition**

**JWT (JSON Web Token)** is a **digitally signed** token used to authenticate and authorize users **without storing session state on the server**.

Spring Security normally uses stateful sessions. JWT replaces that with a **stateless system**:

- User logs in once
    
- JWT is created & given to user
    
- On each request the user sends JWT
    
- Server validates signature → extracts user info
    
- No session stored in backend
    

**In short:** JWT = **portable proof of authentication**, verified by signature.

---

# 2️⃣ **Related Components (Core Parts of JWT Security)**

Spring Security with JWT has **5 essential classes**:

### **A) Authentication Controller**

Accepts username/password and returns JWT.

### **B) UserDetailsService**

Loads the user by username.

### **C) AuthenticationProvider**

Validates the password during login.

### **D) JWT Utility Class**

- Creates JWT
    
- Validates JWT
    
- Extracts username/claims
    

### **E) JWT Filter** _(THE HEART of JWT security)_

Intercepts every request, reads the token from header, validates it, and sets authentication in the SecurityContext.

---

## ⚙️ JWT Token Structure

JWT = **HEADER . PAYLOAD . SIGNATURE**

Example:

```
eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJldGhhbiIsInJvbGUiOiJST0xFX1VTRVIiLCJleHAiOjE3MzIzMjM2MDB9.s8d13jkd8....
```

---

# 3️⃣ **Example Code (Professional Level)**

## **A) JWT Utility**

```java
@Component
public class JwtUtil {

    private final String SECRET = "veryStrongSecretKeyHere";

    public String generateToken(UserDetails userDetails) {
        return Jwts.builder()
                .setSubject(userDetails.getUsername())
                .claim("roles", userDetails.getAuthorities())
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + 1000 * 60 * 60)) // 1 hour
                .signWith(SignatureAlgorithm.HS256, SECRET)
                .compact();
    }

    public String extractUsername(String token) {
        return extractAllClaims(token).getSubject();
    }

    public boolean isTokenValid(String token, UserDetails userDetails) {
        return extractUsername(token).equals(userDetails.getUsername()) &&
               !isTokenExpired(token);
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parser().setSigningKey(SECRET).parseClaimsJws(token).getBody();
    }

    private boolean isTokenExpired(String token) {
        return extractAllClaims(token).getExpiration().before(new Date());
    }
}
```

### Explanation:

- Validates signature
    
- Reads claims
    
- Generates expiration
    
- Stores roles
    

---

## **B) JWT Filter**

```java
@Component
public class JwtFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final UserDetailsService userDetailsService;

    public JwtFilter(JwtUtil jwtUtil, UserDetailsService userDetailsService) {
        this.jwtUtil = jwtUtil;
        this.userDetailsService = userDetailsService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");

        String username = null;
        String jwt = null;

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            jwt = authHeader.substring(7);
            username = jwtUtil.extractUsername(jwt);
        }

        if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {

            UserDetails userDetails = userDetailsService.loadUserByUsername(username);

            if (jwtUtil.isTokenValid(jwt, userDetails)) {

                UsernamePasswordAuthenticationToken token =
                        new UsernamePasswordAuthenticationToken(
                                userDetails,
                                null,
                                userDetails.getAuthorities()
                        );

                SecurityContextHolder.getContext().setAuthentication(token);
            }
        }

        filterChain.doFilter(request, response);
    }
}
```

### Explanation:

- Extracts JWT from the header
    
- Validates token
    
- Loads user
    
- Creates Spring Security Authentication object
    
- Injects user into SecurityContext
    

---

## **C) Security Configuration**

```java
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtFilter jwtFilter;
    private final AuthenticationProvider authenticationProvider;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

        http.csrf().disable()
            .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
            .authorizeHttpRequests()
            .requestMatchers("/auth/login").permitAll()
            .anyRequest().authenticated()
            .and()
            .authenticationProvider(authenticationProvider)
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
```

---

# 4️⃣ **Methods (Advanced Explanation)**

### **JwtUtil Methods**

- `generateToken()` → encrypts header+payload using secret key.
    
- `extractUsername()` → reads value of `sub` (subject).
    
- `isTokenValid()` → checks expiration + signature.
    
- `extractAllClaims()` → parses and verifies the token.
    

### **JwtFilter Methods**

- `doFilterInternal()` → intercepts every request
    
- Extract header
    
- Validate
    
- Set authentication
    

### **SecurityConfig**

- Sets stateless session
    
- Adds JWT filter
    
- Registers AuthenticationProvider
    

---

# 5️⃣ **Professional / Advanced Knowledge**

### 🧠 Why JWT is stateless

Server does _not_ hold any user session.  
All authentication data is stored **inside the token** itself.

### 🧠 Why JWT should NOT store sensitive data

Payload is base64 encoded, **not encrypted**.  
Anyone can decode it.

### 🧠 Common security patterns

- Use short expiration times
    
- Store refresh tokens in DB
    
- Always rotate tokens
    
- Never store JWT in browser localStorage (XSS risk) — use httpOnly cookies if possible
    

---

# 6️⃣ **Complete Workflow (Step-by-Step)**

### **Login Phase (stateful)**

1. User sends username/password to `/auth/login`.
    
2. AuthenticationProvider verifies credentials.
    
3. If valid → JWT is generated.
    
4. JWT sent back to user.
    

### **Authenticated Requests (stateless)**

1. Client sends request → includes JWT in `Authorization: Bearer <token>`.
    
2. JWT filter intercepts the request.
    
3. Filter extracts token and username.
    
4. Signature is validated.
    
5. Expiration is checked.
    
6. If valid → load user from DB.
    
7. Create Authentication object.
    
8. Store in SecurityContext.
    
9. Controller receives request as authenticated user.
    


###### Tags : [[1 - Spring Security 🍌]]