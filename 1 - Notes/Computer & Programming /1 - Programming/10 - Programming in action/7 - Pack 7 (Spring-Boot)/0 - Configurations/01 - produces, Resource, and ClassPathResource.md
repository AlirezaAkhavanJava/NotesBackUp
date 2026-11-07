


These three ideas meet in one place: a controller method that sends a file from your project back to a client as JSON. You'll learn each piece separately, then see how they combine.

## Part 1: `@GetMapping(produces = ...)`

### Definition

`@GetMapping` is a shortcut for `@RequestMapping(method = RequestMethod.GET)`. It marks a method as the handler for HTTP GET requests. The `produces` attribute declares which response media types that method is willing to return. A media type (also called a MIME type) is the label that tells the client what format the body is in, such as `application/json`, `text/html`, or `application/xml`.

### Why it exists

HTTP has a built-in negotiation mechanism. The client sends an `Accept` header saying what formats it can handle, and the server replies with a `Content-Type` header saying what format it actually sent. Consider a client that sends:

```
GET /api/report HTTP/1.1
Accept: application/xml
```

If your server has only a JSON method at that path, what should happen? Without `produces`, Spring would run the JSON method and send JSON to a client that asked for XML. With `produces`, Spring checks the `Accept` header before choosing the method, and if nothing matches, it refuses the request.

### Problems it solves

First, it lets you have multiple methods at the same URL that differ only by format. You can serve `/api/report` as JSON for one client and as XML for another, and Spring picks the right method based on the `Accept` header.

Second, it turns mismatches into clear errors. A client that asks for something you can't provide gets a `406 Not Acceptable` response, instead of receiving data in a format it can't parse and failing in a confusing way.

Third, it documents your contract. Anyone reading the method signature knows exactly what the endpoint returns.

### How it works

When a request arrives, Spring follows these steps:

1. It finds all methods mapped to the URL and HTTP verb.
2. It compares each method's `produces` value with the request's `Accept` header.
3. If exactly one method matches, it runs that method.
4. If the request has no `Accept` header, Spring treats it as accepting anything, so the first matching method runs.
5. If no method matches, Spring returns `406`.

### Example

```java
package com.example.demo.controller;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/status")
public class StatusController {

    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Map<String, String> statusAsJson() {
        return Map.of("service", "running", "version", "1.0");
    }

    @GetMapping(produces = MediaType.TEXT_PLAIN_VALUE)
    public String statusAsText() {
        return "service=running version=1.0";
    }
}
```

**What this does:**

- `MediaType.APPLICATION_JSON_VALUE` is the constant for the string `"application/json"`. Using the constant avoids typos, and the compiler catches a misspelled constant name where a misspelled string would fail silently at runtime.
- Both methods share the URL `/api/status`. They are distinguished only by `produces`.
- The `Map` return value is converted to JSON automatically, because Jackson is on the classpath in a standard Spring Boot project.
- The `String` method is sent as plain text.

### Testing it

Open a terminal on your Debian machine and run:

```bash
curl -i -H "Accept: application/json" http://localhost:8080/api/status
```

The response body is JSON, and the header includes `Content-Type: application/json`.

```bash
curl -i -H "Accept: text/plain" http://localhost:8080/api/status
```

This returns the plain-text version.

```bash
curl -i -H "Accept: application/xml" http://localhost:8080/api/status
```

This returns `406 Not Acceptable`, because neither method produces XML. This is the mechanism working as intended.

### Two details to remember

`produces` controls matching, and it doesn't change the format of the response body by itself. The body is serialized by whichever message converter handles the return type. Jackson handles objects as JSON, and `ResourceHttpMessageConverter` handles `Resource` objects, which is where the next section begins.

Also, the `produces` value is a _list_, so you can write `produces = {"application/json", "application/xml"}` if a method supports both.

## Part 2: `Resource`

### Definition

`Resource` is an interface in `org.springframework.core` that represents a source of bytes. It could be a file on disk, a file inside your JAR, a URL, or an array of bytes in memory. The key methods are:

- `getInputStream()` opens the content for reading.
- `exists()` tells you whether the content is actually there.
- `getFilename()` returns the name portion, such as `settings.json`.
- `contentLength()` returns the size in bytes.
- `isReadable()` checks whether the content can be read.

### Why it exists

Java already has several ways to access content, and each works differently:

- `java.io.File` refers to a path on the file system.
- `java.net.URL` refers to a location that might be on the web or on disk.
- `ClassLoader.getResourceAsStream(...)` reads from the classpath.

Each one has its own method names, its own exceptions, and its own rules. If your code uses `File` directly, it works on your laptop but can break when the app is packaged. Spring's `Resource` interface wraps all of these behind one common API, so your code can ask for "a resource" and not care where it lives.

### Problems it solves

It makes code independent of where the content lives. The same method can read from the classpath during development and from a mounted directory in production, depending only on which implementation or prefix you use.

