
**Logging** means your application writes a running diary of what it is doing (events, warnings, errors) to the console or a file, so that when something goes wrong you can find out _what happened and why_, without being there to watch.

**Analogy:** A plane's **flight recorder** (black box). Nobody looks at it during a normal flight, but when something fails, it is the only way to reconstruct what happened. And just like testing, it is item "monitoring" on the real-projects checklist: in production you cannot attach a debugger or add `System.out.println` and restart, so the logs are often your _only_ window into the running system.

## Why not just `System.out.println`?

It works in a learning project, but fails in a real one:

||`System.out.println`|A logging framework|
|---|---|---|
|**Severity**|None, everything looks the same|Levels (`ERROR`, `WARN`, `INFO`...)|
|**Filtering**|Can't turn it off without editing code|Change a config line, no recompile|
|**Context**|Just your text|Timestamp, thread, class name added automatically|
|**Destination**|Console only|Console, files, rotating files, remote systems|
|**Performance**|Slow, synchronized|Optimized, can be async|
|**Format**|Whatever you typed|Consistent, can be JSON for tools|

## Log levels (from most to least severe)

|Level|Meaning|Example|
|---|---|---|
|**ERROR**|Something failed, needs attention|Database unreachable, payment crashed|
|**WARN**|Unexpected, but the app continues|Retrying a request, deprecated usage|
|**INFO**|Normal important events|"Order 42 placed", "Application started"|
|**DEBUG**|Detail for developers diagnosing|Method inputs, SQL parameters|
|**TRACE**|Extremely fine detail|Step-by-step internals|

You set a **threshold**: if it is `INFO`, then `INFO`, `WARN`, and `ERROR` are shown, while `DEBUG` and `TRACE` are hidden. In production you typically run at `INFO`, and temporarily switch to `DEBUG` when investigating a problem, with **no code change**.

## The Java logging landscape (why it looks confusing)

Java has several logging libraries, which is historical (the same pattern as JDBC/JPA: an interface plus implementations):

- **SLF4J:** a **facade**, just the API you write against (like `PaymentService` in the API lesson).
- **Logback:** the **implementation** doing the real work. Spring Boot uses it by default.
- **Log4j2:** another popular implementation.
- **`java.util.logging`:** built into the JDK, rarely used in Spring projects.

You write code against **SLF4J**, so you can swap the implementation without touching your code. Spring Boot already includes all of this through `spring-boot-starter`, so you add no dependency.

## Using a logger

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class BookService {

    private static final Logger log = LoggerFactory.getLogger(BookService.class);

    private final BookRepository repository;

    public BookService(BookRepository repository) {
        this.repository = repository;
    }

    public Book getBook(Long id) {
        log.debug("Looking up book id={}", id);

        return repository.findById(id).orElseThrow(() -> {
            log.warn("Book not found, id={}", id);
            return new BookNotFoundException(id);
        });
    }

    public Book create(CreateBookRequest request) {
        try {
            Book saved = repository.save(new Book(null, request.title(), request.year()));
            log.info("Book created, id={}, title={}", saved.getId(), saved.getTitle());
            return saved;
        } catch (DataAccessException e) {
            log.error("Failed to create book, title={}", request.title(), e);
            throw e;
        }
    }
}
```

**Key points in that code:**

- `LoggerFactory.getLogger(BookService.class)` names the logger after the class, so each line shows _where_ it came from.
- **`{}` placeholders** instead of string concatenation. `log.debug("id=" + id)` builds the string even if DEBUG is off, while `{}` builds it only if the message will actually be printed.
- **The exception goes last, as its own argument:** `log.error("message", e)` prints the full **stack trace**. Writing `log.error("Failed: " + e.getMessage())` throws the stack trace away, and the stack trace is usually the most valuable part.

## Lombok shortcut

Many projects use Lombok to remove the boilerplate line:

```java
@Slf4j
@Service
public class BookService {
    // `log` is generated automatically
}
```

This needs the Lombok dependency in your `pom.xml`. It is common in real projects, but understand the plain version first.

## What a Spring Boot log line looks like

```
2026-10-02T10:15:30.123+02:00  INFO 4821 --- [nio-8080-exec-1] c.e.library.BookService : Book created, id=7, title=Clean Code
```

Reading it left to right: timestamp, level, process ID, **thread name**, logger (class), then your message. The thread name connects to the networking lesson: each HTTP request is handled by a thread from Tomcat's pool, so you can follow one request's lines.

## Configuration (no code changes)

In `application.properties`:

```properties
# Default level for everything
logging.level.root=INFO

