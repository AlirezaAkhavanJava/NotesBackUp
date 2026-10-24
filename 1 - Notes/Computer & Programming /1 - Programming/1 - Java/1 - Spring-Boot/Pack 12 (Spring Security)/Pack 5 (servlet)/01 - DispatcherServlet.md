

## The problem it solves

Imagine a web app with 50 URLs. In the old servlet style, each URL needed its own servlet class, and every one of them repeated the same chores: read the parameters, convert types, check the method, write the response, handle errors. That's a lot of duplicated code, and it's easy to forget a step in one of them.

The **DispatcherServlet** fixes this with one rule: **one servlet receives every request, then hands each one to the right piece of your code.** The repeated chores happen in one place, and you only write the interesting part, your controller method.

This design is called the **Front Controller pattern**.

## The picture: a hotel reception desk

| Hotel | Spring MVC |
|---|---|
| Guests arrive at one front desk | Every request enters through **one servlet** |
| The receptionist checks the request ("room service? spa? luggage?") | **HandlerMapping** finds the right controller method |
| The receptionist calls the correct department in its own way | **HandlerAdapter** calls your method the way it expects |
| Security glances at the guest on the way in | **Interceptors** run before and after |
| The department does the real work | Your **controller method** |
| The receptionist writes up the answer politely | **Message converters** or **view rendering** build the response |
| A complaint line for when something goes wrong | **Exception resolvers** |

The receptionist does very little of the actual work. Their job is to **coordinate**: find who can handle it, call them, and package the result.

## Where it sits

You already know the request path from the networking lesson. Here it is with the DispatcherServlet in the middle:

```
Browser
  │  TCP + TLS
  ▼
Tomcat (embedded in your Spring Boot app)
  │
  ▼
Servlet FILTERS      (Spring Security, CORS, encoding, logging)
  │
  ▼
┌──────────────────────────────────────────────┐
│ DispatcherServlet                            │
│   1. find the handler        (HandlerMapping)│
│   2. interceptors: preHandle                 │
│   3. call it                 (HandlerAdapter)│
│        └─ your @Controller method            │
│   4. interceptors: postHandle                │
│   5. build the response (converter or view)  │
│   6. interceptors: afterCompletion           │
└──────────────────────────────────────────────┘
  │
  ▼
Filters again (on the way back out)
  │
  ▼
Browser
```

The thing to remember: **filters belong to the servlet container and run before the DispatcherServlet. Interceptors belong to Spring MVC and run inside it.** That's why Spring Security (a filter chain) can reject a request before the DispatcherServlet ever sees it.

---

# Part 1: What it is

The DispatcherServlet is a normal Java servlet, a class that extends `HttpServlet`. Its family tree explains a lot:

```
HttpServlet                  (from Jakarta Servlet API)
   └─ HttpServletBean        (lets servlet init params become bean properties)
        └─ FrameworkServlet  (creates and owns the Spring application context)
             └─ DispatcherServlet   (the routing logic)
```

| Class | Its job |
|---|---|
| `HttpServlet` | Receives raw requests from Tomcat (`service`, `doGet`, `doPost`) |
| `FrameworkServlet` | Connects the servlet world to the Spring world (the `WebApplicationContext`) |
| `DispatcherServlet` | Decides who handles each request and runs the whole flow |

Every request reaches `FrameworkServlet.service()`, which eventually calls `DispatcherServlet.doService()` and then the most important method, **`doDispatch()`**.

### Who creates it?

**In Spring Boot, you never create it.** Auto-configuration (`DispatcherServletAutoConfiguration`) does it when it sees Spring MVC on the classpath. By default it's mapped to `/`, which means "everything that no other servlet claims."

| Setting | Meaning |
|---|---|
| `spring.mvc.servlet.path=/api` | Maps the DispatcherServlet to `/api/*` instead of `/` |
| `spring.mvc.servlet.load-on-startup=1` | Initialize it at startup instead of at the first request (the default is lazy, `-1`) |
| `server.servlet.context-path=/shop` | A prefix for the whole app, separate from the above |

