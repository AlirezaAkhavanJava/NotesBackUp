

A Servlet is a Java component that runs inside a web server environment and handles HTTP requests and responses.

In simple words:

A Servlet receives an HTTP request, processes it, and produces an HTTP response.

Servlets are one of the fundamental technologies behind Java web applications, including Spring MVC and Spring Security.

When you create a Spring Boot REST API using `@RestController`, you usually don't write Servlets yourself. However, Spring MVC uses a Servlet internally to receive and dispatch incoming HTTP requests.

That Servlet is called `DispatcherServlet`.

## The problem it solves

Imagine you have a normal Java application:

```
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello World");
    }
}
```

- `Main` is a Java class.
    
- `main()` is the entry point of your application.
    
- `System.out.println()` prints text to the terminal.
    

This program runs, prints a message, and finishes.

Now imagine you want your Java application to act as a web application.

You want someone to open:

`http://localhost:8080/hello`

And receive:

`Hello World`

But there is a problem.

Your ordinary Java class does not automatically know how to:

- Listen for incoming HTTP connections.
    
- Read HTTP requests.
    
- Determine which code should handle each request.
    
- Generate HTTP responses.
    
- Handle multiple clients simultaneously.
    

You need infrastructure to connect HTTP communication with your Java code.

That is where Servlets and Servlet containers come in.

## Part 1 — The big picture

Think of a restaurant.

- The customer is the HTTP client.
    
- The waiter is the Servlet container.
    
- The kitchen is your application logic.
    
- The order is the HTTP request.
    
- The prepared food is the HTTP response.
    

The waiter receives the order and delivers it to the appropriate kitchen staff.

Similarly, a Servlet container receives HTTP requests and invokes the appropriate Servlet.

HTTP Client

Browser, Postman, curl

Servlet Container (Tomcat)

Receives HTTP and manages Servlet execution

Servlet

Processes the request

HTTP Response

Status, headers, body

The important distinction:

|Component|Responsibility|
|---|---|
|Web server|Handles network connections and HTTP communication|
|Servlet container|Manages Servlets, their lifecycle, and request execution|
|Servlet|Processes requests and generates responses|
|Spring MVC|Builds a higher-level web framework on top of the Servlet API|

A Servlet container such as Tomcat can also provide HTTP server functionality. These responsibilities can exist in the same software.

## Part 2 — What exactly is a Servlet?

Technically, a Servlet is a Java component that implements the `jakarta.servlet.Servlet` interface, either directly or through a base class.

The Jakarta Servlet API defines the contract between a Servlet and its container.

The central method is:

`service(ServletRequest request, ServletResponse response)`

When a request is mapped to a Servlet, the container calls its `service()` method.

For HTTP applications, Java provides the `HttpServlet` class, which makes working with HTTP easier.

It includes methods such as:

|Method|HTTP method|
|---|---|
|`doGet()`|GET|
|`doPost()`|POST|
|`doPut()`|PUT|
|`doDelete()`|DELETE|
|`doPatch()`|PATCH|
|`doHead()`|HEAD|
|`doOptions()`|OPTIONS|

You normally extend `HttpServlet` instead of implementing the low-level `Servlet` interface directly.

## Part 3 — Creating your first Servlet

Here is a simple Servlet:

```
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

@WebServlet("/hello")
public class HelloServlet extends HttpServlet {

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        response.setContentType("text/plain");
        response.getWriter().println("Hello from Servlet!");
    }
}
```

Line-by-line explanation:

- `@WebServlet("/hello")` declares a URL mapping for this Servlet. The container must have Servlet annotation discovery enabled for it to be registered this way.
    
- `extends HttpServlet` makes your class an HTTP Servlet.
    
- `@Override` indicates that you are overriding an inherited method.
    
- `doGet()` handles HTTP GET requests.
    
- `HttpServletRequest` provides information about the incoming request.
    
- `HttpServletResponse` lets you construct the response.
    
- `throws IOException` allows input/output errors to propagate.
    
- `setContentType("text/plain")` tells the client that the response contains plain text.
    
- `getWriter()` obtains a writer for the response body.
    
