

The stages above tell you the _order_. This section answers the question you actually face when writing code: "I want to run something right now. Which hook do I use, and what can I safely touch at that moment?" Every hook sits at a different point in the bean's life, so each one has a different set of things that are already built and a different set of things that are not.

Some hooks belong to a single bean (like `@PostConstruct`). Others are called for **every bean in the app** (like `postProcessBeforeInitialization`). Keeping those two groups apart in your head clears up most of the confusion around the lifecycle. Let's go through them in order and see what each one is for.

### The one table to remember

|Stage|Hook|Runs for|What is ready at this moment|
|---|---|---|---|
|0|`BeanFactoryPostProcessor`|The whole container, once|Only bean _definitions_ (blueprints). No beans yet|
|1|Constructor|One bean|The raw object. Only constructor arguments are available|
|2|`@Autowired` fields, setters|One bean|Dependencies injected|
|3|`BeanNameAware`, `ApplicationContextAware`, etc.|One bean|The bean knows its name and its container|
|4|`postProcessBeforeInitialization`|**Every** bean|Fully wired, not yet initialized|
|5|`@PostConstruct`, `afterPropertiesSet()`, `initMethod`|One bean|Safe to use dependencies and start work|
|6|`postProcessAfterInitialization`|**Every** bean|Fully initialized, may be swapped for a proxy|
|7|_(in use)_||The bean does its real work|
|8|`@PreDestroy`, `destroy()`, `destroyMethod`|One bean, at shutdown|Last chance to release resources|

If you remember only one idea from this table, make it this: **the further down you go, the more is ready.** Most lifecycle bugs come from using something one row too early.

---

### Stage 0 in depth: editing the blueprint

Why does Spring give you a hook before any bean exists? Because sometimes you need to change _how_ beans will be built, and that has to happen before they are built. A `BeanFactoryPostProcessor` edits **bean definitions**, not beans. Think of a building plan: this hook lets you redraw the plan before anyone pours concrete.

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

**Line-by-line walkthrough**

- `implements BeanFactoryPostProcessor` tells Spring to call this class very early, before normal beans are created.
- `getBeanDefinition("userService")` fetches the recipe for the bean named `userService`. Note that it returns a _definition_, not the bean itself, because the bean does not exist yet.
- `setLazyInit(true)` edits the recipe so the bean is created only when it is first needed.

You already rely on this mechanism without knowing it. The `${db.url}` placeholders in your configuration are resolved by a `BeanFactoryPostProcessor` called `PropertySourcesPlaceholderConfigurer`.

**A trap to avoid.** If you declare a `BeanFactoryPostProcessor` with a `@Bean` method, make that method `static`:

```java
@Bean
public static MyFactoryPostProcessor myFactoryPostProcessor() {
    return new MyFactoryPostProcessor();
}
```

Without `static`, Spring has to create the surrounding `@Configuration` class _first_ just to call the method, and that is far too early. Features of that class, such as `@Autowired` fields and `@Value`, may then silently not work.

**A related concept: `BeanDefinitionRegistryPostProcessor`.** This is a stricter cousin that runs even earlier. A normal `BeanFactoryPostProcessor` can only _edit_ existing definitions, while this one can **add brand-new definitions** to the registry. Spring itself uses it to process your `@Configuration` classes and turn their `@Bean` methods into definitions. You will almost never write one, but it explains where those definitions come from.

---

### Stages 1 and 2 in depth: constructor versus injection

Spring builds the object with its constructor first, and only then fills in fields and setters. That order is the source of one of the most common beginner bugs, so let's look at it from the "what is ready" angle.

```java
@Service
public class OrderService {

    private final PaymentService paymentService;

    public OrderService(PaymentService paymentService) { // injected here
        this.paymentService = paymentService;
        System.out.println("1. Constructor");
    }
}
```

With **constructor injection**, dependencies arrive as arguments, so they are ready the moment the constructor runs. The field can be `final`, and the object is never half-built. This is the style Spring recommends today.

With **field or setter injection**, the dependency is still `null` inside the constructor:

```java
@Service
public class ReportService {

    @Autowired
    private EmailService emailService;          // field injection

    private AuditService auditService;

    @Autowired
    public void setAuditService(AuditService auditService) { // setter injection
        this.auditService = auditService;
        System.out.println("2. Setter injection");
    }
}
```

Spring runs the constructor, then injects `emailService`, then calls the setter. The same step also fills in `@Value("${app.name}")` properties. A rule of thumb: use constructor injection for required dependencies, and use setters only for optional ones.

---

### Stage 3 in depth: the Aware interfaces

Normally a bean knows nothing about Spring, which is a good thing because it keeps the class simple and easy to test. The `*Aware` interfaces are the exception. Implementing one means saying, "Please tell me about the container I live in," and Spring calls a setter to hand over the information.

|Interface|What Spring gives you|
|---|---|
|`BeanNameAware`|The name of this bean|
|`BeanFactoryAware`|The `BeanFactory` that created it|
|`ApplicationContextAware`|The whole `ApplicationContext`|
|`EnvironmentAware`|The `Environment` (profiles and properties)|

```java
@Component
public class InfoBean implements BeanNameAware, ApplicationContextAware {

    @Override
    public void setBeanName(String name) {
        System.out.println("3. My bean name is " + name);
    }

    @Override
    public void setApplicationContext(ApplicationContext ctx) {
        System.out.println("3. Context id: " + ctx.getId());
    }
}
```

Use these sparingly. They tie your class to Spring, and in most cases injecting exactly what you need with `@Autowired` is cleaner.

