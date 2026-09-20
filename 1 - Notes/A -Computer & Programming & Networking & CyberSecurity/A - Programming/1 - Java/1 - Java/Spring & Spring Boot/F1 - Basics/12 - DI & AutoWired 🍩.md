**Date**: 2025-08-24  
**Course**: Java Language Fundamentals  
**Tags**: [[0 - Spring Framework]]

## Introduction

`@Autowired` is a Spring annotation that enables **automatic dependency injection (DI)**, allowing the Spring Container to inject beans (objects) into a class without manual setup. DI promotes **loose coupling**, making code modular, testable, and maintainable. This note covers `@Autowired`, its DI components, related annotations (`@Qualifier`, `@Primary`, `@Bean`, `@Lazy`, `@Scope`), their usage, and where they are applied in Spring Boot applications.

## Terms

- **Dependency Injection (DI)**: A pattern where dependencies are provided to a class instead of created internally.
- **Bean**: A Java object managed by the Spring Container.
- **@Autowired**: Automatically injects a bean into a field, constructor, or method.
- **Spring Container**: Manages beans and their lifecycle (e.g., `ApplicationContext`).
- **Loose Coupling**: Reducing direct dependencies between classes using interfaces or DI.

## Detailed Concepts

### Dependency Injection (DI)

DI allows Spring to inject dependencies, reducing tight coupling. Spring’s `ApplicationContext` creates and wires beans based on configuration (annotations, Java config, or XML).

- **Types of DI**:
    1. **Constructor Injection**: Inject via constructor (preferred for mandatory dependencies).
    2. **Setter Injection**: Inject via setter methods (for optional dependencies).
    3. **Field Injection**: Inject directly into fields (less recommended due to testability issues).

### @Autowired

`@Autowired` tells Spring to inject a matching bean. It can be used in classes annotated with `@Component`, `@Service`, `@Repository`, or `@Controller`/`@RestController`.

- **Field Injection**:
    - Quick but less testable; avoid in complex apps.
    - Example:
        
        ```java
        @Service
        public class UserService {
            @Autowired
            private UserRepository repository; // Direct injection
        }
        ```
        
- **Constructor Injection** (Recommended):
    - Ensures immutability and testability; `@Autowired` optional for single constructor (Spring 4.3+).
    - Example:
        
        ```java
        @Service
        public class UserService {
            private final UserRepository repository;
        
            @Autowired // Optional if single constructor
            public UserService(UserRepository repository) {
                this.repository = repository;
            }
        }
        ```
        
- **Setter Injection**:
    - For optional or dynamic dependencies.
    - Example:
        
        ```java
        @Service
        public class UserService {
            private UserRepository repository;
        
            @Autowired
            public void setRepository(UserRepository repository) {
                this.repository = repository;
            }
        }
        ```
        

### Related Annotations

These annotations enhance `@Autowired` and manage DI in specific scenarios.

1. **@Qualifier**
    
    - **Purpose**: Resolves ambiguity when multiple beans of the same type exist by specifying the bean name.
    - **Used In**: With `@Autowired` in `@Component`, `@Service`, `@Repository`, `@Controller`/`@RestController`.
    - **When**: Multiple implementations of an interface exist.
    - **Example**:
        
        ```java
        public interface NotificationService {
            void send(String message);
        }
        
        @Service("emailService")
        public class EmailService implements NotificationService {
            public void send(String message) { return "Email: " + message; }
        }
        
        @Service("smsService")
        public class SmsService implements NotificationService {
            public void send(String message) { return "SMS: " + message; }
        }
        
        @RestController
        public class NotificationController {
            private final NotificationService service;
        
            @Autowired
            public NotificationController(@Qualifier("emailService") NotificationService service) {
                this.service = service; // Injects EmailService
            }
        }
        ```
        
2. **@Primary**
    
    - **Purpose**: Marks a bean as the default choice when multiple beans of the same type exist.
    - **Used In**: `@Component`, `@Service`, `@Repository`, or `@Bean` in `@Configuration`.
    - **When**: To avoid `@Qualifier` by setting a default bean.
    - **Example**:
        
        ```java
        @Service
        @Primary
        public class EmailService implements NotificationService {
            public void send(String message) { return "Email: " + message; }
        }
        
        @Service
        public class SmsService implements NotificationService {
            public void send(String message) { return "SMS: " + message; }
        }
        
        @RestController
        public class NotificationController {
            @Autowired
            private NotificationService service; // Injects EmailService (primary)
        }
        ```
        
