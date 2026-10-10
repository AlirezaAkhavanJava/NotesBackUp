
## Core intuition

You now know two separate ways to configure Spring: XML files (`<bean>`, `<context:component-scan>`) and Java `@Configuration` classes (`@ComponentScan`, `@Bean`). In real legacy codebases you often need **both at once** — maybe 80% of the app is now annotation-based, but there's one old XML file nobody's migrated yet. Spring lets a `@Configuration` class pull in an XML file (or vice versa), so the two systems merge into one `ApplicationContext`.

Think of it as: your Java config class says _"also load these XML instructions,"_ and the container merges both sets of bean definitions into the same container.

## The mechanism: `@ImportResource`

```java
@Configuration
@ComponentScan(basePackages = "com.arcade")
@ImportResource("classpath:legacy-beans.xml")
public class AppConfig {

    @Bean
    public GameRepository gameRepository() {
        return new GameRepository();
    }
}
```

```xml
<!-- legacy-beans.xml -->
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="legacyPaymentService" class="com.arcade.legacy.PaymentService" />
</beans>
```

What happens at startup:

1. `@ComponentScan` finds and registers your annotated `@Service`/`@Repository`/`@Component` classes
2. The `@Bean` method registers `gameRepository`
3. `@ImportResource` tells Spring to **also** parse `legacy-beans.xml` and register `legacyPaymentService`

All three end up in the **same** `ApplicationContext` — a bean from the XML file can be `@Autowired` into a class found by `@ComponentScan`, and vice versa. They're not separate containers; it's one merged bean registry.

## The reverse direction: XML pulling in annotation scanning

This is actually what you were doing earlier without naming it — XML can trigger annotation-based discovery too:

```xml
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
           http://www.springframework.org/schema/beans/spring-beans.xsd
           http://www.springframework.org/schema/context
           http://www.springframework.org/schema/context/spring-context.xsd">

    <context:component-scan base-package="com.arcade" />
    <context:annotation-config />

</beans>
```

- `<context:component-scan>` — finds `@Component`/`@Service`/`@Repository`/`@Controller` classes, same as `@ComponentScan`
- `<context:annotation-config />` — activates processing of `@Autowired`, `@Qualifier`, `@Value`, `@PostConstruct` etc. **on beans you declared manually with `<bean>` tags in that same XML file.** (Note: `<context:component-scan>` already implies this — you only need `<context:annotation-config />` standalone if you're _not_ using component-scan but still want annotations honored on your XML-declared beans.)

So the full picture of "mixing," both directions:

|Direction|How|
|---|---|
|Java config → load XML|`@ImportResource("classpath:file.xml")` on a `@Configuration` class|
|XML → enable annotation scanning|`<context:component-scan base-package="..."/>` inside the XML file|
|XML → load another XML file|`<import resource="other-file.xml" />`|

## Full combined example

```java
@Configuration
@ComponentScan(basePackages = "com.arcade.service")  // scans only service package
@ImportResource("classpath:repository-config.xml")    // old repo beans still in XML
public class AppConfig {
}
```

```xml
<!-- repository-config.xml -->
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="...">

    <context:component-scan base-package="com.arcade.repository" />

    <bean id="legacyAuditLogger" class="com.arcade.legacy.AuditLogger" />
</beans>
```

Here the Java config scans `service`, the XML scans `repository` _and_ manually declares `legacyAuditLogger`. All four categories of beans — annotated services, annotated repos, the XML-declared bean, any `@Bean` methods — end up in one shared context, freely autowirable into each other.

## Gotchas specific to mixing

- **Loading order matters for conflicts.** If both a `@Bean` method and an XML `<bean>` define the same bean `id`/name, whichever is processed **later** wins (same silent-override behavior you saw with duplicate XML `id`s). This gets genuinely confusing in large mixed apps — avoid overlapping names across the two systems.
- **`@ImportResource` path format:** `classpath:` prefix is required for a file on the classpath (e.g., `src/main/resources/`). Omitting it or using a plain relative path is a common source of `FileNotFoundException` at startup.
- **You can import multiple XML files at once:**
    
    ```java
    @ImportResource({"classpath:repo-config.xml", "classpath:legacy-security.xml"})
    ```
    
- **This pattern is almost exclusively a migration tool.** You'd use it when incrementally moving a legacy XML Spring app to annotations — not something you'd deliberately design into a new Spring Boot project. Worth knowing it exists so you're not confused seeing it in an older enterprise codebase.





[[Spring Framework]]