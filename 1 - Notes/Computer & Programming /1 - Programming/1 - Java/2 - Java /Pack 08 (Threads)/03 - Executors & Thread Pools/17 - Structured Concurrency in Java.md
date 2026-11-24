Structured concurrency is a fix for a problem that `ExecutorService` and raw threads never actually solved: when one logical task splits into several concurrent subtasks, nothing forces those subtasks to live and die together. With `ExecutorService`, if one subtask fails, the others keep running anyway unless you manually track and cancel them — and if the parent method returns early (exception, early return), orphaned threads can keep executing in the background with nobody watching them. Structured concurrency gives concurrent subtasks a single, enforced lifetime: they're opened in one block, and that block does not exit until every subtask inside it has finished — succeeded, failed, or been cancelled. The relationship between parent and subtasks becomes as disciplined as a normal method call tree, instead of being scattered across independently-managed threads.

**One important thing up front:** on JDK 25, this is still a **preview feature** (JEP 505, fifth preview round — it isn't finalized until JDK 28). To compile and run code using it, you need `--enable-preview` on both `javac` and `java`:

```
javac --release 25 --enable-preview Main.java
java --enable-preview Main
```

## The basic shape

```java
import java.util.concurrent.StructuredTaskScope;

try (var scope = StructuredTaskScope.open()) {

    StructuredTaskScope.Subtask<String> user  = scope.fork(() -> fetchUser(id));
    StructuredTaskScope.Subtask<Order>  order = scope.fork(() -> fetchOrder(id));

    scope.join();                 // waits for both subtasks, throws if either failed

    return new Profile(user.get(), order.get());

} // scope.close() runs automatically — guaranteed cleanup
```

Four pieces, in order:

- **`open()`** — opens the scope. It's a static factory method (there's no public constructor), and it's used in try-with-resources so `close()` is guaranteed.
- **`fork(Callable<U>)`** — starts a new thread for a subtask and immediately returns a `Subtask<U>` handle, _not_ the result. Each `fork` call creates one virtual thread by default.
- **`join()`** — blocks the owner thread until all subtasks finish (or the scope is cancelled some other way). This is the one place the "structure" is enforced: code after `join()` only runs once every forked subtask has completed.
- **`close()`** — runs automatically via try-with-resources. It cancels anything still unfinished and waits for every thread to actually terminate before letting execution continue past the block.

There's a strict rule worth knowing: `fork`, `join`, and `close` can only be called by the thread that opened the scope (the "owner thread"). Calling them from a subtask or a different thread throws `WrongThreadException`.

## `Subtask<T>` — what `fork` actually gives you

```java
public sealed interface Subtask<T> extends Supplier<T> {
    enum State { UNAVAILABLE, SUCCESS, FAILED }
    State state();
    T get();              // only valid after join(), if state is SUCCESS
    Throwable exception(); // only valid after join(), if state is FAILED
}
```

`get()` only works _after_ `join()` returns, and only if that specific subtask succeeded — calling it earlier, or on a failed subtask, throws `IllegalStateException`. This is deliberate: it stops you from accidentally reading a result that isn't ready yet.

## `Joiner` — the policy for how subtasks combine

This is the part that replaces what used to be subclassing `StructuredTaskScope` in earlier preview versions. A `Joiner<T, R>` decides what "waiting for subtasks" actually means, and produces whatever `join()` returns. `open()` with no arguments uses a default joiner; `open(Joiner)` lets you pick a different policy:

```java
Joiner.awaitAllSuccessfulOrThrow()   // default: wait for all, cancel+throw on first failure, join() returns null
Joiner.allSuccessfulOrThrow()        // same cancel-on-failure behavior, but join() returns Stream<Subtask<T>>
Joiner.anySuccessfulResultOrThrow()  // race: first success wins, others get cancelled, join() returns T directly
Joiner.awaitAll()                    // waits for everything, never cancels on failure, join() returns null
Joiner.allUntil(predicate)           // custom: cancel once your predicate says so
```

`awaitAllSuccessfulOrThrow()` (the default) is for subtasks of _different_ types, read individually via `subtask.get()` afterward. `allSuccessfulOrThrow()` is for subtasks that all return the _same_ type, where you want `join()` to hand you a stream directly:

```java
try (var scope = StructuredTaskScope.open(Joiner.<String>allSuccessfulOrThrow())) {
    scope.fork(() -> fetchFromMirrorA());
    scope.fork(() -> fetchFromMirrorB());

    List<String> results = scope.join().map(Subtask::get).toList();
}
```

A race between redundant calls — take whichever finishes first, cancel the rest — uses `anySuccessfulResultOrThrow()`:

```java
try (var scope = StructuredTaskScope.open(Joiner.<String>anySuccessfulResultOrThrow())) {
    scope.fork(() -> queryPrimary());
    scope.fork(() -> queryReplica());

    String firstResult = scope.join(); // whichever responds first; the other is interrupted
}
```

## Cancellation — what actually happens

When a `Joiner` decides the scope should cancel (e.g. one subtask failed, under a cancel-on-failure policy), three things happen immediately: no new subtasks can be forked, every thread running an unfinished subtask gets `interrupt()`ed, and `join()` wakes up with the outcome. This only works correctly if your subtask code actually responds to interruption — a subtask blocked on something non-interruptible can delay the scope's `close()` indefinitely, since `close()` always waits for every thread to actually finish, cancelled or not.

## Exception handling

If the joiner's policy produces an exception instead of a result, `join()` throws `StructuredTaskScope.FailedException`, wrapping the real cause:

```java
try (var scope = StructuredTaskScope.open()) {
    scope.fork(() -> riskyCall());
    scope.join();
} catch (StructuredTaskScope.FailedException e) {
    switch (e.getCause()) {
        case IOException io -> handleIo(io);
        default -> throw e;
    }
}
```

## Configuration — naming, thread factory, timeouts

The 2-arg `open(Joiner, Function<Configuration, Configuration>)` overload lets you customize the scope beyond the defaults (unnamed virtual threads, no timeout):

```java
Duration timeout = Duration.ofSeconds(10);

try (var scope = StructuredTaskScope.open(
        Joiner.<String>allSuccessfulOrThrow(),
        cf -> cf.withTimeout(timeout))) {

    scope.fork(callable1);
    scope.fork(callable2);

    List<String> results = scope.join().map(Subtask::get).toList();
}
```

If the timeout expires before `join()` finishes, the scope cancels and `join()` throws `StructuredTaskScope.TimeoutException` instead.

## Related, briefly: `ScopedValue`

`StructuredTaskScope` pairs naturally with `ScopedValue` (also a preview API) — a way to bind an immutable value to a thread for a bounded stretch of execution, instead of using a field or a `ThreadLocal`. When a subtask is forked inside a scope, it automatically inherits whatever `ScopedValue` bindings the owner thread had at that point, safely and without copying the value through constructor parameters. You don't need it to use structured concurrency, but it's the mechanism Java expects you to reach for instead of `ThreadLocal` when passing context (like a request ID) down into subtasks.


[[Java]]
