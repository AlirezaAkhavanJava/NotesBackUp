

## The mental model: a fire alarm, not a return value

Imagine a restaurant kitchen. A line cook (a method) discovers there are no eggs left. He has no authority to fix that. Without an alarm, he'd hand the next station a bogus dish and hope somebody notices, which is how old C code works: functions return `-1` or `null`, and every caller must remember to check.

Java's approach is different. The cook pulls an alarm and hands over a **report** saying what happened, where, and why. Normal work stops. The alarm travels **up the chain of command** (the call stack), and each level asks "can I handle this?" The first one that can, handles it. If nobody can, the whole kitchen shuts down (the thread dies).

An **exception is that report**: an object representing an abnormal event, plus the machinery that abandons normal control flow and delivers the object to whoever can deal with it.

## Mechanics

### 1. An exception is an ordinary object

Everything throwable descends from `java.lang.Throwable`:

```
Throwable
├── Error                  (JVM-level catastrophes: OutOfMemoryError, StackOverflowError)
└── Exception
    ├── IOException, SQLException, ...   (CHECKED)
    └── RuntimeException                 (UNCHECKED)
        ├── NullPointerException
        ├── IllegalArgumentException
        ├── IndexOutOfBoundsException
        └── ...
```

A `Throwable` carries four things: a **message**, a **cause** (another Throwable), a **stack trace** (the call path when it was created), and **suppressed exceptions** (more on that below).

### 2. Throwing and propagation

```java
public class Demo {
    public static void main(String[] args) {
        System.out.println("start");
        a();
        System.out.println("never printed");
    }
    static void a() { b(); }
    static void b() { throw new IllegalStateException("boom"); }
}
```

Output:

```
start
Exception in thread "main" java.lang.IllegalStateException: boom
    at Demo.b(Demo.java:8)
    at Demo.a(Demo.java:7)
    at Demo.main(Demo.java:4)
```

Here is what the JVM does at `throw`:

1. It looks in `b`'s **exception table** (a compiled-in list of "if the bytecode is in range X and the exception type is Y, jump to handler Z"). No match.
2. It **pops `b`'s stack frame** (stack unwinding) and repeats the search in `a`. No match.
3. Same for `main`. Still no match.
4. The exception reaches the top of the thread, so the thread's **uncaught exception handler** prints the stack trace and the thread terminates.

Read a stack trace **top to bottom as "where it happened, and who called whom"**: the top line is the throw site, the bottom is the entry point.

Note that `"never printed"` really never runs. Control doesn't return to the caller at all.

### 3. Catching it

```java
try {
    a();
} catch (IllegalStateException e) {
    System.out.println("handled: " + e.getMessage());
}
// execution continues here
```

The `try` block costs essentially **nothing at runtime** when no exception occurs, because the exception table is static data. The cost is paid only when something is thrown, mostly for capturing the stack trace.

## The checked vs. unchecked split

||Checked|Unchecked|
|---|---|---|
|Type|`Exception` and subclasses, **excluding** `RuntimeException`|`RuntimeException`, `Error` and subclasses|
|Compiler|Forces you to **catch or declare** (`throws`)|No enforcement|
|Meaning|"Foreseeable, possibly recoverable condition outside your control" (missing file, network failure)|"Bug in the program" (null deref, bad argument) or fatal JVM condition|

```java
void read() throws IOException {      // declares: callers must deal with it
    Files.readAllBytes(Path.of("x"));
}
```

**Why it works this way:** the designers wanted the _type system_ to make error handling part of a method's contract. `throws IOException` is as much a part of the signature as the return type. For things like `NullPointerException`, forcing a `try/catch` around every dereference would be absurd, since the fix is to correct the code, not handle the error.

**The honest caveat:** checked exceptions are contested. They don't compose with lambdas (`Stream.map(x -> Files.readString(x))` won't compile, because functional interfaces don't declare `throws`), they leak implementation details through layers, and they push people toward swallowing exceptions. Languages like C# and Kotlin dropped them. Most modern Java libraries and frameworks (Spring, for example) lean toward unchecked exceptions.

## The "why": exceptions versus error codes

- **The happy path stays readable.** Error handling lives in separate blocks instead of an `if (result == -1)` after every call.
- **They can't be silently ignored.** Forget to check a return code and the program continues in a corrupt state. Forget to handle an exception and the program fails loudly at the point of failure.
- **They carry context**: type, message, cause chain, location.
- **Propagation is automatic.** Intermediate methods that can't handle the problem don't need any code.