- `println()` writes the message to the response.
    

When someone sends:

`GET /hello`

The container invokes the Servlet's `doGet()` method, and the client receives:

`Hello from Servlet!`

Spring Boot note: `@WebServlet` is not automatically discovered in every embedded-container Spring Boot application. You can use `@ServletComponentScan` or register the Servlet through a `ServletRegistrationBean`.

## Part 4 — The Servlet lifecycle

Servlets have a lifecycle managed by the Servlet container.

A lifecycle describes the stages an object goes through from creation to destruction.

The three important Servlet lifecycle methods are:

|Method|When it runs|Purpose|
|---|---|---|
|`init()`|During Servlet initialization|Prepare resources|
|`service()`|For each request|Process requests|
|`destroy()`|When the Servlet is taken out of service|Release resources|

Here's the typical lifecycle:

1. Servlet instance created

Container creates the object

2. init()

Called once per instance

3. service()

Called for incoming requests

4. destroy()

Called during normal shutdown/removal

### An important detail: Servlets are generally shared

A Servlet container usually creates one instance of a Servlet per registration and handles many requests through that same instance.

Multiple threads may execute its `service()` method concurrently.

This means you must be careful with mutable instance variables.

For example, storing request-specific information in Servlet fields can create race conditions and leak information between users.

Use method-local variables for request-specific data.

## Part 5 — How a Servlet works internally

Suppose your browser requests:

`http://localhost:8080/api/users`

Here is what happens in a typical Spring Boot MVC application.

1. The browser establishes a connection to the server.
    
2. Tomcat receives and parses the HTTP request.
    
3. Tomcat creates or prepares Servlet request and response objects.
    
4. Tomcat invokes the applicable Servlet filter chain.
    
5. The filter chain eventually invokes Spring MVC's `DispatcherServlet`.
    
6. `DispatcherServlet` finds the appropriate controller handler.
    
7. Your controller executes and returns a result.
    
8. Spring MVC writes the result into the HTTP response.
    
9. Tomcat sends the response back to the client.
    

Browser

Tomcat

Servlet Filters

DispatcherServlet

Spring MVC Controller

Service / Repository

HTTP Response

This is why understanding Servlets is useful when learning Spring Security.

Spring Security's web security architecture for Spring MVC is built around Servlet filters.

## Part 6 — Servlet vs DispatcherServlet vs Controller

These three concepts are related but not interchangeable.

|Concept|What it is|Responsibility|
|---|---|---|
|Servlet|Jakarta web component|Handles requests and responses|
|`DispatcherServlet`|Spring MVC Servlet|Dispatches requests to handlers|
|`@RestController`|Spring MVC controller|Implements endpoint logic|

`DispatcherServlet` is a special Servlet provided by Spring MVC.

Instead of writing a separate Servlet for every endpoint, you write controller methods, and `DispatcherServlet` routes requests to them.

For example:

```
@RestController
@RequestMapping("/api")
public class UserController {

    @GetMapping("/users")
    public String users() {
        return "Users endpoint";
    }
}
```

- `@RestController` registers a controller whose return values are normally written to the HTTP response body.
    
- `@RequestMapping("/api")` sets a common URL prefix.
    
- `@GetMapping("/users")` maps GET requests to `/api/users`.
    
- `users()` is the handler method.
    
- The returned string becomes the response body.
    

You don't need to manually create `HttpServletRequest` and `HttpServletResponse` for simple controller methods because Spring MVC handles that infrastructure.

## Part 7 — Servlet Filters and Spring Security

A Servlet Filter is a component that can process a request before it reaches a Servlet and can also process the response on the way back.

A filter is not the same as a Servlet.

A Servlet is typically the destination that handles a request. A filter surrounds or intercepts request processing.

For example:

```
public class LoggingFilter implements Filter {

    @Override
    public void doFilter(
            ServletRequest request,
            ServletResponse response,
            FilterChain chain
    ) throws IOException, ServletException {

        System.out.println("Before Servlet");

        chain.doFilter(request, response);

        System.out.println("After Servlet");
    }
}
```

