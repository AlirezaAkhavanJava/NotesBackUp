
## Core intuition

You already know `@ComponentScan` finds classes annotated with "stereotype" annotations and registers them as beans. `@Component`, `@Controller`, `@Service`, and `@Repository` are the actual stereotypes you tag classes with — but here's the key thing most tutorials skip: **three of these four are functionally identical to `@Component`**. They don't add extra bean-registration behavior. What they add is **semantic meaning** (for humans and tooling) plus, in some cases, **extra Spring-specific behavior bolted on top**.

Think of `@Component` as the base annotation, and the other three as specialized flavors of it.

## The hierarchy

```java
@Component          // the generic/base stereotype
@Controller          // meta-annotated with @Component + adds MVC handling
@Service              // meta-annotated with @Component, pure convention
@Repository          // meta-annotated with @Component + adds exception translation
```

If you open the Spring source code, you'd literally see:

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Component   // <-- @Service IS a @Component under the hood
public @interface Service {
    String value() default "";
}
```

This is **meta-annotation** — Spring's `@ComponentScan` doesn't just look for `@Component` literally; it detects anything _annotated with_ `@Component`, directly or transitively. That's why all four get picked up by the same scan.

## `@Component` — the generic case

```java
@Component
public class SlugGenerator {
    public String slugify(String title) {
        return title.toLowerCase().replace(" ", "-");
    }
}
```

Use this when a class doesn't cleanly fit "controller," "service," or "repository" — a utility, a helper, a validator, a formatter. It gets picked up by `@ComponentScan` and becomes an injectable bean, full stop. No extra behavior.

## `@Service` — business logic layer

```java
@Service
public class GameService {
    private final GameRepository gameRepository;

    public GameService(GameRepository gameRepository) {
        this.gameRepository = gameRepository;
    }

    public void startGame(Long gameId) {
        // business logic: validation, orchestration, calculations
        gameRepository.save(/* ... */);
    }
}
```

`@Service` is **purely conventional** — it adds zero extra framework behavior over `@Component`. You could tag `GameService` with `@Component` and it would work identically. The reason it exists: it signals intent to every developer reading the code ("this holds business logic, not persistence or HTTP handling") and lets tools/future-Spring-features hook into "all service-layer beans" if needed. This is a documentation/architecture tool, not a technical one.

## `@Controller` — handles HTTP requests

```java
@Controller
public class GameController {
    private final GameService gameService;

    public GameController(GameService gameService) {
        this.gameService = gameService;
    }

    @GetMapping("/games/{id}")
    public String getGame(@PathVariable Long id, Model model) {
        model.addAttribute("game", gameService.findById(id));
        return "game-view";  // returns a VIEW NAME (e.g. Thymeleaf template)
    }
}
```

This one **does** add real behavior: it marks the class as a Spring MVC handler, so `@GetMapping`/`@PostMapping` methods inside it get wired to actual HTTP routes by `DispatcherServlet`. Plain `@Controller` methods return **view names** (for server-rendered HTML) — not raw data.

```java
@RestController   // = @Controller + @ResponseBody, applied to every method
public class GameRestController {

    @GetMapping("/api/games/{id}")
    public Game getGame(@PathVariable Long id) {
        return gameService.findById(id);  // returned directly as JSON
    }
}
```

`@RestController` is `@Controller` + `@ResponseBody` fused together — every method's return value gets serialized straight to the HTTP response body (JSON, typically) instead of being treated as a view name. **For building REST APIs (what you'll do almost always in Spring Boot), `@RestController` is what you'll actually use.**

## `@Repository` — persistence layer

```java
@Repository
public class GameRepositoryImpl implements GameRepository {
    @PersistenceContext
    private EntityManager entityManager;

    public Game findById(Long id) {
        return entityManager.find(Game.class, id);
    }
}
```

This one adds a genuinely useful piece of extra behavior: **automatic exception translation**. Without `@Repository`, a database call that fails throws a low-level, technology-specific exception (e.g., Hibernate's `ConstraintViolationException`, or a raw JDBC `SQLException`). With `@Repository`, Spring wraps your class in a `PersistenceExceptionTranslationPostProcessor` that catches those and rethrows them as one of Spring's unified `DataAccessException` subclasses.

Why this matters: your `@Service` layer can now catch `DataAccessException` generically, without caring whether the underlying implementation is Hibernate, plain JDBC, or MongoDB. Swap your persistence technology later, and your service-layer error handling doesn't have to change.

**In modern Spring Data JPA, you rarely write `@Repository` yourself:**

```java
public interface GameRepository extends JpaRepository<Game, Long> {
    // no implementation, no @Repository needed — Spring Data generates
    // the implementation at runtime and registers it as a bean automatically
}
```

Spring Data JPA auto-generates the implementation and handles the exception translation internally, which is why you see `@Repository` less often in day-to-day Spring Boot code than in the older/manual persistence style above.

## Summary table

|Annotation|Extra behavior beyond `@Component`?|Layer|
|---|---|---|
|`@Component`|None — base case|Generic/utility|
|`@Service`|None — pure convention|Business logic|
|`@Repository`|**Yes** — exception translation to `DataAccessException`|Persistence/data access|
|`@Controller`|**Yes** — registers HTTP handler methods|Web/HTTP layer|
|`@RestController`|`@Controller` + auto `@ResponseBody` on every method|REST API layer|

## Nuances/gotchas

- **You _can_ swap them and the app will still technically run** (e.g., tagging a service with `@Component` instead of `@Service`) — nothing breaks mechanically. But it's bad practice; the semantic layering is part of why Spring codebases stay navigable at scale. Don't do this on purpose.
- **Constructor injection is implicitly "just works" since Spring 4.3+** if a class has exactly one constructor — you don't even need `@Autowired` on it (all the examples above omit it deliberately). You only need `@Autowired` explicitly when a class has multiple constructors and you need to tell Spring which one to use.
- **Layering convention**: `@Controller`/`@RestController` → calls → `@Service` → calls → `@Repository`. Controllers should never talk to repositories directly — this is an architectural discipline, not something Spring enforces for you.
- **`@Component` scanning doesn't care about the layer name at all** — it's literally just checking "is this annotated with something meta-annotated `@Component`?" The architectural meaning is 100% a human/team convention layered on top of a mechanically simple scan.




[[Spring Framework]]