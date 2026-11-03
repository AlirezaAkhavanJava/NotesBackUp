


These two imports sit at the start of almost every Spring Boot app:

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
```

They do two different jobs. **`@SpringBootApplication` is an annotation that tells Spring how to configure your app**: where to look for your classes and what to set up automatically. **`SpringApplication` is the class that starts the app**: it creates the Spring container and runs everything.

Once you see that split (configuration versus startup), most of Spring Boot's "magic" stops being mysterious.

```java
@SpringBootApplication                                   // the "what"
public class MyApplication {
    public static void main(String[] args) {
        SpringApplication.run(MyApplication.class, args); // the "go"
    }
}
```

Line by line:

- `@SpringBootApplication` marks this class as the main configuration.
- `main` is a normal Java entry point.
- `SpringApplication.run(...)` starts Spring, using `MyApplication.class` as the starting point for finding your configuration.

---

## Part 1: `@SpringBootApplication` is three annotations in one

It's a shortcut for:

```java
@Configuration
@EnableAutoConfiguration
@ComponentScan
```

(Technically it uses `@SpringBootConfiguration`, which is a `@Configuration` underneath. Thinking of it as `@Configuration` is fine.)

|Annotation|What it does for you|
|---|---|
|`@Configuration`|This class can declare beans with `@Bean` methods|
|`@ComponentScan`|Find your `@Component`, `@Service`, `@Repository`, `@Controller` classes|
|`@EnableAutoConfiguration`|Set up infrastructure (web server, database, JSON) based on what's on the classpath|

### `@Configuration`: your main class can hold beans

```java
@SpringBootApplication
public class MyApplication {
    @Bean
    public Clock clock() { return Clock.systemUTC(); }
}
```

Spring calls `clock()` and manages the result as a bean. Nothing special, just a normal configuration class.

### `@ComponentScan`: where Spring looks

Scanning starts at the package of the annotated class and goes **downward**.

```text
com.example.myapp
├── MyApplication.java      ← scanning starts here
├── controller/             ✔ scanned
├── service/                ✔ scanned
└── repository/             ✔ scanned

org.foo.controller/         ✘ NOT scanned (different package tree)
```

This is the classic beginner bug: a controller outside your main package is silently ignored, and you get 404s or "bean not found" errors. The fix is to move the class under the main package. The alternative is `@SpringBootApplication(scanBasePackages = "...")`, but fixing the structure is usually better.

### `@EnableAutoConfiguration`: the real "magic"

Plain Spring would never guess "PostgreSQL is on the classpath, so I'll create a `DataSource`." Boot does, using **conditions**:

```text
Is the class there?  ──yes──► configure it
                     ──no───► skip it
```

Common conditions (you'll see these in Boot's own source):

- `@ConditionalOnClass(DataSource.class)`: only if that class exists on the classpath.
- `@ConditionalOnMissingBean`: only if **you** haven't defined your own bean.
- `@ConditionalOnProperty`: only if a property is set.

The `@ConditionalOnMissingBean` condition is what makes Boot **overridable**. If you define your own `DataSource` bean, Boot's default "backs off." You get sensible defaults without losing control.

**A real example.** You add `spring-boot-starter-data-jpa`, a PostgreSQL driver, and these properties:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=postgres
spring.datasource.password=password
```

You never write a `DataSource`, `EntityManagerFactory` or `TransactionManager`. The chain is:

```text
Starter adds jars → classes are on the classpath → conditions pass
→ Boot's auto-config creates the beans
```

Note that a **starter only puts jars on the classpath**. The auto-configuration is what turns those jars into beans. They're two separate steps.

---

## Part 2: `SpringApplication` is the launcher

`SpringApplication.run(...)` coordinates startup. In order, it roughly does this:

1. Works out the application type (`SERVLET` for Spring MVC, `REACTIVE` for WebFlux, `NONE` for no web).
2. Prepares the `Environment` (properties, profiles).
3. Creates the `ApplicationContext`.
4. Processes your `@SpringBootApplication` class (config, scanning, auto-config) and registers bean definitions.
5. Refreshes the context, which creates the beans and injects dependencies.
6. Starts the embedded web server if it's a web app.
7. Publishes startup events and returns the context.

The exact internals change between Boot versions, but this order is the right mental model.

**`SpringApplication` does not contain Tomcat or your beans.** It only coordinates. Tomcat arrives through the web starter's dependencies and auto-configuration. Your beans live in the container.

### `SpringApplication` vs `ApplicationContext`

These get mixed up constantly, so keep them apart:

- **`SpringApplication`** is the starter. It runs once at startup.
- **`ApplicationContext`** is the running container that holds your beans.

`run()` returns the context, so you can use it:

```java
ConfigurableApplicationContext ctx = SpringApplication.run(MyApplication.class, args);
UserService s = ctx.getBean(UserService.class);
```

This is fine for learning and for rare bootstrap code. In real application code, use constructor injection instead of `getBean()`.

### Customizing startup

If you need control, build it yourself instead of calling the static `run`:

```java
SpringApplication app = new SpringApplication(MyApplication.class);
app.setAdditionalProfiles("dev");
app.run(args);
```

You can set profiles, listeners, initializers, the banner and the application type this way.

---

## Part 3: They are independent

Remove the annotation and keep `run()`:

```java
public class MyApplication {
    public static void main(String[] args) {
        SpringApplication.run(MyApplication.class, args);
    }
}
```

It still starts a Spring container, but with no scanning and no auto-configuration, so your beans aren't found and no server is set up. You'd have to add `@Configuration`, `@ComponentScan` and `@EnableAutoConfiguration` yourself. So the annotation supplies the **configuration**, and `SpringApplication` supplies the **startup**.

Here is the full flow:

```text
main()
  └─ SpringApplication.run(MyApplication.class)
        └─ creates ApplicationContext
              └─ reads @SpringBootApplication
                    ├─ @Configuration         → your @Bean methods
                    ├─ @ComponentScan         → your stereotype classes
                    └─ @EnableAutoConfiguration → conditional Boot beans
              └─ bean definitions → beans created → DI → app running
```

---

## Debugging auto-configuration

Auto-configuration isn't a black box. Add this to `application.properties`:

```properties
debug=true
```

On startup, Boot prints a **conditions report**:

- **Positive matches**: what was configured, and why.
- **Negative matches**: what was skipped, and which condition failed.

This answers "why did (or didn't) Boot create this bean?" You can also turn off a specific auto-config, but only when you have a clear reason, such as replacing it with your own:

```java
@SpringBootApplication(exclude = SomeAutoConfiguration.class)
```

---

## Related concept in short

**Starter**: a dependency bundle such as `spring-boot-starter-web`. It brings the jars. Auto-configuration then decides what to do with them.

---

## Common mistakes

- **"`@SpringBootApplication` starts Spring."** It doesn't. It only describes the configuration. `SpringApplication.run()` starts the app.
- **"`SpringApplication` creates my objects."** The `ApplicationContext` does. `SpringApplication` sets it up.
- **Putting classes outside the main package.** They won't be scanned.

---

## Test yourself

1. Why isn't `SpringApplication` the Spring container? What does `ApplicationContext` do in between?
2. You add PostgreSQL and Spring Data JPA but define no `DataSource`. Walk through the chain, from the dependency to Boot deciding to create one, including the role of conditions.



[[Spring Framework]]