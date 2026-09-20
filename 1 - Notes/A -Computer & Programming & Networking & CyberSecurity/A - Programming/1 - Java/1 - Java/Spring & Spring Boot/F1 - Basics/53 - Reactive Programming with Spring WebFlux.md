
## Introduction to Reactive Programming

Reactive Programming is a programming paradigm focused on asynchronous data streams and the propagation of change. In the context of Spring, it enables building non-blocking, asynchronous applications that can handle high concurrency with a small number of threads.

### What is Spring WebFlux?
Spring WebFlux is a reactive-stack web framework introduced in Spring 5. It's designed to handle asynchronous, non-blocking processing with backpressure support, built on top of Project Reactor.

### Why Use Reactive Programming?
- **High throughput**: Ideal for applications requiring high concurrency
- **Low latency**: Efficient resource utilization with non-blocking operations
- **Scalability**: Better performance with limited hardware resources
- **Backpressure support**: Controls data flow between fast producers and slow consumers

## Prerequisites

Before diving into WebFlux, you should understand:
- Basic reactive programming concepts (Observables, Publishers, Subscribers)
- Java 8+ features (lambdas, functional interfaces)
- Spring Boot fundamentals
- REST API concepts

## Getting Started with WebFlux

### Add Dependencies

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webflux</artifactId>
</dependency>
```

### Core Concepts: Mono and Flux

WebFlux uses Project Reactor's two main publishers:

#### Mono
A Mono represents a single value or empty result (0..1)
```java
Mono<String> greeting = Mono.just("Hello, World!");
Mono<String> empty = Mono.empty();
Mono<String> error = Mono.error(new RuntimeException("Error occurred"));
```

#### Flux
A Flux represents a sequence of values (0..N)
```java
Flux<String> colors = Flux.just("Red", "Green", "Blue");
Flux<Integer> numbers = Flux.range(1, 10);
Flux<Long> interval = Flux.interval(Duration.ofSeconds(1));
```

## Building Reactive Endpoints

### Traditional vs Reactive Controller

**Traditional (Spring MVC)**
```java
@RestController
@RequestMapping("/todos")
public class TodoController {
    
    @GetMapping("/{id}")
    public Todo getTodo(@PathVariable String id) {
        return todoService.findById(id);
    }
    
    @GetMapping
    public List<Todo> getAllTodos() {
        return todoService.findAll();
    }
}
```

**Reactive (WebFlux)**
```java
@RestController
@RequestMapping("/todos")
public class ReactiveTodoController {
    
    @GetMapping("/{id}")
    public Mono<Todo> getTodo(@PathVariable String id) {
        return todoService.findById(id);
    }
    
    @GetMapping
    public Flux<Todo> getAllTodos() {
        return todoService.findAll();
    }
    
    @PostMapping
    public Mono<Todo> createTodo(@RequestBody Todo todo) {
        return todoService.save(todo);
    }
    
    @GetMapping("/stream")
    public Flux<Todo> getTodoStream() {
        return todoService.findAll().delayElements(Duration.ofSeconds(1));
    }
}
```

### Functional Endpoints

WebFlux also supports functional programming style:

```java
@Configuration
public class TodoRouter {
    
    @Bean
    public RouterFunction<ServerResponse> route(TodoHandler todoHandler) {
        return RouterFunctions
            .route(GET("/todos/{id}").and(accept(MediaType.APPLICATION_JSON)), 
                    todoHandler::getTodo)
            .andRoute(GET("/todos").and(accept(MediaType.APPLICATION_JSON)), 
                    todoHandler::getAllTodos)
            .andRoute(POST("/todos").and(accept(MediaType.APPLICATION_JSON)), 
                    todoHandler::createTodo);
    }
}

@Component
public class TodoHandler {
    
    public Mono<ServerResponse> getTodo(ServerRequest request) {
        String id = request.pathVariable("id");
        Mono<Todo> todo = todoService.findById(id);
        return todo
                .flatMap(t -> ServerResponse.ok().bodyValue(t))
                .switchIfEmpty(ServerResponse.notFound().build());
    }
    
    public Mono<ServerResponse> getAllTodos(ServerRequest request) {
        Flux<Todo> todos = todoService.findAll();
        return ServerResponse.ok().body(todos, Todo.class);
    }
    
