
CORS (Cross-Origin Resource Sharing) is a rule that **browsers** enforce, and your server only takes part by sending headers. By default a browser lets JavaScript read a response only if the page and the API share the same _origin_. Your React app on `http://localhost:5173` calling your API on `http://localhost:8080` is cross-origin, so the browser blocks the response unless the API says "this origin is allowed" in its headers.

So CORS is not server-side security. `curl`, Postman, and other servers ignore it completely. It protects the user's browser from letting a random website read responses from your API using the user's session. Your job as the backend developer is to declare exactly which origins, methods, and headers are allowed, in one place, and nowhere else.

## What the browser actually does

An **origin** is `scheme + host + port`. `http://localhost:5173` and `http://localhost:8080` differ by port, so they are different origins.

For "simple" requests (a plain `GET`, or a `POST` with a form content type), the browser sends the request with an `Origin` header and then checks the response headers. For anything else, such as `Authorization` headers, `application/json` bodies, or `PUT`/`PATCH`/`DELETE`, it first sends a **preflight**: an `OPTIONS` request asking permission.

```http
OPTIONS /api/books HTTP/1.1
Origin: http://localhost:5173
Access-Control-Request-Method: POST
Access-Control-Request-Headers: authorization, content-type
```

If your server approves, it answers:

```http
HTTP/1.1 200
Access-Control-Allow-Origin: http://localhost:5173
Access-Control-Allow-Methods: GET,POST,PUT,PATCH,DELETE,OPTIONS
Access-Control-Allow-Headers: Authorization,Content-Type
Access-Control-Max-Age: 3600
Vary: Origin
```

Only then does the browser send the real request. Here is what each header does:

|Header|Meaning|
|---|---|
|`Access-Control-Allow-Origin`|Which origin may read the response. Exactly one origin or `*`.|
|`Access-Control-Allow-Methods`|Methods allowed (preflight answer).|
|`Access-Control-Allow-Headers`|Request headers allowed (preflight answer).|
|`Access-Control-Allow-Credentials`|`true` lets the browser send cookies and read the response.|
|`Access-Control-Expose-Headers`|Response headers JavaScript may read (by default it can read only a few basic ones).|
|`Access-Control-Max-Age`|How long the browser caches the preflight result, so it does not repeat it before every call.|

## Spring Boot's four ways to configure it

1. **`@CrossOrigin`** on a controller or method. It is quick, but the rules end up scattered over your controllers, so it is hard to audit.
2. **`WebMvcConfigurer.addCorsMappings`**. It is global, but it lives in the MVC layer.
3. **A `CorsFilter` bean**. It is global and runs as a servlet filter, but you wire it manually.
4. **A `CorsConfigurationSource` bean plus `http.cors(...)` in Spring Security**. This is the pro choice.

The reason is ordering. Spring Security's filter chain runs _before_ Spring MVC. A preflight `OPTIONS` request carries no `Authorization` header, so if CORS is not handled inside the security chain, your JWT filter and `authorizeHttpRequests` reject it with `401` before MVC ever sees it. The browser then reports a CORS error even though the real problem is security. When you enable `.cors(...)`, Spring Security puts a `CorsFilter` at the front of the chain. It answers the preflight itself and stops there. You don't need `permitAll()` on `OPTIONS`.

## The pro design: properties, then bean, then security chain

The idea is that the allowed origins are _configuration_, not code. Local development, staging, and production each need different values, and you already know the tools for that: `@ConfigurationProperties` and profiles.

**Step 1: a validated properties record.**

```java
@Validated
@ConfigurationProperties(prefix = "app.cors")
public record CorsProperties(
        @NotEmpty List<String> allowedOrigins,
        @DefaultValue({"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"}) List<String> allowedMethods,
        @DefaultValue({"Authorization", "Content-Type"}) List<String> allowedHeaders,
        @DefaultValue({}) List<String> exposedHeaders,
        @DefaultValue("false") boolean allowCredentials,
        @DefaultValue("1h") Duration maxAge
) {}
```

`@NotEmpty` makes the app fail at startup if you forget to configure origins, which is better than failing silently in the browser. Register the record with `@ConfigurationPropertiesScan` or `@EnableConfigurationProperties(CorsProperties.class)`.

**Step 2: one `CorsConfigurationSource` bean.**

```java
@Configuration
public class CorsConfig {

    @Bean
    CorsConfigurationSource corsConfigurationSource(CorsProperties props) {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(props.allowedOrigins());
        config.setAllowedMethods(props.allowedMethods());
        config.setAllowedHeaders(props.allowedHeaders());
        config.setExposedHeaders(props.exposedHeaders());
        config.setAllowCredentials(props.allowCredentials());
        config.setMaxAge(props.maxAge());

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", config);
        return source;
    }
}
```

Line by line: `CorsConfiguration` holds one set of rules. `UrlBasedCorsConfigurationSource` maps URL patterns to rules, so you could give `/api/public/**` a different policy than `/api/**`. The bean name `corsConfigurationSource` matters, because Spring Security looks for exactly that name.

**Step 3: plug it into the `SecurityFilterChain`.** This builds on your earlier JWT filter chain lesson.

