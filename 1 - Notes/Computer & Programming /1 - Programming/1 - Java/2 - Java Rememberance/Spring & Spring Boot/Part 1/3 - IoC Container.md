Important clarification up front: the IoC container isn't some separate memory zone outside the JVM — it's just Java objects, living on the **heap** like everything else. There's no special hardware allocation for it. Let me break down why, and show the code.

## What is the IoC Container?

The **IoC (Inversion of Control) Container** is the core of Spring. It's an object (or set of objects) whose job is to:

1. Read your configuration (annotations, XML, or Java config)
2. **Instantiate** your classes (create objects — "beans")
3. **Wire** their dependencies together (inject one bean into another)
4. **Manage their lifecycle** (create, initialize, destroy)

Instead of you writing `new UserService(new UserRepository())`, you just declare the classes and their dependencies, and the container does the `new`-ing and wiring for you.

Spring has two main container interfaces:

- `BeanFactory` — the basic, lightweight container
- `ApplicationContext` — the one you actually use; it extends `BeanFactory` and adds enterprise features (event handling, internationalization, AOP integration, etc.)

## Creating the Container in Code

**Plain Spring (no Boot):**

```java
public class AppConfig {
    @Bean
    public UserRepository userRepository() {
        return new UserRepository();
    }

    @Bean
    public UserService userService() {
        return new UserService(userRepository());
    }
}

public class Main {
    public static void main(String[] args) {
        ApplicationContext context =
            new AnnotationConfigApplicationContext(AppConfig.class);

        UserService service = context.getBean(UserService.class);
        service.doSomething();
    }
}
```

`new AnnotationConfigApplicationContext(AppConfig.class)` — **that line creates the container.** It reads `AppConfig`, sees the `@Bean` methods, creates those objects, and stores them internally.

**With Spring Boot**, this happens for you automatically:

```java
@SpringBootApplication
public class MyApp {
    public static void main(String[] args) {
        SpringApplication.run(MyApp.class, args);
    }
}
```

`SpringApplication.run(...)` internally creates an `ApplicationContext` (specifically something like `AnnotationConfigServletWebServerApplicationContext` if it's a web app), scans your classes for `@Component`, `@Service`, `@Repository`, `@Controller`, etc., and builds the container — plus starts the embedded server.

## Using the Container

You rarely call `context.getBean()` directly in real apps — the container injects dependencies for you via `@Autowired` (or constructor injection, which is the modern recommended way):

```java
@Service
public class UserService {
    private final UserRepository repo;

    // Constructor injection — Spring sees this class needs a UserRepository
    // and supplies one from the container automatically
    @Autowired
    public UserService(UserRepository repo) {
        this.repo = repo;
    }
}
```

You just declare "I need a `UserRepository`," and the container figures out which bean to hand you.

## Now, the memory internals question

This is the key insight: **the IoC container has no special hardware-level memory allocation mechanism.** It's not like the stack/heap distinction at the JVM level. Here's what's actually happening:

### JVM memory recap

- **Stack**: one per thread, stores local variables, method call frames, references to objects. Fast, automatically popped when a method returns.
- **Heap**: shared across all threads, stores all objects created with `new`. Managed by the **Garbage Collector (GC)**. This is where actual object data lives.

### Where does the container live?

The `ApplicationContext` object itself is **just a Java object** — created with `new`, sitting on the **heap**, like any other object. It internally holds data structures (mainly `Map`s) mapping bean names to bean instances — something conceptually like:

```java
Map<String, Object> singletonBeans; // bean name -> bean instance
```

When the container "creates a bean," under the hood it is literally calling `new SomeClass(...)` (via reflection, using `Constructor.newInstance()`), and the resulting object goes on the **heap**, exactly as if you'd written `new` yourself. The container just keeps a _reference_ to it in its internal map so it can hand it out later and reuse it (for singleton-scoped beans, which is the default).

So in terms of hardware/OS:

- No special memory region is requested from the OS for "Spring beans"
- It's the same heap memory the JVM already requested from the OS at startup (via `-Xms`/`-Xmx` or defaults), managed by the same GC
- Reflection-based instantiation (which Spring uses heavily) is slightly slower than direct `new` calls due to extra JVM-level checks, but the resulting objects are ordinary heap objects — GC doesn't treat them specially

### What actually differs from manual object creation

||Manual `new`|Spring-managed bean|
|---|---|---|
|Memory location|Heap|Heap (same)|
|How it's created|Direct bytecode `new` + constructor call|Reflection (`Constructor.newInstance()`) or CGLIB-generated subclass proxies|
|Who holds the reference|Whoever calls `new`|The container's internal bean map, plus anyone it's injected into|
|Lifecycle|You manage it, GC collects when unreachable|Container manages init/destroy callbacks, but GC still collects the same way once unreachable|

One nuance: for `@Transactional`, `@Async`, AOP-proxied beans, etc., Spring often doesn't give you the raw object — it gives you a **dynamically generated proxy object** (via CGLIB or JDK dynamic proxies) that wraps your real object. That proxy is _also_ just a heap object; it just adds an extra layer of method interception before delegating to your actual bean.

So: **no separate "container memory" exists in hardware terms.** The container is a bookkeeping layer written in Java, running inside the same JVM heap/stack model you already know — it just automates the `new` + wiring + lifecycle management you'd otherwise do by hand.

Want to see this proven experimentally — e.g., printing `System.identityHashCode()` of a bean to confirm it's a normal heap object, or looking at what a CGLIB proxy class actually looks like?

[[0 - Spring + Spring Boot]]
[[0 - Spring Framework]]
[[Java]]
[[11 - IoC & DI 🍩]]
[[12 - DI & AutoWired 🍩]]
[[4 - What is dependency and DI]]