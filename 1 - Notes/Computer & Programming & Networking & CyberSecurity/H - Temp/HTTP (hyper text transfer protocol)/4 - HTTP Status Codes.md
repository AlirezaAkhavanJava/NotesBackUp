
### 🔹 What Are They?

When a server responds to your HTTP request, it sends a **status code** to tell you how the request went.  
They are **3-digit numbers** grouped into **5 categories**.

---

### 📘 Categories

|Code Range|Category|Meaning|
|---|---|---|
|**1xx**|Informational|Request received, still processing|
|**2xx**|Success|Everything went fine ✅|
|**3xx**|Redirection|Go somewhere else (URL changed)|
|**4xx**|Client Error|You did something wrong ❌|
|**5xx**|Server Error|Server failed to handle request 💀|

---

### 🔹 Common Codes Explained

|Code|Meaning|Example|
|---|---|---|
|**200 OK**|Request succeeded|GET /users works fine|
|**201 Created**|New resource created|POST /users (added user)|
|**204 No Content**|Request succeeded, no data to return|DELETE /users/5|
|**301 Moved Permanently**|URL changed|Redirected to new URL|
|**400 Bad Request**|Invalid input|Missing field in JSON|
|**401 Unauthorized**|Not logged in|Missing or wrong token|
|**403 Forbidden**|You’re logged in but not allowed|Normal user accessing admin page|
|**404 Not Found**|Resource doesn’t exist|/user/99 doesn’t exist|
|**409 Conflict**|Resource conflict|Trying to create something that already exists|
|**500 Internal Server Error**|Server crashed or failed|Code bug|
|**503 Service Unavailable**|Server temporarily down|Maintenance mode|

---

### 💻 Example: Returning Codes in Spring Boot

```java
@RestController
@RequestMapping("/api")
public class StatusDemoController {

    @PostMapping("/create")
    public ResponseEntity<String> createResource(@RequestBody String data) {
        if (data.isEmpty()) {
            return ResponseEntity.badRequest().body("Missing data"); // 400
        }
        return ResponseEntity.status(201).body("Created successfully"); // 201
    }

    @GetMapping("/users/{id}")
    public ResponseEntity<String> getUser(@PathVariable int id) {
        if (id == 0) {
            return ResponseEntity.status(404).body("User not found"); // 404
        }
        return ResponseEntity.ok("User data"); // 200
    }
}
```

🧠 **Explanation:**

- `ResponseEntity` → gives full control over status code + body.
    
- `.ok()` = 200, `.badRequest()` = 400, `.status(201)` = 201.
    

---

## 🧠 Topic 2: HTTP Headers

---

### 🔹 What Are Headers?

**Headers** are key-value pairs sent **before the body** in HTTP messages.  
They carry **extra information** about the request or response — like metadata, content type, authorization, etc.

---

### 📬 Common Request Headers

|Header|Purpose|Example|
|---|---|---|
|**Host**|Server address|`Host: api.example.com`|
|**User-Agent**|Info about client|`User-Agent: Chrome/142`|
|**Content-Type**|Type of body data|`application/json`|
|**Accept**|What response formats client can handle|`Accept: application/json`|
|**Authorization**|Credentials or token|`Bearer eyJhbGci...`|
|**Cookie**|Session info|`Cookie: sessionid=xyz`|
|**Cache-Control**|How caching should work|`Cache-Control: no-cache`|

---

### 📦 Common Response Headers

|Header|Purpose|Example|
|---|---|---|
|**Content-Type**|Format of response|`application/json`|
|**Content-Length**|Size of response body|`1234`|
|**Server**|Info about backend server|`Server: nginx/1.20`|
|**Set-Cookie**|Send cookies to client|`Set-Cookie: sessionid=abc123`|
|**Location**|Where to redirect|`Location: /login`|
|**Access-Control-Allow-Origin**|CORS control|`*` (allow all origins)|

---

### 💻 Example: Custom Headers in Java (HttpClient)

```java
HttpRequest request = HttpRequest.newBuilder()
        .uri(URI.create("https://api.example.com/data"))
        .header("Authorization", "Bearer mySecretToken")
        .header("Accept", "application/json")
        .GET()
        .build();
```

---

### 💻 Example: Custom Headers in Spring Boot

```java
@GetMapping("/custom-header")
public ResponseEntity<String> customHeader() {
    HttpHeaders headers = new HttpHeaders();
    headers.add("Custom-Header", "Hello-Ethan");
    return new ResponseEntity<>("Headers sent!", headers, HttpStatus.OK);
}
```

**Result:**

```
HTTP/1.1 200 OK
Custom-Header: Hello-Ethan
Content-Type: text/plain
```

---

### 🧩 Summary Table

|Concept|Purpose|Example|
|---|---|---|
|**Status Code**|Communicates result of the request|`200 OK`, `404 Not Found`|
|**Request Headers**|Provide client info or data type|`Authorization`, `Accept`|
|**Response Headers**|Provide metadata about response|`Content-Type`, `Set-Cookie`|
|**Spring Boot**|Use `ResponseEntity` & `HttpHeaders`|Add custom status or headers easily|

---

### 🧠 Quick Recap

- **Status codes** tell what happened (success, error, etc.)
    
- **Headers** describe the data (format, auth, caching, etc.)
    
- **Spring Boot** makes them easy to control using `ResponseEntity` and `HttpHeaders`.
    

---



[[1 - HTTP]]