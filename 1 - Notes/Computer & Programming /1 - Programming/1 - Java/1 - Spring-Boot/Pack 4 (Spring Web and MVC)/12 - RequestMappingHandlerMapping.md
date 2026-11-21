

This is the concrete class behind the **"Handler Mapping" + "Mapping registry"** boxes in your diagram. Last time I said it "scans annotations and builds a table." Now we open it up.

## 1. Core intuition

**Analogy:** it is a **librarian who catalogues the library before opening**. At startup, they go through every shelf (your beans), write an index card for each method (`GET /users/{id}` → `UserController.get`), and file the cards. During the day, when a request arrives, they only look up cards, they never re-scan the shelves.

Its job, in one line: **given an HTTP request, return the `@Controller` method that should handle it.** It doesn't call the method (that's the HandlerAdapter) and it doesn't touch JSON.

The name decodes as: **RequestMapping** (handles `@RequestMapping` and its shortcuts `@GetMapping`, `@PostMapping`, ...) + **HandlerMapping** (the interface "request → handler").

## 2. Two phases

```
STARTUP (once)                         REQUEST TIME (every request)
──────────────                         ────────────────────────────
scan beans                             read method, path, headers
  → find @Controller methods             → look up the registry
  → build a RequestMappingInfo           → pick the best match
  → store in the registry                → return HandlerExecutionChain
  → clash? app fails to start            → no match? 404 / 405 / 415 / 406
```

## 3. Startup: how the cards are written

`RequestMappingHandlerMapping` extends `AbstractHandlerMethodMapping`, which implements `InitializingBean`. So right after the bean is created, Spring calls `afterPropertiesSet()`, which does roughly this:

1. Loop over **every bean** in the context.
2. Keep only those that are handlers: the class has `@Controller` (so `@RestController` too) or `@RequestMapping` on the type.
3. For each method with a mapping annotation, build a **`RequestMappingInfo`**: the "index card."
4. Combine class-level and method-level annotations. Class `@RequestMapping("/somepath")` + method `@GetMapping("/{name}/{id}")` gives `/somepath/{name}/{id}`.
5. Register it in the internal **`MappingRegistry`**, which holds `RequestMappingInfo → HandlerMethod`. **This is the "Mapping registry" box in your slide.** Uniqueness is enforced here: a duplicate throws `Ambiguous mapping` immediately.

A `HandlerMethod` is just the target: the bean instance + the `java.lang.reflect.Method`.

## 4. What a `RequestMappingInfo` really contains

It isn't just a path. It is a bundle of **conditions**, and a request must satisfy **all** of them:

|Condition|Comes from|Example|
|---|---|---|
|Path patterns|`path` / `value`|`/users/{id}`|
|HTTP methods|`method`, or `@GetMapping`|`GET`|
|Params|`params`|`active=true`|
|Headers|`headers`|`X-Client=mobile`|
|Consumes|`consumes`|request `Content-Type: application/json`|
|Produces|`produces`|request `Accept: text/csv`|
|**Version** (Spring 7 / Boot 4)|`version`|`"2"`|

This is why the slide's rule "Method + Path + ..." is only the beginning of the story. Two mappings clash only if **every** condition is identical.

## 5. Request time: how the lookup works

Inside `lookupHandlerMethod(...)`:

1. **Fast path:** if a mapping has a plain path with no `{variables}` or wildcards (like `/users`), it sits in a hash lookup and is found instantly.
2. **Candidates:** otherwise, check all registered mappings and collect those whose conditions **all** match the request.
3. **Rank:** if several match, sort them by specificity. A literal beats a variable, fewer wildcards beat more, and so on.
4. **Compare the top two.** If they are equally specific, throw `IllegalStateException: Ambiguous handler methods mapped for ...` (this is the _request-time_ twin of the startup error, and it can happen with overlapping wildcard patterns).
5. Return the winner. The path variables (`{id}`) are extracted and stored on the request for `@PathVariable` to use later.

Then the parent class, `AbstractHandlerMapping.getHandler()`, wraps the result into a **`HandlerExecutionChain`**: the `HandlerMethod` + matching **interceptors** (+ CORS handling). That chain is what goes back to the DispatcherServlet (step ④ in your slide).

## 6. Why you get different error codes

When **no** card fully matches, the class inspects _partial_ matches to choose the most helpful error:

