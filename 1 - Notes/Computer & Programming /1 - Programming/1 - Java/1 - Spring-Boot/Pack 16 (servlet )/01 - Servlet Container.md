


## 1. The problem it solves

You already know that a Servlet is a Java component that processes HTTP requests and generates HTTP responses.

For example:

```
@WebServlet("/hello")
public class HelloServlet extends HttpServlet {

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        response.getWriter().println("Hello World!");
    }
}
```

But there is a problem.

This servlet cannot independently:

- Open and manage a network port.
    
- Accept HTTP connections from browsers.
    
- Parse incoming HTTP requests.
    
- Create `HttpServletRequest` and `HttpServletResponse` objects.
    
- Manage its own lifecycle automatically.
    
- Determine which servlet should handle a particular URL.
    
- Manage multiple incoming requests and threads.
    

Something must provide these capabilities.

That is the job of a Servlet Container.

> Definition: A Servlet Container is a runtime environment that implements the Jakarta Servlet specification and is responsible for loading, initializing, executing, and managing Servlets.

In simple words:

A Servlet Container is the environment that runs Servlets and manages everything they need to process web requests.

One popular example is Apache Tomcat.

## 2. How does a Servlet Container work?

Imagine that you start a Spring Boot application using embedded Tomcat.

When a browser sends an HTTP request, the following process takes place:

```
                 CLIENT
             (Web Browser)
                    |
                    | HTTP Request
                    v
        +------------------------+
        |      APACHE TOMCAT     |
        |   (Servlet Container)  |
        |                        |
        |  1. Accept connection  |
        |  2. Parse HTTP request |
        |  3. Locate Servlet     |
        |  4. Execute Servlet    |
        |  5. Return response    |
        +------------+-----------+
                     |
                     v
              +-------------+
              |   Servlet   |
              |             |
              |   doGet()   |
              |   doPost()  |
              +-------------+
```

Let's break it down.

### Step 1 — The Servlet Container starts

Tomcat starts an HTTP connector, typically listening on port `8080` in a default Spring Boot configuration.

```
http://localhost:8080
```

It prepares the environment for receiving HTTP requests.

### Step 2 — The client sends a request

For example:

```
GET /hello HTTP/1.1
Host: localhost:8080
```

Tomcat receives the request.

### Step 3 — The container creates request and response objects

Tomcat prepares objects implementing:

```
HttpServletRequest
HttpServletResponse
```

These objects allow the Servlet to read the request and construct the response.

### Step 4 — The container finds the correct Servlet

For example, if we have:

```
@WebServlet("/hello")
```

Tomcat can map a request for `/hello` to that servlet.

### Step 5 — The container invokes the Servlet

Tomcat calls the Servlet's `service()` method.

For an `HttpServlet`, this method dispatches the request to the appropriate HTTP method handler, such as:

```
doGet();
doPost();
doPut();
doDelete();
```

### Step 6 — The container sends the response

After the Servlet finishes processing, Tomcat handles transmitting the HTTP response back to the client.

## 3. Responsibilities of a Servlet Container

A Servlet Container does much more than execute Servlet methods.

|Responsibility|Explanation|
|---|---|
|Servlet lifecycle|Creates, initializes, and destroys Servlets|
|Request processing|Handles incoming requests and outgoing responses|
|URL mapping|Determines which Servlet handles a URL|
|Multithreading|Manages execution of concurrent requests|
|Session management|Supports HTTP sessions using `HttpSession`|
|ServletContext|Provides application-wide Servlet context|
|Filters|Executes Servlet Filters through a FilterChain|
|Security integration|Provides container-managed security capabilities|
|Resource management|Makes web application resources available|

An important detail about multithreading:

The container usually does not create a new Servlet for every request.

Instead, multiple request-processing threads may call the same Servlet instance concurrently.

That is why thread safety matters when writing Servlets.

## 4. Servlet lifecycle and the container

