
**HttpServletRequest** is a **Java object that represents an incoming HTTP request** sent from a client (browser, mobile app, curl) to your server.

In plain terms: it’s how your Spring / Servlet code **reads what the client sent**.


### **What it actually contains**

When a request hits your app, the servlet container (Tomcat, Jetty, etc.) builds an `HttpServletRequest` and fills it with:

- HTTP method (`GET`, `POST`, `PUT`, …)
    
- URL and URI
    
- Query parameters
    
- Headers
    
- Cookies
    
- Request body (JSON, form data)
    
- Client info (IP, locale, session)
    

Your controller never parses raw HTTP. It reads _this object_.

### **Typical things you read from it**

- `getMethod()` → request type
    
- `getParameter("id")` → query/form values
    
- `getHeader("Authorization")` → auth headers
    
- `getCookies()` → cookies sent by browser
    
- `getSession()` → user session
    
- `getRequestURI()` → endpoint path
    

### **Where it lives in Spring**

In Spring MVC:

```java
@GetMapping("/users")
public String users(HttpServletRequest request) {
    String ip = request.getRemoteAddr();
    return "ok";
}
```

Spring injects it automatically. No magic—just dependency injection over the Servlet API.

### **Important clarifications**

- It is **request-scoped**  
    A new instance per HTTP request. Never shared.
    
- It is **read-only from the client’s perspective**  
    You read what the client sent. You don’t modify the request that already happened.
    
- It is **not HTTPS-specific**  
    Despite the name confusion, it works for both HTTP and HTTPS.  
    The correct name is **HttpServletRequest**, not `HttpsServletRequest`.
    

### **Why it matters**

Everything about:

- authentication
    
- CSRF validation
    
- headers
    
- cookies
    
- request metadata
    

Flows through this object.

Think of `HttpServletRequest` as the **decoded envelope** of an HTTP message—already opened, already parsed, ready for inspection.

#### Tags : [[1 - Spring Security 🍌]]