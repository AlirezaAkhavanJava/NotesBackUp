
`@Value` injects a single value — a literal, a property from `application.properties`, a system/env variable, or a SpEL expression — directly into a field, constructor parameter, or setter parameter.

## Basic property injection

```java
@Component
public class MyService {

    @Value("${server.port}")
    private int port;

    @Value("${app.name}")
    private String appName;
}
```

Given:

```properties
server.port=8080
app.name=MyApplication
```

`port` becomes `8080`, `appName` becomes `"MyApplication"`. Spring auto-converts the string property to the target type (`int`, `boolean`, `List<String>`, etc).

## With a default value

Use `:` inside the placeholder — if the property isn't found, this default is used instead of throwing an error:

```java
@Value("${app.timeout:30}")
private int timeout;          // 30 if "app.timeout" isn't set

@Value("${app.feature.enabled:false}")
private boolean featureEnabled;
```

Without a default, a missing property causes startup failure (`Could not resolve placeholder`).

## Literal values (no property lookup)

```java
@Value("Hello World")
private String greeting;   // just the literal string, no ${...}
```

## SpEL expressions

Anything starting with `#{}` is evaluated as Spring Expression Language:

```java
@Value("#{2 + 3}")
private int sum;                          // 5

@Value("#{systemProperties['user.home']}")
private String userHome;

@Value("#{someOtherBean.someProperty}")
private String derivedValue;              // reference another bean
```

## Injecting lists / arrays

```properties
app.servers=server1,server2,server3
```

```java
@Value("${app.servers}")
private String[] servers;        // ["server1", "server2", "server3"]

@Value("${app.servers}")
private List<String> serverList; // Spring converts this too
```

## Constructor injection with `@Value`

```java
@Component
public class MyComponent {

    private final String appName;

    public MyComponent(@Value("${app.name}") String appName) {
        this.appName = appName;
    }
}
```

## Prerequisite: `PropertySourcesPlaceholderConfigurer`

In plain Spring, you need to register this bean for `${...}` placeholders to resolve. **Spring Boot registers it automatically** via `application.properties`/`.yml` auto-configuration, so in Boot you almost never think about this.

## `@Value` vs `@ConfigurationProperties`

This is the more important distinction in real Spring Boot apps:

```java
// @Value — one field at a time, scattered across classes
@Value("${app.mail.host}")
private String mailHost;
@Value("${app.mail.port}")
private int mailPort;
```

```java
// @ConfigurationProperties — grouped, type-safe, bulk-bound
@ConfigurationProperties(prefix = "app.mail")
public class MailProperties {
    private String host;
    private int port;
    // getters/setters
}
```

```properties
app.mail.host=smtp.example.com
app.mail.port=587
```

## When to use which

|Use `@Value` when...|Use `@ConfigurationProperties` when...|
|---|---|
|You need one or two simple values|You have a group of related properties|
|A quick literal or SpEL expression|You want type-safe, validated (`@Validated`) config|
|Prototyping / small scripts|Real applications — it's the officially recommended approach|

**Spring Boot's own docs recommend `@ConfigurationProperties` over `@Value`** for anything beyond a couple of ad hoc values, because it's more testable, refactor-safe (no string literals scattered everywhere), and supports relaxed binding, validation, and nested objects.


[[Java]]
[[0 - Spring Framework]]
[[0 - Spring + Spring Boot]]