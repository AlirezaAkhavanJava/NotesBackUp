

**Convention over configuration** is a design rule: a tool should already know the common, sensible way to do things, so you only write settings when you want something _different_. If you follow the usual way, you write almost nothing. If you want to deviate, you say so, and only for that one thing.

Think of ordering coffee. At a good café, you say "a latte" and get a normal-sized latte with normal milk. You do not have to say the cup size, the milk type, the temperature, and the foam depth every time. You only speak up when you want oat milk. Spring Boot works like that café. The phrase was made famous by Ruby on Rails, and Maven and Spring Boot follow the same idea, which is why you can start a Spring Boot project with almost no setup.

---

## Seeing it with your own eyes

Here is a complete web application in Spring Boot:

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
    String hello() {
        return "Hello!";
    }
}
```

Run it, open `http://localhost:8080/hello`, and you see `Hello!`. Now count what you did **not** write:

|You did not write|Who decided it for you|
|---|---|
|Which server to use|Tomcat (embedded, from `spring-boot-starter-web`)|
|Which port|`8080`|
|Where `DispatcherServlet` is registered|Mapped to `/`|
|How Java objects become JSON|Jackson, already wired|
|Where to look for your beans|The package of your main class, and everything below it|
|How to log|Logback, `INFO` level, printed to the console|
|A `web.xml` file|Not needed at all|

Before Boot, each of those lines was your job. Old Spring apps needed a `web.xml`, a `dispatcher-servlet.xml`, a view resolver bean, a message converter bean, and more. Boot looked at what most people wrote and made it the default.

---

## The conventions you meet every day

### 1. Folder layout (Maven)

Maven is a convention-over-configuration tool too. It expects this shape and needs no config to find anything:

|Folder|What lives there|
|---|---|
|`src/main/java`|Your code|
|`src/main/resources`|`application.properties`, static files, templates|
|`src/test/java`|Your tests|
|`target/`|Build output (the JAR or WAR)|

You never tell Maven "my source is here." It already looks there.

### 2. Resource locations in Spring Boot

|Path|Convention|
|---|---|
|`src/main/resources/application.properties`|Read automatically, no import needed|
|`src/main/resources/static/`|Files here are served as-is (`static/logo.png` → `/logo.png`)|
|`src/main/resources/templates/`|Where template engines such as Thymeleaf look|

### 3. Package layout and component scanning

Put your main class in the **root package**:

```
com.example.demo                  ← DemoApplication (main class)
com.example.demo.controller       ← found
com.example.demo.service          ← found
com.example.demo.repository       ← found
```

`@SpringBootApplication` includes `@ComponentScan`, which scans the main class's package **and everything under it**. That is the convention. If you put a controller in `com.other.stuff`, Spring will not find it, because it is outside the scanned area. Breaking a convention means you must configure the gap yourself, for example with `@ComponentScan(basePackages = ...)`.

### 4. Bean names

|You write|Bean name Spring gives it|
|---|---|
|`class UserService` with `@Service`|`userService` (class name, first letter lowercase)|
|`@Bean DataSource myDataSource()`|`myDataSource` (the method name)|

You never type a name unless you need a different one.

### 5. JPA naming

With Spring Boot and Hibernate, names are worked out for you using snake_case:

```java
@Entity
public class UserAccount {
    @Id
    private Long id;
    private String firstName;
    private String emailAddress;
}
```

|Java|Database|
|---|---|
|`UserAccount` (class)|`user_account` (table)|
|`firstName` (field)|`first_name` (column)|
|`emailAddress` (field)|`email_address` (column)|

Boot does this with `CamelCaseToUnderscoresNamingStrategy`. You can override a single name with `@Table(name = "users")` or `@Column(name = "fname")`.

### 6. Spring Data method names

```java
public interface UserRepository extends JpaRepository<UserAccount, Long> {
    List<UserAccount> findByEmailAddress(String email);
    List<UserAccount> findByFirstNameAndActiveTrue(String firstName);
}
```

You wrote **no SQL and no implementation class**. Spring Data reads the method name as a sentence: `findBy` + `FirstName` + `And` + `ActiveTrue`, and builds the query. The name _is_ the configuration.

---

## Overriding: configuration only where you differ

Convention does not lock you in. Each default can be changed in `application.properties`:

```properties
server.port=9090
spring.jpa.show-sql=true
logging.level.root=WARN
```

Line by line:

- `server.port=9090` replaces the default `8080`. Everything else stays the same.
- `spring.jpa.show-sql=true` turns on something that is off by default.
- `logging.level.root=WARN` makes logging quieter than the default `INFO`.

You can also replace whole parts by writing your own bean:

```java
@Configuration
class JsonConfig {
    @Bean
    ObjectMapper objectMapper() {
        return new ObjectMapper().findAndRegisterModules();
    }
}
```

Boot had a default `ObjectMapper`. Because you defined your own, Boot **steps aside** and uses yours. The next section shows why that works.

---

## How Spring Boot makes this possible

Two pieces do the work.

**Starters** bundle the usual dependencies for a goal. Add `spring-boot-starter-web` and you get Spring MVC, Jackson, and Tomcat, all in versions that fit together. You say what you want to build, not which jar versions to pick.

**Auto-configuration** is a large set of ready-made `@Configuration` classes inside Boot. Each one switches on only under conditions:

```java
@Bean
@ConditionalOnMissingBean
public ObjectMapper jacksonObjectMapper() { ... }
```

- `@Bean` creates the default `ObjectMapper`.
- `@ConditionalOnMissingBean` means "only if the user has not defined one." That is how your own bean wins.

Other conditions work the same way. `@ConditionalOnClass` means "only if this library is on the classpath." That is why adding the PostgreSQL driver and a `spring.datasource.url` is enough to get a `DataSource`.

Want to see what Boot decided? Start the app with `--debug` (or set `debug=true`). It prints a **conditions report** listing every auto-configuration that was applied, and every one that was skipped and why.

---

## The honest trade-offs

|Benefit|Cost|
|---|---|
|Less code, faster start|Some behavior is invisible, because nothing in your code says it|
|Every Boot project looks familiar|You must learn the conventions, or things feel like magic|
|Easy to override one thing|Going far off the usual path means writing more config|

The main trap is "it works but I don't know why." The fix is to learn the conventions (this lesson) and use `--debug` when something surprises you.

---

## Related concept: auto-configuration

**Auto-configuration** is the machinery that applies conventions. It scans your classpath and properties, then creates the beans you probably want. Convention over configuration is the _idea_, and auto-configuration is how Spring Boot _delivers_ it. A closely related idea is being **opinionated**: Boot picks one good default (Tomcat, Logback, Jackson) instead of asking you to choose.

---

## Quick recap

- Convention over configuration means sensible defaults first, and settings only when you differ.
- You see it in Maven folders, Boot resource paths, root-package scanning, bean names, JPA snake_case naming, and Spring Data method names.
- Override with properties for small changes, or define your own bean to replace a default.
- Starters and conditional auto-configuration (`@ConditionalOnMissingBean`) make it work.
- When Boot surprises you, run with `--debug` and read the conditions report.

[[Spring Framework]]