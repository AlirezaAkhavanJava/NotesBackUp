

**Definition.** `HttpServletRequest` and `HttpServletResponse` are two interfaces in `jakarta.servlet.http`. The container creates both objects for every incoming request. `HttpServletRequest` gives you read access to everything the client sent: the method, the URL, the headers, the parameters, and the body. `HttpServletResponse` gives you write access to everything the server sends back: the status code, the headers, and the body. `doGet` is the method in `HttpServlet` that the framework calls when a `GET` request arrives, and it receives those two objects as arguments.

```java
protected void doGet(HttpServletRequest req, HttpServletResponse resp)
        throws ServletException, IOException
```

You never create these objects yourself. Tomcat builds them from the raw bytes on the socket and passes them in. Your job is to read from one and write to the other.

## Why they exist

Recall the HTTP text you saw earlier. A request is a block of text with a request line, headers, a blank line, and an optional body. A response is the same shape in reverse. Without a standard abstraction, every application would parse and format that text by hand.

The two interfaces solve that problem by turning the text into method calls. Reading `GET /greet?name=Alireza HTTP/1.1` becomes `req.getMethod()` and `req.getParameter("name")`. Writing a `200 OK` with a body becomes `resp.setStatus(200)` and `resp.getWriter().println(...)`. The container guarantees the bytes on the wire match what your code described.

## The request side: HttpServletRequest

Here is a request on the wire and the calls that read each part:

```
POST /search?lang=en HTTP/1.1
Host: localhost:8080
User-Agent: Mozilla/5.0
Content-Type: application/x-www-form-urlencoded

q=java+servlets
```

|Part of the request|Method on `HttpServletRequest`|Returns|
|---|---|---|
|Method|`getMethod()`|`"POST"`|
|Path|`getRequestURI()`|`"/search"`|
|Query string|`getQueryString()`|`"lang=en"`|
|Single query or form value|`getParameter("lang")`|`"en"`|
|Header|`getHeader("User-Agent")`|`"Mozilla/5.0"`|
|Cookies|`getCookies()`|`Cookie[]` or `null`|
|Client address|`getRemoteAddr()`|`"127.0.0.1"`|

Here is a servlet that reads most of these in one place:

```java
@WebServlet("/inspect")
public class InspectServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String lang = req.getParameter("lang");        // null if ?lang= is absent
        String agent = req.getHeader("User-Agent");    // null if header is absent
        String path = req.getRequestURI();              // path only, no query string
        String ip = req.getRemoteAddr();                // address of the client

        resp.setContentType("text/plain");
        resp.getWriter().println("Path:  " + path);
        resp.getWriter().println("Lang:  " + lang);
        resp.getWriter().println("Agent: " + agent);
        resp.getWriter().println("IP:    " + ip);
    }
}
```

Visiting `http://localhost:8080/inspect?lang=fr` in a browser would print the path, `fr`, your browser's User-Agent string, and `127.0.0.1`.

What each part does:

- `getParameter` reads from the query string for `GET` and from the body for `POST` with form encoding. It returns `null` when the parameter is missing, so always check for `null` before using the value.
- `getHeader` returns the first header with that name, or `null`. Header names are case-insensitive, so `"user-agent"` works too.
- `getRequestURI` returns only the path. The query string is separate, which is why `getQueryString` exists.
- `getRemoteAddr` returns the immediate peer's address. If your app sits behind a proxy, this will be the proxy's address, and the real client is usually in the `X-Forwarded-For` header. That is a common source of bugs in deployed systems.

Note on multiple values: a parameter can appear more than once, as in `?tag=a&tag=b`. `getParameter` returns only the first. Use `getParameterValues("tag")` to get all of them as a `String[]`.

## Reading the body

For a `GET` request, the body is normally empty. For `POST` and `PUT` with JSON, you read the raw body with `getReader()` or `getInputStream()`:

```java
@Override
protected void doPost(HttpServletRequest req, HttpServletResponse resp)
        throws IOException {

    String body = req.getReader().lines()
            .collect(java.util.stream.Collectors.joining("\n"));
    resp.setContentType("text/plain");
    resp.getWriter().println("You sent " + body.length() + " characters");
}
```

