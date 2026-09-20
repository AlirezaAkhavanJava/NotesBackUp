
## 🧠 Topic: What is HTTP?

### 🔹 Definition

**HTTP (HyperText Transfer Protocol)** is the **communication system of the web**.  
It defines **how data is sent and received** between:

- **Client** → usually your browser or app
    
- **Server** → where your website or backend logic lives
    

So when you open a website, your browser sends an **HTTP request**, and the server replies with an **HTTP response**.

---

### 🔹 Basic Example (Conceptually)

**Client:** “Hey server, give me the homepage (index.html).”  
**Server:** “Here you go (HTML + CSS + images).”

That’s one full HTTP cycle:

```
Request → Processing → Response
```

---

### 🔹 Structure of HTTP

HTTP messages are **text-based** and follow a clear format.

#### 1️⃣ HTTP Request

Example:

```
GET /index.html HTTP/1.1
Host: www.example.com
User-Agent: Chrome/142
Accept: text/html
```

**Explanation:**

- `GET` → the HTTP method (asking for data)
    
- `/index.html` → the resource
    
- `Host` → server name
    
- `User-Agent` → client info
    
- `Accept` → what type of content you want
    

#### 2️⃣ HTTP Response

Example:

```
HTTP/1.1 200 OK
Content-Type: text/html
Content-Length: 1256

<html>...</html>
```

**Explanation:**

- `200 OK` → status code (means success)
    
- `Content-Type` → what the body contains
    
- After headers → comes the **body**, the actual data.
    

---

### 🔹 HTTP is Stateless

Each request is **independent** — the server doesn’t remember you.  
To keep track (like login sessions), we use **cookies**, **sessions**, or **tokens**.

---

### 🔹 Common HTTP Methods

|Method|Meaning|Example Use|
|---|---|---|
|GET|Request data|Get list of users|
|POST|Send new data|Add a new user|
|PUT|Update data|Edit an existing user|
|DELETE|Remove data|Delete user by ID|

---

## 💻 Example in Java (Spring Boot)

### Controller Example

```java
@RestController
@RequestMapping("/users")
public class UserController {

    // GET method
    @GetMapping
    public String getUsers() {
        return "List of users";
    }

    // POST method
    @PostMapping
    public String addUser() {
        return "User added!";
    }
}
```

Here:

- `@RestController` → marks this as a controller that returns HTTP responses.
    
- `@GetMapping`, `@PostMapping` → define HTTP methods.
    
- Spring Boot automatically converts these methods into HTTP endpoints.
    

---

### ⚙️ How this works

When you visit:

```
GET http://localhost:8080/users
```

Spring Boot sends:

```
Response: "List of users"
```

When you send:

```
POST http://localhost:8080/users
```

Spring Boot replies:

```
Response: "User added!"
```

---

### 🔹 Summary

- **HTTP** = language of web communication.
    
- Uses **requests** and **responses**.
    
- Is **stateless** by design.
    
- Used by browsers, APIs, and backend apps (like your Spring Boot app).
    




[[Java]] [[0 - Back-End]]