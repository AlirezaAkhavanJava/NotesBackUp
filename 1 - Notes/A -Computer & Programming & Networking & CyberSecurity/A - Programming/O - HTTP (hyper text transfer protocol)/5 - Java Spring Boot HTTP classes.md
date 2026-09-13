

## ⚙️ 1️⃣ Core Java HTTP Classes (No Spring)

### 🧩 `java.net.HttpURLConnection`

- The **classic** class for HTTP requests (since Java 1.1)
    
- Works with all Java versions, but verbose
    

#### 🔹 Common Methods

|Method|Description|
|---|---|
|`openConnection()`|Opens a connection to a URL|
|`setRequestMethod("GET" / "POST")`|Sets HTTP method|
|`setRequestProperty("Header", "Value")`|Adds headers|
|`getResponseCode()`|Returns HTTP status code|
|`getInputStream()`|Reads success response body|
|`getErrorStream()`|Reads error response body|
|`disconnect()`|Closes the connection|
|`setDoOutput(true)`|Allows sending a request body (for POST/PUT)|

#### ✅ Example

```java
URL url = new URL("https://api.example.com/data");
HttpURLConnection conn = (HttpURLConnection) url.openConnection();
conn.setRequestMethod("GET");
int code = conn.getResponseCode();
```

---

### 🧩 `java.net.http.HttpClient` (Java 11+)

- Modern replacement for `HttpURLConnection`
    
- Easier syntax, supports **HTTP/2** and **async**
    

#### 🔹 Common Classes & Methods

|Class|Purpose|Common Methods|
|---|---|---|
|`HttpClient`|Main HTTP client|`.send()`, `.sendAsync()`|
|`HttpRequest`|Builds HTTP requests|`.uri()`, `.header()`, `.POST()`, `.GET()`, `.PUT()`|
|`HttpResponse`|Represents server response|`.statusCode()`, `.body()`, `.headers()`|

#### ✅ Example

```java
HttpClient client = HttpClient.newHttpClient();

HttpRequest request = HttpRequest.newBuilder()
        .uri(URI.create("https://example.com"))
        .header("Accept", "application/json")
        .GET()
        .build();

HttpResponse<String> response =
        client.send(request, HttpResponse.BodyHandlers.ofString());

System.out.println(response.statusCode());
System.out.println(response.body());
```

---

### 🧩 Supporting Classes

|Class|Description|
|---|---|
|`URI`|Represents a Uniform Resource Identifier (used in `HttpRequest`)|
|`HttpHeaders` (in `java.net.http`)|Read headers from response|
|`HttpResponse.BodyHandlers`|Converts response to string, byte array, file, etc.|

---

## 🚀 2️⃣ Spring Boot HTTP Classes

Spring builds on Java’s HTTP API — and gives you high-level helpers.

---

### 🧩 `RestTemplate` (Classic, Blocking)

|Method|Description|
|---|---|
|`getForObject(url, Class<T>)`|Send GET request, return body|
|`getForEntity(url, Class<T>)`|GET + full `ResponseEntity`|
|`postForObject(url, body, Class<T>)`|Send POST with body|
|`postForEntity(url, body, Class<T>)`|POST + status + headers|
|`put(url, body)`|PUT request|
|`delete(url)`|DELETE request|
|`exchange(url, HttpMethod, HttpEntity, Class<T>)`|Fully custom request (headers, method, body)|

#### ✅ Example

```java
RestTemplate rest = new RestTemplate();
String result = rest.getForObject("https://api.example.com/users", String.class);
```

---

### 🧩 `WebClient` (Modern, Non-blocking - Reactive)

|Method|Description|
|---|---|
|`.get()`, `.post()`, `.put()`, `.delete()`|Choose HTTP method|
|`.uri(url)`|Set target URL|
|`.header(name, value)`|Add headers|
|`.bodyValue(obj)`|Add body|
|`.retrieve()`|Execute and get response|
|`.bodyToMono(Class<T>)`|Convert response to object|
|`.exchangeToMono()`|Access raw response|

#### ✅ Example

```java
WebClient client = WebClient.create("https://api.example.com");
String response = client.get()
        .uri("/users/1")
        .retrieve()
        .bodyToMono(String.class)
        .block();
```

---

### 🧩 `ResponseEntity`

Represents **the entire HTTP response** (status, headers, and body).

|Method|Purpose|
|---|---|
|`ok(body)`|200 OK|
|`status(HttpStatus)`|Custom status|
|`body(Object)`|Set body|
|`headers(HttpHeaders)`|Set headers|
|`build()`|Build final response|

#### ✅ Example

```java
@GetMapping("/info")
public ResponseEntity<String> info() {
    return ResponseEntity
            .status(HttpStatus.CREATED)
            .header("Custom", "Ethan")
            .body("Resource created");
}
```

---

### 🧩 `HttpEntity` & `HttpHeaders`

|Class|Purpose|
|---|---|
|`HttpEntity<T>`|Wraps body + headers for requests|
|`HttpHeaders`|Represents headers, used to set or get header values|

#### ✅ Example

```java
HttpHeaders headers = new HttpHeaders();
headers.setContentType(MediaType.APPLICATION_JSON);
HttpEntity<String> entity = new HttpEntity<>("{\"name\":\"Ethan\"}", headers);
```

---

### 🧩 `HttpStatus`

Enum of all HTTP status codes in Spring.

|Example|Meaning|
|---|---|
|`HttpStatus.OK`|200|
|`HttpStatus.CREATED`|201|
|`HttpStatus.BAD_REQUEST`|400|
|`HttpStatus.NOT_FOUND`|404|
|`HttpStatus.INTERNAL_SERVER_ERROR`|500|

---

### 🧩 `HttpMethod`

Enum representing HTTP verbs:

```java
HttpMethod.GET
HttpMethod.POST
HttpMethod.PUT
HttpMethod.DELETE
HttpMethod.PATCH
```

---

## 🔹 Summary Table

|Area|Class|Description|Modern or Legacy|
|---|---|---|---|
|Core Java|`HttpURLConnection`|Basic old-style HTTP client|Legacy|
|Core Java|`HttpClient`, `HttpRequest`, `HttpResponse`|Modern Java HTTP API|✅ Modern|
|Spring|`RestTemplate`|Synchronous HTTP client|Common|
|Spring|`WebClient`|Reactive, async HTTP client|✅ Modern|
|Spring|`ResponseEntity`, `HttpEntity`, `HttpHeaders`|Build responses manually|✅ Common|
|Spring|`HttpStatus`, `HttpMethod`|Enumerations for codes & verbs|✅ Common|

---

### 🧠 Quick Recap

- Use **`HttpClient`** for pure Java (new projects).
    
- Use **`RestTemplate`** for simple Spring apps.
    
- Use **`WebClient`** for async or reactive Spring apps.
    
- Use **`ResponseEntity`** and **`HttpHeaders`** to control HTTP responses.
    

---




[[1 - HTTP]]