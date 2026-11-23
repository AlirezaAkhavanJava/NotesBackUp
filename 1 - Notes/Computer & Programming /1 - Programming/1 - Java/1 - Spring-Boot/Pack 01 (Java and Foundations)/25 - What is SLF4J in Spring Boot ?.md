


SLF4J (Simple Logging Facade for Java) is not a logging framework — it's an interface layer that sits in front of one. Your code calls `Logger.info(...)`, `Logger.debug(...)`, and so on against the SLF4J API, and a separate "binding" dependency decides which actual logging engine (Logback, Log4j2, java.util.logging) does the real work of formatting and writing those calls. The payoff is that your application code never references a concrete logging library directly, so the backend can be swapped — Logback today, Log4j2 tomorrow — without touching a single `logger.info(...)` call anywhere in your codebase. Spring Boot ships with SLF4J bound to Logback by default, which is why adding `spring-boot-starter-web` gives you working logging with zero extra dependencies.

## Getting a logger

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class UserService {
    private static final Logger logger = LoggerFactory.getLogger(UserService.class);
}
```

`LoggerFactory.getLogger(Class<?>)` ties the logger's name to the fully-qualified class name, which matters later because Logback lets you set different log levels per package or per class based on that name. Declaring it `private static final` means one logger instance is shared across all instances of the class rather than created per object — there's no reason for logging infrastructure to be duplicated per instance.

Always pass the `Class<?>` overload, not `getLogger(String)` with a hand-typed name. A typo or a renamed class leaves the string stale, and your logs silently misattribute which class produced them.

## The five levels, and what they're for

SLF4J defines five levels, ordered by severity: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`. The ordering matters because setting a level enables that level _and everything above it_ — set a logger to `INFO` and `TRACE`/`DEBUG` calls are suppressed, while `WARN`/`ERROR` still fire.

- `TRACE` — the finest detail, essentially never enabled outside active debugging of a specific problem.
- `DEBUG` — information useful to a developer tracing what the app is doing; too noisy for production.
- `INFO` — significant, expected events: a user registered, a job completed.
- `WARN` — something unexpected happened but the app recovered or can continue.
- `ERROR` — something failed and needs attention, often paired with the exception.

```java
public void registerUser(String username) {
    logger.debug("Attempting to register user: {}", username);
    try {
        // registration logic
        logger.info("User {} registered successfully", username);
    } catch (Exception e) {
        logger.error("Failed to register user: {}", username, e);
    }
}
```

Note the last call: passing the exception object itself (`e`) as the final argument — not formatting it into the message string — is what makes Logback print the full stack trace underneath the log line. Dropping the exception object and only logging `e.getMessage()` throws away the stack trace, which is usually the one thing you actually need when debugging a failure.

## Parameterized logging

```java
logger.info("User {} attempted login {} times", username, attempts);
```

The `{}` placeholders get substituted positionally, and SLF4J takes the arguments as varargs — you can pass as many as the message needs; there's no fixed cap requiring you to fall back to an array for anything beyond two. The actual performance reason this pattern exists is lazier than it looks at first: if the `INFO` level isn't enabled for this logger, SLF4J never evaluates or concatenates the arguments into a string at all. Compare that to `logger.info("User " + username + " attempted login " + attempts + " times")`, which builds the full string on every call whether or not anything ends up written — wasted work on every disabled log statement, which adds up in hot code paths.

For an argument that's expensive to compute (not just format), parameterized logging alone doesn't save you — the expensive call still happens before `logger.info` is even invoked. Guard it explicitly:

```java
if (logger.isDebugEnabled()) {
    logger.debug("Expensive operation result: {}", computeExpensiveResult());
}
```

## Configuring levels in Spring Boot

```properties
logging.level.root=INFO
logging.level.com.example=DEBUG
logging.level.com.example.UserService=TRACE
```

More specific package/class entries override the broader ones above them — `UserService` logs at `TRACE` even though everything else under `com.example` is at `DEBUG`, and everything outside `com.example` falls back to the root `INFO`. This is Spring Boot's own property-based shortcut; it's translated into Logback's actual configuration format underneath, which is the next layer down.

## Logback configuration directly

