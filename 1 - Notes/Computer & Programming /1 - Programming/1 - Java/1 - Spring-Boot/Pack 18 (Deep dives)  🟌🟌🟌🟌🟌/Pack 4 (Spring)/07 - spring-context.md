

Spring is not one big library. It is a set of small modules, each with one job, stacked in layers. `spring-context` sits near the top of that stack. When you add it to a project, Maven or Gradle automatically downloads the modules below it, because `spring-context` cannot work without them. This is called a **transitive dependency**: you ask for one, and you receive the ones it needs.

So the question "what are these four, and why do we need them?" is really a question about how the layers fit together. Each module solves one piece of the puzzle: `spring-core` gives the basic tools, `spring-beans` builds objects, `spring-aop` wraps objects with extra behavior, `spring-expression` evaluates small expressions at runtime, and `spring-context` ties it all into the `ApplicationContext` you use every day.

---

## 1. The dependency picture

```
spring-context
 ├── spring-aop
 │    ├── spring-beans
 │    │    └── spring-core
 │    └── spring-core
 ├── spring-beans
 │    └── spring-core
 ├── spring-core
 │    └── spring-jcl
 ├── spring-expression
 │    └── spring-core
 └── micrometer-observation   (Spring 6+)
```

You can see the same tree yourself with `mvn dependency:tree` (or `./gradlew dependencies`).

Read it from the bottom up:

- `spring-core` depends on almost nothing. It is the **foundation**.
- `spring-beans` and `spring-expression` sit on top of core.
- `spring-aop` sits on top of beans.
- `spring-context` sits on top of all of them.

The arrows never point back down. Lower modules know nothing about higher ones. That is why you can use `spring-core` alone, but you cannot use `spring-context` without the rest.

---

## 2. What each module is

|Module|One-line job|Main things inside|
|---|---|---|
|`spring-core`|Basic utilities everything else uses|`Resource`, `Environment`, type conversion, annotation reading, `Assert`|
|`spring-beans`|Define and create beans|`BeanFactory`, `BeanDefinition`, injection, `BeanWrapper`|
|`spring-aop`|Wrap beans with extra behavior|Proxies, `ProxyFactory`, advice, pointcuts|
|`spring-expression`|Evaluate expressions at runtime (SpEL)|`SpelExpressionParser`, `Expression`|
|`spring-context`|The full container you actually use|`ApplicationContext`, `@Component`, `@Configuration`, events, scheduling|

Now each one in detail.

---

## 3. spring-core: the foundation

This module holds the tools that every other Spring module needs. It has no idea what a "bean" is. It only provides general-purpose helpers.

**What is inside:**

|Area|Key types|What it does|
|---|---|---|
|Resources|`Resource`, `ClassPathResource`, `ResourceLoader`|Read files from classpath, disk, or URL in one uniform way|
|Environment|`Environment`, `PropertySource`, `Profiles`|Hold properties and active profiles (`application.properties` ends up here)|
|Type conversion|`ConversionService`, `Converter`|Turn a `String` like `"42"` into an `int`, or `"2026-10-29"` into a `LocalDate`|
|Annotation tools|`AnnotationUtils`, `MergedAnnotations`|Read annotations, including ones nested inside other annotations|
|Metadata reading|ASM-based readers|Read class info **without loading the class** (used by component scanning)|
|Utilities|`Assert`, `ClassUtils`, `StringUtils`, `ResolvableType`|Small helpers, including generic type handling|

**Why we need it:** the other modules lean on it constantly. When Spring scans your packages, it reads class metadata through core. When `@Value("${port}")` becomes a number, core's conversion does it. When Spring reads `@Service`, core's annotation tools understand that `@Service` is built on `@Component`.

A tiny example:

```java
Resource r = new ClassPathResource("data/movies.json");
try (InputStream in = r.getInputStream()) {
    // read the file
}
```

1. `ClassPathResource` points at a file inside your project's classpath.
2. `getInputStream()` opens it. You did not need to care whether it sits in a folder or inside a `.jar`, because `Resource` hides that difference.

---

## 4. spring-beans: how objects get built

This is where the idea of a "bean" lives. You already studied `BeanDefinition` and `BeanFactory`, and both are here.

**What is inside:**

|Type|Role|
|---|---|
|`BeanFactory`|The basic container interface: `getBean(...)`|
|`DefaultListableBeanFactory`|The main working implementation|
|`BeanDefinition`|The recipe for a bean|
|`BeanDefinitionRegistry`|The store of recipes|
|`BeanWrapper`|Sets properties on an object by name|
|`BeanPostProcessor`, `BeanFactoryPostProcessor`|The lifecycle hooks|
|`@Autowired`, `@Qualifier`, `@Value`|Injection annotations (the processing code lives in this module)|
|`FactoryBean`|A bean that builds another bean|

