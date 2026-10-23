


## The problem it solves (again)
CORS is great, but if you just throw a tiny filter on one controller, it’s easy to miss.  
Security is everything. Spring Security adds the exact same CORS rules to **every single request** in the whole app (login, logout, any endpoint, even errors).  
It also works perfectly with JWT, OAuth2, and all your other security stuff.

## How Spring Security CORS works – step by step
1. You enable CORS in your `SecurityFilterChain` bean.
2. The security filter **before** your controllers checks the Origin header.
3. If allowed, it adds the three `Access-Control-Allow-*` headers.
4. If the request is OPTIONS (pre-flight), it returns 200 OK and stops.
5. Your normal controllers and services still work exactly as before.

## Spring Boot 3.x – the cleanest way (2026 version)

```java
// application.yml (or properties)
cors:
  allowed-origins: "http://localhost:3000,https://my-cool-site.com"   # <== change this
  allowed-methods: "GET,POST,PUT,DELETE,OPTIONS"
  allowed-headers: "*"
  allow-credentials: true   # important if you use cookies or JWTs
```

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .authorizeHttpRequests(auth -> auth
                .anyRequest().authenticated()   // or .permitAll() for dev
            )
            .csrf(csrf -> csrf.disable())   // disable only if you really need it
            .formLogin(form -> form.disable())
            .httpBasic(httpBasic -> httpBasic.disable());

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(List.of("http://localhost:3000", "https://my-cool-site.com")); // exact match
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);   // needed for credentials

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);   // apply to EVERY request

        return source;
    }

    public AuthenticationEntryPoint authenticationEntryPoint() {
        return (req, res, ex) -> res.sendError(HttpServletResponse.SC_UNAUTHORIZED);
    }
}
```

**Line-by-line**  
- `.cors()` – tells Spring Security to use our custom configuration.  
- `configurationSource` – the method that builds the rules.  
- `setAllowedOrigins` – **never** use `*` here in production (see below).  
- `setAllowCredentials(true)` – required when you use JWTs or cookies.  
- `UrlBasedCorsConfigurationSource` – the Spring class that does all the work.

## Production rule – never use *
Never use `*` for `allowedOrigins` or `allowedHeaders` in production.  
It’s a security hole that lets attackers read your data from any site.

**When you CAN use `*` and `allow-credentials: false`**
- Pure API (no auth)
- Dev only (localhost:3000 + localhost:8080)

**When you MUST use exact origins**
- Real apps with JWT or cookies

## Spring Boot 2.x – quick upgrade note
If you’re still on Spring Boot 2, the code is almost identical — just use `WebSecurityConfigurerAdapter` instead of the lambda style. The concept is the same.

## Try it yourself (5 minutes)
1. Add the `application.yml` above.
2. Replace your old CORS filter with the `SecurityConfig` above.
3. Run the app.
4. Open any page on localhost:3000 and call your API — it should work instantly.
5. Test pre-flight: open Network tab, click a button that sends POST — you’ll see the OPTIONS request disappear.

## Common mistakes
| Mistake | Why it hurts | How to fix |
|---------|--------------|----------|
| Forgetting `.cors()` in SecurityFilterChain | No headers added | Add the `.cors(cors -> ...)` line |
| Using `*` for origins | Security risk | Use exact origins or `allowedOrigins(List.of("*"))` + `allowCredentials(false)` |
| Forgetting `allow-credentials: true` | JWT/cookies break | Add it when you need auth |
| Not handling OPTIONS | Pre-flight fails | Spring Security does it automatically |
| Putting CORS in a regular controller | Not applied to everything | Move to SecurityConfig |

## Related concept, briefly
**CORS + JWT**  
Spring Security’s CORS config works perfectly with JWT because the JWT is just another token. The headers are added before your JwtAuthenticationFilter runs, so everything stays secure.

## The whole picture

| Question | Answer |
|----------|--------|
| Why Spring Security CORS? | Automatically protects the whole app |
| How do you turn it on? | `.cors(cors -> cors.configurationSource(...))` |
| What config do you put in yml? | allowed-origins, allowed-methods, allowed-headers, allow-credentials |
| Can I use * in production? | No — use exact origins instead |
| Does it handle pre-flight? | Yes, automatically |







[[Spring Security]]