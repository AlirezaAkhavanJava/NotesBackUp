


An **exception handler** is a piece of code whose only job is to decide what happens after something goes wrong: log it, show a message, retry, clean up, or shut down. Instead of repeating the same `catch` block in fifty places, you write that logic once in one class and send every exception to it.

Java has no built-in "handler class" like Spring's `@ControllerAdvice`. You build one yourself from a few small pieces: custom exceptions, a handler class, and a way to call it. The calling part has several options, depending on where the exception happens (normal code, another thread, an async task). This lesson covers each one.

---

## 1. Create your own exceptions

A handler needs to tell errors apart, so give each kind of error its own type:

```java
public class InvalidInputException extends RuntimeException {
    public InvalidInputException(String message) {
        super(message);
    }
}

public class ResourceNotFoundException extends RuntimeException {
    private final int id;

    public ResourceNotFoundException(int id) {
        super("Resource not found: " + id);
        this.id = id;
    }

    public int getId() { return id; }
}
```

- `extends RuntimeException` makes these **unchecked**, so you don't have to write `throws` everywhere.
- `super(message)` stores the message so `getMessage()` works later.
- Extra fields, like `id`, let the handler read details without parsing text.

---

## 2. Write the handler (simple version)

```java
public class ExceptionHandler {

    public void handle(Throwable ex) {
        if (ex instanceof InvalidInputException e) {
            System.out.println("[400] Bad input: " + e.getMessage());
        } else if (ex instanceof ResourceNotFoundException e) {
            System.out.println("[404] Not found, id=" + e.getId());
        } else {
            System.err.println("[500] Unexpected: " + ex);
            ex.printStackTrace();
        }
    }
}
```

Line by line:

- `Throwable ex`: the parent of everything throwable, so the handler accepts any error.
- `ex instanceof InvalidInputException e`: checks the type and, if it matches, gives you a typed variable `e` (pattern matching, Java 16+).
- The last `else` is your **safety net**. Any exception you didn't plan for still gets logged instead of silently disappearing.

This works, but the `if` chain grows with every new exception. The next version fixes that.

---

## 3. Write the handler (registry version)

Here you _register_ an action per exception type, and the handler finds the right one:

```java
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.function.Consumer;

public class GlobalExceptionHandler {

    private final Map<Class<? extends Throwable>, Consumer<Throwable>> handlers =
            new LinkedHashMap<>();

    public <T extends Throwable> GlobalExceptionHandler on(
            Class<T> type, Consumer<? super T> action) {
        handlers.put(type, ex -> action.accept(type.cast(ex)));
        return this; // allows chaining
    }

    public void handle(Throwable ex) {
        for (var entry : handlers.entrySet()) {
            if (entry.getKey().isInstance(ex)) {
                entry.getValue().accept(ex);
                return; // first match wins
            }
        }
        System.err.println("[500] Unhandled: " + ex);
    }
}
```

Walkthrough:

- The `Map` stores _exception type → action_. `LinkedHashMap` keeps insertion order, which matters (see below).
- `on(...)` registers an action. `type.cast(ex)` converts the generic `Throwable` into the exact type, so your lambda gets `InvalidInputException`, not just `Throwable`.
- `handle(...)` loops through the registered types. `isInstance` also matches **subclasses**, and the first match runs.
- The fallback line handles anything unregistered.

**Order matters.** Register specific exceptions first and general ones (like `Exception.class`) last. If you register `Exception.class` first, it matches everything and the specific ones never run.

Using it:

```java
GlobalExceptionHandler handler = new GlobalExceptionHandler()
        .on(InvalidInputException.class,
            e -> System.out.println("[400] " + e.getMessage()))
        .on(ResourceNotFoundException.class,
            e -> System.out.println("[404] id=" + e.getId()))
        .on(Exception.class,
            e -> System.err.println("[500] " + e));
```

---

## 4. How to call the handler

The handler does nothing until something sends an exception to it. Where the exception happens decides which option to use.

### Option A: `try/catch` that calls the handler

The most direct way:

```java
try {
    userService.findUser(-1);
} catch (Exception e) {
    handler.handle(e);
}
```

You still write a `try/catch`, but the catch body is one line and all the logic lives in the handler.

### Option B: a reusable "safe run" wrapper

To avoid writing `try/catch` repeatedly, wrap it once:

```java
import java.util.Optional;
import java.util.concurrent.Callable;

public final class Safe {
    private Safe() {}

    public static <T> Optional<T> call(Callable<T> task, GlobalExceptionHandler handler) {
        try {
            return Optional.ofNullable(task.call());
        } catch (Exception e) {
            handler.handle(e);
            return Optional.empty();
        }
    }
}
```

Usage:

```java
Optional<String> name = Safe.call(() -> userService.findUser(-1), handler);
System.out.println(name.orElse("fallback"));
```

- `Callable<T>` is a task that returns a value and is allowed to throw.
- If the task succeeds, you get the value in an `Optional`.
- If it fails, the handler runs and you get `Optional.empty()`, so the caller can pick a fallback.

This is the closest plain-Java equivalent to what `@ControllerAdvice` does for you in Spring.

### Option C: catch everything nobody caught (uncaught exception handler)

