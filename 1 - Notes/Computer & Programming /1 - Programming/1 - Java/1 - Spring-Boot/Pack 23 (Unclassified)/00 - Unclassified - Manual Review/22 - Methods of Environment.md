

Every real application behaves differently depending on where it runs. A database URL on your laptop is not the one in production, a payment gateway might be mocked in tests but live for customers, and a feature flag might be on in staging and off everywhere else. Spring's `Environment` is the single object that holds that context. It does two jobs: it knows which **profiles** are active (dev, test, prod, and so on), and it can look up any **property** from every configuration source the app knows about.

In this tutorial we'll start from the pain it solves, then walk through the profile side, the property side, the programmatic side, and finally when you should and shouldn't touch it directly.

---

## 1. The problem: configuration is scattered

Without something like `Environment`, a typical app would read configuration from many places:

- `System.getenv("DB_URL")` for environment variables
- `System.getProperty("app.mode")` for JVM `-D` flags
- a `.properties` or `.yml` file loaded by hand
- command-line arguments

Each source has its own API, its own naming quirks, and its own idea of "missing". Worse, you'd have to decide yourself which one wins when the same key appears in two places.

Spring's answer is to put all of those sources behind **one lookup API** (`PropertyResolver`) and **one precedence list** (`PropertySource`s, ordered). You ask for `app.mode`, and Spring checks sources in order until one has it.

## 2. The family tree (related concepts)

```
PropertyResolver          <- "give me a property" (getProperty, placeholders...)
      ^
Environment               <- adds profiles (getActiveProfiles, acceptsProfiles...)
      ^
ConfigurableEnvironment   <- adds mutation (setActiveProfiles, getPropertySources...)
```

A mental shortcut: `PropertyResolver` is the read-only lookup, `Environment` is that plus "which profiles am I in?", and `ConfigurableEnvironment` is the editable version. You inject `Environment` in your code, but the object Spring actually creates is a `ConfigurableEnvironment` (in Boot web apps, typically `StandardServletEnvironment` or `StandardEnvironment`).

## 3. The profile side

A **profile** is a named switch for groups of beans and config, like `dev`, `prod`, or `cloud`. They solve the "same code, different wiring" problem.

```java
@Configuration
@Profile("dev")
class DevMailConfig {
    @Bean MailSender mailSender() { return new LoggingMailSender(); }
}

@Configuration
@Profile("prod")
class ProdMailConfig {
    @Bean MailSender mailSender() { return new SmtpMailSender(); }
}
```

The `Environment` is where you query which profiles are on:

|Method|What it tells you|
|---|---|
|`getActiveProfiles()`|Profiles explicitly activated (e.g. via `spring.profiles.active=prod`)|
|`getDefaultProfiles()`|The fallback set used only when _no_ profile is active. By default this is `["default"]`|
|`acceptsProfiles(...)`|"Is this profile (or expression) satisfied right now?"|

```java
@Autowired Environment env;

void demo() {
    String[] active = env.getActiveProfiles();     // ["prod"]
    boolean notProd = env.acceptsProfiles(Profiles.of("!prod"));
    boolean combo = env.acceptsProfiles(Profiles.of("cloud & !test"));
}
```

**Heads-up:** the older `acceptsProfiles(String...)` overload (the one in your notes) is deprecated since Spring 5.1. Prefer `acceptsProfiles(Profiles.of(...))`, which supports expressions with `&`, `|`, `!` and parentheses.

## 4. The property side

This is the "inherited from `PropertyResolver`" half, and it's what you'll use most. Think of the methods as variations on one question: _"What's the value of this key, and what should happen if it isn't there?"_

|If the key is missing, you want...|Use|
|---|---|
|`null`|`getProperty(key)`|
|a fallback value|`getProperty(key, defaultValue)`|
|a failure (fail fast!)|`getRequiredProperty(key)` which throws `IllegalStateException`|
|just a yes/no|`containsProperty(key)`|

Each lookup also has a typed version, so Spring does the conversion for you:

```java
int timeout = env.getProperty("http.timeout", Integer.class, 5000);
String apiKey = env.getRequiredProperty("payments.api-key"); // app can't run without it
```

Using `getRequiredProperty` for things like secrets and URLs is a nice habit. A missing value then blows up at startup instead of causing a mysterious `NullPointerException` at 3 a.m.

### Placeholders

