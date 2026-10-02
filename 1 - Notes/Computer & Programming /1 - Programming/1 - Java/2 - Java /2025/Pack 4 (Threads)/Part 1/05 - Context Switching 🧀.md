
## 1. Context Switching

### What is it?

Context switching is when a computer switches from running one task (or thread) to another. Imagine a chef pausing chopping vegetables to stir a pot of soup. The chef saves where they left off (e.g., puts down the knife) and picks up the new task (e.g., grabs the spoon). In a computer, this happens when the operating system (OS) pauses one thread to run another on the same CPU core.


> *During a **context switch**, the CPU has to save the current thread’s state so it can resume later. That **state is stored in the CPU registers** (general-purpose registers, program counter, stack pointer, flags, etc.) and usually also involves the **stack in memory**.*
### How it Works

- Each thread has a "context" (its current state, like variables and progress).
- The OS saves the current thread’s context (e.g., register values) and loads the next thread’s context.
- This lets multiple threads share a single CPU core, making it seem like they’re running at the same time (concurrency).

### Why it Matters

Context switching enables multitasking but adds a small delay (overhead) because saving and loading contexts takes time.

### Example

Imagine a Java program with two threads printing messages:

``` java
public class ContextSwitchExample {
    public static void main(String[] args) {
        Thread thread1 = new Thread(() -> {
            for (int i = 0; i < 5; i++) {
                System.out.println("Thread 1: " + i);
                try {
                    Thread.sleep(100); // Simulates work
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        });

        Thread thread2 = new Thread(() -> {
            for (int i = 0; i < 5; i++) {
                System.out.println("Thread 2: " + i);
                try {
                    Thread.sleep(100); // Simulates work
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        });

        thread1.start();
        thread2.start();
    }
}
```

**Explanation**: The OS switches between `thread1` and `thread2` on the same CPU core. The output alternates (e.g., "Thread 1: 0", "Thread 2: 0", etc.) because of context switching.

## 2. Inter-Core Communication

### What is it?

Inter-core communication is how different CPU cores share information when running threads in parallel. Picture two chefs in a kitchen passing ingredients to each other to make a dish faster. In a multi-core CPU, threads running on different cores need to share data or coordinate.

### How it Works

- Each core runs a thread independently (parallelism).
- Threads share data through shared memory (e.g., variables) or message passing.
- The CPU’s cache and memory system ensure data consistency, but this can slow things down (communication overhead).



### Why it Matters

Inter-core communication is key for parallelism but can be tricky. If two cores access the same data without coordination, it causes errors (e.g., race conditions). Tools like locks or atomic variables help.

### Example

A Java program with two threads on different cores incrementing a shared counter, using synchronization:

``` java
import java.util.concurrent.locks.ReentrantLock;

public class InterCoreCommunicationExample {
    private int counter = 0;
    private final ReentrantLock lock = new ReentrantLock();

    public void increment() {
        lock.lock();
        try {
            counter++;
            System.out.println(Thread.currentThread().getName() + ": " + counter);
        } finally {
            lock.unlock();
        }
    }

    public static void main(String[] args) {
        InterCoreCommunicationExample example = new InterCoreCommunicationExample();

        Thread thread1 = new Thread(() -> {
            for (int i = 0; i < 5; i++) {
                example.increment();
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }, "Core1-Thread");

        Thread thread2 = new Thread(() -> {
            for (int i = 0; i < 5; i++) {
                example.increment();
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }, "Core2-Thread");

        thread1.start();
        thread2.start();
    }
}
```

**Explanation**: On a multi-core CPU, `thread1` and `thread2` may run on separate cores. The `ReentrantLock` ensures safe communication, preventing data corruption when both cores update `counter`.

## Key Differences

| Aspect       | Context Switching            | Inter-Core Communication     |
| ------------ | ---------------------------- | ---------------------------- |
| **Purpose**  | Switch tasks on one core     | Share data between cores     |
| **Scope**    | Single core (concurrency)    | Multiple cores (parallelism) |
| **Overhead** | Saving/loading thread state  | Cache synchronization, locks |
| **Example**  | Alternating threads printing | Threads sharing a counter    |

