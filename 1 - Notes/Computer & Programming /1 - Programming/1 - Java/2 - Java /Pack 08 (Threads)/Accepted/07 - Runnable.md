



## Definition

**`Runnable`** is a **functional interface** in `java.lang` representing **a task with no input and no return value** — "a block of code that can be run." It has exactly one abstract method:

```java
@FunctionalInterface
public interface Runnable {
    void run();
}
```

You actually already met this exact shape in the lambda tutorial — `Runnable` is the _first_ entry in the lambda types table ("no-argument, no return value"). This is the formal, complete definition.

---

## The problem it solves

Java needed a standard, universal way to represent **"a piece of behavior to execute"** — separate from any data. This shows up in two related but distinct contexts:

### 1. As a general "task" abstraction

Before lambdas existed, if you wanted to pass "code to run later" as a value (to a thread, a timer, a callback), you needed some interface type to hold it. `Runnable` became that standard type — predating lambdas by many years (it's been in Java since 1.0).

### 2. Specifically, as the way to give a `Thread` something to execute

```java
Thread thread = new Thread(runnableTask);
thread.start();
```

This is `Runnable`'s most common real-world use, connecting directly to the last few tutorials: a `Thread` needs to know _what code to actually run_ on that new thread — `Runnable` is the contract for supplying that.

---

## How to create a `Runnable` — three ways

### 1. Lambda (modern, most common)

```java
Runnable task = () -> System.out.println("Running!");
```

### 2. Method reference

```java
Runnable task = MyClass::doSomething; // if doSomething() is void, no args
```

### 3. Anonymous class (the old, pre-lambda way — still valid)

```java
Runnable task = new Runnable() {
    @Override
    public void run() {
        System.out.println("Running!");
    }
};
```

All three produce an object satisfying the same contract — `run()` with no arguments, no return value. This is a good concrete example of exactly what the lambda tutorial's opening example demonstrated: the lambda is shorthand for the anonymous class.

---

## Using a `Runnable`

### Running it directly (no threading — just calling the method)

```java
Runnable task = () -> System.out.println("Hello");
task.run(); // just a normal method call — runs on the CURRENT thread, no concurrency here
```

### Running it on a new thread (the actual point of `Runnable`, in practice)

```java
Runnable task = () -> System.out.println("Running on: " + Thread.currentThread().getName());
Thread thread = new Thread(task);
thread.start(); // NOW it runs on a separate thread
```

This is the exact `run()` vs `start()` distinction from the threads tutorial — worth repeating here because it's specifically about `Runnable`'s purpose: calling `.run()` on a `Runnable` is just an ordinary method call; only `Thread.start()` actually creates concurrency.

### Submitting it to an `ExecutorService` (the modern, preferred approach)

```java
ExecutorService executor = Executors.newFixedThreadPool(4);
executor.submit(task); // Runnable submitted to a managed thread pool
executor.shutdown();
```

---

## `Runnable`'s key limitation — and what replaces it when you need more

`Runnable`'s `run()` method:

- Takes **no arguments**
- Returns **`void`** (no result)
- **Cannot throw checked exceptions** (its signature doesn't declare any)

```java
Runnable task = () -> {
    // Files.readString(path); // COMPILE ERROR — throws IOException, but run() doesn't declare it
};
```

This connects directly to the exception-handling limitation covered in the method-reference/lambda tutorials: since `run()` doesn't declare any checked exceptions, a lambda assigned to `Runnable` can't throw one either — you must catch it inside the lambda body.

```java
Runnable task = () -> {
    try {
        Files.readString(path);
    } catch (IOException e) {
        System.out.println("Failed: " + e.getMessage());
    }
};
```

### When you need a _result_ back — use `Callable` instead

```java
import java.util.concurrent.Callable;

Callable<String> task = () -> {
    return Files.readString(path); // CAN throw checked exceptions, AND returns a value
};

ExecutorService executor = Executors.newFixedThreadPool(1);
Future<String> future = executor.submit(task); // submit() accepts Callable too
String result = future.get(); // blocks until the result is ready
```

**`Callable<V>`** is `Runnable`'s sibling, specifically designed to fix both limitations: it returns a value (`V call()`) and its method signature declares `throws Exception`, so checked exceptions are allowed.

||`Runnable`|`Callable<V>`|
|---|---|---|
|Method|`void run()`|`V call() throws Exception`|
|Returns a value?|No|Yes|
|Can throw checked exceptions?|No|Yes|
|Package|`java.lang`|`java.util.concurrent`|
|Used with|`Thread`, `ExecutorService.submit()`|`ExecutorService.submit()` (returns `Future<V>`)|

---

## `Runnable` vs `CompletableFuture` — how they connect

Since we covered `CompletableFuture` in the concurrency tutorial: `CompletableFuture.runAsync()` specifically takes a `Runnable` (for "do this, no result needed"), while `CompletableFuture.supplyAsync()` takes a `Supplier<T>` (for "do this, give me a result") — the same no-result vs. has-result split as `Runnable` vs `Callable`, just expressed through the async API instead of raw threads/executors.

```java
CompletableFuture.runAsync(() -> System.out.println("Fire and forget task")); // Runnable

CompletableFuture<String> future = CompletableFuture.supplyAsync(() -> fetchData()); // Supplier<String>
```

---

## Where `Runnable` fits across everything you've learned

```
Thread(Runnable) ──────┐
                          │
ExecutorService.submit(Runnable) ── all need "a task with no input, no output"
                          │
CompletableFuture.runAsync(Runnable) ┘
```

`Runnable` is the oldest and simplest of the functional-interface family you've covered (`Runnable`, `Consumer`, `Supplier`, `Function`, `Predicate`) — and it's the one specifically tied to Java's concurrency model, which is exactly why it kept its own `java.lang` package placement (predating `java.util.function`, introduced in Java 8) rather than being folded into the newer functional interfaces package.

## Summary

|Aspect|Detail|
|---|---|
|What it is|functional interface, `void run()`, no args, no return|
|Solves|representing "a task to execute" as a value, especially for threads|
|Package|`java.lang`|
|Create with|lambda `() -> {...}`, method reference, or anonymous class|
|Use with|`new Thread(runnable)`, `ExecutorService.submit()`, `CompletableFuture.runAsync()`|
|Limitation|no return value, no checked exceptions|
|When you need more|use `Callable<V>` instead|


[[Java]]