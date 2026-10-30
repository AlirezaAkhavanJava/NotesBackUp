![[Spring Bean Lifecycle Flow Infographic.png]]

A **bean** is just an object that Spring creates and manages for you. Because Spring owns it, the bean doesn't simply appear when you call `new`. It goes through a series of stages: Spring reads its definition, creates it, wires in its dependencies, lets you run setup code, hands it out to the rest of the app, and finally cleans it up when the application shuts down. That journey is the **bean lifecycle**.

Knowing the lifecycle matters because it tells you _where_ your code should run. Opening a connection, warming a cache, validating configuration, and releasing resources each belong at a specific moment. Put them at the wrong moment, and you get classic bugs like a `NullPointerException` in a constructor because a dependency hasn't been injected yet.

---

## The big picture

Here is the full journey of a singleton bean (the default scope) in order:

| #   | Stage                  | What happens                                                                                       | Your hook                                              |
| --- | ---------------------- | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| 0   | Definition loading     | Spring scans `@Component`, `@Bean`, etc. and records _recipes_ (bean definitions), not objects yet | `BeanFactoryPostProcessor`                             |
| 1   | Instantiation          | Spring calls the constructor                                                                       | Constructor                                            |
| 2   | Dependency injection   | Fields, setters, and other beans get wired in                                                      | `@Autowired`, setters                                  |
| 3   | Aware callbacks        | Bean learns its own name, factory, or context                                                      | `BeanNameAware`, `ApplicationContextAware`, etc.       |
| 4   | Before-init processing | Every `BeanPostProcessor` gets a first look                                                        | `postProcessBeforeInitialization`                      |
| 5   | Initialization         | Your setup code runs                                                                               | `@PostConstruct`, `afterPropertiesSet()`, `initMethod` |
| 6   | After-init processing  | Post-processors get a second look (proxies are created here)                                       | `postProcessAfterInitialization`                       |
| 7   | **Ready to use**       | The bean lives in the container and serves the app                                                 |                                                        |
| 8   | Destruction            | Context closes, cleanup runs                                                                       | `@PreDestroy`, `destroy()`, `destroyMethod`            |

Stages 1 to 6 are called **creation and initialization**. Stage 8 is **destruction**. Stage 7 is the long middle where your application actually does its work.

---

## Seeing it run

Reading about the order is one thing. Watching it print is better. Here is a bean that hooks into almost every stage:

```java
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.springframework.beans.factory.BeanNameAware;
import org.springframework.beans.factory.DisposableBean;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.stereotype.Component;

@Component
public class DemoBean implements BeanNameAware, InitializingBean, DisposableBean {

    private final OtherService otherService;

    public DemoBean(OtherService otherService) {
        this.otherService = otherService;
        System.out.println("1. Constructor");
    }

    @Override
    public void setBeanName(String name) {
        System.out.println("3. BeanNameAware: my name is " + name);
    }

    @PostConstruct
    public void postConstruct() {
        System.out.println("5. @PostConstruct");
    }

    @Override
    public void afterPropertiesSet() {
        System.out.println("6. InitializingBean.afterPropertiesSet");
    }

    @PreDestroy
    public void preDestroy() {
        System.out.println("8. @PreDestroy");
    }

    @Override
    public void destroy() {
        System.out.println("9. DisposableBean.destroy");
    }
}
```

**Line-by-line walkthrough**

- `implements BeanNameAware, InitializingBean, DisposableBean` opts the bean into three Spring interfaces. Each one is a hook Spring checks for.
- The **constructor** runs first. Spring has to create the object before it can do anything else. Since this class uses constructor injection, `otherService` is already available here.
- `setBeanName` is an _Aware_ callback. Spring calls it to tell the bean what name it has in the container (here, `demoBean`).
- `@PostConstruct` marks a method to run once the bean is fully built and all dependencies are injected. This is the most common place for setup code.
- `afterPropertiesSet()` does the same job as `@PostConstruct`, but through a Spring interface instead of an annotation. It runs right _after_ `@PostConstruct`.
- `@PreDestroy` runs when the context is closing, before the bean is thrown away.
- `destroy()` is the interface version of `@PreDestroy` and runs right _after_ it.

The console output would look like this:

```
1. Constructor
2. BeanNameAware: my name is demoBean
3. @PostConstruct
4. InitializingBean.afterPropertiesSet
... application runs ...
5. @PreDestroy
6. DisposableBean.destroy
```

(The numbers are from the table, so 2, 4, and 7 are missing because nothing here prints during them.)

---

## Each stage in detail

### Stage 0: Bean definitions (before any object exists)

When the application starts, Spring doesn't create objects right away. It first scans your classes and builds a **bean definition** for each one. A definition is a recipe: the class, the scope, the dependencies, the init and destroy methods.

There's a special hook at this point, `BeanFactoryPostProcessor`, which lets you _modify the recipes_ before any bean is cooked. Spring itself uses it to resolve `${...}` placeholders in your properties. You will rarely write one yourself.

### Stage 1: Instantiation

Spring calls your constructor. At this point the object exists, but it is only a raw shell. If you use **field** or **setter** injection, those dependencies are still `null` here. This is why this fails:

```java
@Component
public class BadBean {
    @Autowired
    private OtherService otherService;

    public BadBean() {
        otherService.doSomething(); // NullPointerException!
    }
}
```

With **constructor injection**, dependencies arrive as constructor parameters, so they _are_ available. That is one of several reasons constructor injection is recommended.

### Stage 2: Dependency injection

Spring fills in the rest: `@Autowired` fields, setter methods, `@Value` properties. After this stage, the bean is fully wired.

### Stage 3: Aware callbacks

Sometimes a bean needs to know something about its surroundings. The _Aware_ interfaces let Spring pass that information in:

|Interface|What you receive|
|---|---|
|`BeanNameAware`|The bean's name in the container|
|`BeanFactoryAware`|The `BeanFactory` that created it|
|`ApplicationContextAware`|The full `ApplicationContext`|

You need these rarely in everyday code. Use them only when a bean truly has to look up other beans programmatically or know its own name.

### Stage 4 and 6: BeanPostProcessor (the interceptors)

A `BeanPostProcessor` is a special bean that gets to look at **every other bean** as it is created. It has two methods:

```java
@Component
public class LoggingPostProcessor implements BeanPostProcessor {

    @Override
    public Object postProcessBeforeInitialization(Object bean, String beanName) {
        System.out.println("Before init: " + beanName);
        return bean;
    }

    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName) {
        System.out.println("After init: " + beanName);
        return bean;
    }
}
```

**Walkthrough**

- Both methods receive the bean and its name, and both _return_ a bean. That return value is important: you can return the same object or **replace it with a different one**, such as a wrapper or proxy.
- `postProcessBeforeInitialization` runs before your init methods. Spring's own `@PostConstruct` support is itself implemented through a post-processor at this stage.
- `postProcessAfterInitialization` runs after your init methods. This is where Spring wraps beans in **proxies** for features like `@Transactional`, `@Async`, and AOP. It is also why a transactional bean you inject is often a proxy rather than your actual class.

This one mechanism is behind much of Spring's "magic."

### Stage 5: Initialization callbacks

You have three ways to say "run this after the bean is ready," and they always run in the same order:

1. `@PostConstruct`
2. `afterPropertiesSet()` from `InitializingBean`
3. A custom init method declared in `@Bean(initMethod = "setup")`

**Which should you use?** `@PostConstruct` for beans you write yourself. It is simple and doesn't tie your class to Spring interfaces. The `initMethod` attribute is handy for third-party classes you can't edit:

```java
@Bean(initMethod = "start", destroyMethod = "shutdown")
public ThirdPartyClient client() {
    return new ThirdPartyClient();
}
```

Here, `ThirdPartyClient` has its own `start()` and `shutdown()` methods. You can't add annotations to that class, but you can tell Spring which methods to call.

### Stage 7: Ready

The bean is registered in the container. Every other bean that depends on it receives this instance (for singletons, always the _same_ one). The bean stays alive until the context shuts down.

### Stage 8: Destruction

When the `ApplicationContext` closes (for example, on `Ctrl+C` or `SIGTERM` in a Spring Boot app, or when you call `context.close()`), Spring destroys singleton beans in this order:

1. `@PreDestroy`
2. `destroy()` from `DisposableBean`
3. Custom `destroyMethod`

Use this to close connections, flush buffers, stop thread pools, or release file handles.

---

## How scope changes the story

The lifecycle above describes a **singleton**. Scope changes it:

|Scope|Created|Destruction callbacks|
|---|---|---|
|`singleton` (default)|Once, at startup (eagerly)|Yes, on context close|
|`prototype`|Every time it is requested|**No.** Spring creates it and hands it over, then forgets it|
|`request` / `session` (web)|Per HTTP request or session|Yes, when that request or session ends|

The prototype row catches people out. If a prototype bean holds a resource that needs closing, Spring will **not** call `@PreDestroy` for you. You must clean it up yourself.

---

## Common pitfalls

- **Heavy work in the constructor.** Keep constructors simple. Do real setup in `@PostConstruct`, where everything is wired.
- **Expecting `@PreDestroy` on prototypes.** As above, it won't run.
- **Calling a `@Transactional` method from `@PostConstruct`.** The proxy that adds transaction behavior is applied in stage 6, _after_ `@PostConstruct`, so the transaction may not be active yet.
- **Using `@PostConstruct` imports from `javax`.** On Spring Boot 3 and later, the package is `jakarta.annotation`.
- **Circular dependencies.** If bean A needs B and B needs A, Spring can't finish either one's creation cleanly. Spring Boot now rejects this by default, so redesign instead.

---

## A related concept in short: lazy initialization

By default, singletons are created **eagerly** at startup, so problems show up immediately. Adding `@Lazy` delays creation until the bean is first needed. That speeds up startup, but errors in that bean now appear later, at runtime, rather than at boot. The lifecycle stages stay the same. Only the _moment_ it begins changes.

---

## Quick recap

Think of it as: **construct → inject → aware → before-init → init → after-init → use → destroy**. For your own beans, you will mostly use just three tools: constructor injection, `@PostConstruct` for setup, and `@PreDestroy` for cleanup. The rest (`Aware` interfaces, `BeanPostProcessor`) is there for framework-level work and is good to understand even if you rarely write it.




[[Spring Framework]]