
# Spring Boot HTTP Request Lifecycle: Security Filters to DispatcherServlet

## 1. The problem it solves

When a client sends an HTTP request to a Spring Boot application, something must:

1. Accept the network connection and HTTP request.
2. Apply cross-cutting processing such as security.
3. Decide which controller method should run.
4. Execute application logic and prepare the HTTP response.

Spring Boot uses a **Servlet container**, **Servlet filters**, and Spring MVC's **front controller** (`DispatcherServlet`) to do this work.

> **Core mental model:** The request reaches the Servlet container first, runs through applicable filters (including Spring Security), then reaches `DispatcherServlet`, which routes it to the correct controller method.

## 2. The whole request flow

```
Client (Browser / Postman)
          |
          | HTTP request
          v
Web Server + Servlet Container (e.g. embedded Tomcat)
          |
          v
Servlet Filter Chain
          |
          +--> Other registered servlet filters (if applicable)
          |
          +--> DelegatingFilterProxy (Spring Security bridge)
                   |
                   v
               FilterChainProxy
                   |
                   v
               Matching SecurityFilterChain
                   |
                   +--> Security filters (authentication, authorization,
                   |    CSRF checks where enabled, etc.)
                   |
                   +--> Continue if allowed
          |
          v
DispatcherServlet (Spring MVC front controller)
          |
          v
HandlerMapping: locate matching endpoint
          |
          v
HandlerAdapter: invoke controller handler
          |
          v
@RestController method
          |
          v
Service -> Repository -> Database (when needed)
          |
          v
Return value -> HTTP message converter (e.g. JSON)
          |
          v
HTTP response travels back through filter chain and container
          |
          v
Client
```

**Important:** Not every request reaches a controller. A security filter can reject it first (for example, with `401 Unauthorized` or `403 Forbidden`). Other filters can also stop the request.

## 3. Step 1: Client sends an HTTP request

Example:

```
GET /api/v1/tasks HTTP/1.1
Host: localhost:8080
Authorization: Basic YWxpY2U6c2VjcmV0
```

The client only knows the application's URL. It does not directly call a Java controller object.

## 4. Step 2: Tomcat receives the request

Tomcat is the **Servlet container** in a typical Spring Boot MVC application using `spring-boot-starter-web` and its default embedded server.

Tomcat:

- Accepts the connection and parses HTTP data.
- Provides `HttpServletRequest` and `HttpServletResponse` objects.
- Finds the appropriate servlet and its registered filters using URL mappings.
- Invokes the filter chain, eventually invoking the target servlet if processing continues.

Think of Tomcat as the infrastructure that hosts your Servlet-based web application. **Spring Security and Spring MVC run within that infrastructure.**

## 5. Step 3: Servlet filters execute

A Servlet `Filter` can inspect or modify request/response handling before and after the target servlet runs.

For example:

```
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class RequestLoggingFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        System.out.println("Before: " + request.getRequestURI());

        // Pass control to the next filter (or eventually the servlet).
        filterChain.doFilter(request, response);

        System.out.println("After: " + response.getStatus());
    }
}
```

`filterChain.doFilter(...)` is critical: it continues request processing. If a filter does not call it, the downstream servlet will not run on that path.

**Note:** `@Component` registers this example filter with Spring Boot, but the exact order relative to Spring Security depends on filter registration and ordering. Do not assume this logging filter always runs before or after the security filters.

## 6. Where Spring Security fits

You might say: **“The request enters `SecurityFilterChain`.”** That is useful shorthand, but technically the integration is:

```
Tomcat's Servlet Filter Chain
         |
         v
DelegatingFilterProxy
         |
         v
Spring-managed FilterChainProxy
         |
         v
Selected SecurityFilterChain
         |
         v
Spring Security filters
```

- **`DelegatingFilterProxy`** connects the Servlet container's filter system to a Spring-managed filter bean.
- **`FilterChainProxy`** is Spring Security's filter-chain dispatcher.
- **`SecurityFilterChain`** defines which security filters apply to matching requests.
- **Individual security filters** perform tasks such as loading security context, authenticating credentials, handling exceptions, and enforcing authorization.

A minimal security configuration might look like:

```
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/public/**").permitAll()
                        .anyRequest().authenticated()
                )
                .httpBasic(Customizer.withDefaults())
                .build();
    }
}
```

What happens?

1. A request to `/api/public/info` is allowed by the authorization rules (although it still passes through applicable security filters).
2. A request to `/api/v1/tasks` needs an authenticated user.
3. With HTTP Basic enabled, Spring Security can authenticate a valid Basic Authorization header.
4. If security checks pass, processing continues toward Spring MVC.
5. If not, Spring Security can generate an error response **before `DispatcherServlet` calls your controller**.

> `permitAll()` does **not** mean “skip the Spring Security filter chain.” It means that endpoint's authorization rule permits access.

**Also:** Spring Security authentication and authorization are distinct:

|Concept|Question|
|---|---|
|Authentication|Who is making this request?|
|Authorization|Is this user allowed to access this resource?|

## 7. Step 4: DispatcherServlet receives the request

`DispatcherServlet` is the **Front Controller** of Spring MVC.

It does not contain your application-specific business logic. Instead, it coordinates request handling:

1. Ask a `HandlerMapping` to find the appropriate handler.
2. Use an appropriate `HandlerAdapter` to invoke it.
3. Bind request data to parameters (for example, `@PathVariable`, `@RequestBody`).
4. Run validation where configured and requested.
5. Process the return value or delegate exception handling.
6. Write the HTTP response (for REST, often JSON using an HTTP message converter).

