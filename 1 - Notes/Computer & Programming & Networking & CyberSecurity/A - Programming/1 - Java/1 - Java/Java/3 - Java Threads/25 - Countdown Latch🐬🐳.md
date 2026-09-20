Date : 2025-09-05


In Java, a **CountDownLatch** is a synchronization aid provided by the `java.util.concurrent` package that allows one or more threads to wait until a set of operations being performed in other threads completes. It is used to ensure that a particular task does not proceed until a specified number of events or tasks have occurred.

Think of a **CountdownLatch** like a **door that won’t open until everyone you’re waiting for has arrived**.

- You give it a number (say `3`).
    
- That means: _“Don’t let the door open until 3 people show up and say ‘I’m here’.”_
    
- Each time someone says **`countDown()`**, the latch number goes down by 1.
    
- When it reaches **0**, the door opens → threads waiting on `await()` can finally move.

**CountDownLatch is not a thread itself.** It’s a _tool_ used to **coordinate** (**decide when threads are allowed to move forward**.) threads. You don’t “run” it like a pool; you _use it inside_ threads, executors, or pools to manage execution order.

### Typical Uses

1. **Waiting for workers to finish**
    
    - Example: Main thread waits until N background tasks are done.
        
    - Common in **thread pools** where you submit jobs and then wait on the latch.
        
2. **Starting threads at the same time**
    
    - Example: A race condition test → multiple threads wait on a latch, and then you release them all at once.
        
    - Used in **concurrency testing** and performance benchmarking.
        
3. **Service startup dependencies**
    
    - Example: App needs **Database**, **Cache**, and **Message Broker** started before serving requests.
        
    - Each service thread calls `countDown()` when ready. Main thread waits with `await()`.
        
4. **Replacing complex wait/notify logic**
    
    - Easier alternative to manually using `Object.wait()` and `Object.notify()`.
        

### Where it fits

- **Thread operations**  (used to synchronize between threads).
    
- **ExecutorService / ThreadPools**  (workers in a pool call `countDown()`; main thread `await()`s).
    
- **Standalone Threads**  (just create raw `Thread` objects and use it).
    
- **NOT** for running tasks itself  (that’s the job of a pool or scheduler).
    

 In short: it’s **glue** for coordination, not a runner.

### Key Concepts of CountDownLatch:
- **Initialization**: A `CountDownLatch` is initialized with a count, which represents the number of events or tasks that must complete before the latch is released.
- **Counting Down**: Threads call the `countDown()` method to decrement the count when they complete their task. Each call reduces the count by one.
- **Awaiting**: Threads that need to wait for the latch to reach zero call the `await()` method, which blocks until the count reaches zero.
- **Non-reusable**: Once the count reaches zero, the latch is released, and it cannot be reused. A new `CountDownLatch` must be created for further use.

### How It Works:
1. Create a `CountDownLatch` with a specific count:
   ```java
   CountDownLatch latch = new CountDownLatch(3); // Initialize with count 3
   ```
2. Threads performing tasks call `countDown()` when their work is done:
   ```java
   latch.countDown(); // Decrement the count
   ```
3. Threads that need to wait for all tasks to complete call `await()`:
   ```java
   latch.await(); // Blocks until count reaches 0
   ```
4. Optionally, `await()` can take a timeout:
   ```java
   latch.await(5, TimeUnit.SECONDS); // Wait for 5 seconds max
   ```

### Example Use Case:
Suppose you have a program where a main thread needs to wait for three worker threads to complete their tasks before proceeding.

```java
import java.util.concurrent.CountDownLatch;

public class CountDownLatchExample {
    public static void main(String[] args) throws InterruptedException {
        CountDownLatch latch = new CountDownLatch(3);

        // Create three worker threads
        for (int i = 1; i <= 3; i++) {
            final int taskId = i;
            new Thread(() -> {
                System.out.println("Task " + taskId + " is running");
                try {
                    Thread.sleep(1000); // Simulate work
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println("Task " + taskId + " completed");
                latch.countDown(); // Signal task completion
            }).start();
        }

        System.out.println("Main thread waiting for tasks to complete...");
        latch.await(); // Wait until all tasks are done
        System.out.println("All tasks completed, main thread proceeding.");
    }
}
```

### Output (example):
```
Main thread waiting for tasks to complete...
Task 1 is running
Task 2 is running
Task 3 is running
Task 1 completed
Task 2 completed
Task 3 completed
All tasks completed, main thread proceeding.
```

### Key Methods:
- `CountDownLatch(int count)`: Constructs a `CountDownLatch` with the given count.
- `void countDown()`: Decrements the count. If the count reaches zero, waiting threads are released.
- `void await()`: Causes the current thread to wait until the count reaches zero or the thread is interrupted.
- `boolean await(long timeout, TimeUnit unit)`: Waits for the count to reach zero, up to the specified timeout.
- `long getCount()`: Returns the current count.

### When to Use:
- When you need to coordinate the start of one or more threads after a set of prerequisite tasks are completed (e.g., initializing resources before starting a process).
- Common in scenarios like parallel processing, where a main thread needs to wait for multiple worker threads to finish.

