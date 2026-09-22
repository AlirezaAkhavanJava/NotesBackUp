
```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
```


These two imports are small, but they sit at the **center of Spring Boot startup and auto-configuration**. If you understand them properly, a lot of the “magic” of Spring Boot becomes much less magical.

---

# 1. The mental model

Start with this:

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
```

They represent **two different responsibilities**:

```text
@SpringBootApplication
        │
        ▼
"How should Spring configure my application?"
        │
        ▼
SpringApplication.run(...)
        │
        ▼
"Start the Spring application."
```

So:

- `@SpringBootApplication` → **configuration / metadata**
    
- `SpringApplication` → **startup / bootstrapping mechanism**
    

A typical application:

```java
@SpringBootApplication
public class MyApplication {

    public static void main(String[] args) {
        SpringApplication.run(MyApplication.class, args);
    }
}
```

The annotation tells Spring **what kind of application this is and where to look**.

`SpringApplication.run()` actually **creates and starts the Spring application context**.

---

# 2. `SpringApplication`

## Definition

```java
org.springframework.boot.SpringApplication
```

`SpringApplication` is a Spring Boot class responsible for **bootstrapping and launching a Spring application**.

The most common usage is:

```java
SpringApplication.run(MyApplication.class, args);
```

Think of it as the **orchestrator for application startup**.

It doesn't itself contain all the application logic.

Instead, it coordinates things like:

```text
JVM
 │
 ▼
main()
 │
 ▼
SpringApplication
 │
 ├── determine application type
 ├── create ApplicationContext
 ├── prepare Environment
 ├── load configuration
 ├── discover configuration classes
 ├── perform component scanning
 ├── apply auto-configuration
 ├── create/register beans
 ├── start embedded server if necessary
 ├── publish startup events
 └── return ApplicationContext
```

That's the important mental model.

---

# 3. What actually happens with `run()`

Consider:

```java
public static void main(String[] args) {
    SpringApplication.run(MyApplication.class, args);
}
```

Conceptually:

```text
SpringApplication.run()
        │
        ▼
Create SpringApplication
        │
        ▼
Prepare Environment
        │
        ▼
Create ApplicationContext
        │
        ▼
Load application configuration
        │
        ▼
Process @SpringBootApplication
        │
        ▼
Component scanning
        │
        ▼
Auto-configuration
        │
        ▼
Bean creation
        │
        ▼
ApplicationContext.refresh()
        │
        ▼
Application ready
```

The exact internal implementation is more complicated and changes between Spring Boot versions, but this is the correct architectural model.

---

# 4. `SpringApplication` isn't the same thing as `ApplicationContext`

This distinction is **very important**.

You will encounter:

```java
SpringApplication
```

and:

```java
ApplicationContext
```

They are not interchangeable.

### `SpringApplication`

Think:

> **"How do I bootstrap this application?"**

### `ApplicationContext`

Think:

> **"The running Spring container containing my beans."**

For example:

```java
ConfigurableApplicationContext context =
        SpringApplication.run(MyApplication.class, args);
```

Now:

```text
SpringApplication
       │
       │ creates/configures
       ▼
ApplicationContext
       │
       ├── UserService
       ├── UserRepository
       ├── UserController
       ├── DataSource
       ├── EntityManager
       └── ...
```

The context is essentially the **runtime container**.

---

# 5. Why does `run()` accept `MyApplication.class`?

This:

```java
SpringApplication.run(MyApplication.class, args);
```

isn't arbitrary.

You're giving Spring Boot a **primary source**.

```java
MyApplication.class
```

is usually:

```java
@SpringBootApplication
public class MyApplication {
}
```

Spring Boot uses this class as an important starting point for discovering configuration.

For example:

```text
com.example
│
├── MyApplication.java
│
├── controller
│   └── UserController.java
│
├── service
│   └── UserService.java
│
└── repository
    └── UserRepository.java
