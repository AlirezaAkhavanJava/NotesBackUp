


## 1. Creating Threads Directly (Platform threads)



Java provides two primary ways to create threads: extending the `Thread` class or implementing the `Runnable` interface. Threads represent independent paths of execution within a program.

> `new Thread(target)` → creates the thread object.
 `t.start()` → tells the JVM to allocate an OS/virtual thread, schedule it, and begin execution.



- **Extending `Thread`**: Create a subclass of `Thread` and override its `run()` method.
- **Implementing `Runnable`**: Define a class that implements `Runnable`, then pass it to a `Thread` object. This is more flexible as it allows the class to extend another class.


> If you define one class that extends `Thread` (or implements `Runnable`), you can create **multiple thread objects** from it.



`Runnable` is preferred because Java supports single inheritance, and it promotes better separation of concerns. Both methods start threads with `thread.start()`, which calls `run()` in a new thread.

**Example: Extending `Thread`**

```java
public class ThreadExample extends Thread {
    @Override
    public void run() {
        for (int i = 0; i < 3; i++) {
            System.out.println("Thread " + getName() + ": " + i);
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    public static void main(String[] args) {
        ThreadExample thread1 = new ThreadExample();
        ThreadExample thread2 = new ThreadExample();
        thread1.start();
        thread2.start();
    }
}
```

**Explanation**: Two threads print numbers, running concurrently. Each thread has its own execution path.

**Example: Implementing `Runnable`**

```java
public class RunnableExample implements Runnable {
    @Override
    public void run() {
        for (int i = 0; i < 3; i++) {
            System.out.println("Thread " + Thread.currentThread().getName() + ": " + i);
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    public static void main(String[] args) {
        Runnable runnable = new RunnableExample();
        Thread thread1 = new Thread(runnable, "Runnable-Thread-1" /*name*/);
        Thread thread2 = new Thread(runnable, "Runnable-Thread-2");
        thread1.start();
        thread2.start();
    }
}
```

**Explanation**: A single `Runnable` instance is shared by two threads, demonstrating reusability.

---
### Tips : 

 >  Each **platform thread** eats memory (stack space, ~1–2 MB by default).
 >  
>   The OS can’t schedule that many efficiently. You’d run out of RAM or spend all CPU time context-switching.

>Better approaches:
>1. **Thread pools (ExecutorService)** → Reuse a fixed number of threads for many tasks.
>2. **Virtual threads (Java 21+)** → You _can_ spin up millions, since they are very lightweight and scheduled by the JVM, not the OS.
>

---
## 2. Using Thread Pools with `ExecutorService`



> Creating threads directly for every task is inefficient due to overhead. Thread pools reuse a fixed number of threads to execute tasks, reducing creation costs.



The `ExecutorService` interface (from `java.util.concurrent`) manages thread pools. The `Executors` utility class provides factory methods to create thread pools, like fixed-size or cached pools.


Thread pools handle task queuing and thread lifecycle. Common types:

- **Fixed Thread Pool**: Limited number of threads (e.g., `Executors.newFixedThreadPool(n)`).
> threads are reused forever (unless the pool is shut down).
- **Cached Thread Pool**: Creates threads as needed, reuses idle ones (`Executors.newCachedThreadPool()`).
> **Cached thread pool** → threads are reused _if another task arrives soon_. If a thread stays idle for 60 seconds, it’s destroyed and memory is freed.
- **Single Thread Executor**: One thread for all tasks (`Executors.newSingleThreadExecutor()`).


>**FixedThreadPool / SingleThreadExecutor** → use a **LinkedBlockingQueue** (unbounded). Tasks queue up if all threads are busy.
 **CachedThreadPool** → uses a **SynchronousQueue** (no capacity). That means a task can only be handed off directly to a free thread. If no thread is free, the pool spawns a new one instead of queuing.


**Example: Fixed Thread Pool**

```java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class ThreadPoolExample {
    public static void main(String[] args) {
        ExecutorService executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());

        Runnable task1 = () -> {
            for (int i = 0; i < 3; i++) {
                System.out.println("Task 1 on " + Thread.currentThread().getName() + ": " + i);
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        };

        Runnable task2 = () -> {
            for (int i = 0; i < 3; i++) {
                System.out.println("Task 2 on " + Thread.currentThread().getName() + ": " + i);
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        };

        executor.submit(task1);
        executor.submit(task2);
        executor.shutdown();
    }
}
```

**Explanation**: A pool with two threads executes two tasks. If more tasks are submitted, they queue until a thread is free.

## 3. Using `ExecutorService` with `Callable`


Unlike `Runnable`, `Callable` (from `java.util.concurrent`) allows threads to return results and throw checked exceptions.


`ExecutorService` supports `Callable` via `submit()`, which returns a `Future` object to retrieve results or check task status.


