

A **Spring stereotype annotation** is an annotation that tells Spring:

> **"This class represents a particular kind of application component, so discover it and register it as a Spring bean."**

The core stereotypes are:

```java
@Component
@Service
@Repository
@Controller
@RestController
```

The important idea is not the annotations themselves. It's the **architecture and dependency-injection mechanism behind them**.

---

# 1. The problem they solve

Without Spring, you might manually construct your application's objects:

```java
UserRepository repository = new UserRepository();
UserService service = new UserService(repository);
UserController controller = new UserController(service);
```

As the application grows:

```text
Controller
   ↓
Service
   ↓
Repository
   ↓
Database
```

you end up manually managing:

- object creation
    
- dependencies
    
- object lifetime
    
- configuration
    
- wiring
    
- initialization
    

Spring's **IoC container** takes responsibility for that.

You declare:

```java
@Service
public class UserService {

    private final UserRepository repository;

    public UserService(UserRepository repository) {
        this.repository = repository;
    }
}
```

and Spring handles the construction and dependency wiring.

So stereotypes are part of the mechanism that lets Spring discover **what objects belong in its container**.

---

# 2. The dependency chain

You need these concepts in this order:

```text
Stereotype annotations
        ↓
Component scanning
        ↓
Bean definition
        ↓
IoC container / ApplicationContext
        ↓
Bean creation
        ↓
Dependency Injection
        ↓
Your application
```

Let's break that down.

---

# 3. `@Component`

The fundamental stereotype is:

```java
@Component
public class EmailService {
}
```

It means:

> Make this class a Spring-managed component.

During component scanning, Spring finds it and registers it as a bean.

Conceptually:

```text
@Component
    ↓
Component scanning
    ↓
BeanDefinition
    ↓
ApplicationContext
    ↓
EmailService bean
```

Then another bean can depend on it:

```java
@Service
public class UserService {

    private final EmailService emailService;

    public UserService(EmailService emailService) {
        this.emailService = emailService;
    }
}
```

Spring sees:

```text
UserService
    │
    └── requires EmailService
                    │
                    ▼
              ApplicationContext
```

and injects the dependency.

---

# 4. Why do we have `@Service`, `@Repository`, etc.?

Because not every component has the same **semantic responsibility**.

For example:

```java
@Component
public class UserService
```

technically works.

But:

```java
@Service
public class UserService
```

communicates much more.

It tells developers:

> This component belongs to the service/business-logic layer.

Similarly:

```java
@Repository
public class UserRepository
```

communicates:

> This component performs persistence/data-access operations.

So stereotypes provide both:

1. **technical behavior**
    
2. **architectural meaning**
    

---

# 5. `@Service`

```java
@Service
public class UserService {
}
```

`@Service` is essentially a specialized form of `@Component`.

Its primary purpose is semantic:

> This is a service/business-logic component.

For example:

```java
@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User register(User user) {
        // business rules
        return userRepository.save(user);
    }
}
```

The important architectural boundary is:

```text
Controller
    ↓
Service
    ↓
Repository
```

The service is where your **application/business logic** generally lives.

---

# 6. `@Repository`

```java
@Repository
public class UserRepository {
}
```

Semantically:

> This component belongs to the persistence/data-access layer.

For example, a manually implemented repository:

```java
@Repository
public class UserRepository {

    private final JdbcTemplate jdbcTemplate;

    // SQL/data access
}
```

However, with Spring Data JPA:

```java
public interface UserRepository
        extends JpaRepository<User, UUID> {
}
```

you normally don't need to add `@Repository`.

Spring Data detects the repository interface and creates the implementation/proxy.

So:

```text
@Repository
```

and:

```text
JpaRepository
```

are related to the **repository layer**, but they solve different problems.

---

# 7. `@Controller`

```java
@Controller
public class UserController {
}
```

This marks a component as an MVC controller.

Its responsibility is handling web requests.

For example:

```java
@Controller
public class UserController {

    @GetMapping("/users")
    public String users() {
        return "users";
    }
}
```

The flow becomes:

```text
HTTP request
     ↓
DispatcherServlet
     ↓
UserController
     ↓
UserService
     ↓
UserRepository
```

---

# 8. `@RestController`

For REST APIs, you'll usually use:

```java
@RestController
public class UserController {
}
```

`@RestController` is effectively:

```java
@Controller
@ResponseBody
```

So:

```java
@RestController
public class UserController {

    @GetMapping("/users")
    public User getUser() {
        return userService.findUser();
    }
}
```

Spring serializes the returned object into the HTTP response, commonly JSON.

Conceptually:

```text
Java object
    ↓
HttpMessageConverter
    ↓
JSON
    ↓
HTTP response
```

---

# 9. The hierarchy

The easiest way to understand the stereotypes is:

```text
                    @Component
                        │
          ┌─────────────┼──────────────┐
          │             │              │
       @Service     @Repository    @Controller
                                       │
                                       ▼
                                @RestController
```

