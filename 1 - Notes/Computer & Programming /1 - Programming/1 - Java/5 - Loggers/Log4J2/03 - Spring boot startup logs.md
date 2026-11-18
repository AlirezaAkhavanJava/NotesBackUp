


Every line Spring Boot writes to the console during startup (and afterward) is a log entry, and Spring Boot configures Logback with a default _pattern_ that lays each entry out in fixed columns — timestamp, level, process id, thread, logger, message. It looks dense at first, but it's not random: each piece answers a specific question about that event, and once you know the format you can read any log line, from any Spring Boot app, at a glance.

Here's a real line from a startup, which we'll take apart piece by piece:

```
2026-11-18 14:32:07.112  INFO 8421 --- [           main] com.me.demo.DemoApplication             : Starting DemoApplication using Java 25
```

## The Pattern, Piece by Piece

**`2026-11-18 14:32:07.112`** — the timestamp, down to the millisecond. This is _when_ the event happened, which is the whole reason logs are useful after the fact: if something broke at 14:32:07, you scan for entries around that exact moment instead of guessing.

**`INFO`** — the log level. It tells you how significant this entry is. Spring Boot's defaults, from least to most severe, are `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`. `INFO` is routine status ("here's what's happening"); `WARN` means something's off but recoverable; `ERROR` means something failed. Logback pads this field to a fixed width (5 characters) purely so every column lines up vertically — that's why you'll sometimes see an extra space before `INFO` but not before `ERROR`.

**`8421`** — the process id (PID) of the JVM running your app. This is the operating-system-level id you'd use with `kill 8421` or look for in `ps aux`. It matters most when you're running several instances of the same app and need to tell their log output apart, or when correlating console output with a crash dump or a `jstack` thread dump taken against that specific process.

**`---`** — a plain visual separator. It carries no information; it just gives your eye a consistent break between the "metadata" columns on the left and the "where/what" columns on the right.

**`[ main]`** — the name of the thread that logged this line, in brackets. Logback right-aligns and pads/truncates this to a fixed width (15 characters by default), which is why short names like `main` get a lot of leading spaces. During startup almost everything runs on the `main` thread; once the app is serving HTTP requests you'll start seeing thread names like `[nio-8080-exec-3]` — each incoming request is handled by a worker thread from Tomcat's pool, and this field tells you which one.

**`com.me.demo.DemoApplication`** — the _logger name_, almost always the fully qualified class name that produced the log entry. This is how you know _where in the code_ the message came from. Spring Boot's default pattern caps this field at 40 characters; if a package path is longer than that, Logback abbreviates the package segments down to a single letter each to make it fit — so `org.springframework.boot.SpringApplication` becomes something like `o.s.b.SpringApplication` in the output. It's the same class, just compressed to keep the columns aligned.

**`: Starting DemoApplication using Java 25`** — the actual message, the one part of the line a developer wrote by hand (everything before it, Logback generated automatically). This is the "what happened," in plain text.

## One Thing Worth Noticing

Only the message is free text — every other column is structured and predictable, which is exactly what makes logs searchable and filterable instead of being just scrollback text. A tool parsing thousands of these lines doesn't need to guess where the timestamp ends and the level begins; the format is fixed, so it can split on those columns reliably. That structure is also _why_ Spring Boot can let you turn a logger's output up or down (`logging.level.com.me.demo=DEBUG`) by matching on that logger-name column specifically, without touching anything else in the line.
[[Logger]]