```java
@Bean
SecurityFilterChain security(HttpSecurity http, JwtAuthenticationFilter jwtFilter) throws Exception {
    return http
            .cors(Customizer.withDefaults())          // uses the corsConfigurationSource bean
            .csrf(csrf -> csrf.disable())             // stateless JWT, see the note below
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a -> a
                    .requestMatchers("/api/auth/**").permitAll()
                    .anyRequest().authenticated())
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)
            .build();
}
```

**Step 4: per-environment values** (this is where your profiles lesson pays off).

```yaml
# application.yml (dev defaults)
app:
  cors:
    allowed-origins:
      - http://localhost:5173
      - http://localhost:3000
```

```yaml
# application-prod.yml
app:
  cors:
    allowed-origins:
      - https://app.example.com
    max-age: 2h
```

Relaxed binding also lets you override the list from the environment, for example `APP_CORS_ALLOWED_ORIGINS=https://app.example.com` in Docker.

## The rules that make it "pro"

**Never use `*` in production.** List exact origins. An origin must be the full `scheme://host:port` with no trailing slash and no path.

**`allowCredentials(true)` and `*` cannot coexist.** The browser refuses it, and Spring throws `IllegalArgumentException` at startup. If you need wildcard-style matching, such as all your subdomains, use `setAllowedOriginPatterns(List.of("https://*.example.com"))`, which works with credentials. Never combine it with `*` alone.

**Decide whether you use credentials at all.** If your JWT travels in the `Authorization: Bearer ...` header, the browser treats it as a normal custom header and you do _not_ need `allowCredentials`. You just need `Authorization` in `allowedHeaders`. Credentials are only needed when the browser must send cookies, such as a refresh-token cookie or a session cookie. In that case set `allowCredentials=true`, use exact origins, and add `SameSite` on the cookie.

**Allow only what you use.** Do not list every method and header out of habit. If the API has no `PATCH`, don't allow it.

**Expose headers deliberately.** If the frontend must read `Location` (after a `201 Created`) or a pagination header, add it to `exposedHeaders`. Otherwise `response.headers.get("Location")` returns `null` in JavaScript even though the header arrived.

**Use `maxAge`.** Without it, browsers cap the preflight cache at a very short default (Chrome: 5 seconds), which doubles your request count for non-simple calls. Note that browsers cap the maximum too (Chrome: 2 hours).

**Handle CORS in exactly one layer.** If you put Spring Cloud Gateway or Nginx in front of the service, configure CORS in that single layer. If both the gateway and the service add `Access-Control-Allow-Origin`, the response has two copies of the header and the browser rejects it. For a gateway, the setting is `spring.cloud.gateway.globalcors`, and the services behind it should not configure CORS at all.

**Error responses must carry CORS headers too.** Because `CorsFilter` runs at the front of the chain, even your `401` and your `@RestControllerAdvice` `ProblemDetail` responses get the headers. Without that, the browser would hide your real error body behind a generic "CORS error" and you could not debug it.

## Testing it

Test with `curl`, because the browser hides the details:

```bash
curl -i -X OPTIONS http://localhost:8080/api/books \
  -H "Origin: http://localhost:5173" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: authorization,content-type"
```

An allowed origin gets `200` with the `Access-Control-Allow-*` headers. A disallowed origin gets `403` with the body `Invalid CORS request`, which is Spring telling you that the origin, method, or header is not in your configuration. When you see a CORS error in the browser console, run this command first. It tells you which of the three failed.

Then pin the behavior with an automated test:

```java
@Test
void preflightFromAllowedOriginIsAccepted() throws Exception {
    mockMvc.perform(options("/api/books")
                    .header("Origin", "http://localhost:5173")
                    .header("Access-Control-Request-Method", "POST")
                    .header("Access-Control-Request-Headers", "authorization"))
           .andExpect(status().isOk())
           .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:5173"));
}

@Test
void preflightFromUnknownOriginIsRejected() throws Exception {
    mockMvc.perform(options("/api/books")
                    .header("Origin", "https://evil.example")
                    .header("Access-Control-Request-Method", "POST"))
           .andExpect(status().isForbidden());
}
```

## The mistakes that cost people hours

- Enabling CORS only in `addCorsMappings` while Spring Security is active and `.cors()` is missing, so the preflight gets a `401`.
- Allowing `Authorization` on the server but forgetting it in `allowedHeaders`, so the preflight fails on the header, not the origin.
- A trailing slash in the origin (`http://localhost:5173/`), which never matches.
- Reflecting the incoming `Origin` header back blindly ("allow everyone, but with credentials"). That defeats the whole purpose.
- Fixing a CORS error in the frontend dev server's proxy and never configuring the backend, so production breaks on release day.

## A related concept: CSRF

CORS and **CSRF** are often confused. CORS controls which sites may _read_ your responses. CSRF is an attack where another site makes the browser _send_ a state-changing request with the user's cookies. CORS does not stop that, because a simple cross-origin `POST` still reaches your server. With a stateless JWT in the `Authorization` header, the browser never attaches it automatically, so CSRF is not a risk and disabling it (as in the chain above) is correct. If you move to cookie-based auth, turn CSRF protection back on and keep your CORS origins strict.



[[Spring Framework]]