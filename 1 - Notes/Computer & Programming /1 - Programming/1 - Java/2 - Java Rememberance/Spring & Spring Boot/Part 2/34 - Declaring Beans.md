

## 1. Core Mental Model: The Spring Container as a Restaurant Kitchen

Imagine you’re running a restaurant. You don’t personally cook every dish (`new MyService()`). Instead, you write **recipes** and hand them to the chef. The chef (the Spring container) reads the recipes, gathers ingredients (dependencies), cooks the dishes (instantiates), and manages their lifecycle. When a waiter needs a dish, the chef provides it.

- **Bean**: A dish — an object whose lifecycle is managed by Spring.
- **BeanDefinition**: A recipe card — metadata describing how to create the bean (class, scope, constructor args, dependencies, init/destroy methods, etc.).
- **BeanFactory**: The basic kitchen — the core container that can create and manage beans.
- **ApplicationContext**: A full restaurant — extends `BeanFactory` with events, internationalization, AOP integration, and more.
- **BeanDefinitionRegistry**: The recipe book — where bean definitions are stored before beans are instantiated.

The key insight: **Declaring a bean means giving Spring a recipe.** There are many ways to submit that recipe, but they all end up as `BeanDefinition` objects in the registry. Understanding this unifies all declaration styles.

---

## 2. Formal Mechanics: How Spring Turns Recipes into Objects

Before diving into syntax, let’s trace the lifecycle:

1. **Configuration parsing**: Spring reads your `@Configuration` classes, XML files, or programmatic registrations.
2. **BeanDefinition registration**: Each bean declaration becomes a `BeanDefinition` in the `BeanDefinitionRegistry`.
3. **BeanFactoryPostProcessor**: These run *before* any bean is instantiated. They can modify existing bean definitions or register new ones. `BeanDefinitionRegistryPostProcessor` is a special subtype that runs first and can register more definitions.
4. **Bean instantiation**: Spring creates bean instances from definitions.
5. **Dependency injection**: Spring populates properties and resolves constructor arguments.
6. **BeanPostProcessor**: These run *after* instantiation but *before* and *after* initialization. They can wrap beans (AOP proxies), inject `@Autowired`, `@Value`, call `@PostConstruct`, etc.
7. **Initialization**: `@PostConstruct`, `InitializingBean.afterPropertiesSet()`, or custom `initMethod`.
8. **Ready for use**.
9. **Destruction**: `@PreDestroy`, `DisposableBean.destroy()`, or custom `destroyMethod`.

This explains why some declaration methods work at different phases. For example, `BeanDefinitionRegistryPostProcessor` must be declared as a `static @Bean` method to avoid premature instantiation of the configuration class.

---

## 3. The Ways to Declare Beans

### 3.1 Stereotype Annotations + Component Scanning

**Intuition**: You mark your own classes with a label, and Spring scans the classpath to find them.

```java
@Service
public class UserService {
    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
}
```

- `@Component` is the generic stereotype.
- `@Service`, `@Repository`, `@Controller`, `@RestController` are specializations.
- `@Repository` adds exception translation (JDBC/ORM exceptions to Spring’s `DataAccessException`).
- `@Controller` marks a web controller; `@RestController` = `@Controller` + `@ResponseBody`.

**How it works**: `@ComponentScan` (included in `@SpringBootApplication`) scans packages for `@Component`-annotated classes. For each, it registers a `BeanDefinition` with the class name and default scope (singleton).

**Edge cases**:
- Default bean name is the decapitalized class name: `userService`.
- You can specify a name: `@Service("myUserService")`.
- `@ComponentScan` can include/exclude filters:
  ```java
  @ComponentScan(
      basePackages = "com.example",
      excludeFilters = @ComponentScan.Filter(type = FilterType.REGEX, pattern = ".*Test.*")
  )
  ```
- `@Indexed` (Spring 5) can speed up scanning by generating a `META-INF/spring.components` index at compile time.
- `@Component` classes are **lite mode** for `@Bean` methods (see next section).

---

### 3.2 `@Bean` Methods in `@Configuration` Classes (Java Config)

**Intuition**: You write a method that returns the object. Spring calls it and manages the result.

```java
@Configuration
public class AppConfig {
    @Bean
    public UserService userService(UserRepository userRepository) {
        return new UserService(userRepository);
    }

    @Bean
    public UserRepository userRepository() {
        return new JpaUserRepository();
    }
}
```

