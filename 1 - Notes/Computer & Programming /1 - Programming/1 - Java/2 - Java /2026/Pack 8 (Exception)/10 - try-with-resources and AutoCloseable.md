

## The mental model: a rental counter with a limited pool

Picture a workshop where tools come from a rental counter with a limited stock: file handles, database connections, sockets, locks. You borrow a tool, use it, and must return it. Each unreturned tool shrinks the pool for everyone, and when the pool runs dry, the whole workshop stalls.

The garbage collector is the cleaning crew, and it only sweeps up **memory**. It doesn't know about the rental counter, and it runs whenever it likes. A file descriptor leaked on Monday might not be reclaimed until Friday, or ever, if memory is plentiful. So returning the tool is **your** job.

The hard part is returning it **no matter how you leave the room**: normal exit, an exception, an early `return`. try-with-resources fixes the tool to a **spring-loaded leash** that retracts when you leave the block, however you leave it.

> **A resource is anything that must be explicitly released. try-with-resources guarantees the release, in the right order, without losing error information.**

## The problem it solves

Here is the pre-Java-7 pattern:

```java
InputStream in = null;
try {
    in = new FileInputStream("data.bin");
    process(in);                  // throws IOException("bad format")
} finally {
    if (in != null) {
        in.close();               // ALSO throws IOException("disk error")
    }
}
```

There are three problems:

1. **Masked exceptions.** If `process` throws and then `close` throws in `finally`, the `finally` exception **replaces** the original. You see "disk error" and never learn about "bad format," the real root cause.
2. **Boilerplate and the null check.** `in` must be declared outside the `try`, initialized to `null`, and checked.
3. **Nesting with multiple resources.** Doing it correctly with two resources needs nested try/finally blocks, because a `close()` failure on the first would skip closing the second. In practice, people got this wrong constantly, and even JDK code and textbooks had leaks.

## Mechanics

### Syntax

```java
try (InputStream in = new FileInputStream("data.bin")) {
    process(in);
}   // in.close() has been called here
```

A resource is a variable declaration whose type implements `AutoCloseable`. The compiler generates the cleanup for you.

### What the compiler actually generates

Conceptually (this is the translation the Java Language Specification defines):

```java
{
    final InputStream in = new FileInputStream("data.bin");
    Throwable primary = null;
    try {
        process(in);
    } catch (Throwable t) {
        primary = t;
        throw t;
    } finally {
        if (in != null) {
            if (primary != null) {
                try { in.close(); }
                catch (Throwable s) { primary.addSuppressed(s); }   // attach, don't replace
            } else {
                in.close();                                         // body succeeded: close errors propagate
            }
        }
    }
}
```

Each piece does something specific:

- If the body fails, that exception stays **primary**. A failing `close()` is **attached** to it as a _suppressed_ exception, retrievable with `getSuppressed()`.
- If the body succeeds but `close()` fails, the close exception propagates normally.
- The `null` check means a resource expression that evaluates to `null` is **silently skipped**, not an NPE.

(Real javac output is more compact than this, but behaves identically.)

### Multiple resources: closed in reverse order

```java
try (Res a = new Res("A"); Res b = new Res("B")) {
    b.use();
}
```

This is equivalent to **nested** try-with-resources, `A` outside and `B` inside. Resources are closed in **reverse order of declaration** (like unstacking plates, last on is first off). That matters because later resources typically depend on earlier ones: close the `BufferedReader` before the `FileReader` underneath it.

Here is a complete demonstration of ordering and suppression:

```java
class Res implements AutoCloseable {
    private final String name;
    Res(String name) { this.name = name; System.out.println("open " + name); }
    void use() { System.out.println("use " + name);
                 throw new IllegalStateException("use failed: " + name); }
    @Override public void close() { System.out.println("close " + name);
                 throw new IllegalArgumentException("close failed: " + name); }
}

try (Res a = new Res("A"); Res b = new Res("B")) {
    b.use();
} catch (Exception e) {
    System.out.println("caught " + e);
    for (Throwable s : e.getSuppressed()) System.out.println("  suppressed " + s);
}
```

Output:

```
open A
open B
use B
close B
close A
caught java.lang.IllegalStateException: use failed: B
  suppressed java.lang.IllegalArgumentException: close failed: B
  suppressed java.lang.IllegalArgumentException: close failed: A
```

Both `close()` calls ran even though the first failed, and nothing was lost: the body's exception is primary, and both close failures ride along on it. This is what makes the construct trustworthy. An uncaught version prints these as `Suppressed:` blocks in the stack trace.

