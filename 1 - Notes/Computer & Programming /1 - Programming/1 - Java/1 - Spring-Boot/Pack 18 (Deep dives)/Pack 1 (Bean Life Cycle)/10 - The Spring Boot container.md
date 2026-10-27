


 **what is the thing that holds and manages your objects, and who creates it?** In Spring, that thing is called the **container**. It creates your objects (called **beans**), wires them together, and manages their lifecycle, so you never write `new UserService(new UserRepository())` yourself.

The confusion comes from mixing up two different things: the **container** (the object that holds your beans) and the **launcher** (the code that builds and starts it). `SpringApplication.run(...)` is the launcher. `ApplicationContext` is the container. Once you see that split, everything else falls into place.

---

## 1. What is the type of the container?

The container's type is **`ApplicationContext`**, an interface in `org.springframework.context`.

An interface can't be created directly, so Spring Boot picks a [^1]concrete class for you based on your app type:

|Your app type|Concrete container class|
|---|---|
|Web app (Spring MVC, servlet)|`AnnotationConfigServletWebServerApplicationContext`|
|Reactive web app (WebFlux)|`AnnotationConfigReactiveWebServerApplicationContext`|
|Non-web (console, batch)|`AnnotationConfigApplicationContext`|

You can see which one you got:

```java
ConfigurableApplicationContext ctx = SpringApplication.run(DummyProjectApplication.class, args);
System.out.println(ctx.getClass().getName());
```

For a normal web project, it prints the servlet one.

---

## 2. Why do we say "the container is an ApplicationContext"?

A container needs to do one basic job: **create beans and hand them out**. That job is defined by a smaller, older interface called **`BeanFactory`**.

`ApplicationContext` extends `BeanFactory` and adds the features real apps need:

|Feature|What it gives you|
|---|---|
|Bean creation and injection|Inherited from `BeanFactory`|
|Events|`ApplicationEventPublisher`, so beans can publish and listen to events|
|Environment|Access to `application.properties`, profiles, and env variables|
|Messages|Internationalization (i18n)|
|Resource loading|Load files from classpath, disk, or URLs|

So when people say "the container is an ApplicationContext", they mean: _the container is the full-featured, application-level version of the bean factory._ In everyday Spring talk, "container", "Spring container", "IoC container", and "ApplicationContext" all mean the same object.

---

## 3. What is `SpringApplication.run(DummyProjectApplication.class, args)`?

This is the line that **builds, starts, and returns the container**. It isn't the container itself. Here's the usual file:

```java
@SpringBootApplication
public class DummyProjectApplication {
    public static void main(String[] args) {
        SpringApplication.run(DummyProjectApplication.class, args);
    }
}
```

**Line by line:**

- `public static void main(String[] args)` is the normal Java entry point. Nothing Spring-specific yet.
- `SpringApplication.run(...)` is a **static helper method**. It does the whole startup for you.
- `DummyProjectApplication.class` is the first argument, called the **primary source**. It tells Spring: "start from this class. Read its annotations, and use its package as the starting point for scanning."
- `args` are the command-line arguments (like `--server.port=9090`). Spring turns them into properties.

**What happens inside `run`, in order:**

1. It creates a `SpringApplication` object.
2. It detects your app type (servlet web, reactive web, or none) by checking which libraries are on the classpath.
3. It prepares the `Environment`, loading `application.properties` or `application.yml`, env variables, and your command-line args.
4. It creates the right `ApplicationContext` class, from the table above.
5. It registers `DummyProjectApplication` as the first bean definition.
6. It calls `refresh()` on the context. This is the big step: it processes `@ComponentScan`, applies auto-configuration, creates all singleton beans, injects dependencies, and starts the embedded web server (Tomcat by default).
7. It runs any `CommandLineRunner` or `ApplicationRunner` beans.
8. It **returns** the running `ConfigurableApplicationContext`.

**This answers your last question.** `SpringApplication.run` doesn't look like an `ApplicationContext` because it isn't one. Look at its return type:

```java
ConfigurableApplicationContext ctx = SpringApplication.run(DummyProjectApplication.class, args);
```

Think of a car. `SpringApplication.run` is the ignition: you turn the key once. The `ApplicationContext` is the engine that keeps running afterward. The ignition starts the engine and hands it back to you, but it isn't the engine.

You usually ignore the return value, and the context keeps running anyway because the web server's threads keep the JVM alive.

---

