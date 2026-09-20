
## What is Spring WebFlux?

Spring WebFlux is like a **super-fast waiter** in a restaurant who can handle many customers at once without getting overwhelmed. While traditional Spring MVC is like a waiter who can only serve one table at a time, WebFlux can serve many tables simultaneously.

### Why Use WebFlux?
- Handles thousands of users with few resources
- Perfect for chat apps, real-time updates, streaming services
- Doesn't get stuck waiting for slow operations

---

## Part 1: Beginner Concepts

### 1.1 Setting Up a WebFlux Project

Create a new Spring Boot project and add this dependency:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webflux</artifactId>
</dependency>
```

### 1.2 Your First Reactive Endpoint

```java
@RestController
public class SimpleController {
    
    @GetMapping("/hello")
    public Mono<String> sayHello() {
        return Mono.just("Hello, WebFlux!");
    }
}
```

**What's Mono?** Think of it as a **box** that will eventually contain a single value (or be empty).

### 1.3 Returning Lists with Flux

```java
@GetMapping("/numbers")
public Flux<Integer> getNumbers() {
    return Flux.just(1, 2, 3, 4, 5);
}
```

**What's Flux?** Think of it as a **conveyor belt** that delivers multiple values over time.

### 1.4 Simple Reactive Service

```java
@Service
public class UserService {
    
    public Flux<User> getAllUsers() {
        // Simulate getting users from a database
        return Flux.just(
            new User("Alice", "alice@example.com"),
            new User("Bob", "bob@example.com"),
            new User("Charlie", "charlie@example.com")
        );
    }
    
    public Mono<User> getUserById(String id) {
        // Simulate database lookup
        return Mono.just(new User("Demo", "demo@example.com"));
    }
}
```

---

## Part 2: Intermediate Concepts

### 2.1 Handling Data Streams

WebFlux shines when working with continuous data:

```java
@GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
public Flux<String> streamData() {
    return Flux.interval(Duration.ofSeconds(1))
               .map(sequence -> "Event #" + sequence + " at " + new Date());
}
```

This sends a new event every second, perfect for live updates!

### 2.2 Combining Reactive Operations

```java
@GetMapping("/user/{id}/details")
public Mono<UserDetails> getUserDetails(@PathVariable String id) {
    return userService.getUserById(id)
                     .flatMap(user -> {
                         return orderService.getOrders(user.getId())
                                            .map(orders -> new UserDetails(user, orders));
                     });
}
```

**flatMap vs map:**
- `map` transforms the value inside the Mono/Flux
- `flatMap` transforms and flattens nested Monos/Fluxes

### 2.3 Error Handling

```java
@GetMapping("/user/{id}")
public Mono<User> getUser(@PathVariable String id) {
    return userService.getUserById(id)
                     .switchIfEmpty(Mono.error(new UserNotFoundException(id)))
                     .onErrorResume(exception -> {
                         // Log error and return fallback
                         return Mono.just(new User("Guest", "guest@example.com"));
                     });
}

@ResponseStatus(HttpStatus.NOT_FOUND)
class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(String id) {
        super("User not found: " + id);
    }
}
```

### 2.4 Filtering and Transforming Streams

```java
@GetMapping("/users/active")
public Flux<User> getActiveUsers() {
    return userService.getAllUsers()
                     .filter(user -> user.isActive())      // Only active users
                     .take(10)                            // First 10 results
                     .timeout(Duration.ofSeconds(5))       // Timeout after 5 seconds
                     .log();                              // Log what's happening
}
```

---

## Part 3: Advanced Concepts

### 3.1 Backpressure - Handling Fast Producers

When data comes faster than you can process it:

```java
@GetMapping("/fast-data")
public Flux<Data> handleFastStream() {
    return dataService.getFastStreamingData()
                     .onBackpressureBuffer(1000)          // Buffer up to 1000 items
                     .delayElements(Duration.ofMillis(10)) // Slow down processing
                     .doOnNext(data -> processData(data)); // Process each item
}
```

### 3.2 WebClient - Reactive HTTP Client

Call other services reactively:

```java
@Service
public class ApiService {
    
    private final WebClient webClient;
    
    public ApiService(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.baseUrl("https://api.example.com").build();
    }
    
    public Mono<User> fetchUserData(String userId) {
        return webClient.get()
                       .uri("/users/{id}", userId)
                       .retrieve()
                       .bodyToMono(User.class)
                       .timeout(Duration.ofSeconds(3))
                       .retry(3); // Retry up to 3 times on failure
    }
    
