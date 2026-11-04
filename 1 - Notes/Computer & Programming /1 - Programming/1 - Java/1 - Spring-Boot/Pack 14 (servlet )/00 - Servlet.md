

# Servlet in Java and Spring Boot

A **Servlet** is a Java class that receives an HTTP request and produces an HTTP response. It is defined by the **Jakarta Servlet specification**, which is a set of interfaces and rules. The core interface is `jakarta.servlet.Servlet`, with three lifecycle methods: `init()`, `service()`, and `destroy()`. In practice you almost always extend `HttpServlet`, which splits `service()` into methods named after HTTP verbs, such as `doGet()` and `doPost()`.


## 1. The Problem It Solves

Imagine you have written a Java application that manages users.

``` java
public class UserService {

    public String getUsername() {
        return "Alireza";
    }
}
```

This works inside Java, but what if someone opens their browser and visits:

```
http://localhost:8080/users
```

How can the browser communicate with your Java application?

We need something that can:

1. Receive an HTTP request.
    
2. Read information from that request.
    
3. Execute Java code.
    
4. Generate an HTTP response.
    
5. Send the response back to the client.
    

This is one of the main problems Servlets solve.

> Definition: A Servlet is a Java component managed by a Servlet container that receives and processes requests and generates responses. In web applications, servlets commonly handle HTTP requests and responses.

In simple words: A Servlet is a Java object that can receive an HTTP request, execute Java code, and produce an HTTP response.

## 2. Where Does a Servlet Fit?

A Servlet does not independently listen for connections on a network port.

It needs a Servlet container, such as Apache Tomcat.

```
Client (Browser / Postman)
          |
          | HTTP Request
          v
Tomcat (Servlet Container)
          |
          v
      Your Servlet
          |
          v
 Java Application Logic
          |
          v
      HTTP Response
```

Here is what happens:

1. The browser sends an HTTP request to Tomcat.
    
2. Tomcat accepts the connection and parses the HTTP request.
    
3. Tomcat finds the servlet responsible for the requested URL.
    
4. Tomcat calls the servlet.
    
5. The servlet executes Java code to process the request.
    
6. Tomcat sends the generated response back to the client.
    

The Servlet is responsible for application-level request processing, while Tomcat provides the infrastructure needed to run it.

## 3. What Does a Servlet Look Like in Java?

Let's create a simple Servlet without using Spring MVC.

```java
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

> you need to add ***@ServletComponentScan*** on the top of spring-boot application
### @WebServlet("/hello")

This annotation declares the servlet and maps it to a URL:

```
GET /hello
```

The servlet container discovers and registers annotated servlets when annotation scanning is enabled.

### extends HttpServlet

`HttpServlet` is a class from the Jakarta Servlet API.

It provides HTTP-specific behavior, including methods for handling different HTTP methods.

|HTTP Method|Servlet Method|
|---|---|
|GET|`doGet()`|
|POST|`doPost()`|
|PUT|`doPut()`|
|DELETE|`doDelete()`|
|HEAD|`doHead()`|

When Tomcat receives a GET request matching this servlet's mapping, it invokes its `service()` method, which dispatches the request to `doGet()`.

### HttpServletRequest request

This object represents the incoming HTTP request.

```java
request.getMethod();
request.getRequestURI();
request.getHeader("User-Agent");
request.getParameter("name");
```

### HttpServletResponse response

This object allows us to construct the HTTP response.

```java
response.setStatus(200);
response.setContentType("text/plain");
response.getWriter().println("Hello!");
```

## 4. Servlet Lifecycle

Servlets are managed by the servlet container.

They have three important lifecycle methods:

```
       init()
          |
          v
      service()
          |
          v
      destroy()
```

### 1. init()

Called once when the servlet is initialized.

```java
@Override
public void init() {
    System.out.println("Servlet initialized!");
}
```

### 2. service()

Called for each incoming request to the servlet.

For an `HttpServlet`, the inherited `service()` implementation dispatches requests to methods such as `doGet()` and `doPost()`.

A servlet instance typically serves multiple requests, potentially concurrently on different threads.

### 3. destroy()

Called when the servlet is being taken out of service.

```java
@Override
public void destroy() {
    System.out.println("Servlet destroyed!");
}
```

Important: A new servlet object is not normally created for every HTTP request. The container generally reuses a servlet instance.

Because multiple threads may execute servlet methods concurrently, avoid storing request-specific information in servlet instance fields.

## 5. How Are Servlets Related to Spring Boot?

You have already worked with Spring Boot REST controllers:

```java
@RestController
@RequestMapping("/users")
public class UserController {