- The method name becomes the bean name (`userService`).
- Method parameters are **autowired** — Spring resolves them from the container.
- You can specify `initMethod`, `destroyMethod`, `name`, `@Primary`, `@Scope`, `@Lazy`, etc.

**Full mode vs. Lite mode**:
- `@Configuration(proxyBeanMethods = true)` (default) — Spring creates a CGLIB proxy of the configuration class. When you call `userRepository()` inside `userService()`, the proxy intercepts and returns the singleton bean from the container. This ensures **inter-bean method calls** respect scope.
- `@Configuration(proxyBeanMethods = false)` — no CGLIB proxy. Calling `userRepository()` directly creates a **new instance**, not the container-managed one. This is “lite mode” and is faster (no CGLIB). Spring Boot’s auto-configuration classes use `proxyBeanMethods = false` by default.
- `@Bean` methods inside a plain `@Component` class are also in lite mode. This is a common gotcha: calling one `@Bean` method from another creates a new object.

**Why CGLIB?** It’s a hack to make Java method calls behave like container lookups. Without it, you’d need to inject dependencies as method parameters.

**Edge cases**:
- `@Bean` methods must be **overridable** (not `private` or `final`) if `proxyBeanMethods = true`.
- `static @Bean` methods are not proxied and can be called without instantiating the configuration class. Useful for `BeanFactoryPostProcessor`:
  ```java
  @Bean
  public static PropertySourcesPlaceholderConfigurer propertyConfigurer() {
      return new PropertySourcesPlaceholderConfigurer();
  }
  ```
- `@Bean` methods can return `FactoryBean<T>` for complex creation logic.
- `@Bean` with `@Scope("prototype")` — each call to `getBean()` creates a new instance. But injecting a prototype into a singleton requires `@Lookup` or `ObjectProvider`.

---

### 3.3 `@Import` and Its Variants

**Intuition**: Instead of scanning, you explicitly import other configuration classes or programmatic registrars.

```java
@Configuration
@Import({DatabaseConfig.class, SecurityConfig.class})
public class AppConfig {}
```

- `@Import(MyConfig.class)` — imports a `@Configuration` class.
- `@Import(MyComponent.class)` — since Spring 4.2, you can import regular component classes.
- `@Import(MyImportSelector.class)` — programmatically select which configs to import.
- `@Import(MyImportBeanDefinitionRegistrar.class)` — register bean definitions directly.

**ImportSelector**:
```java
public class MyImportSelector implements ImportSelector {
    @Override
    public String[] selectImports(AnnotationMetadata importingClassMetadata) {
        return new String[] { "com.example.FooConfig", "com.example.BarConfig" };
    }
}
```

**ImportBeanDefinitionRegistrar**:
```java
public class MyRegistrar implements ImportBeanDefinitionRegistrar {
    @Override
    public void registerBeanDefinitions(AnnotationMetadata metadata, BeanDefinitionRegistry registry) {
        BeanDefinitionBuilder builder = BeanDefinitionBuilder
            .genericBeanDefinition(MyService.class)
            .addPropertyValue("name", "dynamic");
        registry.registerBeanDefinition("myService", builder.getBeanDefinition());
    }
}
```

**Why it matters**: `@Enable*` annotations (e.g., `@EnableAspectJAutoProxy`, `@EnableCaching`) use `@Import` to bring in infrastructure. Spring Boot’s auto-configuration is built on this.

---

### 3.4 Programmatic Registration

**Intuition**: You bypass annotations entirely and register beans directly with the container.

**Using `GenericApplicationContext`**:
```java
AnnotationConfigApplicationContext ctx = new AnnotationConfigApplicationContext();
ctx.registerBean(UserService.class, () -> new UserService(new JpaUserRepository()));
ctx.refresh();
UserService service = ctx.getBean(UserService.class);
```

- `registerBean(Class<T>, Supplier<T>)` — Spring 5+.
- `registerBean(Class<T>, BeanDefinitionCustomizer...)` — customize scope, lazy, etc.

**Using `BeanDefinitionRegistryPostProcessor`**:
```java
@Component
public class DynamicBeanRegistrar implements BeanDefinitionRegistryPostProcessor {
    @Override
    public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) {
        BeanDefinitionBuilder builder = BeanDefinitionBuilder
            .genericBeanDefinition(MyService.class)
            .setScope(BeanDefinition.SCOPE_SINGLETON);
        registry.registerBeanDefinition("myService", builder.getBeanDefinition());
    }

    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) {}
}
```

