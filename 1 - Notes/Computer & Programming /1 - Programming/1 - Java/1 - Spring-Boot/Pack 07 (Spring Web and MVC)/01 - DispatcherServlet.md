


## 1. Core intuition

Picture a hotel with one **front desk**. Every guest, whatever they want (room service, a taxi, a late checkout), walks up to the same desk. The receptionist doesn't do the work. They read the request, decide which staff member handles it, hand it over, then collect the result and give it back to the guest.

`DispatcherServlet` is that front desk. **Every HTTP request to your Spring MVC app goes through it first**, and it routes the request to the right controller method. This is the **Front Controller pattern**.

Last time I said "the `DispatcherServlet` receives the request and finds the matching controller method" and "an `HttpMessageConverter` reads the body". This topic opens up that black box.

## 2. Where it sits

Spring Boot embeds a web server (Tomcat by default). Tomcat only understands **servlets**, which are Java classes that take an HTTP request and produce an HTTP response. Spring MVC plugs into this by registering **one** servlet, `DispatcherServlet`, mapped to `/`, which means "everything."

```
Browser/Client
     │
     ▼
 Tomcat (embedded)
     │
     ▼
 Servlet Filters          ← run BEFORE Spring MVC (security, CORS, logging)
     │
     ▼
 DispatcherServlet        ← Spring MVC begins here
     │
     ▼
 Your @RestController
```

You never create it yourself. Spring Boot's auto-configuration (`DispatcherServletAutoConfiguration`) registers it when it sees `spring-boot-starter-web` on the classpath.

## 3. The request lifecycle, step by step

Inside `DispatcherServlet.doDispatch(...)`:

```
1. HandlerMapping      "Which method handles GET /users/5?"
        ↓
2. Interceptors        preHandle()  (can stop the request here)
        ↓
3. HandlerAdapter      "How do I call that method?"
        │   ├─ ArgumentResolvers: build @PathVariable, @RequestParam,
        │   │                      @RequestBody (via HttpMessageConverter + Jackson)
        │   ├─ @Valid validation
        │   ├─ >>> your controller method runs <<<
        │   └─ ReturnValueHandlers: serialize the result (Jackson) into the response
        ↓
4. Interceptors        postHandle(), then afterCompletion()
        ↓
5. Response sent
        
   (any exception along the way → HandlerExceptionResolvers → @ExceptionHandler)
```

### Step 1: HandlerMapping

At startup, Spring scans your controllers and builds a lookup table, essentially `(HTTP method + URL pattern) → method`. The implementation is `RequestMappingHandlerMapping`. For each request it returns a **handler execution chain**: the target method **plus** any matching interceptors.

If nothing matches, you get a `404`.

### Step 2: HandlerAdapter

The `DispatcherServlet` doesn't know how to call your method. Handlers can be of different kinds (annotated methods, functional endpoints, old-style `Controller` classes). A **HandlerAdapter** knows how to invoke one specific kind. For `@GetMapping`-style methods it is `RequestMappingHandlerAdapter`.

**Why this design:** the dispatcher stays generic, and new handler types can be added without changing it. This is the **Strategy pattern**, and you'll find it all over Spring.

Inside the adapter, two sets of helpers do the heavy lifting you learned about earlier:

- **`HandlerMethodArgumentResolver`s** build each parameter. One handles `@PathVariable`, another `@RequestParam`, and the `@RequestBody` one delegates to `HttpMessageConverter`, which uses Jackson. This is where your `@JsonProperty`, `@JsonCreator`, and `@JsonFormat` apply.
- **`HandlerMethodReturnValueHandler`s** process what you return. With `@ResponseBody` (included in `@RestController`), the return value is serialized to the response body. This is where `@JsonInclude` applies.

### Step 3: Views (only for `@Controller`, not `@RestController`)

For classic server-rendered pages (Thymeleaf), a method returns a **view name** like `"home"`, and a `ViewResolver` turns it into an HTML template. With `@RestController`, this step is skipped entirely, because the body is already written.

### Step 4: Exceptions

If anything throws (a failed `@Valid`, unparseable JSON, your own exception), the dispatcher asks its **`HandlerExceptionResolver`s** to translate it into a response. This is how `HttpMessageNotReadableException` becomes `400` automatically, and how your `@ExceptionHandler` methods take over:

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ErrorResponse> handle(UserNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ErrorResponse(ex.getMessage()));
    }
}

