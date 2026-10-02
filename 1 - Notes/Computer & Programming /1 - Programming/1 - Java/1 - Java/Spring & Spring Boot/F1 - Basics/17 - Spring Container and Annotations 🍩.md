### Spring Container, ApplicationContext, and Annotations in Java

**Date**: 2025-08-24  
**Tags**: [[0 - Spring Framework]]

## What is the Spring Container?

The **Spring Container** is the core of the Spring Framework. It’s like a manager that creates, configures, and manages Java objects (called **beans**) in your application. It handles the lifecycle of beans, injects dependencies, and wires them together to make your app work smoothly.

- **Purpose**: Manages beans, their dependencies, and their lifecycle (creation, use, destruction).
- **Types**: Two main types of Spring Containers:
    - **BeanFactory**: Basic container, provides simple dependency injection (less commonly used).
    - **ApplicationContext**: Advanced container, adds features like internationalization, event handling, and annotations support (most commonly used).

## What is ApplicationContext?

The **ApplicationContext** is a powerful version of the Spring Container. It’s the central interface for managing beans and providing configuration in Spring applications. It loads bean definitions, resolves dependencies, and supports advanced features like annotations and web applications.

- **Key Features**:
    - Loads beans from configuration (XML, Java, or annotations).
    - Supports dependency injection (DI).
    - Manages bean lifecycle (init, destroy).
    - Provides utilities like event publishing and resource loading.
    - Commonly used in Spring Boot via auto-configuration.

## Key Concepts

- **Bean**: A Java object managed by the Spring Container (e.g., a service, repository, or controller).
- **Dependency Injection (DI)**: Spring injects dependencies (other beans) into a bean, reducing tight coupling.
- **Configuration**: Defines beans and their relationships using XML, Java config, or annotations.
- **Annotations**: Special tags (e.g., `@Component`, `@Autowired`) to simplify configuration and wiring.
- **Bean Scope**: Defines how beans are created and shared (e.g., singleton, prototype).

## Spring Annotations

Annotations are the easiest way to configure beans and dependencies in Spring. They reduce the need for XML or Java configuration files. Here are the key annotations:

### Core Annotations

1. **@Component**: Marks a class as a Spring bean, auto-detected during component scanning.
    - Example: `@Component` on a class makes it a bean.
2. **@Autowired**: Injects a dependency (bean) into a field, constructor, or setter.
    - Example: `@Autowired private UserService service;`
3. **@Bean**: Defines a bean in a `@Configuration` class (used in Java-based config).
    - Example: `@Bean public DataSource dataSource() {...}`
4. **@Configuration**: Marks a class as a source of bean definitions.
    - Example: `@Configuration` class with `@Bean` methods.
5. **@ComponentScan**: Tells Spring where to look for `@Component` classes.
    - Example: `@ComponentScan(basePackages = "com.example")`

### Stereotype Annotations (Specialized @Component)

6. **@Service**: Marks a class as a business logic (service) bean.
    - Example: `@Service` for service-layer classes.
7. **@Repository**: Marks a class as a data access (DAO) bean, adds database error handling.
    - Example: `@Repository` for repository classes.
8. **@Controller/@RestController**: Marks a class as a web controller for handling HTTP requests.
    - Example: `@RestController` for REST APIs.

### Other Useful Annotations

9. **@Qualifier**: Specifies which bean to inject when multiple beans of the same type exist.
    - Example: `@Autowired @Qualifier("specificBean")`
10. **@Scope**: Defines the scope of a bean (e.g., `singleton`, `prototype`).
    - Example: `@Scope("prototype")`
11. **@Value**: Injects values from properties files or environment variables.
    - Example: `@Value("${app.name}") String appName;`
12. **@PostConstruct/@PreDestroy**: Marks methods to run after bean creation or before destruction.
    - Example: `@PostConstruct void init() {...}`

## How It Works

