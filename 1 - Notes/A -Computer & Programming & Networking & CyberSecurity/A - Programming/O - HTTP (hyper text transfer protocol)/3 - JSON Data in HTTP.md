


## 🧠 Topic: Sending JSON Data in HTTP (Java + Spring Boot)

---

### 🔹 What Is JSON?

**JSON (JavaScript Object Notation)** is a lightweight data format used to send data between client and server.  
It looks like this:

```json
{
  "id": 1,
  "name": "Ethan",
  "score": 9000
}
```

Servers love JSON because it’s **easy to read, easy to parse, and language-independent**.

---

## 1️⃣ Sending JSON in Plain Java (Using `HttpClient`)

### ✅ Example

```java
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public class SendJsonExample {
    public static void main(String[] args) throws Exception {
        HttpClient client = HttpClient.newHttpClient();

        // JSON body
        String json = """
            {
                "title": "Ultimate Arcade",
                "body": "Best game ever!",
                "userId": 101
            }
        """;

        // Create request with JSON body
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("https://jsonplaceholder.typicode.com/posts"))
                .header("Content-Type", "application/json")  // Important!
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();

        // Send request
        HttpResponse<String> response =
                client.send(request, HttpResponse.BodyHandlers.ofString());

        System.out.println("Status Code: " + response.statusCode());
        System.out.println("Response Body: " + response.body());
    }
}
```

### 🧠 What’s happening:

1. Create a **JSON string**.
    
2. Add header → `"Content-Type: application/json"`.
    
3. Send a **POST** request with `BodyPublishers.ofString(json)`.
    
4. Server gets your JSON data in the body.
    

---

## 2️⃣ Sending JSON in **Spring Boot**

In Spring Boot, JSON handling is automatic — you just send or receive Java objects, and Spring converts them using **Jackson**.

---

### 🧩 Example: Sending JSON to an External API

#### Service

```java
import org.springframework.http.*;
import org.springframework.web.client.RestTemplate;
import java.util.Map;

public class JsonSender {
    public static void main(String[] args) {
        RestTemplate restTemplate = new RestTemplate();

        // JSON body as Map (could also use a custom class)
        Map<String, Object> requestBody = Map.of(
            "title", "Arcade Champion",
            "body", "Reached level 99!",
            "userId", 202
        );

        // Set headers
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        // Combine body + headers
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        // Send POST request
        ResponseEntity<String> response = restTemplate.postForEntity(
                "https://jsonplaceholder.typicode.com/posts",
                entity,
                String.class
        );

        System.out.println("Status: " + response.getStatusCode());
        System.out.println("Response: " + response.getBody());
    }
}
```

### 🧠 Key Parts:

- `HttpHeaders` → sets content type (like `Content-Type: application/json`)
    
- `HttpEntity` → wraps your body + headers
    
- `RestTemplate.postForEntity()` → sends POST with your JSON
    

Spring converts your Java `Map` or POJO automatically into JSON.

---

## 3️⃣ Receiving JSON in Spring Boot

If your **server** is receiving JSON, it’s just as simple.

### Example Controller

```java
@RestController
@RequestMapping("/api")
public class GameController {

    @PostMapping("/score")
    public String receiveScore(@RequestBody PlayerScore score) {
        return "Received: " + score.getName() + " with score " + score.getPoints();
    }
}

class PlayerScore {
    private String name;
    private int points;

    // getters and setters
}
```

### 🧠 Explanation:

- `@RequestBody` → tells Spring to **convert JSON → Java Object**
    
- `PlayerScore` → your Java model class
    
- Spring uses **Jackson** to handle all conversions automatically
    

Example JSON request:

```json
{
  "name": "Ethan",
  "points": 12000
}
```

Response:

```
Received: Ethan with score 12000
```

---

## 🧩 Summary Table

|Task|Java 11+|Spring Boot|
|---|---|---|
|Send JSON|`HttpClient` + `.header("Content-Type","application/json")`|`RestTemplate.postForEntity()`|
|Receive JSON|Manually parse|`@RequestBody` auto-converts|
|JSON Converter|Manual string|**Jackson** built-in|
|Recommended|✅ HttpClient|✅ RestTemplate / WebClient|

---

## 🔹 In short

- Always set header `Content-Type: application/json`
    
- Spring Boot automatically converts between **JSON ↔ Java Objects**
    
- Use:
    
    - `HttpClient` → for plain Java
        
    - `RestTemplate` or `WebClient` → for Spring Boot
        

---



[[1 - HTTP]]