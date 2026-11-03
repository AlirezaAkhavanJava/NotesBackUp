
A **Spring Container** is the part of the Spring Framework that **creates, configures, stores, and manages the objects (beans) in your application**.

Think of it as an **object factory + dependency injection manager + lifecycle manager**.

### The basic idea

Without Spring:

```java
TaskRepository repository = new TaskRepository();
TaskService service = new TaskService(repository);
TaskController controller = new TaskController(service);
```

**You** are responsible for:

- creating objects
    
- figuring out their dependencies
    
- connecting them together
    
- managing their lifecycle
    

With Spring:

```java
@Service
class TaskService {
    private final TaskRepository repository;

    public TaskService(TaskRepository repository) {
        this.repository = repository;
    }
}
```

Spring sees `@Service`, creates the `TaskService`, sees that it needs a `TaskRepository`, obtains that object from the container, and injects it.

Conceptually:

```text
                 Spring Container
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
   TaskRepository  TaskService  TaskController
          │            │            │
          └────────────┴────────────┘
                 dependencies
```

### What exactly is inside the container?

The container maintains a collection of **beans**.

```text
ApplicationContext
       │
       ├── TaskRepository bean
       ├── TaskService bean
       ├── TaskController bean
       ├── DataSource bean
       ├── EntityManager bean
       └── ...
```

A bean is simply an **object managed by Spring**.

For example:

```java
@Service
public class TaskService {
}
```

Spring effectively does something conceptually similar to:

```java
TaskService taskService = new TaskService(...);
```

and registers that object inside the container.

### The actual Spring Container

In modern Spring applications, the main container abstraction you'll encounter is:

```java
ApplicationContext
```

For example:

```java
ApplicationContext context =
        new AnnotationConfigApplicationContext(AppConfig.class);

TaskService service = context.getBean(TaskService.class);
```

With **Spring Boot**, you normally don't create this yourself.

```java
@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

`SpringApplication.run()` starts the application and creates the Spring `ApplicationContext`.

---

### The important distinction

**Spring Framework**

```text
Spring Container
      │
      └── ApplicationContext
             │
             └── BeanFactory
```

The container is responsible for things such as:

1. **Instantiation** — creating beans
    
2. **Dependency Injection** — connecting beans
    
3. **Configuration** — configuring beans
    
4. **Lifecycle management** — initialization/destruction
    
5. **Scope management** — singleton, prototype, request, etc.
    

So when you write:

```java
@RequiredArgsConstructor
@Service
public class TaskService {

    private final TaskRepository repository;
}
```

you're essentially telling Spring:

> "This class is a bean. It needs a `TaskRepository`. You manage creating it and give me its dependency."

That's the core idea behind **Inversion of Control (IoC)** and **Dependency Injection (DI)** in Spring.


[[Spring Framework]]