public record ErrorResponse(String message) {}
```

## 4. Seeing it for yourself

Add to `application.properties`:

```properties
logging.level.org.springframework.web.servlet.DispatcherServlet=DEBUG
logging.level.org.springframework.web=DEBUG
```

Now every request logs lines like `GET "/users/5", parameters={}` followed by `Mapped to ...UserController#get(Long)`. Seeing the mapping log is the quickest way to debug "why does my endpoint return 404?"

You can also see the lookup table: add `spring-boot-starter-actuator`, expose the `mappings` endpoint, and visit `/actuator/mappings`.

## 5. Interceptors: hooking into the chain

An interceptor runs **inside** the dispatcher, around your controller:

```java
@Component
public class TimingInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest req, HttpServletResponse res, Object handler) {
        req.setAttribute("start", System.currentTimeMillis());
        return true;                     // false = stop here, controller never runs
    }

    @Override
    public void afterCompletion(HttpServletRequest req, HttpServletResponse res,
                                Object handler, Exception ex) {
        long ms = System.currentTimeMillis() - (long) req.getAttribute("start");
        System.out.println(req.getRequestURI() + " took " + ms + "ms");
    }
}

@Configuration
public class WebConfig implements WebMvcConfigurer {

    private final TimingInterceptor timing;

    public WebConfig(TimingInterceptor timing) { this.timing = timing; }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(timing).addPathPatterns("/api/**");
    }
}
```

The callbacks are:

- `preHandle`: before the controller, and it can veto the request.
- `postHandle`: after the controller, before the response is written.
- `afterCompletion`: always runs at the end, even after an exception, so it's the right place for cleanup.

## 6. Filter vs. Interceptor vs. ControllerAdvice

This is the most commonly confused part, and it's explained by **position relative to the dispatcher**:

||Belongs to|Runs|Knows which controller method?|Typical use|
|---|---|---|---|---|
|**Filter**|Servlet container|Before the `DispatcherServlet`|No|Spring Security, CORS, encoding, request logging|
|**Interceptor**|Spring MVC|Inside the dispatcher, around the handler|**Yes**|Auth checks per endpoint, timing, locale|
|**`@ControllerAdvice`**|Spring MVC|Reacts to exceptions/binding from controllers|Yes|Centralized error responses|

Rule of thumb: if it must work for **every** request, including static files and those that never reach a controller, use a filter. If it depends on **which handler** was chosen, use an interceptor.

## 7. Gotchas

1. **Exceptions thrown in a filter never reach `@ControllerAdvice`.** The dispatcher hasn't been reached yet, so its exception machinery doesn't exist at that point. This is why Spring Security errors (`401`/`403`) are shaped by Security's own entry point and not your `@ExceptionHandler`.
2. **One request can pass through the dispatcher more than once.** Error handling (forwarding to `/error`) and async processing re-dispatch. That's why `OncePerRequestFilter` exists, so filters don't run twice.
3. **Mapped to `/`, not `/*`.** The `/` mapping is a "default servlet" style mapping, which is why Spring MVC can also serve static resources (`/static`, `/public`) through the same machinery.
4. **Ambiguous mappings fail at startup, not at request time.** Two methods with the same path and HTTP method throw `IllegalStateException: Ambiguous mapping` when the app boots. That's useful, because the problem shows up immediately.
5. **Changing the base path:** `spring.mvc.servlet.path=/api` prefixes everything. This is a servlet-level setting, so it's different from `server.servlet.context-path`, which changes the whole application's root.
6. **Spring WebFlux has no `DispatcherServlet`.** The reactive stack uses `DispatcherHandler` for the same job (it runs on Netty, not servlets). The concepts map one-to-one, but the class names differ.
7. **Thread model:** with Tomcat, one request is handled by one thread from a pool for the entire trip through the dispatcher. A slow outgoing call, which I warned about last time, holds that thread. This is why timeouts matter.

## 8. Connecting it to what you know

Every earlier topic now has a place on the map:

- `@Valid` and `@JsonProperty` happen in step 3, **inside** the HandlerAdapter, while building arguments.
- `@JsonInclude` and your response DTO's shape are applied by the **return value handler**.
- The `400`/`415` errors come from **exception resolvers** reacting to failures in those steps.
- Outgoing `RestClient` calls happen **inside your controller or service**, in the middle of this chain.

So the `DispatcherServlet` is the conductor, and the pieces you've learned are the instruments it calls in order.





[[Spring Framework]]