`Callable` is ideal for tasks needing results (e.g., computations). Use `Future.get()` to retrieve results, which blocks until completion. 

> Advanced: Use `CompletableFuture` for asynchronous, non-blocking operations.

**Example: Using `Callable`**

```java
import java.util.concurrent.*;

public class CallableExample {
    public static void main(String[] args) throws ExecutionException, InterruptedException {
        ExecutorService executor = Executors.newFixedThreadPool(2);

        Callable<Integer> task1 = () -> {
            int sum = 0;
            for (int i = 1; i <= 5; i++) {
                sum += i;
                Thread.sleep(100);
            }
            return sum;
        };

        Future<Integer> future1 = executor.submit(task1);
        System.out.println("Task 1 result: " + future1.get()); // Blocks until result

        executor.shutdown();
    }
}
```

**Explanation**: The `Callable` computes a sum and returns it via `Future`. The main thread waits for the result.

## 4. Other Ways: Fork/Join Framework



>The Fork/Join framework (from `java.util.concurrent`) is designed for parallelism, splitting tasks into smaller subtasks to run on multiple cores.




Use `ForkJoinPool` to execute `RecursiveTask` (returns a result) or `RecursiveAction` (no result). It’s ideal for divide-and-conquer algorithms (e.g., sorting).



Fork/Join uses work-stealing: idle threads take tasks from busy ones, optimizing CPU usage. Best for CPU-bound tasks with recursive patterns.

**Example: Fork/Join for Summing an Array**

```java
import java.util.concurrent.*;

public class ForkJoinExample extends RecursiveTask<Long> {
    private final int[] array;
    private final int start, end;
    private static final int THRESHOLD = 5;

    public ForkJoinExample(int[] array, int start, int end) {
        this.array = array;
        this.start = start;
        this.end = end;
    }

    @Override
    protected Long compute() {
        if (end - start <= THRESHOLD) {
            long sum = 0;
            for (int i = start; i < end; i++) {
                sum += array[i];
            }
            return sum;
        } else {
            int mid = start + (end - start) / 2;
            ForkJoinExample leftTask = new ForkJoinExample(array, start, mid);
            ForkJoinExample rightTask = new ForkJoinExample(array, mid, end);
            leftTask.fork(); // Run left task in parallel
            return rightTask.compute() + leftTask.join(); // Compute right, then get left result
        }
    }

    public static void main(String[] args) {
        int[] array = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
        ForkJoinPool pool = ForkJoinPool.commonPool();
        long sum = pool.invoke(new ForkJoinExample(array, 0, array.length));
        System.out.println("Sum: " + sum);
        pool.shutdown();
    }
}
```

**Explanation**: The array is split into smaller chunks, processed in parallel, and results are combined.

>  Executors/Threads → general-purpose concurrency.
Fork/Join → structured parallelism for CPU-bound tasks.


> ⚠️ Important: If your subtasks are **blocking I/O**, Fork/Join is **not ideal** — it’s designed for **CPU-bound, fast subtasks**.


>**Blocking I/O:** thread **sits and waits** until the operation finishes.
**Non-blocking I/O:** thread **starts the operation, goes off to do other work, and comes back** when it’s done.

## 5. Other Ways: Virtual Threads (Java 21+)


> Virtual threads (introduced in Java 21) are lightweight threads managed by the JVM, not the OS. They allow millions of threads with low overhead.


Virtual threads are ideal for I/O-bound tasks (e.g., web servers). Create them using `Thread.ofVirtual()` or `Executors.newVirtualThreadPerTaskExecutor()`.


Virtual threads reduce context-switching overhead and simplify concurrency for high-throughput apps. They integrate with existing `ExecutorService` APIs.

**Example: Virtual Threads**

```java
public class VirtualThreadExample {
    public static void main(String[] args) {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            executor.submit(() -> {
                System.out.println("Virtual Thread 1: " + Thread.currentThread());
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            });

            executor.submit(() -> {
                System.out.println("Virtual Thread 2: " + Thread.currentThread());
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            });
        }
    }
}
```

**Explanation**: Virtual threads run tasks concurrently with minimal overhead, ideal for scalable apps.

## Summary of Methods

|Method|Use Case|Pros|Cons|
|---|---|---|---|
|**Extend `Thread`**|Simple, one-off threads|Easy to implement|Limited flexibility|
|**Implement `Runnable`**|Reusable tasks|Flexible, reusable|Manual thread management|
|**Thread Pool**|Multiple tasks, reuse threads|Efficient, scalable|Complex setup|
|**Callable**|Tasks with results|Returns values, exceptions|Blocking with `Future.get()`|
|**Fork/Join**|Parallel, recursive tasks|Optimizes CPU usage|Complex for simple tasks|
|**Virtual Threads**|High-concurrency I/O tasks|Lightweight, scalable|Requires Java 21+|



###### Tags : [[44 - Threads 🧀]]