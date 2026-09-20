


## The four pieces, in one sentence each

- **`try`** — marks a block of code that might fail
- **`catch`** — handles a specific exception type if the `try` block throws it
- **`throw`** — manually raises an exception, right now, in your code
- **`throws`** — a method signature's declaration that it _might_ raise a checked exception, so callers know to handle it

---

## 1. Basic `try` / `catch`

```java
try {
    int result = 10 / 0;
} catch (ArithmeticException e) {
    System.out.println("Can't divide by zero: " + e.getMessage());
}
```

**Where to use it:** wrap only the specific lines that can actually fail — not your entire method. A `try` block that's too large makes it unclear which line actually threw, and can accidentally swallow unrelated bugs.

```java
// Too broad — unclear what actually failed if something goes wrong
try {
    validateInput(data);
    int result = riskyCalculation(data);
    saveToDatabase(result);
    sendConfirmationEmail();
} catch (Exception e) {
    System.out.println("Something failed");
}
```

```java
// Better — narrow, specific
validateInput(data);
try {
    int result = riskyCalculation(data);
    saveToDatabase(result);
} catch (ArithmeticException e) {
    System.out.println("Calculation error: " + e.getMessage());
}
sendConfirmationEmail();
```

---

## 2. Multiple `catch` blocks — order matters

```java
try {
    processFile("data.txt");
} catch (FileNotFoundException e) {         // most specific first
    System.out.println("File missing: " + e.getMessage());
} catch (IOException e) {                    // broader category second
    System.out.println("I/O problem: " + e.getMessage());
} catch (Exception e) {                      // catch-all last
    System.out.println("Unexpected error: " + e.getMessage());
}
```

**Rule:** subclasses must be caught **before** their parent classes. `FileNotFoundException` is a subclass of `IOException` — if you put `IOException` first, the compiler errors out, because that `catch` would swallow everything, making the more specific one unreachable.

---

## 3. Multi-catch — one block, multiple exception types (Java 7+)

**Problem it solves:** if two or more exception types need _identical_ handling, writing separate blocks with duplicated code is wasteful.

```java
// Before multi-catch — duplicated handling logic
try {
    riskyOperation();
} catch (IOException e) {
    logger.error("Operation failed", e);
    throw new ServiceException("Failed", e);
} catch (SQLException e) {
    logger.error("Operation failed", e);
    throw new ServiceException("Failed", e);
}
```

```java
// With multi-catch — one block, pipe-separated types
try {
    riskyOperation();
} catch (IOException | SQLException e) {
    logger.error("Operation failed", e);
    throw new ServiceException("Failed", e);
}
```

**Rules:**

- The types in a multi-catch **cannot** be subtype/supertype of each other (that would be redundant/ambiguous — just use the parent type alone).
- The caught variable (`e`) is implicitly `final` and its compile-time type is the **most specific common supertype** of the listed types — so you only get access to methods common to both.

**Where to use it:** whenever two+ unrelated exception types genuinely need the same response — very common when calling APIs that throw different checked exceptions for similar failure classes.

---

## 4. `finally` — guaranteed cleanup

```java
FileInputStream in = null;
try {
    in = new FileInputStream("data.txt");
    // use in
} catch (IOException e) {
    System.out.println("Failed: " + e.getMessage());
} finally {
    if (in != null) {
        try { in.close(); } catch (IOException e) { /* ignore */ }
    }
}
```

`finally` runs **no matter what** — whether the `try` succeeds, throws, or even `return`s early. It's the last thing that happens before control actually leaves.

**Where to use it directly:** rarely, in modern Java — see try-with-resources below, which replaces this pattern for anything `Closeable`. Use raw `finally` for cleanup that _isn't_ about closing a resource (e.g., resetting a flag, releasing a non-`Closeable` lock).

---

## 5. try-with-resources — the modern replacement for manual `finally` cleanup (Java 7+)

```java
try (FileInputStream in = new FileInputStream("data.txt")) {
    // use in
} catch (IOException e) {
    System.out.println("Failed: " + e.getMessage());
}
// in.close() called automatically — no finally needed
```

