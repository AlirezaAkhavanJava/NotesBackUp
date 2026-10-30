

A `BeanDefinition` is Spring's **recipe card for a bean**. It is a small object that describes _how_ to make a bean: which class to use, what scope it has, what it depends on, and which methods to call when it starts or stops. It is not the bean itself. It is only the plan.

Spring does its work in two separate stages, and `BeanDefinition` is the link between them. First, Spring reads your configuration (`@Component`, `@Bean`, XML) and turns each item into a `BeanDefinition`. Later, Spring reads those definitions and creates the real objects. Because the plan exists _before_ the object, Spring can inspect it, change it, and decide when to build the bean. This is how lazy beans, scopes, `@Primary`, and `@DependsOn` all work.

---

## 1. Definition vs. instance

This is the idea to hold on to. Think of a cake recipe and a cake.

||BeanDefinition|Bean instance|
|---|---|---|
|What it is|Metadata (the recipe)|The real object (the cake)|
|When it exists|From startup, before anything is built|After Spring creates it|
|How many|Exactly one per bean name|One, or many, depending on scope|
|Can you change it?|Yes, before creation|You change the object itself|

A `prototype` bean shows this clearly: there is **one** definition, but a new instance every time you ask for it.

---

## 2. What is inside a BeanDefinition

A definition stores these things:

|Property|Meaning|Where you set it|
|---|---|---|
|Bean class name|Which class to instantiate|`@Component`, `@Bean` return type|
|Scope|`singleton`, `prototype`, `request`, ...|`@Scope`|
|Lazy init|Create only when first needed|`@Lazy`|
|Primary|Preferred when several match|`@Primary`|
|Autowire candidate|Can it be injected elsewhere?|`autowireCandidate` in `@Bean`|
|Depends on|Beans that must be created first|`@DependsOn`|
|Constructor arguments|Values for the constructor|`@Bean` method parameters, XML|
|Property values|Values for setters|XML, `MutablePropertyValues`|
|Init method / destroy method|Names of lifecycle methods|`@Bean(initMethod=..., destroyMethod=...)`|
|Factory bean / factory method|Build it by calling another method|`@Bean` methods|
|Parent name|Inherit settings from another definition|XML|
|Role|Application, support, or infrastructure|`@Role`|

Here is the important point: **every annotation you use is just a way of filling in these fields.** `@Lazy` sets `lazyInit = true`. `@Scope("prototype")` sets the scope field. Nothing magic happens until Spring reads the definition.

---

## 3. Where definitions come from

Spring creates definitions from different sources, and each source produces a slightly different class.

|Source|Definition class created|
|---|---|
|`@Component` / `@Service` found by component scan|`ScannedGenericBeanDefinition`|
|`@Bean` method inside `@Configuration`|`ConfigurationClassBeanDefinition`|
|Class registered with `AnnotationConfigApplicationContext`|`AnnotatedGenericBeanDefinition`|
|XML `<bean>`|`GenericBeanDefinition`|
|Code, using `registerBean(...)` or the registry|`GenericBeanDefinition` or `RootBeanDefinition`|

You rarely care about the exact class. The `BeanDefinition` interface is what you use, and all of these implement it.

### The class family

- **`BeanDefinition`** is the interface (`org.springframework.beans.factory.config`).
- **`AbstractBeanDefinition`** is the base class with most of the fields.
- **`GenericBeanDefinition`** is the general-purpose one you build in code.
- **`RootBeanDefinition`** is the _merged, final_ view Spring uses internally at creation time. It combines a definition with its parent's settings.
- **`ChildBeanDefinition`** is an older class for inheriting from a parent. `GenericBeanDefinition` replaced it.

---

## 4. The startup flow

Here is where `BeanDefinition` sits in the journey. This links straight to the lifecycle hooks you already know.

1. **Read configuration.** Spring scans classes and reads `@Bean` methods.
2. **Register definitions.** Each result is stored in a **`BeanDefinitionRegistry`** (a map of `name -> BeanDefinition`).
3. **`BeanFactoryPostProcessor` runs.** This is your chance to change definitions. No beans exist yet.
4. **Instantiate beans.** For each non-lazy singleton, Spring reads its definition, builds the object, injects dependencies, and runs `BeanPostProcessor` and init callbacks.
5. **Cache singletons.** The real object is stored; the definition stays in the registry.

The key rule: **`BeanFactoryPostProcessor` works on definitions. `BeanPostProcessor` works on instances.** Step 3 happens before step 4, which is why you can still change a definition at that point.

---

## 5. Seeing a definition for real

You can ask the container for any definition and read it.

```java
@SpringBootApplication
public class DemoApplication {

    public static void main(String[] args) {
        ConfigurableApplicationContext ctx =
                SpringApplication.run(DemoApplication.class, args);

        BeanDefinition def = ctx.getBeanFactory()
                                .getBeanDefinition("userService");

        System.out.println(def.getBeanClassName());
        System.out.println(def.getScope());
        System.out.println(def.isLazyInit());
        System.out.println(def.isPrimary());
    }
}
```

Line by line:

1. `SpringApplication.run(...)` starts the app and returns the context.
2. `ctx.getBeanFactory()` gives you the underlying `ConfigurableListableBeanFactory`, which can look up definitions.
3. `getBeanDefinition("userService")` fetches the recipe by bean name. The name must exist, or you get a `NoSuchBeanDefinitionException`.
4. The next lines read the stored settings. For a normal service you will see the full class name, an empty scope (which means singleton), `false`, and `false`.

Note that `getScope()` returns an **empty string** when you did not set one. Spring treats that as the default, singleton.

To list every bean name, use `ctx.getBeanDefinitionNames()`. It is a fun way to see everything Spring Boot auto-configures for you.

