# Exceptions in practice: what goes in `try`, `catch`, and what to log

## 1. First, a small correction to the mental model

Exceptions cover **two different situations**, and your question mixes them:

|Situation|Example|What you do|
|---|---|---|
|**A. Bug in your code**|`NullPointerException`, `IndexOutOfBoundsException`|**Don't handle it. Fix the code.** The exception and its stack trace are your diagnostic tool.|
|**B. Expected failure outside your control**|File missing, network down, user typed bad input, DB unavailable|**Handle it** (recover, retry, or report). The code is correct; the world misbehaved.|

**Analogy:** a smoke alarm versus a fire extinguisher.

- The stack trace is the **smoke alarm**: it tells you where the fire is so you can fix the wiring (situation A).
- `catch` is the **extinguisher**: use it only when you actually know how to put out _this particular_ fire (situation B).

So **catching an exception is not how you fix a bug**. You fix a bug by reading the stack trace, finding the line, and changing the code. A `catch` block that hides a bug makes things worse, because the alarm is silenced and the fire keeps burning.

---

## 2. What goes in the `try` block

Only the **smallest piece of code that can throw the exception you're handling**.

```java
// ❌ Too wide: which line failed? What are we even handling?
try {
    String name = request.getName().trim();
    Path path = Path.of("data/" + name + ".txt");
    String content = Files.readString(path);   // the only line that can throw IOException
    int count = content.split(",").length;
    System.out.println(count);
} catch (Exception e) { ... }

// ✅ Tight: only the risky call is inside
String content;
try {
    content = Files.readString(path);
} catch (NoSuchFileException e) {
    // we know exactly what happened
}
```

**Why:** a wide `try` can accidentally catch bugs (like a `NullPointerException` from `request.getName()`) and treat them as if they were a missing file.

---

## 3. What goes in the `catch` block

A `catch` block is legitimate only if it does **one of these four things**. If it does none, don't catch at all and let the exception travel up.

### Action 1: Recover (retry, fallback, default value)

```java
try {
    return Files.readString(configPath);
} catch (NoSuchFileException e) {
    log.warn("Config {} not found, using defaults", configPath);   // note it, then recover
    return DEFAULT_CONFIG;
}
```

### Action 2: Translate (wrap into a meaningful exception and keep the cause)

```java
try {
    return repository.load(id);
} catch (SQLException e) {
    throw new UserLookupException("Could not load user " + id, e);   // e = the cause
}
```

### Action 3: Report at the boundary (the top layer: log once, give a clean response)

```java
@ExceptionHandler(Exception.class)
public ResponseEntity<ApiError> handleAny(Exception ex) {
    log.error("Unexpected error", ex);
    return ResponseEntity.status(500).body(new ApiError("INTERNAL_ERROR", "Something went wrong"));
}
```

### Action 4: Cleanup

Prefer **try-with-resources** over a manual `finally`, as covered earlier.

### The decision test

> _"Do I know something useful to do right here?"_  
> **Yes** → catch it. **No** → let it propagate to a layer that does.

---

## 4. Which components should you use?

|Component|Purpose|
|---|---|
|**A logger (SLF4J)**|Record what happened, with context and the stack trace|
|**Custom exceptions**|Name business problems (`OutOfStockException`)|
|**try-with-resources**|Automatic cleanup of streams and connections|
|**Input validation (fail fast)**|Catch bad input at the start with `IllegalArgumentException`|
|**`Optional`**|"Might be absent" without throwing|
|**Central handler** (`@RestControllerAdvice` in Spring)|One place that turns exceptions into responses|

---

## 5. What should the message say?

Every exception has **two audiences** with different needs:

|Audience|Needs|Where it goes|
|---|---|---|
|**Developer** (you at 3 AM)|Exactly what failed, with which values, and the cause|Exception message + log|
|**End user**|Something calm and actionable, with no internals|HTTP response / UI|

**A good developer message answers: what operation, on what data, and why it failed.**

