

Convention over configuration means the framework already knows the usual way to do things, so you only write settings where your project differs. The problem it solves is real: classic Spring apps needed pages of XML or Java config (`web.xml`, a dispatcher config, view resolvers, message converters) before they could print "Hello". Most of that config was identical across projects, so Boot turned the common choices into defaults.

This tutorial follows one tiny app. You'll see the defaults working, then break each one to see how it behaves and how to fix it.

## Step 1: The app with zero configuration

```java
@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}

@RestController
class HelloController {
    @GetMapping("/hello")
    String hello() { return "Hello!"; }
}
```

Run it and open `http://localhost:8080/hello`. You never chose a server, a port, a JSON library or a logger. Tomcat, 8080, Jackson and Logback were all chosen for you.

## Step 2: Where the conventions come from

There are three sources, and knowing which one you're dealing with tells you where to look when something goes wrong.

|Source|Example|Who enforces it|
|---|---|---|
|**The build tool**|Code in `src/main/java`, config in `src/main/resources`|Maven/Gradle|
|**Boot's auto-configuration**|Embedded Tomcat, port 8080, a default `ObjectMapper`|Boot, based on your classpath and properties|
|**Naming rules**|`UserAccount` → table `user_account`; `UserService` → bean `userService`|Hibernate and Spring|

Auto-configuration has two parts. **Starters** are dependency bundles: `spring-boot-starter-web` brings Spring MVC, Jackson and Tomcat in matching versions. **Auto-configuration classes** are the logic: each one creates default beans only when certain conditions hold.

```java
@Bean
@ConditionalOnMissingBean   // "only if the user hasn't defined one"
ObjectMapper jacksonObjectMapper() { ... }
```

Defaults that switch on when something is present (`@ConditionalOnClass`) and step aside when you define your own (`@ConditionalOnMissingBean`) are what make overriding painless.

## Step 3: Break it on purpose

**Break 1: move a controller outside the main package.**

```
com.example.demo.DemoApplication      ← main class
com.other.HelloController             ← outside
```

The app starts without errors, but `/hello` returns 404. `@SpringBootApplication` includes `@ComponentScan`, which scans only the main class's package and below. This is the most common convention-related bug, because nothing crashes. The fix is to move the class, or to widen the scan with `@SpringBootApplication(scanBasePackages = "com.other")`.

**Break 2: change the port.**

```properties
# application.properties
server.port=9090
```

Only this one default changes. The same property can be set from an environment variable (`SERVER_PORT=9090`) or the command line (`--server.port=9090`), and those take priority over the file. That is how the same JAR runs unchanged in dev and production.

**Break 3: customize JSON.** Don't replace the `ObjectMapper` bean, because you would lose Boot's other Jackson setup. Use properties, or a customizer that adjusts Boot's mapper:

```properties
spring.jackson.default-property-inclusion=non_null
```

```java
@Bean
Jackson2ObjectMapperBuilderCustomizer customizer() {
    return builder -> builder.simpleDateFormat("yyyy-MM-dd");
}
```

Define a full replacement bean only when you really need total control.

**Break 4: naming in JPA.**

```java
@Entity
public class UserAccount {
    @Id Long id;
    String firstName;
    boolean active;
}
```

The table becomes `user_account` and the columns `first_name` and `active`. This works because Boot configures a physical naming strategy that converts camelCase to snake_case. In recent Boot versions that is Hibernate's `CamelCaseToUnderscoresNamingStrategy`, which Hibernate copied from Boot's older `SpringPhysicalNamingStrategy`. Override one name with `@Table(name = "users")` or `@Column(name = "fname")`.

**Break 5: Spring Data method names.**

```java
interface UserRepository extends JpaRepository<UserAccount, Long> {
    List<UserAccount> findByFirstNameAndActiveTrue(String firstName);
}
```

Spring Data parses the method name against your entity's properties and builds the query. This is a naming rule rather than a framework default. Misspell `Active` and the app refuses to start, so the mistake is caught early instead of at runtime.

## Step 4: Finding out what Boot decided

When behavior surprises you, don't guess. Start the app with `--debug` (or `debug=true`) and Boot prints the **conditions report**. It lists every auto-configuration that was applied or skipped, with the exact condition that decided it. Most "magic" turns out to be a single `@ConditionalOn...` line.

## Trade-offs

Convention gives you less code and a familiar layout in every Boot project. It costs you visibility: behavior exists that no line of your code states, so you need to know the conventions, and the further you stray from them, the more config you write. Running with `--debug` is the safety net.

## Related concepts to study next

- **Opinionated defaults**: Boot picks one option (Tomcat, Logback, Jackson) instead of asking you to choose. You can swap any of them, for example Jetty for Tomcat.
- **Externalized configuration**: the full property precedence order (command line, environment, profile files, `application.properties`).
- **Profiles** (`application-prod.properties`): conventions that vary per environment.
- **Writing your own starter**: the best way to understand auto-configuration is to build one.


[[Spring Framework]]