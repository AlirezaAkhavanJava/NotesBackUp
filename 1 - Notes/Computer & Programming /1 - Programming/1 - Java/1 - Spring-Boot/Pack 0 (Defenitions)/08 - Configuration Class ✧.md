

A **configuration class** is a normal Java class marked with `@Configuration` whose job is to tell Spring _which beans to create and how to build them_. Instead of letting Spring discover your classes by scanning for `@Component`, you write the recipe yourself, in plain Java, inside methods annotated with `@Bean`.

Think of it as a kitchen instruction sheet for Spring. Each `@Bean` method is one dish: the method name is the dish name, the method body is how to make it, and the return value is the finished dish that Spring stores in its container. You will use configuration classes whenever you need to create a bean from a class you don't own (like a library class), or when creation needs real logic.

---

## The smallest possible example

```java
@Configuration
public class AppConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

Line by line:

1. `@Configuration` tells Spring: "This class contains bean definitions. Read it at startup."
2. `@Bean` tells Spring: "Run this method, and keep the returned object as a bean."
3. `public PasswordEncoder passwordEncoder()` is the method. The **return type** is the type of the bean, and the **method name** (`passwordEncoder`) becomes the bean's name.
4. `return new BCryptPasswordEncoder();` is the recipe. Spring calls it once and stores the result.

Now any other bean can ask for it:

```java
@Service
public class UserService {
    private final PasswordEncoder encoder;

    public UserService(PasswordEncoder encoder) {   // Spring injects the bean
        this.encoder = encoder;
    }
}
```

You never wrote `new` for the encoder in `UserService`. That's the container doing its job.

---

## Why not just use `@Component`?

`@Component` works on classes **you wrote**, because you can put the annotation on them. But you can't edit `BCryptPasswordEncoder`, `ObjectMapper`, `DataSource`, or `RestTemplate`. They live inside libraries. A `@Bean` method lets you create and register them anyway.

|You want to...|Use|
|---|---|
|Register your own simple class|`@Component` / `@Service` / `@Repository`|
|Register a library class|`@Bean` in a `@Configuration` class|
|Build a bean with choices or logic (profiles, conditions, settings)|`@Bean` in a `@Configuration` class|
|Create several beans of the same type with different settings|`@Bean` methods with different names|

---

## Beans that depend on other beans

There are two good ways to wire beans together inside a configuration class.

**Way 1: method parameters (preferred).** Spring injects whatever you ask for:

```java
@Configuration
public class AppConfig {

    @Bean
    public DataSource dataSource() {
        HikariDataSource ds = new HikariDataSource();
        ds.setJdbcUrl("jdbc:postgresql://localhost:5432/mydb");
        return ds;
    }

    @Bean
    public JdbcTemplate jdbcTemplate(DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }
}
```

Here `jdbcTemplate` declares that it needs a `DataSource`. Spring finds the `dataSource` bean, creates it first, and passes it in. The creation order comes for free, so you don't need `@DependsOn`.

**Way 2: calling another `@Bean` method directly:**

```java
@Bean
public JdbcTemplate jdbcTemplate() {
    return new JdbcTemplate(dataSource());   // calls the other @Bean method
}
```

This looks like it would create a second `DataSource` each time, but it doesn't. Spring wraps your configuration class in a proxy (more on this next), and that proxy intercepts the call and returns the existing bean.

---

## The hidden trick: CGLIB proxy and "full mode"

By default, Spring doesn't run your `@Configuration` class directly. It creates a **subclass** of it at startup (using CGLIB) and uses that. This subclass overrides each `@Bean` method like this: "If this bean already exists, return it. Otherwise, call the real method and store the result."

That is why calling `dataSource()` twice gives you the same object. The beans stay **singletons**.

You can see the difference with `@Component`:

```java
@Component                       // "lite mode": no proxy
public class LiteConfig {
    @Bean public A a() { return new A(); }
    @Bean public B b() { return new B(a()); }   // creates a NEW A, not the bean
}
```

With `@Configuration` (full mode), `b()` gets the shared `A` bean. With `@Component` (lite mode), it gets a fresh `A` and you've broken the singleton rule. If you want to avoid the proxy cost and use parameters for wiring, you can set `@Configuration(proxyBeanMethods = false)`. Spring Boot's own auto-configuration classes do this for faster startup.

---

## Bean names, and more than one bean of a type

```java
@Configuration
public class ClientConfig {

    @Bean                              // name: "fastClient"
    public HttpClient fastClient() { ... }

    @Bean("slowClient")                // name set explicitly
    public HttpClient slowClient() { ... }
}
```

With two beans of the same type, injection becomes ambiguous. You pick one using `@Qualifier("fastClient")` at the injection point, or mark one `@Primary` as the default.

---

## Useful annotations that pair with configuration classes

|Annotation|What it does here|
|---|---|
|`@Import(OtherConfig.class)`|Pulls another configuration class into this one|
|`@ComponentScan("com.example")`|Tells Spring to scan packages for `@Component` classes|
|`@Profile("dev")`|Loads the class (or one bean) only in the "dev" profile|
|`@ConditionalOnProperty` (Boot)|Creates the bean only if a property is set|
|`@PropertySource` / `@Value`|Reads values from property files|
|`@EnableXxx` (e.g. `@EnableScheduling`)|Switches on a Spring feature|
|`@DependsOn`|Forces creation order when injection can't show it|
|`@Scope("prototype")`|Changes how many instances Spring makes|

Example with a profile:

```java
@Configuration
@Profile("dev")
public class DevConfig {
    @Bean
    public DataSource devDataSource() { /* H2 in-memory */ }
}
```

---

## Where this shows up in your Spring Security work

Your JWT lab almost certainly has a class like this:

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception { ... }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config)
            throws Exception {
        return config.getAuthenticationManager();
    }
}
```

Both methods are `@Bean` recipes. Spring passes `HttpSecurity` and `AuthenticationConfiguration` in as parameters, and registers what you return. That's the configuration class idea in real use.

---

## Configuration class vs. other ways to define beans

Spring has had three styles over the years:

1. **XML files** (`applicationContext.xml`): the old way.
2. **Annotation scanning** (`@Component` and friends): good for your own classes.
3. **Java configuration** (`@Configuration` + `@Bean`): type-safe, refactor-friendly, and the standard for third-party objects and logic.

Modern Spring Boot projects mix 2 and 3. Annotation scanning does the bulk, and configuration classes handle the special cases.

---

## Short summary of a related concept: `@SpringBootApplication`

Your main class is already a configuration class. `@SpringBootApplication` is a shortcut that combines three annotations: `@Configuration` (it can hold `@Bean` methods), `@ComponentScan` (it scans its package and below), and `@EnableAutoConfiguration` (Spring Boot adds beans automatically based on your dependencies). That's why you can put a `@Bean` method straight in your main class, though keeping them in separate configuration classes is tidier.

---

## Takeaways

- A configuration class is a Java class with `@Configuration` that holds `@Bean` methods, which are recipes for Spring beans.
- Use it for **library classes** and **beans that need logic**; use `@Component` for your own simple classes.
- The method **name** is the bean name, the **return type** is the bean type, and **parameters** are injected dependencies.
- `@Configuration` classes are proxied, so calling one `@Bean` method from another still returns the shared singleton.
- Combine with `@Profile`, `@Import`, `@Qualifier`, and `@DependsOn` to control which beans exist, which one wins, and in what order.






[[Spring Framework]]