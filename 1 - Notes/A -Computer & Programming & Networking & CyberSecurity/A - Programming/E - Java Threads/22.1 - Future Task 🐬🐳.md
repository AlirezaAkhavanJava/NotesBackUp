 🐐`Future` in Java :  This is **not Optional**, even though it might look similar. `Future` is about **something that will be available later**, asynchronously.

---

### 1️⃣ What is `Future`?

- A `Future<V>` represents **the result of an asynchronous computation**.
    
- It’s like ordering pizza: you place the order, go do other stuff, and later you get the pizza (the result).
    
- It’s part of `java.util.concurrent`.
    

---

### 2️⃣ Core Methods

```java
V get()              // Waits if necessary for the computation to complete and returns the result.
V get(long timeout, TimeUnit unit)  // Waits up to a given time.
boolean cancel(boolean mayInterruptIfRunning)  // Cancels the task.
boolean isDone()     // True if computation is complete.
boolean isCancelled()// True if task was cancelled.
```

---

### 3️⃣ How to create a `Future`

You **don’t instantiate it directly**. You get it via an `ExecutorService`.

#### Example: `Callable` + `ExecutorService`

```java
import java.util.concurrent.*;

public class FutureExample {
    public static void main(String[] args) throws Exception {
        ExecutorService executor = Executors.newFixedThreadPool(2);

        Callable<String> task = () -> {
            Thread.sleep(2000); // simulate long computation
            return "Hello from the future!";
        };

        Future<String> future = executor.submit(task);

        System.out.println("Doing other stuff...");

        // Get the result (blocks until ready)
        String result = future.get();
        System.out.println("Result: " + result);

        executor.shutdown();
    }
}
```

**What happens here:**

1. `submit` sends the task to a thread pool.
    
2. You continue doing other work.
    
3. `future.get()` blocks until the task completes and returns the result.
    

---

### 4️⃣ Non-blocking check

You don’t have to block if you don’t want:

```java
if (future.isDone()) {
    System.out.println(future.get());
} else {
    System.out.println("Still computing...");
}
```

---

### 5️⃣ Cancel a Future

```java
future.cancel(true); // try to interrupt the task
```

- If it hasn’t started, it won’t run.
    
- If it’s running and `mayInterruptIfRunning = true`, it tries to stop the thread.
    

---

### 🐐 Tip:

- Use `Callable` when you need a result.
    
- Use `Runnable` with `submit` if you want `Future<?>` but don’t need a return value.
    
- `Future` is **blocking by default**, so for real async processing, `CompletableFuture` is often better.
    

---

*“Blocking” means your code waits and does nothing until the result is ready.*

*In the case of `Future`:*

```java
Future<String> future = executor.submit(task);
 String result = future.get(); // <-- blocking call
```

- *When you call `future.get()`, the thread pauses here until the task finishes.*
    
- *Nothing after `future.get()` runs until the task completes.*
    
- *So if your task takes 5 seconds, `get()` blocks for 5 seconds.*
    

---

*Contrast with non-blocking:*

- *You could check `future.isDone()` first, and only call `get()` if ready.*
    
- *Or use `CompletableFuture`, which lets you run code after completion without blocking.*
    

*🐐 Analogy: Blocking is like standing at the pizza shop until your pizza is ready. Non-blocking is like ordering the pizza and going home to play video games; when the pizza arrives, someone notifies you.*

---

### 1️⃣ The rule:

|You want…|Use…|Why|
|---|---|---|
|**A result from a task**|`Callable` + `Future`|Callable can return a value; Future lets you get it later.|
|**No result, just know when it’s done**|`Runnable` + `Future`|Runnable doesn’t return anything; Future can tell you when it’s done.|
|**Manual thread control**|`Thread`|You run code asynchronously, but must manage results yourself.|

---

### 2️⃣ How Future works

- `Future` **never stands alone**. You get it from an **ExecutorService**:
    

```java
ExecutorService executor = Executors.newFixedThreadPool(1);
Future<V> future = executor.submit(task);
```

- `future.get()` → **blocks** until the task completes.
    
- `future.isDone()` → check without blocking.
    
- `future.cancel(true)` → stop the task if possible.
    

---

### 3️⃣ Simple template

#### With `Callable` (recommended if you need a result)

```java
Callable<Integer> task = () -> {
    // long computation
    return 42;
};
Future<Integer> future = executor.submit(task);
Integer result = future.get(); // blocks until ready
```

#### With `Runnable` (if no result needed)

```java
Runnable task = () -> { /* do stuff */ };
Future<?> future = executor.submit(task);
future.get(); // blocks until done
```

---

### 4️⃣ 🐐 Tip

- **Always prefer `Callable` if you need a return value**.
    
- `Runnable` is only for “fire and wait” tasks.
    
- Avoid raw `Thread` unless you really need manual control.
    

---


[[44 - Threads 🧀]]