1. **Start ApplicationContext**: Spring Boot auto-creates an `ApplicationContext` (e.g., `AnnotationConfigApplicationContext`).
2. **Scan for Beans**: Spring finds classes with `@Component`, `@Service`, etc., using `@ComponentScan`.
3. **Create Beans**: The container creates beans and injects dependencies using `@Autowired`.
4. **Manage Lifecycle**: Calls `@PostConstruct` after creation and `@PreDestroy` before destruction.
5. **Handle Requests**: In web apps, `@Controller` beans process HTTP requests.

## Common Issues

- **Bean Not Found**: Spring can’t find a bean for `@Autowired`.
    - **Fix**: Ensure the class is annotated with `@Component` (or similar) and included in component scanning.
- **Ambiguous Beans**: Multiple beans of the same type cause injection errors.
    - **Fix**: Use `@Qualifier` or `@Primary` to specify the bean.
- **Missing @ComponentScan**: Beans in other packages aren’t detected.
    - **Fix**: Add `@ComponentScan(basePackages = "com.example")`.
- **Circular Dependencies**: Beans depending on each other cause errors.
    - **Fix**: Refactor code or use `@Lazy` on one dependency.

## Best Practices

1. Use annotations over XML for simpler configuration.
2. Keep `@ComponentScan` focused to avoid scanning unnecessary packages.
3. Use `@Service`, `@Repository`, and `@Controller` for clear layer separation.
4. Inject dependencies via constructors for better testability.
5. Handle exceptions with `@ControllerAdvice` for REST APIs.
6. Use `@Value` for external configuration (e.g., `application.properties`).

## Example Code

```java
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Configuration;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

// Main Application
@SpringBootApplication // Includes @Configuration, @ComponentScan
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}

// Service Layer
@Service
class GreetingService {
    @Value("${app.greeting}") // From application.properties
    private String greeting;

    public String greet(String name) {
        return greeting + ", " + name + "!";
    }
}

// Component (General Bean)
@Component
class Logger {
    public void log(String message) {
        System.out.println("Log: " + message);
    }
}

// REST Controller
@RestController
class GreetingController {
    private final GreetingService service;
    private final Logger logger;

    @Autowired
    public GreetingController(GreetingService service, Logger logger) {
        this.service = service;
        this.logger = logger;
    }

    @GetMapping("/greet")
    public String greet(@RequestParam(defaultValue = "World") String name) {
        String result = service.greet(name);
        logger.log(result);
        return result;
    }
}
```

**application.properties**:

```properties
app.greeting=Hello
```

**Note**:

- Add `spring-boot-starter-web` to your project (Maven/Gradle).
- Run the app and access `http://localhost:8080/greet?name=Alice`.
- Expected output: `Hello, Alice!` (logged and returned).
- The `ApplicationContext` auto-scans `@Component`, `@Service`, and `@RestController`, injects dependencies with `@Autowired`, and loads `@Value` from properties.

## Advanced Notes

- **Types of ApplicationContext**:
    - `AnnotationConfigApplicationContext`: For annotation-based config.
    - `ClassPathXmlApplicationContext`: For XML-based config.
    - `WebApplicationContext`: For web apps (used by Spring MVC).
- **Bean Scopes**:
    - `singleton` (default): One instance per container.
    - `prototype`: New instance each time requested.
    - `request`, `session`, `application`: For web apps.
- **Spring Boot Auto-Configuration**: Spring Boot’s `@SpringBootApplication` creates an `ApplicationContext` and auto-configures beans based on dependencies.
- **Custom Beans**: Define beans in a `@Configuration` class with `@Bean` for fine-grained control.
    
    ```java
    @Configuration
    class AppConfig {
        @Bean
        public Logger customLogger() {
            return new Logger();
        }
    }
    ```
    

## Summary

The **Spring Container** (via `ApplicationContext`) manages beans, their dependencies, and lifecycle in a Java application. **ApplicationContext** is the main interface, supporting annotations, DI, and features like event handling. Key annotations like `@Component`, `@Service`, `@Repository`, `@RestController`, and `@Autowired` simplify configuration and wiring. Use annotations for ease, follow best practices like constructor injection, and leverage Spring Boot for automatic setup to build clean, maintainable applications.