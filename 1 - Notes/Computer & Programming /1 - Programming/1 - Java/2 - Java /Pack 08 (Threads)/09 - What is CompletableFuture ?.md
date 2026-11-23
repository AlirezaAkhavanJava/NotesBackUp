

`CompletableFuture<T>` is Java's class for representing a value that doesn't exist yet but will — the result of an asynchronous computation. It implements both `Future<T>` and `CompletionStage<T>`. The `Future` part means you _can_ block and wait for the result if you want to (`get()`), just like the plain `Future` you get from `ExecutorService.submit()`. The `CompletionStage` part is the real addition: it lets you attach callbacks that run automatically _when the value becomes available_, and chain further async steps off of those callbacks, without ever calling `get()` and blocking a thread.

This solves a real problem with plain `Future`: a `Future` from `submit()` only gives you `get()`, `isDone()`, and `cancel()`. There's no way to say "when this finishes, do X next" — you have to poll `isDone()` or call the blocking `get()` and sit there. `CompletableFuture` turns that into a pipeline: produce a value, transform it, combine it with another async value, react to it — all without blocking, and with the threading model fully under your control.

### Creating one

```java
// Starts a Supplier on a background thread, returns immediately
CompletableFuture<Integer> future = CompletableFuture.supplyAsync(
    () -> computeSomething(),
    executorService   // optional — defaults to ForkJoinPool.commonPool()
);

// No return value — wraps a Runnable instead
CompletableFuture<Void> task = CompletableFuture.runAsync(
    () -> doSomething(),
    executorService
);

// Already has a value right now — no async work at all
CompletableFuture<String> done = CompletableFuture.completedFuture("ready");
```

`supplyAsync` takes a `Supplier<T>` (you just covered this) — "go compute a `T` on some other thread." `runAsync` takes a `Runnable` — same idea but no result. Both return immediately with a `CompletableFuture` that is _incomplete_ until the background work finishes.

### Chaining stages

Once you have a `CompletableFuture`, you attach what happens next. This is where `Function`, `Consumer`, and `Runnable` come back in, each matching a different shape of "what's next":

```java
CompletableFuture<String> pipeline = CompletableFuture
    .supplyAsync(() -> fetchUserId(), executorService)      // Supplier<Integer>
    .thenApply(id -> "User-" + id)                          // Function<Integer, String>
    .thenApply(String::toUpperCase);                         // Function<String, String>

pipeline.thenAccept(name -> System.out.println(name));      // Consumer<String>
```

Every `thenX` call returns a _new_ `CompletableFuture`, so you're building a chain of stages, not mutating one object. Each stage only runs once the stage before it completes, and it receives that stage's result as input.

### Combining two independent futures

If two async computations don't depend on each other but you need both results, use `thenCombine` with a `BiFunction` (from the end of your last lesson):

```java
CompletableFuture<Integer> priceFuture = CompletableFuture.supplyAsync(() -> getPrice(), executorService);
CompletableFuture<Integer> taxFuture = CompletableFuture.supplyAsync(() -> getTax(), executorService);

CompletableFuture<Integer> total = priceFuture.thenCombine(taxFuture, (price, tax) -> price + tax);
```

Both `priceFuture` and `taxFuture` run concurrently on separate pool threads; `thenCombine` fires only once _both_ are done.

If instead you have a `CompletableFuture` that produces _another_ `CompletableFuture`, use `thenCompose` to flatten it instead of nesting (`Function<T, CompletionStage<R>>`):

```java
CompletableFuture<Order> orderFuture = CompletableFuture
    .supplyAsync(() -> fetchUserId(), executorService)
    .thenCompose(userId -> fetchOrderAsync(userId));   // fetchOrderAsync returns a CompletableFuture<Order>
```

Using `thenApply` here would give you a `CompletableFuture<CompletableFuture<Order>>` — a future wrapping a future. `thenCompose` collapses that one level, the same role `flatMap` plays for `Optional` or `Stream`.

### Error handling

A failure anywhere in the chain skips every subsequent `thenApply`/`thenAccept` stage and propagates the exception forward, wrapped in a `CompletionException`. You recover from it with `exceptionally` (a `Function<Throwable, T>` — supply a fallback value) or handle both success and failure uniformly with `handle` (a `BiFunction<T, Throwable, R>`, where exactly one of the two arguments is non-null):

```java
CompletableFuture<Integer> safe = CompletableFuture
    .supplyAsync(() -> riskyComputation(), executorService)
    .exceptionally(ex -> {
        System.err.println("Failed: " + ex.getMessage());
        return -1;
    });

CompletableFuture<String> handled = CompletableFuture
    .supplyAsync(() -> riskyComputation(), executorService)
    .handle((result, ex) -> ex != null ? "fallback" : "value: " + result);
```

### Sync vs. Async stage variants

Every chaining method (`thenApply`, `thenAccept`, `thenCompose`, `thenCombine`, `exceptionally`, etc.) has a matching `*Async` version: `thenApplyAsync`, `thenAcceptAsync`, and so on. The difference is which thread runs the stage:

- **Non-`Async`** (`thenApply`): runs on whichever thread completed the _previous_ stage. If the previous stage was already done by the time you attached this one, it may even run on the thread that called `thenApply` itself.
- **`Async`** (`thenApplyAsync`): always submitted to an executor — the common `ForkJoinPool` if you don't pass one, or an explicit `Executor` as the last argument if you do.

This matters in practice: if one stage is doing something cheap (formatting a string) you might not care which thread runs it, but if a stage does real work, you want to force it onto a pool with `*Async` so it never accidentally runs on a thread you need free — like a request-handling thread in a web server.

### Blocking when you actually need to

Despite the whole point being to avoid blocking, sometimes you do need the final value synchronously — at the boundary of your program, or in a test:

```java
Integer result = future.get();                        // blocks, throws checked ExecutionException/InterruptedException
Integer result2 = future.join();                       // blocks, throws unchecked CompletionException instead
```

`join()` is the one you'll reach for more often in chained code, since it doesn't force you to declare checked exceptions at every call site.

### Waiting on several futures at once

```java
CompletableFuture<Void> all = CompletableFuture.allOf(future1, future2, future3);
all.join();   // blocks until every one of them is done

CompletableFuture<Object> any = CompletableFuture.anyOf(future1, future2, future3);
```

`allOf` returns a `CompletableFuture<Void>` — it doesn't give you the individual results back directly, so you still call `.get()`/`.join()` on each original future afterward to collect them once you know they're all done. `anyOf` completes as soon as the _first_ of the given futures completes.


[[Threads]]