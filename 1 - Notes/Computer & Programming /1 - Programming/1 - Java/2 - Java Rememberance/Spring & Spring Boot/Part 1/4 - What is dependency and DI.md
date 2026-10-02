
> What is a dependency? I see the term **dependency** in a Maven `pom.xml`, and I think it can also mean a class or object that my code needs in order to work. Is that why we call it a dependency?
> And what does **injecting** mean in Dependency Injection? Does it simply mean providing or putting the required dependency into my code?


Good catch noticing that overlap — "dependency" is genuinely used in two related but different senses in the Spring/Maven world, and mixing them up trips up a lot of learners. Let's separate them clearly first, then get into DI itself.


## Two meanings of "dependency"

### 1. Maven dependency (a JAR / library)

When you see this in `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

This means: "my **project** depends on this external **library**" — a `.jar` file containing compiled classes that Maven downloads (from a repository) and puts on your classpath so you can use its classes in your code. This is a **build-time/compile-time** dependency — about which code is _available_ to you.

### 2. DI dependency (an object your class needs)

This is a completely different, **runtime** concept. If `UserService` needs a `UserRepository` to do its job, then `UserRepository` is a **dependency of `UserService`** — not a JAR, but an actual **object instance** that must exist and be given to `UserService` before it can work.

```java
public class UserService {
    private UserRepository userRepository; // <- this is a dependency
}
```

You're right that it's "a class/object my code needs" — that's exactly it. The word "dependency" is reused because the relationship is conceptually the same ("A depends on B to function"), just at different levels — Maven dependencies are about _code availability_, DI dependencies are about _object relationships at runtime_.

## What is Dependency Injection (DI), then?

DI is the pattern where, instead of a class **creating** its own dependencies, something **external** creates them and **hands them to** the class — "injects" them in, as you guessed.

### Without DI (manual, tight coupling)

```java
public class UserService {
    private UserRepository userRepository;

    public UserService() {
        this.userRepository = new UserRepository(); // class builds its own dependency
    }
}
```

Problem: `UserService` is now hard-wired to one specific `UserRepository` implementation. Hard to swap it out (e.g., for testing with a fake/mock), and if `UserRepository` itself needs dependencies, this chain of manual construction gets messy fast in a large app.

### With DI (Spring injects it)

```java
@Service
public class UserService {
    private final UserRepository userRepository;

    // Spring sees this constructor, notices it needs a UserRepository,
    // finds (or creates) one in the container, and passes it in automatically
    @Autowired
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
}

@Repository
public class UserRepository {
    // Spring also manages this one as a bean
}
```

Now `UserService` doesn't know or care _how_ `UserRepository` was built — it just declares "give me one in my constructor," and the IoC container (which we discussed earlier) supplies it.

## The three ways to inject

**1. Constructor injection (recommended — use this by default)**

```java
@Service
public class UserService {
    private final UserRepository userRepository;

    @Autowired // optional here if there's only one constructor — Spring 4.3+ infers it
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
}
```

Dependencies are `final`, guaranteed non-null once the object exists, easy to test (just call `new UserService(mockRepo)` in a test).

**2. Setter injection**

```java
@Service
public class UserService {
    private UserRepository userRepository;

    @Autowired
    public void setUserRepository(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
}
```

Used when a dependency is optional or needs to change after construction. Less preferred for required dependencies.

**3. Field injection (avoid in real projects, but you'll see it everywhere in tutorials)**

```java
@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;
}
```

Concise, but harder to test (can't easily construct the object with mocks) and hides the dependency — considered bad practice by Spring's own team, though extremely common in beginner examples.

## How it flows end-to-end

1. Maven downloads the `spring-boot-starter-*` **JARs** (dependency, meaning #1) → gives you access to `@Service`, `@Autowired`, `ApplicationContext`, etc.
2. At startup, Spring's component scan finds your `@Service`, `@Repository`, `@Controller` classes
3. For each one, it looks at what **objects** (dependency, meaning #2) the constructor needs
4. It creates those objects first (recursively, if they have their own dependencies), then **injects** them in — literally calling your constructor/setter/field with the object reference
5. The finished, fully-wired object goes into the container's bean map (as we discussed — just a heap object)

---
`@Required` is a setter-injection annotation that tells Spring "this property must be set" — if it isn't, Spring fails fast at startup instead of letting you hit a `NullPointerException` later at runtime.

## Important: it's deprecated

`@Required` has been **deprecated since Spring 5.1** in favor of constructor injection (where required dependencies are just constructor parameters — no annotation needed) and `@Autowired(required = true)` on setters. You'll still see it in older codebases and tutorials, so it's worth knowing, but don't use it in new Spring Boot code.

## How it worked

```java
@Component
public class CustomerService {

    private CustomerRepository customerRepository;

    @Required
    public void setCustomerRepository(CustomerRepository customerRepository) {
        this.customerRepository = customerRepository;
    }
}
```

It only makes sense on a **setter method**, and it needed a special bean post-processor (`RequiredAnnotationBeanPostProcessor`) registered to actually be enforced — in plain XML config you had to declare it yourself; with component scanning / `AnnotationConfigApplicationContext` it was auto-registered.

If the property was never set (no matching bean, or nobody called the setter manually), the context would fail to start with a `BeanInitializationException`.

## Why it fell out of favor

1. It only worked with **setter injection**, which itself is discouraged now.
2. **Constructor injection already gives you this for free** — a required dependency is just a constructor parameter, and Java won't let you construct the object without it:

```java
@Service
public class CustomerService {

    private final CustomerRepository customerRepository;

    // constructor injection — implicitly "required", no annotation needed
    public CustomerService(CustomerRepository customerRepository) {
        this.customerRepository = customerRepository;
    }
}
```

With a single constructor, you don't even need `@Autowired` on it in modern Spring Boot.

## Practical takeaway

|Old style|Modern equivalent|
|---|---|
|`@Required` on setter|Constructor injection (required by default)|
|`@Autowired(required = false)` on setter|`@Autowired(required = false)` still valid, or `Optional<T>` constructor param|

So: if you're writing new Spring Boot code, just use constructor injection for required dependencies and you get `@Required`'s guarantee automatically, with better testability and immutability (`final` fields) as a bonus.


[[0 - Spring + Spring Boot]]
[[0 - Spring Framework]]
[[Java]]