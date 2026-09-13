
## 📨 1️⃣ What is an HTTP Request?

An **HTTP request** is a message sent by the **client (browser, app, or code)** to the **server** asking for something — data, a file, an action, etc.

It has 3 main parts:

|Part|Example|Meaning|
|---|---|---|
|**Method (Verb)**|`GET`, `POST`, `PUT`, `DELETE`|What action to perform|
|**URL (Path)**|`/users/10`|Where the request goes|
|**Headers**|`Content-Type: application/json`|Meta info like format, auth, etc.|
|**Body (Optional)**|`{ "name": "Ethan" }`|The data you send (mainly in POST/PUT)|

---

### 🧩 Example HTTP Request (Raw)

```
POST /api/users HTTP/1.1
Host: example.com
Content-Type: application/json
Content-Length: 27

{
  "username": "Ethan"
}
```

---

## ⚙️ 2️⃣ HTTP Request in Java (using `HttpClient`)

Java 11+ includes a modern `HttpClient` for making HTTP requests.

```java
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public class HttpExample {
    public static void main(String[] args) throws Exception {
        HttpClient client = HttpClient.newHttpClient();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("https://jsonplaceholder.typicode.com/posts"))
                .GET() // You can also use POST, PUT, DELETE
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

        System.out.println("Status: " + response.statusCode());
        System.out.println("Body: " + response.body());
    }
}
```

**Explanation:**

- `HttpClient` → Sends the request.
    
- `HttpRequest` → Describes what to send (URL, headers, body).
    
- `HttpResponse` → Holds the result (status, body, headers).
    

---

## ☕ 3️⃣ HTTP Request in Spring Boot

### ➤ Example: Handling a Request in a Controller

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    @GetMapping("/{id}")
    public ResponseEntity<String> getUser(@PathVariable Long id) {
        return ResponseEntity.ok("User ID: " + id);
    }

    @PostMapping
    public ResponseEntity<String> createUser(@RequestBody String userData) {
        return ResponseEntity.status(HttpStatus.CREATED).body("User created: " + userData);
    }
}
```

**What happens:**

1. The client sends a request to `/api/users`.
    
2. Spring Boot automatically maps it to the correct controller method.
    
3. The method returns a `ResponseEntity` — which becomes the **HTTP Response**.
    

---

## 📦 4️⃣ What is an HTTP Response?

An **HTTP response** is what the **server sends back** to the **client** after processing a request.

It has:

|Part|Example|Meaning|
|---|---|---|
|**Status Line**|`HTTP/1.1 200 OK`|Result code|
|**Headers**|`Content-Type: application/json`|Metadata|
|**Body**|`{ "id": 10, "name": "Ethan" }`|Data being returned|

---

### 🧩 Example HTTP Response (Raw)

```
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 35

{
  "id": 10,
  "name": "Ethan"
}
```

---

## ⚙️ 5️⃣ HTTP Response in Java

```java
HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
System.out.println(response.statusCode()); // 200
System.out.println(response.headers());    // Response headers
System.out.println(response.body());       // JSON or text
```

---

## ☕ 6️⃣ HTTP Response in Spring Boot

Handled using `ResponseEntity` or return types.

```java
@GetMapping("/welcome")
public ResponseEntity<String> welcome() {
    return new ResponseEntity<>("Welcome to UltimateArcadeBoot!", HttpStatus.OK);
}
```

OR simplified:

```java
@GetMapping("/simple")
public String simpleResponse() {
    return "Hello Ethan!";
}
```

Spring automatically wraps it in:

```
HTTP/1.1 200 OK
Content-Type: text/plain
Body: Hello Ethan!
```

---

## 🔑 7️⃣ Common HTTP Methods (Verbs)

|Method|Purpose|Example|
|---|---|---|
|**GET**|Read data|`/users`|
|**POST**|Create new data|`/users`|
|**PUT**|Update full record|`/users/10`|
|**PATCH**|Partial update|`/users/10`|
|**DELETE**|Remove record|`/users/10`|

---

## 🧠 Summary:

|Concept|Java Class|Spring Boot Equivalent|
|---|---|---|
|Request|`HttpRequest`|`@RequestMapping`, `@GetMapping`, etc.|
|Response|`HttpResponse`|`ResponseEntity`|
|Status|`response.statusCode()`|`HttpStatus`|
|Body|`response.body()`|`ResponseEntity.body()`|




[[1 - HTTP]]