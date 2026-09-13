## ****Real-life Example of Java Multithreading****

> *Suppose you are using two tasks at a time on the computer, be it using Microsoft Word and listening to music. These two tasks are called ***processes*** . So you start typing in Word and at the same time start music app, this is called ***multitasking*** . Now you committed a mistake in a Word and spell check shows exception, this means Word is a process that is broken down into sub-processes. Now if a machine is dual-core then one process or task is been handled by one core and music is been handled by another core.*

In the above example, we come across both multiprocessing and multithreading. These are somehow indirectly used to achieve multitasking. In this way the mechanism of dividing the tasks is called multithreading in which every process or task is called by a thread where a thread is responsible for when to execute, when to stop and how long to be in a waiting state. Hence, a ****thread**** is the smallest unit of processing whereas ****multitasking**** is a process of executing multiple tasks at a time.

### **Multitasking is being achieved in two ways*** :

1. ****Multiprocessing**** : Process-based multitasking is a heavyweight process and occupies different address spaces in memory. Hence, while switching from one process to another, it will require some time be it very small, causing a lag because of switching. This happens as registers will be loaded in memory maps and the list will be updated.
2. ****Multithreading**** : Thread-based multitasking is a lightweight process and occupies the same address space. Hence, while switching cost of communication will be very less.



---

# Concurrency in Java

Concurrency allows multiple tasks to run simultaneously, improving performance in multi-threaded applications. This guide covers the basics of threads, virtual threads, the Java Memory Model (JMM), and the `volatile` keyword, with examples and features up to Java 25 (September 2025).

---

## Phase 1: Basics of Threads

### What are Threads?

A thread is a lightweight process that executes code independently. Java supports threads via the `java.lang.Thread` class and `Runnable` interface.

### Creating Threads

1. **Extend `Thread`**:
    
    ```java
    public class MyThread extends Thread {
        public void run() {
            System.out.println("Thread running: " + Thread.currentThread().getName());
        }
    
        public static void main(String[] args) {
            MyThread thread = new MyThread();
            thread.start(); // Start thread
        }
    }
    ```
    
2. **Implement `Runnable`**:
    
    ```java
    public class MyRunnable implements Runnable {
        public void run() {
            System.out.println("Runnable running: " + Thread.currentThread().getName());
        }
    
        public static void main(String[] args) {
            Thread thread = new Thread(new MyRunnable());
            thread.start();
        }
    }
    ```
    

**Key Methods**:

- `start()`: Begins thread execution.
- `run()`: Defines thread’s task.
- `sleep(long millis)`: Pauses thread.
- `join()`: Waits for thread to finish.
- `interrupt()`: Signals thread to stop.

**Example: Thread with Sleep**

```java
public class Main {
    public static void main(String[] args) throws InterruptedException {
        Thread t1 = new Thread(() -> {
            for (int i = 1; i <= 3; i++) {
                System.out.println("Count: " + i);
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        });
        t1.start();
        t1.join(); // Wait for t1 to finish
        System.out.println("Done!");
    }
}
```

**Output**:

```
Count: 1
Count: 2
Count: 3
Done!
```

---

## Phase 2: Virtual Threads (Java 19+, Stable in Java 21)

### What are Virtual Threads?

Virtual threads (introduced as a preview in Java 19, stable in Java 21) are lightweight threads managed by the JVM, not the OS. They simplify concurrency for high-throughput applications like web servers.

### Why Use Virtual Threads?

- **Scalability**: Thousands of virtual threads use minimal resources (unlike OS threads).
- **Simpler Code**: Write blocking code without worrying about thread pooling.

**Example: Virtual Threads**

```java
import java.util.concurrent.Executors;

public class Main {
    public static void main(String[] args) {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (int i = 0; i < 3; i++) {
                executor.submit(() -> {
                    System.out.println("Task running on: " + Thread.currentThread());
                    try {
                        Thread.sleep(1000);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                    }
                });
            }
        } // Auto-closes executor
    }
}
```

**Output** (varies by thread):

