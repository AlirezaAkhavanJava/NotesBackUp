

## The mental model: a stack of desks, each with a sticky note

Picture an office where every active method call is a desk, stacked vertically. Taped to each desk is a sticky note, written at compile time and never changed, listing rules like this: "if trouble hits while you're on tasks 0 to 12, and it's a problem of kind X, jump to step 15."

When someone pulls the alarm at the top desk, nobody sprints around searching the building. The JVM walks down the stack one desk at a time and reads each note:

- If a rule matches, work resumes at the step it names, and the desks above are cleared away.
- If no rule matches, that desk is cleared away and the JVM reads the next note down.
- If it reaches the bottom with no match, the thread dies.

This gives you two separate things:

1. The exception table is static data: the sticky note, built by the compiler, one per method.
2. Unwinding is a runtime algorithm: the walk down the stack, popping frames.

A third thing is often confused with both: filling in the stack trace. That happens earlier, when the exception object is constructed, and has nothing to do with unwinding. More on that below.

## The pieces

Every method invocation gets a frame holding:

- a local variable array (parameters and locals)
- an operand stack (scratch space for the bytecode)
- a program counter, `pc`, the index of the bytecode currently executing in that frame

For a caller, `pc` sits on the `invoke*` instruction that is still waiting for its callee to return. That detail is how the JVM knows where in the caller's code the exception "happened."

A method's bytecode carries an exception table. Each entry has four fields:

|Field|Meaning|
|---|---|
|`start_pc`|First covered instruction (inclusive)|
|`end_pc`|End of covered range (exclusive, so the range is half-open)|
|`handler_pc`|Where to jump if this entry matches|
|`catch_type`|Class to match, or 0 meaning "any" (used for `finally`)|

The algorithm, as defined for `athrow` in the JVM spec:

1. Pop the exception object from the operand stack.
2. Scan the current method's table from the top, in order. The first entry where `start_pc <= pc < end_pc` and the exception is an instance of `catch_type` wins.
3. On a match, clear the operand stack, push the exception object, set `pc = handler_pc`, and keep running. Local variables survive untouched.
4. With no match, pop this frame (releasing the monitor if the method is `synchronized`), then repeat step 2 in the caller's frame, using the caller's `pc`.
5. If no frames remain, the thread terminates through its uncaught-exception handler.

Step through it here:## What to try in the explorer

- `pc 9` with `IllegalStateException`: the inner entry is skipped because pc 9 lies outside `[0,4)`. The outer entry catches it. The handler code for `IOException` isn't covered by its own `try`, so an exception thrown inside a `catch` block can't loop back into that same `catch`. It goes to the next enclosing handler.
- `pc 1` with `IllegalStateException`: the range matches the inner entry but the type doesn't, so the scan continues to the outer entry.
- `StackOverflowError` anywhere: nothing matches, because it's neither an `IOException` nor a `RuntimeException`, so the frame is popped.

## Why it works this way

- Zero cost when nothing is thrown. The table is passive data. There is no setup code on entry to a `try` block, no registration, and no cleanup, which is why `try` is free on the happy path. Compare that with a design where each `try` pushes a handler onto a runtime stack, as in `setjmp`-style schemes.
- Half-open ranges and static tables make nesting a pure ordering problem. The compiler only has to emit inner entries first. If they were reversed, `catch (RuntimeException)` would shadow a more specific inner handler for the same range.
- Clearing the operand stack but keeping the locals. The operand stack holds half-evaluated expressions. In `f(a(), b())`, if `b()` throws, the result of `a()` is simply discarded. Locals persist, which is why a variable assigned in the `try` body is still there in the `catch`. The bytecode verifier works from the same fact: at a handler, it only trusts what is true at every instruction in the covered range. This is the origin of Java's definite-assignment rule, which forbids reading a variable in a `catch` that was only assigned partway through the `try`.

## Edge cases and gotchas

### How `finally` is compiled

There is no special runtime concept of `finally`. javac builds it from the same parts:

```java
try { A(); } finally { F(); }
```

compiles to roughly:

