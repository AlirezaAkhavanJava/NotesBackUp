

## 1. The mental model

Think of a **kitchen in a restaurant**. A cook (your method) is preparing a dish and discovers there's no flour. They can't continue, so they **shout up the chain**: cook → head chef → manager. Whoever knows how to handle it (order more flour, change the menu) does so. If nobody does, the restaurant closes (the program crashes).

An exception is that shout. Java's machinery has two jobs:

1. **Interrupt normal flow** the moment something goes wrong (`throw`).
2. **Travel up the call stack** until someone handles it (`catch`).

```java
public static void main(String[] args) {
    a();                       // main -> a -> b -> c
}
static void a() { b(); }
static void b() { c(); }
static void c() { throw new IllegalStateException("boom"); }
// Nobody catches it, so it unwinds c -> b -> a -> main -> JVM prints the stack trace and exits
```

This unwinding is called **stack unwinding**. Everything after the `throw` in each frame is skipped.

---

## 2. The hierarchy

```
Throwable
├── Error                      (JVM-level disasters: OutOfMemoryError, StackOverflowError)
└── Exception
    ├── IOException, SQLException, ...     ← CHECKED
    └── RuntimeException                    ← UNCHECKED
        ├── NullPointerException
        ├── IllegalArgumentException
        ├── IllegalStateException
        ├── IndexOutOfBoundsException
        └── ArithmeticException ...
```

|Kind|Compiler forces you to handle?|Meaning|Examples|
|---|---|---|---|
|**Error**|No|Don't catch; the JVM is in trouble|`OutOfMemoryError`|
|**Checked** (`Exception` but not `RuntimeException`)|**Yes** (catch or declare with `throws`)|Recoverable, _expected_ external failures|`IOException`, `SQLException`|
|**Unchecked** (`RuntimeException`)|No|Usually **programmer bugs** or violated contracts|`NullPointerException`, `IllegalArgumentException`|

**Why this split exists:** Checked exceptions model things outside your control (file missing, network down), so the compiler makes the caller face them. Unchecked ones model bugs. You fix the code rather than "handle" them.

> **Modern reality:** Many modern frameworks, **Spring included**, favor unchecked exceptions, because checked ones clutter every signature up the chain. Spring even wraps `SQLException` into unchecked `DataAccessException`. Know both; lean unchecked for your own application exceptions.

---

## 3. The handling toolbox

### 3.1 `try / catch`

```java
try {
    int result = 10 / divisor;
    System.out.println(result);
} catch (ArithmeticException e) {
    System.out.println("Cannot divide by zero: " + e.getMessage());
}
```

**Multiple catches: order matters, specific first, general last.** The first matching block wins, and the compiler rejects unreachable ones.

```java
try {
    Files.readAllLines(Path.of("data.txt"));
} catch (NoSuchFileException e) {       // subclass of IOException, so it must come first
    System.out.println("File missing");
} catch (IOException e) {
    System.out.println("Other I/O problem");
}
// Reversing the order is a COMPILE ERROR: the IOException catch would shadow the other
```

**Multi-catch** (same handling for unrelated types):

```java
try {
    process();
} catch (IllegalArgumentException | IllegalStateException e) {
    log.warn("Bad input or state", e);
}
// Types can't be related by inheritance (e.g. IOException | Exception won't compile)
```

### 3.2 `finally`: cleanup that always runs

```java
Connection conn = null;
try {
    conn = dataSource.getConnection();
    // work...
} catch (SQLException e) {
    log.error("DB failure", e);
} finally {
    if (conn != null) {
        try { conn.close(); } catch (SQLException ignored) {}
    }
}
```

`finally` runs on normal completion, on a caught exception, on an uncaught exception, and even on `return`. It does **not** run if the JVM dies (`System.exit()`, crash, power loss).

That ceremony is ugly, which is why 3.3 exists.

### 3.3 `try-with-resources`: the proper way to handle cleanup

Any class implementing `AutoCloseable` is closed automatically, in **reverse order of declaration**, even if an exception occurs.

```java
try (BufferedReader reader = Files.newBufferedReader(Path.of("data.txt"));
     BufferedWriter writer = Files.newBufferedWriter(Path.of("out.txt"))) {

    String line;
    while ((line = reader.readLine()) != null) {
        writer.write(line.toUpperCase());
        writer.newLine();
    }
} catch (IOException e) {
    log.error("File processing failed", e);
}
// writer closes first, then reader, no finally needed
```

**Why it's better than manual `finally`:** if the body throws _and_ `close()` throws, the old pattern **loses the original exception**. try-with-resources keeps the body's exception as primary and attaches the close failure as a **suppressed** exception:

