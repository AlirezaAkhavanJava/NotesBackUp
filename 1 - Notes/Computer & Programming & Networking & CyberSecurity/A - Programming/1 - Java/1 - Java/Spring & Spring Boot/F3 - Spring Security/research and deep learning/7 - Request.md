
When a request is sent to your Spring Boot application (e.g., a user visits `/api/orders` or submits a login form), **here’s exactly what happens to it** step by step once Spring Security is active.

### 1. **Request enters the Servlet Filter Chain**
Every HTTP request in a Spring Boot app goes through a chain of **Servlet Filters** (managed by the Servlet container like Tomcat).  
Spring Security inserts its own filters into this chain — specifically into the **Spring Security Filter Chain** (a special filter called `FilterChainProxy`).

### 2. **FilterChainProxy decides what to do**
The first Spring Security filter (`FilterChainProxy`) receives the request and decides:

- **Which `SecurityFilterChain` to use** (if you have multiple chains, e.g., one for `/api/**` and one for `/admin/**`)
- **Whether to apply security at all** (based on your `HttpSecurity` configuration)

### 3. **The request goes through the Security Filters (in order)**

Here’s the typical order and what each filter does with the request:

| Filter (in order)                          | What it does to the request                                                                                          | Possible outcome                                                                 |
|--------------------------------------------|----------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| `ChannelProcessingFilter`                  | Checks if HTTPS is required (if you configured `.requiresSecure()`).                                                 | Redirects to HTTPS if needed                                                     |
| `SecurityContextPersistenceFilter`         | Loads the user’s `SecurityContext` from session (or JWT, etc.) → makes `SecurityContextHolder` available.           | Sets user info for later filters                                                 |
| `HeaderWriterFilter`                       | Adds security headers (HSTS, X-Frame-Options, CSP, etc.) to the response.                                            | Response gets safer headers                                                      |
| `CsrfFilter`                               | (For POST/PUT/DELETE) Checks CSRF token in request.                                                                  | Rejects request with 403 if CSRF token is missing or invalid                     |
| `LogoutFilter`                             | Checks if URL is `/logout` (or custom logout URL).                                                                   | Invalidates session, deletes cookies, redirects to login page                    |
| `UsernamePasswordAuthenticationFilter`     | (For form login) Checks if request is POST to `/login`. Extracts username/password and authenticates.                | If valid → sets authenticated user in `SecurityContext`. Redirects to success URL |
| `BasicAuthenticationFilter`                | (If enabled) Checks `Authorization: Basic` header, authenticates user.                                               | If valid → sets authenticated user                                               |
| `RequestCacheAwareFilter`                  | (After login) Restores the originally requested URL (e.g., user tried `/admin`, was redirected to login).           | Redirects back to original protected page                                        |
| `ExceptionTranslationFilter`               | Catches authorization/authentication exceptions.                                                                     | Redirects to login page (401 → 302) or access denied page (403)                 |
| `FilterSecurityInterceptor`                | **Final authorization check**: Checks if the authenticated user has permission for the requested URL (roles, etc.). | If not authorized → throws `AccessDeniedException` → handled by previous filter  |

### 4. **Final outcome of the request**

| Scenario                                      | What happens to the request                                                                                     |
|-----------------------------------------------|---------------------------------------------------------------------------------------------------------------|
| **No authentication required** (`.permitAll()`) | Request continues to your controllers (e.g., `@GetMapping("/public")`).                                       |
| **Authenticated successfully**                | Request continues to your controllers with `SecurityContext` set (you can use `@AuthenticationPrincipal`).    |
| **Not authenticated** (anonymous user)        | Redirected to login page (302) or returns 401 (for APIs).                                                     |
| **Authenticated but lacks permission**        | Returns 403 Forbidden or redirects to access denied page.                                                     |
| **CSRF token invalid/missing**                | Returns 403 Forbidden.                                                                                        |
| **Login succeeded**                           | Redirects to original requested page or default success URL.                                                  |
| **Logout**                                    | Session invalidated → redirects to login page.                                                                |

### 5. **What happens after the Security Filters?**

If the request passes all security checks, it proceeds to:

- Spring MVC → DispatcherServlet → your `@Controller` methods
- Your business logic executes
- Response is returned to the client

### Visual flow (simplified)

```
Client → HTTP Request → Tomcat → FilterChainProxy (Spring Security)

    ↓
    ├── If HTTPS required → Redirect to HTTPS
    ├── Load SecurityContext (user info)
    ├── Add security headers
    ├── Check CSRF (if POST/PUT/DELETE)
    ├── Handle logout (if /logout)
    ├── Try to authenticate (form login or Basic)
    ├── Check authorization (roles, etc.)
    ↓
If all checks pass → Your @Controller → Response
If any check fails → 401/403/Redirect to login
```

### Summary

- **You don’t add filters manually** — Spring Security builds the chain automatically based on your `HttpSecurity` configuration.
- **Every request is processed by ~10–15 security filters** in a very specific order.
- **Each filter can reject, modify, or pass the request forward**.
- **Only if all filters allow it**, the request reaches your application code.

This is why Spring Security is so powerful and secure — it enforces security at every step before your code even runs.

#### Tags : [[1 - Spring Security 🍌]]