**Why we need it:** this module _is_ the dependency injection engine. Without it, nothing creates objects or fills in their dependencies.

You can use it on its own, with no `ApplicationContext` at all:

```java
DefaultListableBeanFactory factory = new DefaultListableBeanFactory();
factory.registerBeanDefinition("greeter",
        new RootBeanDefinition(GreetingService.class));

GreetingService s = factory.getBean(GreetingService.class);
```

1. `DefaultListableBeanFactory` is the bare container.
2. `RootBeanDefinition` is a recipe for `GreetingService`.
3. `registerBeanDefinition` stores the recipe under the name `greeter`.
4. `getBean` reads the recipe and builds the object.

This works, but it is minimal. A plain `BeanFactory` does not scan packages, does not handle `@Component`, and does not run annotation-based injection until you add extra processors by hand. That gap is exactly what `spring-context` fills.

---

## 5. spring-aop: wrapping beans with extra behavior

**AOP** means _Aspect-Oriented Programming_. The idea: some behavior (logging, transactions, security checks, timing) belongs to many classes at once. Instead of copying that code everywhere, you write it once and have Spring **wrap** your beans with it.

The way Spring does this is with **proxies**: a stand-in object that sits in front of your real bean. When you call a method, the proxy runs the extra code, then calls your real method.

**What is inside:**

|Type|Role|
|---|---|
|`ProxyFactory`|Builds a proxy around an object|
|`Advice` (`MethodInterceptor`)|The extra code to run|
|`Pointcut`|Decides _which_ methods get the extra code|
|`Advisor`|A pointcut and an advice together|
|`AopProxy`|JDK dynamic proxy or CGLIB proxy under the hood|

A small example:

```java
ProxyFactory pf = new ProxyFactory(new ReportService());
pf.addAdvice((MethodInterceptor) invocation -> {
    long start = System.nanoTime();
    Object result = invocation.proceed();
    System.out.println(invocation.getMethod().getName() + " took "
            + (System.nanoTime() - start) / 1_000_000 + " ms");
    return result;
});

ReportService proxy = (ReportService) pf.getProxy();
proxy.build();
```

1. `new ProxyFactory(new ReportService())` says "wrap this real object".
2. `addAdvice(...)` adds the extra behavior. `invocation.proceed()` runs the real method.
3. `getProxy()` returns the stand-in. Calling `proxy.build()` runs the timer code first and last, with your real code in the middle.

**Why we need it in `spring-context`:** many features you use every day are built on proxies:

- `@Transactional` (open and commit a transaction around a method)
- `@Async` (run a method on another thread)
- `@Cacheable` (return a stored result instead of running the method)
- `@Scope(proxyMode = ...)` and `@RequestScope` (a proxy that finds the right request-bound object, just like the client proxy in CDI)
- `@Validated` method validation

So the container needs AOP support available, even if you never write an aspect yourself.

One clarification: **AspectJ-style annotations** (`@Aspect`, `@Around`, `@Before`) need an extra module, `spring-aspects` (and the AspectJ weaver library). `spring-aop` provides the proxy machinery; Spring Boot's `spring-boot-starter-aop` adds the annotation style on top.

---

## 6. spring-expression: SpEL

`spring-expression` contains **SpEL**, the Spring Expression Language. It is a tiny language that Spring evaluates **at runtime**, so you can write logic inside a string.

```java
ExpressionParser parser = new SpelExpressionParser();
Integer n = parser.parseExpression("'Hello'.length() + 3")
                  .getValue(Integer.class);
// n = 8
```

1. `SpelExpressionParser` reads the string as an expression.
2. `parseExpression(...)` turns it into an `Expression` object.
3. `getValue(Integer.class)` runs it and gives you the result: `5 + 3 = 8`.

**Where you meet SpEL without noticing:**

|You write|SpEL does|
|---|---|
|`@Value("#{systemProperties['user.home']}")`|Reads a system property|
|`@Value("#{2 * 60}")`|Calculates a value|
|`@Cacheable(condition = "#id > 10")`|Decides whether to cache|
|`@PreAuthorize("hasRole('ADMIN')")`|Evaluates a security rule|
|`@ConditionalOnExpression("${feature.on:false}")`|Turns a config class on or off|
|`@EventListener(condition = "#event.ok")`|Filters events|

A quick spot: `${...}` is a **property placeholder** (it reads a property from the environment), while `#{...}` is **SpEL**. They can be combined: `@Value("#{${base} * 2}")`.

