
---
## `@Import` Annotation in Spring Boot

The `@Import` annotation is a core Spring Framework annotation (from `org.springframework.context.annotation`) that allows you to **import additional configuration classes, `@Configuration` classes, or regular component classes into a Spring application context** — without them being picked up by component scanning.

It's especially useful in Spring Boot when you want explicit, controlled inclusion of beans.

---

### Basic Syntax

```java
@Import({MyConfig.class, AnotherConfig.class})
@Configuration
public class AppConfig {
}
```

---

### What Can You Import?

`@Import` accepts three types of classes:

#### 1. `@Configuration` classes
Imports all beans defined in that config class.

```java
@Configuration
public class DatabaseConfig {
    @Bean
    public DataSource dataSource() { ... }
}

@Import(DatabaseConfig.class)
@Configuration
public class AppConfig { }
```

#### 2. Regular component classes (since Spring 4.2)
Any plain class can be imported and registered as a bean.

```java
public class MyService { }

@Import(MyService.class)
@Configuration
public class AppConfig { }
// MyService is now a bean
```

#### 3. `ImportSelector` implementations
Programmatically decide which classes to import at runtime.

```java
public class MySelector implements ImportSelector {
    @Override
    public String[] selectImports(AnnotationMetadata meta) {
        return new String[] { "com.example.FooConfig", "com.example.BarConfig" };
    }
}

@Import(MySelector.class)
@Configuration
public class AppConfig { }
```

#### 4. `ImportBeanDefinitionRegistrar` implementations
Manually register bean definitions with full control.

```java
public class MyRegistrar implements ImportBeanDefinitionRegistrar {
    @Override
    public void registerBeanDefinitions(AnnotationMetadata meta, BeanDefinitionRegistry registry) {
        // register beans programmatically
    }
}

@Import(MyRegistrar.class)
@Configuration
public class AppConfig { }
```

---

### How It Works Internally

- `@Import` is processed by `ConfigurationClassPostProcessor`.
- Imported classes are treated as additional configuration classes (for `@Configuration`) or as bean definitions.
- Unlike `@ComponentScan`, `@Import` does **not** scan packages — it's explicit and precise.
- Imported classes do **not** need `@Component`/`@Configuration` (unless they define beans via `@Bean`, in which case `@Configuration` is required).

---

### Common Use Cases in Spring Boot

| Use Case | Example |
|---|---|
| Modularizing configs | Import a shared `SecurityConfig` from a library |
| Enabling features | Spring Boot's `@EnableAutoConfiguration` uses `@Import(AutoConfigurationImportSelector.class)` |
| Writing custom `@Enable*` annotations | `@EnableCaching` → `@Import(CachingConfigurationSelector.class)` |
| Conditional bean loading | Combined with `@Conditional` |

---

### `@Import` vs Related Annotations

| Annotation | Purpose |
|---|---|
| `@Import` | Explicitly include specific classes |
| `@ComponentScan` | Scan packages for annotated components |
| `@ImportResource` | Import XML-based bean definitions |
| `@EnableAutoConfiguration` | Auto-import based on classpath (uses `@Import` internally) |

---

### Example: Custom `@Enable` Annotation

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
@Import(MyFeatureConfiguration.class)
public @interface EnableMyFeature { }

// Usage
@EnableMyFeature
@SpringBootApplication
public class Application { }
```

This is the idiomatic way Spring Boot exposes optional features — a meta-annotation wrapping `@Import`.

---

### Key Takeaways

- `@Import` gives **explicit control** over which classes become part of the Spring context.
- It bypasses component scanning, making it ideal for libraries and modular configs.
- It underpins Spring Boot's entire auto-configuration mechanism.
- Prefer it over `@ComponentScan` when you need precision and don't want unintended beans picked up.

[[Java]]
[[0 - Spring Framework]]
