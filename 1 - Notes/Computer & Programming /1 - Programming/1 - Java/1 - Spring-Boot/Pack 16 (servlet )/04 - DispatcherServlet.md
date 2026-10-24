

**Definition.** `DispatcherServlet` is the one `HttpServlet` that Spring MVC registers with Tomcat. It receives every HTTP request your application accepts, works out which of your methods should handle it, calls that method, and turns the result into an HTTP response. It is the **front controller**: a single entry point that delegates to many handlers.

## The hierarchy

You met part of this chain when we discussed `HttpServlet`:

```
Servlet (interface)
  └── GenericServlet
        └── HttpServlet                  routes service() to doGet, doPost, ...
              └── HttpServletBean        maps init parameters onto bean properties
                    └── FrameworkServlet    creates the Spring WebApplicationContext
                          └── DispatcherServlet  the request routing logic
```

Each layer adds one responsibility. `DispatcherServlet` does not do the HTTP parsing, since Tomcat already did that. It does the routing and the invocation.

## The problem it solves

Before front controllers, a common pattern was one servlet per URL. A `/users` servlet, a `/orders` servlet, and a `/products` servlet each repeated the same work: parse parameters, check authentication, convert data to a response, and handle errors. Every class carried its own copy of that plumbing, and cross-cutting behavior such as logging or error formatting had to be duplicated or wired through every class.

A front controller inverts this. One servlet receives everything, so shared behavior lives in one place. The URL-to-method mapping becomes data that the framework reads, not a separate class per URL. Your code shrinks to the part that is unique to each endpoint: the business logic.

## Where it fits in the request path

```
Browser
  │
  ▼
Tomcat           parses HTTP, picks a worker thread
  │
  ▼
Servlet Filters  run first, can reject or modify the request
  │
  ▼
DispatcherServlet                     ← you are here
  │   asks: which handler matches GET /users/42 ?
  ▼
Handler (your @GetMapping method)
  │   returns an object, or throws an exception
  ▼
DispatcherServlet
  │   writes the object to the response body (JSON), or resolves a view
  ▼
Tomcat sends the bytes back
```

Filters run before `DispatcherServlet` and wrap it, which is why authentication filters can stop a request before any controller sees it.

## The components it coordinates

`DispatcherServlet` holds no routing logic of its own. It delegates to pluggable components, which Spring calls strategies. Each one answers a single question.

|Component|Question it answers|
|---|---|
|`HandlerMapping`|Which handler should receive this request?|
|`HandlerAdapter`|How do I call that handler, and with what arguments?|
|`HandlerInterceptor`|Should anything run before or after the handler?|
|`HandlerExceptionResolver`|If something threw, what response should be produced?|
|`ViewResolver`|If the handler returns a view name, which template renders it?|
|`HttpMessageConverter`|How do I turn a Java object into JSON or XML, and back?|

For a `@RestController`, the default implementations are `RequestMappingHandlerMapping`, which reads your `@GetMapping` and similar annotations at startup, and `RequestMappingHandlerAdapter`, which resolves method parameters and serializes return values. For a traditional MVC app that returns HTML templates, the `ViewResolver` takes over the last step.

## What happens inside `doDispatch`

The core logic lives in a method called `doDispatch`, which you will see in stack traces. This is a simplified version of its flow. The real code adds async support, multipart handling, and more error paths:

```java
// Simplified from Spring's DispatcherServlet.doDispatch
protected void doDispatch(HttpServletRequest request, HttpServletResponse response) {

    HandlerExecutionChain chain = getHandler(request);   // 1. find the handler + interceptors
    if (chain == null) {
        response.sendError(404);                         // no mapping matched
        return;
    }

    HandlerAdapter adapter = getHandlerAdapter(chain.getHandler());  // 2. pick a way to call it

    if (!chain.applyPreHandle(request, response)) {      // 3. interceptors, before
        return;
    }

    ModelAndView mv;
    try {
        mv = adapter.handle(request, response, chain.getHandler());  // 4. call your method
    } catch (Exception ex) {
        mv = processHandlerException(request, response, chain.getHandler(), ex); // 5. errors
    }

    chain.applyPostHandle(request, response, mv);        // 6. interceptors, after

    render(mv, request, response);                       // 7. write the response
    chain.triggerAfterCompletion(request, response, null); // 8. interceptors, always
}
```

