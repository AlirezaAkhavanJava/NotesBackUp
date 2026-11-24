
Runnable is one of Java's functional interfaces — it represents a single unit of work (a "task") without any opinion on how that work actually gets run on a thread. That separation is the whole point: `Runnable` is just _what_ to do, and `Thread`, `ExecutorService`, or anything else that accepts one is _how_ it gets executed. Understanding it well means understanding both the interface itself and the different "references" to it — the different ways code can hand a `Runnable` to something that will run it.

## The interface itself

```java
@FunctionalInterface
public interface Runnable {
    void run();
}
```

One abstract method, no parameters, no return value, and critically — it declares no checked exceptions. That last part matters: if your task logic can throw a checked exception (like `IOException`), you cannot let it escape `run()` as-is; you have to catch it inside or wrap it in an unchecked exception. This is one of the real limitations of `Runnable` compared to `Callable<V>` (which you've already seen — `Callable.call()` _can_ throw checked exceptions and _does_ return a value).

## The different ways to "reference" a Runnable

Since it's a functional interface, there isn't just one way to produce a `Runnable` — there are four, and which one you reach for depends on the situation.

**1. Anonymous class** — verbose, but makes the object nature explicit:

```java
Runnable task = new Runnable() {
    @Override
    public void run() {
        System.out.println("Running on: " + Thread.currentThread().getName());
    }
};
```

**2. Lambda expression** — the common modern form, since `run()` takes no args and returns nothing:

```java
Runnable task = () -> System.out.println("Running on: " + Thread.currentThread().getName());
```

**3. Method reference to an existing method** — when the method you want to run already matches `void methodName()`:

```java
public class ReportJob {
    public void generate() {
        System.out.println("Generating report...");
    }
}

ReportJob job = new ReportJob();
Runnable task = job::generate;   // bound instance method reference
```

This works because `generate()`'s signature (`void`, no params) matches `run()`'s exactly. If the method were `static`, you'd reference it as `ClassName::methodName` instead.

**4. Constructor reference**, when a class's constructor itself does the work and returns nothing meaningful you need to keep:

```java
Runnable task = Logger::new; // only valid if Logger's constructor matches a no-arg, void-effective shape
```

(less common in practice — you'll mostly use #2 and #3.)

## Where a Runnable reference actually gets used

This is the part that ties back into what you've already learned about thread creation:

```java
// 1. Directly on a Thread
Thread t = new Thread(task);
t.start();

// 2. Handed to an ExecutorService (preferred over raw Thread in real code)
ExecutorService pool = Executors.newFixedThreadPool(4);
pool.execute(task);              // fire-and-forget, returns void
Future<?> future = pool.submit(task); // tracked, but future.get() always returns null for a Runnable

// 3. Scheduled, recurring work
ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);
scheduler.scheduleAtFixedRate(task, 0, 5, TimeUnit.SECONDS);

// 4. Async composition
CompletableFuture.runAsync(task); // runs on the common ForkJoinPool by default
```

Notice `submit(Runnable)` still gives you back a `Future<?>` — you get a handle you can cancel or wait on with `get()`/`isDone()`, but the generic type is a wildcard because there's genuinely nothing to return. If you need a result, that's exactly the signal to reach for `Callable<V>` instead and call `submit(Callable<V>)`.

## Why `Runnable` exists instead of just always extending `Thread`

Java only allows single inheritance — a class can extend only one superclass. If your task class extends `Thread`, it can never extend anything else. Implementing `Runnable` costs you nothing in that sense: your class stays free to extend whatever it needs, and the `Runnable` instance gets handed to a `Thread` (or a pool) as data, not as the class's own identity. This is also why `Runnable` composes cleanly with executor pools — a pool thread isn't "becoming" your task class, it's just invoking `run()` on an object it was given.


[[Threads]]