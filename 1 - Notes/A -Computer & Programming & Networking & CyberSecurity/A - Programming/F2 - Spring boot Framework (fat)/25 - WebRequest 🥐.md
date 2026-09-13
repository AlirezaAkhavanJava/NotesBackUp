
`WebRequest` in Spring represents the **current HTTP request** in a **generic, framework-neutral way**.

You often see it used in `@ExceptionHandler` or `ResponseEntityExceptionHandler` methods — it lets you access request data **without depending directly on `HttpServletRequest`**.

---

### 🧩 Example — In an Exception Handler

```java
@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Object> handleNotFound(ResourceNotFoundException ex, WebRequest request) {
        Map<String, Object> body = new HashMap<>();
        body.put("error", "Not Found");
        body.put("message", ex.getMessage());
        body.put("path", request.getDescription(false)); // shows URI
        body.put("timestamp", LocalDateTime.now());

        return new ResponseEntity<>(body, HttpStatus.NOT_FOUND);
    }
}
```

If the request was `/users/10`,  
`request.getDescription(false)` → `"uri=/users/10"`

---

### 🧱 Common Methods

|Method|What it returns|
|---|---|
|`getDescription(boolean includeClientInfo)`|Request URI (and optionally client info)|
|`getHeader(String name)`|Specific header|
|`getParameter(String name)`|Query/form parameter|
|`setAttribute(String name, Object value, int scope)`|Store data in request or session|
|`getUserPrincipal()`|Authenticated user info (if available)|

---

### ⚖️ When to use

✅ In exception handlers or filters — to log or include request info  
❌ Rarely needed in controllers (there you usually use `@RequestParam`, `@PathVariable`, etc.)

---


## 🧱 `HttpServletRequest`

`HttpServletRequest` is part of the **Java Servlet API**, not specific to Spring.  
It represents the **raw HTTP request** — everything that came from the client: headers, parameters, body, cookies, etc.

Spring can inject it into any controller or exception handler:

```java
@RestController
public class UserController {

    @GetMapping("/info")
    public String info(HttpServletRequest request) {
        return "You called: " + request.getRequestURI();
    }
}
```

---

### 🔍 Common Methods

|Method|Description|
|---|---|
|`getRequestURI()`|Returns `/info`|
|`getMethod()`|Returns `GET`, `POST`, etc.|
|`getHeader(String name)`|Reads an HTTP header|
|`getParameter(String name)`|Reads a query/form parameter|
|`getRemoteAddr()`|Returns the client’s IP|
|`getSession()`|Accesses session|
|`getInputStream()`|Reads the raw request body|

---

## ⚖️ Comparison — `WebRequest` vs `HttpServletRequest`

|Feature|`WebRequest`|`HttpServletRequest`|
|---|---|---|
|**Belongs to**|Spring Framework|Java Servlet API|
|**Level**|Abstract (works with Servlet or Portlet)|Servlet-specific (HTTP only)|
|**Use case**|Framework-neutral request handling (good for global exception handlers)|Direct access to HTTP request details|
|**Example method**|`getDescription(false)`|`getRequestURI()`|
|**Access to body/session**|Limited|Full|
|**Best used in**|`@ExceptionHandler`, `ResponseEntityExceptionHandler`|Controllers, filters, interceptors|

---

### 🧠 In short:

- 🪶 **`WebRequest`** → Light, framework-level abstraction (used by Spring internally)
    
- ⚙️ **`HttpServletRequest`** → Raw servlet object, more powerful but lower-level
    

---


##### Tags :[[0 - Spring Framework]]