More precisely, the specialized stereotypes are meta-annotated with `@Component`.

For example, conceptually:

```java
@Component
public @interface Service {
}
```

Spring therefore recognizes `@Service` as a component during scanning.

---

# 10. Component scanning

This is one of the **dependent ideas** you need to understand.

Spring has to find these classes.

For example:

```java
@Service
public class UserService {
}
```

doesn't magically execute because you wrote `@Service`.

Spring needs to **scan packages** looking for component candidates.

Spring Boot normally establishes the component-scanning boundary from your application class.

For example:

```java
@SpringBootApplication
public class Application {
}
```

If:

```text
com.example
├── Application.java
├── controller
│   └── UserController.java
├── service
│   └── UserService.java
└── repository
    └── UserRepository.java
```

then Spring Boot can discover those components.

That's why package organization matters.

---

# 11. What happens during startup?

Simplified:

```text
SpringApplication.run(...)
          │
          ▼
Create ApplicationContext
          │
          ▼
Component scanning
          │
          ▼
Find @Component / @Service / @Repository / @Controller
          │
          ▼
Create BeanDefinitions
          │
          ▼
Create beans
          │
          ▼
Resolve dependencies
          │
          ▼
Inject dependencies
          │
          ▼
Application ready
```

Suppose you have:

```java
@Service
public class UserService {

    private final UserRepository repository;

    public UserService(UserRepository repository) {
        this.repository = repository;
    }
}
```

Spring effectively needs to solve:

```text
"I need a UserService."

UserService requires UserRepository.

"Do I have a UserRepository bean?"

Yes.

Construct:

UserService(repository)
```

That's **Dependency Injection**.

---

# 12. Stereotype vs Bean

This distinction is extremely important.

A stereotype is **not the bean itself**.

For example:

```java
@Service
public class UserService {
}
```

The class is a **component candidate**.

Spring then creates an actual object:

```text
Class
 │
 │ component scanning
 ▼
BeanDefinition
 │
 │ bean creation
 ▼
Object instance
 │
 ▼
Spring-managed Bean
```

So:

> **Bean = object managed by Spring's IoC container.**

Stereotype annotations are one way of telling Spring which classes should become beans.

---

# 13. Do stereotypes create objects?

Not directly.

This:

```java
@Service
public class UserService {
}
```

doesn't mean the Java annotation itself creates the object.

Instead:

```text
@Service
   ↓
Spring discovers class
   ↓
Spring registers bean definition
   ↓
Spring creates object
   ↓
Spring manages object
```

That's a crucial mental model.

---

# 14. Stereotypes vs `@Bean`

There's another way to register beans:

```java
@Configuration
public class AppConfig {

    @Bean
    public ObjectMapper objectMapper() {
        return new ObjectMapper();
    }
}
```

Here you explicitly tell Spring:

> Call this method and register its returned object as a bean.

Compare:

### Component scanning

```java
@Service
public class UserService {
}
```

### Explicit bean declaration

```java
@Configuration
public class AppConfig {

    @Bean
    public UserService userService() {
        return new UserService(...);
    }
}
```

So:

```text
@Component / @Service / @Repository
        ↓
"Discover this class"

@Bean
        ↓
"Register the object returned by this method"
```

Both produce Spring-managed beans, but through different mechanisms.

---

# 15. What problem does each stereotype communicate?

|Annotation|Architectural meaning|
|---|---|
|`@Component`|General Spring-managed component|
|`@Service`|Business/application service|
|`@Repository`|Persistence/data access|
|`@Controller`|MVC web controller|
|`@RestController`|REST/HTTP controller|

Think in terms of **responsibility** rather than syntax.

For a typical Spring Boot application:

```text
                 HTTP
                  │
                  ▼
        ┌──────────────────┐
        │ @RestController  │
        │  HTTP boundary   │
        └────────┬─────────┘
                 │
                 ▼
        ┌──────────────────┐
        │    @Service      │
        │ business logic   │
        └────────┬─────────┘
                 │
                 ▼
        ┌──────────────────┐
        │   Repository     │
        │  data access     │
        └────────┬─────────┘
                 │
                 ▼
              Database
```

That's why you'll see these annotations everywhere in Spring applications.

---

# 16. The professional mental model

Don't memorize:

> "`@Service` means service."

Instead, understand this chain:

```text
Stereotype
    ↓
Component candidate
    ↓
Component scanning
    ↓
BeanDefinition
    ↓
IoC Container
    ↓
Bean instance
    ↓
Dependency Injection
    ↓
Application architecture
```

And understand that the stereotype adds **semantic classification**:

```text
@Component
    = generic component

@Service
    = business/application component

@Repository
    = persistence component

@Controller
    = MVC web component

@RestController
    = REST web component
```

Once you understand **IoC + ApplicationContext + component scanning + BeanDefinition + dependency injection**, Spring stereotypes stop being magic annotations and become a very thin layer over Spring's bean-registration mechanism.


[[Java]]
[[0 - Spring Framework]]
