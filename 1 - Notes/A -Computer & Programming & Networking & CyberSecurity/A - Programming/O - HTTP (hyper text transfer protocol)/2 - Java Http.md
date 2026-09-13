
## 🧠 Topic: HTTP in Java

### 🔹 What it means

In Java, “HTTP” refers to how your program **sends and receives data** over the web — just like a browser.  
You can:

- **Send requests** to servers (APIs, websites)
    
- **Receive responses** (JSON, HTML, files, etc.)
    

---

## 1️⃣ Using `HttpURLConnection` (Old School, Built-In)

### 🧩 Explanation

`HttpURLConnection` is a **built-in Java class** in `java.net` package.  
It lets you make HTTP requests manually — it’s simple but verbose.

### ✅ Example

```java
import java.io.*;
import java.net.*;

public class HttpExample {
    public static void main(String[] args) throws IOException {
        // 1. URL to connect
        URL url = new URL("https://jsonplaceholder.typicode.com/posts/1");

        // 2. Open connection
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();

        // 3. Set HTTP method (GET, POST, etc.)
        conn.setRequestMethod("GET");

        // 4. Read response
        BufferedReader reader = new BufferedReader(
                new InputStreamReader(conn.getInputStream()));
        String line;
        StringBuilder response = new StringBuilder();
        while ((line = reader.readLine()) != null) {
            response.append(line);
        }
        reader.close();

        // 5. Print result
        System.out.println("Response Code: " + conn.getResponseCode());
        System.out.println("Body: " + response.toString());

        // 6. Close connection
        conn.disconnect();
    }
}
```

### 🧠 What happens here

1. You connect to a URL.
    
2. Tell it what HTTP method to use.
    
3. Read the response stream.
    
4. Print or use the data.
    

This is **core Java HTTP** — no extra libraries needed.

---

## 2️⃣ Using `HttpClient` (Modern, Java 11+)

### 🧩 Explanation

`HttpClient` is the **new standard** HTTP API introduced in **Java 11**.  
It’s easier, cleaner, and supports async and HTTP/2.

### ✅ Example

```java
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public class HttpClientExample {
    public static void main(String[] args) throws Exception {
        // 1. Create client
        HttpClient client = HttpClient.newHttpClient();

        // 2. Create request
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("https://jsonplaceholder.typicode.com/posts/1"))
                .GET()
                .build();

        // 3. Send and get response
        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

        // 4. Print data
        System.out.println("Status Code: " + response.statusCode());
        System.out.println("Response Body: " + response.body());
    }
}
```

### 🧠 Explanation

- `HttpClient` → handles network connection
    
- `HttpRequest` → represents what you’re sending
    
- `HttpResponse` → contains what you received
    

Much cleaner than `HttpURLConnection`.

---

## 3️⃣ HTTP in **Spring Boot**

Spring Boot builds on top of Java’s HTTP features.

### 🧩 Example: Using `RestTemplate`

```java
import org.springframework.web.client.RestTemplate;
import org.springframework.http.ResponseEntity;

public class SpringHttpExample {
    public static void main(String[] args) {
        RestTemplate restTemplate = new RestTemplate();

        // Send GET request
        String url = "https://jsonplaceholder.typicode.com/posts/1";
        ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);

        System.out.println("Status Code: " + response.getStatusCode());
        System.out.println("Body: " + response.getBody());
    }
}
```

### 💡 New term:

- `RestTemplate` → Spring’s helper class for making HTTP requests (built on top of HttpClient).
    
- Returns a `ResponseEntity` (contains both headers and body).
    

---

## 🧩 In Short

|Tool|Introduced|Description|Best For|
|---|---|---|---|
|`HttpURLConnection`|Java 1.1|Old low-level HTTP class|Basic, simple apps|
|`HttpClient`|Java 11|Modern, clean, async ready|Most Java apps|
|`RestTemplate`|Spring|Simplified wrapper|Spring Boot projects|
|`WebClient`|Spring WebFlux|Reactive, non-blocking|Async apps|

---

### 🔹 Summary

- HTTP in Java = communicating with web servers using classes like `HttpClient` or `RestTemplate`.
    
- Choose based on your stack:
    
    - **Plain Java** → `HttpClient`
        
    - **Spring Boot** → `RestTemplate` or `WebClient`
        



[[1 - HTTP]]