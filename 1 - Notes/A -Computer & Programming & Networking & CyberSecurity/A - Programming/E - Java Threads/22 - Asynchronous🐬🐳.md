Date : 2025-09-13
Concept : Asynchronous Programming
Course : [Asynchronous Programming in Java: Options to Choose from By Venkat Subramaniam](https://www.youtube.com/watch?v=1zSF1259s6w)
Tags : [[44 - Threads 🧀]]


This guide explains **asynchronous programming** in Java in a clear, structured way. You’ll learn how to run tasks without blocking your main thread, how Java handles async tasks, and how this works in real-world applications and frameworks like Spring Boot. Examples are included with explanations for easy understanding.

---

## 1. Understanding Asynchronous Programming

**Concept:**  
Asynchronous programming allows your program to start a task and continue doing other things before the task finishes.

**Analogy:**  
It’s like ordering food at a restaurant and reading a book while waiting, instead of standing in the kitchen staring at the chef.

**Why it matters:**  
Without async programming, your program waits for each task to finish, making it slow or unresponsive—especially for tasks like network calls, file I/O, or database queries.

**Example: Using `CompletableFuture`**

```java
import java.util.concurrent.CompletableFuture;

public class AsyncExample {
    public static void main(String[] args) {
        CompletableFuture.supplyAsync(() -> {
            try {
                Thread.sleep(1000); // Simulate a long task
                return "Task completed!";
            } catch (InterruptedException e) {
                return "Error: " + e.getMessage();
            }
        }).thenAccept(result -> System.out.println("Result: " + result));

        System.out.println("Main thread continues...");
    }
}
```

**Explanation:**

- `supplyAsync()` runs a task on a background thread.
    
- `thenAccept()` handles the result when ready.
    
- Meanwhile, the main thread keeps running.
    

---

## 2. How Threads Enable Async Programming

**Concept:**  
Threads are the units of execution in Java. Async programming often relies on threads (or lightweight virtual threads in Java 21+) to run tasks without blocking the main thread.

**Key Tools:**

- ExecutorService → manages pools of threads.
    
-   CompletableFuture → easier way to handle async results.
    
-   Virtual threads → lightweight threads for massive concurrency.
    

**Example: Virtual Thread**

```java
import java.util.concurrent.Executors;

public class VirtualThreadAsync {
    public static void main(String[] args) {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            executor.submit(() -> {
                Thread.sleep(1000);
                System.out.println("Async task on " + Thread.currentThread());
            });
            System.out.println("Main thread moves on...");
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

**Explanation:**  
The virtual thread runs in the background, leaving the main thread free. Virtual threads are cheap and ideal for I/O-heavy tasks.

---

## 3. Concurrency vs Parallelism

**Concurrency:** Multiple tasks progress independently, possibly overlapping in time.  
**Parallelism:** Tasks run literally at the same time on multiple CPU cores.

**How Async fits in:**

- Async programming improves concurrency by letting tasks run in the background.
    
- CPU-bound tasks can also be executed in parallel if you have multiple threads or cores.
    

**Tip:** ==For I/O-heavy apps, focus on concurrency; for CPU-heavy tasks, combine async programming with parallel execution.==

---

## 4. Real-World Applications

**Apps that rely on async programming:**

- **Obsidian:** Syncs files and searches notes without freezing the UI.
    
- **Music players:** Stream audio while allowing user interaction.
    
- **Google Chrome:** Each tab runs tasks asynchronously to prevent freezes.
    

**Example: Simulating File Sync**

```java
import java.util.concurrent.CompletableFuture;

public class FileSyncExample {
    public static void main(String[] args) {
        CompletableFuture.runAsync(() -> {
            Thread.sleep(2000);
            System.out.println("File sync completed on " + Thread.currentThread().getName());
        });

        System.out.println("UI remains responsive...");
    }
}
```

**Explanation:**  
Async tasks allow UI or main thread to remain interactive while background tasks finish.

---

## 5. Async Programming in Spring Boot

**Concept:** Spring Boot provides simple async execution via `@Async`.

**Setup:**

1. Enable async: `@EnableAsync`
    
2. Define a thread pool with `ThreadPoolTaskExecutor`
    
3. Mark methods with `@Async`
    

**Example: Spring Boot Async**

```java
@SpringBootApplication
@EnableAsync
public class SpringAsyncApp {

    public static void main(String[] args) {
        SpringApplication.run(SpringAsyncApp.class, args);
    }

    @Bean
    public Executor taskExecutor() {
        var executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(2);
        executor.setQueueCapacity(500);
        executor.setThreadNamePrefix("AsyncThread-");
        executor.initialize();
        return executor;
    }

    @Async
    public CompletableFuture<String> asyncMethod() throws InterruptedException {
        Thread.sleep(1000);
        return CompletableFuture.completedFuture("Task done on " + Thread.currentThread().getName());
    }
}
```

**Explanation:**  
`@Async` runs the method on a background thread. `CompletableFuture` allows handling the result asynchronously.

---

## 6. Callbacks in Java

**Concept:** A callback is a function that runs when a task is done.

**Ways to implement:**

1. **Interface-based callback**
    
2. **Lambda expressions**
    
3. **CompletableFuture for async tasks**
    
4. **GUI event listeners**
    

**Example: Lambda Callback**

```java
interface Callback { 
	void done(String message); 
}

class Worker {
    void doWork(Callback callback) {
        System.out.println("Working...");
        callback.done("Finished!");
    }
}

public class Main {
    public static void main(String[] args) {
        Worker worker = new Worker();
        worker.doWork(message -> System.out.println("Got message: " + message));
    }
}
```

**Explanation:**  
The lambda function runs when the work is finished, acting as a simple callback.

---

## 7. Future in Java

**Concept:** A `Future` represents a result that will be available later.

**Analogy:** Ordering a package online. You get a tracking number (`Future`) and can check if it’s delivered (`isDone()`), then open it (`get()`) when it arrives.

**Example: Using Future**

```java
ExecutorService executor = Executors.newFixedThreadPool(1);

Future<Integer> future = executor.submit(() -> {
    Thread.sleep(2000);
    return 42;
});

System.out.println("Doing other work...");
Integer result = future.get(); // waits until done
System.out.println("Result is: " + result);
executor.shutdown();
```

**Explanation:**

- `submit()` starts a background task.
    
- `get()` waits for the result.
    
- `isDone()` can check if the task is complete without blocking.
    

**Tip:** For chaining tasks or handling multiple async results, use `CompletableFuture`.

---

## 8. Coordinating Multiple Async Tasks

```java
CompletableFuture<String> task1 = CompletableFuture.supplyAsync(() -> "Task 1 done");
CompletableFuture<String> task2 = CompletableFuture.supplyAsync(() -> "Task 2 done");

CompletableFuture.allOf(task1, task2).thenRun(() -> {
    System.out.println(task1.join() + " and " + task2.join());
});
```

**Explanation:**  
`allOf()` waits for multiple tasks to finish before executing the next step. Useful for coordinating async work.

---

✅ **Key Takeaways**

- Async programming frees the main thread to perform other work.
    
- `CompletableFuture` and virtual threads simplify handling async tasks.
    
- `Future` represents a placeholder for results of async operations.
    
- Spring Boot and GUI apps integrate async to improve responsiveness.
    
- Callbacks allow executing code when tasks finish.
    

---
