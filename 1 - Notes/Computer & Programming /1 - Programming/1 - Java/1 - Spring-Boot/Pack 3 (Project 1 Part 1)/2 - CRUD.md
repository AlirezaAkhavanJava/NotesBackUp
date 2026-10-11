
## Core intuition

CRUD (Create, Read, Update, Delete) in Spring Boot is the complete vertical slice through every layer you've learned: an **Entity** (maps to a DB table) → a **Repository** (talks to the DB) → a **Service** (business logic) → a **RestController** (exposes HTTP endpoints). Every piece you already understand — `@Component` family, dependency injection, auto-configuration — comes together here. This is the "hello world" of real Spring Boot apps, and once it clicks, you can build almost any API by repeating this pattern.

Let's build a `Game` CRUD API end to end.

## 1. The Entity — maps a class to a DB table

```java
import jakarta.persistence.*;

@Entity
@Table(name = "games")
public class Game {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title;

    private String genre;
    private int releaseYear;

    // Spring Data JPA + Jackson both require a no-arg constructor
    public Game() {}

    public Game(String title, String genre, int releaseYear) {
        this.title = title;
        this.genre = genre;
        this.releaseYear = releaseYear;
    }

    // getters and setters — required for JPA and JSON serialization
    public Long getId() { return id; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getGenre() { return genre; }
    public void setGenre(String genre) { this.genre = genre; }
    public int getReleaseYear() { return releaseYear; }
    public void setReleaseYear(int releaseYear) { this.releaseYear = releaseYear; }
}
```

- `@Entity` tells JPA/Hibernate "this class maps to a table" — Spring Boot's auto-configuration (from your last lesson) picks this up via `spring-boot-starter-data-jpa` and wires in Hibernate behind the scenes.
- `@Id` + `@GeneratedValue` = primary key, auto-incremented by the DB.
- `@Column(nullable = false)` is optional fine-tuning; without any `@Column`, JPA infers a column from the field name.
- **Getters/setters matter**: Jackson (JSON serialization) uses getters to turn this into JSON for responses, and Hibernate uses them to populate fields when reading from the DB.

## 2. The Repository — data access, with zero implementation code

```java
import org.springframework.data.jpa.repository.JpaRepository;

public interface GameRepository extends JpaRepository<Game, Long> {
    // Long = type of the ID field. That's it — CRUD methods are inherited.
}
```

This single line gives you, for free: `save()`, `findById()`, `findAll()`, `deleteById()`, `count()`, and more. No `@Repository` annotation needed — Spring Data JPA generates a proxy implementation at startup and registers it as a bean automatically (recall from the last lesson: this is the modern replacement for hand-written `@Repository` classes with `EntityManager`).

## 3. The Service — business logic layer

```java
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class GameService {

    private final GameRepository gameRepository;

    public GameService(GameRepository gameRepository) {
        this.gameRepository = gameRepository;
    }

    public List<Game> findAll() {
        return gameRepository.findAll();
    }

    public Game findById(Long id) {
        return gameRepository.findById(id)
            .orElseThrow(() -> new GameNotFoundException(id));
    }

    public Game create(Game game) {
        return gameRepository.save(game);
    }

    public Game update(Long id, Game updatedGame) {
        Game existing = findById(id); // reuses the not-found check above
        existing.setTitle(updatedGame.getTitle());
        existing.setGenre(updatedGame.getGenre());
        existing.setReleaseYear(updatedGame.getReleaseYear());
        return gameRepository.save(existing); // save() does UPDATE if ID exists
    }

    public void delete(Long id) {
        if (!gameRepository.existsById(id)) {
            throw new GameNotFoundException(id);
        }
        gameRepository.deleteById(id);
    }
}
```

Notice: the service doesn't know or care _how_ `GameRepository` is implemented — it just calls the interface methods. This is the dependency-inversion payoff from your earliest `ApplicationContext` lesson, made concrete.

`save()` doing double duty as both insert and update is a common point of confusion: **JPA decides based on whether the entity's ID is `null`** (insert) **or already set** (update). That's why `update()` fetches the existing entity first, mutates it, then saves — rather than constructing a brand-new `Game`.