What this does: `getReader()` gives a stream of characters from the body, `lines()` turns it into a stream of lines, and `joining` puts them back together. The body is a stream that can be read only once. If a filter has already consumed it, your servlet receives nothing, which is a frequent surprise when logging request bodies.

## The response side: HttpServletResponse

The response is built in a fixed order, and the order matters:

1. **Status code** with `setStatus`, or `sendError` for error responses.
2. **Headers** with `setHeader`, `setContentType`, and `addCookie`.
3. **Body** through `getWriter()` for text or `getOutputStream()` for binary.

```java
@WebServlet("/product")
public class ProductServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String id = req.getParameter("id");

        if (id == null) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "id is required");
            return;                                          // stop here
        }

        resp.setStatus(HttpServletResponse.SC_OK);           // 200
        resp.setContentType("application/json");             // Content-Type header
        resp.setHeader("Cache-Control", "no-cache");         // any custom header
        resp.getWriter().println("{\"id\": \"" + id + "\"}");
    }
}
```

What each part does:

- `sendError(code, message)` produces an error page from the container. It commits the response, so later writes are ignored or cause an error. Always `return` after it.
- `setStatus` sets the code for a successful response. Use the named constants such as `SC_OK` and `SC_NOT_FOUND` rather than bare numbers, because they make intent clear.
- `setContentType` must come before `getWriter()`. The writer locks in the character encoding, so changing the content type afterward has no effect on the output.
- `setHeader` replaces an existing header with that name. Use `addHeader` if you want to add a second value under the same name.

Two rules to remember about the body. `getWriter()` and `getOutputStream()` are mutually exclusive, so you can use only one per response. And once the response is committed (after the buffer is flushed or `sendError` runs), the headers can no longer change.

## doGet: the method that receives them

`doGet` is the handler for `GET`. The base implementation in `HttpServlet` sends a 405 error, so a servlet that overrides nothing refuses every `GET`. Overriding `doGet` is how you say "this servlet answers `GET`."

Its signature has three important features:

- **Both objects are passed in.** You do not return a response. You write to `resp`, and the container sends it when your method returns.
- **It returns `void`.** Because the response is written to `resp` as a side effect, there is no return value.
- **It declares `ServletException` and `IOException`.** `IOException` comes from reading the body or writing to the client. `ServletException` is for failures the container wraps. Both are checked, so you either declare them or catch them.

Because `doGet` is called for `GET` only, the same URL can have separate handlers for each verb. That is the routing you saw in the previous answer.

## The same logic in Spring Boot

In Spring, you rarely write `doGet` yourself. Spring's `DispatcherServlet` calls your controller method, and it can give you the same objects if you ask:

```java
@RestController
public class ProductController {

    @GetMapping("/product")
    public ResponseEntity<String> product(
            HttpServletRequest req,
            HttpServletResponse resp,
            @RequestParam(required = false) String id) {

        if (id == null) {
            return ResponseEntity.badRequest().body("id is required");
        }
        return ResponseEntity.ok()
                .header("Cache-Control", "no-cache")
                .contentType(MediaType.APPLICATION_JSON)
                .body("{\"id\": \"" + id + "\"}");
    }
}
```

What this does: `@GetMapping("/product")` plays the role of `doGet` for that URL. `@RequestParam` replaces `getParameter`, and `ResponseEntity` replaces the status, header, and body calls. Spring builds the same response internally. `HttpServletRequest` and `HttpServletResponse` are present in the signature because you asked for them, but in most code you do not need them.

Use `ResponseEntity` in Spring code and keep the raw servlet objects for cases such as reading the client IP, setting a cookie directly, or working with a streamed download.

## Common mistakes

- **Forgetting `return` after `sendError`.** The method keeps running and tries to write a body into a committed response.
- **Calling `getWriter()` and then `getOutputStream()`.** This throws `IllegalStateException`.
- **Setting the content type after writing.** The change is silently ignored.
- **Trusting `getParameter` without a null check.** A missing parameter returns `null`, and using it in a string or a method call causes a `NullPointerException`.
- **Reading the body after a filter has already read it.** The second read returns nothing.




[[Servlet]]