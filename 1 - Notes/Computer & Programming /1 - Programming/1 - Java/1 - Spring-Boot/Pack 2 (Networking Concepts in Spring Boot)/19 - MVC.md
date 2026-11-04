
# MVC in Spring Boot

**MVC (Model-View-Controller)** is a way to split a web application into three roles. The **Model** holds the data and rules, the **View** decides how that data is shown to the user, and the **Controller** receives the request and coordinates the two. Each role changes for different reasons, so you can change one without breaking the others.

Spring's web layer, **Spring MVC**, is built on this pattern, and it supports two styles. In the **server-rendered** style, the app builds HTML pages with a template engine such as Thymeleaf. In the **REST** style, the app returns JSON for a separate front end or mobile app. Both are valid and both are in use, and this note covers both. It joins your two MVC notes and builds on your Spring Web note (`DispatcherServlet`), your REST API notes, and your data access note.

---

## The three roles, and a naming trap

|Role|Job|In Spring Boot|
|---|---|---|
|**Model**|The data and business rules|Entities, DTOs, services|
|**View**|Turns the data into what the user sees|A Thymeleaf template (HTML), or the JSON body|
|**Controller**|Handles the request and picks the response|`@Controller` or `@RestController`|

**The trap:** the word "Model" means two things in Spring.

- The **M in MVC** is the idea: your data and logic.
- **`org.springframework.ui.Model`** is a small map-like object you receive in a controller method, used to hand data to the view.

Don't confuse them. The second is just the tool for passing data from controller to template.

---

## What really happens when a request arrives

The original diagram showed the controller calling the view directly. In Spring, the controller never renders anything. A front controller in the middle does the routing:

```text
Browser ──► DispatcherServlet ──► finds the right @Controller method
                                        │ runs it (calls your service)
                                        ▼
            controller returns:  a view name + model data   (server-rendered)
                           or:   an object                  (REST)
                                        │
            ┌───────────────────────────┴──────────────────────────┐
            ▼                                                      ▼
  ViewResolver finds the template                Jackson converts the object to JSON
  Thymeleaf renders HTML                         written straight to the response
            └───────────────────────────┬──────────────────────────┘
                                        ▼
                                 Response to browser
```

`DispatcherServlet` is the single entry point for every request. Your controller only returns a _name_ or an _object_, and Spring picks the view.

---

## Style A: server-rendered pages (`@Controller` + Thymeleaf)

Add `spring-boot-starter-thymeleaf`. Templates live in `src/main/resources/templates/`.

```java
@Controller
public class UserPageController {

    private final UserService service;

    public UserPageController(UserService service) { this.service = service; }

    @GetMapping("/users/{id}")
    public String showUser(@PathVariable Long id, Model model) {
        model.addAttribute("user", service.getUser(id));   // data for the template
        return "user-details";                             // → templates/user-details.html
    }
}
```

```html
<!-- templates/user-details.html -->
<html xmlns:th="http://www.thymeleaf.org">
  <body>
    <h1 th:text="${user.name}">Name</h1>
  </body>
</html>
```

Line by line:

- The `Model` parameter is the data hand-off. `user` becomes available in the template as `${user}`.
- The returned string is the **template name**, not text. This is the key difference from `@RestController`.

For a form, use **Post-Redirect-Get**, so a page refresh doesn't resubmit the form:

```java
@PostMapping("/users")
public String create(@Valid @ModelAttribute CreateUserForm form, BindingResult result) {
    if (result.hasErrors()) return "user-form";   // show the form again, with errors
    service.create(form);
    return "redirect:/users";                     // redirect after a successful POST
}
```

---

## Style B: a REST API (`@RestController`)

`@RestController` is `@Controller` plus `@ResponseBody`. The return value is converted to JSON and written to the body, with no view and no template. In MVC terms, the "view" is the JSON.