## Edge cases and gotchas

### Stack trace is captured at _construction_, not at `throw`

```java
Exception e = new Exception("x");   // trace records THIS line
doOtherStuff();
throw e;                            // trace still points at the line above
```

Capturing the trace (`fillInStackTrace()`) is the expensive part of an exception. High-performance code that uses exceptions for control flow sometimes uses the protected constructor `Throwable(message, cause, enableSuppression, writableStackTrace)` with `writableStackTrace = false`. Using exceptions for normal control flow is generally bad design, though.

### `finally` runs almost always, and can lie to you

```java
static int f() {
    try { return 1; }
    finally { return 2; }     // returns 2; the first return is discarded
}
```

```java
try { throw new A(); }
finally { throw new B(); }    // A is LOST; only B propagates
```

A `return` or `throw` inside `finally` **overrides** whatever was in flight. `finally` is skipped only if the JVM exits (`System.exit`, a crash) or the thread is killed or blocks forever inside the `try`.

### try-with-resources and suppressed exceptions

```java
try (var in = new FileInputStream("a")) {
    throw new RuntimeException("work failed");
}   // in.close() is called automatically, even on exception
```

If the body throws _and_ `close()` throws, the **body's exception is primary**, and the `close()` exception is attached via `e.getSuppressed()`. This fixes the lost-exception bug from the hand-written `finally` version above. It works for anything implementing `AutoCloseable`.

### Catch order and the "impossible catch"

```java
try { ... }
catch (Exception e) { }
catch (IOException e) { }   // COMPILE ERROR: already caught by the superclass
```

Always list **specific before general**. Also, catching a _checked_ exception that the `try` body cannot throw is a compile error (`catch (IOException e)` around code that doesn't throw it). That rule doesn't apply to `Exception` or `Throwable`, since unchecked subtypes could always occur.

Multi-catch handles unrelated types together: `catch (IOException | SQLException e)`. Types in a multi-catch can't be subclasses of each other, and `e` is effectively final.

### Overriding rules

An overriding method **cannot throw broader checked exceptions** than the method it overrides. Reason: callers program against the parent's contract. If `Parent.m()` declares `throws IOException` and `Child.m()` could throw `Exception`, code holding a `Parent` reference would face an exception it was never told about. Narrower, fewer, or unchecked ones are fine.

### Exception chaining: always keep the cause

```java
try {
    db.query();
} catch (SQLException e) {
    throw new ServiceException("could not load user", e);  // preserves root cause
}
```

Dropping `e` here destroys the real diagnostic information. The stack trace prints "Caused by: ..." sections for the chain.

### Things you generally shouldn't catch

- **`Error` and `Throwable`**: `OutOfMemoryError` and `StackOverflowError` can be caught, but the JVM state afterward may be unreliable.
- **Empty catch blocks**: `catch (Exception e) {}` swallows the evidence. At minimum, log it.
- **`InterruptedException`**: if you catch it and don't rethrow, **restore the flag** with `Thread.currentThread().interrupt()`. Catching clears the thread's interrupt status, and swallowing it makes the thread impossible to cancel cleanly.

### Other quirks worth knowing

- An exception in a **static initializer** is wrapped in `ExceptionInInitializerError`, and later uses of that class throw `NoClassDefFoundError`, which is confusing the first time you see it.
- An uncaught exception kills **only its own thread**. If other non-daemon threads are alive, the JVM keeps running.
- Since Java 15, NPE messages are descriptive by default (`Cannot invoke "String.length()" because "s" is null`).
- Java 7 added **precise rethrow**: in `catch (Exception e) { throw e; }`, the compiler knows the real types the `try` can throw, so your method only needs to declare those.

## How it connects to other concepts

- **The call stack**: exceptions are really about _unwinding_ it. Understanding frames makes stack traces and `StackOverflowError` obvious.
- **Type hierarchy and polymorphism**: `catch` matches by `instanceof`-style subtyping, and the overriding rules are Liskov substitution in action.
- **Resource management**: `AutoCloseable` and try-with-resources exist because exceptions make manual cleanup error-prone.
- **Threads**: uncaught-exception handlers, `Future.get()` wrapping failures in `ExecutionException`, and the interrupt mechanism.
- **Functional style**: the checked-exception/lambda friction is why people write wrapper utilities or use `Optional`/result types for expected failures.
- **Design**: the rule of thumb is to use exceptions for _exceptional_ situations, and return values (`Optional`, a result object) for expected outcomes like "key not found in map."





[[Java]]