For anything beyond simple level-setting, you configure Logback itself via `logback-spring.xml` in `src/main/resources` (the `-spring` suffix lets it react to Spring profiles, which plain `logback.xml` can't):

```xml
<configuration>
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>

    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>logs/app.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <fileNamePattern>logs/app.%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <maxFileSize>10MB</maxFileSize>
            <maxHistory>30</maxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} %X{userId} - %msg%n</pattern>
        </encoder>
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

Three concepts compose here: an **appender** is a destination (console, a file); an **encoder** defines the text format written to that destination; a **rolling policy** on a file appender decides when the current file closes and a new one starts — here, by size (10MB) or by date, whichever comes first, keeping at most 30 days of history before older files are deleted. A `<logger>` block scoped to `com.example` with `additivity="false"` stops its log events from _also_ being handled by the root logger's appenders — without that flag, the same line would be written twice, once by the package-specific appender and again by root's.

## MDC: per-request context without passing parameters everywhere

MDC (Mapped Diagnostic Context) is a thread-local map Logback can pull values from when formatting a line, so you can tag every log statement in a request's lifecycle with, say, a request ID, without threading that ID through every method signature:

```java
public void processRequest(String userId, String requestId) {
    MDC.put("userId", userId);
    MDC.put("requestId", requestId);
    try {
        logger.info("Processing request");
    } finally {
        MDC.clear();
    }
}
```

`%X{userId}` in a pattern pulls that value into the printed line. The `finally` block clearing MDC isn't optional cleanup — it's correctness. Since MDC is thread-local and application servers reuse threads across requests (this is exactly the thread-pool reuse you've already seen with Tomcat's worker threads), a request that forgets to clear MDC leaves its values sitting on that thread for whichever unrelated request runs on it next, silently mislabeling that request's logs.

## Asynchronous logging

```xml
<appender name="ASYNC" class="ch.qos.logback.classic.AsyncAppender">
    <appender-ref ref="FILE" />
</appender>
```

Wrapping an appender in `AsyncAppender` moves the actual I/O (writing to disk, in this case) onto a separate thread, so the thread that called `logger.info(...)` doesn't block waiting for the disk write to finish. This matters for throughput under load, but it comes with a tradeoff worth knowing: `AsyncAppender` has a bounded internal queue, and if logging is produced faster than it can be written out, by default it starts _discarding_ lower-severity events (`TRACE`/`DEBUG`/`INFO`) rather than blocking the application — so under extreme load, async logging can silently drop log lines. `WARN`/`ERROR` are not discarded.

## Markers: routing, not just formatting

```java
private static final Marker SECURITY = MarkerFactory.getMarker("SECURITY");

logger.info(SECURITY, "Checking access for user: {}", user);
```

A marker attaches a tag to a log call that Logback's filters can act on — for example, routing every `SECURITY`-marked line to a dedicated security log file regardless of which class or package produced it, independent of the logger-name-based routing you set up with `<logger>` elements.

## Structured logging

Plain text log lines are easy for a human to read in a terminal but awkward for a machine to parse reliably. If logs are being shipped to an aggregation system (ELK, Splunk, or similar), emitting each line as JSON instead of a formatted string lets the aggregator index fields directly rather than regex-parsing text. This is usually done with a dedicated JSON encoder for Logback (the ecosystem has moved toward `logstash-logback-encoder` as the actively maintained option) configured as the encoder on a file or console appender, in place of the `<pattern>` encoder shown above.

## Testing that logging actually happened

```java
Logger logger = (Logger) LoggerFactory.getLogger(MyService.class);
ListAppender<ILoggingEvent> listAppender = new ListAppender<>();
listAppender.start();
logger.addAppender(listAppender);

myService.doWork();

assertEquals(Level.INFO, listAppender.list.get(0).getLevel());
assertEquals("Work started", listAppender.list.get(0).getMessage());
```

`ListAppender` is a Logback test double that captures emitted log events into an in-memory list instead of writing them anywhere, so a test can assert on level, message content, or MDC values without touching a real file or console — useful specifically for verifying that a code path logs what it's supposed to (an audit trail, a security event) as part of its contract, not just that it behaves correctly otherwise.

## What actually breaks logging setups in practice

- **Multiple SLF4J bindings on the classpath** (e.g., both Logback and Log4j2's SLF4J binding present at once) causes SLF4J to fail at startup rather than guess which one you meant — if you switch backends, make sure the old one is fully removed, not just unused.
- **Logging sensitive data** — passwords, tokens, full card numbers — directly into log statements is a common and serious mistake precisely because logs usually have looser access control and longer retention than the database itself.
- **Leaving TRACE/DEBUG enabled in production** generates enough I/O volume to measurably affect performance, separate from any correctness concern.


[[Logger]]
[[Spring Framework]]