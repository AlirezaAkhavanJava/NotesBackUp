

We've used `@RestController` throughout this entire series without stopping to explain its parent annotation, `@Controller`, or why Spring has _two_ separate annotations for what looks like the same job. This distinction matters — it's the difference between returning JSON and returning a rendered HTML page, and it connects directly back to the UI architecture options we covered early in this series.

---

## 1. The Core Idea — `@Controller` Returns _View Names_, Not Data

Back in the High-Level Architecture tutorial, we discussed three UI options: a separate frontend (React), Thymeleaf server-rendered HTML, or a hybrid. **`@Controller` is the annotation behind Option B** — server-side rendering. `@RestController` is what we've used for everything else (Option A, the pure REST API).

The fundamental difference:

```java
@Controller                    // returns a STRING naming a VIEW to render
public class BookViewController {
    @GetMapping("/books")
    public String listBooks(Model model) {
        model.addAttribute("books", bookService.findAll());
        return "books";   // → resolves to templates/books.html
    }
}
```

```java
@RestController                 // returns DATA, serialized directly to the response body
public class BookController {
    @GetMapping("/books")
    public List<BookDto> listBooks() {
        return bookService.findAll();   // → serialized straight to JSON
    }
}
```

**Same HTTP verb, same URL pattern, same method signature shape — completely different meaning of the return value.** This is the single most important thing to internalize: `@Controller`'s return value is an _instruction to Spring about which template to render_; `@RestController`'s return value _is the actual response content_.

---

## 2. What `@RestController` Actually Is — Not a Separate Mechanism

Here's something that clarifies a lot: `@RestController` isn't a fundamentally different annotation — it's a **meta-annotation**, literally defined as:

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Controller
@ResponseBody
public @interface RestController {
}
```

`@RestController` = `@Controller` + `@ResponseBody`, bundled together. This is why everything we've built across this entire series (`BookController`, `LoanController`, etc.) is, underneath, still a `@Controller` — just with `@ResponseBody` baked in automatically.

### What `@ResponseBody` actually does

This is the piece that changes the return-value meaning. Without it, Spring treats a controller method's `String` return value as a **view name** to resolve and render. With `@ResponseBody`, Spring instead takes whatever the method returns and **serializes it directly into the HTTP response body** (via Jackson, for JSON) — skipping view resolution entirely.

```java
@Controller
public class BookController {

    @GetMapping("/books")
    @ResponseBody                          // applied per-method, not class-wide
    public List<BookDto> listBooksAsJson() {
        return bookService.findAll();       // JSON response
    }

    @GetMapping("/books/view")
    public String listBooksAsHtml(Model model) {
        model.addAttribute("books", bookService.findAll());
        return "books";                      // rendered HTML page
    }
}
```

This is a genuinely useful thing to see explicitly once: **the exact same `@Controller` class can mix both styles**, method by method, using `@ResponseBody` selectively. In practice, nobody actually does this in a real codebase — you pick one style for a controller and stick with it — but seeing it work this way makes the underlying mechanism concrete rather than feeling like two unrelated annotations.

---

## 3. View Resolution — How `"books"` Becomes an Actual HTML File

When a `@Controller` method returns a plain string like `"books"`, Spring hands that string to a **`ViewResolver`** — a component whose job is to map a logical name to an actual template file. With Thymeleaf (Spring Boot's default templating engine, auto-configured the moment `spring-boot-starter-thymeleaf` is on your classpath), the resolution follows a fixed convention:

```
"books"
   │
   ▼
src/main/resources/templates/ + "books" + ".html"
   │
   ▼
src/main/resources/templates/books.html
```

```html
<!-- src/main/resources/templates/books.html -->
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<body>
    <h1>Books</h1>
    <ul>
        <li th:each="book : ${books}" th:text="${book.title}"></li>
    </ul>
