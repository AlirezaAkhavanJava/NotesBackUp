
> A **semaphore is a tool that controls how many threads (tasks) can use a resource at the same time**.  
  Think of it as a **counter with permits**.  
  If there’s a permit → you can use the resource.  
  If no permit → you must wait until someone releases a permit.

A **Semaphore** is like a traffic signal  for threads.  
It controls **how many threads** can access a resource at the same time.

- **Semaphore(n)** → allows at most `n` threads to enter.
    
- If all permits are taken → new threads **wait** until a permit is released.

## **Real-world Examples**

### Example 1 — Parking Lot 🅿️

Imagine a parking lot with **5 parking spots**.

- There are 10 cars trying to park.
    
- Only 5 cars can park at the same time.
    
- Others must wait until a spot is free.
    

In Java:

```java
import java.util.concurrent.Semaphore;

public class ParkingLot {
    public static void main(String[] args) {
        Semaphore parkingSpots = new Semaphore(5); // 5 spots

        Runnable car = () -> {
            try {
                System.out.println(Thread.currentThread().getName() + " wants a spot");
                parkingSpots.acquire(); // take a spot
                System.out.println(Thread.currentThread().getName() + " parked");
                Thread.sleep(2000); // parked for 2 seconds
            } catch (InterruptedException e) {
                e.printStackTrace();
            } finally {
                parkingSpots.release(); // leave spot
                System.out.println(Thread.currentThread().getName() + " left");
            }
        };

        for (int i = 1; i <= 10; i++) {
            new Thread(car, "Car-" + i).start();
        } // 10 threads(cars)
    }
}

```

**What happens:**

- Only 5 cars park at a time.
    
- Others wait until a spot is free.


---

Semaphores are used when you need to **limit concurrency** or **coordinate threads**.

### 1. **Limit Database Connections**

If you only want 3 threads accessing the DB:

```java
Semaphore dbSemaphore = new Semaphore(3);
```

### 2. **Mutual Exclusion (like a Lock)**

If you use `new Semaphore(1)`, it acts like a **binary lock** — only one thread at a time.

```java
Semaphore mutex = new Semaphore(1);

mutex.acquire();
// critical section
mutex.release();

```

### 3. **Producer-Consumer (Bounded Buffer)**

Semaphore can manage empty vs. full slots.

- `Semaphore empty = new Semaphore(N);` → N slots initially empty.
    
- `Semaphore full = new Semaphore(0);` → no items initially.
    

Producers acquire `empty`, then release `full`.  
Consumers acquire `full`, then release `empty`.

---

### 1. **Fair vs. Unfair Semaphores**

- By default → unfair (threads might cut in line).
    
- `new Semaphore(permits, true);` → fair (first come, first served).
    

```java 
Semaphore fairSemaphore = new Semaphore(2, true);
```

### 2. **Try Acquire with Timeout**

Instead of waiting forever, a thread can wait for a limited time:

```java 
if (semaphore.tryAcquire(500, TimeUnit.MILLISECONDS)) {
    try {
        // got permit
    } finally {
        semaphore.release();
    }
} else {
    System.out.println("Couldn’t acquire permit in time.");
}

```

### 3. **Controlling Thread Pools**

Instead of using `ExecutorService` fixed thread pools, you can control concurrency manually with Semaphore.

```java 
Semaphore limiter = new Semaphore(10); // max 10 concurrent tasks

Runnable limitedTask = () -> {
    try {
        limiter.acquire();
        System.out.println(Thread.currentThread().getName() + " running");
        Thread.sleep(2000);
    } catch (InterruptedException e) {
        e.printStackTrace();
    } finally {
        limiter.release();
    }
};

```

### 4. **Deadlock Risks**

If you `acquire()` and forget to `release()`, your program can **hang forever**.  
Always use `try-finally` to release.

---

## 🧠 Summary

- **Beginner:** Semaphore = traffic controller, limits concurrent access.
    
- **Intermediate:** Used for DB connections, mutual exclusion, producer-consumer problems.
    
- **Advanced:** Fairness, timeouts, custom thread limiting, avoiding deadlocks.
#### Tags : [[44 - Threads 🧀]]