


A `BeanFactoryPostProcessor` (BFPP) is a Spring hook that runs after Spring has read every `BeanDefinition` (the metadata blueprints from your last lesson) but before Spring has created a single regular bean. It receives the whole bean factory, so it can read and edit any blueprint: change a scope, flip a bean to lazy, add a property value, swap the class, or point it at a different init method.

The key idea is that a BFPP works on the **blueprint**, not on the **object**. When it runs, no instance exists yet, so you cannot touch `new Greeter()`. You can only change what Spring _will_ do when it builds it. Editing the finished object is the job of `BeanPostProcessor`, which comes later in the lifecycle (summary at the end).

---

## 1. Where it sits in the lifecycle

From your bean lifecycle lesson, the order is:

1. Spring reads config (XML, `@Configuration`, `@ComponentScan`) and **registers BeanDefinitions**
2. **`BeanFactoryPostProcessor`s run** ← this lesson
3. Beans are instantiated (constructor), dependencies injected
4. `BeanPostProcessor`s, init callbacks, and so on

So a BFPP is the last chance to change metadata. After step 2, the blueprints are treated as final.

---

## 2. Way one: implement `BeanFactoryPostProcessor`

The interface has one method:

```java
@FunctionalInterface
public interface BeanFactoryPostProcessor {
    void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException;
}
```

`ConfigurableListableBeanFactory` is the factory in its "editable" form. Its most useful methods:

|Method|What it gives you|
|---|---|
|`getBeanDefinitionNames()`|the names of every registered blueprint|
|`getBeanDefinition(name)`|the editable `BeanDefinition` for one bean|
|`getBeanNamesForType(Class)`|find blueprints by type (without creating beans)|

Here is a complete example. First, a normal bean:

```java
@Component
public class Greeter {
    private String message = "Hello";

    public void setMessage(String message) { this.message = message; }
    public String getMessage() { return message; }
}
```

Now a BFPP that edits its blueprint:

```java
@Component
public class MetadataTweaker implements BeanFactoryPostProcessor {

    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) {
        BeanDefinition bd = beanFactory.getBeanDefinition("greeter");

        bd.setScope(BeanDefinition.SCOPE_PROTOTYPE);   // was singleton
        bd.setLazyInit(true);                          // don't create at startup
        bd.getPropertyValues().add("message", "Hello from the BFPP"); // setter injection
    }
}
```

Line by line:

- `getBeanDefinition("greeter")` fetches the blueprint registered under the bean name `greeter` (the default name for `@Component Greeter`).
- `setScope(...)` replaces the scope. Spring will now build a new `Greeter` on every request for it.
- `setLazyInit(true)` marks it as not-created-at-startup.
- `getPropertyValues().add("message", ...)` adds a property. When Spring builds the bean, it will call `setMessage("Hello from the BFPP")` on it. The setter name is derived from the property name.

### What you can change on a `BeanDefinition`

|Setter|Annotation or XML equivalent|
|---|---|
|`setScope("prototype")`|`@Scope("prototype")`|
|`setLazyInit(true)`|`@Lazy`|
|`setPrimary(true)`|`@Primary`|
|`setDependsOn("a", "b")`|`@DependsOn({"a","b"})`|
|`setInitMethodName("start")`|`@Bean(initMethod = "start")`|
|`setDestroyMethodName("stop")`|`@Bean(destroyMethod = "stop")`|
|`setAutowireCandidate(false)`|`@Bean(autowireCandidate = false)`|
|`setBeanClassName("com.x.Other")`|swaps which class gets built|
|`setRole(...)` / `setDescription(...)`|`@Role`, `@Description`|
|`getPropertyValues().add(...)`|setter values (XML `<property>`)|
|`getConstructorArgumentValues()`|constructor values (XML `<constructor-arg>`)|

### The `static` rule for `@Bean` methods

If you register a BFPP with `@Bean` inside a `@Configuration` class, the method **must be `static`**:

```java
@Configuration
public class AppConfig {

    @Bean
    public static BeanFactoryPostProcessor tweaker() {   // static!
        return bf -> bf.getBeanDefinition("greeter").setLazyInit(true);
    }
}
```

The reason is timing. A non-static `@Bean` method needs an instance of `AppConfig`, which forces Spring to create `AppConfig` **early**, before the BFPP phase is finished. That early creation means `AppConfig` (and anything it autowires) skips normal post-processing, and Spring prints a warning. `static` lets Spring call the method without building `AppConfig` first. It is the same reason `PropertySourcesPlaceholderConfigurer` is always declared as a static `@Bean`.