3. **@Bean**
    
    - **Purpose**: Defines a bean programmatically in a `@Configuration` class.
    - **Used In**: `@Configuration` classes.
    - **When**: For custom beans (e.g., third-party library objects).
    - **Example**:
        
        ```java
        @Configuration
        public class AppConfig {
            @Bean
            public NotificationService emailService() {
                return new EmailService();
            }
        }
        ```
        
4. **@Lazy**
    
    - **Purpose**: Delays bean initialization until first use, resolving circular dependencies or improving startup.
    - **Used In**: `@Component`, `@Service`, `@Repository`, `@Controller`, or `@Bean`.
    - **When**: For heavy beans or to fix circular dependencies.
    - **Example**:
        
        ```java
        @Service
        public class UserService {
            @Autowired
            @Lazy
            private OrderService orderService; // Initialized on first use
        }
        ```
        
5. **@Scope**
    
    - **Purpose**: Sets the scope of a bean (e.g., `singleton`, `prototype`, `request`, `session`).
    - **Used In**: `@Component`, `@Service`, `@Repository`, `@Controller`, or `@Bean`.
    - **When**: To control bean lifecycle (e.g., new instance per HTTP request).
    - **Example**:
        
        ```java
        @Service
        @Scope("prototype")
        public class UserService {
            // New instance for each injection
        }
        ```
        

## Where Annotations Are Used

- **@Autowired**: In `@Component`, `@Service`, `@Repository`, `@Controller`/`@RestController` to inject dependencies (e.g., `UserService` into `UserController`).
- **@Qualifier**: With `@Autowired` to specify a bean (e.g., choosing `EmailService` over `SmsService`).
- **@Primary**: On `@Service`, `@Repository`, or `@Bean` to mark a default bean.
- **@Bean**: In `@Configuration` classes to define custom beans.
- **@Lazy**: In any bean class to delay initialization.
- **@Scope**: In bean classes to set lifecycle (e.g., `request` scope in `@Controller`).

## Pitfalls

1. **Bean Not Found**:
    - Cause: Missing `@Component`/`@Service` or not scanned.
    - Fix: Add annotation and ensure `@ComponentScan` includes the package.
2. **Ambiguous Beans**:
    - Cause: Multiple beans of the same type.
    - Fix: Use `@Qualifier` or `@Primary`.
3. **Circular Dependencies**:
    - Cause: Beans depending on each other.
    - Fix: Use `@Lazy` or redesign.
4. **Field Injection**:
    - Cause: Less testable and explicit.
    - Fix: Prefer constructor injection.

## Best Practices

1. **Prefer Constructor Injection**: Ensures immutability and testability.
2. **Use @Qualifier or @Primary**: To handle multiple beans clearly.
3. **Define Custom Beans with @Bean**: For third-party or complex setups.
4. **Use @Lazy Sparingly**: Only for circular dependencies or heavy beans.
5. **Test with Mocks**: Use Mockito to mock dependencies in unit tests.
6. **Enable Component Scanning**: Use `@SpringBootApplication` or `@ComponentScan` to detect beans.

## Example Code

import org.springframework.beans.factory.annotation.Autowired; import org.springframework.beans.factory.annotation.Qualifier; import org.springframework.context.annotation.Bean; import org.springframework.context.annotation.Configuration; import org.springframework.context.annotation.Primary; import org.springframework.stereotype.Service; import org.springframework.web.bind.annotation.GetMapping; import org.springframework.web.bind.annotation.RestController;

// Interface  
public interface NotificationService {  
String send(String message);  
}

// Implementation 1  
@Service  
@Primary  
class EmailService implements NotificationService {  
public String send(String message) {  
return "Email: " + message;  
}  
}

// Implementation 2  
@Service  
@Qualifier("smsService")  
class SmsService implements NotificationService {  
public String send(String message) {  
return "SMS: " + message;  
}  
}

// Configuration  
@Configuration  
class AppConfig {  
@Bean  
public NotificationService customService() {  
return new EmailService();  
}  
}

// Controller  
@RestController  
class NotificationController {  
private final NotificationService primaryService;  
private final NotificationService smsService;

```
@Autowired
public NotificationController(
    NotificationService primaryService,
    @Qualifier("smsService") NotificationService smsService
) {
    this.primaryService = primaryService;
    this.smsService = smsService;
}

@GetMapping("/notify")
public String notify() {
    return primaryService.send("Hello") + " | " + smsService.send("Hello");
}
```

}