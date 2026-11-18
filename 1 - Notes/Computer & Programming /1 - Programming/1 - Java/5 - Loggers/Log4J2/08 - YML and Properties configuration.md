

Up to now you've seen Logback's own native config file (`logback-spring.xml`) and Log4j 2's JSON option — both are _the logging engine's own_ configuration format, independent of Spring. But Spring Boot also exposes a second, simpler layer: a set of **Boot-specific properties** that let you control the most common logging settings — levels, patterns, file output — directly from `application.properties` or `application.yml`, the same files you already use for database config, server port, etc. Spring Boot reads these and applies them to whichever logging engine is active, without you ever touching `logback-spring.xml` at all. It's a convenience layer sitting on top of the engine, not a replacement for it — for anything advanced (custom appenders, rolling file policies, filters), you still need the engine's own XML.

## Properties Format

```properties
# application.properties
logging.level.root=WARN
logging.level.com.me.orders=DEBUG
logging.level.org.springframework.web=INFO

logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss} %-5level %logger{36} - %msg%n
logging.pattern.file=%d{yyyy-MM-dd HH:mm:ss} %-5level [%thread] %logger{36} - %msg%n

logging.file.name=logs/app.log
logging.file.max-size=10MB
logging.file.max-history=30
```

Each line is a flat `key=value` pair. `logging.level.<logger-name>=<LEVEL>` is the most commonly used one — it sets the level for a specific package or class, exactly like the `<logger>` elements you saw in `logback-spring.xml`, just without XML.

## YAML Format (Same Settings)

```yaml
# application.yml
logging:
  level:
    root: WARN
    com.me.orders: DEBUG
    org.springframework.web: INFO
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} %-5level %logger{36} - %msg%n"
    file: "%d{yyyy-MM-dd HH:mm:ss} %-5level [%thread] %logger{36} - %msg%n"
  file:
    name: logs/app.log
    max-size: 10MB
    max-history: 30
```

Same keys, same values — YAML just expresses the dotted property path (`logging.level.root`) as nested indentation instead of repeating `logging.` on every line. Indentation must be spaces, never tabs; YAML is whitespace-sensitive, and a tab character will cause a parse error at startup.

## What You Can Configure This Way

- **Per-package/per-class log levels** (`logging.level.*`) — far more common to set here than to edit XML for.
- **Console and file patterns** (`logging.pattern.console`, `logging.pattern.file`).
- **Writing to a file** — `logging.file.name` (a specific file) or `logging.file.path` (a directory, Boot picks the filename), plus basic size/history rollover settings.
- **Grouping loggers** — define a named group once, set its level in one line:

```yaml
logging:
  group:
    tomcat: org.apache.catalina, org.apache.tomcat
  level:
    tomcat: DEBUG
```

This turns on `DEBUG` for both Tomcat packages at once instead of listing each individually.

## What You Can't Configure This Way

This layer deliberately only covers the common cases. It has no way to express: custom appenders (shipping to Kafka, a database, a network socket), conditional/profile-specific appender wiring beyond basic level overrides, filters, or async wrapper configuration. The moment you need any of that, you still write a `logback-spring.xml` (or `log4j2.xml`) — and if both exist, the dedicated logging config file takes precedence for anything it defines, while Boot's properties still work for the parts the XML doesn't override.

## YAML vs Properties: The General Comparison

This isn't a logging-specific question — it's the same tradeoff for _all_ Spring Boot configuration, logging included.

**Properties** is flat `key=value`, one setting per line, no nesting syntax to get wrong. It's unambiguous and fails loudly on typos (a malformed line is just a broken key). Lists require an awkward index-based syntax:

```properties
my.servers[0]=prod1.example.com
my.servers[1]=prod2.example.com
```

**YAML** expresses hierarchy natively through indentation, which removes the repeated prefix on every line and reads more naturally once you have many related settings — like the `logging.level.*` block above. It also supports lists cleanly:

```yaml
my:
  servers:
    - prod1.example.com
    - prod2.example.com
```

and, importantly for real Spring Boot projects, YAML supports **multiple profile documents in a single file**, separated by `---`:

```yaml
spring:
  config:
    activate:
      on-profile: prod
logging:
  level:
    root: WARN
---
spring:
  config:
    activate:
      on-profile: dev
logging:
  level:
    root: DEBUG
```

Properties files can't do this — each profile needs its own separate file (`application-dev.properties`, `application-prod.properties`).

## Which Is Preferred in Spring Boot

**YAML is the more commonly preferred choice in real Spring Boot projects**, and it's what you'll see in most production codebases, mainly because of two things: the nesting readability once a config file grows past a handful of properties, and single-file multi-profile support, which keeps all environment variants visible together instead of scattered across several files. The tradeoff is that YAML's indentation sensitivity is a real source of silent, hard-to-spot startup failures — a single misaligned space breaks the whole document, and the error messages aren't always obvious.

**Properties remains preferred** in smaller projects, by teams that value the complete lack of structural ambiguity, or anywhere config is often edited by hand under time pressure (since there's nothing to misindent). Spring's own reference documentation defaults to showing properties-format examples for this reason — it's the safer format to demonstrate correctly in isolated snippets.

In practice: pick one per project and stay consistent — mixing both `application.properties` and `application.yml` in the same app works (Boot merges them, with properties taking precedence on conflicts) but makes config harder to find at a glance, so it's worth avoiding unless you have a specific reason.



[[Logger]]