# More detail for your own code
logging.level.com.example.library=DEBUG

# See the SQL Hibernate generates (from the Hibernate lesson)
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.orm.jdbc.bind=TRACE

# Write to a file as well as the console
logging.file.name=logs/app.log
logging.logback.rollingpolicy.max-file-size=10MB
logging.logback.rollingpolicy.max-history=14
```

The Hibernate lines connect to the previous lesson: they are the proper way to see SQL and bound parameters, better than `show-sql=true` because they go through the logging system. You can also change levels at runtime with Spring Boot Actuator, without restarting.

For advanced needs you add `logback-spring.xml` to `src/main/resources`, where you control format, multiple files, and separate levels per destination.

## Rotation

Log files grow forever and fill your disk. **Rolling** splits them by size or date and deletes old ones, which is what `max-file-size` and `max-history` above do. In Docker, the common practice is the opposite: log to the **console only**, and let Docker or the platform collect the output (`docker logs my-app`, from your Docker lesson).

## Real-world practices

1. **Use the right level.** If everything is `ERROR`, nothing stands out. A user typing a wrong password is `INFO` or `WARN`, not `ERROR`.
    
2. **Log events, not noise.** Log business events (order placed, payment failed) and boundaries (incoming request, external call), not every line of code.
    
3. **Include identifiers** (`orderId`, `userId`) so you can search for one case. A message like "Error occurred" is useless.
    
4. **MDC (Mapped Diagnostic Context):** attach a **correlation ID** to every log line of one request, so you can trace it across layers or even across services.
    
    ```java
    MDC.put("requestId", UUID.randomUUID().toString());
    // every log line in this thread can now include %X{requestId}
    MDC.clear();   // important: threads are reused
    ```
    
5. **Structured (JSON) logging** for production: tools like the ELK stack, Grafana Loki, or Datadog can search and filter fields instead of parsing text. Spring Boot 3.4+ supports structured logging formats out of the box.
    
6. **Centralize logs:** with many instances or containers, you can't SSH into each one, so they are shipped to one searchable place.
    

## Logs vs the other observability tools

- **Logs:** discrete events ("what happened").
- **Metrics:** numbers over time (requests per second, memory use), for example with Micrometer and Prometheus.
- **Traces:** the path of one request across services.

Together these are called **observability**. Logs are the foundation and the part you will meet first.

## Seeing logs on Debian 13

```bash
tail -f logs/app.log             # follow a file live
grep ERROR logs/app.log          # find errors
grep "id=7" logs/app.log         # follow one case
journalctl -u myapp -f           # if the app runs as a systemd service
docker logs -f my-app            # if it runs in Docker
```

## Gotchas

- **Never log secrets or personal data:** passwords, tokens, API keys, credit card numbers, full personal details. Logs are copied, shipped, and read by many people, and they often have weaker protection than the database. This is a very common real-world security leak, and in some regions it also breaks privacy laws.
- **Log injection:** if you log raw user input, an attacker can include newline characters to forge fake log lines. Sanitize or use structured logging for untrusted input (the same "never trust the input" idea as SQL injection).
- **Don't log and rethrow everywhere.** If every layer catches, logs, and rethrows, one error appears five times. Log **once**, usually where the exception is finally handled (for example, a `@ControllerAdvice` global exception handler).
- **Debug logging in production is expensive:** it slows the app and floods the disk. Use it temporarily.
- **Swallowing exceptions:** `catch (Exception e) { }` with nothing inside is the worst bug-hiding habit. At minimum, log it.
- **Expensive arguments:** `log.debug("data={}", computeBigReport())` still _runs_ `computeBigReport()` even when DEBUG is off, since Java evaluates arguments first. Wrap it with `if (log.isDebugEnabled())` or use a lambda-style call.
- **Disk space:** without rotation, a log file can fill the server's disk and crash the whole machine.
- **Logging is not auditing.** If you must keep a legally reliable record (who changed what), store it in the database or an audit system, not in ordinary logs that rotate away.
- **Logging in tests:** keep test output quiet by setting a higher level in `src/test/resources/application.properties`, but don't depend on logs as assertions.




[[Java]]
[[Spring Framework]]
[[Java-Script]]
[[C]]
[[Python]]