**Requirement:** the resource must implement `AutoCloseable` (or its subtype `Closeable`).

**Multiple resources — closed in reverse order automatically:**

```java
try (FileInputStream in = new FileInputStream("in.txt");
     FileOutputStream out = new FileOutputStream("out.txt")) {
    in.transferTo(out);
} catch (IOException e) {
    System.out.println("Copy failed: " + e.getMessage());
}
```

### Java 9 improvement: effectively-final resources

Originally, the resource _had_ to be declared inside the `try (...)` parentheses. Since Java 9, you can open it earlier and just reference it, as long as it's effectively final:

```java
FileInputStream in = new FileInputStream("data.txt"); // declared outside
try (in) {                                              // just referenced here
    // use in
} catch (IOException e) {
    System.out.println("Failed: " + e.getMessage());
}
```

**Where to use it:** whenever the resource was already created by other code (e.g., passed into your method) and you just need to guarantee it gets closed.

### Suppressed exceptions — a subtle but important detail

If the `try` block throws **and** closing the resource _also_ throws, you'd normally lose one of the two exceptions. Try-with-resources doesn't lose it — it attaches the close-failure as a **suppressed exception** on the primary one:

```java
try (var resource = new FaultyResource()) {
    throw new RuntimeException("Main failure");
} catch (RuntimeException e) {
    System.out.println("Primary: " + e.getMessage());
    for (Throwable suppressed : e.getSuppressed()) {
        System.out.println("Also failed while closing: " + suppressed.getMessage());
    }
}
```

This is genuinely useful in production debugging — you never silently lose the "close also failed" information the way manual `finally` blocks historically did.

---

## 6. `throw` — manually raising an exception

```java
void setAge(int age) {
    if (age < 0) {
        throw new IllegalArgumentException("Age cannot be negative: " + age);
    }
    this.age = age;
}
```

**Where to use it:** validating preconditions, signaling domain-specific failures (with custom exceptions, as covered earlier), or re-throwing after partially handling something.

### Rethrowing — Java 7's "more precise rethrow"

```java
void process() throws IOException, SQLException {
    try {
        doIoWork();
        doSqlWork();
    } catch (Exception e) {           // caught broadly...
        logger.error("Failed", e);
        throw e;                       // ...but the compiler knows this can ONLY be
                                        // IOException or SQLException (not any Exception),
                                        // because that's all that's possible in the try block
    }
}
```

Before Java 7, rethrowing a caught `Exception e` forced your method to declare `throws Exception` (too broad). Since Java 7, the compiler analyzes what could _actually_ be thrown inside the `try` and lets you declare only the real, specific checked types — as long as `e` isn't reassigned.

---

## 7. `throws` — declaring checked exceptions

```java
void readConfig(String path) throws IOException {
    FileReader reader = new FileReader(path); // can throw IOException
    // ...
}
```

**Where to use it:** on any method that calls something checked and **doesn't** want to catch it locally — pushing the responsibility to whoever calls _this_ method instead.

```java
void loadApp() {
    try {
        readConfig("app.conf"); // caller decides to handle it HERE instead
    } catch (IOException e) {
        System.out.println("Startup failed: " + e.getMessage());
    }
}
```

Chains of `throws` are normal — a method can call another `throws`-declaring method and just re-declare `throws` itself, deferring handling further up the call stack, until something finally has enough context to actually deal with the failure meaningfully.

---

## 8. Modern/recent additions relevant to exception handling (up to JDK 25)

### Helpful NullPointerExceptions (JEP 358, Java 14+, on by default since Java 15)

Historically, `NullPointerException` told you almost nothing:

```
Exception in thread "main" java.lang.NullPointerException
```

Modern JVMs (Java 14+ with the flag, default since 15) generate a precise message identifying exactly which variable was null:

```
Exception in thread "main" java.lang.NullPointerException:
    Cannot invoke "String.length()" because "user.name" is null
```

**Why this matters for your code:** you don't need to do anything special to get this — it's automatic — but it changes how you debug. NPEs are now often self-explanatory without needing a debugger session.

