
## **1. What is `JwtAuthenticationFilter`?**

`JwtAuthenticationFilter` is a **custom Spring Security filter** that intercepts HTTP requests to:

1. Extract the **JWT token** from the request header (usually `Authorization: Bearer <token>`).
    
2. Validate the token (check signature, expiration, etc.).
    
3. If valid, set the **authentication object** in the Spring Security **context**, so that the request is considered authenticated.
    

Basically, it tells Spring Security: _“Hey, this user is valid, let them in.”_

---

## **2. Where it fits in the Security chain**

In Spring Security:

- Filters are executed in order.
    
- `JwtAuthenticationFilter` usually comes **before `UsernamePasswordAuthenticationFilter`**, because you want to authenticate **via token** rather than form login.
    

**Example configuration:**

```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http.csrf().disable()
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/api/auth/**").permitAll()
            .anyRequest().authenticated()
        )
        .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .addFilterBefore(jwtAuthenticationFilter(), UsernamePasswordAuthenticationFilter.class);

    return http.build();
}
```

---

## **3. Typical Implementation**

```java
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService; // for validating tokens
    private final UserDetailsService userDetailsService;

    public JwtAuthenticationFilter(JwtService jwtService, UserDetailsService userDetailsService) {
        this.jwtService = jwtService;
        this.userDetailsService = userDetailsService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        final String authHeader = request.getHeader("Authorization");
        final String jwt;
        final String username;

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        jwt = authHeader.substring(7);
        username = jwtService.extractUsername(jwt);

        if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            UserDetails userDetails = this.userDetailsService.loadUserByUsername(username);

            if (jwtService.isTokenValid(jwt, userDetails)) {
                UsernamePasswordAuthenticationToken authToken =
                        new UsernamePasswordAuthenticationToken(
                                userDetails,
                                null,
                                userDetails.getAuthorities()
                        );
                authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
        }

        filterChain.doFilter(request, response);
    }
}
```

---

## **4. Key Components Explained**

- **OncePerRequestFilter**: Ensures the filter runs only once per request.
    
- **Authorization Header**: Standard place for JWT tokens.
    
- **JwtService**: Custom service for:
    
    - Extracting username
        
    - Validating token (signature, expiration)
        
- **SecurityContextHolder**: Holds authentication info for the current request.
    
- **FilterChain**: Passes the request to the next filter after processing.
    

---

## **5. Workflow**

1. Client sends a request with `Authorization: Bearer <JWT>`.
    
2. `JwtAuthenticationFilter` intercepts.
    
3. Token is extracted and validated.
    
4. If valid:
    
    - User details are loaded.
        
    - `Authentication` is set in `SecurityContextHolder`.
        
5. Request proceeds with authentication context.
    

---




###### Tags : [[1 - Spring Security 🍌]]