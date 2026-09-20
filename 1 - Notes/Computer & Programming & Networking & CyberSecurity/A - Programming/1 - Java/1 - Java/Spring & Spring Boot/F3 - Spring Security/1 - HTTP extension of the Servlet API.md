

# ✅ **1. HttpServlet**

### **Definition**

`HttpServlet` is the base class for building HTTP-based servlets.  
You extend it when you want to process HTTP requests (GET, POST, PUT, DELETE).

### **What it does**

- Routes incoming HTTP requests to methods like `doGet()` and `doPost()`.
    
- Lets you write server-side logic.
    

### **Example**

```java
@WebServlet("/hello")
public class HelloServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.getWriter().write("Hello Ethan!");
    }
}
```

---

# ✅ **2. HttpServletRequest**

### **Definition**

Represents the client’s HTTP request.  
Contains URL, headers, params, body, cookies, session, etc.

### **What it does**

Lets you read:

- headers
    
- query params
    
- JSON/XML body
    
- cookies
    
- session
    
- metadata (method, path, IP)
    

### **Example**

```java
protected void doPost(HttpServletRequest req, HttpServletResponse resp)
        throws IOException {
    String username = req.getParameter("user");
    String agent = req.getHeader("User-Agent");
    resp.getWriter().write("User=" + username + ", Agent=" + agent);
}
```

---

# ✅ **3. HttpServletResponse**

### **Definition**

Represents the server’s HTTP response.  
You use it to set status code, headers, cookies, and write output.

### **What it does**

- set HTTP status
    
- write HTML/JSON/XML
    
- set headers
    
- add cookies
    
- send redirect
    

### **Example**

```java
protected void doGet(HttpServletRequest req, HttpServletResponse resp)
        throws IOException {
    resp.setStatus(200);
    resp.setContentType("text/plain");
    resp.getWriter().write("OK");
}
```

---

# ✅ **4. HttpSession**

### **Definition**

A server-side storage for a logged-in user or client.  
Survives across multiple requests.

### **What it does**

Stores data like:

- userId
    
- role
    
- cart items
    
- preferences
    

### **Example**

```java
protected void doGet(HttpServletRequest req, HttpServletResponse resp)
        throws IOException {
    HttpSession session = req.getSession();
    session.setAttribute("name", "Ethan");
    resp.getWriter().write("Saved!");
}
```

---

# ✅ **5. Cookie**

### **Definition**

A piece of small data stored in the browser.  
Sent by the server, returned by the browser on every request.

### **What it does**

Stores:

- session ids
    
- authentication tokens
    
- user preferences
    

### **Example (sending cookie):**

```java
Cookie c = new Cookie("mode", "dark");
c.setMaxAge(3600);
resp.addCookie(c);
```

### **Example (reading cookie):**

```java
for (Cookie c : req.getCookies()) {
    if (c.getName().equals("mode")) {
        String val = c.getValue();
    }
}
```

---

# ✅ **6. HttpServletRequestWrapper**

### **Definition**

A class you extend to **modify** or **intercept** a request.

### **What it does**

Useful for:

- sanitizing input
    
- modifying headers
    
- reading request body twice
    

### **Example**

```java
public class UpperCaseHeaderRequest extends HttpServletRequestWrapper {
    public UpperCaseHeaderRequest(HttpServletRequest request) {
        super(request);
    }

    @Override
    public String getHeader(String name) {
        return super.getHeader(name).toUpperCase();
    }
}
```

Used in filters.

---

# ✅ **7. HttpServletResponseWrapper**

### **Definition**

Same as the request wrapper, but for responses.

### **What it does**

Used for:

- modifying headers
    
- capturing output
    
- compressing response (gzip)
    

### **Example**

```java
public class LoggingResponseWrapper extends HttpServletResponseWrapper {
    public LoggingResponseWrapper(HttpServletResponse resp) {
        super(resp);
    }

    @Override
    public void setHeader(String name, String value) {
        System.out.println("Setting header: " + name);
        super.setHeader(name, value);
    }
}
```

---

# ✅ **8. HttpSessionListener**

### **Definition**

A listener interface for session life-cycle events.

### **What it does**

Lets you run logic when:

- a session is created
    
- a session is destroyed
    

### **Example**

```java
@WebListener
public class MySessionListener implements HttpSessionListener {
    @Override
    public void sessionCreated(HttpSessionEvent se) {
        System.out.println("Session created: " + se.getSession().getId());
    }

    @Override
    public void sessionDestroyed(HttpSessionEvent se) {
        System.out.println("Session destroyed");
    }
}
```

---

# ✅ **9. HttpSessionEvent**

### **Definition**

Event object passed to session listeners.

### **What it does**

Provides access to the session that triggered the event.

### **Example**

```java
@Override
public void sessionCreated(HttpSessionEvent event) {
    HttpSession s = event.getSession();
    System.out.println("New ID: " + s.getId());
}
```

---

# ✅ **10. HttpServletMapping**

### **Definition**

Provides information about how an HTTP request matched a servlet.

### **What it does**

Helps identify mapping pattern and matched path.

### **Example**

```java
protected void doGet(HttpServletRequest req, HttpServletResponse resp)
        throws IOException {
    HttpServletMapping mapping = req.getHttpServletMapping();
    resp.getWriter().write("Matched pattern: " + mapping.getPattern());
}
```

---

# 🏁 **BONUS: Other Useful Classes**

These are part of the package but less critical:

## **HttpSessionIdListener**

Listens specifically to ID change (e.g., on re-authentication).

```java
@WebListener
public class IdChangeListener implements HttpSessionIdListener {
    @Override
    public void sessionIdChanged(HttpSessionEvent event, String oldId) {
        System.out.println("Session ID changed");
    }
}
```

---


##### Tags : [[1 - Spring Security 🍌]]