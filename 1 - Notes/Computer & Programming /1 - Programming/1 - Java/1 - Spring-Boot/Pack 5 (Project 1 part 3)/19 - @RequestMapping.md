
[[2 - CRUD with Spring MVC Annotations]]


You've seen its parameters (`path`, `method`, `params`, `headers`, `consumes`, `produces`, `name`) and its shortcuts (`@GetMapping`, etc.), so this lesson doesn't repeat them. It covers what `@RequestMapping` is in the framework, how Spring uses it, and the rules for combining it across class and method.

## Mental model: the building directory

A large building has a directory board in the lobby: "Dentist → floor 3, room 12". `@RequestMapping` is how every controller method registers itself on that board. At startup Spring reads all the registrations, and at runtime `DispatcherServlet` looks up each incoming request on the board to find the method to run.

## Definition

`@RequestMapping` is the **base annotation for routing** in Spring MVC. It declares which requests a class or method handles. Every other mapping annotation is built on it:

```java
@Target({ElementType.METHOD})
@RequestMapping(method = RequestMethod.GET)   // the only thing @GetMapping adds
public @interface GetMapping { ... }
```

`@GetMapping` is a **meta-annotation**: `@RequestMapping` with `method` pre-filled. That's why it has the same attributes minus `method`, and why the two are interchangeable at runtime.

## How it works inside

**At startup** (once):

1. `RequestMappingHandlerMapping` scans every bean. A class counts as a handler if it has `@Controller` (which `@RestController` includes) or `@RequestMapping` on the type.
2. For each method, it builds a `RequestMappingInfo`: an object holding all the conditions (path patterns, methods, params, headers, consumes, produces), merged from class level and method level.
3. It stores them in a registry. If two methods end up with an identical `RequestMappingInfo`, the app **refuses to start** (`Ambiguous mapping`).

**On each request:**

1. Look up candidates by path.
2. Filter by the other conditions, in effect checking the `method`, `params`, `headers`, `consumes` and `produces` conditions.
3. If several remain, pick the most specific (`/users/me` beats `/users/{id}`, and a mapping with extra conditions beats one without).
4. If none remain, the rejection reason decides the error: 404 (no path), 405 (wrong verb), 415 (`consumes`), 406 (`produces`), 400 (`params`/`headers`).

The sorting is why Spring can tell you _which_ check failed instead of a generic 404.

## Class level vs method level

```java
@RestController
@RequestMapping(path = "/api/products", produces = MediaType.APPLICATION_JSON_VALUE)
public class ProductController {

    @GetMapping("/{id}")                                // → GET /api/products/{id}
    public ProductResponse one(@PathVariable Long id) { ... }

    @GetMapping(path = "/{id}/label", produces = MediaType.TEXT_PLAIN_VALUE)  // overrides class produces
    public String label(@PathVariable Long id) { ... }
}
```

How the two levels merge:

|Attribute|Rule|Result|
|---|---|---|
|`path`|**concatenated**|`/api/products` + `/{id}`|
|`method`|**union**|class `GET` + method `POST` means either verb matches. Rarely useful, so put `method` on methods only|
|`params`, `headers`|**both must hold**|class requires `X-Tenant`, so every method does too|
|`consumes`, `produces`|**method overrides class**|not merged|

Putting `@RequestMapping` on the class is only useful for shared prefix and shared `produces`/`headers`. On a method, prefer the shortcut annotations.

## When to use `@RequestMapping` instead of the shortcuts

1. **On the class**, for the shared prefix. This is its main job today.
2. **One method, several verbs:**
    
    ```java
    @RequestMapping(path = "/users/{id}", method = {RequestMethod.PUT, RequestMethod.PATCH})
    ```
    
3. **A catch-all fallback** for any verb on a path (rare):
    
    ```java
    @RequestMapping("/legacy/**")
    ```
    
4. **Custom composed annotations**, because it works as a meta-annotation:
    
    ```java
    @Target(ElementType.METHOD)@Retention(RetentionPolicy.RUNTIME)@PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE,             produces = MediaType.APPLICATION_JSON_VALUE)public @interface JsonPost {    @AliasFor(annotation = PostMapping.class, attribute = "path")    String[] value() default {};}
    ```
    
    Now `@JsonPost("/orders")` replaces repeating the same two attributes everywhere.

## What if we don't use it at class level?

```java
@GetMapping("/api/products")        // prefix repeated
@GetMapping("/api/products/{id}")   // on every method
@PutMapping("/api/products/{id}")
```

It works, but a typo in one prefix makes that single endpoint 404 while the others work, and changing `/api` to `/api/v2` means editing every method.

## Nuances and gotchas

**1. Paths don't need the leading slash on the method.** `@GetMapping("{id}")` is joined with a `/` automatically, but writing it explicitly is clearer.

**2. Trailing slashes.** In Spring 6 / Boot 3+, `/api/products/` does **not** match `/api/products`. Older tutorials assumed it did.

**3. Pattern syntax is `PathPattern`, not Ant.** `*` matches one segment, `**` matches many but **only at the end** of the pattern, and `{*rest}` captures the remainder. `/files/**/edit` is invalid in Spring 6.

**4. `@RequestMapping` on an interface.** Annotations on interface methods are inherited by the implementing controller. This is how Feign clients and API-first generated code (OpenAPI) share contracts. It works, but keeping them on the class is clearer.

**5. A `@RequestMapping` bean without `@Controller`.** `@RequestMapping` on a class alone is enough to register it as a handler, but without `@Component`-family stereotypes it isn't a bean, so nothing happens. Use `@RestController`.

**6. Same mapping in two places crashes at startup**, which is a good thing. The error names both methods.

**7. Don't put `{placeholders}` in the class path unless every method uses them.** `/api/users/{userId}/orders` on the class means each method must either bind `userId` or ignore it deliberately.

**8. Debugging: see every registered mapping.**

```properties
# application.properties
management.endpoints.web.exposure.include=mappings
logging.level.org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping=TRACE
```

With Actuator on the classpath, `GET /actuator/mappings` lists every route and its conditions, which is the first place to look when an endpoint "doesn't exist".

**9. API versioning is becoming built in.** Header-based versioning with `headers = "X-API-VERSION=2"` works everywhere, as you saw. Spring Framework 7 / Boot 4 also adds first-class versioning support with a `version` attribute on mappings. Check which Spring Boot version you're on before relying on it.

## Quick reference

|You want|Use|
|---|---|
|Shared prefix for a controller|`@RequestMapping("/api/products")` on the class|
|One verb on one method|`@GetMapping`, `@PostMapping`, `@PutMapping`, `@PatchMapping`, `@DeleteMapping`|
|Several verbs on one method|`@RequestMapping(method = {...})`|
|Version by header|`headers = "X-API-VERSION=2"`|
|Reusable combination of attributes|custom annotation composed from a mapping annotation|
|See what's registered|`/actuator/mappings`|

## How it fits the big picture

```
@RequestMapping (base)
   ├── @GetMapping     = method GET
   ├── @PostMapping    = method POST
   ├── @PutMapping     = method PUT
   ├── @PatchMapping   = method PATCH
   └── @DeleteMapping  = method DELETE
```

`@RequestMapping` says which requests reach a method. `@PathVariable`, `@RequestParam`, `@RequestBody` and `@RequestHeader` then read the data out of those requests, and `ResponseEntity` / `@ResponseStatus` shape what goes back.



[[Spring Framework]]