## 4. A custom exception + handler (clean error responses)

```java
public class GameNotFoundException extends RuntimeException {
    public GameNotFoundException(Long id) {
        super("Game not found with id: " + id);
    }
}
```

```java
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(GameNotFoundException.class)
    public ResponseEntity<String> handleNotFound(GameNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ex.getMessage());
    }
}
```

`@RestControllerAdvice` intercepts exceptions thrown from _any_ controller in the app and converts them into clean HTTP responses — without this, an unhandled exception would return an ugly default 500 error page instead of a proper 404.

## 5. The Controller — the HTTP layer

```java
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/games")
public class GameController {

    private final GameService gameService;

    public GameController(GameService gameService) {
        this.gameService = gameService;
    }

    @GetMapping
    public List<Game> getAll() {
        return gameService.findAll();
    }

    @GetMapping("/{id}")
    public Game getById(@PathVariable Long id) {
        return gameService.findById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Game create(@RequestBody Game game) {
        return gameService.create(game);
    }

    @PutMapping("/{id}")
    public Game update(@PathVariable Long id, @RequestBody Game game) {
        return gameService.update(id, game);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        gameService.delete(id);
    }
}
```

|Annotation|Maps to|
|---|---|
|`@RequestMapping("/api/games")`|shared URL prefix for every method in this class|
|`@GetMapping`|`GET /api/games` → list all|
|`@GetMapping("/{id}")`|`GET /api/games/5` → one game|
|`@PostMapping`|`POST /api/games` → create|
|`@PutMapping("/{id}")`|`PUT /api/games/5` → update|
|`@DeleteMapping("/{id}")`|`DELETE /api/games/5` → delete|
|`@PathVariable`|pulls `{id}` out of the URL|
|`@RequestBody`|deserializes the JSON request body into a `Game` object|

## The full request lifecycle (tying everything together)

```
HTTP POST /api/games  {"title": "Celeste", "genre": "Platformer", "releaseYear": 2018}
        ↓
DispatcherServlet routes to GameController.create()
        ↓
@RequestBody deserializes JSON → Game object (Jackson, auto-configured)
        ↓
gameService.create(game) called
        ↓
gameRepository.save(game) called
        ↓
Hibernate generates: INSERT INTO games (title, genre, release_year) VALUES (...)
        ↓
Saved Game (now with generated id) returned back up the chain
        ↓
Jackson serializes it to JSON → HTTP response body, status 201
```

## application.properties (what actually makes this run)

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/arcade
spring.datasource.username=admin
spring.datasource.password=secret
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
```

`ddl-auto=update` tells Hibernate to auto-create/alter the `games` table from your `@Entity` class at startup — great for learning/dev, **dangerous in production** (you'd use migration tools like Flyway/Liquibase instead, to avoid Hibernate silently altering a live schema).

## Nuances/gotchas

- **`save()` for update requires the ID to already exist** — if you pass an entity with an ID that _doesn't_ exist in the DB, JPA will try to `INSERT` with that explicit ID rather than erroring, which can produce confusing behavior. This is why the `update()` method above fetches first rather than trusting the caller's ID blindly.
- **`@RequestBody` vs entity leakage**: accepting your `@Entity` class directly as the request body (like above) is fine for learning, but in real apps you'd use separate **DTO classes** (`GameRequestDto`/`GameResponseDto`) to avoid exposing internal DB fields or accidentally letting a client set the `id` on create. Worth knowing now, not urgent yet.
- **`existsById()` before `deleteById()`** avoids a confusing silent no-op — `deleteById()` on a missing ID throws `EmptyResultDataAccessException` by default in some JPA versions, which is a vague error if unhandled; checking first gives you the clean 404 instead.
- **Transactions**: `save()`/`deleteById()` from `JpaRepository` are already wrapped in a transaction for you (Spring Data JPA auto-configures this) — you don't need `@Transactional` for simple single-operation methods like these. You'd add `@Transactional` explicitly on a service method only when it performs _multiple_ repository calls that must succeed or fail together.




[[Spring Framework]]