### The controller

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {       // constructor injection
        this.userService = userService;
    }

    @GetMapping
    public List<UserDto> getAll() { return userService.getAll(); }

    @GetMapping("/{id}")
    public UserDto get(@PathVariable Long id) { return userService.get(id); }

    @PostMapping
    public ResponseEntity<UserDto> create(@Valid @RequestBody CreateUserRequest request) {
        UserDto created = userService.create(request);
        return ResponseEntity.created(URI.create("/api/users/" + created.id())).body(created);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) { userService.delete(id); }
}
```

Line by line:

- `@RequestMapping` at class level gives a shared base path. The `@GetMapping`, `@PostMapping` and `@DeleteMapping` annotations set the verb.
- `@RequestBody` turns the incoming JSON into an object. `@Valid` runs Bean Validation on it (it needs the validation starter, as the REST API note said).
- Creation returns **201 with a `Location` header**, and deletion returns **204**. Your REST endpoint rules note explains these choices.

### DTOs: records, not entities

```java
public record UserDto(Long id, String name, String email) {}

public record CreateUserRequest(@NotBlank String name, @Email String email) {}
```

Don't return JPA entities from controllers. It leaks your table structure into the API, can trigger lazy-loading errors during JSON conversion, and ties your API to your schema. Records are ideal DTOs because they are short and immutable. (Your Entity/DTO/mapper note covers mapping, and MapStruct can generate it.)

### The service: logic and mapping

```java
@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) { this.userRepository = userRepository; }

    @Transactional(readOnly = true)
    public UserDto get(Long id) {
        User user = userRepository.findById(id).orElseThrow(() -> new UserNotFoundException(id));
        return toDto(user);
    }

    @Transactional
    public UserDto create(CreateUserRequest request) {
        return toDto(userRepository.save(new User(request.name(), request.email())));
    }

    private UserDto toDto(User u) { return new UserDto(u.getId(), u.getName(), u.getEmail()); }
}
```

Mapping to a DTO happens **inside the service**, within the transaction. `@Transactional` is a proxy-based feature, so the self-call rule from your AOP note applies.

### The repository and the entity

```java
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);    // Spring writes the query from the name
}
```

```java
@Entity
@Table(name = "users")                           // "user" is reserved in PostgreSQL
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private String email;

    protected User() {}                          // JPA needs a no-argument constructor
    public User(String name, String email) { this.name = name; this.email = email; }
    // getters
}
```

The repository interface has no implementation class. Spring Data builds one at startup, using the same proxy machinery as AOP.

### Errors in one place

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    public ProblemDetail handleNotFound(UserNotFoundException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
    }
}
```

This catches the exception from every controller, so you don't put `try/catch` in each one. It is the same cross-cutting idea as AOP. `ProblemDetail` gives clients the standard error format described in your REST API note, which also shows how to handle validation errors.

---

## MVC is not the same as layers

The two original notes mixed these up, so keep them apart.

||What it describes|
|---|---|
|**MVC**|How the **web layer** handles a request: controller, model data, view|
|**Layered architecture**|How the **whole app** is organized: controller → service → repository → database|

The controller belongs to both. In the REST style, the full path is:

```text
Client → Controller → Service → Repository → Database
```

Here "Model" in the MVC sense covers the entities, DTOs and services behind the controller, and your data access note (persistence layer) covers the bottom two layers.

---

## Which style to choose

|You are building|Use|
|---|---|
|A website where the server produces the pages|`@Controller` + Thymeleaf|
|An API for a React/Angular front end or a mobile app|`@RestController`|
|Both|Two sets of controllers, sharing the same services|

---

## Habits that apply to both styles

|Prefer|Instead of|
|---|---|
|Constructor injection|`@Autowired` on fields|
|`@GetMapping`, `@PostMapping`|`@RequestMapping(method = ...)`|
|DTOs (records) at the boundary|Returning entities|
|`@Valid` with Bean Validation|Manual `if/else` checks|
|`@RestControllerAdvice`|`try/catch` in every controller|
|Java config and annotations|XML configuration|

---

## Related concept in short

**MVP and MVVM** are cousins of MVC for UI-heavy apps. In MVP, a _Presenter_ replaces the controller and the view is passive. In MVVM, a _ViewModel_ is bound to the view in both directions, as in Angular and Vue. Neither is a Spring concept. They matter if you build the front end.




[[Spring Framework]]