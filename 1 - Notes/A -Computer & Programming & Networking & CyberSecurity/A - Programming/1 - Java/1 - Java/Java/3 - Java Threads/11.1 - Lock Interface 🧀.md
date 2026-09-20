Date : 2025-09-11

### **1. What is `Lock`?**

- It’s part of `java.util.concurrent.locks`.
    
- Provides **more flexible locking** than `synchronized`.
    
- Can be **blocking, non-blocking, or timed**.
    
- Supports **reentrancy** via `ReentrantLock`.

> In Java (or any language with concurrency control), you only need to lock a resource if multiple threads **might access it at the same time** and at least one of them can **modify it**. If a resource is only used by one thread, locking is unnecessary—it just adds overhead.

>If all threads are **only reading** and the resource is never modified, **you don’t need a lock**. Reading simultaneously doesn’t cause conflicts.
>💡 **Rule of thumb:** Locks = only for shared, mutable state. Immutable or read-only = safe without locking.

---

### **2. Core Methods of `Lock`**

|Method|What it does|
|---|---|
|`lock()`|Acquires the lock, **blocks** if unavailable.|
|`unlock()`|Releases the lock. Must call after `lock()`.|
|`tryLock()`|Attempts to acquire the lock **without blocking**. Returns `true` if successful.|
|`tryLock(long time, TimeUnit unit)`|Tries to acquire the lock, waits up to the given time.|
|`lockInterruptibly()`|Acquires the lock unless **interrupted**.|

---

### **3. Example: ReentrantLock**

```java
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class LockExample {
    private final Lock lock = new ReentrantLock();
    private int counter = 0;

    public void increment() {
        lock.lock(); // blocking lock
        try {
            counter++;
            System.out.println(Thread.currentThread().getName() + " incremented to " + counter);
        } finally {
            lock.unlock();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        LockExample example = new LockExample();

        Thread t1 = new Thread(() -> { 
	        for (int i=0; i<100; i++) 
	        example.increment(); 
	    }, "T1");
        Thread t2 = new Thread(() -> {
	        for (int i=0; i<100; i++)
	         example.increment(); 
	    }, "T2");

        t1.start();
        t2.start();
        t1.join();
        t2.join();
    }
}
```

✅ Why this is better than `synchronized`:

- Can try **non-blocking acquisition** with `tryLock()`.
    
- Can acquire **interruptibly**.
    
- Can create **fair locks** (`new ReentrantLock(true)` ensures first-come-first-serve).
    

---

🐐 **Takeaway:**

- `Lock` = flexible, powerful alternative to `synchronized`.
    
- Supports **blocking**, **non-blocking**, **timed**, and **interruptible** locking.
    
- Most commonly used via **`ReentrantLock`**.
    


---

### **1. Interface Level**

```java
java.lang.Object
   └── java.util.concurrent.locks.Lock  (interface)
```

- **Lock**: The main interface. Core methods: `lock()`, `unlock()`, `tryLock()`, `lockInterruptibly()`.
    

---

### **2. Implementations**

```java
Lock (interface)
│
├── ReentrantLock
│    ├─ Implements Lock
│    ├─ Reentrant (thread can reacquire the same lock)
│    ├─ Optional fairness (first-come-first-serve)
│
├── ReentrantReadWriteLock
│    ├─ Has inner classes:
│    │     ├─ ReentrantReadWriteLock.ReadLock
│    │     └─ ReentrantReadWriteLock.WriteLock
│    ├─ ReadLock allows multiple readers
│    └─ WriteLock allows single writer
│
├── StampedLock (Java 8+)
│    ├─ Optimistic reads
│    ├─ Read lock
│    └─ Write lock
│
└── AbstractOwnableSynchronizer (AOS) – internal helper for custom locks
```

---

### **3. Notes**

- `synchronized` (intrinsic lock) is **not part of Lock hierarchy** — it’s built into the JVM.
    
- `ReentrantLock` = most commonly used **explicit lock**.
    
- `ReentrantReadWriteLock` = useful when reads are frequent and writes are rare.
    
- `StampedLock` = high-performance lock with **optimistic reads**.
    

---

🐐 **Visual cheat:**

```java
Lock (interface)
├── ReentrantLock
├── ReentrantReadWriteLock
│    ├── ReadLock
│    └── WriteLock
└── StampedLock
```


##### Resource : [video](https://www.youtube.com/watch?v=MWlqrLiscjQ)



##### *Tags : [[44 - Threads 🧀]]