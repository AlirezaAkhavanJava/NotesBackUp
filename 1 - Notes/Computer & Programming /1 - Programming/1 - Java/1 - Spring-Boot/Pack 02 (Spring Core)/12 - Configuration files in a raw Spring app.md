

**The files can exist, but the names `application.properties` and `application.yml` mean nothing to plain Spring.** Spring Framework itself has no idea those names are special. It's Spring Boot that looks for them automatically at startup. Without Boot, you pick a file (any name you like), and you tell Spring explicitly to load it.

Underneath, Spring has a small, general system for configuration values: the `Environment` and its `PropertySource`s. Boot builds its convenient "just drop a file in `resources`" behavior on top of that system. Once you understand the underlying system, the raw Spring approach is simple, and you also understand what Boot was doing for you.

## How Spring sees configuration

Spring keeps all configuration values in one object called the **`Environment`**. The `Environment` holds an ordered list of **`PropertySource`s**. Each one is a bag of key/value pairs from somewhere. When you ask for `db.url`, Spring checks the sources in order and returns the first match.

|Source|Where it comes from|Loaded by default?|
|---|---|---|
|System properties|`-Ddb.url=...` on the JVM command line|Yes|
|OS environment variables|`DB_URL` etc.|Yes|
|Your `.properties` file|A file you register|**No, you must register it**|

So "telling Spring to use the file" really means "add my file as another `PropertySource`." Because system properties and environment variables are checked first, they can override your file. That's handy for production.

## Step 1: Create the file

Put it in `src/main/resources` so it lands on the classpath:

```properties
# src/main/resources/application.properties
db.url=jdbc:postgresql://localhost:5432/shop
db.username=postgres
db.pool.size=20
```

Call it `application.properties` if you like the habit, or `app.properties`, or `config.properties`. Spring doesn't care.

## Step 2: Register it with `@PropertySource`

```java
@Configuration
@ComponentScan("com.example")
@PropertySource("classpath:application.properties")
public class AppConfig {
}
```

Line by line:

- `@Configuration` marks the class as Java config.
- `@ComponentScan` finds your beans, as usual.
- `@PropertySource("classpath:application.properties")` says: "Read this file and add its keys to the `Environment`." The `classpath:` prefix means "look inside the application's resources." You can also use `file:/etc/myapp/app.properties` for an absolute path on disk.

## Step 3: Read the values

There are two ways. Both read from the same `Environment`.

**Option A: `@Value`**

```java
@Component
public class DbSettings {

    @Value("${db.url}")
    private String url;

    @Value("${db.pool.size:10}")
    private int poolSize;
}
```

- `${db.url}` is a placeholder. Spring replaces it with the value from the `Environment`.
- `:10` after the key is a **default**. If `db.pool.size` isn't found, Spring uses `10`.
- Spring converts the text `"20"` to an `int` for you.

**Option B: inject `Environment` directly**

```java
@Component
public class DbSettings {

    private final Environment env;

    public DbSettings(Environment env) {
        this.env = env;
    }

    public void print() {
        String url = env.getProperty("db.url");
        int size = env.getProperty("db.pool.size", Integer.class, 10);
    }
}
```

`getProperty("key")` returns `null` if the key is missing. `getRequiredProperty("key")` throws an exception instead, which is better for settings your app can't live without.

> A note on `@Value` and a placeholder bean: since Spring 4.3, `@Value("${...}")` works with `@PropertySource` on its own. Older tutorials declare a `static` bean of type `PropertySourcesPlaceholderConfigurer`. You still see it in many codebases and it gives extra control, but a simple setup doesn't need it.

## Loading more than one file

```java
@PropertySource({
    "classpath:application.properties",
    "classpath:db.properties"
})
```

If the same key appears in two files, the **later one wins**. That gives you an easy override trick:

```java
@PropertySource(
    value = {
        "classpath:application.properties",
        "file:/etc/myapp/override.properties"
    },
    ignoreResourceNotFound = true
)
```

