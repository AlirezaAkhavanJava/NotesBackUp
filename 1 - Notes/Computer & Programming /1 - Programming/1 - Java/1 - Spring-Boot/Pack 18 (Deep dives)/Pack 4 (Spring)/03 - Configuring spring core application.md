


## The definition

**Configuring a Spring Core application** means two things:

1. Giving the container **configuration metadata**: a description of which objects (beans) exist and how they depend on each other.
2. **Starting the container** by creating an `ApplicationContext`, the object that reads that metadata, builds the beans, injects dependencies, and holds the results.

Spring Boot automates both. Without Boot you do them yourself, and this is useful to learn because Boot's auto-configuration is just these same mechanisms running for you.

**Versions:** The current Spring Framework generation is 7.0. It keeps a JDK 17 baseline (JDK 25 is recommended) and moves to Jakarta EE 11. The examples below work on 17 or newer.

## Mental model: three input formats, one internal representation

Whichever format you choose, the container converts it into a set of **`BeanDefinition`** objects. A `BeanDefinition` is a record saying "bean named X, of class Y, with these constructor arguments and properties, in this scope". After that, the container works only with definitions and doesn't care where they came from.

|Metadata source|Context class you start|
|---|---|
|Java `@Configuration` class with `@Bean` methods|`AnnotationConfigApplicationContext`|
|Stereotype annotations plus component scanning|`AnnotationConfigApplicationContext`|
|XML file|`ClassPathXmlApplicationContext`|
|Programmatic registration|`GenericApplicationContext`|

All of these are implementations of the `ApplicationContext` interface. Only the "load bean definitions" step differs, and the rest of startup is identical (covered below).

## Project setup

Create a Maven project with one dependency. `spring-context` pulls in `spring-core`, `spring-beans`, `spring-aop`, and `spring-expression` transitively.

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>spring-core-demo</artifactId>
  <version>1.0-SNAPSHOT</version>

  <properties>
    <maven.compiler.release>17</maven.compiler.release>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.springframework</groupId>
      <artifactId>spring-context</artifactId>
      <version>7.0.8</version> <!-- use the latest 7.0.x -->
    </dependency>
  </dependencies>
</project>
```

## The example domain used by every approach

Plain classes with **no Spring imports**, so you can see exactly what each configuration style adds. In `com.example.app`:

```java
public interface OrderRepository {
    void save(String order);
}

public class InMemoryOrderRepository implements OrderRepository {
    private final List<String> orders = new ArrayList<>();
    public void save(String order) { orders.add(order); System.out.println("Saved " + order); }
}

public interface NotificationSender {
    void send(String message);
}

public class ConsoleNotificationSender implements NotificationSender {
    public void send(String message) { System.out.println("Notify: " + message); }
}

public class OrderService {
    private final OrderRepository repository;
    private final NotificationSender sender;

    public OrderService(OrderRepository repository, NotificationSender sender) {
        this.repository = repository;
        this.sender = sender;
    }

    public void placeOrder(String order) {
        repository.save(order);
        sender.send("Order placed: " + order);
    }
}
```

`OrderService` has two dependencies, passed through its constructor. The configuration's job is to tell Spring how to build all three objects and connect them.

---
## Way 1: Java configuration (the modern default)

A class annotated `@Configuration` is a **bean factory written in Java**. Each `@Bean` method is a recipe: the method name becomes the bean name, the return type becomes the bean type, the method body creates the object, and the parameters are dependencies that Spring supplies.

```java
@Configuration
public class AppConfig {

    @Bean
    public OrderRepository orderRepository() {
        return new InMemoryOrderRepository();
    }

    @Bean
    public NotificationSender notificationSender() {
        return new ConsoleNotificationSender();
    }