    @GetMapping
    public String getUsers() {
        return "List of users";
    }
}
```

You might think Spring Boot handles HTTP requests directly without servlets.

But in a typical Spring Boot application using Spring MVC, Spring MVC itself is built on the Servlet API.

Instead of requiring you to write an `HttpServlet` for each endpoint, Spring MVC uses a central servlet called `DispatcherServlet`.

### Without Spring MVC

```json
HTTP Request
    |
    v
Tomcat
    |
    v
Your HttpServlet
    |
    v
Your Java Code
    |
    v
HTTP Response
```

### With Spring MVC

```
HTTP Request
    |
    v
Tomcat
    |
    v
DispatcherServlet
    |
    v
Spring MVC Handler Mapping
    |
    v
@RestController
    |
    v
@Service
    |
    v
@Repository
```

The response then travels back through Spring MVC and Tomcat to the client.

The `DispatcherServlet` is itself a servlet, but it delegates application logic to Spring-managed controllers and other components.

This is why you normally do not write servlets manually when developing Spring Boot REST APIs.

Spring MVC handles much of the servlet-level infrastructure for you.

## 6. Servlet vs DispatcherServlet vs Controller

|Concept|Responsibility|
|---|---|
|Servlet|Processes requests and produces responses|
|`HttpServlet`|Base class for HTTP-based servlets|
|`DispatcherServlet`|Spring MVC's central front controller servlet|
|`@RestController`|Spring component containing request handler methods|
|Tomcat|Hosts servlets and manages their lifecycle|

Important: A Spring `@RestController` is not itself a Servlet.

Your controller is a Spring-managed bean whose methods are invoked through Spring MVC's request-handling infrastructure.

## 7. Servlet vs ServletContext

|Servlet|ServletContext|
|---|---|
|Processes requests|Represents the web application's shared environment|
|Managed by the container|Managed by the container|
|Can have multiple servlets per application|Usually one per web application|
|Has `init()`, `service()`, `destroy()`|Has an application-wide lifecycle|
|Can access `ServletContext`|Can be accessed by servlets|

For example:

```
ServletContext context = getServletContext();
```

This is how a servlet can obtain the shared context of its web application.

## 8. Common Mistakes

### Mistake 1: Thinking Tomcat and Servlet Are the Same

Tomcat is a servlet container. A servlet is a component running inside that container.

### Mistake 2: Thinking Each HTTP Request Creates a New Servlet

Usually, the container reuses an existing servlet instance.

### Mistake 3: Thinking @RestController Is a Servlet

A REST controller is a Spring bean. `DispatcherServlet` is the servlet that coordinates invoking controllers.

### Mistake 4: Thinking Servlets Only Support REST APIs

Servlets can also support server-rendered web applications, file downloads, HTML responses, and many other HTTP operations.

### Mistake 5: Thinking Every Spring Boot Application Needs Servlets

Spring Boot can build non-web applications too. Spring WebFlux can also run on non-servlet runtimes such as Reactor Netty.

## 9. The Whole Picture

|Component|Job|
|---|---|
|HTTP|Communication protocol between client and server|
|Tomcat|Accepts HTTP requests and runs servlets|
|Servlet|Processes requests within a servlet container|
|`HttpServletRequest`|Represents incoming HTTP request data|
|`HttpServletResponse`|Used to generate an HTTP response|
|ServletContext|Shared application-wide servlet environment|
|DispatcherServlet|Connects servlet request processing to Spring MVC|
|ApplicationContext|Manages Spring beans and dependencies|
|`@RestController`|Defines Spring MVC request handlers|

### Final Mental Model

A Servlet is a Java component for processing web requests. Tomcat runs and manages servlets. Spring MVC builds on this foundation by using `DispatcherServlet`, which receives requests and forwards them to your Spring controllers.

So when you write:

```
@GetMapping("/hello")
public String hello() {
    return "Hello!";
}
```

You are using a higher-level abstraction built on top of servlet technology.

You don't have to manually parse the HTTP request or dispatch it to the correct handler because Spring MVC performs those tasks for you.




[[Servlet]]