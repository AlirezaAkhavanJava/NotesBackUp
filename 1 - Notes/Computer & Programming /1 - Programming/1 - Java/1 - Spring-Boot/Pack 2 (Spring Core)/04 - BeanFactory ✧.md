

`BeanFactory` is the root interface of Spring's **IoC (Inversion of Control) container**. Its job is simple to say: it creates your objects (called **beans**), wires them together, and hands them to you when you ask. Instead of writing `new UserService()` all over your code, you describe what you need and let Spring build it.

You will ***almost never*** use `BeanFactory` directly in a Spring Boot app. You will use its bigger sibling, `ApplicationContext`, which builds on `BeanFactory` and adds extra features. But `BeanFactory` is the engine underneath, so understanding it explains how the whole container works.

---

## The basic idea

Without Spring, you build and connect objects by hand:

```java
UserService service = new UserService();
```

With Spring, you ask the container for the object:

```java
UserService service = beanFactory.getBean(UserService.class);
```

Spring creates it, injects whatever it needs, and gives it to you.

---

## What a BeanFactory does

### 1. Creates beans

It reads **bean definitions** (recipes saying "this class is a bean") and builds objects from them. The definitions can come from `@Bean` methods, `@Component` scanning, or XML.

```java
@Configuration
public class AppConfig {

    @Bean
    public UserService userService() {
        return new UserService();
    }
}
```

### 2. Injects dependencies

```java
@Service
public class OrderService {

    private final PaymentService paymentService;

    public OrderService(PaymentService paymentService) {
        this.paymentService = paymentService;
    }
}
```

The container thinks it through like this:

```
OrderService needs a PaymentService
        -> find the PaymentService bean (create it first if needed)
        -> pass it into the OrderService constructor
```

### 3. Manages the lifecycle

```
Create object -> Inject dependencies -> Initialize -> Use -> Destroy
```

You can hook into the initialize and destroy steps with `@PostConstruct` and `@PreDestroy`. (Prototype beans are the exception: Spring does not destroy them.)

### 4. Looks up beans

```java
UserService a = factory.getBean(UserService.class);        // by type
UserService b = (UserService) factory.getBean("userService"); // by name, needs a cast
UserService c = factory.getBean("userService", UserService.class); // by name + type, no cast
```

The default bean name is the `@Bean` method name (or the class name with a lowercase first letter for `@Component`).

Two exceptions to know:

- `NoSuchBeanDefinitionException`: no bean matches.
- `NoUniqueBeanDefinitionException`: more than one bean matches, so Spring can't choose. `@Primary` or `@Qualifier` fixes this.

---

## A real, plain BeanFactory

Here is what a "pure" `BeanFactory` looks like, with no `ApplicationContext` involved:

```java
DefaultListableBeanFactory factory = new DefaultListableBeanFactory();

BeanDefinition definition = BeanDefinitionBuilder
        .genericBeanDefinition(UserService.class)
        .getBeanDefinition();

factory.registerBeanDefinition("userService", definition);

UserService service = factory.getBean(UserService.class);
```

Line by line:

1. `DefaultListableBeanFactory` is the standard `BeanFactory` implementation. Spring Boot uses it internally too.
2. You build a bean definition (the recipe) for `UserService`.
3. You register it under the name `"userService"`.
4. You ask for the bean, and the container builds it.

Notice how manual that was. A plain `BeanFactory` does **not** process annotations like `@Autowired`, `@PostConstruct`, or `@Transactional` on its own. You would have to register the post-processors that handle them yourself.

---

## BeanFactory vs ApplicationContext

`ApplicationContext` extends `BeanFactory`, so it can do everything a `BeanFactory` does and more. In fact, an `ApplicationContext` **contains** a `DefaultListableBeanFactory` and delegates bean work to it.

```
BeanFactory                (core: create, wire, look up beans)
     ^
ApplicationContext         (adds the features below)
```

|Feature|BeanFactory|ApplicationContext|
|---|---|---|
|Create beans, inject dependencies, lifecycle|✅|✅|
|Singleton beans created|Lazily (on first `getBean`)|Eagerly at startup|
|Annotation processing and `BeanPostProcessor`s|Register by hand|Detected and registered automatically|
|Events (`ApplicationEvent`, `@EventListener`)|❌|✅|
|Messages / internationalization (`MessageSource`)|❌|✅|
|Resource loading, profiles, `Environment`|❌|✅|
|Used directly in Spring Boot|Rarely|Always|

**Eager startup is a real benefit.** If a bean is misconfigured, an `ApplicationContext` fails when the app starts, not later when a user hits that code.

---

## Why does BeanFactory still exist?

Two reasons:

- It is the **core contract**. Every `ApplicationContext` is built on it, so the container's real work happens in the `BeanFactory` part.
- It is useful for the rare case where you want a very small container, or want to inject it somewhere to fetch beans on demand.

In day-to-day code, you can inject it if you ever need it:

```java
@Component
public class BeanFinder {

    private final BeanFactory beanFactory;

    public BeanFinder(BeanFactory beanFactory) {
        this.beanFactory = beanFactory;
    }

    public PaymentService payment() {
        return beanFactory.getBean(PaymentService.class);
    }
}
```

---

## What Spring Boot does at startup

When you run `./mvnw spring-boot:run`, the main steps are:

```
SpringApplication.run()
   -> create an ApplicationContext (it holds a BeanFactory inside)
   -> scan for @Component, @Configuration, @Bean, auto-configuration
   -> register bean definitions
   -> run BeanFactoryPostProcessors and register BeanPostProcessors
   -> create singleton beans and inject their dependencies
   -> application is ready
```

Spring Boot is **not** a type of `BeanFactory`. It is a launcher that creates and configures an `ApplicationContext` for you.

---

## A related concept: FactoryBean

The names are easy to mix up. A **`BeanFactory`** is the container itself. A **`FactoryBean<T>`** is a special bean that _produces another object_ when you ask for it (for example, to build something with complicated setup code). `BeanFactory` = "the container", `FactoryBean` = "a bean that makes beans".

---

## Mental model

- **Bean:** an object managed by Spring.
- **BeanFactory:** the core container that creates, wires, and looks up beans.
- **ApplicationContext:** a `BeanFactory` plus events, messages, profiles, automatic annotation support, and eager startup.
- **Spring Boot:** creates and configures the `ApplicationContext` for you. You mostly work with it indirectly through `@Component`, `@Service`, `@Autowired`, and constructor injection.

---

## What I fixed in your note

1. **The example created a `BeanFactory` from `AnnotationConfigApplicationContext`.** That works, but it is really an `ApplicationContext` in disguise, which hides the difference you are trying to teach. I added a true `DefaultListableBeanFactory` example.
2. **The hierarchy "ApplicationContext → Spring Boot Application" was wrong.** Spring Boot isn't a subclass of anything here. It creates an `ApplicationContext`.
3. **"Create ApplicationContext → Create BeanFactory" in the startup flow:** the `BeanFactory` is created inside the `ApplicationContext`, not as a separate later step.
4. **The comparison table was vague** ("AOP: Limited vs Better"). The real differences are automatic post-processor registration, eager singleton creation, events, messages, and resources.
5. **Removed "Security integration" and "Validation" as `ApplicationContext` features.** They come from other Spring modules, not from the context itself.
6. **Removed the meaningless diagram** ("Database object → BeanFactory") and the repeated "Bean creation" explanation that appeared in both the intro and the responsibilities.
7. **Added:** by-name lookup needing a cast, the two common lookup exceptions, the prototype destroy note, and a short `FactoryBean` summary.

[[Spring Framework]]