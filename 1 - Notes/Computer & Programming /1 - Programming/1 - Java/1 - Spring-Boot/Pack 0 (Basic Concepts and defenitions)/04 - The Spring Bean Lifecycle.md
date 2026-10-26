


Every object that Spring manages (a "bean") goes through a fixed life: Spring reads its definition, creates it, wires in its dependencies, prepares it, hands it to your app, and finally cleans it up when the app shuts down. The picture you shared shows that life from top to bottom.

A **hook** is a spot in that life where you can run your own code. Some hooks belong to one bean (like `@PostConstruct`). Others see every bean in the app (like `postProcessBeforeInitialization`). Once you know the order, you always know _when_ your code runs and _what is ready_ at that moment.

## The order at a glance

|#|Hook|Runs|What is ready?|
|---|---|---|---|
|1|`BeanFactoryPostProcessor`|Once, before beans are created|Only bean _definitions_ (blueprints)|
|2|Constructor|Per bean|The object exists, nothing injected (except constructor args)|
|3|`@Autowired`, setters|Per bean|Dependencies injected|
|4|`BeanNameAware`, `ApplicationContextAware`, etc.|Per bean|Bean knows its name and container|
|5|`postProcessBeforeInitialization`|Every bean|Fully wired, not yet initialized|
|6|`@PostConstruct`, `afterPropertiesSet()`, `initMethod`|Per bean|Safe to start using dependencies|
|7|`postProcessAfterInitialization`|Every bean|Fully initialized, can be wrapped in a proxy|
|8|_(bean is in use)_|||
|9|`@PreDestroy`, `destroy()`, `destroyMethod`|Per bean, on shutdown|Last chance to release resources|

The blank gap in your picture is step 8. That is the long stretch where your bean does its real work.

---

## 1. BeanFactoryPostProcessor

This is the earliest hook, and it is different from the rest. It runs **before any normal bean is created**. It does not touch beans. It touches **bean definitions**, which are the blueprints Spring read from your `@Component`, `@Bean`, or XML config.

Think of a building plan. This hook lets you edit the plan _before_ anyone builds the house.

```java
@Component
public class MyFactoryPostProcessor implements BeanFactoryPostProcessor {

    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) {
        BeanDefinition def = beanFactory.getBeanDefinition("userService");
        def.setLazyInit(true); // change the blueprint
    }
}
```

Line by line:

- `implements BeanFactoryPostProcessor` tells Spring to call you early.
- `getBeanDefinition("userService")` fetches the blueprint for the bean named `userService`.
- `setLazyInit(true)` edits the blueprint so that bean is created only when first needed.

A real example you already use: `${db.url}` placeholders in your config are resolved by a `BeanFactoryPostProcessor` called `PropertySourcesPlaceholderConfigurer`.

**Watch out:** if you declare one with `@Bean`, make the method `static`. Otherwise Spring has to create your config class too early, and some features of that class will not work.

**Related concept, in short:** `BeanDefinitionRegistryPostProcessor` is a stricter cousin. It runs even earlier and can _add brand-new_ bean definitions, not just edit existing ones. Spring uses it to process `@Configuration` classes.

---

## 2. Constructor

Now Spring finally builds the object by calling its constructor. At this point it is a plain Java object. If you use **constructor injection**, the dependencies arrive here as arguments.

```java
@Service
public class OrderService {

    private final PaymentService paymentService;

    public OrderService(PaymentService paymentService) { // injected here
        this.paymentService = paymentService;
        System.out.println("2. Constructor");
    }
}
```

This is the style Spring recommends today. The field can be `final`, and the object is never half-built. With field or setter injection, though, the dependencies are **not** available yet in the constructor. Using them there gives you a `NullPointerException`.

---

## 3. @Autowired and setters

If you did not use constructor injection, Spring fills in dependencies right after the constructor. That is **field injection** (`@Autowired` on a field) or **setter injection**.

```java
@Service
public class ReportService {

    @Autowired
    private EmailService emailService;          // field injection

    private AuditService auditService;

    @Autowired
    public void setAuditService(AuditService auditService) { // setter injection
        this.auditService = auditService;
        System.out.println("3. Setter injection");
    }
}
```

The same step also sets simple values from `@Value("${app.name}")`. After this step, the bean has everything it needs from the container.

**Quick tip:** use constructor injection for required dependencies. Use setters only for optional ones.

---

## 4. Aware interfaces

Normally a bean knows nothing about Spring. The `*Aware` interfaces are a way to say, "Please tell me about the container I live in." Spring then calls a setter and hands you the information.

|Interface|What Spring gives you|
|---|---|
|`BeanNameAware`|The name of this bean|
|`BeanFactoryAware`|The `BeanFactory` that created it|
|`ApplicationContextAware`|The whole `ApplicationContext`|
|`EnvironmentAware`|The `Environment` (profiles, properties)|

```java
@Component
public class InfoBean implements BeanNameAware, ApplicationContextAware {

    @Override
    public void setBeanName(String name) {
        System.out.println("4. My bean name is " + name);
    }

    @Override
    public void setApplicationContext(ApplicationContext ctx) {
        System.out.println("4. Context id: " + ctx.getId());
    }
}
```

Use these rarely. They tie your class to Spring, which makes it harder to test. Most of the time, injecting what you need with `@Autowired` is cleaner. (Small detail: `ApplicationContextAware` is technically delivered by a built-in `BeanPostProcessor` just before step 5, but the order in your picture is the right way to think about it.)

---

## 5. postProcessBeforeInitialization

This is the first of two **`BeanPostProcessor`** methods. A `BeanPostProcessor` is different from the hooks above because it is called for **every bean in the app**, not just one.