|Situation|Status|
|---|---|
|Path exists, but not for this HTTP method|`405` Method Not Allowed|
|Path+method match, but body `Content-Type` isn't accepted|`415` Unsupported Media Type|
|Path+method match, but no producible type fits `Accept`|`406` Not Acceptable|
|Required `params` condition missing|`400`|
|Nothing matches the path|`404`|

This is the real source of the `415` and `405` I listed in the earlier request-flow lesson.

## 7. See it with your own eyes

Inject the bean and print the registry:

```java
@Component
public class MappingPrinter implements CommandLineRunner {

    private final RequestMappingHandlerMapping mapping;

    public MappingPrinter(@Qualifier("requestMappingHandlerMapping")
                          RequestMappingHandlerMapping mapping) {
        this.mapping = mapping;
    }

    @Override
    public void run(String... args) {
        mapping.getHandlerMethods().forEach((info, method) ->
            System.out.println(info + "  →  " + method));
    }
}
```

Output looks like:

```
{GET [/somepath/{name}/{id}]}  →  DemoController#get(String, Integer)
{POST [/somepath/{name}/{id}]} →  DemoController#post(String, Integer)
```

(The `@Qualifier` is needed because Spring MVC registers more than one `HandlerMapping` bean of related types.) The same data is exposed at `/actuator/mappings` if you add Actuator.

## 8. Registering a mapping **without** annotations

Because the registry is just an API, you can add routes programmatically (rarely needed, but it shows there is no magic):

```java
@Configuration
public class DynamicRoutes {

    @Bean
    ApplicationRunner register(@Qualifier("requestMappingHandlerMapping")
                               RequestMappingHandlerMapping mapping,
                               PingController controller) throws Exception {
        return args -> {
            RequestMappingInfo info = RequestMappingInfo
                    .paths("/ping").methods(RequestMethod.GET).build();
            mapping.registerMapping(info, controller,
                    PingController.class.getMethod("ping"));
        };
    }
}
```

## 9. It is not the only HandlerMapping

The DispatcherServlet holds a **list** of mappings and asks each in order until one answers. That is why `/` can serve static files and `/users` can hit your controller:

|HandlerMapping|Handles|
|---|---|
|**`RequestMappingHandlerMapping`**|`@Controller` methods (your code)|
|`RouterFunctionMapping`|functional endpoints (`RouterFunction`)|
|`BeanNameUrlHandlerMapping`|beans named like a URL (legacy)|
|`SimpleUrlHandlerMapping` + `WelcomePageHandlerMapping`|static resources, `index.html`|

`RequestMappingHandlerMapping` has the highest priority, so your annotated controllers win over static resources.

## 10. Boot 4 / Spring 7 relevance

- **API versioning** is enforced here as the `version` condition from section 4. You choose how to read the version (header, path segment, query parameter, media type) in configuration, and the mapping class applies it, so `version = "1"` and `version = "2"` for the same path can coexist.
- Path matching uses the **`PathPatternParser`** (fast, pre-parsed patterns), which has been the default since Spring Boot 2.6. The older `AntPathMatcher` style is legacy.

## 11. Gotchas

1. **A `@Controller` bean must be a Spring bean.** A class with `@GetMapping` methods but no `@Controller`/`@RestController`/`@RequestMapping` on the type is silently **ignored**. This is a very common reason for "my endpoint returns 404."
2. **Scanning is limited to your component-scan area.** A controller in a package _above_ the `@SpringBootApplication` class isn't found.
3. **Trailing slash:** since Spring 6, `/users` and `/users/` are **different** paths by default. `/users/` returns `404` if only `/users` is mapped.
4. **Two annotations can't be hidden by inheritance rules the way you expect.** If an interface and its implementation both declare mappings, put them in one place only.
5. **The registry is fixed after startup** (unless you register programmatically), so a request costs a lookup, never a reflection scan. That's why Spring MVC routing is fast.
6. **Startup errors beat runtime errors.** The `Ambiguous mapping` at boot (identical conditions) is safe. The runtime `Ambiguous handler methods` (overlapping patterns like `/a/{x}` vs `/{y}/b` for `/a/b`) can appear only when a request hits that overlap, so test those routes.

## 12. Summary

> `RequestMappingHandlerMapping` is a **startup-built index** of every annotated controller method, keyed by a bundle of conditions (path, method, params, headers, consumes, produces, version). At request time it finds the single best match, wraps it with interceptors into a `HandlerExecutionChain`, and hands it back to the DispatcherServlet.




[[Spring Framework]]