    public Mono<ServerResponse> createTodo(ServerRequest request) {
        Mono<Todo> todoMono = request.bodyToMono(Todo.class);
        return todoMono
                .flatMap(todoService::save)
                .flatMap(t -> ServerResponse
                        .created(URI.create("/todos/" + t.getId()))
                        .bodyValue(t));
    }
}
```

## Reactive Data Access

### Reactive Repositories

Spring Data supports reactive repositories for various databases:

```java
public interface ReactiveTodoRepository extends ReactiveCrudRepository<Todo, String> {
    
    Flux<Todo> findByCompleted(boolean completed);
    
    Flux<Todo> findByDescriptionContaining(String description);
}

@Service
public class ReactiveTodoService {
    
    private final ReactiveTodoRepository repository;
    
    public ReactiveTodoService(ReactiveTodoRepository repository) {
        this.repository = repository;
    }
    
    public Flux<Todo> findAll() {
        return repository.findAll();
    }
    
    public Mono<Todo> findById(String id) {
        return repository.findById(id);
    }
    
    public Mono<Todo> save(Todo todo) {
        return repository.save(todo);
    }
    
    public Mono<Void> deleteById(String id) {
        return repository.deleteById(id);
    }
}
```

## Error Handling in Reactive Streams

```java
@RestController
@RequestMapping("/todos")
public class ReactiveTodoController {
    
    @GetMapping("/{id}")
    public Mono<Todo> getTodo(@PathVariable String id) {
        return todoService.findById(id)
                .switchIfEmpty(Mono.error(new TodoNotFoundException(id)));
    }
    
    @ExceptionHandler(TodoNotFoundException.class)
    public Mono<ResponseEntity<String>> handleTodoNotFound(TodoNotFoundException ex) {
        return Mono.just(ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(ex.getMessage()));
    }
}
```

## Testing Reactive APIs

```java
@WebFluxTest(ReactiveTodoController.class)
public class ReactiveTodoControllerTest {
    
    @Autowired
    private WebTestClient webTestClient;
    
    @MockBean
    private ReactiveTodoService todoService;
    
    @Test
    public void testGetTodo() {
        Todo todo = new Todo("1", "Learn WebFlux", false);
        
        when(todoService.findById("1")).thenReturn(Mono.just(todo));
        
        webTestClient.get()
                .uri("/todos/1")
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.id").isEqualTo("1")
                .jsonPath("$.description").isEqualTo("Learn WebFlux");
    }
    
    @Test
    public void testGetAllTodos() {
        Todo todo1 = new Todo("1", "Learn WebFlux", false);
        Todo todo2 = new Todo("2", "Practice Reactive Programming", true);
        
        when(todoService.findAll()).thenReturn(Flux.just(todo1, todo2));
        
        webTestClient.get()
                .uri("/todos")
                .exchange()
                .expectStatus().isOk()
                .expectBodyList(Todo.class)
                .hasSize(2)
                .contains(todo1, todo2);
    }
}
```

## Practice: Rewrite Your Todo API with WebFlux

### Step 1: Create a Spring Boot Project with WebFlux

Use Spring Initializr (https://start.spring.io/) and select:
- Spring WebFlux
- Spring Data Reactive MongoDB (or another reactive database)
- Lombok (optional)

### Step 2: Define the Todo Model

```java
@Data
@NoArgsConstructor
@AllArgsConstructor
@Document
public class Todo {
    @Id
    private String id;
    private String description;
    private boolean completed;
    
    public Todo(String description, boolean completed) {
        this.description = description;
        this.completed = completed;
    }
}
```

### Step 3: Create Reactive Repository

```java
public interface ReactiveTodoRepository extends ReactiveMongoRepository<Todo, String> {
    Flux<Todo> findByCompleted(boolean completed);
}
```

### Step 4: Implement Service Layer

```java
@Service
public class ReactiveTodoService {
    
    private final ReactiveTodoRepository repository;
    
    public ReactiveTodoService(ReactiveTodoRepository repository) {
        this.repository = repository;
    }
    
    public Flux<Todo> findAll() {
        return repository.findAll();
    }
    
    public Mono<Todo> findById(String id) {
        return repository.findById(id);
    }
    
    public Mono<Todo> save(Todo todo) {
        return repository.save(todo);
    }
    
    public Mono<Todo> update(String id, Todo todo) {
        return repository.findById(id)
                .flatMap(existingTodo -> {
                    existingTodo.setDescription(todo.getDescription());
                    existingTodo.setCompleted(todo.isCompleted());
                    return repository.save(existingTodo);
                });
    }
    
