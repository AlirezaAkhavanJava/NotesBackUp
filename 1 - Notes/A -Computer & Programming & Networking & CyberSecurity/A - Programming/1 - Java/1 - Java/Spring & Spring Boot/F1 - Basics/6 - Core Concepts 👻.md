
## Overview

The **Spring Framework** is a powerful Java framework that simplifies enterprise application development by promoting loose coupling, modularity, and testability. Its core concepts—**Inversion of Control (IoC)**, **Dependency Injection (DI)**, and the **Spring Container (ApplicationContext)**—form the backbone of Spring’s architecture.

**Why Learn These Concepts?**

- **Loose Coupling**: Reduces dependencies between components, making code easier to maintain and test.
- **Modularity**: Enables reusable, interchangeable components.
- **Scalability**: Supports building robust enterprise applications.



---

## Core Concepts

### 1. Inversion of Control (IoC)

IoC is a design principle where the control of object creation and management is transferred from the application code to a framework (Spring). ==Instead of a class instantiating its dependencies directly, the framework provides them.==

**Why IoC?**

- Reduces tight coupling between classes.
- Simplifies testing by allowing dependency substitution.
- Centralizes object lifecycle management.

**Example (Without IoC)**:

```java
public class UserService {
    private UserRepository userRepository = new UserRepositoryImpl(); 
    // Tight coupling
}
```

**With IoC (Conceptual)**:  
The framework (Spring) creates and injects `UserRepository` into `UserService`.

```java
public class UserService {
	@AutoWrired
    private UserRepository userRepository; 
    //Loose coupling
}
```

### 2. Dependency Injection (DI)

DI is a specific implementation of IoC where dependencies are injected into a class, typically via:

- **Constructor Injection**: Preferred for mandatory dependencies.
- **Setter Injection**: Optional or changeable dependencies.
- **Field Injection**: Less recommended due to testing difficulties.

**Why DI?**

- Promotes loose coupling.
- Simplifies unit testing with mock objects.
- Centralizes dependency configuration.

**Example (Constructor Injection)**:

```java
public class UserService {
    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
}
```

### 3. Spring Container (ApplicationContext)

The **Spring Container**, specifically the `ApplicationContext`, is responsible for:

- Creating and managing objects (beans).
- Wiring dependencies.
- Handling bean lifecycle (initialization, destruction).

**Key Features**:

- **Bean Management**: Objects managed by Spring are called beans.
- **Configuration**: Beans are defined using annotations (`@Bean`, `@Component`) or XML.
- **Scopes**: Singleton (default), prototype, request, session, etc.

**Example (ApplicationContext)**:

```java
ApplicationContext context = new AnnotationConfigApplicationContext(AppConfig.class);
UserService userService = context.getBean(UserService.class);
```

---




## Key Differences Between Manual DI and Spring DI

|Aspect|Manual DI|Spring DI|
|---|---|---|
|**Dependency Creation**|Developer creates objects|Spring container creates beans|
|**Wiring**|Manual in code|Automatic via `@Autowired` or `@Bean`|
|**Configuration**|Scattered in code|Centralized in `@Configuration`|
|**Scalability**|Hard to manage in large apps|Scales well with Spring container|
|**Testing**|Requires manual mocks|Easy with Spring’s test support|

---

## Advanced Notes

- **Bean Scopes**:
    - Default: `singleton` (one instance per context).
    - `prototype`: New instance per request.
    - Example:
        
        ```java
        @Component
        @Scope("prototype")
        public class UserService { ... }
        ```
        
- **Qualifier for Multiple Implementations**:  
    If multiple beans implement the same interface, use `@Qualifier`:
    
    ```java
    @Autowired
    public UserService(@Qualifier("userRepositoryImpl") UserRepository userRepository) { ... }
    ```
    
- **Lifecycle Management**:  
    Use `@PostConstruct` and `@PreDestroy` for initialization and cleanup:
    
    ```java
    @PostConstruct
    public void init() {
        System.out.println("Bean initialized");
    }
    ```
    

### Common Scopes

1. **singleton** _(default)_
    
    - Only **one instance** of the bean per Spring container.
        
    - All requests for the bean return the same object.
        
    - Example: configuration services, caches.
        
2. **prototype**
    
    - A **new instance** is created each time you request the bean.
        
    - Spring does not manage its full lifecycle (no destroy).
        
    - Example: objects with short-lived state.
        
3. **request** _(web only)_
    
    - One bean instance per **HTTP request**.
        
    - Example: per-request data objects.
        
4. **session** _(web only)_
    
    - One bean instance per **HTTP session**.
        
    - Example: user session data.
        
5. **application** _(web only)_
    
    - One bean instance per **ServletContext** (web app).
        
    - Example: shared app-level objects.
        
6. **websocket** _(web only)_
    
    - One bean instance per **WebSocket session**.
---
## Conclusion

The core Spring concepts—IoC, DI, and the ApplicationContext—enable modular, testable, and maintainable Java applications. By refactoring a manual DI application to use Spring’s `@Configuration`, `@Bean`, and `@Component`, you experience firsthand how Spring simplifies dependency management. Continue exploring _Spring in Action_ (Ch. 1–2) and the Spring Core Guide to deepen your understanding, and experiment with additional features like bean scopes and lifecycle methods.

[[0 - Spring Framework]]