Remember the three important Servlet lifecycle methods:

```
init()
service()
destroy()
```

Who calls these methods?

The Servlet Container.

```
          Tomcat starts
                |
                v
      Creates Servlet object
                |
                v
             init()
                |
                v
     +---------------------+
     |     service()       |
     |                     |
     | Processes requests  |
     | multiple times      |
     +---------------------+
                |
                v
            destroy()
                |
                v
     Servlet taken out
         of service
```

For example:

```
@WebServlet("/example")
public class ExampleServlet extends HttpServlet {

    @Override
    public void init() {
        System.out.println("Servlet initialized");
    }

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        response.getWriter().println("Hello!");
    }

    @Override
    public void destroy() {
        System.out.println("Servlet destroyed");
    }
}
```

Tomcat manages the lifecycle of this servlet.

You don't normally need to construct or initialize it manually.

## 5. Popular Servlet Containers

There are several implementations of the Jakarta Servlet specification.

|Servlet Container|Description|
|---|---|
|Apache Tomcat|Popular Servlet Container and HTTP server|
|Eclipse Jetty|Lightweight HTTP server and Servlet Container|
|Undertow|Web server that supports Servlet applications|

These implementations provide the infrastructure required to run Servlet-based applications.

One important distinction:

The Jakarta Servlet API defines the contract, while a Servlet Container implements that contract.

For example:

```
import jakarta.servlet.http.HttpServlet;
```

`HttpServlet` is part of the Servlet API.

Tomcat provides the runtime implementation needed to execute Servlet applications.

## 6. Servlet Container in Spring Boot

This is where everything connects to what you have already learned.

When you create a Spring Boot project using `spring-boot-starter-web`, Spring Boot typically configures an embedded Tomcat server.

You do not need to download Tomcat separately.

For a typical Spring MVC application, the architecture looks like this:

```
           HTTP Request
                 |
                 v
       +-------------------+
       |   Apache Tomcat   |
       | Servlet Container |
       +---------+---------+
                 |
                 v
       +-------------------+
       |  Servlet Filters  |
       +---------+---------+
                 |
                 v
       +-------------------+
       | DispatcherServlet |
       +---------+---------+
                 |
                 v
       +-------------------+
       |   @RestController |
       +---------+---------+
                 |
                 v
       +-------------------+
       |     @Service      |
       +---------+---------+
                 |
                 v
       +-------------------+
       |    @Repository    |
       +-------------------+
```

Remember:

- Tomcat is the Servlet Container.
    
- DispatcherServlet is Spring MVC's main Servlet.
    
- Controller is a Spring-managed bean.
    
- Service contains business logic.
    
- Repository handles persistence.
    

When a request reaches Tomcat, it passes through the appropriate Servlet Filters and then reaches `DispatcherServlet`, which coordinates Spring MVC request handling.

For example:

```
@RestController
@RequestMapping("/api/users")
public class UserController {

    @GetMapping
    public String getUsers() {
        return "Users";
    }
}
```

You did not create an `HttpServlet`.

But Spring MVC's `DispatcherServlet` is still involved in handling that request.

Spring Boot does not replace the Servlet Container. It configures and integrates it for you.

## 7. Embedded vs external Servlet Containers

There are two common approaches to deploying Servlet-based Java applications.

### External Servlet Container

Traditionally, you might:

1. Install Tomcat separately.
    
2. Package your application as a WAR file.
    
3. Deploy the WAR to Tomcat.
    
4. Let Tomcat run your application.
    

```
        External Tomcat
              |
              v
          myapp.war
              |
              v
         Application
```

### Embedded Servlet Container

Spring Boot popularized embedding a Servlet Container directly inside the application.

```
       Spring Boot Application
                 |
          Embedded Tomcat
                 |
          DispatcherServlet
                 |
             Controllers
```

You can package the application as an executable JAR:

```
./mvnw package
```