### Pattern matching in `catch` blocks (using `instanceof` patterns, Java 16+)

You can't pattern-match directly in a `catch(...)` clause, but once you catch a broad type, pattern matching (Java 16+) makes dispatching on the real type much cleaner than old-style casting:

```java
try {
    doWork();
} catch (Exception e) {
    if (e instanceof InsufficientFundsException ife) {
        System.out.println("Shortfall: " + ife.getRequestedAmount());
    } else if (e instanceof AccountFrozenException afe) {
        System.out.println("Frozen since: " + afe.getFrozenDate());
    } else {
        throw new RuntimeException(e);
    }
}
```

Compare to the old way, which needed an explicit cast after the `instanceof` check — pattern matching merges the check and the cast into one step, removing a whole line of boilerplate per branch.

### Switch pattern matching for exception dispatch (Java 21+, switch pattern matching finalized)

Since switch expressions gained pattern matching (finalized in Java 21), you can dispatch on exception type even more cleanly than if/else chains:

```java
try {
    doWork();
} catch (Exception e) {
    String message = switch (e) {
        case InsufficientFundsException ife -> "Shortfall: " + ife.getRequestedAmount();
        case AccountFrozenException afe -> "Frozen since: " + afe.getFrozenDate();
        default -> "Unexpected: " + e.getMessage();
    };
    System.out.println(message);
}
```

**Where this helps:** when you have many possible exception subtypes and want exhaustive, readable dispatch instead of a long `if/else instanceof` chain.

### Sealed exception hierarchies (using `sealed`, Java 17+)

You can combine `sealed` classes (finalized Java 17) with your custom exception hierarchy to make the compiler **enforce exhaustiveness** when pattern-matching on it — the compiler knows every possible subtype, so a `switch` over them doesn't even need a `default` branch if every case is covered:

```java
sealed abstract class BankingException extends Exception
    permits InsufficientFundsException, AccountFrozenException {
    protected BankingException(String message) { super(message); }
}

final class InsufficientFundsException extends BankingException {
    public InsufficientFundsException(String message) { super(message); }
}

final class AccountFrozenException extends BankingException {
    public AccountFrozenException(String message) { super(message); }
}
```

```java
try {
    doBankingWork();
} catch (BankingException e) {
    String result = switch (e) {
        case InsufficientFundsException ife -> "Not enough funds";
        case AccountFrozenException afe -> "Account frozen";
        // NO default needed — compiler knows these are the only two possible subtypes
    };
}
```

**Why this matters:** if you later add a third subtype (`AccountClosedException`) but forget to add a case for it in some `switch`, the compiler errors out immediately, instead of silently falling through to a `default` at runtime. This is a genuinely strong safety improvement for exception-heavy domain code.

### Structured concurrency and exception handling (preview feature, Java 21+, still evolving through 25)

When running multiple tasks concurrently via `StructuredTaskScope` (a preview API in recent JDKs), exception handling changes shape — instead of each thread's exception being isolated and easy to lose track of, structured concurrency ties a group of subtasks together so a failure in one can automatically cancel the others and propagate a single, well-defined exception to the parent. This is still a **preview feature** as of the most recent JDKs, so treat it as "worth knowing exists" rather than something to rely on in production code yet — check the current JDK release notes before using it, since preview APIs can still change.

---

## Quick reference: what to use where

|Situation|Use|
|---|---|
|Code might fail, you want to handle it locally|`try` / `catch`|
|Two+ exception types need identical handling|multi-catch (`catch (A \| B e)`)|
|Resource needs guaranteed closing|try-with-resources|
|Cleanup unrelated to closing a resource|`finally`|
|You want to signal a failure yourself|`throw`|
|You don't want to handle it here, push it to the caller|`throws` in method signature|
|Dispatching behavior based on which exception subtype you caught|`instanceof` pattern matching, or switch pattern matching (Java 21+)|
|You control the full exception family and want compiler-enforced completeness|`sealed` exception hierarchy + switch|


[[Java]]