This method runs **before** the init callbacks of step 6. The bean is wired but not yet "started".

```java
@Component
public class LoggingBeanPostProcessor implements BeanPostProcessor {

    @Override
    public Object postProcessBeforeInitialization(Object bean, String beanName) {
        System.out.println("5. Before init: " + beanName);
        return bean; // must return the bean
    }
}
```

Line by line:

- `Object bean` is the bean Spring just built, and `String beanName` is its name.
- `return bean;` hands it back. You can return a _different_ object here and Spring will use that one instead.
- **Never return `null`.** Spring would lose your bean.

Typical uses: custom annotation processing, validation, or logging.

---

## 6. Init callbacks: @PostConstruct, afterPropertiesSet(), initMethod

Here is the bean's own "I'm ready, let me get started" moment. Everything is injected, so it is safe to use your dependencies. There are three ways to hook in, and they run in this order:

1. `@PostConstruct`
2. `afterPropertiesSet()` from the `InitializingBean` interface
3. A custom `initMethod`

```java
@Component
public class CacheLoader implements InitializingBean {

    @PostConstruct
    public void first() {                       // 1st
        System.out.println("6a. @PostConstruct");
    }

    @Override
    public void afterPropertiesSet() {          // 2nd
        System.out.println("6b. afterPropertiesSet");
    }

    public void customInit() {                  // 3rd
        System.out.println("6c. initMethod");
    }
}

@Configuration
class AppConfig {
    @Bean(initMethod = "customInit")
    public CacheLoader cacheLoader() {
        return new CacheLoader();
    }
}
```

Which one should you pick?

|Option|Ties you to Spring?|When to use|
|---|---|---|
|`@PostConstruct`|No (it is standard Jakarta)|**Default choice**|
|`afterPropertiesSet()`|Yes|Mostly in framework code|
|`initMethod`|No|Classes you cannot edit (third-party libraries)|

In Spring Boot 3, the annotation is `jakarta.annotation.PostConstruct`. Older versions used `javax.annotation`.

Good uses: load a cache, open a connection, validate that required config exists.

---

## 7. postProcessAfterInitialization

This is the second `BeanPostProcessor` method. It runs **after** all init callbacks. The bean is now completely ready.

This step matters more than it looks. It is where Spring **wraps beans in proxies**. When you put `@Transactional`, `@Async`, or `@Cacheable` on a method, a post-processor creates a proxy here and returns it in place of your original bean.

```java
@Override
public Object postProcessAfterInitialization(Object bean, String beanName) {
    System.out.println("7. After init: " + beanName);
    return bean; // or return a proxy wrapping it
}
```

So the object you receive with `@Autowired` can actually be a _proxy_, not your raw class. That is why calling a `@Transactional` method from another method **in the same class** does not start a transaction. The call skips the proxy.

---

## 8. The bean is in use

Your picture leaves this blank on purpose. For a singleton (the default), the bean now lives until the application shuts down, and every part of your app shares it.

---

## 9. Destroy callbacks: @PreDestroy, destroy(), destroyMethod

When the context closes (for example, you stop the app), Spring cleans up. These hooks mirror the init ones, and run in the same pattern:

1. `@PreDestroy`
2. `destroy()` from `DisposableBean`
3. A custom `destroyMethod`

```java
@Component
public class ConnectionHolder implements DisposableBean {

    @PreDestroy
    public void closeA() { System.out.println("9a. @PreDestroy"); }

    @Override
    public void destroy() { System.out.println("9b. destroy()"); }

    public void closeC() { System.out.println("9c. destroyMethod"); }
}
```

Use these to close connections, flush buffers, stop threads, or release files.

**Two things to know:**

- **`prototype` beans are never destroyed by Spring.** Spring creates them and then forgets them, so you must clean them up yourself.
- For `@Bean` methods, Spring auto-detects public `close()` or `shutdown()` methods. You do not always need to name a `destroyMethod`.

---

## See it all together

Put the pieces in one class and run it to watch the order print:

```java
@Component
public class Demo implements BeanNameAware, InitializingBean, DisposableBean {

    public Demo() { System.out.println("2. Constructor"); }

    @Autowired
    public void setEnv(Environment env) { System.out.println("3. Setter injection"); }

    @Override public void setBeanName(String n) { System.out.println("4. BeanNameAware"); }

    @PostConstruct
    public void post() { System.out.println("6a. @PostConstruct"); }

    @Override public void afterPropertiesSet() { System.out.println("6b. afterPropertiesSet"); }

    @PreDestroy
    public void pre() { System.out.println("9a. @PreDestroy"); }

    @Override public void destroy() { System.out.println("9b. destroy()"); }
}
```

Output (with the `BeanPostProcessor` from earlier also registered):

```
2. Constructor
3. Setter injection
4. BeanNameAware
5. Before init: demo
6a. @PostConstruct
6b. afterPropertiesSet
6. After init: demo
... app runs ...
9a. @PreDestroy
9b. destroy()
```

## Key takeaways

- **Two kinds of post-processors:** `BeanFactoryPostProcessor` edits _blueprints_ once, early. `BeanPostProcessor` touches _finished objects_, one by one, for every bean.
- **Prefer the annotations:** use `@PostConstruct` and `@PreDestroy`. They are simple and keep your class free of Spring interfaces.
- **Do not use dependencies in the constructor** unless they are constructor-injected. Use `@PostConstruct` for startup work.
- **Proxies appear in step 7.** This explains most "why doesn't my `@Transactional` work?" surprises.




[[Spring Framework]]