Read the numbered steps as the real lifecycle of every request:

1. **Find the handler.** The `HandlerMapping` compares the method, path, and headers with the mappings it recorded at startup. If nothing matches, you get a 404.
2. **Pick an adapter.** Different kinds of handler need different calling conventions. A `@RequestMapping` method needs an adapter that knows how to fill in parameters.
3. **Run pre-handle interceptors.** If one returns `false`, processing stops here.
4. **Call the handler.** The adapter resolves each parameter (from `@RequestParam`, `@RequestBody`, and so on), invokes your method, and collects the return value.
5. **Handle exceptions.** If your method threw, the `HandlerExceptionResolver` chain tries to produce a response. This is where `@ExceptionHandler` and `@ControllerAdvice` methods run.
6. **Run post-handle interceptors.**
7. **Render.** For `@RestController`, the return value goes through an `HttpMessageConverter`. For a view, the `ViewResolver` produces HTML.
8. **Run after-completion interceptors.** These run even when an exception occurred, which makes them the right place for cleanup and timing logs.

## Walkthrough: following one request

Here is a small controller and one request traced through the dispatcher:

```java
@RestController
@RequestMapping("/users")
public class UserController {

    @GetMapping("/{id}")
    public UserDto findById(@PathVariable long id) {
        if (id <= 0) {
            throw new IllegalArgumentException("id must be positive");
        }
        return new UserDto(id, "Alireza");
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<String> badInput(IllegalArgumentException ex) {
        return ResponseEntity.badRequest().body(ex.getMessage());
    }
}

public record UserDto(long id, String name) {}
```

Now send `GET /users/42`:

- **At startup**, `RequestMappingHandlerMapping` read `@RequestMapping("/users")` combined with `@GetMapping("/{id}")` and recorded the pattern `/users/{id}` for `GET`, pointing at `findById`.
- **At request time**, `DispatcherServlet` matches `GET /users/42`, extracts `id = 42` from the path, and the adapter converts the string `"42"` into a `long`.
- `findById` returns a `UserDto`. The `HttpMessageConverter` serializes it as JSON, and the response is `200 OK` with `{"id":42,"name":"Alireza"}`.

Now send `GET /users/-1`:

- The mapping and conversion succeed, and `findById` throws `IllegalArgumentException`.
- The exception skips the normal return path, and the exception resolver finds `badInput`, which was declared for that exception type. The response is `400 Bad Request` with the message as the body.

The controller never handled HTTP parsing, parameter conversion, JSON writing, or error routing. The dispatcher did all of that. Your method only expressed the business rule.

## Seeing it for yourself

You can watch the dispatcher make its decisions. Add this to `application.properties`:

```properties
logging.level.org.springframework.web=DEBUG
```

Restart and send a request. You will see lines such as `Mapped to com.example.UserController#findById(long)` and `Completed 200 OK`. Those lines come from the mapping and rendering steps described above, so this is the simplest way to confirm which handler matched.

To see every mapping the application registered, add the Actuator dependency and request `/actuator/mappings`. This lists the same table that `RequestMappingHandlerMapping` built at startup.

## Customizing it

Spring Boot registers the dispatcher on `/` by default. That mapping matches every path except exact matches for other servlets, so it catches all requests. You can change the prefix with a property:

```properties
spring.mvc.servlet.path=/api
```

With that setting, `@GetMapping("/users/{id}")` answers at `/api/users/{id}`. The dispatcher still sees every request, but only under that prefix. Static files and filters behave differently under a prefix, so change it only when you have a clear reason.

## Common mistakes

- **Assuming a filter sees the controller's return value.** Filters run before `DispatcherServlet` and cannot see what the handler returned. Use an interceptor or `ResponseBodyAdvice` for that.
- **Catching exceptions inside every controller method.** Put shared error handling in a `@ControllerAdvice` class, which the `ExceptionHandlerExceptionResolver` picks up in step 5.
- **Expecting a 404 from an unmatched path with a `@RestController` after a path change.** A forgotten `/api` prefix makes everything look like a missing route. Check the mappings endpoint first.
- **Writing heavy work into an interceptor.** Interceptors run on every matched request, so keep them light.





[[Servlet]]