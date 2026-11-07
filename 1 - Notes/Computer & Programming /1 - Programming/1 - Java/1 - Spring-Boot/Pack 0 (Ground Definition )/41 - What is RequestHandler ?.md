

A **request handler** is the piece of code that actually deals with one incoming web request. A request arrives (say `GET /movies/5`), something has to decide _who_ answers it, and that "who" is the handler. In Spring Boot, 99% of the time your handler is a method in a controller class, such as a method annotated with `@GetMapping`. The framework finds it, calls it with the right arguments, and turns whatever it returns into an HTTP response.

**MVC (Model-View-Controller)** is the design pattern that decides how a web app is split up so it doesn't turn into one giant mess. The Model holds the data and rules, the View is what the user sees, and the Controller sits in the middle, receives requests, and coordinates the other two. The two ideas fit together: in Spring MVC, the _controller_ is the class, and the _request handler_ is the specific method inside it that serves one URL. Let's build both from the ground up.

---

## Part 1: MVC, the three roles

Think of a restaurant. You (the user) tell the waiter what you want. The waiter goes to the kitchen, gets the food, and brings it to your table on a plate.

|MVC part|Restaurant|In Spring Boot|Its one job|
|---|---|---|---|
|**Model**|The kitchen and its ingredients|Entities, services, repositories, DTOs|Holds data and business rules|
|**View**|The plate you see|Thymeleaf/HTML page, or JSON in a REST API|Shows data to the user|
|**Controller**|The waiter|`@Controller` / `@RestController` classes|Takes the request, asks the Model, picks the View|

The golden rule is that each part knows as little as possible about the others. The View never talks to the database, and the Controller never builds HTML by hand. That is why you can redesign a page without touching your business logic.

**Why it matters in practice:** if tomorrow you want a mobile app instead of a website, your Model stays exactly the same. Only the View changes (JSON instead of HTML).

---

## Part 2: What "handler" means

Inside a web framework, a request goes through several stages. The word _handler_ names the final destination of that journey. Here is the full trip in Spring MVC:

```
Browser
  │  GET /movies/5
  ▼
DispatcherServlet          ← the front door (one for the whole app)
  │  "who handles this?"
  ▼
HandlerMapping             ← the phone book: URL → handler
  │  "MovieController.getMovie()"
  ▼
HandlerInterceptors        ← optional checkpoints before/after
  ▼
HandlerAdapter             ← the translator that knows how to call it
  │
  ▼
YOUR HANDLER METHOD        ← the code you write
  │  returns a Movie object (or a view name)
  ▼
HttpMessageConverter       ← Movie → JSON   (REST)
   or ViewResolver         ← "movies" → movies.html   (pages)
  │
  ▼
Browser gets the response
```

Each actor has one small job:

|Actor|What it does|Analogy|
|---|---|---|
|**DispatcherServlet**|Receives every request first and coordinates the rest|Reception desk|
|**HandlerMapping**|Looks at the URL and HTTP method and finds the matching handler|Directory board in a building|
|**HandlerAdapter**|Calls the handler, filling in its arguments (`@PathVariable`, `@RequestBody`...)|Interpreter between the framework and your method|
|**Handler**|Your method. Does the actual work|The person you came to see|
|**ViewResolver / HttpMessageConverter**|Turns the result into HTML or JSON|The printer|

You might ask why an adapter is needed at all. Spring supports several _kinds_ of handlers (annotated methods, old-style `Controller` interface, plain `HttpRequestHandler`), and each is called differently. The adapter hides that difference, so the DispatcherServlet can treat them all the same.

---

## Part 3: Seeing it in code

```java
@RestController                        // 1
@RequestMapping("/movies")             // 2
public class MovieController {

    private final MovieService service;

    public MovieController(MovieService service) {   // 3
        this.service = service;
    }

    @GetMapping("/{id}")                             // 4
    public MovieDto getMovie(@PathVariable Long id) { // 5
        return service.findById(id);                 // 6
    }
}
```

Line by line:

1. `@RestController` marks the class as a controller whose methods return data (JSON) directly instead of page names.
2. `@RequestMapping("/movies")` gives every handler in this class the base path `/movies`.
3. The service comes in through the constructor (this is the Model side being injected into the Controller).
4. `@GetMapping("/{id}")` is the registration for the handler. At startup, Spring records: **`GET /movies/{id}` → `getMovie`**. This record is what HandlerMapping consults later.
5. `getMovie` is the **handler method**. `@PathVariable Long id` tells the adapter, "take the `5` from `/movies/5` and pass it in as `id`."
6. The method asks the Model (service) for data and returns it. It does not write JSON itself; the message converter does that.

So when `GET /movies/5` arrives, the story is: DispatcherServlet receives it → HandlerMapping finds `getMovie` → HandlerAdapter calls `getMovie(5L)` → the returned `MovieDto` becomes JSON.

### The same flow with a View (classic MVC)

```java
@Controller
public class MoviePageController {

    @GetMapping("/movies/{id}")
    public String showMovie(@PathVariable Long id, Model model) {
        model.addAttribute("movie", service.findById(id));  // fill the Model
        return "movie-details";                              // name of the View
    }
}
```

Here all three MVC letters are visible at once:

- **Model**: the `Model` object carries data to the page.
- **View**: `"movie-details"` is resolved to `movie-details.html` (a Thymeleaf template).
- **Controller**: `showMovie`, the handler, wires them together.

The only difference between the two examples is the return: `@RestController` skips the View and writes the data straight into the response.

---

## Part 4: What can a handler receive and return?

The adapter is flexible about your method's parameters. Some common ones:

|You write|The framework gives you|
|---|---|
|`@PathVariable Long id`|The `{id}` part of the URL|
|`@RequestParam String q`|Query string `?q=...`|
|`@RequestBody MovieDto dto`|The JSON body, converted to an object|
|`@RequestHeader("Authorization")`|A header value|
|`HttpServletRequest request`|The raw servlet request|
|`Principal principal`|The logged-in user|

And for return values:

|You return|Result|
|---|---|
|An object (`@RestController`)|JSON body|
|A `String` (`@Controller`)|View name|
|`ResponseEntity<T>`|Full control: status, headers, body|
|`void`|Empty response (often with `@ResponseStatus`)|

---

## Part 5: Other meanings of "request handler"

The word shows up in more than one place, so here is how to tell them apart:

- **Spring MVC handler** (everything above): usually a `@RequestMapping`-style method.
- **`HttpRequestHandler`**: a tiny Spring interface with one method, `handleRequest(request, response)`. No mapping magic, just raw request and response. Used for things like serving static resources.
- **Servlet**: the lower-level Java standard. A `HttpServlet` with `doGet`/`doPost` _is_ a request handler. Spring's DispatcherServlet is itself one servlet that then hands work to your handler methods.
- **Handler in other frameworks** (Node, Go, etc.): the same idea, "the function that answers this route."

---

## Part 6: A small related concept: Interceptors

A **HandlerInterceptor** is a checkpoint that runs _around_ your handler: `preHandle` (before), `postHandle` (after, before the view), `afterCompletion` (at the very end). It is handy for logging or timing requests. It is not the same as a servlet **Filter**: filters run earlier, before the DispatcherServlet even sees the request (that is where Spring Security lives), while interceptors run inside Spring MVC and know which handler is about to be called.

---

## Common mistakes

1. **Putting business logic in the handler.** A handler should be thin: read the input, call a service, return the result. Rules and database work belong in the Model side.
2. **Mixing `@Controller` and `@RestController`.** If you return a `String` from a `@Controller` expecting text, Spring will hunt for a view with that name.
3. **Two handlers with the same URL and method.** The app fails at startup with an "ambiguous mapping" error.
4. **Returning entities directly.** Prefer DTOs so your database shape doesn't leak into your API.

---

## Quick recap

- **MVC** splits an app into Model (data and rules), View (display), and Controller (coordinator).
- A **request handler** is the code that answers one specific request. In Spring it's a controller method found through `HandlerMapping` and called by a `HandlerAdapter`.
- Every request goes: **DispatcherServlet → HandlerMapping → (interceptors) → HandlerAdapter → your handler → converter/view resolver → response**.
- Keep handlers thin. Let services do the real work.




[[Spring Framework]]