```java
// ❌ Useless
throw new RuntimeException("Error");
throw new RuntimeException("Something went wrong");

// ✅ Useful
throw new OrderNotFoundException("Order not found: id=" + orderId);
throw new IllegalArgumentException("Quantity must be > 0, got: " + quantity);
```

**User-facing** (never expose stack traces, SQL, or file paths):

```java
// ❌ "java.sql.SQLException: Connection refused at 10.0.0.5:5432 user=admin"
// ✅ "We couldn't process your request right now. Please try again later."
```

**Never put secrets in messages or logs:** passwords, tokens, full card numbers.

---

## 6. Logger or `System.out.println`?

**Always a logger** in real applications.

**Why `System.out` is a poor tool:**

- No **timestamp**, **class name**, or **thread** information.
- No **severity levels**, so you can't separate "FYI" from "disaster".
- You can't turn it down in production or up when debugging, without editing code.
- It can't route to files, log aggregators, or alerting systems.
- In production (servers, containers) there's often **no terminal** to watch.
- `e.printStackTrace()` is the same problem, going to `System.err`.

**Exception:** a small console app that talks to a user (menus, prompts, results) legitimately uses `System.out`. That's _program output_, not _diagnostics_.

### How to use SLF4J properly

In **Spring Boot**, a logger (SLF4J with Logback) is **already included**, so you just use it. In plain Java, add an SLF4J implementation such as Logback as a dependency.

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class OrderService {
    private static final Logger log = LoggerFactory.getLogger(OrderService.class);

    public void process(long orderId) {
        log.info("Processing order {}", orderId);                  // {} = placeholder

        try {
            gateway.charge(orderId);
        } catch (GatewayTimeoutException e) {
            log.error("Payment failed for order {}", orderId, e);  // exception LAST
            throw new PaymentFailedException("Payment failed for order " + orderId, e);
        }
    }
}
```

**Two rules people get wrong:**

```java
// ❌ Loses the stack trace (only the message text is kept)
log.error("Payment failed: " + e.getMessage());

// ✅ Pass the exception object as the LAST argument: full stack trace is logged
log.error("Payment failed for order {}", orderId, e);
```

and use `{}` placeholders instead of string concatenation (`+`), because they skip building the string when that level is disabled.

### Log levels

|Level|Use for|
|---|---|
|`ERROR`|Something failed and needs attention (unexpected exceptions)|
|`WARN`|Something odd happened, but you recovered (fallback used)|
|`INFO`|Normal important events (order placed, app started)|
|`DEBUG`|Detailed diagnostic info for development|

---

## 7. One complete before/after

```java
// ❌ Typical beginner code
public String readUserFile(String name) {
    try {
        return Files.readString(Path.of("users/" + name));
    } catch (Exception e) {
        System.out.println("error");        // no info, no stack trace
        return null;                         // caller will NPE later, far from the real cause
    }
}
```

```java
// ✅ Proper
public String readUserFile(String name) {
    Objects.requireNonNull(name, "name must not be null");          // fail fast on bugs
    Path path = Path.of("users", name);

    try {
        return Files.readString(path);                              // only the risky line
    } catch (NoSuchFileException e) {
        throw new UserFileNotFoundException("User file not found: " + path, e);   // specific + cause
    } catch (IOException e) {
        throw new UncheckedIOException("Failed reading user file: " + path, e);   // wrap, keep cause
    }
    // No logging here: the top-level handler logs once
}
```

Notice there's no `catch (Exception)`, no `null` return, and no logging in the middle. Logging happens **once, at the boundary**.

---

## 8. Your workflow when an unexpected exception appears

1. **Read the stack trace top to bottom.** The first line that mentions _your_ package is usually where to look.
2. **Reproduce it**, then fix the actual code (the null check, the index, the logic).
3. **Add a test** so it can't come back.
4. Only then ask: _"Could this also legitimately happen in real life?"_ If yes (bad input, network), add proper validation or handling.

**Summary in one sentence:** _catch only what you can meaningfully handle, put only the risky line in `try`, write messages with the context a future-you needs, log with a logger (once, with the exception as the last argument), and fix bugs by reading stack traces, not by catching them._




[[Exception]]
[[Java]]