```

Because `MyApplication` is in:

```text
com.example
```

component scanning normally searches:

```text
com.example
├── controller
├── service
├── repository
└── ...
```

This is why package placement matters.

---

# 6. Now the more interesting part: `@SpringBootApplication`

The second import:

```java
import org.springframework.boot.autoconfigure.SpringBootApplication;
```

imports an **annotation**.

Usage:

```java
@SpringBootApplication
public class MyApplication {
}
```

The important thing is that `@SpringBootApplication` is **not itself a startup mechanism**.

It is metadata telling Spring:

> "Treat this class as the primary configuration class for a Spring Boot application."

But there's something deeper.

---

# 7. `@SpringBootApplication` is a composite annotation

This is one of the most important things to understand.

Conceptually:

```java
@SpringBootApplication
```

combines three major annotations:

```java
@Configuration
@EnableAutoConfiguration
@ComponentScan
```

So:

```java
@SpringBootApplication
```

is roughly equivalent to:

```java
@Configuration
@EnableAutoConfiguration
@ComponentScan
public class MyApplication {
}
```

Not literally identical in every implementation detail, but architecturally this is the correct mental model.

---

# 8. First component: `@Configuration`

```java
@Configuration
```

means:

> "This class can provide configuration for the Spring container."

For example:

```java
@Configuration
public class AppConfig {

    @Bean
    public UserService userService() {
        return new UserService();
    }
}
```

Spring discovers `AppConfig` and processes its `@Bean` methods.

Therefore:

```java
@Bean
public UserService userService()
```

results in a bean being registered in the application context.

With:

```java
@SpringBootApplication
public class MyApplication {
}
```

your main class itself is treated as configuration.

You can therefore do:

```java
@SpringBootApplication
public class MyApplication {

    @Bean
    public Clock clock() {
        return Clock.systemUTC();
    }
}
```

and Spring can register that bean.

---

# 9. Second component: `@ComponentScan`

This is where your normal Spring application structure comes into play.

Suppose:

```java
package com.example;

@SpringBootApplication
public class MyApplication {
}
```

and:

```java
package com.example.service;

@Service
public class UserService {
}
```

`@ComponentScan` tells Spring to search for component classes such as:

```java
@Component
@Service
@Repository
@Controller
@RestController
```

So:

```text
MyApplication
      │
      ▼
@ComponentScan
      │
      ├── UserController
      ├── UserService
      └── UserRepository
```

and those become candidates for Spring bean registration.

---

# 10. Why package structure matters

This is a classic Spring Boot issue.

Imagine:

```text
com.example
└── MyApplication.java
```

but your controller is:

```text
org.foo.controller.UserController
```

By default:

```java
@ComponentScan
```

doesn't magically scan every Java package on your machine.

It starts from the package containing your application configuration class and scans downward.

So:

```text
com.example
├── service       ← scanned
├── repository    ← scanned
└── controller    ← scanned
```

but:

```text
org.foo.controller
```

is outside that hierarchy.

This is why the recommended structure is generally:

```text
com.example.myapp
│
├── MyApplication.java
│
├── controller
├── service
├── repository
├── entity
└── config
```

---

# 11. Third component: `@EnableAutoConfiguration`

This is where **Spring Boot's biggest convenience feature** enters.

Spring Framework itself doesn't automatically decide:

> "Oh, PostgreSQL is on the classpath, therefore I'll configure a DataSource."

Spring Boot adds that behavior through **auto-configuration**.

Conceptually:

```java
@EnableAutoConfiguration
```

means:

> "Look at the application's environment and classpath, then conditionally configure appropriate infrastructure."

For example, if you have:

```text
spring-boot-starter-web
```

on the classpath, Spring Boot detects relevant web infrastructure.

You may therefore get things such as:

```text
embedded web server
Spring MVC infrastructure
JSON support
HTTP message converters
DispatcherServlet
```

without manually configuring all of them.

---

# 12. Auto-configuration is conditional

This is crucial.

Spring Boot doesn't blindly configure everything.

It uses conditions.

Conceptually:

```text
Is DataSource available?
        │
        ├── yes → configure database infrastructure
        │
        └── no  → don't
