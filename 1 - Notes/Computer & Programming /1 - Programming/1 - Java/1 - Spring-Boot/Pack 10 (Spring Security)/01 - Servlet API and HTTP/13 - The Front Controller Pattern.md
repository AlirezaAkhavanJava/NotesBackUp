

Front Controller is one of the classic enterprise design patterns. Once you understand it, you will see it inside almost every Java web framework, including Spring MVC. This lesson builds the idea from the ground up, shows a hand-written version, and then shows where Spring does the same job for you.

## Part 1: The Definition

A **Front Controller** is a single component that receives every incoming request for an application and then decides which piece of code should handle it. Instead of each URL having its own entry point, all requests enter through one door. That door reads the request, works out the intent, and hands the work to the right handler.

Two roles appear in every version of this pattern:

- **The front controller** is the single entry point. It handles shared concerns and dispatches.
- **The handlers** (also called commands, actions, or controllers) contain the business logic for one specific task.

Keep these two roles separate in your head. The front controller routes. The handler does the work.

## Part 2: Why It Exists

Consider the older way of building web applications, where every page is its own servlet or script. Imagine three pages: a book list, a book form, and a book save action.

```
/books       -> BookListServlet
/books/add   -> BookFormServlet
/books/save  -> BookSaveServlet
```

This works for three pages. At thirty pages, you have thirty entry points, and each one repeats the same setup:

- Parse the request parameters.
- Check that the user is logged in.
- Set the character encoding.
- Log the request.
- Handle exceptions in a consistent way.
- Choose the response format (HTML, JSON, or a redirect).

Every servlet copies this code, and copies drift apart over time. One servlet forgets to set UTF-8, another logs nothing, and a third returns a stack trace to the user.

## Part 3: The Problem It Solves

The front controller solves three specific problems.

**Duplicated cross-cutting code.** Logic that applies to every request, such as logging, authentication checks, and encoding, lives in one place.

**Inconsistent behavior.** Because every request flows through the same code, every request gets the same treatment unless you deliberately change it.

**Hard-to-change URL structure.** When routes are spread across many classes, renaming `/books` to `/library/books` means hunting through files. With a front controller, the route table is one map or one configuration file.

## Part 4: How It Works, Step by Step

Here is the flow for one request, from browser to response:

1. The browser sends `GET /app/books`.
2. The web container (Tomcat) sees that `/app/*` is mapped to the front controller and passes the request to it.
3. The front controller inspects the path and looks up a matching handler in its table.
4. It calls the handler and passes the request and response objects.
5. The handler does its work and writes the result, or returns the name of a view to render.
6. The front controller finishes the response.

The important point is step 3. The lookup table is the heart of the pattern.

## Part 5: A Hand-Written Front Controller in Plain Servlets

This example shows the pattern without any framework. It uses the Jakarta Servlet API, which you would find in a standalone Tomcat deployment (Tomcat 10 or newer, Java 17 or newer). The goal is to understand the mechanism, not to build a production system.

**Step A: The handler contract.** Every handler implements one interface.

```java
package com.example.frontcontroller;

import java.io.IOException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

public interface Command {
    void execute(HttpServletRequest request, HttpServletResponse response) throws IOException;
}
```

This interface is the contract. The front controller only knows about this interface, not about any specific handler. That separation is why you can add new handlers without editing the controller.

**Step B: Two concrete handlers.**

```java
package com.example.frontcontroller;

import java.io.IOException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

public class ListBooksCommand implements Command {
    @Override
    public void execute(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("text/plain;charset=UTF-8");
        response.getWriter().println("Effective Java");
        response.getWriter().println("Spring in Action");
    }
}
```

```java
package com.example.frontcontroller;

import java.io.IOException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

public class AddBookCommand implements Command {
    @Override
    public void execute(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String title = request.getParameter("title");
        response.setContentType("text/plain;charset=UTF-8");
        response.getWriter().println("Added book: " + title);
    }
}
```

What each handler does: `ListBooksCommand` writes a fixed list, and `AddBookCommand` reads a `title` parameter from the query string or form and echoes it back. Neither handler knows about routing, and neither sets up logging or encoding for the whole application. They focus on one task each.

**Step C: The front controller itself.**

```java
package com.example.frontcontroller;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/app/*")
public class FrontController extends HttpServlet {

    private final Map<String, Command> routes = new HashMap<>();

    @Override
    public void init() {
        routes.put("/books", new ListBooksCommand());
        routes.put("/books/add", new AddBookCommand());
    }

    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Shared work for every request happens here, once.
        request.setCharacterEncoding("UTF-8");

        // With @WebServlet("/app/*"), getPathInfo() returns the part after /app.
        String path = request.getPathInfo();
        Command command = routes.get(path);

        if (command == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "No route for " + path);
            return;
        }

        command.execute(request, response);
    }
}
```

**What each part does.**

`@WebServlet("/app/*")` maps every URL starting with `/app/` to this one class. This is what makes it a front controller: the container sends all of those requests here.

`routes` is the dispatch table. It connects a path string to a handler object. Adding a feature means adding one line to `init()`.

`request.setCharacterEncoding("UTF-8")` runs once for every request. This is exactly the kind of shared behavior that would otherwise be copied into each servlet.

`request.getPathInfo()` returns the portion after the mapping, so `/app/books` yields `/books`. This is the key you use for the lookup.

