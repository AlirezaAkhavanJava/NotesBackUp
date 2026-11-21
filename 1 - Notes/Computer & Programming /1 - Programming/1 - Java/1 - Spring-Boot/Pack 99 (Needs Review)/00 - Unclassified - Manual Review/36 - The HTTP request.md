

## What's actually happening when your browser talks to your server

![[e8a7c378-f1e1-4a4d-bc2b-5fa4746b2ce8.png]]

The browser and your Spring Boot app don't share any Java-specific contract at all. They agree on something much lower-level and language-neutral: **HTTP**, which is just a text-based protocol sent over a plain TCP connection. Nothing object-oriented about it — it's bytes on a wire, formatted in a very specific but language-agnostic way. Your Java app, a Python app, a Node app, a C app — they all receive the _exact same bytes_ for the same request. What differs is what each one does with those bytes once they arrive.


![[4b877983-0a31-4666-a0b3-6be7bdb26c29.png]]


### The actual shape of an HTTP request

If you captured the raw bytes your browser sends when it hits `GET /users/5`, you'd see something like this — plain text, not a Java object, not JSON unless the body happens to be JSON:

```
GET /users/5 HTTP/1.1
Host: myserver.com
User-Agent: Mozilla/5.0
Accept: application/json
Connection: keep-alive

```

And for a POST with a body:

```
POST /users HTTP/1.1
Host: myserver.com
Content-Type: application/json
Content-Length: 27

{"name":"ethan","age":30}
```

Four parts, always in this order:

1. **Request line** — method, path, HTTP version (`GET /users/5 HTTP/1.1`)
2. **Headers** — key-value metadata lines
3. **Blank line** — marks the end of headers
4. **Body** — optional, present on POST/PUT/PATCH typically

This whole thing travels as one chunk of text over a TCP socket connection that the browser opened to your server's IP and port (443 for HTTPS, which just wraps this same text in TLS encryption before sending it).

### Where the "Java object" actually comes from

The request itself is never a Java object — it's text on a socket. The Java object only exists _after_ something on your server reads that text and builds one from it.

In a Spring Boot app, here's the chain:

1. **Embedded Tomcat** (or Jetty/Undertow) accepts the raw TCP connection and reads the raw HTTP text off the socket.
2. Tomcat, acting as a **Servlet container**, parses that text and constructs an `HttpServletRequest` object — _this_ is the first Java object in the picture. It has methods like `getMethod()`, `getHeader()`, `getInputStream()` that just expose the parsed text.
3. Spring's `DispatcherServlet` takes that `HttpServletRequest`, looks at the path and method, and figures out which `@Controller` method should handle it.
4. If your method has `@RequestBody MyDto dto`, Spring uses a `HttpMessageConverter` (Jackson, usually) to deserialize the JSON _body text_ into your `MyDto` Java object.

So the Java object is several layers removed from what crossed the network. The network only ever saw text.

### What happens with a Python server instead

Swap Tomcat for, say, a Python WSGI server (Gunicorn running Flask or Django). The browser sends the _identical_ raw HTTP text — it has no idea or care what's listening on the other end. The difference is entirely on the receiving side:

- Gunicorn reads the same raw bytes off the socket.
- It parses them into a Python `environ` dict (WSGI's version of `HttpServletRequest`) — keys like `REQUEST_METHOD`, `PATH_INFO`, `wsgi.input`.
- Flask/Django wrap that dict in their own `Request` object (`flask.Request`, `django.http.HttpRequest`).
- If the body is JSON, Flask parses it into a Python `dict`, not a typed object, unless you're using something like Pydantic to deserialize into a class instance.

Same bytes in, completely different internal representation, because "Java object" vs "Python dict" is a decision made by the framework author, not by HTTP.

### Does the browser know the server's language?

No — and this is the actual point of HTTP existing as a standard. The browser's contract is only with the _protocol_, never with the implementation behind it. It doesn't send different bytes for a Java backend vs a Python backend vs a PHP backend. It just:

1. Opens a TCP connection to the host/port from the URL.
2. Writes a correctly formatted HTTP request (as text) onto that socket.
3. Reads back whatever comes — which is also just text in the same style (a status line, headers, blank line, body):

```
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 45

{"id":5,"name":"ethan"}
```

The browser parses _that_ response the same way regardless of what produced it. This is exactly why you can swap Tomcat for Nginx, or rewrite your backend from Spring Boot to Django, and no browser configuration anywhere needs to change — the language behind the server is invisible at the protocol level. It only becomes visible in response headers if the server chooses to advertise it (e.g. a `Server: Apache Tomcat/10.1` header), but that's optional metadata, not something HTTP requires.



[[Networking]]
[[Spring Framework]]