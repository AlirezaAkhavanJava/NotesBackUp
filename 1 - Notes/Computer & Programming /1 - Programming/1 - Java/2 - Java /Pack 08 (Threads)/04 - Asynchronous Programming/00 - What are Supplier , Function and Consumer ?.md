

These three come from `java.util.function`, and they're not thread-specific on their own — they're general-purpose "shapes of work" that Java uses everywhere functional programming shows up. The reason they matter for threading is `CompletableFuture`: its whole async API is built around handing it one of these interfaces instead of a `Runnable` or `Callable`, because each one captures a different kind of step in a pipeline — "produce a value," "transform a value," "consume a value and produce nothing." Once you know the three shapes, the entire `CompletableFuture` chaining API (`supplyAsync`, `thenApply`, `thenAccept`, and their threaded siblings) becomes predictable instead of memorized.

### `Supplier<T>` — takes nothing, returns something

```java
Supplier<Integer> randomNumber = () -> ThreadLocalRandom.current().nextInt(100);
Integer value = randomNumber.get();
```

One abstract method: `T get()`. It's the "go produce a value for me" shape. This is exactly what a background thread does when it computes something and hands the result back — which is why `CompletableFuture.supplyAsync(Supplier<T>)` exists: it runs the supplier on a separate thread (from the common `ForkJoinPool` by default, or a pool you pass in) and gives you back a `CompletableFuture<T>` holding the eventual result.

```java
CompletableFuture<Integer> future = CompletableFuture.supplyAsync(
    () -> ThreadLocalRandom.current().nextInt(100),
    executorService
);
```

Compare this to `Callable<T>`, which you already know from `ExecutorService.submit(Callable<T>)` — same shape (no input, returns a value), except `Callable.call()` is allowed to throw a checked exception and `Supplier.get()` is not. `Supplier` is the "promise there's no checked exception" version of the same idea.

### `Function<T, R>` — takes something, returns something (possibly different type)

```java
Function<String, Integer> length = s -> s.length();
Integer len = length.apply("hello");
```

One abstract method: `R apply(T t)`. This is the "transform" shape. In a threading pipeline, once you have a value (from a `Supplier` running on another thread), you often want to turn it into a different value without blocking the current thread to do it. That's `thenApply`:

```java
CompletableFuture<String> future = CompletableFuture
    .supplyAsync(() -> fetchUserId(), executorService)
    .thenApply(userId -> "User-" + userId);
```

`thenApply` runs on whichever thread completed the previous stage (unless you use `thenApplyAsync`, which forces it onto the pool instead — useful if the previous stage finished on a thread you don't want doing more work, like a request thread). `Function` composes too, which matters once chains get long: `length.andThen(n -> n * 2)` or `otherFunction.compose(length)`.

### `Consumer<T>` — takes something, returns nothing

```java
Consumer<String> printer = s -> System.out.println("Got: " + s);
printer.accept("done");
```

One abstract method: `void accept(T t)`. This is the "end of the line" shape — you have a value, you do something with it (log it, save it, display it), and there's nothing further to pass on. In `CompletableFuture`, that's `thenAccept`:

```java
CompletableFuture
    .supplyAsync(() -> fetchUserId(), executorService)
    .thenApply(id -> "User-" + id)
    .thenAccept(name -> System.out.println("Resolved: " + name));
```

Notice the shape of the whole chain: `Supplier` starts it, any number of `Function`s transform it, `Consumer` finishes it. If there's truly nothing to pass in _or_ out at some step, that's `Runnable`, matched by `thenRun`.

### The `*Async` variants — where the actual threading decision lives

Every one of `thenApply`, `thenAccept`, `thenRun`, `thenCombine`, etc. has an `*Async` twin (`thenApplyAsync`, `thenAcceptAsync`...). The non-`Async` version runs on whatever thread just finished the prior stage — which could be your main thread if the prior stage was already done when you attached the callback, or a pool thread if it wasn't. The `Async` version always submits the work to an executor (the common pool, or one you supply as a second argument), guaranteeing it runs on a pool thread rather than piggybacking on whichever thread happened to get there first. This is the actual point where `Supplier`/`Function`/`Consumer` connect to thread _scheduling_ rather than just being generic plumbing — deciding which stages need `Async` is a real design choice once you're mixing a request-handling thread (don't want to tie it up) with pool threads (fine to chain work on).

### A short related note: `BiFunction` and `BiConsumer`

If a step needs two inputs instead of one — for example `CompletableFuture.thenCombine`, which merges the results of two independent async computations — Java has two-argument versions: `BiFunction<T, U, R>` (`R apply(T t, U u)`) and `BiConsumer<T, U>` (`void accept(T t, U u)`). Same shapes, just arity two. You'll meet these the moment you start combining two parallel `CompletableFuture`s instead of chaining one.


[[Threads]]