Without Boot (plain Spring), you'd register it yourself in `web.xml` or a Java class that extends `AbstractAnnotationConfigDispatcherServletInitializer`. Boot hides all of this.

---

# Part 2: The flow, step by step

Here is what `doDispatch()` does, in simplified pseudo-code (the real source has more branches, but the skeleton is this):

```java
// Simplified. Not the exact Spring source.
void doDispatch(request, response) {
    handlerChain = getHandler(request);               // 1. who handles this?
    if (handlerChain == null) { send 404; return; }

    adapter = getHandlerAdapter(handlerChain.handler); // 2. how do I call it?

    if (!handlerChain.applyPreHandle(request, response)) return;  // 3. interceptors

    modelAndView = adapter.handle(request, response, handler);    // 4. YOUR code runs

    handlerChain.applyPostHandle(request, response, modelAndView); // 5. interceptors
    render(modelAndView) or exception handling;                    // 6. build response
    handlerChain.triggerAfterCompletion(request, response, ex);    // 7. cleanup
}
```

Let's walk through each step.

## Step 1: HandlerMapping, "who handles this?"

A **HandlerMapping** looks at the request (path, method, headers) and returns the handler, plus the interceptors that apply. Spring Boot registers several, tried in order:

| HandlerMapping | Handles |
|---|---|
| `RequestMappingHandlerMapping` | Your `@RequestMapping`, `@GetMapping`, `@PostMapping` methods |
| `RouterFunctionMapping` | Functional-style routes |
| `BeanNameUrlHandlerMapping` | Beans named like URLs (rare) |
| `SimpleUrlHandlerMapping` (static resources, `/**`) | Static files such as `/css/app.css`, `/index.html` |
| `WelcomePageHandlerMapping` | The `/` welcome page |

The first mapping that finds a match wins. Static resources come **after** your controllers, so your controller paths take priority.

At startup, `RequestMappingHandlerMapping` scans every controller bean and builds a **lookup table**:

```
GET  /users/{id}   →  UserController.get(long)
POST /users        →  UserController.create(User)
```

At request time, it's a table lookup, not scanning. The matching considers several things, and each failure maps to an HTTP status you learned about:

| What doesn't match | Status the client gets |
|---|---|
| No path matches at all | **404** Not Found |
| Path matches, but the method doesn't (`DELETE` on a GET-only URL) | **405** Method Not Allowed |
| Path matches, but `consumes` doesn't match the request's `Content-Type` | **415** Unsupported Media Type |
| Path matches, but `produces` doesn't match the `Accept` header | **406** Not Acceptable |

So these status codes aren't random. They come out of the matching step.

## Step 2: HandlerAdapter, "how do I call it?"

Handlers come in different shapes: an annotated method, a `Controller` interface implementation, a `HttpRequestHandler`. The DispatcherServlet doesn't want to know the details of each. A **HandlerAdapter** knows how to call one shape.

| Adapter | Calls |
|---|---|
| `RequestMappingHandlerAdapter` | Your annotated controller methods |
| `HandlerFunctionAdapter` | Functional handlers |
| `HttpRequestHandlerAdapter` | Static resource handlers and similar |

This is the **Adapter pattern**: the DispatcherServlet always asks the same question ("can you handle this?"), and each adapter answers for its own type. New kinds of handlers can be added without changing the DispatcherServlet at all.

## Step 3: Interceptors, `preHandle`

Interceptors are small hooks around the handler (more in Part 4). `preHandle` runs first. If any interceptor returns `false`, the chain stops and your controller is never called.

## Step 4: Your controller runs, but Spring does a lot first

The `RequestMappingHandlerAdapter` doesn't just call `get(id)`. It **prepares every argument** using **argument resolvers**:

```java
@GetMapping("/users/{id}")
public User get(@PathVariable long id,
                @RequestParam(defaultValue = "false") boolean details,
                @RequestHeader("Accept-Language") String lang,
                HttpSession session,
                @AuthenticationPrincipal UserDetails me) { ... }
```

Each parameter gets filled by a different resolver:

