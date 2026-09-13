Date : 2025-09-04


## 1. Introduction

- **Files and Folders:** Java provides classes to manipulate files and directories.
    
- **APIs:** Java can interact with external services using HTTP clients.
    
- **Purpose:** Read, write, delete files, and integrate external data seamlessly.
    

**Tip:** Think of files as **storage boxes** and APIs as **windows to the internet**.

---

## 2. Working with Files

### 2.1 Creating and Writing Files

#### 2.1.1 Using `FileWriter`

```java
import java.io.FileWriter;
import java.io.IOException;

try (FileWriter writer = new FileWriter("example.txt")) {
    writer.write("Hello World");
} catch (IOException e) {
    e.printStackTrace();
}
```

- Writes characters to a file.
    
- Automatically creates the file if it doesn't exist.
    

#### 2.1.2 Using `Files.writeString` (Java 11+)

```java
import java.nio.file.Files;
import java.nio.file.Paths;

Files.writeString(Paths.get("example.txt"), "Hello World");
```

- Simple and modern way to write a full string to a file.
    

---

### 2.2 Reading Files

#### 2.2.1 Using `FileReader`

```java
import java.io.FileReader;
import java.io.IOException;

try (FileReader reader = new FileReader("example.txt")) {
    int ch;
    while ((ch = reader.read()) != -1) {
        System.out.print((char) ch);
    }
} catch (IOException e) {
    e.printStackTrace();
}
```

- Reads characters from a file sequentially.
    

#### 2.2.2 Using `Files.readString` (Java 11+)

```java
String content = Files.readString(Paths.get("example.txt"));
System.out.println(content);
```

- Reads the entire file into a string with one line.
    

#### 2.2.3 Processing Files as Stream (Java 8+)

```java
import java.nio.file.Files;
import java.nio.file.Paths;

Files.lines(Paths.get("example.txt"))
     .forEach(System.out::println);
```

- Reads file line by line as a **Stream**, enabling functional operations.
    

---

### 2.3 Deleting Files and Folders

#### 2.3.1 Using `Files.deleteIfExists`

```java
import java.nio.file.Files;
import java.nio.file.Paths;

Files.deleteIfExists(Paths.get("example.txt"));
```

- Deletes the file if it exists.
    

#### 2.3.2 Working with Directories

```java
Files.createDirectory(Paths.get("myFolder"));
Files.delete(Paths.get("myFolder"));
```

- Allows creating and deleting directories.
    

---

### 2.4 Checking File Properties

```java
Path path = Paths.get("example.txt");
System.out.println(Files.exists(path));
System.out.println(Files.isReadable(path));
System.out.println(Files.size(path));
```

- Check existence, readability, size, and other properties.
    

---

## 3. Making API Calls

### 3.1 Using `HttpURLConnection`

```java
import java.net.HttpURLConnection;
import java.net.URL;
import java.io.BufferedReader;
import java.io.InputStreamReader;

URL url = new URL("https://api.example.com/data");
HttpURLConnection con = (HttpURLConnection) url.openConnection();
con.setRequestMethod("GET");

try (BufferedReader in = new BufferedReader(new InputStreamReader(con.getInputStream()))) {
    String inputLine;
    StringBuilder content = new StringBuilder();
    while ((inputLine = in.readLine()) != null) {
        content.append(inputLine);
    }
    System.out.println(content.toString());
}
```

- Classic way to make HTTP GET requests.
    

### 3.2 Using `HttpClient` (Java 11+)

```java
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

HttpClient client = HttpClient.newHttpClient();
HttpRequest request = HttpRequest.newBuilder()
        .uri(URI.create("https://api.example.com/data"))
        .GET()
        .build();

HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
System.out.println(response.body());
```

- Modern, simple, and powerful API for HTTP requests.
    

### 3.3 Parsing JSON Responses

- Use libraries like **Jackson** or **Gson**.
    

```java
import com.fasterxml.jackson.databind.ObjectMapper;

ObjectMapper mapper = new ObjectMapper();
MyClass obj = mapper.readValue(response.body(), MyClass.class);
```

- Converts JSON response into Java objects.
    

---

## 4. Best Practices

1. Use **try-with-resources** to automatically close files and streams.
    
2. Prefer **`Files` API** for modern file operations.
    
3. Handle exceptions carefully for file and network operations.
    
4. Use **HttpClient** over `HttpURLConnection` for readability and modern features.
    
5. For APIs, always **validate and parse JSON carefully**.
    
6. Combine **Optionals and Streams** for safer and concise file or API data handling.
    

---

## 5. Real-World Applications

- Reading configuration files.
    
- Logging and storing application data.
    
- Interacting with REST APIs.
    
- Batch processing of files.
    
- Modern microservices handling JSON responses.
    

---

## 6. Summary

- **Files API:** Use `FileReader`, `FileWriter`, `Files` class for reading, writing, deleting, and streaming files.
    
- **APIs:** Use `HttpClient` for HTTP requests and parse responses with JSON libraries.
    
- Modern Java (8–25) improves **file streaming, string reading/writing, and HTTP operations**.
    

This guide ensures mastery of **Java Files and API interactions from beginner to senior-level**, including modern practices and features up to Java 25.



##### *Tags : [[Java]]