```java
catch (Exception e) {
    for (Throwable s : e.getSuppressed()) {
        System.out.println("Also failed during close: " + s);
    }
}
```

**Rule:** if it's closeable (streams, connections, scanners, `ExecutorService` in newer Java), use try-with-resources.

### 3.4 `throw`: raising an exception

```java
public void withdraw(double amount) {
    if (amount <= 0) {
        throw new IllegalArgumentException("Amount must be positive, got: " + amount);
    }
    if (amount > balance) {
        throw new IllegalStateException("Insufficient funds");
    }
    balance -= amount;
}
```

Write messages that include the **offending value and context**. You'll thank yourself at 3 AM reading logs.

### 3.5 `throws`: declaring instead of handling

If you can't meaningfully handle a checked exception, **pass the responsibility up**:

```java
public String readConfig(Path path) throws IOException {   // caller must deal with it
    return Files.readString(path);
}
```

**Who should handle it?** The layer that has enough context to _do something useful_ (retry, fallback, show a message). A low-level method rarely knows what the user should be told, so let it propagate.

### 3.6 Custom exceptions

```java
// Unchecked: preferred for application/business errors
public class InsufficientFundsException extends RuntimeException {
    private final double shortfall;

    public InsufficientFundsException(double shortfall) {
        super("Insufficient funds, short by " + shortfall);
        this.shortfall = shortfall;
    }

    public InsufficientFundsException(String message, Throwable cause) {
        super(message, cause);
        this.shortfall = 0;
    }

    public double getShortfall() { return shortfall; }
}

// Checked: only when the caller can and must realistically recover
public class ConfigLoadException extends Exception {
    public ConfigLoadException(String message, Throwable cause) {
        super(message, cause);
    }
}
```

Always provide a constructor accepting a `cause`. You'll need it for chaining.

### 3.7 Exception chaining: wrap, never lose the cause

Translate low-level exceptions into ones that make sense at your layer, **but keep the original as the cause**.

```java
public User findUser(long id) {
    try {
        return repository.load(id);                       // throws SQLException
    } catch (SQLException e) {
        throw new UserLookupException("Could not load user " + id, e);  // cause preserved
    }
}
```

The stack trace then shows `Caused by: java.sql.SQLException ...`, which is the real root of the problem.

**Anti-pattern:** `throw new UserLookupException(e.getMessage());` loses the cause and the original stack trace.

### 3.8 Rethrowing

```java
try {
    riskyOperation();
} catch (IOException e) {
    log.error("Failed during riskyOperation", e);
    throw e;            // rethrow as-is; Java even lets you rethrow precisely (the exact type)
}
```

Be careful: **log OR rethrow, not both** (see anti-patterns below).

---

## 4. Putting it together: a realistic example

```java
public class OrderService {

    private static final Logger log = LoggerFactory.getLogger(OrderService.class);

    public Order placeOrder(OrderRequest request) {
        // 1. Validate early (fail fast) with unchecked exceptions
        Objects.requireNonNull(request, "request must not be null");
        if (request.quantity() <= 0) {
            throw new IllegalArgumentException("Quantity must be > 0, got " + request.quantity());
        }

        // 2. Business rule violation -> custom exception
        Product product = productRepository.findById(request.productId())
                .orElseThrow(() -> new ProductNotFoundException(request.productId()));

        if (product.stock() < request.quantity()) {
            throw new OutOfStockException(product.id(), request.quantity(), product.stock());
        }

        // 3. External failure -> translate and keep the cause
        try {
            paymentGateway.charge(request.paymentToken(), product.price() * request.quantity());
        } catch (GatewayTimeoutException e) {
            throw new PaymentFailedException("Payment gateway timed out", e);
        }

        return orderRepository.save(new Order(product, request.quantity()));
    }
}
```

Notice the pattern: **validate at the top, throw specific exceptions, wrap with cause at boundaries, catch only where you can act.**

---

## 5. Best practices

**Do:**

- **Catch specific exceptions**, not `Exception`.
- **Fail fast**: validate arguments at the start of methods.
- **Include context** in messages (IDs, values).
- **Preserve the cause** when wrapping.
- **Use try-with-resources** for anything closeable.
- **Handle at the right layer**: where you can recover or report meaningfully.
- Prefer standard exceptions (`IllegalArgumentException`, `IllegalStateException`, `UnsupportedOperationException`, `NoSuchElementException`) before inventing new ones.
- Use `Optional` for "might legitimately be absent" instead of throwing or returning null.

**Don't (anti-patterns):**