| Parameter | Resolver reads from | Notes |
|---|---|---|
| `@PathVariable long id` | The URL path (`/users/42`) | Converts `"42"` to `long` |
| `@RequestParam boolean details` | The query string (`?details=true`) | Converts and applies the default |
| `@RequestHeader String lang` | A request header | |
| `@RequestBody User u` | The JSON body | Uses an **HttpMessageConverter** (Jackson) |
| `@CookieValue String theme` | The `Cookie` header | |
| `HttpSession session` | The servlet request | Creates a session if missing |
| `@AuthenticationPrincipal` | Spring Security's `SecurityContext` | A resolver added by Spring Security |
| `Model`, `HttpServletRequest`, `Principal`... | Framework objects | |

Conversion happens here too. `"42"` becomes a `long`, `"2026-10-24"` becomes a `LocalDate`, and a JSON body becomes a `User`. A failure at this point, for example `/users/abc` for a `long`, throws a `MethodArgumentTypeMismatchException` and the client gets **400**, **before your code runs**.

Then **validation** runs for `@Valid` arguments, and a failure there gives **400** as well.

Only after all arguments are ready does the adapter call your method, using Java reflection.

## Step 5: Handling the return value

After your method returns, **return value handlers** decide what to do with the result:

| You return | Handler does | Result |
|---|---|---|
| An object from a `@RestController` (`@ResponseBody`) | Picks an **HttpMessageConverter** based on `Accept` and writes the body | JSON or XML |
| A `String` from a `@Controller` | Treats it as a **view name** | An HTML page |
| `ResponseEntity<T>` | Writes the status, headers, and body you chose | Full control |
| `void` with `@ResponseStatus` | Sets only the status | e.g. 204 |
| `ModelAndView` | Model data plus a view name | An HTML page |

### Two modes

There are two worlds inside Spring MVC, and the return value decides which one you're in:

**JSON/REST mode** (`@RestController`, `@ResponseBody`, `ResponseEntity`):
```
return object → HttpMessageConverter (Jackson) → bytes written to the response
```
The response is **already written** by the time the adapter returns.

**HTML/view mode** (`@Controller` returning a view name):
```
return "orders" → ViewResolver finds the template → View renders HTML using the Model
```
Here, the DispatcherServlet's render step builds the page, for example with Thymeleaf.

## Step 6: `postHandle`, then rendering

`postHandle` interceptors run after your method but **before** the view is rendered. They can add data to the model. Notice the gotcha: in JSON mode the response body is already written, so `postHandle` **can't change it**.

## Step 7: `afterCompletion`

This always runs at the end, even if an exception occurred, as long as that interceptor's `preHandle` ran. It's the right place for cleanup and for timing or logging, similar to a `finally` block.

---

# Part 3: When something goes wrong, exception resolvers

If a controller (or any step above) throws an exception, the DispatcherServlet doesn't let it explode. It asks its **HandlerExceptionResolvers**, in order:

| Resolver | Handles |
|---|---|
| `ExceptionHandlerExceptionResolver` | Your `@ExceptionHandler` methods, including those in `@ControllerAdvice` / `@RestControllerAdvice` |
| `ResponseStatusExceptionResolver` | Exceptions annotated with `@ResponseStatus`, and `ResponseStatusException` |
| `DefaultHandlerExceptionResolver` | Spring's own exceptions (type mismatch becomes 400, unsupported method becomes 405...) |