### The execution order of everything

For `try (resources) { body } catch (...) { } finally { }`:

1. Resources are initialized, in order.
2. The body runs.
3. Resources are closed, in reverse order.
4. **Only then** do `catch` and `finally` blocks run.

Consequences:

```java
try (var in = open()) {
    ...
} catch (IOException e) {
    in.close();   // COMPILE ERROR: `in` is out of scope here
}
```

The resource is scoped to the `try` block only, and it's already closed by the time a catch block runs. The catch clause also covers failures during **resource initialization and during `close()`**, which was awkward to achieve with hand-written try/finally.

### Java 9: using an existing variable

```java
InputStream in = open();             // must be final or effectively final
try (in) {
    process(in);
}
```

This is useful when the resource is created elsewhere (a parameter, a field copy), but note the ownership question it raises: should this code be closing something it didn't open? Often not.

Resource variables are **implicitly final**, so reassigning one inside the block is a compile error. That protects the guarantee that the object closed is the object opened.

## The interfaces

```java
public interface AutoCloseable {
    void close() throws Exception;
}

public interface Closeable extends AutoCloseable {
    void close() throws IOException;      // narrowed
}
```

||`AutoCloseable` (Java 7)|`Closeable` (Java 5)|
|---|---|---|
|Package|`java.lang`|`java.io`|
|`close()` throws|`Exception`|`IOException`|
|Idempotent?|**Not required**, only "strongly encouraged"|**Required** by contract: closing twice has no effect|
|Typical use|Anything: connections, locks, scopes|I/O streams, readers, writers|

**Why two interfaces?** `Closeable` existed before try-with-resources and is tied to `java.io`. The designers needed a more general root for non-I/O resources (JDBC connections throw `SQLException`, for instance), so they added `AutoCloseable` as its **superinterface**, retrofitting `Closeable` beneath it. That's why the hierarchy looks inverted relative to their ages.

### Why idempotence matters

```java
try (var fis = new FileInputStream(f);
     var ois = new ObjectInputStream(fis)) {
    ...
}
```

Closing `ois` closes `fis`, and then the compiler's cleanup closes `fis` again. This is safe only because `Closeable.close()` must tolerate repeated calls. When you write your own `AutoCloseable`, **make `close()` idempotent** with a `closed` flag unless you have a strong reason not to.

The docs also advise that `close()` should **not throw `InterruptedException`**: if that exception were suppressed (as above), the thread's interrupt signal would be silently lost. The `-Xlint:try` compiler flag warns about this.

### Narrowing `throws` in your own implementations

```java
class MyRes implements AutoCloseable {
    @Override public void close() { /* declares no checked exceptions */ }
}

try (MyRes r = new MyRes()) { ... }        // no catch needed
try (AutoCloseable r = new MyRes()) { ... } // must handle Exception!
```

The compiler checks what `close()` can throw using the **static type of the variable**. This is the same overriding-narrows rule from the checked-exceptions discussion. So if you design your own resource type, declare `close()` with no `throws` (or only what it genuinely throws) so callers aren't forced into a pointless `catch (Exception e)`.

## The "why" behind the design

- **Correctness by construction.** The cleanup pattern is subtle enough that experienced developers got it wrong. Moving it into the language removes the whole class of bugs.
- **No lost root cause.** Suppressed exceptions solve the masking problem. The _first_ failure is the one you most need, and now you always get it.
- **Scope equals lifetime.** The resource lives exactly as long as the block, similar to C++'s RAII or Python's `with`. Java's version is explicit (you must write the `try`), because Java objects have no deterministic destructors.
- **Why not finalizers?** `finalize()` ran at an unpredictable time (or never) and could resurrect objects, so it was both unreliable and unsafe. It was deprecated for removal in Java 18. The `java.lang.ref.Cleaner` API remains as a _safety net_ for forgotten close calls, but not as the primary mechanism.

## Edge cases and gotchas

### 1. Chained constructors can leak the inner resource

```java
// BAD: if BufferedReader's constructor throws, the FileReader is never closed
try (var br = new BufferedReader(new FileReader(f))) { ... }
```

The inner `new FileReader(f)` is just an argument expression, not a declared resource, so nobody is responsible for closing it if the outer constructor throws. For `BufferedReader` this is rarely a problem in practice, but for constructors that **do I/O** (like `ObjectInputStream`, which reads a header and can throw `StreamCorruptedException`) it's a real leak. Declare each layer as its own resource:

```java
try (var fr = new FileReader(f);
     var br = new BufferedReader(fr)) { ... }
```

### 2. Returning something that depends on the resource

```java
static Stream<String> lines(Path p) throws IOException {
    try (Stream<String> s = Files.lines(p)) {
        return s;                    // returns an already-CLOSED stream
    }
}
```

The `return` value is evaluated, then the resource is closed, then the method actually returns. The caller gets a stream whose underlying file is gone. The same applies to lazy iterators, `ResultSet` wrappers, and anything holding the resource. Either consume the data inside the block (collect to a `List`), or return the resource and make the **caller** own it with its own try-with-resources.

### 3. Closing can fail meaningfully

For output, `close()` often performs the final flush. If that fails, data was lost:

```java
try (var out = Files.newBufferedWriter(path)) {
    out.write(data);
}   // an IOException here means the file may be incomplete
```

Because a success-path `close()` exception propagates, you find out. Don't wrap `close()` in a swallowing helper for writers. (Swallowing is more defensible for _readers_, where a close failure rarely affects results.)

### 4. A `null` resource is legal; an exception while creating it is not "closing nothing" for earlier ones

If `a` is created and then creating `b` throws, **`a` is still closed**, because `a`'s try block is already active. A resource whose initializer itself throws has nothing to close, so no `close()` is attempted on it.

### 5. Self-suppression is forbidden

`addSuppressed(this)` throws `IllegalArgumentException`. This can surface if a resource's `close()` rethrows the very exception object that is already the primary one, which is a problem in some buggy wrapper classes.

### 6. `finally` and `catch` don't see the resource

Whatever you need from the resource must be extracted inside the block. Declare a variable outside before the `try` and assign into it.

### 7. Lambdas as resources

`AutoCloseable` has a single abstract method, so a lambda works:

```java
try (AutoCloseable cleanup = () -> System.out.println("done")) {
    ...
} catch (Exception e) { }    // forced: close() throws Exception
```

To avoid the forced catch, define your own interface:

```java
@FunctionalInterface
interface Scope extends AutoCloseable {
    @Override void close();           // no throws clause
}
```

This pattern is useful for non-memory "scoped state": timing a block, setting and restoring a `ThreadLocal`, pushing and popping a logging context.

### 8. Not everything you'd expect is `AutoCloseable`

`java.util.concurrent.locks.Lock` is **not**. Locking has the identical pairing problem, but `lock()`/`unlock()` doesn't fit the `close()` shape, so you still write:

```java
lock.lock();
try { ... } finally { lock.unlock(); }
```

(Note the order: `lock()` goes _before_ the `try`. If `lock()` itself failed and sat inside the `try`, `finally` would unlock a lock you never acquired.) `ExecutorService` became `AutoCloseable` in Java 19, where `close()` waits for submitted tasks to finish.

### 9. JDBC: each layer is a resource

```java
try (Connection c = ds.getConnection();
     PreparedStatement ps = c.prepareStatement(sql);
     ResultSet rs = ps.executeQuery()) {
    ...
}
```

Closing a `Statement` closes its `ResultSet`, and closing a `Connection` closes everything beneath it, but relying on that cascade is fragile. Explicit nesting is clearer. With a connection pool, `close()` doesn't destroy the connection; it **returns it to the pool**, which is the "rental counter" idea in its purest form.

### 10. Compiler lint

`-Xlint:try` warns when a resource variable is never referenced in the body (a common sign that the code isn't doing what you think) and when `close()` can throw `InterruptedException`.

## How it connects

- **Exceptions and the checked/unchecked split:** suppressed exceptions are the answer to "what if two things fail at once?" The `close()` signature debate (`Exception` vs `IOException` vs nothing) is the narrowing rule in action.
- **`finally` semantics:** try-with-resources is `finally` done right. It handles the override-and-lose-exception trap, which is worth understanding deeply in its own right.
- **Inheritance and interfaces:** the `Closeable extends AutoCloseable` retrofit and covariant `throws` in overrides.
- **Memory management and GC:** the reason this exists at all. GC reclaims _memory_, not _external resources_, and finalizers and `Cleaner` are the (weak) fallback.
- **Concurrency:** interrupts and `close()`, executors as resources, and scoped constructs (like structured concurrency) that build on the same "lifetime equals block" idea.
- **Design:** the `Scope`-style pattern generalizes "acquire and release" to anything with setup and teardown.



[[Exception]]
[[Java]]