    public Mono<Void> deleteById(String id) {
        return repository.deleteById(id);
    }
    
    public Flux<Todo> findByCompleted(boolean completed) {
        return repository.findByCompleted(completed);
    }
}
```

### Step 5: Create Reactive Controller

```java
@RestController
@RequestMapping("/todos")
public class ReactiveTodoController {
    
    private final ReactiveTodoService todoService;
    
    public ReactiveTodoController(ReactiveTodoService todoService) {
        this.todoService = todoService;
    }
    
    @GetMapping
    public Flux<Todo> getAllTodos() {
        return todoService.findAll();
    }
    
    @GetMapping("/{id}")
    public Mono<ResponseEntity<Todo>> getTodo(@PathVariable String id) {
        return todoService.findById(id)
                .map(ResponseEntity::ok)
                .defaultIfEmpty(ResponseEntity.notFound().build());
    }
    
    @PostMapping
    public Mono<Todo> createTodo(@RequestBody Todo todo) {
        return todoService.save(todo);
    }
    
    @PutMapping("/{id}")
    public Mono<ResponseEntity<Todo>> updateTodo(@PathVariable String id, @RequestBody Todo todo) {
        return todoService.update(id, todo)
                .map(ResponseEntity::ok)
                .defaultIfEmpty(ResponseEntity.notFound().build());
    }
    
    @DeleteMapping("/{id}")
    public Mono<ResponseEntity<Void>> deleteTodo(@PathVariable String id) {
        return todoService.deleteById(id)
                .then(Mono.just(ResponseEntity.ok().<Void>build()))
                .defaultIfEmpty(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/completed/{status}")
    public Flux<Todo> getTodosByCompletion(@PathVariable boolean status) {
        return todoService.findByCompleted(status);
    }
    
    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<Todo> streamTodos() {
        return todoService.findAll()
                .delayElements(Duration.ofSeconds(1))
                .log();
    }
}
```

### Step 6: Configure Application Properties

```properties
# application.properties
spring.data.mongodb.host=localhost
spring.data.mongodb.port=27017
spring.data.mongodb.database=tododb

server.port=8080
```

### Step 7: Test Your Reactive API

Use tools like:
- `curl` for simple requests
- Postman for API testing
- `WebTestClient` for unit tests
- Browser for SSE streaming endpoints

Example test:
```bash
# Get all todos
curl http://localhost:8080/todos

# Create a new todo
curl -X POST -H "Content-Type: application/json" -d '{"description":"Learn Reactive Programming","completed":false}' http://localhost:8080/todos

# Stream todos (SSE)
curl http://localhost:8080/todos/stream
```

## Performance Comparison: WebFlux vs MVC

### Key Differences

| Aspect | Spring MVC | Spring WebFlux |
|--------|------------|----------------|
| Programming Model | Imperative, blocking | Reactive, non-blocking |
| Concurrency Model | Thread-per-request | Event-loop with few threads |
| Scalability | Limited by thread pool size | Better for high concurrency |
| Learning Curve | Lower | Higher (requires understanding reactive programming) |
| Use Cases | Traditional CRUD apps | High-throughput, low-latency apps |

### When to Choose WebFlux

- Applications with many concurrent connections
- Microservices requiring high scalability
- Streaming data applications
- When you need to handle backpressure

### When to Stick with MVC

- Simple CRUD applications
- Teams unfamiliar with reactive programming
- Applications with blocking dependencies (JDBC, etc.)
- When simplicity is more important than extreme scalability

## Conclusion

Spring WebFlux provides a powerful alternative to traditional Spring MVC for building reactive, non-blocking applications. While it has a steeper learning curve, it offers significant benefits in terms of scalability and resource utilization for high-throughput applications.

The key to success with WebFlux is understanding reactive programming principles, particularly the Mono and Flux publishers from Project Reactor. Once mastered, you can build highly efficient APIs that excel in concurrent environments.

Remember that reactive programming isn't always the right choice - evaluate your specific use case and requirements before deciding between WebFlux and traditional MVC.

## Additional Resources

- [Project Reactor Documentation](https://projectreactor.io/docs)
- [Spring WebFlux Documentation](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html)
- [Reactive Streams Specification](https://www.reactive-streams.org/)
- [ReactiveX Documentation](http://reactivex.io/)

[[0 - Spring Framework]]