    @Bean
    public OrderService orderService(OrderRepository repo, NotificationSender sender) {
        return new OrderService(repo, sender);   // parameters injected by type
    }
}
```

The startup class:

```java
public class App {
    public static void main(String[] args) {
        try (var ctx = new AnnotationConfigApplicationContext(AppConfig.class)) {
            ctx.getBean(OrderService.class).placeOrder("book");
        }
    }
}
```

Here is what each line does:

- `new AnnotationConfigApplicationContext(AppConfig.class)` creates the container, registers `AppConfig` as a source of definitions, and calls `refresh()`, which does the whole startup. When the constructor returns, every singleton already exists.
- `try (...)` closes the context at the end, which triggers shutdown callbacks (`@PreDestroy`, `DisposableBean`). A plain `main` has no other way to know when to shut down, so close it explicitly or call `ctx.registerShutdownHook()`.
- `getBean(OrderService.class)` is a lookup by type. In real code you rarely call `getBean`. You call it at the very top of the program, and everything below it is wired by injection.

**Why `@Bean` methods matter:** this is the only way to register classes you don't own, such as a `DataSource` from a library, because you can't put annotations on third-party source code. It also lets you use `if` statements and loops, since it's ordinary Java.

**Inter-bean calls:** you could also write `new OrderService(orderRepository(), notificationSender())`, calling the other `@Bean` methods directly. That still returns the shared singleton because Spring subclasses `@Configuration` classes at runtime (via CGLIB) and intercepts those calls. The parameter style above is clearer and doesn't depend on that trick.

---
## Way 2: Stereotype annotations and component scanning

Here you annotate the classes themselves, and Spring discovers them by scanning packages, so you no longer list every bean.

```java
@Repository
public class InMemoryOrderRepository implements OrderRepository { ... }

@Component
public class ConsoleNotificationSender implements NotificationSender { ... }

@Service
public class OrderService {
    private final OrderRepository repository;
    private final NotificationSender sender;

    public OrderService(OrderRepository repository, NotificationSender sender) { // no @Autowired needed
        ...
    }
}
```

```java
@Configuration
@ComponentScan("com.example.app")
public class AppConfig { }   // now empty: scanning finds the beans
```

The startup class is identical to Way 1.

- **`@Component`** is the generic marker "make this class a bean". `@Service`, `@Repository`, and `@Controller` are specializations of it. They behave the same for registration but carry meaning, and `@Repository` additionally enables exception translation (the idea from the previous lesson).
- **`@ComponentScan`** walks the classpath under the given package at startup, finds annotated classes, and registers a `BeanDefinition` for each. With no argument, it scans the package of the annotated class.
- **Constructor injection:** when a class has exactly one constructor, Spring uses it automatically and resolves each parameter by type. `@Autowired` is only needed if there are several constructors or you inject into fields or setters. Prefer constructor injection, because it lets you write `new OrderService(fake, fake)` in tests.
- Default bean names come from the class name with a lowercase first letter (`orderService`).

You can also mix the two ways: scan for your own classes and add `@Bean` methods for third-party ones in the same config class.

---
## Way 3: XML configuration (legacy, but you will meet it)

```xml
<!-- src/main/resources/beans.xml -->
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           https://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="orderRepository" class="com.example.app.InMemoryOrderRepository"/>
    <bean id="notificationSender" class="com.example.app.ConsoleNotificationSender"/>

    <bean id="orderService" class="com.example.app.OrderService">
        <constructor-arg ref="orderRepository"/>
        <constructor-arg ref="notificationSender"/>
    </bean>
</beans>
```

```java
try (var ctx = new ClassPathXmlApplicationContext("beans.xml")) {
    ctx.getBean("orderService", OrderService.class).placeOrder("book");
}
```

Here you can see the same information as Way 1 in another syntax: `id` is the bean name, `class` the type, `<constructor-arg ref>` the dependency. Setter injection uses `<property name="x" ref="y"/>`.

**Advantages of XML:** configuration is completely outside your code, so you can change wiring without recompiling, and your classes have no Spring dependencies at all. **Disadvantages:** nothing is checked at compile time (a typo in `class="..."` fails at startup), it's verbose, and refactoring tools handle it poorly.

**Status in Spring 7:** XML is not removed. The release notes say there are no plans to remove it completely, although XML configuration won't be updated to follow the Java configuration model, and the core `<bean>` namespace is not deprecated. The `<mvc:*>` and `<lang:*>` namespaces are now deprecated. For new projects, use Java config. Learn XML to read older codebases.

**Annotations inside XML:** if you want `@Autowired` or `@PostConstruct` to work in an XML-configured app, add the `context` namespace and `<context:annotation-config/>` (enables annotation processing) or `<context:component-scan base-package="com.example.app"/>` (does that and scans). Forgetting this is a classic cause of "my `@Autowired` field is null".

## Mixing styles

Real applications often combine formats:

```java
@Configuration
@Import({PersistenceConfig.class, WebConfig.class})   // compose several Java configs
@ImportResource("classpath:legacy-beans.xml")         // pull in an XML file
@ComponentScan("com.example.app")
public class AppConfig { }
```

This lets you migrate an XML application to Java config gradually: start with `AnnotationConfigApplicationContext` and `@ImportResource` the old file. The reverse also works, with `<bean class="...AppConfig"/>` plus `<context:annotation-config/>` in XML.

## Programmatic registration

Beyond the three file-based styles, you can register beans in code, which is how frameworks and libraries do it internally:

```java
var ctx = new GenericApplicationContext();
ctx.registerBean(OrderRepository.class, InMemoryOrderRepository::new);
ctx.registerBean(NotificationSender.class, ConsoleNotificationSender::new);
ctx.registerBean(OrderService.class,
        () -> new OrderService(ctx.getBean(OrderRepository.class), ctx.getBean(NotificationSender.class)));
