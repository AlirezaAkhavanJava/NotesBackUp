
## Mental model

Unwinding was the _mechanism_ (popping frames, running cleanup). Propagation is the _contract and path_: which exceptions are allowed to travel up, how far they travel, and what happens to them on the way.

Think of a **bucket brigade passing a hot coal up a line of people**, each of whom is one method:

- Each person either has a fireproof pot (a matching `catch`) and stops the coal there, or passes it to the person behind them.
- For _checked_ exceptions the compiler is a safety inspector who insists every person write on their badge what kinds of coals they might pass along (`throws`). You can't pass a coal you didn't declare.
- For _unchecked_ exceptions there's no inspector. Anyone can pass any coal.
- The line is the **call chain at runtime**, not the order the code is written in the file.

## The core rule

When a method has no matching handler, it **completes abruptly** and the _same exception object_ is re-raised in the caller, at the call instruction. The caller's exception table is consulted. This repeats until a handler matches or the thread's stack is exhausted.

Two properties follow from this:

1. **Handler lookup is dynamic across methods but lexical within one.** Which `catch` runs depends on who called whom _this time_. Inside a single method, the exception table is fixed at compile time.
2. **It's the same object the whole way.** Its stack trace, set at construction, doesn't change as it propagates.

## Checked exceptions: propagation as a compile-time rule

```java
void a() throws IOException { b(); }   // must declare or catch
void b() throws IOException { c(); }
void c() throws IOException { throw new FileNotFoundException(); }
```

The compiler does flow analysis: for each statement it computes which checked exception types can escape, then requires each to be caught or declared by the enclosing method.

**Why it works this way:** the JVM doesn't enforce any of this. The `throws` list is stored in the class file's `Exceptions` attribute, but the verifier and interpreter ignore it. It exists for the compiler and for reflection. That is why bytecode, other JVM languages (Kotlin, Scala), and the sneaky-throw trick below can propagate checked exceptions with no declaration.

**Rules that fall out of the analysis:**

- **Overriding:** an overriding method may throw the same checked types, narrower ones, or none, but never broader ones. Callers compiled against the parent only prepared for the parent's list.
- **Catching a checked exception that the `try` can't throw is a compile error** (`catch (IOException e)` around code that throws no `IOException`). `catch (Exception e)` and `catch (Throwable e)` are exempt, since unchecked ones are always possible.
- **Static initializers** can't let checked exceptions escape, since no caller exists to receive them. **Instance initializers and field initializers** can throw checked ones only if every constructor declares them.
- **Constructors** propagate like methods, but a constructor that throws leaves a partially built object that is never returned. Its `finalize`/cleanup concerns are a separate topic.

## Precise rethrow (Java 7+)

```java
void m() throws IOException {           // declares only IOException, not Exception
    try {
        mayThrowIO();
    } catch (Exception e) {             // catches broadly...
        log(e);
        throw e;                        // ...but the compiler knows only IOException (or unchecked) is possible
    }
}
```

This works only if `e` is effectively final. The compiler tracks what the `try` can actually throw instead of using the declared catch type. If you reassign `e`, that precision is lost and you'd have to declare `Exception`.

## Propagation through cleanup constructs

- **`finally`:** runs, then the original exception continues, unless the `finally` itself throws, returns, `break`s, or `continue`s. Then the original is **replaced or swallowed**.
- **try-with-resources:** the body's exception stays primary. Exceptions from `close()` are attached with `addSuppressed` and visible via `getSuppressed()`. If the body succeeded and `close()` throws, _that_ exception propagates.
- **`synchronized`:** the monitor is released during propagation, so other threads aren't deadlocked by your exception.

## Translating exceptions at layer boundaries

Low-level exceptions often shouldn't leak upward. A repository layer shouldn't expose `SQLException` to the web layer.

```java
try {
    return jdbc.query(...);
} catch (SQLException e) {
    throw new DataAccessException("loading user " + id, e);   // keep the cause
}
```

The `cause` argument preserves the original trace as "Caused by:". Dropping it is one of the most common ways to make production bugs undiagnosable. Another common mistake is **log-and-rethrow** at every layer. It produces the same stack trace N times in the logs. Prefer to handle it where you can _do_ something, or log once at the boundary.

## Where propagation _stops_ or changes shape

|Boundary|What happens|
|---|---|
|**Thread**|Never propagates to the starter thread. Uncaught: printed by the thread's handler and the thread dies.|
|`ExecutorService.execute`|Goes to the uncaught-exception handler.|
|`ExecutorService.submit`|Captured in the `Future`. `get()` throws `ExecutionException` with it as the cause.|
|`CompletableFuture`|Stored in the future, wrapped in `CompletionException` for dependent stages. `get()` gives `ExecutionException`, `join()` gives `CompletionException`.|
|**Reflection** (`Method.invoke`)|Wrapped in `InvocationTargetException`. Call `getCause()` for the real one.|
|**Dynamic proxy**|If the handler throws a checked exception not declared by the interface method, it is wrapped in `UndeclaredThrowableException`.|
|**Class initialization**|Becomes `ExceptionInInitializerError`, and later uses give `NoClassDefFoundError`.|
|**Streams**|Lazy. An exception in a lambda surfaces at the _terminal operation_, not where you wrote the `map`. In parallel streams it may come from a worker thread and be rethrown in the caller.|
|**`main` thread**|If `main` ends with an uncaught exception, the JVM waits for other non-daemon threads, then exits with status 1.|

## Lambdas and checked exceptions

`Function.apply` doesn't declare `throws`, so a lambda body can't propagate a checked exception through it:

```java
list.stream().map(p -> Files.readString(p));   // compile error: IOException
```

Common fixes are wrapping in `UncheckedIOException`, or a custom functional interface that declares `throws E`.

**The sneaky-throw trick** exploits the fact that the JVM doesn't enforce `throws`:

```java
@SuppressWarnings("unchecked")
static <E extends Throwable> void sneaky(Throwable t) throws E {
    throw (E) t;     // cast is erased; nothing is checked at runtime
}
```

The compiler infers `E` as `RuntimeException`, so callers see no checked exception, but the real `IOException` propagates at runtime. It works, but it breaks callers' expectations, since they can't `catch` it without the compiler complaining that it's never thrown. Use it sparingly, if at all.

## `InterruptedException`: propagation with a catch

It's checked, so you must deal with it. The rule: either **propagate** it, or, if you must swallow it, **restore the flag**:

```java
catch (InterruptedException e) {
    Thread.currentThread().interrupt();   // blocking calls clear the flag when they throw
    // then bail out
}
```

Swallowing it silently breaks cancellation for everything above you in the chain.

## `Error` and `Throwable`

`Error` subclasses (`OutOfMemoryError`, `StackOverflowError`) propagate exactly like any other exception, and `catch (Throwable)` will catch them. After an `OutOfMemoryError`, program state may be inconsistent, so catching and continuing is usually unwise. The exception is a deliberate boundary, like a thread pool worker that logs and moves on.

## Related concepts

- **Unwinding** (previous topic): the frame-by-frame mechanism underneath propagation.
- **Exception chaining and suppression:** how propagation history is preserved.
- **Checked vs. unchecked design debate:** propagation is why checked exceptions are controversial. They force every layer in the chain to declare or wrap.
- **Uncaught-exception handlers:** the end of the line for propagation.
- **Structured concurrency (`StructuredTaskScope`):** a newer model where child-task failures _are_ propagated to the parent scope, fixing the thread-boundary gap.




[[Java]]