One small detail for the curious: `BeanNameAware` and `BeanFactoryAware` are called directly by the container, but `ApplicationContextAware` and `EnvironmentAware` are actually delivered by a built-in `BeanPostProcessor` just before stage 4. The simple order in the table is still the right way to think about it.

---

### Stages 4 and 6 in depth: the post-processors and the proxy trap

A `BeanPostProcessor` is different from every hook above because Spring calls it for **every bean**, not just one. That makes it the tool for cross-cutting work. Think of it as a checkpoint that every bean passes through twice.

```java
@Component
public class LoggingBeanPostProcessor implements BeanPostProcessor {

    @Override
    public Object postProcessBeforeInitialization(Object bean, String beanName) {
        System.out.println("4. Before init: " + beanName);
        return bean; // must return the bean
    }

    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName) {
        System.out.println("6. After init: " + beanName);
        return bean; // or return a proxy wrapping it
    }
}
```

**Line-by-line walkthrough**

- Both methods receive the bean and its name, and both return a bean. Returning the same object means "no change". Returning a _different_ object means Spring will use that one from now on.
- Do not return `null`. Spring then skips the remaining post-processors for that bean, which leads to confusing behavior.
- The "before" method is good for custom annotation processing, validation, or logging.
- The "after" method is where Spring creates **proxies**.

That last point is the most valuable thing in this section. When you put `@Transactional`, `@Async`, or `@Cacheable` on a method, a post-processor wraps your bean in a proxy at stage 6 and returns the proxy in place of your original object. So what you receive from `@Autowired` is often a _proxy_, not your raw class.

This explains a famous surprise: **calling a `@Transactional` method from another method in the same class does not start a transaction.**

```java
@Service
public class PaymentService {

    public void checkout() {
        charge(); // plain call on "this", NOT through the proxy
    }

    @Transactional
    public void charge() { /* no transaction starts here */ }
}
```

The call `charge()` goes straight to `this`, the real object, and skips the proxy that would have added the transaction. The fix is to move `charge()` into another bean and call it through injection, so the call passes through the proxy.

---

### Stage 5 in depth: choosing an init option

All three init options run after injection, and they run in a fixed order: `@PostConstruct`, then `afterPropertiesSet()`, then a custom `initMethod`.

```java
@Component
public class CacheLoader implements InitializingBean {

    @PostConstruct
    public void first() {                       // runs 1st
        System.out.println("5a. @PostConstruct");
    }

    @Override
    public void afterPropertiesSet() {          // runs 2nd
        System.out.println("5b. afterPropertiesSet");
    }

    public void customInit() {                  // runs 3rd
        System.out.println("5c. initMethod");
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

So which one should you choose?

|Option|Ties your class to Spring?|When to use it|
|---|---|---|
|`@PostConstruct`|No (it is standard Jakarta)|**Your default choice**|
|`afterPropertiesSet()`|Yes|Mostly inside framework code|
|`initMethod`|No|Classes you cannot edit, such as third-party libraries|

Good uses for this stage include loading a cache, opening a connection, and checking that required configuration exists. Remember that on Spring Boot 3 and later the annotation lives in `jakarta.annotation`, not `javax.annotation`.

---

### Stage 8 in depth: destruction details

The destroy hooks mirror the init ones and run in the same style of order: `@PreDestroy`, then `destroy()` from `DisposableBean`, then a custom `destroyMethod`.

```java
@Component
public class ConnectionHolder implements DisposableBean {

    @PreDestroy
    public void closeA() { System.out.println("8a. @PreDestroy"); }

    @Override
    public void destroy() { System.out.println("8b. destroy()"); }

    public void closeC() { System.out.println("8c. destroyMethod"); }
}
```

Two details are worth knowing:

- **Spring never destroys `prototype` beans.** It creates them, hands them over, and forgets them, so cleanup is your job.
- **For `@Bean` methods, Spring auto-detects a public `close()` or `shutdown()` method** and calls it on shutdown. You do not always have to name a `destroyMethod`. If you do _not_ want that, set `destroyMethod = ""`.

---

### Putting it all together

Here is one class that touches most of the hooks. Run it with the `LoggingBeanPostProcessor` from above registered, and watch the order print:

```java
@Component
public class Demo implements BeanNameAware, InitializingBean, DisposableBean {

    public Demo() { System.out.println("1. Constructor"); }

    @Autowired
    public void setEnv(Environment env) { System.out.println("2. Setter injection"); }

    @Override public void setBeanName(String n) { System.out.println("3. BeanNameAware"); }

    @PostConstruct
    public void post() { System.out.println("5a. @PostConstruct"); }

    @Override public void afterPropertiesSet() { System.out.println("5b. afterPropertiesSet"); }

    @PreDestroy
    public void pre() { System.out.println("8a. @PreDestroy"); }

    @Override public void destroy() { System.out.println("8b. destroy()"); }
}
```

```
1. Constructor
2. Setter injection
3. BeanNameAware
4. Before init: demo
5a. @PostConstruct
5b. afterPropertiesSet
5. After init: demo
... application runs ...
8a. @PreDestroy
8b. destroy()
```

### Key takeaways

- **Two kinds of post-processors.** `BeanFactoryPostProcessor` edits _blueprints_, once, early. `BeanPostProcessor` touches _finished objects_, one by one, for every bean.
- **Prefer the annotations.** `@PostConstruct` and `@PreDestroy` are simple and keep your class free of Spring interfaces.
- **Do startup work in `@PostConstruct`**, not the constructor, unless the dependency is constructor-injected.
- **Proxies appear at stage 6.** Most "why doesn't my `@Transactional` work?" questions trace back to this stage.
- **Static `@Bean` for post-processors.** Declare any `BeanFactoryPostProcessor` bean method as `static`.


[[Spring Framework]]