**Why we need it:** `spring-context` annotations like `@Value`, `@Cacheable`, and `@EventListener` all accept SpEL strings, so the module must be on the classpath.

---

## 7. Why spring-context needs all four

Now put it together by following one line of your own code:

```java
@Service
public class OrderService {

    @Value("${order.limit}")
    private int limit;

    private final PaymentService payments;

    public OrderService(PaymentService payments) {
        this.payments = payments;
    }

    @Transactional
    public void place() { /* ... */ }
}
```

|What happens|Module that does it|
|---|---|
|Spring finds `@Service` by scanning and reads class metadata|`spring-context` (scanner) + `spring-core` (metadata reading)|
|It creates a `BeanDefinition` for the class|`spring-beans`|
|It converts `"100"` from `application.properties` to the `int` field|`spring-core` (conversion, environment)|
|It resolves the `${order.limit}` placeholder and any SpEL|`spring-core` + `spring-expression`|
|It builds the object and injects `PaymentService`|`spring-beans`|
|It wraps the bean in a proxy so `@Transactional` works|`spring-aop`|
|It manages all of this as an `ApplicationContext`|`spring-context`|

Every module appears somewhere in a single, ordinary class. That is why `spring-context` simply declares them as required.

---

## 8. What spring-context adds on top

`spring-context` is the module that gives you the _full_ container. It builds on a plain `BeanFactory` and adds:

- `ApplicationContext` (which extends `BeanFactory`)
- Annotation configuration: `@Component`, `@Service`, `@Configuration`, `@Bean`, `@ComponentScan`, `@Import`
- Automatic registration of the processors that make `@Autowired` and `@PostConstruct` work
- Events: `ApplicationEvent`, `ApplicationEventPublisher`, `@EventListener`
- `MessageSource` for internationalization
- Scheduling and async: `@Scheduled`, `@Async`, `@EnableScheduling`
- Caching abstraction: `@Cacheable`
- Formatting and validation integration
- Lifecycle control: `Lifecycle`, `SmartLifecycle`, `ContextRefreshedEvent`

In short: **beans gives you the engine, context gives you the finished car.**

---

## 9. How this looks in a real project

In **Maven**, one dependency is enough:

```xml
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-context</artifactId>
    <version>6.2.0</version>
</dependency>
```

You do **not** list `spring-core`, `spring-beans`, `spring-aop`, or `spring-expression`. They arrive on their own.

In **Spring Boot**, you add `spring-boot-starter` (or any starter such as `spring-boot-starter-web`). That pulls in `spring-boot`, which depends on `spring-context`, which brings the rest. This is why a Boot project needs just a few lines in `pom.xml` but still has dozens of jars in the dependency tree.

When you should list a module yourself: if you want **only** a small piece. For example, a library that only needs `ResourceLoader` or type conversion can depend on `spring-core` alone and stay light.

---

## 10. Related concept: the two extra transitive jars

You may see two more names in the dependency tree:

- **`spring-jcl`** is a tiny logging bridge that comes with `spring-core`. Spring writes its log messages through it, and it forwards them to whichever logging library you have (Logback, Log4j 2, and so on). It is why Spring logs work with your Log4j setup.
- **`micrometer-observation`** (Spring 6 and later) provides an API for metrics and tracing, so the container can report what it is doing to monitoring tools.

---

## 11. Common mistakes

1. **Adding all four manually.** It is not needed; `spring-context` already declares them.
2. **Mixing Spring versions.** All Spring modules must share the same version. Mixing `spring-core` 6.2 with `spring-beans` 5.3 leads to strange errors. Spring Boot's dependency management (or the Spring BOM) keeps them aligned.
3. **Expecting `@Aspect` to work with only `spring-context`.** You also need AspectJ support (`spring-boot-starter-aop` in Boot).
4. **Confusing `${...}` and `#{...}`.** The first is a property placeholder; the second is SpEL.
5. **Thinking `spring-aop` is only for aspects you write.** It also powers built-in features such as `@Transactional` and `@Async`.

---

## Summary

- `spring-core` is the foundation: resources, environment, type conversion, annotation and metadata tools.
- `spring-beans` is the dependency injection engine: `BeanFactory`, `BeanDefinition`, `@Autowired`.
- `spring-aop` provides proxies, which power `@Transactional`, `@Async`, `@Cacheable`, and scoped proxies.
- `spring-expression` is SpEL, used in `@Value("#{...}")`, `@Cacheable(condition=...)`, and security rules.
- `spring-context` adds `ApplicationContext`, annotation configuration, events, scheduling, and caching, and requires all four.
- Modules stack in layers: lower ones never depend on higher ones, so `spring-core` stands alone.





[[Spring Framework]]