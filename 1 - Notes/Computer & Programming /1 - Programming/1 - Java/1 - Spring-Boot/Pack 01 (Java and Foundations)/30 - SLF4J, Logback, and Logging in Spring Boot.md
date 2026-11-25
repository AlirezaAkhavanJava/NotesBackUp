

SLF4J isn't a logging framework — it's an interface layer in front of one. Your code calls `logger.info(...)` against the SLF4J API; a separate binding decides which engine (Logback, Log4j2) actually writes it. This means your code never references a concrete logging library, so the backend can be swapped without touching a single log call. Spring Boot binds SLF4J to Logback by default.

### Getting a logger

```java
private static final Logger logger = LoggerFactory.getLogger(UserService.class);
```

`private static final` — one shared instance per class, not per object. Always pass `Class<?>`, not a hand-typed string: a renamed class leaves a string stale and misattributes logs.

### The five levels

`TRACE` → `DEBUG` → `INFO` → `WARN` → `ERROR`, ascending severity. Setting a level enables it _and everything above_ — `INFO` suppresses `TRACE`/`DEBUG` but still fires `WARN`/`ERROR`.

- `TRACE` — finest detail, active debugging only
- `DEBUG` — developer-useful, too noisy for prod
- `INFO` — significant expected events
- `WARN` — recovered from something unexpected
- `ERROR` — failure needing attention

```java
try {
    // ...
} catch (Exception e) {
    logger.error("Failed to register user: {}", username, e);  // pass e itself, not e.getMessage()
}
```

Passing `e` as the last argument prints the full stack trace. Logging `e.getMessage()` instead throws that away.

### Parameterized logging

```java
logger.info("User {} attempted login {} times", username, attempts);
```

`{}` placeholders are substituted positionally, as varargs — no fixed limit. The real payoff: if `INFO` is disabled, SLF4J never builds the string at all. String concatenation (`"User " + username + ...`) always builds it, wasted or not.

Expensive _computed_ arguments aren't saved by this — the computation still runs before the call. Guard those explicitly:

```java
if (logger.isDebugEnabled()) {
    logger.debug("Result: {}", computeExpensiveResult());
}
```

### Setting levels

```properties
logging.level.root=INFO
logging.level.com.example=DEBUG
logging.level.com.example.UserService=TRACE
```

More specific entries win. This is Boot's shortcut, translated into Logback config underneath.

### Logback configuration directly

`logback-spring.xml` in `src/main/resources` (the `-spring` suffix reacts to profiles; plain `logback.xml` can't):

```xml
<configuration>
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder><pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern></encoder>
    </appender>

    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>logs/app.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <fileNamePattern>logs/app.%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <maxFileSize>10MB</maxFileSize>
            <maxHistory>30</maxHistory>
        </rollingPolicy>
        <encoder><pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} %X{userId} - %msg%n</pattern></encoder>
    </appender>

    <root level="INFO">
        <appender-ref ref="CONSOLE" />
        <appender-ref ref="FILE" />
    </root>

    <logger name="com.example" level="DEBUG" additivity="false">
        <appender-ref ref="CONSOLE" />
    </logger>
</configuration>
```

- **Appender** — a destination (console, file)
- **Encoder** — the text format for that destination
- **Rolling policy** — when a file closes and a new one starts (here: 10MB or daily, 30-day retention)
- **`additivity="false"`** — stops a package-scoped logger's events from _also_ firing through root's appenders (otherwise every line is written twice)

### MDC: per-request context

A thread-local map Logback can pull from when formatting a line — tags every log in a request's lifecycle (e.g. a request ID) without threading it through every method:

```java
MDC.put("userId", userId);
MDC.put("requestId", requestId);
try {
    logger.info("Processing request");
} finally {
    MDC.clear();   // not optional — threads are reused (same pool reuse as Tomcat workers)
}
```

Forgetting to clear leaves values on the thread for the next unrelated request, silently mislabeling its logs.

### Async logging

```xml
<appender name="ASYNC" class="ch.qos.logback.classic.AsyncAppender">
    <appender-ref ref="FILE" />
</appender>
```

Moves I/O to a separate thread so the caller doesn't block. Tradeoff: the internal queue is bounded — under extreme load it silently **discards** `TRACE`/`DEBUG`/`INFO` (never `WARN`/`ERROR`) rather than blocking the app.

### Markers: routing, not formatting

```java
private static final Marker SECURITY = MarkerFactory.getMarker("SECURITY");
logger.info(SECURITY, "Checking access for user: {}", user);
```

Lets Logback filters route tagged lines (e.g. all `SECURITY` events) to a dedicated file, independent of logger-name-based routing.

### Structured logging

Plain text is human-readable but awkward for machines. If logs ship to an aggregator (ELK, Splunk), emit JSON instead via a dedicated encoder (`logstash-logback-encoder` is the current standard) in place of `<pattern>`.

### Testing logging

```java
Logger logger = (Logger) LoggerFactory.getLogger(MyService.class);
ListAppender<ILoggingEvent> listAppender = new ListAppender<>();
listAppender.start();
logger.addAppender(listAppender);

myService.doWork();

assertEquals(Level.INFO, listAppender.list.get(0).getLevel());
assertEquals("Work started", listAppender.list.get(0).getMessage());
```

`ListAppender` captures events in-memory — useful for asserting a code path logs what it's contractually supposed to (an audit trail, a security event).

### What actually breaks in practice

- **Multiple SLF4J bindings on the classpath** (Logback + Log4j2's binding both present) → fails at startup. Fully remove the old one when switching.
- **Logging sensitive data** (passwords, tokens, card numbers) — logs have looser access control and longer retention than the database.
- **TRACE/DEBUG left on in production** — measurable I/O overhead, independent of correctness.



[[Spring Framework]]