    public Flux<Post> fetchUserPosts(String userId) {
        return webClient.get()
                       .uri("/users/{id}/posts", userId)
                       .retrieve()
                       .bodyToFlux(Post.class);
    }
}
```

### 3.3 Testing Reactive Code

```java
@WebFluxTest(UserController.class)
public class UserControllerTest {
    
    @Autowired
    private WebTestClient webTestClient;
    
    @MockBean
    private UserService userService;
    
    @Test
    public void testGetUser() {
        User mockUser = new User("test", "test@example.com");
        
        when(userService.getUserById("123")).thenReturn(Mono.just(mockUser));
        
        webTestClient.get()
                    .uri("/user/123")
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.name").isEqualTo("test")
                    .jsonPath("$.email").isEqualTo("test@example.com");
    }
    
    @Test
    public void testGetUserStream() {
        User user1 = new User("Alice", "alice@example.com");
        User user2 = new User("Bob", "bob@example.com");
        
        when(userService.getAllUsers()).thenReturn(Flux.just(user1, user2));
        
        webTestClient.get()
                    .uri("/users")
                    .exchange()
                    .expectStatus().isOk()
                    .expectBodyList(User.class)
                    .hasSize(2)
                    .contains(user1, user2);
    }
}
```

### 3.4 Server-Sent Events (SSE) for Real-Time Updates

```java
@GetMapping(value = "/notifications", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
public Flux<ServerSentEvent<Notification>> getNotifications() {
    return notificationService.getNotificationStream()
                             .map(notification -> ServerSentEvent.builder(notification)
                                                                 .id(notification.getId())
                                                                 .event("new-notification")
                                                                 .build());
}
```

### 3.5 Global Error Handling

```java
@ControllerAdvice
public class GlobalErrorHandler extends AbstractErrorWebExceptionHandler {
    
    public GlobalErrorHandler(ErrorAttributes errorAttributes, 
                             WebProperties.Resources resources,
                             ApplicationContext applicationContext,
                             ServerCodecConfigurer serverCodecConfigurer) {
        super(errorAttributes, resources, applicationContext);
        this.setMessageWriters(serverCodecConfigurer.getWriters());
    }
    
    @Override
    protected RouterFunction<ServerResponse> getRoutingFunction(ErrorAttributes errorAttributes) {
        return RouterFunctions.route(RequestPredicates.all(), this::renderErrorResponse);
    }
    
    private Mono<ServerResponse> renderErrorResponse(ServerRequest request) {
        Map<String, Object> errorProperties = getErrorAttributes(request, ErrorAttributeOptions.defaults());
        int status = (int) errorProperties.get("status");
        return ServerResponse.status(status)
                           .contentType(MediaType.APPLICATION_JSON)
                           .body(BodyInserters.fromValue(errorProperties));
    }
}
```

### 3.6 Rate Limiting

```java
@GetMapping("/api/data")
public Mono<Data> getData() {
    return Mono.defer(() -> dataService.getExpensiveData())
               .transformDeferred(RateLimiter.ofDefaults("dataApi")); // Rate limit this endpoint
}
```

---

## Part 4: Real-World Example - Todo App with WebFlux

Let's build a complete reactive Todo application:

### 4.1 Model
```java
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Todo {
    private String id;
    private String task;
    private boolean completed;
    private Instant createdAt;
}
```

### 4.2 Repository (Using Reactive MongoDB)
```java
public interface TodoRepository extends ReactiveMongoRepository<Todo, String> {
    Flux<Todo> findByCompleted(boolean completed);
    Flux<Todo> findByTaskContaining(String keyword);
}
```

### 4.3 Service
```java
@Service
public class TodoService {
    
    private final TodoRepository todoRepository;
    
    public TodoService(TodoRepository todoRepository) {
        this.todoRepository = todoRepository;
    }
    
    public Flux<Todo> getAllTodos() {
        return todoRepository.findAll();
    }
    
    public Mono<Todo> getTodoById(String id) {
        return todoRepository.findById(id);
    }
    
    public Mono<Todo> createTodo(Todo todo) {
        todo.setId(null); // Let MongoDB generate ID
        todo.setCreatedAt(Instant.now());
        return todoRepository.save(todo);
    }
    
    public Mono<Todo> updateTodo(String id, Todo todo) {
        return todoRepository.findById(id)
                           .flatMap(existingTodo -> {
                               existingTodo.setTask(todo.getTask());
                               existingTodo.setCompleted(todo.isCompleted());
                               return todoRepository.save(existingTodo);
                           });
    }
    
    public Mono<Void> deleteTodo(String id) {
        return todoRepository.deleteById(id);
    }
    
    public Flux<Todo> getTodosByCompletion(boolean completed) {
        return todoRepository.findByCompleted(completed);
    }
    
    public Flux<Todo> searchTodos(String keyword) {
        return todoRepository.findByTaskContaining(keyword);
    }
}
```

### 4.4 Controller
```java
@RestController
@RequestMapping("/todos")
public class TodoController {
    
    private final TodoService todoService;
    
    public TodoController(TodoService todoService) {
        this.todoService = todoService;
    }
    
    @GetMapping
    public Flux<Todo> getAllTodos() {
        return todoService.getAllTodos();
    }
    
    @GetMapping("/{id}")
    public Mono<ResponseEntity<Todo>> getTodo(@PathVariable String id) {
        return todoService.getTodoById(id)
                        .map(ResponseEntity::ok)
                        .defaultIfEmpty(ResponseEntity.notFound().build());
    }
    
    @PostMapping
    public Mono<Todo> createTodo(@RequestBody Todo todo) {
        return todoService.createTodo(todo);
    }
    
    @PutMapping("/{id}")
    public Mono<ResponseEntity<Todo>> updateTodo(@PathVariable String id, @RequestBody Todo todo) {
        return todoService.updateTodo(id, todo)
                        .map(ResponseEntity::ok)
                        .defaultIfEmpty(ResponseEntity.notFound().build());
    }
    
    @DeleteMapping("/{id}")
    public Mono<ResponseEntity<Void>> deleteTodo(@PathVariable String id) {
        return todoService.deleteTodo(id)
                        .then(Mono.just(ResponseEntity.ok().<Void>build()))
                        .defaultIfEmpty(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/completed/{status}")
    public Flux<Todo> getTodosByStatus(@PathVariable boolean status) {
        return todoService.getTodosByCompletion(status);
    }
    
    @GetMapping("/search")
    public Flux<Todo> searchTodos(@RequestParam String q) {
        return todoService.searchTodos(q);
    }
    
    // Real-time stream of todo updates
    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<Todo> streamTodos() {
        return todoService.getAllTodos()
                        .delayElements(Duration.ofSeconds(1))
                        .repeat();
    }
}
```

### 4.5 Configuration
```java
@Configuration
public class WebFluxConfig implements WebFluxConfigurer {
    
    @Override
    public void configureHttpMessageCodecs(ServerCodecConfigurer configurer) {
        configurer.defaultCodecs().maxInMemorySize(16 * 1024 * 1024); // 16MB
    }
    
    @Bean
    public RouterFunction<ServerResponse> routerFunction(TodoHandler todoHandler) {
        return RouterFunctions.route()
            .GET("/api/v2/todos", todoHandler::getAllTodos)
            .GET("/api/v2/todos/{id}", todoHandler::getTodo)
            .POST("/api/v2/todos", todoHandler::createTodo)
            .build();
    }
}
```

---

## Part 5: Performance Tips & Best Practices

### 5.1 Do's and Don'ts

**DO:**
- Use reactive all the way down (database, HTTP clients)
- Handle errors properly with onError* methods
- Use backpressure strategies for fast data streams
- Test with WebTestClient

**DON'T:**
- Mix blocking code with reactive code
- Forget to subscribe() (WebFlux handles this for controllers)
- Ignore backpressure warnings

### 5.2 Monitoring and Debugging

```java
// Add to application.properties
logging.level.reactor=debug
logging.level.org.springframework.web.reactive=debug

// Add detailed logging to your flux
fluxOrMono.log("my.stream.name")
          .doOnNext(item -> log.debug("Processing: {}", item))
          .doOnError(error -> log.error("Error occurred: ", error));
```

### 5.3 Common Pitfalls

1. **Blocking in reactive code:** Never call blocking operations (Thread.sleep(), JDBC) inside reactive streams
2. **Forgetting to subscribe:** In services, return Publisher (Mono/Flux), don't call subscribe()
3. **Ignoring backpressure:** Handle cases where producer is faster than consumer

---

## Conclusion

Spring WebFlux is a powerful framework for building reactive applications. Start with simple Mono/Flux endpoints, gradually incorporate more advanced features like streaming, error handling, and WebClient, and always remember to think reactively - work with streams of data rather than individual values.

The key to mastering WebFlux is practice. Build small projects, experiment with different operators, and learn to think in terms of data streams. Happy coding!



[[0 - Spring Framework]]