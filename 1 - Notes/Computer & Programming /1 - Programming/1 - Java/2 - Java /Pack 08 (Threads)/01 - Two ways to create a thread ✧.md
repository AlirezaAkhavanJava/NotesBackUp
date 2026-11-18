
Creating a thread in Java means giving the JVM a task and asking it to run that task on a new thread. You can do this by subclassing `Thread` or by passing a `Runnable`, and you should know why `start()` matters more than `run()`. You'll also see how `synchronized` fixes shared-state bugs and why real code usually uses thread pools.

## Two ways to create a thread

**Extending `Thread`:**

```java
class MyTask extends Thread {
    @Override
    public void run() {
        System.out.println("Running in: " + Thread.currentThread().getName());
    }
}

new MyTask().start();
```

`MyTask` inherits from `Thread` and overrides `run()`, which holds the work. `start()` asks the JVM to create a new thread and call `run()` on it.

**Implementing `Runnable` (preferred):**

```java
Runnable task = () -> System.out.println("Running in: " + Thread.currentThread().getName());
new Thread(task).start();
```

`Runnable` is a functional interface with one method, `void run()`. The lambda supplies that method, and `Thread` runs it. This version is preferred because your task is separate from the thread that runs it, and Java doesn't limit you to one parent class.

## `start()` vs. `run()`

```java
task.run();   // runs on the CURRENT thread; no concurrency
task.start(); // creates a NEW thread, which then calls run()
```

Calling `run()` directly is an ordinary method call, so no new thread is created. Always use `start()` when you want concurrency.

## Fixing a race condition with `synchronized`

```java
class Counter {
    private int count = 0;

    synchronized void increment() { // only one thread at a time
        count++;
    }

    int getCount() { return count; }
}
```

`count++` is really three steps: **read, add one, write back**. Without protection, two threads can read the same value and one update gets lost. 

The `synchronized` keyword makes threads take turns on that method, so each increment finishes before another starts. Two threads each calling `increment()` 1000 times now always produce 2000.

## Thread pools with `ExecutorService`

Creating a new `Thread` for every task is wasteful. A thread pool reuses a fixed set of threads:

```java
import java.util.concurrent.*;

ExecutorService executor = Executors.newFixedThreadPool(4);

for (int i = 0; i < 10; i++) {
    int taskId = i;
    executor.submit(() -> System.out.println("Task " + taskId + " on " + Thread.currentThread().getName()));
}

executor.shutdown();
```


![[b37946d0-f6ab-4b49-9a46-92283794ed15 1.png]]


`newFixedThreadPool(4)` creates four reusable threads. `submit()` queues each task, and whichever thread is free picks it up, so ten tasks run on four threads. `shutdown()` stops accepting new tasks and lets the queued ones finish. Without it, the JVM can keep running because pool threads are still alive.



[[Threads]]