```
A()
F()                 ← copy of finally body for the normal path
goto end
handler:            ← table entry with catch_type = any (0), covering A()
  astore ex
  F()               ← second copy for the exceptional path
  aload ex
  athrow            ← rethrow: unwinding resumes from here
end:
```

So the finally body is duplicated at every exit (normal completion, each `return`, and the exceptional path), and the "any" handler ends in `athrow`. Unwinding pauses at your frame, runs the cleanup code, then starts the algorithm over from the same frame with the same object. That explains the classic trap where a `return` or `throw` inside `finally` silently discards the in-flight exception: the rethrow instruction is simply never reached.

### `synchronized`

A `synchronized` block compiles to `monitorenter`/`monitorexit` plus an any-handler that releases the monitor and rethrows. A `synchronized` method has no explicit code at all: the JVM releases the monitor itself when the frame is popped, normally or by exception. Either way, locks are not leaked by exceptions.

### Stack trace capture is separate from unwinding

The trace is captured in the `Throwable` constructor (`fillInStackTrace`), which walks the frames that exist at that moment and records them. Unwinding happens later and does not modify the trace.

- This is why an exception you construct but never throw still has a trace.
- It is also why a stored exception that you rethrow later still shows the original location.
- The cost splits into two parts: the capture is proportional to stack depth, and the handler search is proportional to the number of frames unwound times the table sizes. The capture is usually the more expensive part.

### The JIT can make exceptions nearly free

Compiled code does not execute `athrow` the way the interpreter does. If the throw and the matching `catch` are inlined into the same compiled method, C2 can turn the whole thing into an ordinary jump. If they aren't, the VM falls back to a slower runtime path that looks up handlers in each compiled method's own handler tables.

There is also a gotcha: after a hot implicit exception (`NullPointerException`, `ArrayIndexOutOfBoundsException`, and so on) has been thrown many times from the same spot, HotSpot may start throwing a preallocated instance with no stack trace. If production logs suddenly show a bare `java.lang.NullPointerException` with no frames, this is why. The flag `-XX:-OmitStackTraceInFastThrow` disables the optimization.

### `StackOverflowError` is thrown at the edge of a limited stack

The thread's stack has a fixed size, and the JVM raises the error when a new frame won't fit. You can catch it, because the table lookup works like any other. But the handler runs in the frame that is nearly out of space, so code that tries to do real work there often throws a second `StackOverflowError`. Catch it only at a point well below the overflow, which means near the bottom of the stack.

### An exception takes down the thread, not the JVM

When unwinding reaches the bottom, the thread's uncaught-exception handler runs. The default one prints `Exception in thread "..."` with the trace, and you can replace it with `Thread.setDefaultUncaughtExceptionHandler`. If other non-daemon threads are alive, the JVM keeps running. Inside an `ExecutorService`, the framework catches exceptions itself and stores them in the `Future`, so you'd see them wrapped in an `ExecutionException` on `get()` rather than at the thread's top.

### Synthetic frames lengthen your traces

Lambdas, streams, reflection, and proxies add frames that you didn't write (`InvocationTargetException` is a wrapper added when a reflective call throws). The unwinding algorithm treats them like any other frame. That is why a long stack trace in a Spring or stream-heavy app is mostly framework frames, with your own code near the top and the bottom.

## Seeing it for yourself

Compile any class and run `javap -c -v ClassName`. Look for the `Exception table:` section at the end of each method. You'll see the `from`, `to`, `target`, and `type` columns exactly as in the explorer above, with `any` for `finally` and `synchronized` entries.

## How it connects

- The call stack: unwinding is just popping frames, so frames, `pc`, and the operand stack are the mechanism, and `StackOverflowError` is the limit.
- `finally` semantics: now you can see why `finally` can override a return or lose an exception (the rethrow gets skipped).
- try-with-resources: the compiler generates this same try/catch/any-handler structure around `close()` calls, plus the `addSuppressed` logic.
- Checked exceptions: they are enforced at compile time and invisible here. The table matches on class only, which is why sneaky throws work.
- The JIT and performance: whether a `throw` is costly depends on inlining and on stack-trace capture, not on the `try`.
- Concurrency: per-thread stacks mean unwinding is per-thread, which is why exceptions don't cross thread boundaries without help (`Future`, handlers).





[[Java]]