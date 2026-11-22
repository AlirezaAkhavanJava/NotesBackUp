Last time you saw `@Conditional` annotations as the filtering mechanism _inside_ auto-configuration. This time let's treat `@Conditional` as its own general-purpose feature: something you can use in your own `@Configuration` classes, not just something Boot uses internally. It's actually a plain Spring Framework feature (not Boot-specific) — Boot just built a large library of ready-made conditions on top of it.

## The core interface

Everything traces back to one interface:

```java
public interface Condition {
    boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata);
}
```

`@Conditional` itself takes an array of `Condition` classes:

```java
@Conditional(OnJavaVersionCondition.class)
@Bean
public SomeBean someBean() { ... }
```

If `matches()` returns `true`, the bean/configuration is registered. If `false`, it's skipped entirely — not created, not even attempted. The two parameters tell you everything the condition is allowed to look at:

- **`ConditionContext`** — gives access to the `BeanDefinitionRegistry` (what beans are already defined), the `ConfigurableListableBeanFactory`, the `Environment` (properties, active profiles), the `ResourceLoader`, and the `ClassLoader`.
- **`AnnotatedTypeMetadata`** — metadata about the annotated class or method itself (its other annotations, its attributes) — this is how a condition can read the _values_ passed to the annotation, like a property name string.

## Writing your own condition

Say you want a bean that only registers when a specific environment variable is set — something Boot doesn't ship a built-in annotation for:

```java
public class OnEnvVarCondition implements Condition {
    @Override
    public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
        return System.getenv("FEATURE_X_ENABLED") != null;
    }

    private static final String envVarName; // simplified
}
```

```java
@Configuration
@Conditional(OnEnvVarCondition.class)
public class FeatureXConfig {
    @Bean
    public FeatureXService featureXService() {
        return new FeatureXService();
    }
}
```

To make it reusable and configurable — passing in _which_ env var name to check, rather than hardcoding it — you combine `@Conditional` with a custom annotation and read the attribute via `metadata`:

```java
@Retention(RetentionPolicy.RUNTIME)
@Conditional(OnEnvVarCondition.class)
public @interface ConditionalOnEnvVar {
    String name();
}
```

```java
public class OnEnvVarCondition implements Condition {
    @Override
    public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
        Map<String, Object> attrs = metadata.getAnnotationAttributes(ConditionalOnEnvVar.class.getName());
        String varName = (String) attrs.get("name");
        return System.getenv(varName) != null;
    }
}
```

```java
@Bean
@ConditionalOnEnvVar(name = "FEATURE_X_ENABLED")
public FeatureXService featureXService() { ... }
```

This is exactly the pattern Boot itself uses to build `@ConditionalOnProperty`, `@ConditionalOnClass`, etc. — a custom annotation meta-annotated with `@Conditional(SomeConditionImpl.class)`, where the condition implementation reads the annotation's own attributes to know what to check.

## `ConfigurationCondition`: when does the check run?

There's a subtlety plain `Condition` doesn't handle: configuration classes get processed in two separate phases — first all `@Configuration` classes are _parsed_ (registered as bean definitions), then beans are actually _created_. Some conditions need to know which phase they're being evaluated in. For that, there's a stricter interface:

```java
public interface ConfigurationCondition extends Condition {
    ConfigurationPhase getConfigurationPhase();

    enum ConfigurationPhase {
        PARSE_CONFIGURATION,
        REGISTER_BEAN
    }
}
```

- `PARSE_CONFIGURATION` — evaluated while configuration classes themselves are being parsed. Use this when the condition should prevent the _entire configuration class_ from being considered at all (this is what `@ConditionalOnClass` uses — if the class isn't even loadable, there's no point parsing further).
- `REGISTER_BEAN` — evaluated later, when individual `@Bean` methods are about to be turned into bean definitions. Use this when other beans need to already exist for the check to make sense (this is what `@ConditionalOnBean` uses — it needs other bean definitions to already be registered to check against them).

Getting this wrong is a classic gotcha: if you write `@ConditionalOnBean` logic but evaluate it at `PARSE_CONFIGURATION` phase, the bean you're checking for might not have been registered yet, and your condition will wrongly say "missing" even when it isn't.

## Stacking multiple conditions

You can put more than one condition on the same element:

```java
@Bean
@ConditionalOnClass(RedisConnectionFactory.class)
@ConditionalOnMissingBean
@ConditionalOnProperty(prefix = "app.cache", name = "provider", havingValue = "redis")
public CacheManager redisCacheManager() { ... }
```

All conditions on one element are combined with **AND** — every single one must pass. There's no built-in OR; if you need "either condition A or condition B," you write a composite `Condition` yourself that checks both and returns true if either matches, then apply that single composite with `@Conditional`.

## `@ConditionalOnExpression`: SpEL escape hatch

When the built-in conditions don't cover your logic, you can drop into a Spring Expression Language string:

```java
@Bean
@ConditionalOnExpression("${app.feature.enabled:false} and '${app.env}'.equals('production')")
public FeatureService featureService() { ... }
```

This is flexible but easy to overuse — it trades compile-time safety and readability for one-line convenience. Reach for it only when combining multiple property conditions in ways `@ConditionalOnProperty` can't express; for anything more complex than a short boolean expression, write a real `Condition` class instead.

## Less common but worth knowing

- **`@ConditionalOnResource`** — checks for the presence of a classpath resource (e.g. a config file packaged in a jar).
- **`@ConditionalOnSingleCandidate`** — like `@ConditionalOnBean`, but only matches if there's exactly one bean of that type, or one marked `@Primary` among several.
- **`@ConditionalOnWarDeployment`** — checks whether the app is running as a deployed WAR versus an embedded container, relevant to the Tomcat/deployment topics you've covered.
- **`@ConditionalOnJava`** — checks the running JVM version meets a minimum, useful for libraries supporting a range of Java versions.

## Why `@ConditionalOnClass` needs special handling

One performance detail worth knowing: when a hundred-plus candidate auto-configuration classes are checked at startup, naively loading every referenced class with `Class.forName()` just to test `@ConditionalOnClass` would be slow and could trigger class-loading side effects you don't want. Boot's actual implementation (`OnClassCondition`) avoids this by inspecting class metadata via ASM bytecode parsing instead of full class loading wherever possible — checking whether a class _exists_ on the classpath without actually loading and initializing it. You won't write this yourself, but it explains why Boot's startup, despite checking so many conditions, doesn't pay the full cost of loading every candidate class.

## Debugging conditions

Same tool as before: `--debug` or `debug=true` gives you the `CONDITIONS EVALUATION REPORT`, listing every condition that ran, whether it matched, and the exact reason — e.g. "found class 'redis.clients.jedis.Jedis'" or "did not find property 'app.cache.provider'". Internally, every condition can report _why_ it matched or didn't via a `ConditionMessage` builder, which is what populates that human-readable report — a small detail, but it's the reason the report reads like a sentence instead of just true/false.


[[Spring Framework]]
