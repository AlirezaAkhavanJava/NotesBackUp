### **1. Blocking Lock**

- A **blocking lock** makes a thread **wait (block)** until the lock becomes available.
    
- The thread cannot do anything else while waiting.
    
- Examples in Java:
    
    - `synchronized` keyword → thread **waits** until it can enter the synchronized block.
        
    - `ReentrantLock.lock()` → blocks the thread if another thread holds the lock.
        

```java 

lock.lock();   // blocking call
try {
    // critical section
} finally {
    lock.unlock();
}


```

✅ Guarantees mutual exclusion, but the thread may be **stuck waiting** if another thread is slow.

---

### **2. Non-blocking Lock**

- A **non-blocking lock** lets the thread **try to acquire the lock**, but if it’s unavailable, the thread can **do something else instead of waiting**.
    
- Examples in Java:
    
    - `ReentrantLock.tryLock()` → returns `true` if it got the lock, `false` if someone else holds it.
        

```java

if (lock.tryLock()) {
    try {
        // critical section
    } finally {
        lock.unlock();
    }
} else {
    // do something else, don't block
}


```

✅ Useful in high-performance or real-time systems where **waiting is costly**.

---

🐐 **Summary:**

- **Blocking lock:** thread waits → guaranteed to enter critical section eventually.
    
- **Non-blocking lock:** thread doesn’t wait → can skip work or retry later.
    

##### Tags : [[44 - Threads 🧀]]