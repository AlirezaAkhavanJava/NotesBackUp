
`HttpServletRequest` = the object Spring (or any servlet container) gives you to read **incoming HTTP request data**.

Direct, factual explanation:

### What it contains

`HttpServletRequest` lets you access things like:

- **Headers** → `request.getHeader("User-Agent")`
    
- **Query params** → `request.getParameter("id")`
    
- **Form data** → also via `getParameter(...)`
    
- **Cookies** → `request.getCookies()`
    
- **HTTP method** → `request.getMethod()` (GET / POST / etc.)
    
- **URL / Path** → `request.getRequestURI()`, `getRequestURL()`
    
- **Client IP** → `request.getRemoteAddr()`
    
- **Session** → `request.getSession()`
    

### Where you use it

In Spring MVC controller:

```java
@GetMapping("/test")
public String test(HttpServletRequest request) {
    String ua = request.getHeader("User-Agent");
    return ua;
}
```

### Why it's important

It is the **main interface to the raw HTTP request** before Spring converts things into nice POJOs (@RequestBody, @PathVariable, @RequestParam, etc.).

---

Here’s a comprehensive cheat-sheet for working with `HttpServletRequest` in Spring Boot (especially in the context of Spring Security and CSRF tokens, since that was our previous topic).

### Most Commonly Used Methods on HttpServletRequest

| Category                  | Method                                      | Description / Typical Use |
|---------------------------|---------------------------------------------|---------------------------|
| **Request Line**          | `getMethod()`                               | GET, POST, PUT, etc.     |
|                           | `getRequestURI()`                           | e.g. `/api/users/42`     |
|                           | `getRequestURL()`                           | Full URL with scheme/host|
|                           | `getQueryString()`                          | Query part only          |
| **Headers**               | `getHeader(String name)`                    | Single header            |
|                           | `getHeaders(String name)`                   | Enumeration (multi-value)|
|                           | `getHeaderNames()`                          | All header names         |
|                           | `getIntHeader(String name)`                 | Convenience for int      |
|                           | `getDateHeader(String name)`                | Convenience for Date     |
| **Parameters**            | `getParameter(String name)`                 | Form or query params     |
|                           | `getParameterMap()`                         | Map<String, String[]>    |
|                           | `getParameterNames()`                       | Enumeration of names     |
|                           | `getParameterValues(String name)`           | For multi-value params   |
| **Body (once only!)**     | `getInputStream()` or `getReader()`         | Raw body (consumes it)   |
| **Client Info**           | `getRemoteAddr()`                           | Client IP                |
|                           | `getRemoteHost()`                           | Client hostname          |
|                           | `getRemotePort()`                           | Client port              |
|                           | `getLocalAddr()`, `getLocalName()`, `getLocalPort()` | Server info    |
| **Session**               | `getSession()` / `getSession(boolean create)` | HttpSession            |
| **Authentication**        | `getUserPrincipal()`                        | Current user (if any)    |
|                           | `isUserInRole(String role)`                 | Role check               |
| **Security / CSRF**       | `getAttribute("org.springframework.security.web.csrf.CsrfToken")` | Current CsrfToken object (new way) |
|                           | `HttpServletRequest request` → `(CsrfToken) request.getAttribute(CsrfToken.class.getName())` | Recommended way in Spring Security 5.8+ / 6+ |

### Getting the CSRF Token from HttpServletRequest (Spring Security 5.8+ / Spring Boot 3+)

```java
// Method 1 – Recommended (works with lazy/deferred loading)
CsrfToken csrfToken = (CsrfToken) request.getAttribute(CsrfToken.class.getName());
if (csrfToken != null) {
    String token = csrfToken.getToken();               // actual value
    String headerName = csrfToken.getHeaderName();     // usually X-CSRF-TOKEN or X-XSRF-TOKEN
    String parameterName = csrfToken.getParameterName(); // usually _csrf
}

// Method 2 – Old style (still works but may trigger early token generation)
CsrfToken csrfToken = (CsrfToken) request.getAttribute("_csrf");
```

### Reading JSON Body Safely (without consuming it twice)

Because `getInputStream()` / `getReader()` can be read only once, use a wrapper in a filter if you need to log or read body multiple times:

```java
public class CachedBodyHttpServletRequest extends HttpServletRequestWrapper {
    private final byte[] cachedBody;

    public CachedBodyHttpServletRequest(HttpServletRequest request) throws IOException {
        super(request);
        InputStream requestInputStream = request.getInputStream();
        this.cachedBody = StreamUtils.copyToByteArray(requestInputStream);
    }

    @Override
    public ServletInputStream getInputStream() {
        return new CachedBodyServletInputStream(this.cachedBody);
    }

    @Override
    public BufferedReader getReader() {
        ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(this.cachedBody);
        return new BufferedReader(new InputStreamReader(byteArrayInputStream));
    }
}
```

Then in a `@ControllerAdvice` or filter:

```java
String body = StreamUtils.copyToString(request.getInputStream(), StandardCharsets.UTF_8);
```

### Extracting Bearer Token (JWT) from Authorization Header

```java
public static String extractBearerToken(HttpServletRequest request) {
    String authHeader = request.getHeader("Authorization");
    if (authHeader != null && authHeader.startsWith("Bearer ")) {
        return authHeader.substring(7);
    }
    return null;
}
```

### Getting Client’s Real IP (behind proxies / load balancers)

```java
public static String getClientIp(HttpServletRequest request) {
    String ip = request.getHeader("X-Forwarded-For");
    if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
        ip = request.getHeader("X-Real-IP");
    }
    if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
        ip = request.getHeader("Proxy-Client-IP");
    }
    if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
        ip = request.getRemoteAddr();
    }
    // X-Forwarded-For can be comma-separated (first is original client)
    if (ip != null && ip.contains(",")) {
        ip = ip.split(",")[0].trim();
    }
    return ip;
}
```

### Quick Reference Example in a Controller

```java
@PostMapping("/example")
public ResponseEntity<?> demo(HttpServletRequest request) {
    // CSRF token
    CsrfToken csrf = (CsrfToken) request.getAttribute(CsrfToken.class.getName());

    // Headers
    String origin = request.getHeader("Origin");
    String userAgent = request.getHeader("User-Agent");

    // Parameters
    String username = request.getParameter("username");

    // Client IP
    String ip = getClientIp(request);

    // Current authenticated user
    String currentUser = (request.getUserPrincipal() != null)
            ? request.getUserPrincipal().getName()
            : "anonymous";

    return ResponseEntity.ok(Map.of(
        "csrfToken", csrf != null ? csrf.getToken() : null,
        "origin", origin,
        "ip", ip,
        "currentUser", currentUser
    ));
}
```

Use this as your go-to reference whenever you’re working with `HttpServletRequest` in Spring Boot! Let me know what specific scenario you’re trying to solve and I can give you the exact code snippet.
##### Tags : [[1 - Spring Security 🍌]]