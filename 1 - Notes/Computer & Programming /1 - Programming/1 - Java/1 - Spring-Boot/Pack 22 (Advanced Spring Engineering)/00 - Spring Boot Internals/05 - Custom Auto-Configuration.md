
You now know _how_ Spring Boot discovers and filters its own auto-configuration classes. This is about building your own: packaging a reusable module that other projects can drop in as a dependency and get auto-wired behavior for free, the same way `spring-boot-starter-data-jpa` gives you a `DataSource` without you writing a `@Bean`.

## The two-module convention

Real Boot starters are split into two separate artifacts, and it's worth following this convention even for a small internal library:

- **`acme-spring-boot-autoconfigure`** — contains the actual `@AutoConfiguration` classes, conditions, and `@ConfigurationProperties` classes. No starter logic, just the real code.
- **`acme-spring-boot-starter`** — an almost-empty module whose only job is to declare dependencies: it depends on the autoconfigure module _and_ whatever libraries that auto-configuration needs (e.g., a Redis client jar). Consumers add just this one dependency.

The separation exists so other tools (or other starters) can depend on the autoconfigure module directly without pulling in the "convenience bundle" of transitive dependencies the starter represents. For a one-off internal module you can skip this and merge both into one jar, but it's the reason you'll see this split in every official starter if you go look.

## Writing the auto-configuration class

Structurally, this is nothing new on top of what you already know — a normal configuration class with conditions:

```java
@AutoConfiguration
@ConditionalOnClass(AcmeClient.class)
@EnableConfigurationProperties(AcmeProperties.class)
public class AcmeAutoConfiguration {

    @Bean
    @ConditionalOnMissingBean
    public AcmeClient acmeClient(AcmeProperties properties) {
        return new AcmeClient(properties.getApiUrl(), properties.getApiKey());
    }
}
```

```java
@ConfigurationProperties(prefix = "acme")
public class AcmeProperties {
    private String apiUrl = "https://api.acme.example.com"; // sensible default
    private String apiKey;
    // getters/setters
}
```

`@ConditionalOnClass(AcmeClient.class)` guards the whole thing on the client library actually being present — if a consumer somehow doesn't pull in the real client jar, this auto-configuration silently does nothing instead of failing. `@ConditionalOnMissingBean` is the backing-off behavior that makes your auto-configured bean overridable, exactly like Boot's own starters.

Notice `@AutoConfiguration` rather than `@Configuration` here — this is the annotation from your Conditional/internals lessons that marks it as `proxyBeanMethods = false` lite mode by default and plugs into Boot's ordering machinery (`@AutoConfigureAfter`/`@AutoConfigureBefore`), rather than a plain `@Configuration` that you're importing manually.

## The registration file — this is the part people forget

Writing the class isn't enough; nothing will discover it unless you register it. The file goes at an exact path, exact name, inside `src/main/resources`:

```
META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
```

Contents — one fully-qualified class name per line:

```
com.acme.autoconfigure.AcmeAutoConfiguration
```

This is the _same_ file format and location you saw `AutoConfigurationImportSelector` reading from in your auto-configuration internals lesson. There's no annotation-based alternative to this file — Boot's `DeferredImportSelector` literally scans the classpath for files at this exact path across every jar, so a missing or misnamed file means your class is just invisible, with no error raised.

(If you ever see an older tutorial use `META-INF/spring.factories` with a line like `org.springframework.boot.autoconfigure.EnableAutoConfiguration=com.acme.AcmeAutoConfiguration`, that's the pre-Boot-2.7 mechanism. Both still work in current Boot for backward compatibility, but the `.imports` file is the one to write for new code.)

## Controlling ordering relative to other auto-configurations

If your auto-configuration needs something another one provides — say, it needs a `DataSource` to already be configured — declare it explicitly rather than hoping for luck with registration order:

```java
@AutoConfiguration(after = DataSourceAutoConfiguration.class)
public class AcmeAutoConfiguration { ... }
```

## Giving IDE autocomplete for your properties

A nice-to-have, not required for functioning: adding the annotation processor

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-configuration-processor</artifactId>
    <optional>true</optional>
</dependency>
```

generates a `META-INF/spring-configuration-metadata.json` file at build time, describing every field in your `@ConfigurationProperties` class — its type, default value, and any `@Deprecated`/Javadoc-derived description. This is purely what powers IDE autocomplete and hover-docs when someone types `acme.api-url=` in their `application.properties` in IntelliJ or VS Code; it has zero effect on runtime behavior.

## Letting consumers exclude it

Nothing extra needed here — because you used `@AutoConfiguration`, your class is a normal citizen of Boot's exclusion mechanism automatically:

```java
@SpringBootApplication(exclude = AcmeAutoConfiguration.class)
```

or

```properties
spring.autoconfigure.exclude=com.acme.autoconfigure.AcmeAutoConfiguration
```

## Testing it without a real application

Boot provides `ApplicationContextRunner` specifically for unit-testing auto-configuration in isolation — spinning up a minimal context with only the conditions and beans you care about, without a full `SpringApplication.run()`:

```java
class AcmeAutoConfigurationTests {

    private final ApplicationContextRunner contextRunner =
        new ApplicationContextRunner()
            .withConfiguration(AutoConfigurations.of(AcmeAutoConfiguration.class));

    @Test
    void createsClientWhenPropertiesPresent() {
        contextRunner
            .withPropertyValues("acme.api-key=test-key")
            .run(context -> {
                assertThat(context).hasSingleBean(AcmeClient.class);
            });
    }

    @Test
    void backsOffWhenUserProvidesOwnBean() {
        contextRunner
            .withUserConfiguration(CustomAcmeConfig.class)
            .run(context -> {
                assertThat(context).hasSingleBean(AcmeClient.class);
                assertThat(context.getBean(AcmeClient.class))
                    .isSameAs(context.getBean(CustomAcmeConfig.class).customClient());
            });
    }
}
```

This is the standard way Boot's own test suite verifies every built-in auto-configuration — each condition path (class present/absent, property set/unset, bean already defined) gets its own test case against a throwaway context, rather than booting a full application for every scenario.

## Seeing your own class in the evaluation report

Once it's wired up and on a consumer's classpath, your class shows up in the same `--debug` `CONDITIONS EVALUATION REPORT` you've already used for diagnosing Boot's built-in auto-configurations — it's processed by the exact same selector, filtered by the exact same condition-evaluation machinery, with no special-casing for "official" versus "yours."



[[Spring Framework]]