`routes.get(path)` performs the dispatch. If no handler matches, the controller returns 404 itself, so the handlers never receive a request they cannot serve.

`command.execute(request, response)` hands control to the handler. After this call, the handler owns the response.

**How to try it.** Deploy the project to Tomcat and open these URLs in a browser or with curl:

```bash
curl http://localhost:8080/your-app/app/books
curl "http://localhost:8080/your-app/app/books/add?title=Clean+Code"
curl -i http://localhost:8080/your-app/app/unknown
```

The first returns the book list. The second echoes the title. The third returns a 404, which proves that the controller handles unmatched routes centrally.

## Part 6: The Same Idea in Spring MVC

Spring MVC is built on a front controller called `DispatcherServlet`. You never write the one you saw in Part 5, because Spring Boot registers `DispatcherServlet` automatically and maps it to `/`, so it receives every request that no other filter or servlet has taken.

Your handlers look like this:

```java
package com.example.library;

import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class BookController {

    @GetMapping("/api/books")
    public List<String> listBooks() {
        return List.of("Effective Java", "Spring in Action");
    }

    @GetMapping("/api/books/add")
    public String addBook(@RequestParam String title) {
        return "Added book: " + title;
    }
}
```

**Mapping each piece to Part 5.**

The `routes` map you wrote by hand is replaced by a **HandlerMapping**. Spring scans your classes at startup, reads the `@GetMapping` values, and builds the lookup table automatically.

The `Command` interface is replaced by a **HandlerAdapter**. It knows how to call your method, whatever its signature, and convert its return value into a response.

The `request.getParameter("title")` call is replaced by `@RequestParam`. Spring reads the parameter and converts it to the declared type.

The `response.getWriter().println(...)` call is replaced by the return value. For `@RestController`, a `String` or object is written directly to the response body. For a regular `@Controller`, the returned string names a view to render.

The `sendError(404)` logic is handled by Spring's default error handling, which you can customize with `@ControllerAdvice`.

Here is the sequence inside `DispatcherServlet` for one request:

```
Request
  -> DispatcherServlet (front controller)
    -> HandlerMapping      (which handler matches this URL and method?)
    -> HandlerInterceptors (preHandle)
    -> HandlerAdapter      (invoke the controller method with converted arguments)
    -> HandlerInterceptors (postHandle)
    -> Return value handling (JSON, view, or redirect)
    -> HandlerInterceptors (afterCompletion)
Response
```

## Part 7: Shared Behavior in Spring, Three Places It Can Live

In Part 5, the shared `setCharacterEncoding` call lived inside the front controller. Spring offers three places for shared behavior, and each one runs at a different point. Choosing the right one is a real design decision.

**Servlet filters** run before the request reaches `DispatcherServlet`. Spring Security is implemented as a filter, which is why it can block a request before any controller sees it. Use filters for work that does not need to know which handler will run.

**HandlerInterceptors** run inside `DispatcherServlet`, after the handler is found. They can see which controller method will run. Use them for logging per endpoint, timing, or checks that depend on the handler.

**`@ControllerAdvice`** handles exceptions and adds shared model data across controllers. Use it for consistent error responses.

Here is a timing interceptor as a concrete example:

```java
package com.example.library;

import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class TimingInterceptor implements HandlerInterceptor {

    private static final String START = "requestStart";

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        request.setAttribute(START, System.nanoTime());
        return true; // true means "continue to the handler"
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response,
                                Object handler, Exception ex) {
        long start = (long) request.getAttribute(START);
        long millis = (System.nanoTime() - start) / 1_000_000;
        System.out.println(request.getMethod() + " " + request.getRequestURI() + " took " + millis + " ms");
    }
}
```

**What each method does.** `preHandle` runs before the controller method and returns `true` to allow the request through. Returning `false` would stop the request, and you would have to write the response yourself. `afterCompletion` runs after the response is finished, even if an exception occurred, which makes it reliable for timing.

Register the interceptor with a configuration class:

```java
package com.example.library;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    private final TimingInterceptor timingInterceptor;

    public WebConfig(TimingInterceptor timingInterceptor) {
        this.timingInterceptor = timingInterceptor;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(timingInterceptor).addPathPatterns("/api/**");
    }
}
```

`addPathPatterns("/api/**")` limits the interceptor to API routes, so static resources and other paths are not timed.

## Part 8: Seeing the Front Controller in Your Own Project

You can observe `DispatcherServlet` in a running Spring Boot application. Add this to `application.properties` to see the registration and mapping at startup:

```properties
logging.level.org.springframework.web.servlet=DEBUG
```

Restart the app and send a request. You will see log lines showing which handler matched and how the request was dispatched. This is the fastest way to confirm that the pattern is working as described.

## Part 9: Common Mistakes

- **Putting business logic in the front controller.** The front controller should route and handle shared concerns. Once it starts computing totals or querying databases, it becomes the giant class the pattern was meant to avoid.
- **Forgetting that the front controller is a single point of failure.** If it throws an unhandled exception, every route fails. Keep it simple, and handle errors consistently.
- **Confusing filters and interceptors.** Filters see raw requests before routing. Interceptors see routed requests with their handler. Putting a security check in an interceptor means unmatched URLs are not protected, because no handler matched.
- **Assuming the security chain runs after the controller.** Spring Security runs as a filter before `DispatcherServlet`, so a request rejected by a security rule never reaches your interceptor.




[[Spring Security]]