**Use cases**: Plugins, dynamic modules, test contexts, framework internals. `ConfigurationClassPostProcessor` itself is a `BeanDefinitionRegistryPostProcessor` that processes `@Configuration` classes.

---

### 3.5 XML (Legacy but Foundational)

**Intuition**: The original way. Still useful for legacy systems and understanding `BeanDefinition`.

```xml
<beans>
    <bean id="userService" class="com.example.UserService">
        <constructor-arg ref="userRepository"/>
    </bean>
    <bean id="userRepository" class="com.example.JpaUserRepository"/>
</beans>
```

- `<context:component-scan base-package="com.example"/>` enables annotation scanning.
- `<import resource="other-config.xml"/>` imports other XML files.
- `@ImportResource("classpath:beans.xml")` imports XML into Java config.

XML directly creates `BeanDefinition` objects. Understanding XML helps you grasp what annotations do under the hood.

---

### 3.6 Spring Boot Auto-Configuration

**Intuition**: Spring Boot ships with pre-written `@Configuration` classes that declare beans conditionally. They are just recipes that only activate when certain conditions are met.

- `@SpringBootApplication` = `@Configuration` + `@EnableAutoConfiguration` + `@ComponentScan`.
- `@EnableAutoConfiguration` imports `AutoConfigurationImportSelector`, which reads `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports` (Spring Boot 2.7+) or `spring.factories` (older).
- Each auto-config class is annotated with `@AutoConfiguration` (meta-annotated with `@Configuration(proxyBeanMethods = false)`).
- Conditions: `@ConditionalOnClass`, `@ConditionalOnMissingBean`, `@ConditionalOnProperty`, `@ConditionalOnWebApplication`, etc.

**Example**:
```java
@AutoConfiguration
@ConditionalOnClass(DataSource.class)
public class DataSourceAutoConfiguration {
    @Bean
    @ConditionalOnMissingBean
    public DataSource dataSource() {
        return new HikariDataSource();
    }
}
```

**Ordering**: `@AutoConfigureBefore`, `@AutoConfigureAfter`, `@AutoConfigureOrder`.

**Custom auto-configuration**: Create your own `@AutoConfiguration` class, register it in `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`.

---

## 4. Advanced Nuances and Gotchas

### 4.1 Scopes

- **singleton** (default): one instance per container.
- **prototype**: new instance each time requested.
- **request**: one per HTTP request (web-aware contexts).
- **session**: one per HTTP session.
- **application**: one per `ServletContext`.
- **websocket**: one per WebSocket session.
- **custom**: implement `Scope`.

**Scoped proxies**: To inject a request-scoped bean into a singleton, use `proxyMode`:
```java
@Bean
@Scope(value = WebApplicationContext.SCOPE_REQUEST, proxyMode = ScopedProxyMode.TARGET_CLASS)
public UserContext userContext() {
    return new UserContext();
}
```

### 4.2 Lazy Initialization

- `@Lazy` on a `@Bean` method delays creation until first requested.
- `@Lazy` on an injection point creates a proxy that resolves the bean on first use.
- `@Lazy` on `@Configuration` makes all its beans lazy.
- Useful for breaking circular dependencies.

### 4.3 Circular Dependencies

- Constructor injection: circular dependencies fail immediately.
- Setter/field injection: Spring can sometimes resolve by early exposure, but Spring Boot 2.6+ disables this by default. Enable with `spring.main.allow-circular-references=true`.
- `@Lazy` on one injection point breaks the cycle.

### 4.4 Bean Overriding

- Spring Framework allows overriding bean definitions by default.
- Spring Boot 2.1+ disables it. Enable with `spring.main.allow-bean-definition-overriding=true`.
- Overriding is useful for tests but dangerous in production.

### 4.5 Conditional Beans

- `@Conditional` with custom `Condition` implementation.
- `@Profile` for environment-based activation.
- `@ConditionalOnMissingBean` is evaluated in order — it only sees beans defined *before* the current configuration class. In auto-configuration, user beans are processed first.

### 4.6 Lifecycle Callbacks

- `@PostConstruct` (JSR-250), `InitializingBean.afterPropertiesSet()`, `@Bean(initMethod = "init")`.
- `@PreDestroy`, `DisposableBean.destroy()`, `@Bean(destroyMethod = "close")`.
- Order: `@PostConstruct` → `afterPropertiesSet()` → `initMethod`.

### 4.7 BeanPostProcessor

