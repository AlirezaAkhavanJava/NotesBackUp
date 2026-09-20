Date : 2025-08-27
Tags :  [[44 - Threads 🧀]] 

---
## 1. What is Concurrency?


Concurrency is handling multiple tasks at once, but not necessarily running them simultaneously. It’s like a single chef juggling multiple dishes—switching between tasks. In Java, threads (lightweight units of execution) share a CPU core, with the JVM switching between them to give the illusion of simultaneous progress.


Concurrency uses context switching: the system ***saves one thread’s state and loads another’s* .** This is ideal for I/O-bound tasks (e.g., waiting for a file or network response), where threads yield time to others.
![[Pasted image 20251122080952.png]]


Concurrency can cause issues like race conditions (threads accessing shared data unpredictably) or deadlocks (threads waiting forever). Java provides synchronization tools like `synchronized` blocks or `java.util.concurrent` locks to manage these.

**Example**: A simple Java program with two threads running concurrently, sharing a single core:

```java
class Counter {
    private int count = 0;

    public void increment() {
        count++; // Not thread-safe; needs synchronization
    }

    public int getCount() {
        return count;
    }
}

class MyThread extends Thread {
    private Counter counter;
    private String name;

    public MyThread(Counter counter, String name) {
        this.counter = counter;
        this.name = name;
    }

    @Override
    public void run() {
        for (int i = 0; i < 1000; i++) {
            counter.increment();
            System.out.println(name + ": " + counter.getCount());
        }
    }
}

public class ConcurrencyExample {
    public static void main(String[] args) {
        Counter counter = new Counter();
        MyThread t1 = new MyThread(counter, "Thread-1");
        MyThread t2 = new MyThread(counter, "Thread-2");

        t1.start();
        t2.start();
    }
}
```

**Explanation**: Two threads increment a shared counter. Without synchronization, the output is unpredictable due to race conditions.

## 2. What is Parallelism?



Parallelism is executing multiple tasks truly simultaneously on multiple CPU cores. It’s like multiple chefs cooking different dishes at once. In Java, threads run on separate cores for faster computation.

> Focus is on the performance(speed)

Modern CPUs (multi-core) enable parallelism. The JVM distributes threads across cores automatically if hardware supports it.



Parallelism excels in CPU-bound tasks (e.g., calculations). Java’s Fork/Join framework splits tasks for parallel execution. Overhead comes from thread creation and inter-core communication.

- **Parallelism** is indeed best for **CPU-bound tasks** like number crunching, simulations, or image processing.
    
- The **Fork/Join framework** in Java works by recursively splitting a big problem into smaller subproblems (fork), then combining results (join).
    
- **Overhead sources**:
    
    - Thread creation (though Fork/Join reuses a pool to reduce this).
        
    - Context switching between threads.
        
    - Synchronization and inter-core communication (cache coherence, memory barriers).

**Example**: Using `parallelStream` to process a list in parallel:

```java
import java.util.Arrays;
import java.util.List;

public class ParallelismExample {
    public static void main(String[] args) {
        List<Integer> numbers = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

        // Parallel processing of numbers
        numbers.parallelStream()
               .map(n -> n * n) // Square each number
               .forEach(System.out::println);
    }
}
```

**Explanation**: The `parallelStream` splits the list across cores, squaring numbers simultaneously.

## 3. Key Differences Between Concurrency and Parallelism


- **Concurrency**: Tasks interleaved on one core (like multitasking in a single kitchen).
- **Parallelism**: Tasks run simultaneously on multiple cores (multiple kitchens).


> Concurrency works on single-core systems; parallelism needs multi-core. 
> 
> Concurrency focuses on responsiveness; parallelism targets speed


Concurrency manages I/O waits (e.g., UI responsiveness); parallelism optimizes CPU-intensive tasks. Concurrency has context-switching costs; parallelism has inter-core communication overhead.

|Aspect|Concurrency|Parallelism|
|---|---|---|
|Execution|Interleaved on one core|Simultaneous on multiple cores|
|Hardware Need|Single-core OK|Multi-core required|
|Focus|Responsiveness, handling waits|Speed, compute-intensive|
|Java Example|Threaded web server|Parallel data processing|

## 4. Concurrency and Parallelism in Modern Programming


In modern Java (e.g., Java 21), concurrency and parallelism are built-in for efficient apps. Threads leverage OS and hardware capabilities.


Java uses thread pools (`ExecutorService`) to reuse threads, reducing overhead. ==Libraries like Project Reactor handle asynchronous concurrency.==