With `ignoreResourceNotFound = true`, the override file is optional. If it's missing, Spring skips it instead of crashing at startup.

## Imitating profiles

Boot gives you `application-dev.properties` automatically. In raw Spring, you can get a similar effect because the path itself can contain placeholders:

```java
@PropertySource("classpath:application-${spring.profiles.active:dev}.properties")
```

Start the app with `-Dspring.profiles.active=prod` and Spring loads `application-prod.properties`. If you don't pass anything, it falls back to `dev`. Spring resolves the placeholder from system properties and environment variables at that moment.

## What about YAML?

This is the catch. **`@PropertySource` only understands `.properties` files.** It has no built-in YAML support. If you point it at an `application.yml`, it will try to read it as properties and give you garbage.

To use YAML in raw Spring, you need two things:

1. The SnakeYAML library on your classpath (Boot brings it for you; here you add it yourself).
2. A small custom factory that tells Spring how to read YAML:

```java
public class YamlPropertySourceFactory implements PropertySourceFactory {

    @Override
    public PropertySource<?> createPropertySource(String name, EncodedResource resource)
            throws IOException {
        YamlPropertiesFactoryBean factory = new YamlPropertiesFactoryBean();
        factory.setResources(resource.getResource());
        Properties props = factory.getObject();
        return new PropertiesPropertySource(
                resource.getResource().getFilename(), props);
    }
}
```

Then use it:

```java
@PropertySource(value = "classpath:application.yml",
                factory = YamlPropertySourceFactory.class)
```

What this does:

- `YamlPropertiesFactoryBean` reads the YAML and **flattens** it into dotted keys.
- So this YAML:

```yaml
db:
  url: jdbc:postgresql://localhost:5432/shop
  pool:
    size: 20
```

becomes the same keys as before: `db.url` and `db.pool.size`. After that, `@Value("${db.pool.size}")` works exactly the same way.

Lists become indexed keys, like `servers[0]` and `servers[1]`.

Honest advice: if you're not using Boot, `.properties` is the path of least resistance. Use YAML only if you really want it.

## The XML way (older projects)

If you meet an older project with XML config, the same idea looks like this:

```xml
<context:property-placeholder location="classpath:application.properties"/>
```

Same result: the file is added to the `Environment`, and `${...}` placeholders work.

## What Boot did for you

|Task|Raw Spring|Spring Boot|
|---|---|---|
|Find the file|You name it and register it with `@PropertySource`|Automatically looks for `application.properties` / `.yml`|
|YAML support|Add SnakeYAML plus a custom factory|Built in|
|Profile files|Placeholder trick in the path|`application-{profile}.properties` automatic|
|Override from outside|You add another `file:` source|Several default locations checked for you|
|Typed binding|Not available|`@ConfigurationProperties`|

## Related concept: `@ConfigurationProperties`

In Boot you can bind a whole group of keys (like everything under `db.`) into one typed class. That feature belongs to Boot, not to core Spring. In raw Spring you either use many `@Value` fields, or read from `Environment` yourself. Some people write a small settings class to keep the `@Value` lines in one place.

## Common mistakes

- **Expecting auto-loading.** If you forget `@PropertySource`, nothing loads and `${db.url}` fails with an "Could not resolve placeholder" error.
- **File not on the classpath.** In Maven, the file must be under `src/main/resources`, not `src/main/java`.
- **Pointing `@PropertySource` at YAML** without the custom factory.
- **Forgetting defaults.** Use `${key:default}` for optional settings.

## Recap

Raw Spring has no special filename. You choose a file, register it with `@PropertySource` (or `<context:property-placeholder>` in XML), and then read values with `@Value` or `Environment`. `.properties` works out of the box; YAML needs SnakeYAML and a custom factory. Boot's `application.properties` magic is just a convenient layer over this same `Environment` system.


[[Spring Framework]]