---

## 3. Way two: `BeanDefinitionRegistryPostProcessor` (add or remove blueprints)

A plain BFPP is good for **editing** blueprints. If you need to **add new blueprints or delete existing ones**, use its subinterface:

```java
public interface BeanDefinitionRegistryPostProcessor extends BeanFactoryPostProcessor {
    void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) throws BeansException;
}
```

`BeanDefinitionRegistry` is the "shelf" that holds blueprints (you saw `registerBeanDefinition` in the BeanDefinition lesson).

```java
@Component
public class ExtraBeanRegistrar implements BeanDefinitionRegistryPostProcessor {

    @Override
    public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) {
        BeanDefinition bd = BeanDefinitionBuilder
                .genericBeanDefinition(Greeter.class)
                .addPropertyValue("message", "I was registered by code")
                .setLazyInit(true)
                .getBeanDefinition();

        registry.registerBeanDefinition("codeGreeter", bd);   // adds a new bean
        // registry.removeBeanDefinition("oldBean");           // or remove one
    }

    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory bf) {
        // still available, runs after all registry post-processors
    }
}
```

**Order matters:** Spring runs _all_ `BeanDefinitionRegistryPostProcessor.postProcessBeanDefinitionRegistry(...)` calls first, then their `postProcessBeanFactory(...)` calls, then the plain BFPPs. So blueprints you add in the registry phase are visible to every plain BFPP.

---

## 4. Way three: the built-in BFPPs you already use

You have probably used BFPPs without knowing it:

|Built-in|What it edits|
|---|---|
|`ConfigurationClassPostProcessor`|A `BeanDefinitionRegistryPostProcessor`. It processes `@Configuration`, `@Bean`, `@ComponentScan`, `@Import`, `@PropertySource`, and turns them into blueprints. This is how all annotation config works.|
|`PropertySourcesPlaceholderConfigurer`|Replaces `${...}` placeholders inside blueprint values with property values (this powers `@Value("${x}")`).|
|`PropertyOverrideConfigurer`|Overrides bean property values from a properties file (`beanName.property=value`).|
|`CustomScopeConfigurer`|Registers custom scopes into the factory.|
|`EventListenerMethodProcessor`|Finds `@EventListener` methods.|

---

## 5. The annotation ways

Here is the important distinction: **there is no annotation that makes a class a BFPP.** A BFPP is always a class implementing the interface, and you register it with `@Component` or a `static @Bean`.

What annotations _do_ is declare metadata, and then `ConfigurationClassPostProcessor` (itself a BFPP) reads them and fills in the `BeanDefinition` for you. So the annotation way of "modifying metadata" is really the same mechanism, written declaratively:

|Annotation|What it means|Which `BeanDefinition` field it fills|
|---|---|---|
|`@Component`, `@Service`, `@Repository`, `@Controller`|"Register this class as a bean"|creates the blueprint (found via `@ComponentScan`)|
|`@Bean`|"The return value of this method is a bean"|blueprint with a factory method|
|`@Scope("prototype")`|how many instances|`scope`|
|`@Lazy`|create on first use|`lazyInit`|
|`@Primary`|winner when several beans match a type|`primary`|
|`@DependsOn("x")`|create `x` first|`dependsOn`|
|`@Profile("dev")`|only register in this profile|blueprint is skipped if inactive|
|`@Conditional(...)`|only register if a condition is true|blueprint is skipped if false|
|`@Role(...)`|marks bean as app / support / infrastructure|`role`|
|`@Description("...")`|human-readable text|`description`|
|`@Bean(initMethod="x", destroyMethod="y")`|lifecycle method names|`initMethodName`, `destroyMethodName`|
|`@Bean(autowireCandidate=false)`|hide from injection by type|`autowireCandidate`|
|`@Import(Config.class)`|pull in more config classes|adds more blueprints|

### The annotation way to _add_ blueprints in code: `@Import` + `ImportBeanDefinitionRegistrar`

This is the one place where an annotation and a registry-editing hook work together, and it is what libraries like Spring Data (`@EnableJpaRepositories`) use.

