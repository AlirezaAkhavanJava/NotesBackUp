

`@Configuration` marks a class as a **configuration class**: a place where you describe, in plain Java, which beans Spring should create and how to wire them together. Inside it, each method marked `@Bean` is one recipe, and Spring turns it into a bean in the container.

It is the Java version of the old XML bean files, and Spring Boot's own auto-configuration is built from classes just like it. In this note you'll see what Spring does with such a class, what you can put in it besides beans, and the mistakes that catch people out. It connects several earlier topics: declaring beans, profiles, `@PropertySource`, `@ConfigurationProperties` and `Environment` all show up inside configuration classes.

---

## What Spring does with it, in order

You saw in the bean-declaration note that Spring works in two phases: register the recipes first, build the objects later. A configuration class follows that pattern exactly.

```text
1. Spring finds your @Configuration class
   (component scan from your main class, or you point at it with @Import)
        │
        ▼
2. ConfigurationClassPostProcessor reads it and registers a
   BeanDefinition for every @Bean method   ← recipes only, nothing built yet
        │
        ▼
3. Spring creates the beans, calling each @Bean method ONCE
        │
        ▼
4. Dependencies are injected, init callbacks run, the app is ready
```

Two corrections to common beliefs:

- **Beans are not lazy by default.** Singletons are created eagerly at startup, in step 3. That is how Spring finds wiring errors immediately instead of at the first request. To delay a bean, add `@Lazy` or set `spring.main.lazy-initialization=true`.
- **Reading the class doesn't call your methods.** Step 2 only registers definitions. The methods run later, in step 3.

---

## A basic configuration class

```java
@Configuration
public class AppConfig {

    @Bean
    public UserRepository userRepository() {
        return new JpaUserRepository();
    }

    @Bean
    public UserService userService(UserRepository userRepository) {   // injected by Spring
        return new UserService(userRepository);
    }
}
```

Line by line:

- `@Configuration` makes the class eligible. It is itself marked with `@Component`, so component scanning finds it, which is why Spring Boot picks it up with no extra work when it's under your main package.
- The method name is the bean name (`userRepository`, `userService`).
- Method **parameters** are injected from the container. `userService` receives the repository bean.
- `@Bean` fits best when the class isn't yours to annotate, or creation needs logic. For your own classes, `@Service` is simpler.

You can also configure each bean on its `@Bean` method: `@Scope`, `@Lazy`, `@Primary`, `@DependsOn`, `initMethod`, `destroyMethod` and `@Profile`.

---

## Calling another `@Bean` method versus taking a parameter

This is the most important subtlety, and the bean-declaration note introduced it as "full mode versus lite mode."

```java
@Bean
public UserService userService() {
    return new UserService(userRepository());   // direct call to another @Bean method
}
```

In a normal `@Configuration` class, Spring wraps the class in a proxy so that `userRepository()` returns the **existing singleton**, not a new object. That is `proxyBeanMethods = true`, the default. With `@Configuration(proxyBeanMethods = false)`, or in a plain `@Component` class, the same call creates a **brand-new object**.

The safe habit is to take the dependency as a method parameter, as in the first example. It behaves the same in both modes, and it makes the dependency visible in the signature.

The proxy also explains two rules:

- With the default proxying, the class must **not be `final`**, and `@Bean` methods must not be `private` or `final`, because Spring subclasses the class.
- With `proxyBeanMethods = false`, those limits go away. Spring Boot's own auto-configuration classes use it, which makes them faster.

---

## What else can live in a configuration class

A configuration class is a hub for _configuration_, and beans are the main part of that. Here is what else belongs there:

|You want to...|Put this on the class (or in it)|Covered in|
|---|---|---|
|Pull in other configuration|`@Import({SecurityConfig.class, MailConfig.class})`|Bean declaration note|
|Choose where to scan|`@ComponentScan(basePackages = "...")`|Bean declaration note|
|Load an extra properties file|`@PropertySource("classpath:mail-config.properties")`|`@PropertySource` note|
|Register a typed properties record|`@EnableConfigurationProperties(MailProperties.class)`|`@ConfigurationProperties` note|
|Create beans only in some profiles|`@Profile("dev")` on the class or a method|Profiles note|
|Read settings in a `@Bean` method|Add an `Environment` parameter|`Environment` note|
|Switch on a Spring feature|An `@Enable...` annotation, such as `@EnableScheduling`|Below|
|Create a bean conditionally|`@ConditionalOnProperty`, `@ConditionalOnMissingBean`|Auto-configuration note|

Many `@Enable...` annotations work through `@Import`. They bring in a whole configuration class that sets up the feature.

### All together

```java
@Configuration
@PropertySource("classpath:mail-config.properties")      // load the file
@EnableConfigurationProperties(MailProperties.class)     // register the typed record
@Import(SecurityConfig.class)                            // compose another config
public class MailConfig {

    @Bean
    public MailSender mailSender(MailProperties props) {  // record injected as a parameter
        return new SmtpMailSender(props.host(), props.port());
    }
}
```

Here one class loads a file, registers the record that binds it, imports another config, and builds a bean from that record.

---

## Splitting configuration by purpose

Don't put everything in one giant class. Make one configuration class per concern, and let the main class import or scan them:

```java
@Configuration
@Profile("dev")
public class DevDataConfig { ... }         // only exists in dev

@Configuration
public class MailConfig { ... }            // mail beans

@Configuration
public class SecurityConfig { ... }        // security beans
```

If a configuration class is nested inside another, make it **`static`**. A non-static inner class needs an instance of the outer class to exist first, which gets in the way.

---

## Mistakes to avoid

- **Thinking beans are lazy.** They're created at startup unless you ask otherwise.
- **Calling `@Bean` methods directly in lite mode.** Take parameters instead.
- **`@Bean` method names that clash.** Two methods (or a `@Component` and a `@Bean`) with the same bean name make Boot fail at startup, because bean overriding is off by default.
- **Making the class `final`** while proxying is on.
- **Putting business logic in configuration classes.** They should wire things together. The logic belongs in your services.
- **Using `@Profile` beans to vary only a value.** The profiles note covers this: put values in `application-{profile}.properties`, and keep `@Profile` for different implementations.

---

## Related concept in short

**`@AutoConfiguration`** is how Spring Boot ships its own configuration classes. It is a `@Configuration(proxyBeanMethods = false)` with extra ordering rules, and it is combined with `@ConditionalOn...` annotations so its beans back off when you define your own.





[[Spring Framework]]