ctx.refresh();   // you call refresh() yourself here
```

Spring 7 also adds a `BeanRegistrar` interface for the same purpose, which you import with `@Import` on a configuration class.

## What actually happens during startup

The constructors of the annotation and XML contexts call **`refresh()`**, and that single method defines the startup sequence:

1. **Prepare the bean factory** and load bean definitions. This is the only step that differs between the approaches above: it reads your `@Configuration` class, scans packages, or parses XML.
2. **Run `BeanFactoryPostProcessor`s.** These can modify definitions before any object exists. `@Configuration` classes, `@ComponentScan`, and `@Import` are processed here, by an internal post-processor. This is why scanning discovers more definitions than you listed.
3. **Register `BeanPostProcessor`s.** These intercept each bean after creation. They are what implement `@Autowired`, `@PostConstruct`, and proxies for `@Transactional`.
4. **Instantiate all non-lazy singletons**, resolving dependencies in the correct order: build `orderRepository` and `notificationSender` first, then `orderService`.
5. **Publish `ContextRefreshedEvent`.** The application is now ready.

A key consequence of step 4: singleton beans are created **eagerly**. A missing dependency, a typo in XML, or an ambiguous injection fails at startup with a clear `BeanCreationException` or `NoSuchBeanDefinitionException`, instead of at 3 a.m. when the first request arrives.

## Externalized values: properties and the Environment

```java
@Configuration
@PropertySource("classpath:app.properties")
public class AppConfig {

    @Bean
    public NotificationSender notificationSender(@Value("${app.sender.prefix}") String prefix) {
        return new ConsoleNotificationSender(prefix);
    }
}
```

`@PropertySource` adds a properties file to the **`Environment`**, the container's view of configuration (system properties, environment variables, loaded files). `@Value("${...}")` reads from it, and you can also inject `Environment` and call `getProperty("app.sender.prefix")`. Boot hides this setup behind `application.properties`; here you declare it explicitly.

## Gotchas

- **Wrong scan package.** `@ComponentScan` only looks at the package you give (or the config class's own package) and below. Classes elsewhere are silently ignored, and you get `NoSuchBeanDefinitionException` later.
- **Two beans of the same type.** Injection by type fails with `NoUniqueBeanDefinitionException`. Fix it with `@Primary`, `@Qualifier("name")`, or a parameter name matching the bean name.
- **`new` bypasses the container.** An `OrderService` you create with `new` yourself gets no injection and no proxies. Only objects the container creates are managed.
- **Circular constructor dependencies** (A needs B, B needs A) fail, because neither can be built first. Redesign them rather than switching to field injection to hide the problem.
- **Default scope is singleton**: one shared instance per context. Bean state must be thread-safe.
- **Don't call `getBean` throughout your code.** That turns the container into a service locator and brings back the lookup problem Spring was created to remove.
- **Forgetting to close the context** leaves destroy callbacks unexecuted.

## Which style should you choose?

Use **component scanning (Way 2)** for your own application classes and **`@Bean` methods (Way 1)** for third-party objects and anything needing logic, both inside Java config classes. This combination is what Spring Boot applications use too. Use **XML** only for maintaining older code or when you need configuration fully outside the source.

## Related concepts you haven't asked about yet

These build directly on this lesson:

- **Bean scopes** (`prototype`, request, session) and **lifecycle callbacks** (`@PostConstruct`, `@PreDestroy`, `InitializingBean`)
- **Profiles** (`@Profile`) and **conditional beans** (`@Conditional`), which are the foundation of Boot's auto-configuration
- **Enabling infrastructure features by hand**: `@EnableTransactionManagement`, `@EnableAspectJAutoProxy`, `@EnableScheduling`, which Boot would otherwise switch on for you
- **Starting a web app without Boot**: registering `DispatcherServlet` with a `WebApplicationInitializer` in a servlet container
- **`BeanPostProcessor` and `BeanFactoryPostProcessor`**: how Spring itself extends the container
- **Testing with `@ContextConfiguration` and `SpringExtension`**




[[Spring Framework]]