```
Task running on: VirtualThread[#1]/runnable@ForkJoinPool-1-worker-1
Task running on: VirtualThread[#2]/runnable@ForkJoinPool-1-worker-2
Task running on: VirtualThread[#3]/runnable@ForkJoinPool-1-worker-3
```

**Key Points**:

- Use `Executors.newVirtualThreadPerTaskExecutor()` for virtual threads.
- Ideal for I/O-bound tasks (e.g., network calls).
- Not for CPU-bound tasks (use thread pools instead).

---

## Phase 3: Java Memory Model (JMM)

### What is the Java Memory Model?

The JMM defines how threads interact with memory, ensuring consistent behavior across threads. It governs visibility, ordering, and atomicity of operations.

### Key Concepts

- **Visibility**: Changes by one thread may not be visible to others without synchronization.
- **Happens-Before**: Guarantees order of operations (e.g., `volatile` writes happen before reads).
- **Atomicity**: Ensures operations are indivisible (e.g., using `synchronized`).

**Example: Visibility Issue**

```java
public class Main {
    static boolean running = true;

    public static void main(String[] args) {
        Thread t1 = new Thread(() -> {
            while (running) {
                // Busy loop
            }
            System.out.println("Stopped");
        });
        t1.start();
        
        try {
            Thread.sleep(1000);
            running = false; // May not be visible to t1 without synchronization
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

**Fix with Synchronization**:

```java
public class Main {
    static boolean running = true;

