You've already seen the _end result_ of this — those readable "Description / Action" error blocks Boot prints instead of a raw stack trace, and you know `ApplicationFailedEvent` fires when something goes wrong during startup. This lesson is about the machinery that turns a raw exception into that friendly report: the **Failure Analyzer** framework.

## The problem it solves

Without this mechanism, a startup failure like a missing `DataSource` property would surface as a `BeanCreationException` wrapping a `UnsatisfiedDependencyException` wrapping several more layers down to the actual cause — technically accurate, but you'd have to read five stack frames to find the one sentence that matters: "you forgot to set `spring.datasource.url`." Boot's failure analysis framework exists to catch specific, well-known exception types and translate them into a direct, two-part message before they ever reach you as a raw trace.

## The contract: `FailureAnalyzer`

The interface is small:

```java
public interface FailureAnalyzer {
    FailureAnalysis analyze(Throwable failure);
}
```

Given the thrown exception (the full chain, not just the top), it either returns a `FailureAnalysis` — which bundles a **description** and an **action** — or returns `null` to say "not my exception, let someone else try." Most implementations extend `AbstractFailureAnalyzer<T>`, a convenience base class that handles walking the cause chain to find an instance of a specific exception type `T`, so you only need to implement the "what do I do once I've found it" part:

```java
public class PortInUseFailureAnalyzer
        extends AbstractFailureAnalyzer<PortInUseException> {

    @Override
    protected FailureAnalysis analyze(Throwable rootFailure, PortInUseException cause) {
        return new FailureAnalysis(
            "Web server failed to start. Port " + cause.getPort() + " was already in use.",
            "Identify and stop the process using port " + cause.getPort() +
                ", or configure this application to listen on a different port."
        );
    }
}
```

That's a real, simplified version of one of Boot's own built-in analyzers — it's exactly why "port already in use" gives you that specific two-line message instead of a bare `BindException`.

## How analyzers get discovered

Same registration pattern you've now seen twice — once for auto-configuration classes, once for starters. Analyzers are listed in a classpath file:

```
META-INF/spring/org.springframework.boot.diagnostics.FailureAnalyzer.imports
```

(or the older `spring.factories` key `org.springframework.boot.diagnostics.FailureAnalyzer=...`, still supported). Boot ships dozens of these out of the box, covering things like: a bean definition conflict, a missing required property, a circular dependency it can't resolve (the constructor-injection kind from your bean registration lesson), an invalid `@ConfigurationProperties` binding, a port conflict, and a failed database connection.

## `FailureAnalyzers`: the dispatcher

The class that actually orchestrates this — `FailureAnalyzers` — is what Boot's `SpringApplication` hands the exception to when `run()` fails. It loads every registered analyzer and tries each one in turn against the failure, using the first non-null `FailureAnalysis` it gets back. If none of them recognize the exception, Boot falls back to printing the raw exception and stack trace, same as any uncaught exception — the framework is additive, not a replacement for normal error output.

## `FailureAnalysisReporter`: how it gets printed

Once a `FailureAnalysis` is produced, a separate interface — `FailureAnalysisReporter` — is responsible for actually rendering it to the console (or wherever output is configured to go). The default implementation (`LoggingFailureAnalysisReporter`) is what produces the exact banner format you've seen:

```
***************************
APPLICATION FAILED TO START
***************************

Description:

Web server failed to start. Port 8080 was already in use.

Action:

Identify and stop the process using port 8080, or configure this application to listen on a different port.
```

Separating "produce the analysis" from "render the analysis" is deliberate — it's what lets tooling (an IDE plugin, a CI log parser) swap in a different `FailureAnalysisReporter` to consume the structured `FailureAnalysis` object programmatically instead of a formatted text blob, without touching any analyzer code.

## Writing your own analyzer

If you have a custom exception type in your own code that would benefit from a translated message — say, a config validation step you wrote yourself that throws on startup — you follow the exact same pattern:

```java
public class AcmeMisconfigurationException extends RuntimeException {
    private final String missingKey;
    public AcmeMisconfigurationException(String missingKey) {
        super("Acme module misconfigured");
        this.missingKey = missingKey;
    }
    public String getMissingKey() { return missingKey; }
}
```

```java
public class AcmeMisconfigurationAnalyzer
        extends AbstractFailureAnalyzer<AcmeMisconfigurationException> {

    @Override
    protected FailureAnalysis analyze(Throwable rootFailure, AcmeMisconfigurationException cause) {
        return new FailureAnalysis(
            "Required Acme property '" + cause.getMissingKey() + "' was not set.",
            "Add '" + cause.getMissingKey() + "' to your application.properties, " +
                "or set the corresponding environment variable."
        );
    }
}
```

Register it the same way as a custom auto-configuration class — a line in the `FailureAnalyzer.imports` file pointing at the fully-qualified class name. This is a genuinely useful pattern to pair with the custom starter you built in your last two lessons: a well-designed starter that throws a plain exception on bad config is only half as friendly as one that also ships an analyzer translating that exception into a clear fix.

## `ExitCodeGenerator`: what the process reports back to the OS

A related but separate piece: when startup fails (or a `CommandLineRunner` throws), Boot needs to decide what numeric exit code the JVM process returns — important for shell scripts, systemd (tying back to your systemd lesson), and CI pipelines checking `$?`. By default this is `1`, but you can customize it by implementing `ExitCodeGenerator` and registering it as a bean, or by having an exception implement `ExitCodeExceptionMapper` to map specific exception types to specific codes:

```java
@Bean
public ExitCodeGenerator exitCodeGenerator() {
    return () -> 42; // custom failure code for this app
}
```

This runs independently of failure analysis — you can have a perfectly readable failure message _and_ a meaningful exit code at the same time, since one affects what's printed and the other affects what the OS-level process status reports.

[[Spring Framework]]
