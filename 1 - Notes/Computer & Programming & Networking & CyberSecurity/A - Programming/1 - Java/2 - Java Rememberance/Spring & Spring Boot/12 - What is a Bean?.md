> A **Bean** is literally the name for any object that container manages. Let's go through it properly.

## What is a Bean?

A **Bean** is an object that is:

1. **Instantiated** by the Spring IoC container (not by you calling `new` directly)
2. **Assembled** (its dependencies injected) by the container
3. **Managed** by the container for its entire lifecycle (creation → use → destruction)

In other words: any object sitting in that `Map<String, Object>` inside the `ApplicationContext` we discussed is a bean. Not every object in your app is a bean — only the ones you've told Spring to manage.

```java
@Service
public class UserService { } // this becomes a bean

UserService manual = new UserService(); // this is NOT a bean — you created it yourself, Spring doesn't know it exists
```

---

## Bean Lifecycle

This is the sequence of stages every bean goes through, from creation to destruction. Full order:

```
1. Container starts
2. Bean instantiation           → constructor called (or factory method)
3. Populate properties           → dependencies injected (@Autowired fields/setters)
4. Aware interfaces called       → e.g. BeanNameAware, ApplicationContextAware
5. BeanPostProcessor (before)    → postProcessBeforeInitialization()
6. @PostConstruct method         → your custom init logic
7. InitializingBean.afterPropertiesSet() → if implemented
8. Custom init-method            → if specified
9. BeanPostProcessor (after)     → postProcessAfterInitialization()
   ── Bean is now fully ready and in use ──
10. Container shutdown begins
11. @PreDestroy method           → your custom cleanup logic
12. DisposableBean.destroy()     → if implemented
13. Custom destroy-method        → if specified
```

### In code — the parts you'll actually use

```java
@Component
public class DatabaseConnector {

    public DatabaseConnector() {
        System.out.println("1. Constructor called");
    }

    @Autowired
    public void setDataSource(DataSource dataSource) {
        System.out.println("2. Dependency injected");
    }

    @PostConstruct
    public void init() {
        System.out.println("3. @PostConstruct — connection pool warmed up");
    }

    @PreDestroy
    public void cleanup() {
        System.out.println("4. @PreDestroy — closing connections");
    }
}
```

`@PostConstruct` and `@PreDestroy` are the ones you'll use 95% of the time — they're simple, standard (from `jakarta.annotation`, not Spring-specific), and clear.

### Why the lifecycle matters practically

- `@PostConstruct` is where you put setup logic that needs the bean's dependencies **already injected** (you can't do this reliably in the constructor if dependencies come via setter injection)
- `@PreDestroy` is where you release resources (close connections, flush caches, shut down thread pools) before the app context shuts down — important for graceful shutdown

---

## Bean Scopes (a "feature" of beans — controls lifecycle/sharing)

This determines **how many instances** exist and **when** they're created:

|Scope|Meaning|
|---|---|
|`singleton` (default)|**One instance** per container, shared everywhere it's injected|
|`prototype`|**New instance** every time it's requested/injected|
|`request`|One instance **per HTTP request** (web apps only)|
|`session`|One instance **per HTTP session** (web apps only)|
|`application`|One instance per `ServletContext`|

```java
@Service
@Scope("prototype")
public class ReportGenerator {
    // a new ReportGenerator is created every time it's injected/requested
}
```

Singleton is default and usually what you want — stateless services, repositories, controllers. Prototype is for stateful objects that shouldn't be shared (e.g., something holding per-use mutable state).

---

## Ways to Configure Beans (declare what should become a bean)

There are three main approaches, and it's worth knowing all three since you'll see them in different codebases.

### 1. Annotation-based (stereotype annotations) — most common today

You annotate your own classes directly:

```java
@Component   // generic "this is a bean"
public class SomeUtility { }

@Service     // semantic: business logic layer
public class UserService { }

@Repository  // semantic: data access layer (also enables exception translation)
public class UserRepository { }

@Controller  // semantic: web layer (returns views)
public class HomeController { }

@RestController // semantic: web layer (returns JSON) = @Controller + @ResponseBody
public class UserController { }
```