    public static void main(String[] args) {
        Thread t1 = new Thread(() -> {
            while (true) {
                synchronized (Main.class) {
                    if (!running) break;
                }
            }
            System.out.println("Stopped");
        });
        t1.start();
        
        try {
            Thread.sleep(1000);
            synchronized (Main.class) {
                running = false;
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

---

## Phase 4: Volatile Keyword

### What is Volatile?

The `volatile` keyword ensures a variable’s value is always read from and written to main memory, guaranteeing visibility across threads. It also establishes a happens-before relationship.

### When to Use Volatile?

- For simple flags or counters shared across threads.
- When atomicity of operations isn’t required (use `synchronized` or `Atomic` classes for that).

**Example: Volatile Flag**

```java
public class Main {
    static volatile boolean running = true;

    public static void main(String[] args) {
        Thread t1 = new Thread(() -> {
            while (running) {
                // Visible to all threads
            }
            System.out.println("Stopped");
        });
        t1.start();
        
        try {
            Thread.sleep(1000);
            running = false; // Guaranteed to be visible
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

**Key Points**:

- `volatile` doesn’t make operations atomic (e.g., `i++` isn’t safe).
- Use `java.util.concurrent.atomic.AtomicInteger` for atomic updates.

**Example: AtomicInteger**

```java
import java.util.concurrent.atomic.AtomicInteger;

public class Main {
    static AtomicInteger counter = new AtomicInteger(0);

    public static void main(String[] args) {
        Runnable task = () -> {
            for (int i = 0; i < 1000; i++) {
                counter.incrementAndGet(); // Thread-safe
            }
        };
        Thread t1 = new Thread(task);
        Thread t2 = new Thread(task);
        t1.start();
        t2.start();
        try {
            t1.join();
            t2.join();
            System.out.println(counter.get()); // 2000
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

---

## Phase 5: Advanced Concurrency

### Key Concurrency Utilities

- **ExecutorService**: Manages thread pools.
- **Future/CompletableFuture**: Handles async results.
- **Lock/ReentrantLock**: Fine-grained thread synchronization.
- **ReadWriteLock**: Separates read/write access for efficiency.

**Example: ExecutorService with Thread Pool**

```java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Main {
    public static void main(String[] args) {
        ExecutorService executor = Executors.newFixedThreadPool(2);
        for (int i = 0; i < 3; i++) {
            executor.submit(() -> {
                System.out.println("Task on: " + Thread.currentThread().getName());
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
        }
        executor.shutdown();
    }
}
```

**Example: CompletableFuture**

```java
import java.util.concurrent.CompletableFuture;

public class Main {
    public static void main(String[] args) {
        CompletableFuture.supplyAsync(() -> "Hello")
                         .thenApply(s -> s + " World")
                         .thenAccept(System.out::println) // Hello World
                         .join();
    }
}
```

**Practice: Producer-Consumer with BlockingQueue**

```java
import java.util.concurrent.LinkedBlockingQueue;

public class Main {
    public static void main(String[] args) {
        LinkedBlockingQueue<Integer> queue = new LinkedBlockingQueue<>(5);
        Thread producer = new Thread(() -> {
            try {
                for (int i = 1; i <= 3; i++) {
                    queue.put(i);
                    System.out.println("Produced: " + i);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });
        Thread consumer = new Thread(() -> {
            try {
                for (int i = 0; i < 3; i++) {
                    System.out.println("Consumed: " + queue.take());
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });
        producer.start();
        consumer.start();
    }
}
```

---

## Java Features Up to Java 25 for Concurrency

- **Java 8 (2014)**:
    - **CompletableFuture**: Chaining async tasks.
    - **Lambda Expressions**: Simplify `Runnable`/`Callable`: `() -> System.out.println("Task")`.
- **Java 9 (2017)**:
    
    - **Flow API**: Reactive streams for concurrency.
    
    ```java
    import java.util.concurrent.Flow;
    
    public class Main implements Flow.Subscriber<Integer> {
        @Override
        public void onSubscribe(Flow.Subscription subscription) { subscription.request(1); }
        @Override
        public void onNext(Integer item) { System.out.println(item); }
        @Override
        public void onError(Throwable throwable) {}
        @Override
        public void onComplete() {}
    }
    ```
    
- **Java 10 (2018)**: `var` for cleaner code: `var executor = Executors.newFixedThreadPool(2);`.
- **Java 14 (2020)**: Records for immutable data in concurrent tasks.
    
    ```java
    record TaskResult(int id, String result) {}
    ```
    
- **Java 17 (2021)**: Pattern matching for `instanceof`.
    
    ```java
    if (future instanceof CompletableFuture<String> cf) {
        System.out.println(cf.join());
    }
    ```
    
- **Java 21 (2023)**: **Virtual Threads**: Scalable concurrency for I/O-bound tasks (shown above).
- **Java 25 (2025)**:
    - **Implicit Classes**: Simplify utility classes for concurrency.
        
        ```java
        implicit class ThreadUtils {
            static void runAsync(Runnable task) {
                Executors.newVirtualThreadPerTaskExecutor().submit(task);
            }
        }
        ```
        
    - **Flexible Constructor Bodies**: Add logic to thread-safe classes.
        
        ```java
        class SafeCounter {
            private int count;
            SafeCounter() {
                this.count = 0;
                if (!Thread.currentThread().isVirtual()) throw new IllegalStateException("Must use virtual thread");
            }
        }
        ```
        

---

## Best Practices

1. **Use Virtual Threads for I/O**: Ideal for network or file operations.
2. **Avoid `volatile` for Complex Operations**: Use `Atomic` classes or `synchronized`.
3. **Leverage ExecutorService**: For thread pool management.
4. **Handle Interruptions**: Always restore interrupted state.
5. **Test Concurrency**: Use **JUnit** with **ConcurrentUnit** for testing.
    
    ```xml
    <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter</artifactId>
        <version>5.11.0</version>
        <scope>test</scope>
    </dependency>
    ```
    

---

## Real-World Applications

- **Web Servers**: Use virtual threads for handling thousands of requests.
- **Data Processing**: Parallelize collection operations with `CompletableFuture`.
- **Task Queues**: Implement producer-consumer with `LinkedBlockingQueue`.
- **Thread-Safe Counters**: Use `AtomicInteger` for shared state.

---

## Conclusion

Java concurrency enables efficient multi-threaded applications. Start with basic threads, use virtual threads for scalability, understand the JMM for memory consistency, and apply `volatile` or atomic classes for thread safety. Java 25 features like virtual threads and implicit classes simplify high-performance concurrent programming.



[[Java]]