```java
public class GreeterRegistrar implements ImportBeanDefinitionRegistrar {

    @Override
    public void registerBeanDefinitions(AnnotationMetadata importingClassMetadata,
                                        BeanDefinitionRegistry registry) {
        BeanDefinition bd = BeanDefinitionBuilder
                .genericBeanDefinition(Greeter.class)
                .addPropertyValue("message", "from the registrar")
                .getBeanDefinition();
        registry.registerBeanDefinition("registrarGreeter", bd);
    }
}
```

```java
@Configuration
@Import(GreeterRegistrar.class)    // "run this registrar while processing me"
public class AppConfig { }
```

- `@Import(GreeterRegistrar.class)` tells `ConfigurationClassPostProcessor` to call the registrar while it processes `AppConfig`.
- The `AnnotationMetadata` parameter lets you read the annotations on the importing class, so a custom annotation can carry settings:

```java
@Retention(RetentionPolicy.RUNTIME)
@Import(GreeterRegistrar.class)
public @interface EnableGreeter {
    String message() default "Hello";
}
```

Inside the registrar you call `importingClassMetadata.getAnnotationAttributes(EnableGreeter.class.getName())` to read `message`. That gives you your own `@Enable...` annotation, exactly like Spring's.

A close cousin is `ImportSelector`: instead of registering blueprints itself, it returns **class names** to import (`String[] selectImports(AnnotationMetadata)`), which is how `@EnableAutoConfiguration` works in Boot.

---

## 6. Way four: programmatic customizers (no BFPP class)

If you build the context yourself (plain Spring without Boot, or in tests), you can edit metadata at registration time:

```java
GenericApplicationContext ctx = new GenericApplicationContext();
ctx.registerBean("greeter", Greeter.class, bd -> {
    bd.setLazyInit(true);
    bd.setScope("prototype");
});
ctx.refresh();
```

The lambda receives the `BeanDefinition` before the context refreshes. For your own bean definitions this is the lightest option. The BFPP is better when you want to change blueprints that come from _somewhere else_ (scanned classes, libraries, auto-configuration).

---

## 7. Ordering several BFPPs

If you have more than one, control the order by implementing `PriorityOrdered` (runs first), `Ordered`, or using `@Order`:

```java
@Component
public class MyTweaker implements BeanFactoryPostProcessor, Ordered {
    @Override public int getOrder() { return 10; }   // lower number = earlier
    @Override public void postProcessBeanFactory(ConfigurableListableBeanFactory bf) { ... }
}
```

Spring's order is: `PriorityOrdered` first, then `Ordered`, then the rest.

---

## 8. Gotchas

1. **Never call `getBean(...)` inside a BFPP.** That forces the bean to be created now, before other post-processors are ready, so it may miss injection and proxying (for example, `@Transactional` won't apply). Use `getBeanDefinition(...)` and `getBeanNamesForType(..., false, false)` instead.
2. **Don't `@Autowired` into a BFPP** for the same reason. Take what you need from the factory, or use `Environment` via `EnvironmentAware`.
3. **Mark BFPP `@Bean` methods `static`**, as in section 2.
4. **Edit only before refresh finishes.** After the BFPP phase, metadata changes are ignored for beans already built (singletons).
5. **Bean names:** `@Component Greeter` becomes `greeter`; a `@Bean` method uses the method name. A wrong name makes `getBeanDefinition` throw `NoSuchBeanDefinitionException`.

---

## Related concept: `BeanPostProcessor` in a few lines

`BeanPostProcessor` is the sibling hook that runs on **instances** instead of blueprints. It has `postProcessBeforeInitialization(bean, name)` and `postProcessAfterInitialization(bean, name)`, and it receives the real object (and may return a replacement). That is how Spring wraps beans in proxies for `@Transactional` and AOP. Rule of thumb:

- change **how a bean will be built** → `BeanFactoryPostProcessor`
- change **the built bean object** → `BeanPostProcessor`

---

## Quick recap

|You want to...|Use|
|---|---|
|Edit existing blueprints (scope, lazy, properties, class)|`BeanFactoryPostProcessor`|
|Add or remove blueprints in code|`BeanDefinitionRegistryPostProcessor`|
|Add blueprints driven by your own annotation|`@Import` + `ImportBeanDefinitionRegistrar`|
|Declare metadata on your own classes|`@Scope`, `@Lazy`, `@Primary`, `@DependsOn`, `@Profile`, `@Bean(...)`|
|Customize while registering programmatically|`registerBean(..., customizer)`|




[[Spring Framework]]