```

Another example:

```text
Is Spring MVC available?
        │
        ├── yes → configure MVC infrastructure
        └── no
```

Conditions can inspect things like:

- classes on the classpath
    
- existing beans
    
- configuration properties
    
- application type
    
- environment properties
    

For example, a simplified conceptual condition:

```java
@ConditionalOnClass(DataSource.class)
```

means approximately:

> Only activate this configuration if `DataSource` exists.

Another common pattern:

```java
@ConditionalOnMissingBean
```

means approximately:

> Configure the default bean only if the application hasn't already provided one.

This is why Boot is **convention-based but overridable**.

---

# 13. This explains Spring Boot's "magic"

Suppose you add:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
```

and PostgreSQL.

Then you configure:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=postgres
spring.datasource.password=password
```

You don't manually create:

```java
DataSource
EntityManagerFactory
TransactionManager
```

in most applications.

Why?

Because:

```text
@SpringBootApplication
        │
        ▼
@EnableAutoConfiguration
        │
        ▼
Spring Boot auto-configurations
        │
        ▼
Conditional configuration
        │
        ▼
DataSource
EntityManagerFactory
TransactionManager
...
```

That's the machinery behind the apparent magic.

---

# 14. The relationship between the two imports

Now put everything together.

Your code:

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class MyApplication {

    public static void main(String[] args) {
        SpringApplication.run(MyApplication.class, args);
    }
}
```

has two separate mechanisms.

### Annotation

```java
@SpringBootApplication
```

defines the **application's configuration model**.

It effectively provides:

```text
@Configuration
@ComponentScan
@EnableAutoConfiguration
```

### Launcher

```java
SpringApplication.run(...)
```

performs the **bootstrap process**.

So:

```text
                 MyApplication.class
                        │
                        ▼
              @SpringBootApplication
                 /      |       \
                /       |        \
       @Configuration   |    @EnableAutoConfiguration
                         |
                  @ComponentScan
                        │
                        ▼
              ApplicationContext
                        │
                        ▼
                  Bean ecosystem
```

---

# 15. Why can't we just use `SpringApplication`?

You could technically build Spring applications with much more explicit configuration.

For example, Spring itself has mechanisms such as:

```java
@Configuration
@ComponentScan
@Bean
```

Spring Boot's value is that it combines:

```text
Spring Framework
       +
Bootstrapping
       +
Auto-configuration
       +
Opinionated defaults
       +
Externalized configuration
       +
Embedded server support
```

So `SpringApplication` is the **bootstrap engine**, while `@SpringBootApplication` gives that engine the primary configuration information.

---

# 16. What happens if you remove `@SpringBootApplication`?

Consider:

```java
public class MyApplication {

    public static void main(String[] args) {
        SpringApplication.run(MyApplication.class, args);
    }
}
```

You can still call:

```java
SpringApplication.run(...)
```

but you've removed the major Boot configuration annotation.

Now Spring doesn't automatically receive the same:

```text
@Configuration
@ComponentScan
@EnableAutoConfiguration
```

setup from this class.

You could explicitly provide configuration classes:

```java
@Configuration
@EnableAutoConfiguration
@ComponentScan
public class MyApplication {
}
```

This demonstrates something important:

> `SpringApplication` does not equal `@SpringBootApplication`.

They're independent concepts.

---

# 17. You can customize `SpringApplication`

You aren't limited to:

```java
SpringApplication.run(MyApplication.class, args);
```

You can explicitly construct it:

```java
public static void main(String[] args) {

    SpringApplication application =
            new SpringApplication(MyApplication.class);

    application.setAdditionalProfiles("dev");

    application.run(args);
}
```

This gives you access to startup configuration.

For example, you can configure:

- profiles
    