Then run it:

```
java -jar target/myapp.jar
```

The application starts its embedded server automatically.

You don't need a separately installed Tomcat instance.

## 8. Servlet vs Servlet Container vs ServletContext

These three concepts have different responsibilities.

|Concept|What it is|Main job|
|---|---|---|
|Servlet|Java component|Processes requests and generates responses|
|Servlet Container|Runtime environment|Executes and manages Servlets|
|ServletContext|Application-wide context|Provides shared application information and resources|

Think of them like this:

Servlet: "I process HTTP requests."

Servlet Container: "I run and manage Servlets."

ServletContext: "I provide shared information and resources for this web application."

## 9. Servlet Container vs Spring ApplicationContext

Because you're learning Spring IoC and dependency injection, it's important to distinguish these concepts.

|Servlet Container|Spring ApplicationContext|
|---|---|
|Implements Jakarta Servlet infrastructure|Implements Spring's IoC container|
|Manages Servlet lifecycle|Manages Spring bean lifecycle|
|Handles Servlet request processing|Manages dependencies and application components|
|Example: Tomcat|Example: `AnnotationConfigApplicationContext`|
|Supports web application execution|Supports web and non-web applications|

They are separate systems that work together in a Spring Boot MVC application.

For example:

```
@Service
public class UserService {
}
```

Spring manages this bean through its `ApplicationContext`.

Meanwhile:

```
@WebServlet("/hello")
public class HelloServlet extends HttpServlet {
}
```

The Servlet Container manages this Servlet when it has been registered with the container.

## 10. Common mistakes

### Mistake 1 — Thinking Servlet and Servlet Container are the same

They are different.

A Servlet is a Java component. A Servlet Container is the environment running it.

### Mistake 2 — Thinking Tomcat is Spring

Tomcat and Spring are separate technologies.

Tomcat implements Servlet infrastructure.

Spring provides a comprehensive application framework, including Spring MVC, dependency injection, and data access.

### Mistake 3 — Thinking every request creates a new Servlet

Servlet instances are usually reused.

The container manages concurrent requests, and multiple threads may execute the same Servlet instance.

### Mistake 4 — Thinking Spring Boot applications always need Tomcat

Spring Boot supports different server configurations, and non-web applications need no Servlet Container.

Reactive applications using Spring WebFlux can run without a Servlet Container, for example on Reactor Netty.

## 11. The whole picture

|Component|Responsibility|
|---|---|
|HTTP|Protocol used for communication|
|Tomcat|HTTP server and Servlet Container|
|Servlet|Processes web requests|
|`HttpServlet`|HTTP-specific Servlet base class|
|ServletContext|Shared application environment|
|DispatcherServlet|Spring MVC's front controller Servlet|
|ApplicationContext|Spring's IoC container|
|`@RestController`|Handles mapped HTTP endpoints|
|`@Service`|Contains application business logic|
|`@Repository`|Provides persistence operations|

### Final mental model

A Servlet Container is the runtime environment responsible for running Servlets.

When you start a typical Spring Boot MVC application:

1. Spring Boot starts and configures embedded Tomcat.
    
2. Tomcat provides the Servlet runtime.
    
3. Spring MVC registers and configures `DispatcherServlet`.
    
4. Tomcat receives HTTP requests.
    
5. Servlet Filters process requests where applicable.
    
6. `DispatcherServlet` finds the appropriate Spring controller.
    
7. The controller executes application logic.
    
8. The response returns through the framework and Tomcat to the client.
    

The key relationship is: Servlet Container runs Servlets, and Spring MVC uses a Servlet called `DispatcherServlet` to connect HTTP requests to your controllers.

### What to learn next

1. DispatcherServlet — How Spring MVC actually finds your controller and invokes the correct method.
    
2. Servlet Filter and FilterChain — How Spring Security and other infrastructure intercept HTTP requests before they reach your controllers.

[[Servlet]]