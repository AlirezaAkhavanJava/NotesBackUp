

A bean's lifecycle is the sequence of steps Spring runs for every object it manages: how the object is created, wired with its dependencies, prepared for use, and finally cleaned up when the application shuts down. Because Spring creates the object for you instead of you calling `new`, it also owns every step in between.

[^1]It matters because Spring gives you **hook points** along the way. A hook is a place where your code can run at a specific moment, for example right after dependencies are injected, or right before shutdown. Spring's own features (`@Autowired`, `@Transactional`, `@Async`) are built on these same hooks.

---

## The full order

**Phase 1: Before any bean object exists**

1. **Definitions are loaded.** Spring scans `@Component` classes, `@Configuration` classes and `@Bean` methods and turns each into a `BeanDefinition` (class, scope, dependencies, init/destroy method names). This is metadata only, as you saw in the BeanDefinition lesson.
2. **`BeanFactoryPostProcessor` runs.** It can read and modify the `BeanDefinition`s before any object is created.

**Phase 2: Building each bean (repeated per bean)**

3. **Instantiation:** the constructor or `@Bean` factory method is called.
4. **Dependency injection:** `@Autowired` fields and setters are filled.
5. **`Aware` callbacks:** `BeanNameAware`, `BeanFactoryAware`, `ApplicationContextAware`.
6. **`BeanPostProcessor.postProcessBeforeInitialization`**
7. **Init callbacks**, in this fixed order:
    1. `@PostConstruct`
    2. `InitializingBean.afterPropertiesSet()`
    3. custom `initMethod`
8. **`BeanPostProcessor.postProcessAfterInitialization`:** proxies are created here.

**Phase 3:** the bean is stored in the container and injected where needed.

**Phase 4: Shutdown**

9. `@PreDestroy`, then `DisposableBean.destroy()`, then custom `destroyMethod`.

---

## Watching the order in code

```java
@Component
public class DemoBean implements BeanNameAware, InitializingBean, DisposableBean {

    public DemoBean() {
        System.out.println("1. Constructor");
    }

    @Autowired
    public void setHelper(Helper helper) {
        System.out.println("2. Dependency injection");
    }

    @Override
    public void setBeanName(String name) {
        System.out.println("3. BeanNameAware: " + name);
    }

    @PostConstruct
    public void postConstruct() {
        System.out.println("4. @PostConstruct");
    }

    @Override
    public void afterPropertiesSet() {
        System.out.println("5. afterPropertiesSet");
    }

    @PreDestroy
    public void preDestroy() {
        System.out.println("6. @PreDestroy");
    }

    @Override
    public void destroy() {
        System.out.println("7. DisposableBean.destroy");
    }
}
```

```java
@Component
public class LoggingPostProcessor implements BeanPostProcessor {

    @Override
    public Object postProcessBeforeInitialization(Object bean, String name) {
        if (bean instanceof DemoBean) System.out.println("BPP before init");
        return bean;
    }

    @Override
    public Object postProcessAfterInitialization(Object bean, String name) {
        if (bean instanceof DemoBean) System.out.println("BPP after init");
        return bean;
    }
}
```

Output:

```
1. Constructor
2. Dependency injection
3. BeanNameAware: demoBean
BPP before init
4. @PostConstruct
5. afterPropertiesSet
BPP after init
... application runs ...
6. @PreDestroy
7. DisposableBean.destroy
```

Both `postProcess...` methods must **return a bean**. If you return `null`, later steps break. Also notice that `@PostConstruct` runs between the two `BeanPostProcessor` calls, because `@PostConstruct` is itself handled by a `BeanPostProcessor` (`CommonAnnotationBeanPostProcessor`).

---

## Each hook in detail

**Constructor.** With constructor injection, dependencies are ready here. With field injection, the field is still `null` inside the constructor, because injection is step 4.

```java
@Component
public class A {
    @Autowired private B b;

    public A() {
        System.out.println(b);   // null! injection has not happened yet
    }
}
```

**`@PostConstruct`.** The place for start-up work that needs injected dependencies: validating config, warming a cache, opening a connection. It is standard Jakarta, so it does not tie your class to Spring.

**`InitializingBean` and `initMethod`.** Same purpose as `@PostConstruct`. `initMethod` is useful for classes you cannot edit:

```java
@Bean(initMethod = "start", destroyMethod = "stop")
public ThirdPartyClient client() {
    return new ThirdPartyClient();
}
```

**`Aware` interfaces.** Give a bean information about its container (its own name, the `ApplicationContext`). Rarely needed, since you can usually just inject what you need.

**`BeanFactoryPostProcessor`.** Works on blueprints before objects exist. A real example is `PropertySourcesPlaceholderConfigurer`, which replaces `${...}` placeholders inside `BeanDefinition`s with real values.

**`BeanPostProcessor`.** Works on real bean objects. It is how `@Autowired`, `@PostConstruct`, `@Transactional` and `@Async` are implemented. The object returned from `postProcessAfterInitialization` is what goes into the container, so it can be a proxy wrapping your original.

**`@PreDestroy`, `DisposableBean`, `destroyMethod`.** Cleanup: closing pools, flushing buffers, stopping threads. They run when the context closes, which Spring Boot does automatically on normal shutdown.

---

## Things that change the picture

**Scope.**

|Scope|Lifecycle behavior|
|---|---|
|singleton (default)|Full lifecycle, once, normally at startup (unless `@Lazy`)|
|prototype|Created and initialized, then Spring forgets it. **Destroy callbacks never run**|
|request / session|Created and destroyed with the request or session|

**Proxies.** Step 8 is where AOP and `@Transactional` wrap your bean. Other beans receive the proxy, not your raw object. This is why a self-invocation inside the same class bypasses `@Transactional`: the call never goes through the proxy. This links to your AOP and proxy notes.

**Order between beans.** A bean's dependencies are fully initialized before it is. For ordering that injection does not imply, use `@DependsOn`.

**Failures.** If a constructor or `@PostConstruct` throws, the context fails to start.

---

## A related concept in short: application-level lifecycle

Everything above is per bean. There is also a lifecycle for the whole application, expressed as events: `ContextRefreshedEvent` (all beans created), `ApplicationReadyEvent` (Spring Boot is fully started), and `ContextClosedEvent` (shutdown begins). If your code should run when the _entire_ app is ready rather than one bean, use:

```java
@EventListener(ApplicationReadyEvent.class)
public void onReady() { ... }
```

For control over start and stop order of long-running components, implement `SmartLifecycle`.

---

## Summary

1. `BeanDefinition`s are loaded, and `BeanFactoryPostProcessor` can edit them.
2. Per bean: constructor, injection, `Aware`, `BeanPostProcessor` (before), `@PostConstruct` / `afterPropertiesSet` / `initMethod`, `BeanPostProcessor` (after, where proxies appear).
3. The bean is in use.
4. Shutdown: `@PreDestroy`, `destroy()`, `destroyMethod`.
5. Prototype beans never get destroy callbacks.

[[Spring Framework]]

[^1]: Spring provides specific points during its execution process where you can intercept, customize, or execute your own logic. These points are called hook points. For example, you can execute custom logic before a bean is initialized, after it is initialized, or before a request reaches a controller. Instead of modifying Spring's internal code, you use these predefined extension points to influence its behavior.