- application listeners
    
- startup behavior
    
- banner behavior
    
- application type
    
- initializers
    
- environment-related behavior
    

This is useful when you need control over the bootstrapping process.

---

# 18. `run()` returns something

A subtle but important detail:

```java
SpringApplication.run(...)
```

returns an:

```java
ConfigurableApplicationContext
```

So this is legal:

```java
ConfigurableApplicationContext context =
        SpringApplication.run(MyApplication.class, args);
```

You can then interact with the container:

```java
UserService service =
        context.getBean(UserService.class);
```

Although in normal Spring application code, you generally **don't manually retrieve beans like this**.

Instead, dependency injection is preferred:

```java
@Service
public class OrderService {

    private final UserService userService;

    public OrderService(UserService userService) {
        this.userService = userService;
    }
}
```

So `getBean()` is useful for understanding the container and for certain advanced/bootstrap scenarios, but it shouldn't become your normal application architecture.

---

# 19. Application type detection

Another interesting `SpringApplication` responsibility is determining what kind of application you're running.

Broadly, Spring Boot distinguishes between applications such as:

```text
SERVLET
REACTIVE
NONE
```

For example:

```text
Spring MVC
   ↓
Servlet web application

Spring WebFlux
   ↓
Reactive web application
```

Boot uses classpath information and configuration to determine appropriate infrastructure.

This is another example of:

> **classpath + conditions → application behavior**

---

# 20. Embedded server connection

Suppose your project has Spring Web.

You run:

```java
SpringApplication.run(MyApplication.class, args);
```

and suddenly:

```text
localhost:8080
```

works.

Where did the server come from?

Conceptually:

```text
SpringApplication
       │
       ▼
ApplicationContext
       │
       ▼
Auto-configuration
       │
       ▼
Web application configuration
       │
       ▼
Embedded server
       │
       ▼
Tomcat / Jetty / Undertow
```

For the normal Spring MVC starter, Tomcat is commonly the default embedded servlet container.

The important point:

**`SpringApplication` doesn't contain Tomcat.**

It coordinates startup; auto-configuration and dependencies determine what gets configured.

---

# 21. A useful distinction: dependency vs auto-configuration

This is a common source of confusion.

Suppose you add:

```xml
spring-boot-starter-data-jpa
```

The starter primarily helps bring the required dependencies onto the classpath.

Then:

```text
Dependency
   ↓
classes become available
   ↓
@EnableAutoConfiguration
   ↓
conditions evaluate
   ↓
appropriate configuration activates
```

So:

```text
Starter ≠ Auto-configuration
```

The starter helps establish the **classpath**.

Auto-configuration uses that classpath to decide what configuration should exist.

---

# 22. Why does Spring Boot use the classpath so heavily?

Java's classpath is essentially one of Spring Boot's major sources of runtime information.

For example:

```text
postgresql driver present?
        ↓
PostgreSQL-related classes exist?
        ↓
JDBC infrastructure potentially applicable
```

Similarly:

```text
Spring MVC classes present?
        ↓
Web application?
        ↓
MVC auto-configuration applicable
```

This is why removing a dependency can dramatically change application behavior.

You aren't just removing a library.

You're changing the **set of conditions that Spring Boot evaluates**.

---

# 23. The "back-off" principle

This is one of the most important advanced Spring Boot concepts.

Suppose Boot wants to create:

```java
DataSource
```

but you explicitly define one:

```java
@Bean
public DataSource dataSource() {
    ...
}
```

Many Boot auto-configurations are designed to **back off** when you provide your own configuration.

Conceptually:

```text
Boot:
"Should I create a DataSource?"

       ↓

Does user already have one?

       ↓ yes

"Okay, I'll back off."
```

This often uses:

```java
@ConditionalOnMissingBean
```

This gives you the combination:

```text
Convention by default
+
Explicit configuration when needed
```

That is one of the fundamental design philosophies of Spring Boot.

---