This example assumes the appropriate `jakarta.servlet` imports.

Line-by-line explanation:

- `implements Filter` declares a Servlet Filter.
    
- `doFilter()` is invoked when the filter participates in a request.
    
- `ServletRequest` contains incoming request information.
    
- `ServletResponse` represents the outgoing response.
    
- `FilterChain` provides access to the next filter or target Servlet.
    
- The first `println()` executes before downstream processing.
    
- `chain.doFilter()` continues the chain.
    
- The final `println()` executes after downstream processing returns normally.
    

The filter must be registered with the Servlet container before it can run.

Spring Security uses this same filter mechanism.

For example, `BasicAuthenticationFilter` examines the HTTP `Authorization` header and attempts authentication when appropriate.

## Part 8 — Try it yourself in Spring Boot

Let's register a real Servlet in your Spring Boot project.

For a Spring MVC application with an embedded Servlet container, create this class:

```
@Configuration
public class ServletConfig {

    @Bean
    ServletRegistrationBean<HttpServlet> helloServlet() {

        HttpServlet servlet = new HttpServlet() {
            @Override
            protected void doGet(
                    HttpServletRequest request,
                    HttpServletResponse response
            ) throws IOException {
                response.setContentType("text/plain");
                response.getWriter().write("Hello from raw Servlet!");
            }
        };

        return new ServletRegistrationBean<>(servlet, "/raw");
    }
}
```

Line-by-line explanation:

- `@Configuration` marks the class as Spring configuration.
    
- `@Bean` registers a Spring-managed object.
    
- `ServletRegistrationBean` registers a Servlet with the embedded container.
    
- `new HttpServlet()` creates an anonymous Servlet implementation.
    
- `doGet()` handles GET requests.
    
- `setContentType()` sets the response content type.
    
- `getWriter().write()` writes the response body.
    
- `"/raw"` maps the Servlet to that path.
    

This code requires the relevant Spring Boot and Jakarta Servlet imports.

Start the application, then run:

```
curl -i http://localhost:8080/raw
```

- `curl` makes an HTTP request.
    
- `-i` displays the response headers.
    
- `/raw` is the Servlet's URL mapping.
    

You should receive:

`Hello from raw Servlet!`

If Spring Security is enabled and protects `/raw`, you may need to authenticate first.

## Common mistakes

|Mistake|Why it hurts|How to fix|
|---|---|---|
|Thinking Tomcat and Servlet are identical|Confuses the runtime with application components|Tomcat hosts and manages Servlets|
|Thinking every controller is a Servlet|Misunderstands Spring MVC architecture|Controllers are invoked through `DispatcherServlet`|
|Storing request data in Servlet fields|Can cause concurrency bugs|Use local variables|
|Forgetting Servlet registration|Requests never reach the Servlet|Register with the container|
|Confusing Filters and Servlets|Makes request flow difficult to understand|Filters wrap processing; Servlets handle requests|
|Mixing `javax.servlet` and `jakarta.servlet`|Causes compatibility problems|Use Jakarta imports with Spring Boot 3+|

## Related concept, briefly — Jakarta Servlet API

The Jakarta Servlet API defines standard interfaces and classes for Java web applications.

Older Java applications used the `javax.servlet` package. Modern Spring Boot 3+ applications use `jakarta.servlet`.

The package change is important because older Servlet libraries are not directly compatible with modern Jakarta-based applications.

## The whole picture

|Question|Answer|
|---|---|
|What is a Servlet?|A Java component that processes requests and responses|
|Why does it exist?|To connect Java application code with web request handling|
|Who manages Servlets?|A Servlet container|
|What is Tomcat?|A web server and Servlet container|
|What is `HttpServlet`?|A base class for HTTP Servlets|
|What is `service()`?|The central request-processing method|
|What is `doGet()`?|A method for handling GET requests|
|What is `DispatcherServlet`?|Spring MVC's central request-dispatching Servlet|
|What is a Servlet Filter?|A component that intercepts request/response processing|
|How does Spring Security use Servlets?|It uses Servlet filters to secure web requests|





[[Spring Security]]