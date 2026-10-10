
Java has several **built-in enums** that you can use directly without defining your own `enum`.

### Common built-in enums

| Enum                 | Package                | Example                               |
| -------------------- | ---------------------- | ------------------------------------- |
| `DayOfWeek`          | `java.time`            | `DayOfWeek.MONDAY`                    |
| `Month`              | `java.time`            | `Month.OCTOBER`                       |
| `MonthDay`           | `java.time`            | `MonthDay.of(10, 4)`                  |
| `ChronoUnit`         | `java.time.temporal`   | `ChronoUnit.DAYS`                     |
| `TimeUnit`           | `java.util.concurrent` | `TimeUnit.SECONDS`                    |
| `Thread.State`       | `java.lang`            | `Thread.State.RUNNABLE`               |
| `ElementType`        | `java.lang.annotation` | `ElementType.METHOD`                  |
| `RetentionPolicy`    | `java.lang.annotation` | `RetentionPolicy.RUNTIME`             |
| `StandardCopyOption` | `java.nio.file`        | `StandardCopyOption.REPLACE_EXISTING` |
| `FileVisitResult`    | `java.nio.file`        | `FileVisitResult.CONTINUE`            |
| `HttpClient.Version` | `java.net.http`        | `HttpClient.Version.HTTP_2`           |

### 1. `DayOfWeek`

```java
import java.time.DayOfWeek;

DayOfWeek day = DayOfWeek.MONDAY;

System.out.println(day);
```

Output:

```text
MONDAY
```

You can compare it:

```java
if (day == DayOfWeek.MONDAY) {
    System.out.println("Start of the week");
}
```

---

### 2. `Month`

```java
import java.time.Month;

Month month = Month.OCTOBER;

System.out.println(month);
System.out.println(month.getValue());
```

Output:

```text
OCTOBER
10
```

---

### 3. `ChronoUnit`

Very useful for date/time calculations:

```java
import java.time.temporal.ChronoUnit;

long days = ChronoUnit.DAYS.between(start, end);
```

Some available values:

```java
ChronoUnit.NANOS
ChronoUnit.MICROS
ChronoUnit.MILLIS
ChronoUnit.SECONDS
ChronoUnit.MINUTES
ChronoUnit.HOURS
ChronoUnit.DAYS
ChronoUnit.WEEKS
ChronoUnit.MONTHS
ChronoUnit.YEARS
```

---

### 4. `TimeUnit`

Useful for concurrency/thread operations:

```java
import java.util.concurrent.TimeUnit;

TimeUnit.SECONDS.sleep(5);
```

Other values:

```java
TimeUnit.NANOSECONDS
TimeUnit.MICROSECONDS
TimeUnit.MILLISECONDS
TimeUnit.SECONDS
TimeUnit.MINUTES
TimeUnit.HOURS
TimeUnit.DAYS
```

---

### 5. `Thread.State`

Java's `Thread` class contains an enum:

```java
Thread.State state = Thread.State.RUNNABLE;
```

Possible states include:

```java
Thread.State.NEW
Thread.State.RUNNABLE
Thread.State.BLOCKED
Thread.State.WAITING
Thread.State.TIMED_WAITING
Thread.State.TERMINATED
```

This is particularly useful when learning JVM/concurrency internals.

### Important distinction

An enum doesn't have to be something you define yourself.

Java itself uses enums extensively:

```java
public enum DayOfWeek {
    MONDAY,
    TUESDAY,
    // ...
}
```

So when you see something like:

```java
DayOfWeek.MONDAY
```

you're using an **enum type from the Java standard library**.

For backend development, the most important built-in enums to know are probably **`DayOfWeek`, `Month`, `ChronoUnit`, `TimeUnit`, `HttpClient.Version`, `Thread.State`, `Locale.Category`, and the annotation-related enums**.


[[Java]]