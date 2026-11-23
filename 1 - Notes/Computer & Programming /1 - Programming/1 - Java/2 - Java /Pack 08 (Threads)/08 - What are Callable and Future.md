


These two are the pair that existed in Java _before_ `CompletableFuture` was added (Java 5, vs. `CompletableFuture` in Java 8), and they're still what `ExecutorService.submit()` works with under the hood. `Callable<V>` is "a task that returns a value and is allowed to throw a checked exception." `Future<V>` is "a handle to a result that doesn't exist yet" — you hold onto it, and later ask it for the value, check if it's done, or cancel the task. Together they're the minimal version of what `CompletableFuture` later built chaining and composition on top of.

### `Callable<V>` — a task with a result

```java
Callable<Integer> task = () -> {
    Thread.sleep(1000);
    return 42;
};
```

One abstract method: `V call() throws Exception`. Compare this to `Runnable`, which you already know from `Thread`/`ExecutorService` — `Runnable.run()` returns nothing and can't throw a checked exception. `Callable` exists specifically to cover the two things `Runnable` can't do: return a value, and declare a checked exception. That's the whole difference. If a background task needs to report a result or might throw something like `IOException`, it needs to be a `Callable`, not a `Runnable`.

### `Future<V>` — the handle to that result

You get a `Future` back when you submit a `Callable` (or `Runnable`) to an `ExecutorService`:

```java
ExecutorService executor = Executors.newFixedThreadPool(4);
Future<Integer> future = executor.submit(task);
```

`submit()` returns immediately — the task runs on a pool thread while your current thread keeps going. `Future<V>` gives you four operations on that eventual result:

```java
boolean cancelled = future.cancel(true);     // attempt to cancel; true = interrupt if already running
boolean done = future.isDone();              // true once completed, failed, or cancelled
boolean wasCancelled = future.isCancelled(); // true only if cancel() succeeded before completion
Integer result = future.get();               // blocks until done, then returns the value
```

`get()` is the only way to actually retrieve the value, and it blocks the calling thread until the task finishes — there's no callback mechanism, no "notify me when it's ready." That's the core limitation `CompletableFuture` was built to remove. There's also a timed overload:

```java
Integer result = future.get(5, TimeUnit.SECONDS);  // throws TimeoutException if not done in time
```

### Exceptions from `get()`

`get()` declares two checked exceptions you have to handle:

```java
try {
    Integer result = future.get();
} catch (InterruptedException e) {
    Thread.currentThread().interrupt();   // restore the interrupt status, don't swallow it
} catch (ExecutionException e) {
    Throwable cause = e.getCause();       // the actual exception the Callable threw
    System.err.println("Task failed: " + cause);
}
```

`InterruptedException` fires if the _waiting_ thread (the one calling `get()`) gets interrupted while blocked. `ExecutionException` fires if the `Callable` itself threw something — note that the original exception is wrapped inside `ExecutionException`, so you unwrap it with `getCause()` rather than catching it directly. This wrapping behavior is exactly what `CompletableFuture` changed when it introduced `CompletionException` (unchecked) for its own `join()` method.

### Submitting multiple Callables at once

`ExecutorService` has two methods for running a batch of `Callable`s together, which `submit()` alone doesn't give you:

```java
List<Callable<Integer>> tasks = List.of(task1, task2, task3);

// Runs all, blocks until every one is done, returns Futures in the same order
List<Future<Integer>> results = executor.invokeAll(tasks);

// Runs all, returns as soon as ONE succeeds, cancels the rest
Integer firstResult = executor.invokeAny(tasks);
```

`invokeAll` is the direct ancestor of `CompletableFuture.allOf` — same idea (wait for every task), but `invokeAll` blocks the calling thread to do it and hands back the actual `List<Future<V>>`, where `allOf` stays non-blocking and returns a `CompletableFuture<Void>` you still have to pull individual results out of separately. `invokeAny` is the ancestor of `anyOf` in the same way.

### Where this connects to what you already know

- `Callable` is what you pass to `ExecutorService.submit()` instead of `Runnable` when you need a return value — same executor, same pool, same thread lifecycle rules you've already covered.
- `Future` is a strictly narrower version of `CompletableFuture`: it only implements the blocking-handle part (`get`, `cancel`, `isDone`, `isCancelled`). `CompletableFuture` implements `Future` itself _and_ adds the whole `CompletionStage` chaining API (`thenApply`, `thenCombine`, `exceptionally`, and so on) on top. So anywhere you see `Future<V>`, you can assign a `CompletableFuture<V>` to it — it satisfies the interface, it just has more capability than the variable's declared type exposes.
- The checked-exception difference between `Runnable`/`Callable` is the same distinction as `Supplier`/`Callable` you saw earlier: `Callable.call()` can throw checked exceptions, `Supplier.get()` cannot — which is exactly why `CompletableFuture.supplyAsync` takes a `Supplier`, not a `Callable`: it wants you to handle checked exceptions yourself before returning, rather than letting them propagate through the async machinery.


[[Threads]]