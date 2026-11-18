

`System.out.println()` is the most basic way to get text out of a Java program. `System.out` is a `PrintStream` object connected to the process's standard output stream (your terminal, by default), and `println` just writes a string to it followed by a line break. There's no formatting system, no filtering, no destination control — it's a direct, synchronous write to the console, every single time it's called.

That simplicity is exactly why it's fine for quick scripts and totally wrong for real applications. Once code is running in a server, with multiple threads, multiple environments (dev, staging, prod), and people who need to search through output later, `println` stops being a tool and starts being a liability. That's the gap logging frameworks exist to fill.

## Why `println` Breaks Down in Real Apps

**No levels.** Every `println` call is equally "loud." You can't say "only show me warnings and errors in production" — if you want less output, you have to go delete or comment out code.

**No way to turn it off.** Your only lever is editing source code and redeploying. A logging framework lets you dial verbosity up or down with a config file, with zero code changes.

**Always synchronous and always to stdout.** `println` blocks the calling thread while it writes, and it can only go to the console (unless you manually redirect the stream). You can't easily send it to a file, roll it over daily, ship it to a log aggregator, or write it asynchronously so it doesn't slow down request handling.

**No context.** It just prints whatever string you built. There's no automatic timestamp, no thread name, no class name, no stack trace formatting for exceptions — you'd have to construct all of that by hand every time.

**Thread-unsafe interleaving.** Under concurrent load, `println` calls from different threads can interleave character-by-character or line-by-line in ways that make the console output nearly unreadable.

```java
// Quick-and-dirty, fine for a 10-line script
System.out.println("Processing order: " + orderId);
```

## What Logging Actually Is

A logging framework separates two concerns that `println` smashes together: **what you want to record** and **what happens to that record**. You write one line of code to say "this happened," and a separate configuration decides whether it's shown, where it goes, and how it's formatted.

In the Java world this almost always means two layers:

- **SLF4J** — a _facade_, i.e. a thin, standard API your code calls (`logger.info(...)`, `logger.error(...)`). Your code never depends on a specific logging engine directly.
- **An actual logging engine underneath** — Logback (Spring Boot's default) or Log4j 2 are the common choices. This is what actually formats, filters, and ships the output.

```java
private static final Logger logger = LoggerFactory.getLogger(OrderService.class);

logger.info("Processing order: {}", orderId);
```

`{}` is a placeholder — SLF4J substitutes `orderId` into it. New thing to flag here since it differs from `println`: that substitution only happens if the log level is actually enabled, which matters for the performance point below.

## Why Logging Is Preferred

**Levels let you control volume without touching code.** The standard levels, from least to most severe, are `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`. You log at whatever level makes sense, and a config file decides the cutoff:

```properties
# application.properties
logging.level.root=WARN
logging.level.com.me.orders=DEBUG
```

Now your own package logs verbosely while everything else stays quiet — in production you can flip this to `INFO` or `WARN` globally with no redeploy.

**Performance: skipped work when a level is disabled.** With `println`, the string concatenation (`"Processing order: " + orderId`) happens _every time_, even if nobody will ever read that output. With SLF4J's placeholder style, if `DEBUG` is disabled, the framework skips the string-building work entirely — it never even evaluates the arguments.

**Output destinations are configurable, not hardcoded.** Logback can write to console, to a rolling file (new file per day, old ones compressed or deleted after N days), to a remote log aggregation system, or several of these at once — all from config, no code changes:

```xml
<!-- logback-spring.xml -->
<appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <file>logs/app.log</file>
    <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
        <fileNamePattern>logs/app.%d{yyyy-MM-dd}.log</fileNamePattern>
        <maxHistory>30</maxHistory>
    </rollingPolicy>
</appender>
```

**Automatic, consistent context.** Every log line gets a timestamp, thread name, log level, and logger name (usually the class) for free, in the same format every time — because the framework adds it, not your code.

**Exceptions are handled properly.** Pass a `Throwable` as the last argument and the full stack trace is logged, correctly formatted, in one call:

```java
try {
    processPayment(order);
} catch (PaymentException e) {
    logger.error("Payment failed for order {}", orderId, e);
}
```

**Thread-safe by design**, so concurrent requests don't produce garbled, interleaved output — each log line is written as a complete, ordered unit.

**Structured output for tooling.** Logback and Log4j 2 can emit JSON instead of plain text, which lets log aggregators (ELK, Grafana Loki, etc.) parse and search fields like `orderId` or `userId` directly, instead of grepping raw strings.

The short version: `println` writes a string to a fixed place with no control. A logging framework gives you a leveled, configurable, performant, and structured way to record what's happening — which is the difference between debugging a toy script and operating a real service.


[[Logger]]