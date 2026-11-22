You already know what `@Configuration` and `@Bean` _do_ — this time let's go under the hood of _how_ a `@Configuration` class actually gets processed into bean definitions. This is the mechanism that makes `@Import`, nested configuration classes, and (tying into your Phase 7 from the startup lifecycle) the whole auto-configuration pipeline possible.

## The component responsible: `ConfigurationClassPostProcessor`

Every `@Configuration` class is processed by one specific bean: `ConfigurationClassPostProcessor`. It's a `BeanDefinitionRegistryPostProcessor` — a type you've already seen from your bean lifecycle lesson, which runs very early, _before_ regular bean instantiation, working directly against the `BeanDefinitionRegistry` rather than live beans.

Boot/Spring registers this processor automatically the moment it sees `@Configuration` anywhere (via `@ComponentScan` or an explicit `@Import`). Its job, in one sentence: take every class annotated `@Configuration` and turn each `@Bean` method inside it into a `BeanDefinition` — the blueprint object from your `BeanDefinition` lesson — without creating any actual bean instances yet.

## Two parsing modes: "full" vs "lite"

This is the part that surprises people. Not all `@Configuration` classes are treated the same way — there are two distinct modes:

**Full mode** — the default. A full-mode configuration class gets **CGLIB-subclassed** at runtime. Spring generates a dynamic subclass of your class and intercepts calls to its `@Bean` methods. This is what guarantees singleton behavior when one `@Bean` method calls another directly:

```java
@Configuration
public class AppConfig {

    @Bean
    public ServiceA serviceA() {
        return new ServiceA(serviceB()); // calling another @Bean method directly
    }

    @Bean
    public ServiceB serviceB() {
        return new ServiceB();
    }
}
```

Without interception, `serviceB()` would run as a plain Java method call and return a _brand new_ `ServiceB` every time something calls `serviceA()`. With CGLIB proxying, the generated subclass intercepts that call, checks the container first, and returns the existing singleton if one's already been created — so `serviceA()` and any other caller all get the _same_ `ServiceB` instance.

**Lite mode** — triggered by setting `proxyBeanMethods = false`:

```java
@Configuration(proxyBeanMethods = false)
public class AppConfig {
    @Bean
    public ServiceA serviceA() {
        return new ServiceA(new ServiceB()); // just a normal object creation now
    }
}
```

No CGLIB subclass is generated. Calling `serviceB()` from inside `serviceA()` is now a _plain method call_ — no interception, no singleton guarantee. In lite mode, inter-bean references should go through method parameters instead, letting Spring inject the already-created bean:

```java
@Bean
public ServiceA serviceA(ServiceB serviceB) { // Spring resolves this from the container
    return new ServiceA(serviceB);
}
```

Lite mode is faster to process (no bytecode generation) and is exactly what `@AutoConfiguration` classes use by default — which answers something from your auto-configuration lesson: that's _why_ Boot's own auto-configuration classes don't typically call each other's `@Bean` methods directly.

`@Component` classes that happen to also have `@Bean` methods (not annotated `@Configuration` at all) are _always_ treated as lite mode automatically — Spring never proxies a plain component.

## `ConfigurationClassParser`: how one class pulls in others

`ConfigurationClassPostProcessor` delegates the actual reading work to `ConfigurationClassParser`. For each `@Configuration` class it finds, the parser doesn't just read `@Bean` methods — it recursively processes everything else that can contribute bean definitions:

- **`@ComponentScan`** — triggers scanning of the specified packages, which can turn up _more_ `@Configuration` classes to feed back into this same parsing process.
- **`@Import`** — pulls in other classes. Three different things can be passed here, each handled differently:
    - A plain `@Configuration` class → parsed just like any other configuration class.
    - An `ImportSelector` implementation → its `selectImports()` method runs, and _its_ returned class names get parsed in turn. (This is exactly the mechanism `AutoConfigurationImportSelector` uses.)
    - An `ImportBeanDefinitionRegistrar` implementation → gets direct access to the `BeanDefinitionRegistry` to register bean definitions programmatically, bypassing the "write a class with `@Bean` methods" pattern entirely.
- **`@ImportResource`** — pulls in bean definitions from an XML config file, for interop with legacy XML-based Spring config.
- **`@PropertySource`** — registers an additional properties file into the `Environment`, which you've already covered.

All of this happens _before_ any bean is instantiated — the parser is purely building up the full set of `BeanDefinition`s, discovering new configuration classes to parse as it goes, like a graph traversal.

## `DeferredImportSelector`: why auto-configuration runs last

There's a special subtype of `ImportSelector` worth calling out: `DeferredImportSelector`. A regular `ImportSelector`'s imports get processed immediately, in the order encountered. A `DeferredImportSelector`'s imports get collected and processed only _after every other configuration class has been fully parsed_.

`AutoConfigurationImportSelector` implements `DeferredImportSelector`. This is deliberate: it guarantees that by the time auto-configuration's `@ConditionalOnMissingBean` checks run, every bean definition from your own `@Configuration` classes and component-scanned beans is _already registered_ — so "back off if the user already defined this bean" actually has something real to check against. If auto-configuration ran eagerly instead, it could evaluate `@ConditionalOnMissingBean` before your own bean definition existed and wrongly register a duplicate.

## Duplicate detection

If the same `@Configuration` class gets imported twice — once via `@ComponentScan` finding it directly, once via another class's `@Import` — the parser tracks already-processed classes by name and skips reprocessing. This is also why `@Import`ing the same configuration class from multiple places is safe rather than producing duplicate bean definitions.

## Putting it together with what you already know

Mapping this onto your Phase 7 (load bean definitions) from the startup lifecycle:

```
Phase 7: ApplicationPreparedEvent window
 ├─ ConfigurationClassPostProcessor runs (as a BeanDefinitionRegistryPostProcessor)
 ├─ ConfigurationClassParser processes @SpringBootApplication class
 │    ├─ @ComponentScan → finds your classes → may find more @Configuration classes → parsed recursively
 │    └─ @EnableAutoConfiguration → @Import(AutoConfigurationImportSelector)
 │         └─ DeferredImportSelector → queued, not processed yet
 ├─ all "normal" configuration classes fully parsed first
 └─ THEN deferred imports (auto-configuration) are resolved and @Conditional-checked
```

By the time this phase ends, every bean definition — yours, component-scanned, and auto-configured — exists in the registry, full or lite mode decided, ready for the actual instantiation step in `refresh()`.

[[Spring Framework]]