Two more methods deal with `${...}` placeholders inside strings:

```java
String msg = env.resolvePlaceholders("Hello from ${app.name}");
String strict = env.resolveRequiredPlaceholders("Hello from ${app.name}");
```

The difference is the same "missing key" story. The plain version leaves unresolvable placeholders as-is, while the _required_ version throws.

## 5. Where do the values come from? `PropertySource`

Behind the scenes, the environment holds an **ordered list of property sources**. When you call `getProperty`, it walks the list top to bottom and returns the first hit. That ordering is how overriding works.

A simplified view of Spring Boot's precedence, highest first:

1. Command-line arguments (`--server.port=9000`)
2. JVM system properties (`-Dserver.port=9000`)
3. OS environment variables (`SERVER_PORT=9000`)
4. Profile-specific files (`application-prod.yml`)
5. `application.yml` / `application.properties`
6. `@PropertySource` files and defaults

So an environment variable beats your YAML file, which is exactly what makes containers and cloud deployments easy: you ship one image and override config from the outside.

## 6. The programmatic side: `ConfigurableEnvironment`

Sometimes you need to _change_ the environment, usually very early in startup. That's what the configurable sub-interface is for:

|Method|Use it to...|
|---|---|
|`setActiveProfiles(...)`|Replace the active profiles (no args clears them)|
|`addActiveProfile(...)`|Add one without losing the others|
|`setDefaultProfiles(...)`|Change the fallback profile set|
|`getPropertySources()`|Add, remove or reorder sources|
|`getSystemEnvironment()` / `getSystemProperties()`|Get `System.getenv()` / `System.getProperties()` as maps|
|`merge(parent)`|Pull a parent context's profiles and sources into a child|

```java
ConfigurableEnvironment cenv = (ConfigurableEnvironment) env;
cenv.getPropertySources().addFirst(
    new MapPropertySource("overrides", Map.of("feature.x", "true")));
```

`addFirst` puts your source at the top of the precedence list, so it wins over everything else. Be careful with this: the timing matters, because beans that have already read a property won't see a later change. That's why this kind of tweak belongs in an `EnvironmentPostProcessor` or `ApplicationContextInitializer`, not in a random `@PostConstruct` (the doc you pasted mentions `@PostConstruct`, but it only works if nothing has consumed the value yet).

## 7. When to use `Environment` directly (and when not to)

For everyday property reading, higher-level tools are nicer:

- **`@Value("${app.name}")`** is good for one or two simple values.
- **`@ConfigurationProperties(prefix = "app")`** is the best choice for groups of related settings. It is type-safe, validated, and supports Boot's relaxed binding (`app.max-retries` ↔ `APP_MAXRETRIES`).

Reach for `Environment` itself when:

- the property key is computed at runtime (`env.getProperty("tenant." + id + ".url")`),
- you need to branch on profiles in code,
- you're writing infrastructure code that adds or reorders property sources.

## Quick recap

- `Environment` = **profiles + property lookup** in one place.
- It extends `PropertyResolver` (reading) and is implemented by `ConfigurableEnvironment` (modifying).
- Property sources are an **ordered list**, so higher ones override lower ones.
- Use `getRequiredProperty` to fail fast, and prefer `Profiles.of(...)` over the deprecated string overload.
- For normal config, prefer `@ConfigurationProperties`, and keep `Environment` for dynamic or startup-time work.

---
## 8. Hands-on: loading config from a custom source with an `EnvironmentPostProcessor`

So far we've only _read_ the environment. Now we'll _extend_ it. Imagine your ops team drops a plain file at `/etc/myapp/overrides.properties` on each server, holding values that shouldn't live in your JAR (a secret, a tenant-specific URL). Spring Boot doesn't know about that file, so we'll teach it.

The tool for this is `EnvironmentPostProcessor`. Spring Boot calls it **after the `Environment` is created but before the application context (and any beans) exist**. That timing is the whole point. Nothing has read a property yet, so anything you add is visible to every bean, `@Value`, and `@ConfigurationProperties` class.

### Step 1: write the post-processor