Here is a controller:

```
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/tasks")
public class TaskController {

    @GetMapping
    public String getTasks() {
        return "Tasks returned";
    }
}
```

When `GET /api/v1/tasks` passes the filters, Spring MVC matches this controller method and invokes it.

### How does `@GetMapping` work?

`@GetMapping` is **not a new servlet**. It declares handler mapping metadata for Spring MVC. By default, many endpoints are handled by the **same** `DispatcherServlet`, which delegates to the appropriate controller methods.

Compare:

|Traditional Servlet API|Spring MVC|
|---|---|
|Define a servlet (often by extending `HttpServlet`)|Define a `@RestController`|
|Map the servlet to a URL|Map a method with `@GetMapping`, `@PostMapping`, etc.|
|Override `doGet()` or `doPost()`|Write a normal Java handler method|
|Handle parsing and response writing manually|Spring MVC handles binding and serialization|
|Servlet container invokes your servlet directly|Container invokes `DispatcherServlet`, which invokes your method|

## 8. Step 5: Controller -> Service -> Repository

Once the request reaches your endpoint, your own application architecture takes over:

```
TaskController
      |
      v
TaskService
      |
      v
TaskRepository
      |
      v
Database
```

Spring MVC does **not** require these layers; they are design choices that help keep responsibilities separated.

For example, your controller delegates to a service, and the service calls a Spring Data JPA repository. After the controller returns an object, Spring MVC can serialize it as JSON and write the HTTP response.

## 9. Step 6: The HTTP response goes back

The processing order is often easiest to understand using a nested call model:

```
Filter A: BEFORE
    Security filter(s): BEFORE
        DispatcherServlet
            Controller method
    Security filter(s): AFTER
Filter A: AFTER
```

As `doFilter(...)` calls return, outer filters can perform post-processing. Response handling can also involve exceptions, asynchronous requests, and response wrappers, so the real flow has variations.

## 10. Three scenarios you should understand

### Scenario A: Public endpoint

```
GET /api/public/info
```

```
Tomcat -> Filters -> Spring Security (authorization permits it)
       -> DispatcherServlet -> Controller -> Response
```

### Scenario B: Protected endpoint, no valid credentials

```
GET /api/v1/tasks
```

```
Tomcat -> Filters -> Spring Security
                         |
                         v
                401 Unauthorized (typical with HTTP Basic)
                         |
                         v
                Controller NOT executed
```

### Scenario C: Authenticated user lacks permission

```
Tomcat -> Filters -> Spring Security
                         |
                         v
                 403 Forbidden (typical)
                         |
                         v
                 Controller NOT executed
```

The exact status and processing point depend on the authentication mechanism, authorization rules, and exception handling configuration.

## 11. Common misunderstandings

|Misunderstanding|Correction|
|---|---|
|“SecurityFilterChain is the very first thing the client hits.”|The network server and Servlet container accept the request first; Servlet filters are then invoked.|
|“SecurityFilterChain is itself a single filter.”|It represents a chain of security filters selected by Spring Security's `FilterChainProxy`.|
|“All requests reach DispatcherServlet.”|Filters may terminate processing first, and some requests can target other servlets.|
|“`@GetMapping` creates a servlet per endpoint.”|Spring MVC maps methods behind the shared `DispatcherServlet`.|
|“`permitAll()` bypasses security filters.”|It allows authorization; applicable security filters still execute.|
|“All requests must go through Service and Repository.”|Those layers are optional application architecture.|
|“Spring Security always runs before every other custom filter.”|Ordering depends on filter registration and configuration.|

## 12. Try it yourself

1. Create a Spring Boot MVC project with Spring Web and Spring Security.
2. Add the `SecurityConfig` example above.
3. Add two controller mappings: `/api/public/info` and `/api/v1/tasks`.
4. Register an in-memory user (or configure another appropriate authentication provider) so you can authenticate requests.
5. Send requests with `curl`:

```
# Public endpoint
curl -i http://localhost:8080/api/public/info

# Protected endpoint without credentials
curl -i http://localhost:8080/api/v1/tasks

# Protected endpoint with Basic credentials
curl -i -u alice:your-password http://localhost:8080/api/v1/tasks
```

6. Add a breakpoint in your filter's `doFilterInternal(...)` and the controller method. Observe which code executes for authorized and unauthorized requests.

**Security note:** HTTP Basic transmits credentials in a Base64-encoded header, not an encrypted one. Use HTTPS for real deployments. Avoid placing production credentials directly in shell command history.

## 13. The whole picture

|Order|Component|Main responsibility|
|---|---|---|
|1|Client|Sends an HTTP request|
|2|Web server / Servlet container|Receives and parses the request, manages Servlet infrastructure|
|3|Servlet filter chain|Runs cross-cutting request/response processing|
|4|Spring Security chain (when matched)|Performs configured security processing|
|5|`DispatcherServlet`|Coordinates Spring MVC request dispatch|
|6|Controller method|Handles the mapped HTTP endpoint|
|7|Service / Repository (if used)|Executes business logic and data access|
|8|MVC return-value handling + response|Produces an HTTP response that returns through the infrastructure|

**Remember:** `Tomcat -> Servlet filters (including Spring Security) -> DispatcherServlet -> Controller` is the most useful high-level order for a normal Spring Boot Servlet-based REST API.




[[Spring Security]]