If none handles it, the exception goes back up to the container, which shows an error page (`/error`, handled by Spring Boot's `BasicErrorController`) with a 500.

A quick example of a global handler, which is a resolver you wrote:

```java
@RestControllerAdvice
public class ApiErrors {

    @ExceptionHandler(UserNotFound.class)
    public ResponseEntity<Map<String, String>> notFound(UserNotFound e) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("error", e.getMessage()));
    }
}
```

- `@RestControllerAdvice` marks a class whose handlers apply to **all** controllers.
- `@ExceptionHandler(UserNotFound.class)` says "run me when this exception type is thrown."
- The method returns a normal `ResponseEntity`, so it goes through the same return-value handling as any other result.

**Important boundary:** the DispatcherServlet only sees exceptions thrown **inside it**. An exception thrown in a servlet **filter** (for example Spring Security rejecting a request) never reaches your `@ControllerAdvice`. That's why security errors have their own handlers (`AuthenticationEntryPoint`, `AccessDeniedHandler`).

---

# Part 4: Interceptors vs filters

These two are often confused, since both "wrap" requests.

| | **Filter** | **Interceptor** |
|---|---|---|
| Belongs to | The Servlet container (Jakarta Servlet) | Spring MVC |
| Runs | **Before** the DispatcherServlet | **Inside** the DispatcherServlet |
| Sees | Raw request and response | Request, response, **and the matched handler** (the controller method) |
| Applies to | Everything (static files, errors, non-Spring servlets) | Only requests that go through Spring MVC |
| Hooks | One `doFilter` method | `preHandle`, `postHandle`, `afterCompletion` |
| Can wrap the request or response objects | **Yes** | No |
| Typical use | Security, CORS, compression, request logging | Timing, per-controller checks, adding model data |
| Example | Spring Security's `FilterChainProxy` | A timing or locale interceptor |

Rule of thumb: if it must work **even for requests that never reach a controller**, use a filter. If it needs to know **which controller method** is about to run, use an interceptor.

### Writing an interceptor

```java
@Component
public class TimingInterceptor implements HandlerInterceptor {

    private static final Logger log = LoggerFactory.getLogger(TimingInterceptor.class);

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) {
        request.setAttribute("startNanos", System.nanoTime());
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request,
                                HttpServletResponse response,
                                Object handler,
                                Exception ex) {
        long start = (long) request.getAttribute("startNanos");
        long ms = (System.nanoTime() - start) / 1_000_000;
        log.info("{} {} -> {} in {} ms", request.getMethod(),
                request.getRequestURI(), response.getStatus(), ms);
    }
}
```

Line by line:
- `HandlerInterceptor` is the interface with the three hooks. All three have default implementations, so you override only the ones you need.
- `preHandle` runs before the controller. Returning `true` means "continue." Returning `false` means "I've handled it, stop here" (you'd write the response yourself first, for example a 401).
- `request.setAttribute("startNanos", ...)` stores a value on the request, so the later hook can read it. Interceptors are shared singletons, so **never store per-request data in a field**. Concurrent requests would overwrite each other.
- `afterCompletion` runs at the very end. The `ex` parameter is the exception if one occurred (or `null`).
- `(System.nanoTime() - start) / 1_000_000` converts nanoseconds to milliseconds.
- `handler` (unused here) is the matched handler, normally a `HandlerMethod` object, from which you can read the controller class, the method, and its annotations.

Register it:

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {

    private final TimingInterceptor timing;

    public WebConfig(TimingInterceptor timing) {
        this.timing = timing;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(timing)
                .addPathPatterns("/api/**")
                .excludePathPatterns("/api/health");
    }
}
```

- `WebMvcConfigurer` is the official way to customize Spring MVC while keeping Boot's defaults.
- `addInterceptors` is where you plug interceptors in. Declaring the class as a `@Component` is **not** enough on its own, since it must also be registered here.
- `addPathPatterns` and `excludePathPatterns` limit which URLs the interceptor applies to.

---

# Part 5: A toy version to see the idea

Here's a tiny front controller in plain Java. It's not Spring, it's only to make the pattern visible:

```java
@WebServlet("/*")
public class MiniDispatcher extends HttpServlet {

    private final Map<String, Handler> routes = new HashMap<>();

    @Override
    public void init() {
        routes.put("GET /hello", (req, res) -> res.getWriter().write("Hello!"));
        routes.put("GET /time",  (req, res) -> res.getWriter().write(Instant.now().toString()));
    }

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse res) throws IOException {
        String key = req.getMethod() + " " + req.getRequestURI();
        Handler handler = routes.get(key);
        if (handler == null) {
            res.sendError(404);
            return;
        }
        try {
            handler.handle(req, res);
        } catch (Exception e) {
            res.sendError(500);
        }
    }

    interface Handler {
        void handle(HttpServletRequest req, HttpServletResponse res) throws Exception;
    }
}
```

Line by line:
- `@WebServlet("/*")` makes this one servlet receive **every** URL. That's the front controller idea.
- `routes` is the lookup table. Spring builds the same kind of table from your annotations.
- `init()` fills the table once at startup.
- `service(...)` is the single entry point. It builds a key like `GET /hello`, finds the handler, and calls it.
- No handler gives a 404, and an exception gives a 500. Spring does this too, just with far more detail.

What Spring adds to this toy: path variables, argument conversion, JSON, validation, interceptors, content negotiation, and exception resolvers. The skeleton is the same.

---

# Part 6: The DispatcherServlet and Spring Security

You learned that Spring Security is a **chain of servlet filters**. Now you can see exactly where it sits:

```
Tomcat
  → [Filter] Spring Security's FilterChainProxy
        → CSRF → Authentication → Authorization ...
  → DispatcherServlet
        → your controller
```

Consequences worth knowing:

| Fact | Why |
|---|---|
| A request rejected by Spring Security **never reaches** the DispatcherServlet | The filters run first |
| `@ControllerAdvice` doesn't catch security errors | They happen before the DispatcherServlet |
| `@PreAuthorize` **does** run inside the DispatcherServlet's flow | It's a method-level check applied around your controller method |
| `@AuthenticationPrincipal` works because of an **argument resolver** | A resolver reads the user from the `SecurityContext` |
| Spring Security's `http.cors(...)` runs as a filter | So the CORS preflight is answered before the DispatcherServlet |

Keep this map in your head. When you study the filter chain next, you'll know the exact point where the filters hand over to the DispatcherServlet.

---

# Part 7: Threads and performance

- Tomcat takes **one thread** from its pool for each request. That same thread carries the request through the filters, the DispatcherServlet, your controller, and back. (This is why the `SecurityContext` can live in a `ThreadLocal`.)
- The DispatcherServlet itself is **a singleton**, one instance shared by all threads. That's why interceptors and controllers must be **thread-safe** and shouldn't keep per-request state in fields.
- A slow controller holds its thread for the whole duration, so a few slow calls can exhaust the pool. Remedies include timeouts, **virtual threads** (`spring.threads.virtual.enabled=true`), or asynchronous return types (`Callable`, `DeferredResult`), which let Tomcat release the thread while waiting.
- The DispatcherServlet is created **lazily by default** (`load-on-startup=-1`), so the very first request is slower, because it initializes its strategies. Set `spring.mvc.servlet.load-on-startup=1` if you want that cost at startup.

---

# Try it yourself

**1. Watch the DispatcherServlet wake up:**
Start your Spring Boot app and look at the logs. After the first request you'll see something like:
```
Initializing Servlet 'dispatcherServlet'
Completed initialization in 12 ms
```

**2. See the dispatch decisions in the logs:**
```properties
logging.level.org.springframework.web.servlet.DispatcherServlet=DEBUG
```
Then `curl http://localhost:8080/users/1`. You'll see lines showing the request (`GET "/users/1"`), which handler it mapped to, and the final status (`Completed 200 OK`).

**3. See every route Spring knows about:**
Add Actuator and expose the mappings endpoint:
```properties
management.endpoints.web.exposure.include=mappings
```
```bash
curl -s http://localhost:8080/actuator/mappings | head -50
```
You'll see the `dispatcherServlets` section, the lookup table from Step 1. Only expose this in development, since it reveals your whole API surface.

**4. Trigger each mapping failure:**
```bash
curl -i http://localhost:8080/nope                       # 404 (no handler)
curl -i -X DELETE http://localhost:8080/users/1          # 405 if DELETE isn't mapped
curl -i -X POST http://localhost:8080/users -H "Content-Type: text/plain" -d "hi"   # 415
curl -i -H "Accept: image/png" http://localhost:8080/users/1   # 406
curl -i http://localhost:8080/users/abc                  # 400 (type mismatch)
```
Every status here comes from a different step of the dispatch you just learned.

**5. Prove the order of filters and interceptors:**
Add the `TimingInterceptor` from Part 4, plus a tiny filter that logs "filter in" and "filter out". Call any endpoint and read the logs. You should see: filter in, then the interceptor's `preHandle`, then your controller, then `afterCompletion`, then filter out.

**6. Peek inside with a debugger (the best lesson of all):**
In IntelliJ, put a breakpoint on the first line of your controller method, call it with `curl`, and look at the **call stack**. You'll see `DispatcherServlet.doDispatch`, then `RequestMappingHandlerAdapter.handle`, then your method, and below them Tomcat's classes and the filter chain. Click through frames to watch the flow from this lesson.

**7. See two kinds of response paths:**
Make one `@RestController` endpoint returning an object (JSON) and one `@Controller` returning a view name. Compare the `Content-Type` headers with `curl -i`. You've just seen the two return-value modes.

---

# Common mistakes

| Mistake | Why it hurts | Fix |
|---|---|---|
| Expecting `@ControllerAdvice` to catch security errors | Security filters run before the DispatcherServlet | Use `AuthenticationEntryPoint` and `AccessDeniedHandler` |
| Storing per-request data in interceptor or controller fields | One instance serves all threads, so requests overwrite each other | Use request attributes or local variables |
| Trying to modify the body in `postHandle` for `@ResponseBody` | The response is already written | Use a `ResponseBodyAdvice` or do it in the controller |
| Declaring an interceptor as `@Component` and expecting it to run | It must also be registered | Add it in `WebMvcConfigurer.addInterceptors` |
| Using an interceptor for something that needs to cover static files and error pages | Interceptors only see MVC-handled requests | Use a filter |
| Mapping the servlet to `/*` in custom config | Hides static resources and `/error` | Keep the default `/` mapping |
| Confusing `server.servlet.context-path` and `spring.mvc.servlet.path` | URLs end up with the wrong prefix | Context path = the whole app, servlet path = the DispatcherServlet |
| Doing slow work directly in controllers | Holds a Tomcat thread | Timeouts, virtual threads, async |
| Leaving `/actuator/mappings` open in production | Leaks your API structure | Restrict or don't expose it |
| Throwing exceptions in filters and expecting JSON error bodies from `@RestControllerAdvice` | The advice never sees them | Handle errors where they occur or use dedicated handlers |

---

## Related concept, briefly

**`DispatcherHandler` in WebFlux:** Spring's reactive stack has no servlets. Its front controller is called `DispatcherHandler`, and it follows the same idea (handler mappings, adapters, result handlers), but it runs on Netty or another non-blocking server and returns `Mono` and `Flux` instead of blocking a thread. Once you understand the DispatcherServlet, the reactive version is the same story told with different class names.

---

## The whole picture

| Question | Answer |
|---|---|
| What is it? | The single front-door servlet of Spring MVC (Front Controller pattern) |
| Who creates it in Boot? | Auto-configuration, mapped to `/` |
| What are its main steps? | Find handler, run interceptors, call it via an adapter, handle the return value, handle errors |
| What finds your controller? | `HandlerMapping` (`RequestMappingHandlerMapping` for annotations) |
| What calls your method? | `HandlerAdapter` (`RequestMappingHandlerAdapter`) |
| What fills your method parameters? | Argument resolvers and type converters |
| How does a returned object become JSON? | `HttpMessageConverter` (Jackson) |
| How do exceptions become responses? | `HandlerExceptionResolver`s (`@ExceptionHandler`, `@ControllerAdvice`) |
| Filter or interceptor? | Filter = container level, before it. Interceptor = Spring level, inside it, knows the handler. |
| Where is Spring Security? | In filters, **before** the DispatcherServlet |
| Is it thread-safe? | It's a singleton, so yes, if you keep request state out of shared fields |
| Why 404, 405, 406, 415? | They come out of the handler mapping step |




[[Spring Security]]