If an exception escapes every `try/catch`, the thread dies. You can intercept that moment for the whole program:

```java
Thread.setDefaultUncaughtExceptionHandler((thread, ex) -> {
    System.err.println("Thread " + thread.getName() + " crashed");
    handler.handle(ex);
});
```

Now any uncaught exception in **any thread** reaches your handler. For a single thread only:

```java
Thread worker = new Thread(() -> {
    throw new InvalidInputException("bad data");
});
worker.setUncaughtExceptionHandler((t, ex) -> handler.handle(ex));
worker.start();
```

Important: this handler runs _after_ the exception has already ended the thread. You can log and clean up, but you can't resume the code that failed. It's a last line of defense, not a replacement for `try/catch`.

### Option D: exceptions inside thread pools

This one surprises many people. With an `ExecutorService`, `submit()` **swallows** the exception and stores it inside the returned `Future`:

```java
ExecutorService pool = Executors.newFixedThreadPool(2);

Future<?> f = pool.submit(() -> {
    throw new InvalidInputException("bad data");
});

try {
    f.get(); // the exception only shows up here
} catch (ExecutionException e) {
    handler.handle(e.getCause()); // unwrap the real exception
} catch (InterruptedException e) {
    Thread.currentThread().interrupt();
}
```

- `f.get()` rethrows the task's exception wrapped in an `ExecutionException`.
- `e.getCause()` gives you the original exception, which is what your handler expects.
- If you never call `get()`, the error disappears silently.

### Option E: `CompletableFuture`

Async code has handling built in:

```java
CompletableFuture.supplyAsync(() -> {
            throw new ResourceNotFoundException(42);
        })
        .exceptionally(ex -> {
            Throwable real = (ex instanceof CompletionException && ex.getCause() != null)
                    ? ex.getCause() : ex;
            handler.handle(real);
            return null; // fallback value
        });
```

- `exceptionally` runs only if the earlier step failed.
- The exception usually arrives wrapped in a `CompletionException`, so you unwrap it before passing it on.
- Whatever you return becomes the replacement result.

---

## 5. Putting it together

```java
public class Main {

    static String findUser(int id) {
        if (id < 0) throw new InvalidInputException("id must be positive");
        if (id > 100) throw new ResourceNotFoundException(id);
        return "User-" + id;
    }

    public static void main(String[] args) {
        GlobalExceptionHandler handler = new GlobalExceptionHandler()
                .on(InvalidInputException.class,
                    e -> System.out.println("[400] " + e.getMessage()))
                .on(ResourceNotFoundException.class,
                    e -> System.out.println("[404] id=" + e.getId()))
                .on(Exception.class,
                    e -> System.err.println("[500] " + e));

        // Safety net for anything uncaught
        Thread.setDefaultUncaughtExceptionHandler((t, ex) -> handler.handle(ex));

        System.out.println(Safe.call(() -> findUser(5), handler).orElse("none"));
        System.out.println(Safe.call(() -> findUser(-1), handler).orElse("none"));
        System.out.println(Safe.call(() -> findUser(500), handler).orElse("none"));
    }
}
```

Output:

```
User-5
[400] id must be positive
none
[404] id=500
none
```

---

## 6. Which option to use

|Where the exception happens|Use|Why|
|---|---|---|
|Normal code, one place|`try/catch` → `handler.handle(e)`|Simple and explicit|
|Normal code, many places|`Safe.call(...)` wrapper|One `try/catch` for everything|
|Any thread, nobody caught it|`setDefaultUncaughtExceptionHandler`|Last line of defense|
|One specific thread|`thread.setUncaughtExceptionHandler`|Different handling per thread|
|`ExecutorService` tasks|`future.get()` + unwrap `getCause()`|`submit()` hides errors|
|Async pipelines|`CompletableFuture.exceptionally`|Built into the chain|

---

## 7. Quick summaries of related concepts

- **Checked vs unchecked exceptions:** Checked exceptions (like `IOException`) must be caught or declared with `throws`. Unchecked ones (`RuntimeException` and its subclasses) don't have to be. Custom business exceptions are usually unchecked.
- **`finally`:** Runs whether or not an exception happened. Use it for cleanup, not for handling.
- **try-with-resources:** `try (var in = new FileInputStream(f)) { ... }` closes resources automatically, even on failure.
- **Exception chaining:** `throw new ServiceException("failed", cause)` keeps the original error as the `cause`, so the stack trace tells the full story.
- **`@ControllerAdvice` in Spring:** The same idea as your handler, except Spring finds the handler method by exception type and calls it for you inside the request pipeline. What you built here is the plain-Java version of that.

---

## 8. Common mistakes

1. **An empty `catch` block.** `catch (Exception e) {}` hides bugs. At minimum, send it to the handler.
2. **Registering `Exception.class` first** in the registry, so specific handlers never run.
3. **Forgetting `ExecutionException` wraps the real error** when using futures, so your handler never matches the right type.
4. **Using the uncaught handler as the main strategy.** The thread is already dead by then. Handle expected errors close to where they happen.
5. **Swallowing the stack trace.** Log the exception itself (`e.printStackTrace()` or a logger), not only `e.getMessage()`.




[[Exception]]