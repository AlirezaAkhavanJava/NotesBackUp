Auto-configuration is the mechanism that lets Spring Boot look at what's on your classpath, what beans you've already defined, and what properties you've set — then decide, on its own, which beans to register for you. It's the actual engine behind "convention over configuration": when you add `spring-boot-starter-data-jpa` and suddenly have a `DataSource`, an `EntityManagerFactory`, and a `JpaTransactionManager` without writing a single `@Bean` method, auto-configuration did that. You've already seen the _effect_ of this. What follows is how it actually works under the hood — the annotations, the files, and the decision process that makes it happen.

## Where it starts: `@SpringBootApplication`

Every Spring Boot app has this on its main class:

```java
@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

`@SpringBootApplication` is a meta-annotation — it's really three annotations stacked together:

```java
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan
public @interface SpringBootApplication { ... }
```

You already know `@ComponentScan` from earlier — it finds your `@Component`/`@Service`/`@Repository`/`@Controller` classes. `@SpringBootConfiguration` is just `@Configuration` with a Boot-specific marker so tooling can recognize "this is the entry point." The one we care about here is `@EnableAutoConfiguration`.

## `@EnableAutoConfiguration`: the real trigger

This annotation does one important thing: it imports a special class called `AutoConfigurationImportSelector`.

```java
@AutoConfigurationPackage
@Import(AutoConfigurationImportSelector.class)
public @interface EnableAutoConfiguration { ... }
```

`ImportSelector` is a Spring interface you haven't used directly, but it's simple in concept — instead of writing `@Import(SomeConfig.class)` with a fixed class, you write a class that _computes_ a list of class names to import at runtime:

```java
public interface ImportSelector {
    String[] selectImports(AnnotationMetadata importingClassMetadata);
}
```

`AutoConfigurationImportSelector` implements this. Its job is: figure out every auto-configuration class that _could_ apply, filter out the ones that shouldn't, and hand Spring the final list of class names to treat as `@Configuration` classes. This happens during the bean definition loading phase — before beans are actually instantiated, which lines up with what you learned about `BeanDefinitionRegistryPostProcessor` running early in the container lifecycle.

## Where the candidate list comes from

In modern Spring Boot (3.x, which pairs with your JDK 25 setup), the full list of candidate auto-configuration classes lives in a file on the classpath:

```
META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
```

It's just a plain text file, one fully-qualified class name per line:

```
org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration
org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration
org.springframework.boot.autoconfigure.web.servlet.DispatcherServletAutoConfiguration
...
```

(Older Spring Boot 2.x used `META-INF/spring.factories` with a `EnableAutoConfiguration=...` key instead — same idea, different file format. If you ever open a library's jar and don't see the `.imports` file, check for `spring.factories`.)

Every starter jar you depend on ships its own copy of this file, contributing its own candidate classes. `AutoConfigurationImportSelector` reads _all_ of them from every jar on the classpath and merges them into one big candidate list — often 100+ entries, almost none of which will actually activate in a given app.

## Filtering: `@Conditional` annotations

This is the actual "intelligence" of auto-configuration. Each class in that file is a normal `@Configuration` class, but annotated with conditions that decide whether it should even be considered. These are all variants of Spring's base `@Conditional` annotation, specialized for Boot's common cases:

```java
@Configuration
@ConditionalOnClass(DataSource.class)
@ConditionalOnMissingBean(DataSource.class)
@EnableConfigurationProperties(DataSourceProperties.class)
public class DataSourceAutoConfiguration {

