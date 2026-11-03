


A **bean** is just an object that Spring creates and manages for you, so you don't call `new` yourself. To make Spring create one, you give it a **recipe** (a `BeanDefinition`) saying what class to build, its scope, and what it needs. There are several ways to hand Spring that recipe, and which one you pick depends on who owns the class and how dynamic you need to be.

The good news is that every way ends in the same place: a `BeanDefinition` stored in the container's registry. Once you see that, the different styles stop feeling like separate topics and become different ways of writing the same recipe.

---

## The one idea that ties everything together

```java
Your declaration  →  BeanDefinition  →  Registry  →  Spring builds the object
(annotation, @Bean, XML, code)
```

Spring works in two phases:

1. **Register recipes.** Nothing is built yet. Post-processors can still edit recipes here.
2. **Build beans.** Create the object, inject dependencies, run init callbacks.

---

## The 6 ways, at a glance

|Way|Use it when|
|---|---|
|Stereotype annotations (`@Service`...)|It's **your own class**|
|`@Bean` in `@Configuration`|It's a **third-party class**, or creation needs logic|
|`@Import`|You want to **pull in** other configs explicitly|
|Programmatic registration|Beans are decided **at runtime**|
|XML|**Legacy** projects|
|Auto-configuration|You're writing a **Boot library**|

---

## 1. Stereotype annotations

Put a label on your class, and Spring finds it by scanning packages.

```java
@Service
public class UserService {
    private final UserRepository repo;
    public UserService(UserRepository repo) { this.repo = repo; }
}
```

- `@Component` is the generic label. `@Service`, `@Repository`, `@Controller` and `@RestController` are specialised versions.
- `@Repository` also converts database exceptions into Spring's `DataAccessException`.
- The bean name is the class name with a lowercase first letter (`userService`). Override it with `@Service("custom")`.
- `@SpringBootApplication` already includes `@ComponentScan`, so scanning just works.

---

## 2. `@Bean` methods

You write a method that returns the object. Spring calls it once and manages the result.

```java
@Configuration
public class AppConfig {
    @Bean
    public UserRepository userRepository() { return new JpaUserRepository(); }

    @Bean
    public UserService userService(UserRepository repo) {   // injected by Spring
        return new UserService(repo);
    }
}
```

Line by line:

- The method name is the bean name.
- Method parameters are injected from the container.
- You can add `@Scope`, `@Lazy`, `@Primary`, `initMethod`, `destroyMethod`.

**The gotcha: full mode vs lite mode.** Suppose one `@Bean` method calls another directly:

|Mode|What happens on `userRepository()` call inside another `@Bean`|
|---|---|
|`@Configuration` (default, proxied)|Spring intercepts and returns the **existing singleton**|
|`proxyBeanMethods = false`, or a plain `@Component`|You get a **brand-new object**|

The safest habit is to take the dependency as a method **parameter** instead of calling the method. Then both modes behave the same.

Two more small rules:

- A `static @Bean` method works without creating the config class first. Use it for `BeanFactoryPostProcessor` beans.
- A `@Bean` can return a `FactoryBean<T>` when creation is complicated.

---

## 3. `@Import`

Instead of scanning, you list exactly what to load.

```java
@Configuration
@Import({DatabaseConfig.class, SecurityConfig.class})
public class AppConfig {}
```

It has two advanced forms:

- **`ImportSelector`** returns class names to import, so you can decide in code.
- **`ImportBeanDefinitionRegistrar`** registers definitions directly:

```java
public class MyRegistrar implements ImportBeanDefinitionRegistrar {
    @Override
    public void registerBeanDefinitions(AnnotationMetadata md, BeanDefinitionRegistry registry) {
        registry.registerBeanDefinition("myService",
            BeanDefinitionBuilder.genericBeanDefinition(MyService.class).getBeanDefinition());
    }
}
```

This is how `@EnableCaching`, `@EnableAspectJAutoProxy` and Boot's auto-configuration work internally.

---

## 4. Programmatic registration

You skip annotations and register beans in code.

```java
var ctx = new AnnotationConfigApplicationContext();
ctx.registerBean(UserService.class, () -> new UserService(new JpaUserRepository()));
ctx.refresh();
```

For bigger needs, implement `BeanDefinitionRegistryPostProcessor`. It runs during phase 1, so it can add or change recipes before any bean exists. Spring's own `ConfigurationClassPostProcessor` is one: it's what processes your `@Configuration` classes.

---

## 5. XML (legacy)

```xml
<bean id="userService" class="com.example.UserService">
    <constructor-arg ref="userRepository"/>
</bean>
```

You'll mostly meet it in old projects. It's still useful to read, because XML maps almost one-to-one onto `BeanDefinition` fields. Load it from Java with `@ImportResource("classpath:beans.xml")`.

---

## 6. Spring Boot auto-configuration

Boot ships ready-made `@Configuration` classes whose beans only appear **if conditions are met**.

```java
@AutoConfiguration
@ConditionalOnClass(DataSource.class)
public class MyAutoConfig {
    @Bean
    @ConditionalOnMissingBean          // back off if the user defined their own
    public DataSource dataSource() { return new HikariDataSource(); }
}
```

- `@SpringBootApplication` = `@Configuration` + `@EnableAutoConfiguration` + `@ComponentScan`.
- Auto-config classes are listed in `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`.
- Common conditions: `@ConditionalOnClass`, `@ConditionalOnMissingBean`, `@ConditionalOnProperty`.
- Your own beans are processed first, so `@ConditionalOnMissingBean` lets you override Boot's defaults.

---

## Things worth knowing (the short list)

**Scopes:** `singleton` (default), `prototype` (new each time), `request`, `session`, `application`, `websocket`.  
To inject a request-scoped bean into a singleton, add `proxyMode = ScopedProxyMode.TARGET_CLASS`.

**Lazy:** `@Lazy` delays creation until first use. It can also break a circular dependency.

**Circular dependencies:** Constructor injection fails immediately. Field and setter injection are blocked by default in Boot 2.6+. Fix the design, or put `@Lazy` on one side.

**Bean overriding:** Disabled by default in Boot. Handy in tests, risky in production.

**Lifecycle order:** `@PostConstruct` → `afterPropertiesSet()` → `initMethod`. On shutdown: `@PreDestroy` → `destroy()` → `destroyMethod`.

**Prototype inside a singleton:** Use `ObjectProvider<T>` or `@Lookup`, otherwise you get the same prototype every time.

**Configuration properties:** `@ConfigurationProperties(prefix = "my")` binds external config to a class. Register it with `@EnableConfigurationProperties` or `@ConfigurationPropertiesScan`.

**Testing:** `@TestConfiguration` adds beans for tests. `@MockBean` and `@SpyBean` replace or wrap existing ones.

---

## Quick summary of related concepts

- **`BeanPostProcessor`** runs on every bean _after_ creation. It's how `@Autowired`, `@PostConstruct` and AOP proxies get applied.
- **`BeanFactoryPostProcessor`** runs _before_ beans exist and edits recipes. It's why `PropertySourcesPlaceholderConfigurer` must be a `static @Bean`.
- **`FactoryBean`** is a bean that produces another bean. `getBean("x")` returns the product, `getBean("&x")` returns the factory itself.

---

## Which one should I use?

1. Your own class → **`@Service` / `@Component`**
2. Class you can't edit → **`@Bean`**
3. Choose beans at runtime → **registrar or post-processor**
4. Shipping a Boot library → **`@AutoConfiguration`**

**The takeaway:** all of these produce `BeanDefinition`s. They differ only in _when_ and _how_ the recipe is written.




[[Spring Framework]]