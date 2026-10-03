In **Spring**, `@ResponseBody` tells Spring that the **return value of a method should be written directly to the HTTP response body** (instead of being interpreted as a view name).

Basically: it’s how you return **raw data** (JSON, XML, text, etc.) from a controller.

Example:

```java
@RestController
public class EmployeeController {

    @GetMapping("/employee/{id}")
    @ResponseBody
    public Employee getEmployee(@PathVariable Long id) {
        // The Employee object will be converted to JSON automatically
        return employeeService.findById(id);
    }
}
```

Key points:

- `@RestController` **already includes `@ResponseBody`**, so you don’t need it on each method.
- Without `@ResponseBody`, Spring would try to find a **view template** with the name of the returned object.


  >Tip: Use `@ResponseBody` when you **only want raw data**, not HTML pages.

---

## Mental model: two exits from a controller

Every controller method hands back something, and Spring needs to decide what to do with it. There are two exits:

```
return value ──►  Exit A: "it's a VIEW NAME"   → ViewResolver → HTML template (Thymeleaf)
              ──►  Exit B: "it's the BODY"       → HttpMessageConverter → bytes in the response
```

`@ResponseBody` is the **switch** that sends the return value to Exit B. Without it, plain `@Controller` methods default to Exit A, because Spring MVC was originally built for server-rendered pages.

## What happens inside (the "why it works")

1. Your method returns a value (`Employee`).
2. Spring MVC asks its list of **return value handlers**: "who can handle this?"
3. It sees `@ResponseBody` (on the method or class), so `RequestResponseBodyMethodProcessor` takes it. (The same class handles `@RequestBody` on the way in, so it's the same machinery in both directions.)
4. That handler asks the list of **`HttpMessageConverter`s**: "who can write this type, in a format the client accepts?" It compares the Java type and the request's `Accept` header.
5. The winning converter serializes the value and sets `Content-Type`.

The converters in play, roughly in order:

|Return type|Converter|Result|
|---|---|---|
|`String`|`StringHttpMessageConverter`|raw text, **no quotes, no JSON encoding**|
|`byte[]`|`ByteArrayHttpMessageConverter`|raw bytes|
|`Resource`|`ResourceHttpMessageConverter`|file stream|
|Objects, `List`, `Map`, records|`MappingJackson2HttpMessageConverter`|JSON|

The order matters: `String` is checked **before** Jackson. That's why returning `"hello"` gives you `hello`, not `"hello"`.

## Where it can be placed

```java
// 1. On a method: only that method returns data
@Controller
public class MixedController {

    @GetMapping("/home")
    public String home() {
        return "home";                 // → templates/home.html (Exit A)
    }

    @GetMapping("/api/ping")
    @ResponseBody
    public Map<String, String> ping() {
        return Map.of("status", "ok"); // → JSON (Exit B)
    }
}

// 2. On the class: every method returns data
@Controller
@ResponseBody
public class ApiController { ... }

// 3. Via @RestController: exactly the same as option 2
@RestController
public class ApiController { ... }
```

`@RestController` is simply `@Controller + @ResponseBody` stacked as a **meta-annotation**. The same trick exists in error handling: `@RestControllerAdvice` is `@ControllerAdvice + @ResponseBody`, which is why your `@ExceptionHandler` methods returned JSON/`ProblemDetail` earlier without any extra annotation.

## What if we don't use it? (the same method, two ways)

```java
@Controller
public class DemoController {

    @GetMapping("/hello")
    public String hello() {
        return "hello";
    }
}
```

Spring treats `"hello"` as a **template name** and looks for `templates/hello.html`. With no matching template you get an error page (a 500 `TemplateInputException` with Thymeleaf, or a 404 Whitelabel page without a view engine). With `@ResponseBody` the browser shows the text `hello`.

For an object, it's worse:

```java
@Controller
public class DemoController {

    @GetMapping("/employee/1")
    public Employee get() {         // no @ResponseBody
        return new Employee(...);   // Spring tries to guess a view name from the URL → error
    }
}
```

## `@ResponseBody` vs `ResponseEntity`

You learned `ResponseEntity` last. They solve different problems:

||`@ResponseBody`|`ResponseEntity<T>`|
|---|---|---|
|Controls|**body only** (serialization switch)|body **+ status + headers**|
|Status|always 200 (unless `@ResponseStatus`)|any, decided at runtime|
|Needs `@ResponseBody`?|it _is_ it|**No**, handled by a different processor (`HttpEntityMethodProcessor`)|

So inside a `@RestController` you can mix them freely: plain return for simple 200s, `ResponseEntity` when you need status or headers.

## Nuances and gotchas

**1. `String` is not JSON.** `return "hello"` gives `hello` with `Content-Type: text/plain` (or whatever the client accepted). If you want a JSON string, return an object or a `Map`. Another consequence: if the string _already is_ JSON, it's written as-is and not escaped.

**2. A redirect string is just text.** In a `@Controller` without `@ResponseBody`, `return "redirect:/login"` triggers a redirect. With `@ResponseBody` (or in a `@RestController`) the client literally receives the text `redirect:/login`. To redirect from a REST controller, use `ResponseEntity.status(HttpStatus.FOUND).location(uri).build()`.

**3. `void` and `null`.** Returning `null` or `void` from a body method gives **200 with an empty body**, not 404. If "not found" matters, throw an exception or return `ResponseEntity.notFound()`.

**4. Unsupported `Accept` → 406.** If the client sends `Accept: application/xml` and no XML converter is on the classpath, Spring answers **406 Not Acceptable** (`HttpMediaTypeNotAcceptableException`). Adding `jackson-dataformat-xml` to your dependencies makes XML work automatically with no code change, which shows how generic this machinery is.

**5. Serialization can fail _after_ your method succeeded.** If your return value can't be written, you get `HttpMessageNotWritableException` → 500. The classic causes, both with JPA entities:

- **Bidirectional relationships** (`User` has `orders`, `Order` has `user`): Jackson loops forever (infinite recursion).
- **Lazy-loaded fields** accessed after the session closed.

This is another reason to return DTOs, not entities.

**6. Status is decided before you can change it.** Once Spring begins writing the body, the status line and headers are already committed. An exception thrown mid-serialization can't turn into a clean 4xx/5xx for that response.

**7. `produces` fixes the format.** `@GetMapping(produces = "text/html") @ResponseBody` lets you return a raw HTML string, which is useful for tiny pages, but a template engine is better for real ones.

**8. It affects only the output.** `@ResponseBody` has nothing to do with reading input. The inbound twin is `@RequestBody`, and both go through the same converters.

## Quick reference

|Situation|Use|
|---|---|
|Whole class is a JSON API|`@RestController`|
|Mostly HTML pages, one JSON endpoint|`@Controller` + `@ResponseBody` on that method|
|Need a custom status or headers|`ResponseEntity<T>`|
|Error responses as JSON|`@RestControllerAdvice`|
|Want to see which converter ran|set `logging.level.org.springframework.web=DEBUG` and read the log|




[[Spring Framework]]