It makes testing easier. You can substitute a `ByteArrayResource` with fixed content in a unit test without touching the disk.

It integrates with Spring. You can inject a `Resource` with `@Value`, and Spring can even return a `Resource` from a controller and stream it to the client efficiently.

### The implementations

`Resource` is an interface, so you always use one of its implementations:

- `ClassPathResource` reads from the classpath. This is the one you'll use most inside a packaged app.
- `FileSystemResource` reads from a path on disk.
- `UrlResource` reads from a URL.
- `ByteArrayResource` wraps content that already lives in memory.

### Location prefixes

When Spring loads a resource from a string, the prefix decides the source:

- `classpath:config/settings.json` comes from the classpath.
- `file:/var/app/data.csv` comes from the file system.
- `https://example.com/logo.png` comes from a URL.

You'll see these prefixes most often in `@Value` annotations.

## Part 3: `ClassPathResource`

### Definition

`ClassPathResource` is a concrete implementation of `Resource` that loads a file from the classpath. The classpath is the set of locations Java searches for resources and classes. In a Spring Boot project, that includes `src/main/resources` during development and the root of your JAR when the app is packaged.

### Why it exists

Think about what happens when you package your application. Maven or Gradle bundles your code and resources into a single `.jar` file. Inside that JAR, your `settings.json` is no longer a file on disk, it's an entry in a compressed archive. A path like `src/main/resources/settings.json` doesn't exist anymore.

This is the most common beginner mistake in Spring. The following code works in your IDE and fails in the packaged app:

```java
// Breaks once the app is packaged in a JAR
File file = new File("src/main/resources/settings.json");
```

`ClassPathResource` solves this by looking inside the classpath instead of the file system. You describe the path relative to the classpath root, and Spring finds it whether the app is running from your IDE or from a JAR.

### How to use it

```java
Resource resource = new ClassPathResource("config/settings.json");
```

This points to `src/main/resources/config/settings.json`. Notice there is no leading slash and no `src/main/resources` in the path. The path starts at the root of the classpath, which corresponds to `src/main/resources` during development.

### Key behaviors

If the file doesn't exist, `exists()` returns `false`. Always check it before reading, so you can respond cleanly instead of throwing an unexpected exception.

`getFile()` tries to return a `java.io.File`, and it fails when the resource is inside a JAR. Avoid it. Use `getInputStream()` instead, which works in both places.

## Part 4: Putting It All Together

Here's a controller that serves a JSON configuration file stored in your project. It uses all three ideas.

First, create the file at `src/main/resources/config/settings.json`:

```json
{
  "appName": "Learning Platform",
  "maxUploadSizeMb": 10,
  "features": ["notifications", "dark-mode"]
}
```

Next, create the controller:

```java
package com.example.demo.controller;

import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/settings")
public class SettingsController {

    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Resource> getSettings() {
        Resource settings = new ClassPathResource("config/settings.json");

        if (!settings.exists()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }

        return ResponseEntity.ok(settings);
    }
}
```

**What each part does:**

- `produces = MediaType.APPLICATION_JSON_VALUE` declares that this method returns JSON. A client asking for XML gets a `406` before this code runs.
- `ClassPathResource("config/settings.json")` locates the file inside the classpath, so it works in the IDE and in the packaged JAR.
- `exists()` guards against a missing file. Without this check, a typo in the path would produce a confusing server error. With it, the client receives a clear `404`.
- `ResponseEntity.ok(settings)` wraps the resource in a `200 OK` response. Spring's `ResourceHttpMessageConverter` streams the file bytes directly to the client, and it sets `Content-Type` from the file name, which is why `produces` and the file's real format should agree.

Test it:

```bash
curl -i -H "Accept: application/json" http://localhost:8080/api/settings
```

You should see `200 OK` with the JSON body. Now rename `settings.json` to `settings.bak`, rebuild or restart, and run the same command. You should get `404`. Rename it back afterward.

### Reading a resource as a String

Sometimes you want the text itself, for example to modify it before sending. Spring provides a utility for this:

```java
import org.springframework.util.StreamUtils;
import java.nio.charset.StandardCharsets;
import java.io.IOException;

String json = StreamUtils.copyToString(
        settings.getInputStream(),
        StandardCharsets.UTF_8);
```

This opens the stream, reads all bytes, and decodes them as UTF-8. Note that `getInputStream()` throws `IOException`, so the calling method must declare it or handle it. Also note that `getInputStream()` opens a stream that should be closed. `StreamUtils.copyToString` closes it for you, which is one reason to prefer it over manual reading.

### Injecting a resource with `@Value`

If the file path is fixed at startup, you can have Spring inject it directly:

```java
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;

@Value("classpath:config/settings.json")
private Resource settingsFile;
```

Spring resolves the `classpath:` prefix and gives you a ready-to-use `Resource` field. This is cleaner when the file never changes at runtime.






[[Spring Framework]]