# 24. How to inspect what Boot actually auto-configured

When learning Spring Boot deeply, don't treat auto-configuration as black magic.

You can inspect it.

For example, enable debug output:

```properties
debug=true
```

Then startup logs include information about auto-configuration evaluation.

You'll see concepts such as:

```text
Positive matches
Negative matches
Unconditional classes
```

This lets you answer:

> "Why did Spring create this bean?"

or:

> "Why didn't Boot configure this thing?"

That is a very useful debugging skill.

---

# 25. Common misconception

### Wrong mental model

> "`@SpringBootApplication` starts Spring."

Not quite.

### Better model

```text
@SpringBootApplication
        ↓
defines configuration + scanning + auto-configuration

SpringApplication.run()
        ↓
bootstraps the application using that configuration
```

Another common misconception:

> "`SpringApplication` creates all my objects."

Not directly.

The **ApplicationContext / Spring container** manages beans.

`SpringApplication` orchestrates the creation and initialization of that container.

---

# 26. The whole startup picture

Here's the mental model I'd recommend remembering:

```text
                    JVM
                     │
                     ▼
                  main()
                     │
                     ▼
       SpringApplication.run(...)
                     │
                     ▼
            SpringApplication
                     │
          ┌──────────┴──────────┐
          │                     │
          ▼                     ▼
     Environment          ApplicationContext
                                │
                                ▼
                    @SpringBootApplication
                                │
             ┌──────────────────┼──────────────────┐
             ▼                  ▼                  ▼
       @Configuration    @ComponentScan    @EnableAutoConfiguration
             │                  │                  │
             │                  │                  │
             │                  ▼                  ▼
             │            @Component etc.      Conditions
             │                  │                  │
             └──────────────────┴──────────────────┘
                                │
                                ▼
                          Bean definitions
                                │
                                ▼
                         Bean instantiation
                                │
                                ▼
                       Dependency Injection
                                │
                                ▼
                       Application started
```

That's the architecture you should have in your head.

---

# 27. One final professional detail

If you inspect the actual annotation declaration in Spring Boot, you'll find that `@SpringBootApplication` has attributes allowing customization, for example:

```java
@SpringBootApplication(
    scanBasePackages = "com.example"
)
public class MyApplication {
}
```

You can also control auto-configuration exclusions:

```java
@SpringBootApplication(
    exclude = SomeAutoConfiguration.class
)
public class MyApplication {
}
```

However, don't reach for `scanBasePackages` casually.

If your package structure is correct, the default scanning behavior is usually preferable because it preserves Spring Boot's conventional architecture.

Similarly, excluding auto-config should generally have a **specific reason**, such as replacing Boot's default infrastructure with your own.

---

# The core knowledge to retain

If you remember only this:

```java
@SpringBootApplication
```

is essentially:

```java
@Configuration
@EnableAutoConfiguration
@ComponentScan
```

while:

```java
SpringApplication.run(MyApplication.class, args);
```

means:

> **Bootstrap a Spring application using `MyApplication` as its primary configuration source, create and refresh the application context, and start the application.**

And the deeper chain is:

```text
Dependencies
     ↓
Classpath
     ↓
Auto-configuration conditions
     ↓
Bean definitions
     ↓
ApplicationContext
     ↓
Dependency Injection
     ↓
Running application
```

That's the foundation for understanding why Spring Boot can give you a fully functioning web application from a surprisingly small amount of code.

### Test yourself

1. **If `SpringApplication.run()` is responsible for starting the application, why can't we say that `SpringApplication` itself is the Spring container? What is the role of `ApplicationContext` in between?**
    
2. **Suppose you add PostgreSQL + Spring Data JPA dependencies but don't manually define a `DataSource`. Explain the chain from the dependency being added to Spring Boot deciding whether to create a `DataSource`, including the role of conditional auto-configuration.**


[[0 - Spring Framework]]
[[Java]]
[[A - @SpringBootApplication]]