
## Core intuition

Everything you just built with `@RestController` actually **skips half of MVC** — it returns data directly as JSON, with no "View" involved. True Spring MVC is for building **server-rendered web pages**: the Controller still handles the HTTP request and talks to the Service, but instead of returning JSON, it returns the _name_ of an HTML template, and Spring fills that template with data before sending rendered HTML back to the browser.

MVC = **Model** (the data) + **View** (the template that renders it) + **Controller** (the traffic cop connecting the two). You've already built the Controller→Service→Repository chain — MVC adds the missing piece: how a Controller talks to a **View**.

## The three pieces

**Model** — not your `@Entity` class. It's a container Spring hands you to stuff data into before rendering.

**View** — an HTML template (Thymeleaf is the standard choice in Spring Boot) that reads from that Model to render dynamic content.

**Controller** — same `@Controller` annotation you already learned, but now its methods return a **view name** (a String) instead of raw data.

## Building it — a web page listing games

**1. Add the Thymeleaf starter**

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>
```

This triggers auto-configuration (recall: classpath detection → conditional beans activate) that wires up a `ViewResolver` pointed at `src/main/resources/templates/`.

**2. The Controller — returns a view name, not JSON**

```java
import org.springframework.stereotype.Controller;  // NOT @RestController
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@Controller
@RequestMapping("/games")
public class GameWebController {

    private final GameService gameService;

    public GameWebController(GameService gameService) {
        this.gameService = gameService;
    }

    @GetMapping
    public String listGames(Model model) {
        model.addAttribute("games", gameService.findAll());
        return "game-list";  // looks for templates/game-list.html
    }

    @GetMapping("/{id}")
    public String gameDetail(@PathVariable Long id, Model model) {
        model.addAttribute("game", gameService.findById(id));
        return "game-detail";  // looks for templates/game-detail.html
    }
}
```

Key difference from `@RestController`: **no `@ResponseBody`**, so the returned String `"game-list"` is interpreted as a **view name**, not response content. Spring's `ViewResolver` maps that to `templates/game-list.html` and renders it.

**3. The View — Thymeleaf template**

```html
<!-- src/main/resources/templates/game-list.html -->
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head><title>Games</title></head>
<body>
    <h1>All Games</h1>
    <ul>
        <li th:each="game : ${games}">
            <a th:href="@{/games/{id}(id=${game.id})}" th:text="${game.title}">Title</a>
            — <span th:text="${game.genre}">Genre</span>
        </li>
    </ul>
</body>
</html>
```

- `th:each="game : ${games}"` — loops over the `games` list you put in the Model; `${games}` reaches into the Model by the exact name you used in `addAttribute("games", ...)`.
- `th:text` — injects dynamic text, replacing the placeholder content.
- `th:href` with `@{...}` — builds a URL, substituting `${game.id}` into the path.

Request flow for `GET /games`:

```
Browser requests /games
    ↓
DispatcherServlet routes to GameWebController.listGames()
    ↓
gameService.findAll() fetches games (same service you already wrote)
    ↓
model.addAttribute("games", ...) stores them
    ↓
Controller returns "game-list" (just a String — the VIEW NAME)
    ↓
ViewResolver finds templates/game-list.html
    ↓
Thymeleaf renders the HTML, substituting ${games}
    ↓
Full rendered HTML sent to browser
```

## MVC vs REST, side by side

||`@Controller` + View (MVC)|`@RestController` (REST API)|
|---|---|---|
|Return value|View name (String)|Data (serialized to JSON)|
|Response|Full HTML page|Raw JSON|
|Rendering|Server-side (Thymeleaf)|None — client renders it (JS frontend)|
|Typical use|Traditional server-rendered websites|APIs consumed by React/Angular/mobile apps|

You already know both halves — this is really just: same Controller/Service/Repository chain, different final step. Since you're learning Angular as your front end (noted from your Angular learning path), you'll mostly use `@RestController` going forward — the Thymeleaf/MVC-view route is relevant mainly for legacy Spring apps, or if you ever build something without a separate frontend framework.

## Nuances/gotchas

- **Model attribute names are string-keyed and easy to typo.** `model.addAttribute("games", ...)` in Java must exactly match `${games}` in the template — no compile-time check catches a mismatch; you'll just get a blank/null render.
- **`@ModelAttribute` for form submissions** — the MVC counterpart to `@RequestBody`:
    
    ```java
    @PostMapping("/games")public String createGame(@ModelAttribute Game game) {    gameService.create(game);    return "redirect:/games"; // redirect, not render — avoids form resubmission on refresh}
    ```
    
    `redirect:` prefix tells Spring "don't render a view, send an HTTP redirect instead" — the classic Post/Redirect/Get pattern to prevent duplicate form submissions on browser refresh.
- **`@Controller` and `@RestController` can coexist in the same app** — nothing stops you from having both a JSON API (`/api/games`) and server-rendered pages (`/games`) in one Spring Boot application, pointing at the same `GameService`.
- **Mixing up the two is a classic beginner bug**: if you return `"game-list"` from a method annotated with `@RestController` (not `@Controller`), Spring won't look for a template — it'll just serialize the literal string `"game-list"` as the JSON response body. The annotation on the class determines interpretation, not the method.




[[Spring Framework]]