- Runs for every bean. Can wrap beans (AOP), inject `@Autowired`, `@Value`, call `@PostConstruct`.
- `@Autowired` is processed by `AutowiredAnnotationBeanPostProcessor`.
- `@PostConstruct` is processed by `CommonAnnotationBeanPostProcessor`.
- AOP proxies are created by `AnnotationAwareAspectJAutoProxyCreator` (a `BeanPostProcessor`).

### 4.8 FactoryBean

- A bean that acts as a factory for another bean.
```java
public class MyFactoryBean implements FactoryBean<MyService> {
    @Override
    public MyService getObject() { return new MyService(); }
    @Override
    public Class<?> getObjectType() { return MyService.class; }
    @Override
    public boolean isSingleton() { return true; }
}
```
- `getBean("myFactoryBean")` returns `MyService`.
- `getBean("&myFactoryBean")` returns the `FactoryBean` itself.

### 4.9 ObjectProvider and @Lookup

- `ObjectProvider<T>` provides lazy resolution, optional dependencies, and multiple beans.
- `@Lookup` allows a singleton to obtain a new prototype instance:
```java
@Component
public class SingletonBean {
    @Lookup
    public PrototypeBean getPrototypeBean() { return null; }
}
```

### 4.10 Configuration Properties

- `@ConfigurationProperties(prefix = "my")` on a `@Component` or `@Bean`.
- `@EnableConfigurationProperties(MyProps.class)` registers it.
- `@ConfigurationPropertiesScan` scans for them.
- Binds external configuration to a POJO.

### 4.11 AOP Proxies and Bean Types

- If a bean is proxied, the actual type may be a JDK dynamic proxy (interface-based) or CGLIB subclass.
- Spring Boot defaults to CGLIB (`spring.aop.proxy-target-class=true`).
- Inject by interface when possible to avoid proxy issues.
- Self-injection (injecting a bean into itself) can be used to call proxied methods (e.g., `@Transactional`). Use `@Lazy` or `ObjectProvider` to avoid circular dependency.

### 4.12 Testing

- `@TestConfiguration` defines additional beans for tests. It is not picked up by component scanning.
- `@MockBean` replaces an existing bean with a Mockito mock.
- `@SpyBean` wraps an existing bean with a spy.

---

## 5. Decision Guide: Which Way to Use?

| Scenario | Recommended Approach |
|----------|----------------------|
| Your own classes (service, repository, controller) | `@Component`, `@Service`, `@Repository`, `@Controller` |
| Third-party classes (no source) | `@Bean` in `@Configuration` |
| Conditional beans | `@Conditional`, `@Profile` |
| Modular configuration | `@Import`, `@ImportSelector` |
| Dynamic registration | `BeanDefinitionRegistryPostProcessor`, `ImportBeanDefinitionRegistrar` |
| Spring Boot library | `@AutoConfiguration` + conditions |
| Legacy system | XML |

---

## 6. Putting It All Together: A Concrete Example

```java
// 1. Stereotype annotation
@Service
public class UserService {
    private final UserRepository userRepository;
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
}

// 2. @Bean in @Configuration (third-party class)
@Configuration
public class AppConfig {
    @Bean
    public UserRepository userRepository(DataSource dataSource) {
        return new JpaUserRepository(dataSource);
    }

    @Bean
    @ConditionalOnMissingBean
    public DataSource dataSource() {
        return new HikariDataSource();
    }
}

// 3. Programmatic registration via ImportBeanDefinitionRegistrar
public class MetricsRegistrar implements ImportBeanDefinitionRegistrar {
    @Override
    public void registerBeanDefinitions(AnnotationMetadata metadata, BeanDefinitionRegistry registry) {
        BeanDefinitionBuilder builder = BeanDefinitionBuilder
            .genericBeanDefinition(MetricsService.class)
            .setScope(BeanDefinition.SCOPE_SINGLETON);
        registry.registerBeanDefinition("metricsService", builder.getBeanDefinition());
    }
}

// 4. Import it
@Configuration
@Import(MetricsRegistrar.class)
public class MetricsConfig {}
```

---

## 7. Final Thoughts

Every declaration style ultimately produces a `BeanDefinition`. The differences are about **when** and **how** that definition is registered, and what conditions apply. Mastering beans means understanding the container’s lifecycle, the role of `BeanFactoryPostProcessor` and `BeanPostProcessor`, and the trade-offs between explicit Java config, annotation scanning, and programmatic registration. With this mental model, you can debug bean creation issues, write robust auto-configurations, and design flexible Spring applications.


[[0 - Spring Framework]]
[[Java]]