Java 21’s virtual threads enable massive concurrency (millions of threads) with low overhead. Parallelism uses hardware threads for CPU-bound tasks. Modern apps combine both: concurrency for I/O, parallelism for computation.

**In Java**: Both concurrency (any hardware) and parallelism (multi-core) are supported via `java.util.concurrent`.

**Example**: Using `ExecutorService` for concurrent task execution:

``` java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class ExecutorExample {
    public static void main(String[] args) {
        ExecutorService executor = Executors.newFixedThreadPool(2);

        Runnable task1 = () -> {
            for (int i = 0; i < 3; i++) {
                System.out.println("Task 1: " + i);
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        };

        Runnable task2 = () -> {
            for (int i = 0; i < 3; i++) {
                System.out.println("Task 2: " + i);
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

**Explanation**: Two tasks run concurrently in a thread pool, sharing CPU resources.

---

## 5. Concurrency and Parallelism in Multiple Apps (e.g., Obsidian, Music Player, Chrome)

### Basics

When running apps like Obsidian, a music player, and Chrome, the OS manages concurrency (switching between apps) and parallelism (using multiple cores). Each app runs in a separate process with its own threads.

### Intermediate

- **Across Apps (Multitasking)**: The OS interleaves apps (concurrency) or runs them on separate cores (parallelism). For example, Chrome renders a webpage while the music player streams audio.
- **Within Each App**:
    - **Obsidian**: Threads for UI (concurrency) and file syncing (possible parallelism).
    - **Music Player**: Threads for playback (concurrency during buffering) and audio effects (parallelism).
    - **Chrome**: Each tab in a thread/process hybrid, using concurrency for page loads and parallelism for rendering.

### Advanced

On a 4-core CPU, the OS might run Chrome on two cores (parallelism), while switching Obsidian and the music player on others (concurrency). Java apps use JVM threads, treated as OS threads.

**Example**: Simulating app threads (e.g., UI and background task):

```java 
public class AppSimulation {
    public static void main(String[] args) {
        Thread uiThread = new Thread(() -> {
            while (true) {
                System.out.println("UI thread updating...");
                try {
                    Thread.sleep(500);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        });

        Thread backgroundThread = new Thread(() -> {
            while (true) {
                System.out.println("Background task processing...");
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        });

        uiThread.start();
        backgroundThread.start();
    }
}
```

**Explanation**: Simulates an app with a UI thread (responsive) and a background thread (e.g., syncing).

## 6. Daemon Threads vs. Normal Threads

### Basics

- **Normal Threads**: Keep the JVM running until they finish (e.g., main app logic).
- **Daemon Threads**: Background threads (e.g., garbage collection) that exit when normal threads finish.

### Intermediate

Set daemon status with `thread.setDaemon(true)` before starting. Normal threads are default.

### Advanced

Daemons are for support tasks (e.g., logging). Differences:

- **Lifecycle**: Daemons exit with the app; normal threads keep it alive.
- **Use Case**: Daemons for monitoring; normal for core logic.

**Example**: A daemon thread for logging:

```java
public class DaemonExample {
    public static void main(String[] args) {
        Thread daemonThread = new Thread(() -> {
            while (true) {
                System.out.println("Daemon logging system stats...");
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        });

        daemonThread.setDaemon(true);
        daemonThread.start();

        // Normal thread
        Thread normalThread = new Thread(() -> {
            try {
                Thread.sleep(3000);
                System.out.println("Normal thread done!");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        });

        normalThread.start();
    }
}
```

**Explanation**: The daemon thread stops when the normal thread finishes, as the JVM exits.

## 7. Multithreading, Multiprocessing, Multitasking, and Differences



- **Multithreading**: Multiple threads in one process, sharing memory (e.g., Java app with UI and background threads).
- **Multiprocessing**: Multiple processes with isolated memory (e.g., separate apps).
- **Multitasking**: OS-level handling of multiple tasks (apps or threads) via switching.



Multithreading is lightweight but risky (shared memory issues). Multiprocessing is safer but heavier. Multitasking is OS-driven.



|Concept|Scope|Memory|Overhead|Example in Java|
|---|---|---|---|---|
|Multithreading|Within process|Shared|Low|Thread pools|
|Multiprocessing|Separate processes|Isolated|High|`ProcessBuilder`|
|Multitasking|OS-wide|Varies|Medium|Running apps|

**Example**: Multiprocessing with `ProcessBuilder`:

```java
import java.io.IOException;

public class MultiprocessingExample {
    public static void main(String[] args) {
        try {
            ProcessBuilder pb = new ProcessBuilder("notepad.exe");
            Process process = pb.start();
            System.out.println("Started a new process: Notepad");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

**Explanation**: Launches a separate process (Notepad), isolated from the Java app.

## 8. When to Use Threads in Java: Processes/Operations and Examples



Use threads for independent tasks that shouldn’t block the main flow, like I/O or computations.



- **I/O-Bound**: Network calls, file reads—threads wait without wasting CPU.
- **CPU-Bound**: Calculations—use parallelism on multi-core.



Avoid threads for simple sequential tasks. Use for scalability in servers, GUIs, or data processing.

**Example**: Thread for file reading (I/O-bound):

```java
import java.io.BufferedReader;
import java.io.FileReader;

public class FileReadThread {
    public static void main(String[] args) {
        Runnable fileTask = () -> {
            try (BufferedReader reader = new BufferedReader(new FileReader("sample.txt"))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    System.out.println("Read: " + line);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        };

        Thread thread = new Thread(fileTask);
        thread.start();
    }
}
```

**Explanation**: Reads a file in a separate thread, keeping the main thread free.

## 9. How Spring Boot Manages Threads



Spring Boot auto-configures thread pools for tasks like web requests or async methods.



Use `@Async` for asynchronous methods, backed by `TaskExecutor` (thread pool).



Customize with `ThreadPoolTaskExecutor`. Spring’s embedded servers (Tomcat/Undertow) manage threads for web requests. Integrates with `java.util.concurrent` for reactive programming. [[8 - Tomcats role , Nginx]]

**Example**: Async method in Spring Boot:

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import java.util.concurrent.Executor;

@SpringBootApplication
@EnableAsync
public class AsyncApp {
    public static void main(String[] args) {
        SpringApplication.run(AsyncApp.class, args);
    }

    @Bean
    public Executor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(2);
        executor.setQueueCapacity(500);
        executor.setThreadNamePrefix("AsyncThread-");
        executor.initialize();
        return executor;
    }

    @Async
    public void asyncTask() {
        System.out.println("Running async task on " + Thread.currentThread().getName());
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

**Explanation**: The `@Async` method runs in a thread pool, configured via `ThreadPoolTaskExecutor`.

## 10. Common Methods, Classes, and Interfaces

### Basics to Advanced

- **Concurrency/Threads**:
    - **Classes**: `Thread`, `ExecutorService`
    - **Interfaces**: `Runnable`, `Callable`
    - **Methods**: `start()`, `run()`, `join()`, `sleep()`
- **Parallelism**:
    - **Classes**: `ForkJoinPool`, `Stream` (with `parallel()`)
    - **Interfaces**: `ForkJoinTask`
- **Synchronization**:
    - **Keywords**: `synchronized`
    - **Classes**: `ReentrantLock` (from `java.util.concurrent.locks`)
- **Daemon**:
    - **Method**: `setDaemon(true)` on `Thread`
- **Multithreading**:
    - **Classes**: `Executors`, `ThreadPoolExecutor`
- **Spring Boot**:
    - **Annotations**: `@Async`, `@EnableAsync`
    - **Interfaces**: `AsyncTaskExecutor`

**Example**: Using `ReentrantLock` for synchronization:

```java
import java.util.concurrent.locks.ReentrantLock;

public class LockExample {
    private int count = 0;
    private final ReentrantLock lock = new ReentrantLock();

    public void increment() {
        lock.lock();
        try {
            count++;
        } finally {
            lock.unlock();
        }
    }

    public int getCount() {
        return count;
    }

    public static void main(String[] args) {
        LockExample example = new LockExample();
        Runnable task = () -> {
            for (int i = 0; i < 1000; i++) {
                example.increment();
            }
        };

        Thread t1 = new Thread(task);
        Thread t2 = new Thread(task);
        t1.start();
        t2.start();

        try {
            t1.join();
            t2.join();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        System.out.println("Final count: " + example.getCount());
    }
}
```

**Explanation**: Uses `ReentrantLock` to ensure thread-safe counter increments.


#### ✅Notes : 
 *Concurrency(guitar solo): One guitarist plays very fast and alternates notes/chords so quickly it _sounds continuous_. Only one note is played at a time, but switching happens so efficiently that the listener perceives flow. This is like a single CPU core switching between tasks.
 
 *Parallelism (band): Multiple musicians (threads/cores) actually play at the _same time_—drummer, bassist, guitarist, etc.—producing real simultaneous sound. This is like multiple CPU cores running tasks in parallel. *