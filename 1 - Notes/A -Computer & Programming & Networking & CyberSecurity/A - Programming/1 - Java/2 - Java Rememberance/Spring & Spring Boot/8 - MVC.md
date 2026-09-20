# MVC (Model-View-Controller)

**MVC** is a **software architectural pattern** that separates an application into three interconnected components. It's one of the most widely used patterns in web development, including in Spring Boot (via Spring MVC).

## The Three Components

| Component | Responsibility | In Spring Boot |
|-----------|---------------|----------------|
| **Model** | Data + business logic. Manages state, rules, and persistence. | `@Entity`, `@Service`, POJOs, repositories |
| **View** | Presentation layer. Renders data to the user. | Thymeleaf, JSP, JSON (via `@ResponseBody`) |
| **Controller** | Handles user input, orchestrates Model ↔ View. | `@Controller`, `@RestController` |

## How It Flows

```
User Request
     │
     ▼
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│ Controller  │ ───► │   Model     │ ───► │    View     │
│ (input)     │ ◄─── │ (data/logic)│      │ (render)    │
└─────────────┘      └─────────────┘      └─────────────┘
                                                  │
                                                  ▼
                                            User Response
```

1. **User** sends a request (clicks a link, submits a form).
2. **Controller** receives it, calls the Model to fetch/update data.
3. **Model** returns data to the Controller.
4. **Controller** passes data to the **View**.
5. **View** renders the response (HTML/JSON) back to the user.

## Example in Spring Boot

```java
// MODEL — data + business logic
@Entity
public class User {
    @Id @GeneratedValue
    private Long id;
    private String name;
    // getters/setters
}

@Service
public class UserService {
    private final UserRepository repo;
    public UserService(UserRepository repo) { this.repo = repo; }

    public User getUser(Long id) {
        return repo.findById(id).orElseThrow();
    }
}

// CONTROLLER — handles request, prepares model, returns view name
@Controller
public class UserController {
    private final UserService service;

    public UserController(UserService service) { this.service = service; }

    @GetMapping("/users/{id}")
    public String getUser(@PathVariable Long id, Model model) {
        model.addAttribute("user", service.getUser(id)); // data for the view
        return "user-details";                            // view name → user-details.html
    }
}
```

```html
<!-- VIEW — Thymeleaf template (user-details.html) -->
<html xmlns:th="http://www.thymeleaf.org">
  <body>
    <h1 th:text="${user.name}">Name</h1>
  </body>
</html>
```

## MVC vs. Related Patterns

| Pattern | Difference |
|---------|-----------|
| **MVC** | Full separation with a dedicated Controller |
| **MVP** | Presenter replaces Controller; View is passive |
| **MVVM** | ViewModel with two-way data binding (e.g., Angular, Vue) |
| **REST API** | Spring's `@RestController` skips the View — returns JSON directly (effectively Model → JSON) |

## Key Benefits

- **Separation of concerns** — UI, logic, and data are decoupled
- **Testability** — Controllers and Models can be unit-tested independently
- **Parallel development** — Frontend and backend teams can work separately
- **Reusability** — Same Model can serve multiple Views (HTML, JSON, XML)

## Key Takeaway

MVC is a **layered design pattern** that splits an app into **Model** (data/logic), **View** (presentation), and **Controller** (request handling). In Spring Boot, it's implemented by **Spring MVC**, where `@Controller` classes route requests, the Model carries data, and View templates (Thymeleaf, JSP) render responses — or `@RestController` bypasses the View to return JSON directly for REST APIs.


[[0 - Spring + Spring Boot]]
[[0 - Spring Framework]]
[[Java]]