

## Mental model

Picture a tall building where each floor is a method call. `main` is the ground floor, and each method it calls adds a floor above. A fire alarm (an exception) goes off on the top floor. The evacuation works like this:

1. The people on that floor check whether they have a fire marshal who handles this kind of fire (a matching `catch`). If so, the evacuation stops there and life resumes on that floor.
2. If not, the floor is **abandoned**: its contents are discarded and the alarm moves down to the floor below, at the exact spot where that floor called upward.
3. On the way out, each floor has a cleanup crew (`finally`, `try-with-resources`, and `synchronized` lock release) that must finish before the floor is given up.
4. If the alarm reaches the ground floor with no marshal, the whole thread shuts down.

That process of popping frames one by one while looking for a handler and running cleanup is stack unwinding.

## The mechanics

```java
static void c() { throw new IllegalStateException("boom"); }
static void b() { try { c(); } finally { System.out.println("b cleanup"); } }
static void a() { try { b(); } catch (IllegalStateException e) { System.out.println("a caught"); } }
```

Output: `b cleanup`, then `a caught`.

What the JVM does when `throw` executes:

1. **The exception object already exists.** `new IllegalStateException(...)` ran earlier, and its constructor called `fillInStackTrace()`, which snapshotted the stack at that moment. `throw` only starts the unwinding.
2. **Look up the current method's exception table.** Every compiled method has a table of rows `(start_pc, end_pc, handler_pc, catch_type)`. The JVM finds the first row, in table order, whose pc range covers the current instruction and whose `catch_type` is a superclass of (or the same as) the thrown class. You can see the table with `javap -c`.
3. **If a row matches,** the operand stack is cleared, the exception is pushed, and execution jumps to `handler_pc`. Unwinding ends.
4. **If nothing matches,** the frame is popped (the method "completes abruptly") and the same exception is raised in the caller at the pc of the call instruction. Go back to step 2.
5. **If the stack is exhausted,** the thread's `UncaughtExceptionHandler` runs (by default it prints the stack trace), and the thread dies.

**Why `finally` works:** `javac` compiles it as a copy of the `finally` code on the normal path, plus a catch-any row (catch type 0) that stores the exception, runs the `finally` code, and rethrows. So `finally` is just an ordinary handler that always rethrows. The same trick makes `synchronized` blocks release their monitor during unwinding (a catch-any row containing `monitorexit`). For `synchronized` methods, the JVM releases the lock when the frame is popped.

## How it differs from C++

C++ unwinding calls destructors (RAII) and is a two-phase process in the common ABI: it first searches for a handler, then unwinds. Java has no destructors, so cleanup is explicit (`finally`, try-with-resources). Also, in C++ an uncaught exception may call `std::terminate` without unwinding at all. In Java an uncaught exception **always unwinds the whole thread's stack**, so `finally` blocks all run before the thread dies.

## Edge cases

**`return` in `finally` swallows the exception.**

```java
static int f() { try { throw new RuntimeException(); } finally { return 1; } }  // returns 1, exception vanishes
```

`break` and `continue` in `finally` do the same. This is legal, which is why linters warn about it.

**An exception thrown in `finally` replaces the original.** The original is silently lost. Try-with-resources fixes this: if the body throws and `close()` also throws, the `close()` exception is attached via `addSuppressed` and the body's exception stays primary. Resources close in reverse order of declaration, and before the statement's own `catch`/`finally` runs.

**`finally` does not always run.** It is skipped on `System.exit()` or `Runtime.halt()`, a JVM crash, `kill -9`, an infinite loop or deadlock in the `try`, or when the thread is a daemon and the JVM exits.

**The stack trace shows where the exception was _created_, not thrown.**

```java
Exception e = new Exception();   // trace points here
// ... later, elsewhere
throw e;                          // trace does NOT update
```

Rethrowing a caught exception also keeps its original trace.

**Cost.** The expensive part is usually `fillInStackTrace()`, which is proportional to stack depth, not the unwinding. That is why exceptions-as-control-flow is slow, and why some libraries use the protected constructor `Throwable(msg, cause, enableSuppression, writableStackTrace=false)`. The JIT can sometimes inline a `throw` and its `catch` in the same compiled unit into a plain jump.

**Vanishing stack traces.** HotSpot's `OmitStackTraceInFastThrow` (on by default) lets the JIT throw preallocated, trace-less `NullPointerException`, `ArrayIndexOutOfBoundsException`, etc. after they get "hot." If you see an NPE with an empty trace in production logs, try `-XX:-OmitStackTraceInFastThrow`.

**`StackOverflowError`.** Unwinding works fine, but handlers and `finally` blocks run near the stack limit, so they can overflow again and replace the error. Keep cleanup in such paths minimal.

**Unwinding stops at the thread boundary.** An exception never propagates from a child thread into the thread that started it.

- `Thread` with no handler: printed and the thread dies.
- `executor.execute(r)`: goes to the uncaught handler.
- `executor.submit(r)`: captured in the `Future` and rethrown as `ExecutionException` at `get()`.
- `CompletableFuture`: wrapped in `CompletionException`.

**Static initializers.** An exception unwinding out of a `static {}` block becomes `ExceptionInInitializerError`, and every later use of the class throws `NoClassDefFoundError`, because the class is marked failed.

**Lambdas and streams.** Unwinding passes through the framework frames between your lambda and its caller (they show up in traces). Checked exceptions can't cross functional interfaces that don't declare them, so you wrap them in unchecked ones.

**Chained exceptions.** Wrapping (`new X("msg", cause)`) preserves the original trace as the "Caused by" section. This is a manual way of keeping the unwinding history across abstraction layers.

## Related concepts

- **Checked vs. unchecked exceptions:** only a compile-time rule. Unwinding treats them identically.
- **`Throwable.fillInStackTrace` / `StackWalker`:** how stack data is captured and inspected.
- **Try-with-resources and suppressed exceptions:** the structured answer to cleanup during unwinding.
- **Thread uncaught-exception handlers:** the "last resort" at the bottom of the stack.
- **Virtual threads:** unwinding works the same way, just over frames of a continuation rather than a native thread stack.



[[Exception]]
[[Java]]