## 4. What is `@SpringBootApplication`?

It's a [^2]**convenience annotation**, a shortcut for three annotations at once:

```java
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan
public @interface SpringBootApplication { ... }
```

|Annotation|The problem it solves|
|---|---|
|`@SpringBootConfiguration`|Marks the class as a configuration class (a specialized `@Configuration`). You can declare `@Bean` methods inside it.|
|`@EnableAutoConfiguration`|Spring Boot looks at your classpath and configures things for you. Found `spring-boot-starter-web`? It sets up Tomcat and Spring MVC. Found a PostgreSQL driver? It sets up a `DataSource`.|
|`@ComponentScan`|Finds your own classes (controllers, services, repositories) and registers them as beans.|

Without this annotation, you'd write all three by hand on your main class.

---

## 5. What is `@ComponentScan`?

**The problem it solves:** the container needs to know which classes should become beans. Listing every class manually would be painful. Component scanning lets Spring **search your packages and find them automatically.**

**How it works:**

1. It starts at the **package of the class that has the annotation**. For us, that's the package of `DummyProjectApplication`.
2. It searches that package and **all sub-packages**.
3. It registers every class annotated with `@Component` or one of its specializations as a bean definition.

The annotations it recognizes:

|Annotation|Typical use|
|---|---|
|`@Component`|Generic bean|
|`@Service`|Business logic|
|`@Repository`|Data access (also translates persistence exceptions)|
|`@Controller` / `@RestController`|Web layer|
|`@Configuration`|Config classes with `@Bean` methods|

`@Service`, `@Repository`, and `@Controller` are all meta-annotated with `@Component`, so the scanner treats them alike.

**Example:**

```
com.example.dummy
├── DummyProjectApplication     ← @SpringBootApplication (scan starts here)
├── controller
│   └── UserController          ← @RestController  ✅ found
├── service
│   └── UserService             ← @Service         ✅ found
└── repository
    └── UserRepository          ← @Repository      ✅ found

com.other
└── PaymentService              ← @Service         ❌ NOT found (outside the base package)
```

**The most common beginner trap** is putting a class outside the base package. It silently isn't scanned, and you later get `NoSuchBeanDefinitionException` or a 404 on an endpoint. Two fixes: move the class under the main package, or widen the scan:

```java
@SpringBootApplication(scanBasePackages = {"com.example.dummy", "com.other"})
```

Scanning only _registers bean definitions_ (recipes for creating beans). The actual objects are created later during `refresh()`.

---

## 6. Putting it all together

```
main()
  └─ SpringApplication.run(DummyProjectApplication.class, args)   ← the launcher
        ├─ detects app type, loads properties
        ├─ creates ApplicationContext                              ← the container
        ├─ reads @SpringBootApplication on your class
        │     ├─ @ComponentScan          → finds your @Service/@Controller/... 
        │     ├─ @EnableAutoConfiguration → adds Tomcat, DataSource, etc.
        │     └─ @SpringBootConfiguration → picks up your @Bean methods
        ├─ creates beans and injects dependencies
        ├─ starts the web server
        └─ returns the running ApplicationContext
```

---

## Related concept: `BeanFactory` in a few lines

`BeanFactory` is the **basic container interface**: it only creates and returns beans, and it creates them lazily (on first request). `ApplicationContext` builds on it, creating singletons eagerly at startup and adding events, environment, and the other features above. In practice you always work with `ApplicationContext`. `BeanFactory` just matters as the foundation underneath.

---





[[Spring Framework]]

[^1]: A concrete class in Java is a class that provides implementations for all its inherited abstract methods and can be instantiated (you can create objects from it using `new`). Unlike an abstract class or an interface, a concrete class represents a fully implemented class that is ready to use. It can contain fields, constructors, and methods, and it can extend other classes or implement interfaces. For example, `class UserService implements UserServiceInterface` is a concrete class if it implements all required abstract methods and is not declared `abstract`.

[^2]: A convenience annotation in Spring is an annotation that simplifies development by combining multiple annotations or providing a shorter, more readable way to achieve a common configuration. Instead of writing several annotations separately, developers can use a single convenience annotation that provides the same functionality. For example, `@RestController` is a convenience annotation that combines `@Controller` and `@ResponseBody`, allowing a class to handle HTTP requests and return response bodies directly without adding `@ResponseBody` to every handler method. These annotations reduce boilerplate code, improve readability, and make Spring applications easier to configure and maintain.
