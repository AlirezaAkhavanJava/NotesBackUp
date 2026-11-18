

This one really is in the "good to know, not critical" bucket — so here's the brief version: Logback (Spring Boot's default) only has native support for **XML** configuration. Log4j 2 supports **both XML and JSON** (plus YAML and `.properties`). XML is the one actually preferred in practice, mostly because it's what every tutorial, template, and Spring Boot convention (`logback-spring.xml`) assumes.

## XML Configuration

This is the format you've already seen in earlier examples — it's the default and most common way to configure either Logback or Log4j 2.

```xml
<!-- Logback: logback-spring.xml -->
<configuration>
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
    <root level="INFO">
        <appender-ref ref="CONSOLE"/>
    </root>
</configuration>
```

Spring Boot auto-detects `logback-spring.xml` on the classpath with zero extra setup, which is a big part of why XML stays the default choice — it's the path of least resistance.

## JSON Configuration

Only Log4j 2 supports this natively (you'd need the `jackson-databind` dependency added). The same config as above, in JSON:

```json
{
  "Configuration": {
    "Appenders": {
      "Console": {
        "name": "Console",
        "PatternLayout": { "pattern": "%d{yyyy-MM-dd HH:mm:ss} %-5level %logger{36} - %msg%n" }
      }
    },
    "Loggers": {
      "Root": { "level": "INFO", "AppenderRef": { "ref": "Console" } }
    }
  }
}
```

People reach for this mainly if their team already standardizes everything else (CI configs, infra configs) in JSON and wants logging config to match that style.

## Which Is Preferred, and Why

**XML wins** for a few practical reasons: it's Logback's only native option (and Logback is what you get by default in Spring Boot), it has schema validation support in most IDEs so typos get caught early, and essentially all official documentation and community examples use it — so troubleshooting and copy-pasting configs is far easier. JSON configuration exists mainly for teams with a strong, pre-existing JSON-everywhere convention; outside of that, there's no real advantage pulling you toward it.


[[Logger]]