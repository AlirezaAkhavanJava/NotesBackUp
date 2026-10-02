

*OAuth 2.0* which stands for “Open Authorization”, is a standard designed to allow a website or application to access resources hosted by other web apps on behalf of a user. It replaced OAuth 1.0 in 2012 and is now the de facto industry standard for online authorization. OAuth 2.0 provides consented access and restricts actions of what the client app can perform on resources on behalf of the user, without ever sharing the user's credentials.

Although the web is the main platform for OAuth 2, the specification also describes how to handle this kind of delegated access to other client types (browser-based applications, server-side web applications, native/mobile apps, connected devices, etc.)

> OAuth 2.0 is an authorization protocol and NOT an authentication protocol. As such, it is designed primarily as a means of granting access to a set of resources, for example, remote APIs or user data.

---
### Authentication and Authorization

Authentication is verifying the true identity of a user or entity, while authorization determines what a user can access and ensures that a user or entity receives the right access or permissions in a system.

![[Pasted image 20251215115414.png]]


---

### What is an Access Token ? 

OAuth 2.0 uses Access Tokens. An *Access Token* is a piece of data that represents the *authorization* to access resources on behalf of the end-user. OAuth 2.0 doesn’t define a specific format for Access Tokens. However, in some contexts, the JSON Web Token (JWT) format is often used. This enables token issuers to include data in the token itself. Also, for security reasons, Access Tokens may have an expiration date.


#### TIP : OAuth 2.0 is an authorization protocol and NOT an authentication protocol


- JWT (JSON Web Token) is a *token format*, not a protocol.
    
- *OAuth 2.0* is an *authorization framework*, not a token format.
    
- *OAuth 2.0 can use JWT*, but it does not require JWT*.
    

> JWT is one possible format of an access token that OAuth 2.0 can use.

### In Spring Security

- Spring Security OAuth2 Resource Server commonly uses JWT access tokens
    
- But OAuth2 access tokens can also be:
    
    - *Opaque tokens* (random strings, validated via introspection)
        
    - *Reference tokens*
        

### JWT vs OAuth2 (clear separation)

|Concept|What it is|
|---|---|
|OAuth2|Authorization framework|
|Access Token|Credential issued by OAuth2|
|JWT|Self-contained token format|
|Spring Security|Implementation that supports both|

---

## Spring Security 

Spring Security is a powerful and highly customizable security framework for building secure applications in the Java ecosystem, particularly within the Spring Framework. Spring Security framework also *handles the most common security vulnerabilities like CSRF, CORS* etc. So for any security vulnerabilities that are identified in the market on day to day basis, the spring security team they’re going to patch or update the framework immediately. Using spring security we can secure our pages/API paths, method level security etch with minimum configurations easily. Also Spring security supports various standards of security to implement authentication like username/password authentication by default, JWT tokens, OAuth2 etc.

Before getting to spring security internal flow lets go through typical scenario inside a web application. So any java web application accepts request and sends response through HTTP protocol because browsers can only understand HTTP protocols. 

But the java code cannot understand those HTTP protocol requests there is need of someone in the middle who can *convert the received HTTP message into an HTTP solid request object*, this middle man is called *servlets* or web servers like Apache Tomcat but because of its complex nature no one uses them directly. So to make the job easy Springboot came into picture which creates servlets internally and handles complex logic related to servlets on its own.


---

### Servlets

![[Pasted image 20251222104605.png]]

Java Servlet is a Java program that runs on a Java-enabled web server or application server. It handles client requests, processes them and generates responses dynamically. Servlets are the backbone of many server-side Java applications due to their efficiency and scalability.

### Features of Java Servlets

- Work on the server-side.
- Efficiently handle complex client requests.
- Generate dynamic responses.
- Provide better performance compared to older technologies like CGI.
- Highly scalable in enterprise-level web applications.

#### Java Servlets Architecture

Java servlets container play a very important role. It is responsible for handling important tasks like load balancing, session management and resource allocation, it make sure that all the requests are process efficiently under high traffic. The container distribute requests across multiple instances, which helps improve the system performance.

![[Pasted image 20251215120621.png]]

### Servlet Architecture Workflow:

Execution of Servlets basically involves Six basic steps: 

- The Clients send the request to the Web Server.
- The Web Server receives the request.
- The Web Server passes the request to the corresponding servlet.
- The Servlet processes the request and generates the response in the form of output.
- The Servlet sends the response back to the webserver.
- The Web Server sends the response back to the client and the client browser displays it on the screen.

---

### DispatcherServlet

> DispatcherServlet _is_ a servlet.  
Specifically, it’s a specialized HTTP servlet.

### Precise breakdown

