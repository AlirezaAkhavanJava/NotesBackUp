
# HttpServlet: The Class You Extend to Handle HTTP

**Definition.** `HttpServlet` is an abstract class in `jakarta.servlet.http` that implements the `Servlet` interface for HTTP. It takes the generic `service()` method from the specification and splits it into one method per HTTP verb: `doGet`, `doPost`, `doPut`, `doDelete`, and a few others. When a request arrives, the class reads the HTTP method and calls the matching method.

## Where it sits in the class hierarchy

Three classes are involved, each adding one layer:

```
Servlet (interface)            defines init, service, destroy
  └── GenericServlet           protocol-neutral base: stores ServletConfig, provides log()
        └── HttpServlet        HTTP-specific: routes service() to doGet, doPost, ...
              └── your class   overrides only the verbs you support
```

`GenericServlet` exists because the specification also covers protocols other than HTTP, so the generic logic lives in a separate class. `HttpServlet` adds everything that is specific to HTTP.

You can confirm this in Spring's own code. `DispatcherServlet`, the front controller you saw earlier, extends `FrameworkServlet`, which extends `HttpServletBean`, which extends `HttpServlet`. Spring builds its entire web layer on this class.

## The problem it solves

Imagine you had to implement `Servlet.service(ServletRequest, ServletResponse)` directly. You would receive a generic request object. You would have to check the HTTP method yourself, cast the request to `HttpServletRequest`, handle the case where the method is unsupported, and return the correct error code. Every servlet would repeat that work.

`HttpServlet` does the repetitive part once. You provide only the behavior for the methods you care about, and the base class handles the rest, including sending a `405 Method Not Allowed` response when a client uses a verb you did not implement.

## How dispatch works inside `service()`

Here is a simplified version of what the framework does on each request:

```java
// Simplified from the real HttpServlet source
protected void service(HttpServletRequest req, HttpServletResponse resp) {
    String method = req.getMethod();
    if (method.equals("GET")) {
        doGet(req, resp);
    } else if (method.equals("POST")) {
        doPost(req, resp);
    } else if (method.equals("PUT")) {
        doPut(req, resp);
    } else if (method.equals("DELETE")) {
        doDelete(req, resp);
    } else {
        resp.sendError(405); // method not supported
    }
}
```

The real code also handles `HEAD`, `OPTIONS`, `TRACE`, and conditional GET support, but the principle is the same. The important detail is the default behavior of each `doX` method. Its base implementation sends a 405 error. So if you override only `doGet` and a client sends `POST`, the client gets a 405 without any code from you.

## Walkthrough: a servlet with GET and POST

This example serves a form on GET and processes its submission on POST:

```java
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;

@WebServlet("/greet")
public class GreetServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        resp.setContentType("text/html");
        PrintWriter out = resp.getWriter();
        out.println("<form method='post' action='/greet'>");
        out.println("  <input name='name' placeholder='Your name'>");
        out.println("  <button type='submit'>Send</button>");
        out.println("</form>");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String name = req.getParameter("name");
        if (name == null || name.isBlank()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "name is required");
            return;
        }
        resp.setContentType("text/plain");
        resp.getWriter().println("Hello, " + name);
    }
}
```

What each part does:

- `@WebServlet("/greet")` maps the class to a URL. As before, Spring Boot needs `@ServletComponentScan` to find it.
- `doGet` runs when the browser opens `/greet`. It writes an HTML form. `resp.setContentType` must come before `getWriter()`, because the header has to be set before the body starts.
- The form submits with `POST`, so the container calls `doPost`. The form data is available through `req.getParameter("name")`, because the container parses the request body for form submissions.
- The validation branch uses `sendError` with a status code, then `return`s. Calling `sendError` does not stop your method, so the `return` is required to prevent the success text from being written after the error.
- Both methods declare `throws ServletException, IOException`. These are checked exceptions, so the compiler forces you to declare them or handle them.

## Walkthrough: reading headers and setting status codes

Often a servlet needs to read metadata from the request and control the response status:

```java
@WebServlet("/whoami")
public class WhoAmIServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String agent = req.getHeader("User-Agent");   // may be null
        if (agent == null) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        resp.setStatus(HttpServletResponse.SC_OK);     // 200, the default
        resp.setContentType("text/plain");
        resp.getWriter().println("Your browser: " + agent);
    }
}
```

This shows the two things a response always carries: a status code and a body. `setStatus` changes the code, and `getWriter` produces the body. Note that `setStatus` with an explicit return does not write a body, so the client receives an empty 400 response, which is correct here.

## The thread-safety trap

This is the most important practical lesson about `HttpServlet`. By default, the container creates **one instance** of your servlet and uses it for every request. Multiple worker threads call `doGet` on that same object at the same time. Instance fields are therefore shared between requests.

Consider this broken version:

```java
@WebServlet("/count")
public class CounterServlet extends HttpServlet {

    private int count = 0; // shared by all threads: DANGEROUS

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        count++;                              // not atomic, can lose updates
        resp.getWriter().println("Visits: " + count);
    }
}
```

Two requests can read the same value of `count` before either writes it back, so increments are lost. The fix is to keep per-request data in local variables, which live on each thread's stack, or to use a thread-safe type such as `AtomicInteger`. The rule to remember is that **instance fields in a servlet hold shared state, and local variables hold per-request state**.

## Why you need to understand it

In Spring Boot, you rarely extend `HttpServlet` yourself. `@RestController` methods are called through `DispatcherServlet`, which does the same verb-to-method routing with more features on top. You will still need this knowledge for three reasons. First, the 405 errors you see in Spring apps come from the same mechanism. Second, when you read Spring's source or a stack trace, you will see `doGet`, `doPost`, and `service` in the call chain, and you will recognize them. Third, the thread-safety rule applies directly to Spring beans, because a `@Controller` or `@Service` is also a single shared instance.





[[Servlet]]