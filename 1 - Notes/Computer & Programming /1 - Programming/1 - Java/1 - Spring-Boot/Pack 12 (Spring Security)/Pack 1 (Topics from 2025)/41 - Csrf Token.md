
### What is CSRF and How Spring Security Handles It

Cross-Site Request Forgery (CSRF) is an attack where a malicious site tricks a user's browser into making an unwanted state-changing request (e.g., POST, PUT, DELETE) to a site where the user is authenticated, using the user's existing session cookies.

Spring Security protects against CSRF **by default** in servlet-based applications (including Spring Boot) when using form login or session-based authentication. It uses the **Synchronizer Token Pattern**:

- A random, unique CSRF token is generated per session.
- The token is included in responses (e.g., in forms or as a cookie).
- On state-changing requests, Spring Security verifies that the submitted token matches the expected one.
- Safe methods (GET, HEAD, OPTIONS, TRACE) are not protected by default.

This has been the case since Spring Security 4+, and remains true in Spring Boot 3+ (Spring Security 6+ as of 2025).

### Default Behavior in Spring Boot 3+ (Spring Security 6+)

- CSRF protection is **enabled by default** for non-safe HTTP methods.
- Token storage: By default, uses `HttpSessionCsrfTokenRepository` (stored in the session attribute `_csrf`).
- Token loading is **deferred/lazy** (only generated when first needed, e.g., when accessed in a view or via an endpoint).
- Additional protections:
  - BREACH attack mitigation via XOR encoding (using `XorCsrfTokenRequestAttributeHandler` by default).
  - Randomness added per request.
- Expected token locations in requests:
  - Parameter: `_csrf`
  - Headers: `X-CSRF-TOKEN` or `X-XSRF-TOKEN`

No extra configuration is needed for basic protection.

### Including the CSRF Token in Your Application

#### 1. Server-Side Rendered Forms (Thymeleaf, JSP, etc.)
Spring automatically injects the token if you use the proper tags.

**Thymeleaf example** (add `thymeleaf-extras-springsecurity6` dependency):
```html
<form method="post" th:action="@{/logout}">
    <input type="hidden" th:name="${_csrf.parameterName}" th:value="${_csrf.token}" />
    <button type="submit">Logout</button>
</form>
```
Or simply:
```html
<form method="post">
    <input type="submit" value="Submit" />
</form>
```
Thymeleaf auto-adds the hidden field if CSRF is enabled.

**JSP example** (with Spring Security taglibs):
```jsp
<form:form method="post">
    <csrf:input />
    ...
</form:form>
```

#### 2. JavaScript / SPA (e.g., Angular, React, Vue)
Use a cookie-based repository so the browser auto-sends the cookie, and JS reads it to send in a header.

Recommended configuration (for SPAs):
```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .csrf(csrf -> csrf
            .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
            // Optional: Read fresh token from /csrf endpoint if needed
        )
        // ... other config: authorizeRequests, formLogin, etc.
    return http.build();
}
```

- This sets a cookie named `XSRF-TOKEN` (readable by JS, since `httpOnly=false`).
- On every response where a token is needed, Spring sends/updates the cookie.
- In JS (e.g., Angular's `HttpClientXsrfModule` or manual):
  ```js
  const token = document.cookie
      .split('; ')
      .find(row => row.startsWith('XSRF-TOKEN'))
      ?.split('=')[1];

  fetch('/api/protected', {
      method: 'POST',
      headers: { 'X-XSRF-TOKEN': token },
      // ...
  });
  ```

To expose a fresh token endpoint (useful for SPAs):
```java
@Controller
public class CsrfController {
    @GetMapping("/csrf")
    public CsrfToken csrf(CsrfToken token) {
        return token;  // Returns JSON with token details
    }
}
```

#### 3. REST APIs / Stateless Apps
- If using JWT or pure token auth (no sessions/cookies): **Disable CSRF** (it's unnecessary and safe if auth is per-request).
  ```java
  http.csrf(csrf -> csrf.disable());
  ```
- Never disable CSRF if you rely on cookies/sessions for authentication.

### Disabling or Customizing CSRF

Disable entirely:
```java
http.csrf(AbstractHttpConfigurer::disable);
```

Ignore CSRF for specific paths (e.g., APIs):
```java
http.csrf(csrf -> csrf.ignoringRequestMatchers("/api/**", "/public/**"));
```

Custom repository or handler (rarely needed):
```java
http.csrf(csrf -> csrf
    .csrfTokenRepository(new HttpSessionCsrfTokenRepository())
    .csrfTokenRequestHandler(new CsrfTokenRequestAttributeHandler())  // Opt-out of XOR/BREACH protection
);
```

### Testing CSRF Protection
In MockMvc tests, include a valid token:
```java
mvc.perform(post("/protected")
    .with(csrf())  // Automatically adds a valid token
    .content(...));
```

### Common Issues in Spring Boot 3+
- 403 Invalid CSRF Token: Token not sent, wrong header/parameter name, or lazy loading issue (first request generates token, subsequent use it).
- BREACH protection: Default XOR can cause "encrypted" tokens in logs; use `CsrfTokenRequestAttributeHandler` if you need raw tokens (less secure).

For the latest official details, refer to: https://docs.spring.io/spring-security/reference/servlet/exploits/csrf.html

This setup provides robust protection out-of-the-box while being flexible for modern SPAs and APIs. If you have a specific code snippet or error, share it for more targeted help!

###### Tags : [[1 - Spring Security 🍌]]