All of these are actually specializations of `@Component` — Spring's component scanning (`@ComponentScan`, enabled automatically by `@SpringBootApplication`) finds any class annotated with `@Component` (or any annotation _meta-annotated_ with `@Component`) and registers it as a bean.

**Use this when:** it's your own class and you can add annotations to it directly.

### 2. Java-based configuration (`@Configuration` + `@Bean`)

```java
@Configuration
public class AppConfig {

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    @Bean
    public ObjectMapper objectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        return mapper;
    }
}
```

- `@Configuration` marks the class as a source of bean definitions
- `@Bean` on a method means "whatever this method returns becomes a managed bean"

**Use this when:** the class comes from a **third-party library** (you can't add `@Component` to `RestTemplate`'s source code — you don't own it), or when bean creation needs custom logic (like the `ObjectMapper` config above).

### 3. XML-based configuration (legacy, rarely used in new Spring Boot projects)

```xml
<beans>
    <bean id="userService" class="com.example.UserService">
        <constructor-arg ref="userRepository"/>
    </bean>
</beans>
```

You'll see this in older/legacy Spring (pre-Boot) codebases. Spring Boot almost never uses this anymore — mentioned for completeness since you might encounter it in enterprise legacy systems.

---

## Other Bean Features worth knowing

### Dependency between beans with `@Bean` methods

```java
@Configuration
public class AppConfig {
    @Bean
    public UserRepository userRepository() {
        return new UserRepository();
    }

    @Bean
    public UserService userService(UserRepository userRepository) { // parameter injection
        return new UserService(userRepository);
    }
}
```

Spring sees `userService` needs a `UserRepository` parameter and automatically supplies the `userRepository` bean — cleaner than calling `userRepository()` directly inside the method.

### `@Primary` — resolving ambiguity

If multiple beans of the same type exist, and you inject by type, Spring doesn't know which one to use — this is the "ambiguous dependency" error I mentioned earlier. `@Primary` marks the default choice:

```java
@Bean
@Primary
public DataSource primaryDataSource() { ... }

@Bean
public DataSource secondaryDataSource() { ... }
```

### `@Qualifier` — explicit choice at injection point

```java
@Autowired
public UserService(@Qualifier("secondaryDataSource") DataSource dataSource) { ... }
```

### `@Lazy` — delay creation until first use

```java
@Component
@Lazy
public class ExpensiveResource { }
```

By default, singleton beans are created **eagerly** at startup. `@Lazy` defers creation until the bean is first requested — useful for rarely-used, expensive-to-create beans.

### Conditional beans — Spring Boot's auto-configuration trick

```java
@Bean
@ConditionalOnMissingBean
public UserService defaultUserService() {
    return new UserService();
}
```

This is actually how Spring Boot's auto-configuration works under the hood — it defines default beans, but only if you haven't defined your own. This is the mechanism behind that "convention over configuration" magic we talked about in your very first question.

---

## Tying it all together

```java
@SpringBootApplication  // triggers @ComponentScan, @EnableAutoConfiguration, @Configuration
public class MyApp {
    public static void main(String[] args) {
        SpringApplication.run(MyApp.class, args); // creates the IoC container
    }
}
```

When this runs:

1. Container starts, scans for `@Component`/`@Service`/`@Repository`/`@Controller`/`@Configuration` classes
2. For each, runs the **lifecycle** — constructor → inject dependencies → `@PostConstruct`
3. Registers each as a bean in the internal map, respecting **scope** (singleton by default)
4. Handles conflicts via `@Primary`/`@Qualifier`
5. On shutdown, runs `@PreDestroy` on all beans before the JVM exits

Want to go through `BeanPostProcessor` next (it's how Spring itself implements features like `@Autowired` and AOP proxying internally — ties directly into the lifecycle diagram above), or move to something more applied like setting up a real project structure?



[[Java]]
[[0 - Spring Framework]]
[[0 - Spring + Spring Boot]]
[[7.1 - Bean LifeCycle 👻]]
[[8 - Bean 🍩]]
[[10 - BeanFactory 🍩]]
