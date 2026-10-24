
# Servlet: The Foundation Under Spring Boot

## What a Servlet is

A **Servlet** is a Java class that receives an HTTP request and produces an HTTP response. It is defined by the **Jakarta Servlet specification**, which is a set of interfaces and rules. The core interface is `jakarta.servlet.Servlet`, with three lifecycle methods: `init()`, `service()`, and `destroy()`. In practice you almost always extend `HttpServlet`, which splits `service()` into methods named after HTTP verbs, such as `doGet()` and `doPost()`.

In Spring Boot 3 and later, the package is `jakarta.servlet`. Older tutorials use `javax.servlet`, which is the same API under the old name.

## Why it exists

HTTP is a text protocol sent over TCP. A request looks something like this on the wire:

```
GET /hello?name=Alireza HTTP/1.1
Host: localhost:8080
Accept: text/plain

```

Before standardization, every web application had to parse that text, manage threads to handle many clients at once, read cookies and form data, and write a correctly formatted response. Each server product did this differently, so an app written for one server often could not run on another.

The Servlet specification solved this by standardizing two things:

1. **The request and response objects.** Your code receives an `HttpServletRequest` with methods like `getParameter()` and `getHeader()`, and writes to an `HttpServletResponse`. You never touch raw text.
2. **The container contract.** A **servlet container** (such as Apache Tomcat, Jetty, or Undertow) is the program that listens on a port, parses incoming HTTP, and calls your servlets. Any compliant container can run any compliant servlet.

So the problem being solved is portability and separation: the server handles networking and threads, and your code handles application logic.

## How it works

Here is a basic servlet that responds to `GET /hello?name=...`:

```java
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/hello")
public class HelloServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        String name = request.getParameter("name");   // reads ?name=... from the URL
        response.setContentType("text/plain");        // sets the Content-Type header
        response.getWriter().write("Hello, " + name); // writes the response body
    }
}
```

What each part does:

- `@WebServlet("/hello")` tells the container to route requests for `/hello` to this class. (In Spring Boot, this annotation only works if you add `@ServletComponentScan` to your main class.)
- `extends HttpServlet` gives you the framework's dispatch logic. When a GET arrives, the base class's `service()` method calls `doGet()`.
- `doGet(...)` is your code. It receives a request object already parsed by the container and a response object you fill in.
- `getParameter("name")` returns the query string value, or `null` if it is absent.
- The response is only sent after the method returns, and the container handles the status line, headers, and framing.

The lifecycle works like this:

1. **`init()`** runs once, when the container first creates the servlet. This is where you open expensive resources such as a database connection pool.
2. **`service()`** runs once per request, usually on a separate worker thread. Tomcat keeps a pool of these threads. Your servlet instance is shared across all of them, so instance fields are a common source of concurrency bugs.
3. **`destroy()`** runs once, when the application shuts down.

## Why you see it constantly in Spring Boot

Spring Boot does not replace the Servlet layer. It builds on it. Three facts explain what you see.

**Fact 1: Spring Boot embeds a servlet container.** The `spring-boot-starter-web` dependency includes Tomcat. When you run `main()`, Spring Boot starts Tomcat inside your JVM, so there is no separate server to install. Tomcat is the thing listening on port 8080.

**Fact 2: Every request enters through one servlet.** Spring MVC registers a single servlet called `DispatcherServlet`, mapped to `/`, which means "all requests." It is the front controller. Your `@RestController` methods are not servlets. They are methods that `DispatcherServlet` calls after it decides which method matches the request.

The full path of a request looks like this:

```
Browser
  → Tomcat (parses HTTP, picks a worker thread)
  → Servlet Filters (your code, optional)
  → DispatcherServlet (the single Servlet Spring registers)
  → HandlerMapping (finds the method for GET /hello)
  → Your @GetMapping method
  → HttpMessageConverter (turns the return value into a body)
  → Tomcat writes the HTTP response
```

**Fact 3: Spring exposes the Servlet objects when you need them.** Spring hides them by default, but they remain available. You can ask for them directly in a controller:

```java
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/hello")
    public String hello(HttpServletRequest request) {
        String name = request.getParameter("name"); // the same API as the raw servlet
        return "Hello, " + name + " from " + request.getMethod();
    }
}
```

Spring passes in the same `HttpServletRequest` that Tomcat created. This is why you see `HttpServletRequest` and `HttpServletResponse` in controller signatures, and why `HttpServlet` names appear in stack traces.

Here is the same endpoint written the idiomatic Spring way, where Spring does the parameter extraction for you:

```java
@RestController
public class HelloController {

    @GetMapping("/hello")
    public String hello(@RequestParam String name) {
        return "Hello, " + name;
    }
}
```

What this example does: `@RequestParam` tells Spring to read `name` from the query string and convert it to a `String`. Spring still uses the Servlet request internally. You simply no longer touch it.

## A Servlet-level Filter, which you will meet next

Filters are part of the same specification. A `Filter` wraps the servlet chain, so it runs before and after `DispatcherServlet`:

```java
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Component;
import java.io.IOException;

@Component
public class RequestLoggingFilter implements Filter {

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest http = (HttpServletRequest) req;
        System.out.println("Incoming: " + http.getMethod() + " " + http.getRequestURI());

        chain.doFilter(req, res); // pass control to the next filter, eventually DispatcherServlet
    }
}
```

What this example does: it logs every request before passing it along. Calling `chain.doFilter()` is essential. If you forget it, the request stops here and never reaches your controller.

## How you will use this in practice

For day-to-day work, you will write `@RestController` classes and rarely touch Servlet types directly. You will reach for `HttpServletRequest` when you need headers, cookies, or the client IP. You will write a `Filter` (or Spring Security's filter chain) for cross-cutting concerns such as authentication, request logging, or correlation IDs.

When you read a stack trace and see `org.apache.catalina` or `DispatcherServlet.doDispatch`, you now know the request had already passed through Tomcat and into Spring MVC when the error occurred. That tells you where to look.




[[Java]]
[[Spring Framework]]