
`@PropertySource` tells Spring **which external `.properties` (or `.xml`) file to load** into the `Environment`, so its keys become available for `@Value` and `Environment.getProperty(...)` to resolve. It's mainly used for **custom, non-default property files** — Spring Boot already auto-loads `application.properties`/`.yml` for you without it.

## Basic usage

```java
@Configuration
@PropertySource("classpath:custom.properties")
public class AppConfig {

    @Value("${custom.key}")
    private String customValue;
}
```

`src/main/resources/custom.properties`:

```properties
custom.key=Hello from custom file
```

Note: it goes on a `@Configuration` class, not on `@Component`/`@Service` — it's about _loading_ a source, so it's a configuration-time concern.

## Multiple files

```java
@PropertySource("classpath:db.properties")
@PropertySource("classpath:mail.properties")
public class AppConfig { }
```

Or, since Java 8+ allows repeatable annotations, this also works with `@PropertySources`:

```java
@PropertySources({
    @PropertySource("classpath:db.properties"),
    @PropertySource("classpath:mail.properties")
})
public class AppConfig { }
```

## Ignoring missing files

By default, a missing file throws `FileNotFoundException` at startup. To make it optional:

```java
@PropertySource(value = "classpath:optional.properties", ignoreResourceNotFound = true)
```

## Loading from the filesystem instead of classpath

```java
@PropertySource("file:/etc/myapp/config.properties")
```

## Why you rarely need it in Spring Boot

Spring Boot's auto-configuration already loads, in order:

```
application.properties
application-{profile}.properties
```

from `src/main/resources` (and a few other conventional locations) — **no `@PropertySource` needed** for those.

You reach for `@PropertySource` when you have a genuinely separate file that isn't part of that convention — e.g. a legacy config file, a file shared with a non-Spring module, or something you deliberately want kept out of `application.properties` (like a vendor-supplied `.properties` file you don't want to merge in).

## `@PropertySource` vs `application.properties`

||`application.properties`|`@PropertySource`|
|---|---|---|
|Loaded automatically by Boot|✅ Yes|❌ No — must declare explicitly|
|Supports profiles (`application-dev.properties`)|✅ Yes|❌ No, not natively|
|Supports YAML|✅ Yes|❌ **No** — `@PropertySource` does not support `.yml`/`.yaml` files|
|Use case|Your app's normal config|Extra/custom/legacy `.properties` files|

That YAML limitation trips people up — if you try `@PropertySource("classpath:custom.yml")`, it won't work as expected. Stick to `.properties` format for anything loaded via `@PropertySource`, or use a `YamlPropertiesFactoryBean` manually if you really need YAML this way.

## Quick example putting it together

```java
@Configuration
@PropertySource("classpath:payment-gateway.properties")
public class PaymentConfig {

    @Value("${payment.gateway.url}")
    private String gatewayUrl;

    @Value("${payment.gateway.apiKey}")
    private String apiKey;

    @Bean
    public PaymentClient paymentClient() {
        return new PaymentClient(gatewayUrl, apiKey);
    }
}
```

## Rule of thumb

- Normal app config → just use `application.properties` / `application-{profile}.properties`, no annotation needed.
- A separate, one-off, or legacy `.properties` file → `@PropertySource` on a `@Configuration` class.
- Need YAML for that extra file → don't use `@PropertySource`; load it manually or restructure as `.properties`.



[[Java]]
[[0 - Spring Framework]]
[[0 - Spring + Spring Boot]]