---
### **How cores talk inside a CPU**

1. **Caches hierarchy:**
    
    - **L1 cache:** private per core, very small, extremely fast.
        
    - **L2 cache:** usually private per core, bigger but slower than L1.
        
    - **L3 cache:** shared among cores (sometimes called the “last-level cache”).
        
2. **Inter-core communication:**
    
    - Cores often need to **share data** (e.g., threads working on the same variables).
        
    - This happens **via the shared caches**, mainly **L3**.
        
    - When a core updates data, the CPU ensures **cache coherence** so other cores see the latest value.
        
3. **Cache coherence protocols:**
    
    - Modern CPUs use protocols like **MESI / MOESI** to keep caches in sync.
        
    - If Core A writes a value in its L1, Core B’s L1 copy is invalidated or updated through the shared cache.
        

---

✅ **Summary:**

- Inter-core communication is mostly **through cache** rather than main memory.
    
- Shared caches and coherence protocols **ensure all cores have a consistent view of memory**.
    
- Accessing shared cache is **much faster than going to RAM**, which is why cache design is critical for multi-core CPUs.
---
> ***On core can only run one thread no matter a 4 core cpu or 32 core cpu both run thread = amount of cores in the same time but they have a queue that each has their own context switching making each core to work with many threads concurrently and in the bigger view all cores are running a threads state at a time this means each core is running multiple threads in concurrent way and when we look at a larger scale all cores are working with many threads and it means a 32 core cpu (or a 4 core) can work with threads more than their core numbers and can run thousands of threads***


1. **Per core execution:**
    
    - Each **core runs only one thread at a time** (ignoring hyperthreading for now).
        
    - So a **4-core CPU** can run **4 threads simultaneously**, a **32-core CPU** can run **32 threads simultaneously**.
        
2. **Context switching per core:**
    
    - If there are more threads than cores, the OS **switches threads on each core** rapidly.
        
    - Each core maintains a **queue of runnable threads** and switches between them, saving/restoring context.
        
    - This is **concurrency**: each core is juggling multiple threads, making progress on all of them over time.
        
3. **Global view:**
    
    - All cores together run **multiple threads in parallel** (up to the number of cores simultaneously).
        
    - Because of context switching, **the CPU can manage thousands of threads** even if only a few run at the same exact moment.
        
    - Each thread gets some time slice, so the OS can make it **appear that many threads are running at once**.
        

✅ Key points:

- **Parallelism** = threads actually executing at the same time on multiple cores.
    
- **Concurrency** = threads making progress over time, via context switching.
    
- A 32-core CPU can handle thousands of threads because **most are waiting or swapped out**, not because all run at once.
---
## Hyperthreading

1. **One physical core ≈ two logical cores:**
    
    - The CPU core has **duplicate sets of some registers**, allowing it to **maintain state for two threads** at the same time.
        
    - Only **one set of execution units** (ALU, FPU) exists per core.
        
2. **How it works:**
    
    - If one thread stalls (e.g., waiting for memory), the core can execute the **other thread** using the same execution units.
        
    - It improves **utilization** of CPU resources but doesn’t double performance.
        
3. **Impact on concurrency and parallelism:**
    
    - A 4-core CPU with hyperthreading → 8 **logical threads** can be scheduled simultaneously.
        
    - Physical cores still limit true parallel execution, but hyperthreading allows the OS to **keep the execution units busier**, reducing idle time.
        

✅ Summary:

- **Parallelism** = still limited by **physical cores**.
    
- **Concurrency** = increased by hyperthreading, since more logical threads can be managed per core.
    
- Hyperthreading helps **I/O-bound or lightly CPU-bound tasks**, less effective for **fully CPU-bound tasks** because execution units are shared.

> ✅ Important: logical cores share **execution units**, so two threads on the same physical core aren’t fully parallel — performance gain is usually **20–30%** for CPU-bound tasks, more for I/O-bound or mixed workloads.

[[44 - Threads 🧀]]