### Notes:
- **Thread Safety**: `CountDownLatch` is thread-safe and designed for concurrent use.
- **Not Reusable**: Unlike other synchronization tools like `CyclicBarrier`, a `CountDownLatch` cannot be reset once the count reaches zero.
- **Exceptions**: If a thread calling `await()` is interrupted, it throws an `InterruptedException`.

```java
import java.util.concurrent.CountDownLatch;

public class SimpleLatchExample {
    public static void main(String[] args) throws InterruptedException {
        // Latch waiting for 3 threads
        CountDownLatch latch = new CountDownLatch(3);

        for (int i = 1; i <= 3; i++) {
            int id = i;
            new Thread(() -> {
                System.out.println("Worker-" + id + " doing work");
                try { Thread.sleep(1000); } catch (InterruptedException e) {}
                System.out.println("Worker-" + id + " finished");
                latch.countDown(); // signal done
            }).start();
        }

        System.out.println("Main thread waiting for workers...");
        latch.await(); // blocks until all 3 workers call countDown()
        System.out.println("All workers finished. Main thread proceeds.");
    }
}

```

### With Executors : 


```java
import java.util.concurrent.*;

public class ExecutorLatchExample {
    public static void main(String[] args) throws InterruptedException {
        int workerCount = 5;
        CountDownLatch latch = new CountDownLatch(workerCount);
        ExecutorService executor = Executors.newFixedThreadPool(workerCount);

        for (int i = 1; i <= workerCount; i++) {
            int id = i;
            executor.submit(() -> {
                System.out.println("Worker-" + id + " doing work");
                try { Thread.sleep(500); } catch (InterruptedException e) {}
                System.out.println("Worker-" + id + " finished");
                latch.countDown(); // signal done
            });
        }

        System.out.println("Main thread waiting for executor tasks...");
        latch.await(); // waits for all workers
        System.out.println("All executor tasks done. Main thread proceeds.");

        executor.shutdown();
    }
}

```

---
## **Example: CountDownLatch + Callable**

```java
import java.util.concurrent.*;

public class CallableLatchExample {
    public static void main(String[] args) throws InterruptedException, ExecutionException {
        int taskCount = 3;
        CountDownLatch latch = new CountDownLatch(taskCount);
        ExecutorService executor = Executors.newFixedThreadPool(taskCount);

        Callable<String> task = () -> {
            try {
                String threadName = Thread.currentThread().getName();
                System.out.println(threadName + " started work");
                Thread.sleep(1000); // simulate work
                return threadName + " result";
            } finally {
                latch.countDown(); // signal done even if exception occurs
            }
        };

        Future<String>[] futures = new Future[taskCount];
        for (int i = 0; i < taskCount; i++) {
            futures[i] = executor.submit(task);
        }

        System.out.println("Main thread waiting for all tasks to complete...");
        latch.await(); // blocks until all Callables call countDown
        System.out.println("All tasks completed. Collecting results...");

        for (Future<String> f : futures) {
            System.out.println(f.get());
        }

        executor.shutdown();
    }
}

```

**How it works:**

1. Submit multiple **Callable tasks** to an executor.
    
2. Each task calls `latch.countDown()` when finished.
    
3. Main thread calls `latch.await()` → **waits until all tasks complete**, then collects results.



---
### `Thread.join()`

- Only works for **one thread** at a time.
    
- Example:
    

`t1.start(); t1.join(); // main waits until t1 finishes`

### `CountDownLatch`

- Can wait for **many threads at once**.
    
- Example:
    

`CountDownLatch latch = new CountDownLatch(3); for (Thread t : threads) t.start(); // each thread calls latch.countDown() when done latch.await(); // main waits for all 3`

✅ Advantage: waiting for **multiple threads simultaneously** without chaining joins.  
❌ Disadvantage: one-shot. Once count hits 0, you can’t reuse it (unlike join, which you can call again on a new thread).

So: **join = wait for one thread**; **CountDownLatch = wait for N threads**


---
**Different beasts.**

- **`wait/notify`** → low-level. You manually coordinate threads on an object’s monitor. One thread `wait()`s, another thread `notify()`s. Pain in the ass, easy to screw up (missed signals, deadlocks, etc.).
    
- **`CountDownLatch`** → higher-level utility built on top of that. Cleaner, safer, less code. Instead of juggling locks and signals, you just say:
    
    - "I’m waiting for X things." (`await()`)
        
    - "I finished one thing." (`countDown()`)
        

👉 Big difference:

- `wait/notify` is like **walkie-talkies**: you keep yelling and hope the other guy heard you.
    
- `CountDownLatch` is like a **counting gate**: it _guarantees_ the door only opens when the count hits zero.

- `wait/notify` = two people using walkie-talkies and manually telling each other “done.”
    
- `CountDownLatch` = a **gate** that automatically opens once the set number of workers has reported done.





##### *Tags : [[44 - Threads 🧀]]