---

## 6. Creating a definition in code

You can skip annotations entirely and build the recipe yourself.

```java
public class GreetingService {
    private final String greeting;

    public GreetingService(String greeting) {
        this.greeting = greeting;
    }

    public String greet(String name) {
        return greeting + ", " + name;
    }
}
```

```java
GenericApplicationContext ctx = new GenericApplicationContext();

BeanDefinition def = BeanDefinitionBuilder
        .genericBeanDefinition(GreetingService.class)
        .addConstructorArgValue("Hello")
        .setScope(BeanDefinition.SCOPE_SINGLETON)
        .setLazyInit(true)
        .getBeanDefinition();

ctx.registerBeanDefinition("greetingService", def);
ctx.refresh();

GreetingService s = ctx.getBean(GreetingService.class);
System.out.println(s.greet("Ana"));
```

Walk through it:

1. `GenericApplicationContext` is a bare container with no annotation scanning, so nothing is registered for you.
2. `BeanDefinitionBuilder.genericBeanDefinition(...)` starts a recipe for the class.
3. `addConstructorArgValue("Hello")` records the argument Spring must pass to the constructor.
4. `setScope(...)` and `setLazyInit(true)` fill in two more fields. Because it is lazy, the object is not created until it is first requested.
5. `registerBeanDefinition("greetingService", def)` stores the recipe under a name. **No object exists yet.**
6. `ctx.refresh()` starts the container. Spring processes definitions here.
7. `getBean(...)` is the first moment the real `GreetingService` is built, because the definition said lazy.

Spring 5 and later also has a shortcut: `ctx.registerBean(GreetingService.class, () -> new GreetingService("Hello"))`, which builds a definition with a supplier for you.

---

## 7. Changing a definition before beans exist

This is the real power. A `BeanFactoryPostProcessor` can edit recipes before any bean is built.

```java
@Component
public class ScopeChanger implements BeanFactoryPostProcessor {

    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory bf) {
        BeanDefinition def = bf.getBeanDefinition("reportService");
        def.setScope(BeanDefinition.SCOPE_PROTOTYPE);
    }
}
```

What happens:

1. Spring finds this class and calls `postProcessBeanFactory` after all definitions are loaded but **before** any normal bean is created.
2. You fetch the definition for `reportService` and change its scope to `prototype`.
3. From then on, every `getBean("reportService")` call returns a new object, even though the class itself says nothing about prototype.

One warning: a `BeanFactoryPostProcessor` runs very early, so avoid injecting other beans into it. If you declare it with `@Bean`, make the method `static`, so Spring does not have to build the surrounding configuration class too soon.

To _add_ new definitions rather than edit existing ones, use the sub-interface `BeanDefinitionRegistryPostProcessor`. It gives you the registry itself, so you can call `registerBeanDefinition(...)` and create beans from nothing. Many libraries, such as Spring Data repositories, use this exact approach to create beans for your interfaces.

---

## 8. Who uses BeanDefinition in real life

You will not edit definitions in everyday app code, but these features all depend on them:

|Feature|How a definition is involved|
|---|---|
|`@ComponentScan`|`ClassPathBeanDefinitionScanner` creates a definition for each found class|
|`@Configuration` + `@Bean`|Each `@Bean` method becomes a definition with a factory method|
|`@Conditional` / Spring Boot auto-configuration|Spring decides whether to **register the definition at all**|
|Spring Data JPA repositories|A registrar adds a definition for each repository interface|
|`@Lazy`, `@Primary`, `@DependsOn`|Set fields on the definition|
|Scoped proxies (`@RequestScope`)|Spring registers an extra proxy definition that points to the real one|

The Boot auto-configuration row is worth thinking about. When Boot says "no DataSource bean configured, so I will create one", it is checking the registry of definitions and deciding whether to add one.

---

## 9. Common mistakes

1. **Mixing up definition and instance.** Changing a `BeanDefinition` after the singleton exists has no effect on the already-built object. Edit it before creation.
2. **Doing it too late.** Use `BeanFactoryPostProcessor`, not `BeanPostProcessor`, to change definitions.
3. **Wrong bean name.** `getBeanDefinition` throws if the name does not exist. A `@Component` named `UserService` gets the default name `userService` (first letter lowercase).
4. **Expecting `getScope()` to say "singleton".** It is empty unless you set it.
5. **Injecting beans into a post-processor.** It forces early creation and often causes confusing warnings.

---

## 10. Related concept: BeanDefinitionRegistry

A **`BeanDefinitionRegistry`** is the storage that holds all definitions, keyed by bean name. It has methods such as `registerBeanDefinition`, `removeBeanDefinition`, `getBeanDefinition`, and `containsBeanDefinition`. `DefaultListableBeanFactory` is the main class that implements it, and `ApplicationContext` uses one inside. When people say "Spring registered a bean", they mean a definition was added to this registry.

For comparison with CDI, which you just learned: CDI keeps similar metadata in its `Bean<T>` and `BeanAttributes` objects, and a CDI extension can observe and change that metadata during discovery. The idea is the same: describe the bean first, build it later.

---

## Summary

- A `BeanDefinition` is the **blueprint** for a bean, not the bean itself.
- It stores class, scope, laziness, dependencies, factory method, and lifecycle method names.
- Annotations like `@Lazy`, `@Scope`, and `@Primary` just fill in its fields.
- Definitions are stored in a `BeanDefinitionRegistry` and read when beans are created.
- `BeanFactoryPostProcessor` edits definitions _before_ instances exist; `BeanPostProcessor` works on instances _after_.
- `BeanDefinitionBuilder` and `registerBeanDefinition` let you create definitions in plain code.





[[Spring Framework]]