</body>
</html>
```

The `Model` parameter from the controller (`model.addAttribute("books", ...)`) is what makes `${books}` available inside the template — this is the bridge between your Java `List<BookDto>` and Thymeleaf's template expressions.

**This whole chain — `@Controller` → `ViewResolver` → `templates/*.html`** — only exists and works because of the `src/main/resources/templates/` convention we flagged (without explaining) back in the Maven Project Structure tutorial. Now you can see exactly what that folder is _for_.

---

## 4. `Model` vs `ModelAndView` vs `ResponseEntity` — Three Ways to Return Data From a Controller

Worth clarifying these together since they're easy to conflate.

### `Model` (most common, what we used above)

A simple attribute bag — you add data, return a view name string separately:

```java
@GetMapping("/books")
public String listBooks(Model model) {
    model.addAttribute("books", bookService.findAll());
    return "books";
}
```

### `ModelAndView` — bundles both into one object

```java
@GetMapping("/books")
public ModelAndView listBooks() {
    ModelAndView mav = new ModelAndView("books");
    mav.addObject("books", bookService.findAll());
    return mav;
}
```

Functionally identical to the `Model` + `String` approach — purely a style choice. `Model` + returning a `String` is more common in modern Spring Boot code because it keeps the method signature simpler and is easier to unit test (you can assert on the returned view name directly).

### `ResponseEntity` — only relevant in `@RestController`/`@ResponseBody` contexts

We used this constantly in earlier tutorials (`ResponseEntity.status(HttpStatus.CREATED).body(...)`) — it has **no meaning** in a plain view-rendering `@Controller` method, because there's no "response body" being constructed directly; you're naming a view to render, not building a response payload. Mixing these up (trying to return `ResponseEntity` from a method meant to render a view) is a common and confusing mistake for people moving between the two controller styles.

---

## 5. Redirects and Forwards — `@Controller`-Specific Return Conventions

Since `@Controller` return values are _instructions_, not data, Spring recognizes special string prefixes with their own meaning:

```java
@PostMapping("/books")
public String createBook(@ModelAttribute CreateBookRequest request) {
    bookService.create(request);
    return "redirect:/books";   // HTTP 302 redirect — browser makes a NEW request to /books
}
```

```java
@GetMapping("/books/{id}")
public String bookDetail(@PathVariable UUID id, Model model) {
    model.addAttribute("book", bookService.findById(id));
    return "forward:/books/detail-fragment";   // internal forward, no new HTTP request, no redirect
}
```

**`redirect:` vs. plain view name — why it matters:** this is the server-rendered equivalent of the classic "Post/Redirect/Get" pattern — after a successful form submission (`POST /books`), you redirect the browser to a `GET` request instead of directly rendering a view. Without this, refreshing the page after submitting a form would **resubmit the POST** (every browser's "confirm form resubmission" warning is exactly this scenario) — `redirect:` avoids that by making the browser issue a fresh `GET`.

This has **no equivalent concept** in `@RestController` land — a REST API client (React, curl, Postman) doesn't have "the page" to redirect; it just gets a JSON response and the frontend code decides what to do next. This is a genuinely clarifying example of how deeply the two controller styles diverge in philosophy, not just mechanics.

---

## 6. Form Binding — `@ModelAttribute`

Thymeleaf forms submit standard HTML form data (`application/x-www-form-urlencoded`), not JSON — so `@Controller` methods handling form submissions use `@ModelAttribute` instead of `@RequestBody`:

```java
@PostMapping("/books")
public String createBook(@ModelAttribute CreateBookRequest request) {
    bookService.create(request);
    return "redirect:/books";
}
```

```html
<form th:action="@{/books}" method="post">
    <input type="text" name="title" />
    <input type="text" name="author" />
    <button type="submit">Add Book</button>
</form>
```

Spring binds each form field (`name="title"`) to the matching constructor parameter/field on `CreateBookRequest` by name — the same relaxed-binding spirit from `@ConfigurationProperties`, just applied to HTML form fields instead of config properties.

---

## 7. When Would You Actually Reach for `@Controller` Today?

Given this entire series has consistently steered toward the separate-frontend architecture (Option A) and treated Thymeleaf as "good to know, simpler while learning" — worth being honest about when `@Controller` is a genuinely good production choice versus just a learning stepping stone:

|Scenario|Good fit for `@Controller` (Thymeleaf)?|
|---|---|
|Internal admin tool, simple CRUD, low interactivity needs|✅ Yes — faster to build, no separate frontend project/deploy pipeline|
|SEO-critical public content site (blog, marketing pages)|✅ Yes — server-rendered HTML is naturally crawlable, no JS-rendering SEO complications|
|Rich, highly interactive UI (drag-drop, real-time updates, complex client state)|❌ No — fighting against server-rendering's grain; React/Vue genuinely fit better|
|API consumed by multiple clients (web + mobile + third parties)|❌ No — `@RestController` is the only sensible choice; Thymeleaf produces HTML, not a reusable API|
|Learning Spring Boot fundamentals without frontend complexity|✅ Yes — exactly the reasoning from the High-Level Architecture tutorial|

**Practical honest take, given where you are:** since you're also learning Angular (per your current learning path) for the frontend, you'll likely spend most of your real project time in `@RestController` land, treating the backend as a pure JSON API. `@Controller`/Thymeleaf is genuinely worth knowing — it explains a huge chunk of Spring MVC's underlying design (view resolution, model binding, redirect semantics) that also quietly underpins `@RestController`'s behavior — but it's not what you'll reach for when building the Library app's real API alongside Angular.

---

## 8. Full Comparison Table

||`@Controller`|`@RestController`|
|---|---|---|
|Return value meaning|View name (or `redirect:`/`forward:`)|Actual response body content|
|Needs `@ResponseBody`?|Only per-method, if mixing in JSON endpoints|Built in automatically|
|Typical return types|`String` (view name), `ModelAndView`|DTOs, `ResponseEntity<T>`, `List<T>`|
|Data passed to view|`Model`/`ModelAndView`|N/A — the return value _is_ the data|
|Request body binding|`@ModelAttribute` (form data)|`@RequestBody` (JSON)|
|Pairs with|Thymeleaf templates in `src/main/resources/templates/`|A separate frontend (React, Angular) or any HTTP client|
|Used throughout this series?|No — mentioned, not built|Yes — every controller we've written|

---

## Quick Summary

1. `@RestController` = `@Controller` + `@ResponseBody` — it's not a separate mechanism, just a convenient bundle
2. A plain `@Controller` method's return `String` is a **view name**, resolved by a `ViewResolver` against `src/main/resources/templates/`, not response content
3. `Model`/`ModelAndView` carry data _into_ the template; `ResponseEntity` only makes sense in `@ResponseBody`/`@RestController` contexts — mixing these up is a common source of confusion
4. `redirect:`/`forward:` prefixes are `@Controller`-specific instructions with no equivalent in REST API design — rooted in the Post/Redirect/Get pattern to prevent duplicate form submissions
5. `@ModelAttribute` binds HTML form fields; `@RequestBody` binds JSON — matching each controller style's actual request format
6. Given your Angular + Spring Boot path, you'll live almost entirely in `@RestController` territory — `@Controller`/Thymeleaf is foundational knowledge worth having, not your primary tool here




[[Spring Framework]]