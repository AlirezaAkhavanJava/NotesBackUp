


`@ControllerAdvice` is a class-level annotation that turns an ordinary class into a **global advice component** for your controllers — instead of writing the same cross-cutting logic (exception handling, shared model data, custom data binding rules) separately inside every `@Controller`, you write it once in a `@ControllerAdvice` class, and Spring applies it across all (or a targeted subset of) controllers automatically. It's a form of the advice concept you've seen in Spring AOP: logic that wraps around your controllers without you having to touch each one.

It supports three distinct kinds of cross-cutting behavior, and `@ExceptionHandler` methods (which you already know) are only one of them:

## 1. Global exception handling

This is the one you've already worked with — an `@ExceptionHandler` method inside a `@ControllerAdvice` class catches exceptions thrown by any controller, not just the one it's declared in:

```java
@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<String> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ex.getMessage());
    }
}
```

Nothing new here beyond what you've already learned about `@ExceptionHandler` and `MethodArgumentNotValidException` — the only difference is _where_ the method lives.

## 2. Global `@ModelAttribute` methods

A `@ModelAttribute` method inside a `@ControllerAdvice` class adds data to the model for **every** request handled by **every** controller, before any controller method runs:

```java
@ControllerAdvice
public class GlobalModelAttributes {

    @ModelAttribute("appVersion")
    public String appVersion() {
        return "2.3.1";
    }
}
```

Now any view rendered by any `@Controller` in the app automatically has `appVersion` available, without each controller method needing to add it to its own `Model` parameter. This matters for traditional MVC apps serving HTML views (think a site-wide footer value, or the currently logged-in user's display name shown in every page's header) — it has no effect in a pure REST API, since there's no view being rendered.

## 3. Global `@InitBinder` methods

An `@InitBinder` method customizes how Spring converts incoming request parameters into Java types, for every controller:

```java
@ControllerAdvice
public class GlobalBindingConfig {

    @InitBinder
    public void initBinder(WebDataBinder binder) {
        binder.registerCustomEditor(LocalDate.class,
                new CustomDateEditor(new SimpleDateFormat("yyyy-MM-dd"), false));
    }
}
```

This tells Spring, app-wide, how to parse a `String` like `"2026-11-10"` into a `LocalDate` whenever such a parameter shows up as a controller argument — again, without repeating the setup in every controller.

## Targeting which controllers it applies to

By default, a `@ControllerAdvice` class applies to _every_ controller in the application context. You can narrow that with attributes on the annotation itself:

```java
@ControllerAdvice(basePackages = "com.example.demo.admin")
public class AdminExceptionHandler { ... }

@ControllerAdvice(assignableTypes = { UserController.class, OrderController.class })
public class SpecificControllerAdvice { ... }
```

`basePackages` restricts it to controllers in a given package; `assignableTypes` restricts it to specific controller classes by name. This is useful when you don't want, say, an admin-only error format leaking into public-facing endpoints.

## @ControllerAdvice vs @RestControllerAdvice

The difference is exactly the same relationship as `@Controller` vs `@RestController`:

- `@ControllerAdvice` — the methods inside behave as they would in a `@Controller`: a returned `String` is treated as a view name to render, a returned object needs an explicit `@ResponseBody` to be serialized as JSON.
- `@RestControllerAdvice` — effectively `@ControllerAdvice` + `@ResponseBody` applied to every method inside it, so a returned object is serialized directly into the response body. This is the one you want for a REST API, which is why your own `ApiExceptionHandler` uses it.

Since your project is a REST API, `@RestControllerAdvice` is the correct choice for exception handling — `@ControllerAdvice` on its own would require adding `@ResponseBody` to every handler method to get JSON output instead of Spring trying to resolve a view name.


[[Spring Framework]]
[[Exception]]