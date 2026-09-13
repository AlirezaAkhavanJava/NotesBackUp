**Date**: 2025-08-24  
**Concept**: Java Memory Model and Threading  
**Course**: Java Programming Fundamentals  
**Tags**: [[44 - Threads 🧀]]

---

## Terms

- **Java Memory Model (JMM)**: A set of rules defining how threads interact with memory in Java, ensuring predictable behavior for concurrent programs.
- **Heap**: Shared memory area where objects, arrays, and class metadata are stored, accessible by all threads.
- **Stack**: Private memory area per thread, used for method calls, local variables, and intermediate computations.
- **Thread Safety**: Ensuring code behaves correctly when accessed by multiple threads, avoiding data races or inconsistent states.
- **Synchronization**: Mechanisms (e.g., `synchronized` keyword, locks) to control thread access to shared resources.

---

## Notes

### How JMM Works

- **Memory Structure**:
    - **Heap**: Stores objects and is shared across all threads. Managed by the garbage collector.
    - **Stack**: Each thread has its own stack for local variables, method parameters, and call frames. Not shared.
    - **Program Counter**: Each thread has a private program counter to track the current instruction.
- **Visibility**: Changes made by one thread to shared variables (in the heap) may not be immediately visible to other threads due to caching or reordering.
- **Happens-Before**: JMM defines rules (happens-before relationships) to guarantee when changes are visible:
    - Writing a variable in a `synchronized` block happens-before reading it in another `synchronized` block.
    - Starting a thread happens-before any action in that thread.
    - A write to a `volatile` variable happens-before a subsequent read of that variable.
- **Atomicity**: Operations like reading/writing primitive variables (except `long` and `double`) are atomic, but compound actions (e.g., `i++`) are not.

### Threads in Java

- Threads share the heap but have private stacks.
- Without synchronization, threads may see stale or inconsistent data due to CPU caching or instruction reordering.
- Use `synchronized` blocks/methods or `volatile` variables to ensure thread safety and visibility.
- Java’s `java.util.concurrent` package provides higher-level tools like `ReentrantLock`, `AtomicInteger`, and `ExecutorService` for safer concurrency.

### JMM in Normal Applications

- In single-threaded apps, JMM is less noticeable since there’s no contention for shared memory.
- Local variables (on stack) are thread-safe by default.
- Objects on the heap (e.g., instance fields) need synchronization only if shared across threads.
- Garbage collection runs in the background, managing heap memory without direct developer intervention.

**Key Rules**:

- Always use `synchronized` or `volatile` for shared variables to avoid data races.
- Avoid sharing mutable objects between threads unless properly synchronized.
- Use `final` fields for immutable objects to ensure safe publication.
- Prefer high-level concurrency utilities (e.g., `ConcurrentHashMap`, `ExecutorService`) over raw `synchronized` blocks.
- Be cautious with `long` and `double` variables; they may require synchronization for atomicity on some systems.

**Things to Know**:

- **Data Races**: Occur when multiple threads access shared data without synchronization, leading to unpredictable results.
- **Volatile**: Ensures visibility of variable changes across threads but doesn’t guarantee atomicity for compound operations.
- **Locks**: `synchronized` blocks/methods use intrinsic locks; only one thread can hold a lock at a time.
- **Deadlocks**: Occur when threads wait for each other’s locks, causing a program to freeze. Avoid by consistent lock ordering.
- **Performance**: Overusing synchronization can slow down programs; use `java.util.concurrent` for better performance.
- **Best Practices**:
    - Minimize shared state between threads.
    - Use immutable objects (`final` fields) to avoid synchronization needs.
    - Test concurrent code thoroughly, as issues may not appear in single-threaded testing.

---

## Summary

The Java Memory Model (JMM) defines how threads interact with memory, ensuring predictable behavior in concurrent programs. The heap is shared, while stacks are private to threads. Synchronization (`synchronized`, `volatile`, locks) ensures visibility and thread safety. In normal applications, JMM is less critical unless threading is involved. Use high-level concurrency tools, immutable objects, and proper synchronization to write safe, efficient Java programs.

---

## Idea

Build a small Java program to demonstrate thread safety:

- Create a counter class with synchronized and unsynchronized methods.
- Run multiple threads to increment the counter and compare results.
- Use `volatile` to ensure visibility of a shared flag.
- Experiment with `AtomicInteger` for thread-safe updates without locks.

---

## Example in Code

```java
import java.util.concurrent.atomic.AtomicInteger;

class Counter {
    private int count = 0;
    private volatile boolean running = true;
    private AtomicInteger atomicCount = new AtomicInteger(0);

    // Unsynchronized: prone to data races
    public void increment() {
        count++;
    }

    // Synchronized: thread-safe
    public synchronized void incrementSafe() {
        count++;
    }

    // Atomic: thread-safe without locks
    public void incrementAtomic() {
        atomicCount.incrementAndGet();
    }

    public int getCount() {
        return count;
    }

    public int getAtomicCount() {
        return atomicCount.get();
    }

    public void stop() {
        running = false;
    }

    public boolean isRunning() {
        return running;
    }
}

public class Main {
    public static void main(String[] args) throws InterruptedException {
        Counter counter = new Counter();

        // Create two threads incrementing the counter
        Runnable task = () -> {
            for (int i = 0; i < 1000 && counter.isRunning(); i++) {
                counter.increment();        // Unsafe
                counter.incrementSafe();    // Safe
                counter.incrementAtomic();  // Safe
            }
        };

        Thread t1 = new Thread(task);
        Thread t2 = new Thread(task);
        t1.start();
        t2.start();
        t1.join();
        t2.join();

        System.out.println("Unsynchronized count: " + counter.getCount()); // Likely < 2000
        System.out.println("Synchronized count: " + counter.getCount());   // Likely 2000
        System.out.println("Atomic count: " + counter.getAtomicCount());   // Exactly 2000
    }
}
```