```java
package com.example.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.Ordered;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.PropertiesPropertySource;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PropertiesLoaderUtils;

import java.io.IOException;
import java.util.Properties;

public class ExternalOverridesPostProcessor implements EnvironmentPostProcessor, Ordered {

    private static final String SOURCE_NAME = "externalOverrides";
    private static final String DEFAULT_PATH = "/etc/myapp/overrides.properties";

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment,
                                       SpringApplication application) {

        // Let the path itself be configurable, with a sensible default
        String path = environment.getProperty("myapp.overrides.path", DEFAULT_PATH);
        Resource resource = new FileSystemResource(path);

        if (!resource.exists()) {
            // Optional file: no file, no problem
            return;
        }

        try {
            Properties props = PropertiesLoaderUtils.loadProperties(resource);

            // Place it just AFTER system env vars, so env vars and -D flags still win
            environment.getPropertySources().addAfter(
                    StandardEnvironment.SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME,
                    new PropertiesPropertySource(SOURCE_NAME, props));

        } catch (IOException e) {
            throw new IllegalStateException("Could not read overrides file: " + path, e);
        }
    }

    @Override
    public int getOrder() {
        // Run late enough that application.yml has already been loaded,
        // so myapp.overrides.path can be set there if you want
        return Ordered.LOWEST_PRECEDENCE;
    }
}
```

A few things worth noticing:

- **We use `getProperty` with a default** to find the file path. That's the `Environment` API from sections 3 to 4, now used for real.
- **`addAfter(...)` instead of `addFirst(...)`.** In section 6 we used `addFirst`, which beats everything. Here we chose a middle position on purpose: operators can still override our file with a plain environment variable or a command-line flag. Picking the right spot in the list is the main design decision when adding a source.
- **A missing file is silently skipped, but an unreadable one fails fast.** That mirrors the `getProperty` vs `getRequiredProperty` distinction.

### Step 2: register it

Spring Boot discovers post-processors through `spring.factories`. Create this file:

`src/main/resources/META-INF/spring.factories`

```
org.springframework.boot.env.EnvironmentPostProcessor=\
com.example.config.ExternalOverridesPostProcessor
```

Without this registration, Boot never finds your class. It is not picked up by component scanning, because there is no application context yet. This is the number one reason people say "my post-processor doesn't run".

### Step 3: try it

Create the file:

`/etc/myapp/overrides.properties`

```properties
payments.api-key=sk_live_from_the_overrides_file
feature.x=true
```

And a class that uses the values like any other property:

```java
@Component
class StartupReport implements CommandLineRunner {

    private final Environment env;

    StartupReport(Environment env) {
        this.env = env;
    }

    @Override
    public void run(String... args) {
        System.out.println("feature.x    = " + env.getProperty("feature.x"));
        System.out.println("api key set? = " + env.containsProperty("payments.api-key"));
    }
}
```

Run it normally and you'll see `feature.x = true`. Now run it again with `FEATURE_X=false` set as an OS environment variable. Because we placed our source _after_ `systemEnvironment`, the env var wins and you'll see `false`. That's the precedence list from section 5 working in front of you.

### Gotchas to keep in mind

- **Logging isn't ready yet.** The logging system initializes _after_ environment post-processors run, so a normal `Logger` may print nothing. For debugging, use `System.out` temporarily, or accept a `DeferredLogFactory` in the constructor (supported by Boot) to log properly once logging starts.
- **Don't inject beans.** There's no context yet, so no `@Autowired`. Everything you need must come from the `Environment` or the filesystem.
- **Mind the order.** `Ordered.LOWEST_PRECEDENCE` means "run last", after Boot's own config-file loading. If you want your source to be able to influence _which_ config files get loaded, you'd need an earlier order instead.
- **Secrets caveat.** For real production secrets, a dedicated mechanism (Kubernetes secrets, Vault, Spring Cloud Config, or Boot's `spring.config.import`) is usually better than a hand-rolled file. Actually, `spring.config.import=optional:file:/etc/myapp/overrides.properties` does exactly what our example does with zero code. Writing the post-processor is still valuable for learning, and for cases where you need custom logic, like decrypting values or calling an internal service.

### Recap of the example

1. Implement `EnvironmentPostProcessor` and add a `PropertySource` to the `ConfigurableEnvironment`.
2. Choose its **position** deliberately (`addFirst`, `addBefore`, `addAfter`, `addLast`), because position is precedence.
3. Register it in `META-INF/spring.factories`.
4. Everything downstream (`@Value`, `@ConfigurationProperties`, plain `env.getProperty`) sees the new values automatically.




[[Spring Framework]]