- `DispatcherServlet` extends `HttpServlet`
    
- It is part of Spring MVC
    
- It acts as the *Front Controller* (one servlet handling all incoming requests)
    

### Why it exists

Instead of many servlets:

- One **DispatcherServlet**
    
- Routes requests to:
    
    - Controllers (`@Controller`, `@RestController`)
        
    - Handler methods
        
    - Views / Response bodies
        

### Position in the servlet model

```
Client
  ↓
Servlet Container (Tomcat)
  ↓
DispatcherServlet  
  ↓
Controllers
```

### Key truth

- It runs **inside** a servlet container (Tomcat, Jetty, etc.)
    
- It obeys the **Servlet API lifecycle**
    
- Spring just adds intelligence on top
    

### `HttpServlet` — straight facts

**Definition**

- `HttpServlet` is an **abstract class** in the **Java Servlet API**
    
- Package: `jakarta.servlet.http`
    
- It is the **base class for HTTP-based servlets**
    

**Inheritance**

```
Object
  ↳ GenericServlet
      ↳ HttpServlet
          ↳ YourServlet / DispatcherServlet
```

**What it does**

- Handles **HTTP protocol specifics**
    
- Dispatches requests to methods based on HTTP verb:
    
    - `doGet()`
        
    - `doPost()`
        
    - `doPut()`
        
    - `doDelete()`
        
    - `doPatch()`
        
    - `doHead()`
        
    - `doOptions()`
        

**Lifecycle (managed by container)**

1. `init()`
    
2. `service()` ← calls the right `doXxx()`
    
3. `destroy()`
    

**Example**

```java
public class MyServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req,
                         HttpServletResponse resp) throws IOException {
        resp.getWriter().write("Hello");
    }
}
```

**Important truth**

- You **never call** `doGet()` yourself
    
- The **servlet container** (Tomcat) does
    

**Relation to Spring**

- `DispatcherServlet` **extends `HttpServlet`**
    
- Spring MVC builds on top of it, not around it
    
---

### Overview of Spring Boot Web Workflow

Spring Boot simplifies web application development by using an embedded web server(default: Tomcat, alternatives: Jetty or Undertow) and auto-configuring Spring MVC components. Unlike traditional Spring MVC apps (which require manual configuration in `web.xml`), Spring Boot handles most setup automatically via the `spring-boot-starter-web` dependency.

The key players are:
- Embedded Web Server: Starts with the application, listens on a port (default 8080), accepts HTTP connections, and delegates requests to registered servlets.
- DispatcherServlet The central front controller in Spring MVC. It receives all application requests, routes them to appropriate handlers (e.g., `@Controller` methods), processes the response, and sends it back.

### Application Startup Workflow

1. Spring Boot application starts (via `@SpringBootApplication` and `SpringApplication.run()`).
2. Auto-configuration detects `spring-webmvc` on the classpath.
3. An embedded server (e.g., Tomcat) is created and started.
4. `DispatcherServletAutoConfiguration` registers a `DispatcherServlet` bean.
5. The `DispatcherServlet` is registered with the embedded server, mapped to "/" (handles all requests by default).
6. The servlet initializes its own `WebApplicationContext`, loading beans like controllers, handler mappings, view resolvers, etc.

At this point, the server is ready to accept requests.

### Request Processing Workflow

When an HTTP request arrives:

1. The embedded web server (e.g., Tomcat) accepts the connection and parses the HTTP request.
2. It delegates the request to the registered DispatcherServlet (as it's the only/main servlet handling app paths).
3. The DispatcherServlet acts as the front controller and orchestrates processing:
   - Uses HandlerMapping (e.g., `RequestMappingHandlerMapping`) to find the appropriate handler (usually a `@Controller` method based on `@RequestMapping`, `@GetMapping`, etc.).
   - Uses HandlerAdapter (e.g., `RequestMappingHandlerAdapter`) to invoke the handler method.
   - The handler method executes business logic (may use services, repositories, etc.) and returns a result (e.g., `ModelAndView`, a POJO for JSON, or a view name).
   - If exceptions occur, HandlerExceptionResolver handles them.
   - For responses:
     - In traditional MVC: Uses ViewResolver to resolve the view (e.g., JSP, Thymeleaf) and render it with model data.
     - In REST APIs (common in Spring Boot): Uses HttpMessageConverters (e.g., Jackson for JSON) to serialize the return value.
1. The DispatcherServlet writes the response back through the embedded server to the client.



In Spring Boot, this flow is identical to Spring MVC but simplified—no manual servlet registration needed. The embedded server integrates seamlessly, making deployment as a standalone JAR possible.


###### Tags : [[1 - Spring Security 🍌]]