    @Bean
    @ConditionalOnProperty(prefix = "spring.datasource", name = "url")
    public DataSource dataSource(DataSourceProperties properties) {
        return properties.initializeDataSourceBuilder().build();
    }
}
```

The conditions you'll run into most:

- **`@ConditionalOnClass`** — only activate if a given class is on the classpath. This is how adding `spring-boot-starter-data-jpa` as a Maven/Gradle dependency "turns on" JPA auto-configuration: the class becomes loadable, the condition passes.
- **`@ConditionalOnMissingBean`** — only activate if _you_ haven't already defined a bean of that type yourself. This is the escape hatch: define your own `DataSource` `@Bean`, and Boot's auto-configured one backs off entirely. This is why "it just works but you can still override it" is true.
- **`@ConditionalOnBean`** — the opposite: only activate if some other bean already exists (used for auto-configs that depend on another auto-config having run).
- **`@ConditionalOnProperty`** — only activate based on a property value in `application.properties`/`.yml`. This is how flags like `spring.datasource.url` gate whether a bean method even runs.
- **`@ConditionalOnWebApplication`** / **`@ConditionalOnNotWebApplication`** — checks whether the app is a servlet app, reactive app, or neither.
- **`@ConditionalOnResource`**, **`@ConditionalOnExpression`** — less common, check for a file on the classpath or evaluate a SpEL expression.

All of these ultimately implement the lower-level `Condition` interface:

```java
public interface Condition {
    boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata);
}
```

`ConditionContext` gives the condition access to the `BeanFactory`, the `Environment` (your properties), the `ClassLoader`, and resource loading — everything it needs to decide. `@ConditionalOnClass` is really just a `Condition` implementation that tries `classLoader.loadClass(...)` and catches `ClassNotFoundException`.

## Ordering matters

Some auto-configurations depend on others running first — JPA auto-configuration needs a `DataSource` to already exist, for example. Rather than relying on accidental ordering, Boot makes it explicit:

```java
@AutoConfiguration(after = DataSourceAutoConfiguration.class)
public class HibernateJpaAutoConfiguration { ... }
```

`@AutoConfigureBefore` and `@AutoConfigureAfter` pin relative order; `@AutoConfigureOrder` sets a numeric priority when there's no specific dependency, just a "this should generally run early/late" preference. (Note: in current Boot versions, auto-configuration classes are annotated `@AutoConfiguration` rather than plain `@Configuration` — it's a specialized meta-annotation that includes sensible defaults like `proxyBeanMethods = false`, since auto-config classes rarely need CGLIB proxying between their own `@Bean` methods.)

## Putting the whole flow together

1. `SpringApplication.run()` starts the container.
2. Component scanning finds your `@Configuration`/`@Component` classes, as usual.
3. `@EnableAutoConfiguration` triggers `AutoConfigurationImportSelector`.
4. The selector reads every `AutoConfiguration.imports` file on the classpath and builds one merged candidate list.
5. Each candidate class is checked against its `@Conditional*` annotations — classpath checks, existing-bean checks, property checks.
6. Survivors get ordered (`@AutoConfigureBefore`/`After`), and the ones not filtered out are registered as real `@Configuration` classes, same as if you'd written `@Import(...)` yourself.
7. From there, they're processed exactly like any other configuration class — their `@Bean` methods run through the normal bean lifecycle you already know (`BeanFactoryPostProcessor` → bean creation → `BeanPostProcessor` → init callbacks).

The important mental model: **auto-configuration classes are not special beans with magic behavior.** They are ordinary `@Configuration` classes. The only "magic" is _how they get imported_ (via `ImportSelector` reading files at startup) and _whether they're allowed to apply_ (via conditions). Once a condition passes and the class is imported, everything downstream is the same bean machinery you already understand.

## Seeing it for yourself

Boot can print exactly which auto-configurations were applied and which were skipped, and why. Run your app with:

```
java -jar app.jar --debug
```

or set `debug=true` in `application.properties`. At startup you'll get a `CONDITIONS EVALUATION REPORT` with two sections — "Positive matches" (activated, with the reason) and "Negative matches" (rejected, with the specific condition that failed). This is the single best tool for understanding _why_ a bean you expected isn't there, or why one you didn't expect showed up.

## Excluding an auto-configuration

Sometimes a condition would pass but you don't want that behavior — say, you have `DataSource` on the classpath for testing but don't want a real connection pool configured. You exclude it explicitly:

```java
@SpringBootApplication(exclude = DataSourceAutoConfiguration.class)
```

or by property, which is useful when you can't edit the annotation (e.g. per-profile):

```properties
spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration
```

This bypasses the conditions entirely — the class is removed from the candidate list before condition evaluation even happens.


[[Spring Framework]]