```java
// ❌ 1. Swallowing: the worst sin; bugs become invisible
try { doWork(); } catch (Exception e) { }

// ❌ 2. Printing instead of logging, then continuing as if nothing happened
catch (Exception e) { e.printStackTrace(); }

// ❌ 3. Catching Throwable/Exception broadly (also catches things you can't handle)
catch (Throwable t) { ... }

// ❌ 4. Log AND rethrow: the same error gets logged multiple times up the stack
catch (IOException e) { log.error("failed", e); throw e; }
// Pick one: handle it (and log), or propagate it (and let the top-level handler log)

// ❌ 5. Using exceptions for normal control flow (slow and confusing)
try { while (true) { list.get(i++); } } catch (IndexOutOfBoundsException e) { }

// ❌ 6. Losing the cause
throw new RuntimeException("failed");           // original is gone
// ✅ throw new RuntimeException("failed", e);

// ❌ 7. Returning null / error codes instead of throwing or using Optional
```

---

## 6. Gotchas and edge cases

**Gotcha 1: `return` in `finally` overrides everything and swallows exceptions.**

```java
static int bad() {
    try {
        throw new RuntimeException("lost forever");
    } finally {
        return 42;        // exception silently discarded, method returns 42
    }
}
```

Never `return` (or `throw`) from `finally`.

**Gotcha 2: an exception in `finally` masks the original.**

```java
try {
    throw new IOException("original");
} finally {
    throw new RuntimeException("from finally");   // "original" is lost
}
```

Another reason to prefer try-with-resources.

**Gotcha 3: `InterruptedException`: never swallow it.** It signals a thread was asked to stop.

```java
try {
    Thread.sleep(1000);
} catch (InterruptedException e) {
    Thread.currentThread().interrupt();   // restore the flag so callers can see it
    throw new IllegalStateException("Interrupted while waiting", e);
}
```

**Gotcha 4: catching `StackOverflowError` / `OutOfMemoryError`.** Technically possible, almost never wise. State may be corrupt.

**Gotcha 5: overriding methods can't widen checked exceptions.** An override may throw the same, narrower, or fewer checked exceptions than the parent method, but not broader ones. (Unchecked ones are unrestricted.)

**Gotcha 6: lambdas and checked exceptions don't mix.** `list.forEach(x -> Files.readString(x))` won't compile because `forEach` doesn't declare `IOException`. Wrap it:

```java
paths.forEach(p -> {
    try {
        Files.readString(p);
    } catch (IOException e) {
        throw new UncheckedIOException(e);    // built-in unchecked wrapper
    }
});
```

**Gotcha 7: cost.** Creating an exception captures the stack trace, which is comparatively expensive. Fine for exceptional events, bad as a normal control-flow mechanism in hot loops.

**Gotcha 8: `catch (Exception e)` also catches `RuntimeException`s**, hiding bugs like NPEs that should crash loudly in development.

---

## 7. Connection to Spring Boot (where you're heading)

In a Spring Boot app, you don't `try/catch` in every controller. Instead you **throw meaningful unchecked exceptions from services** and handle them **centrally** in one place:

```java
// Custom exception
public class ProductNotFoundException extends RuntimeException {
    public ProductNotFoundException(Long id) {
        super("Product not found: " + id);
    }
}

// Central handler for ALL controllers
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ProductNotFoundException.class)
    public ResponseEntity<ApiError> handleNotFound(ProductNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ApiError("NOT_FOUND", ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex) {
        String msg = ex.getBindingResult().getFieldErrors().stream()
                .map(f -> f.getField() + ": " + f.getDefaultMessage())
                .collect(Collectors.joining(", "));
        return ResponseEntity.badRequest().body(new ApiError("VALIDATION_FAILED", msg));
    }

    @ExceptionHandler(Exception.class)               // last-resort safety net
    public ResponseEntity<ApiError> handleAny(Exception ex) {
        log.error("Unexpected error", ex);           // log once, here
        return ResponseEntity.status(500).body(new ApiError("INTERNAL_ERROR", "Something went wrong"));
    }
}

public record ApiError(String code, String message) {}
```

This is the payoff of everything above: services stay clean (`throw`), the handler translates exceptions to HTTP responses and logs once, and nothing is swallowed. Also note: Spring's `@Transactional` rolls back on **unchecked** exceptions by default, which is another reason the unchecked style dominates there.

---

## 8. Quick decision guide

|Situation|What to do|
|---|---|
|Bad method argument|`throw new IllegalArgumentException(...)`|
|Object in wrong state|`throw new IllegalStateException(...)`|
|Business rule violated|Custom unchecked exception|
|Using a closeable resource|try-with-resources|
|Checked exception you can't handle|Declare `throws`, or wrap in an unchecked exception with the cause|
|Need guaranteed non-resource cleanup|`finally`|
|Value might legitimately be absent|`Optional`, not an exception|
|Catching at top level (web app, thread)|One central handler: log once, return a clean error|




[[Java]]