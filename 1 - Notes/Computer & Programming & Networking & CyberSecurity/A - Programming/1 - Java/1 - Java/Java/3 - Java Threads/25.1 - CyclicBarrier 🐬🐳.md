Date : 2025-09-07



# CyclicBarrier (Java)

**What it is**

`CyclicBarrier` is a synchronization aid in `java.util.concurrent` that allows a set of threads (a _party_ count) to wait for each other at a common barrier point. Once the specified number of threads have called `await()`, the barrier is tripped and all waiting threads are released. The barrier can be reused (hence _cyclic_).

**When to use**

- When you have a fixed number of threads that must wait for each other at repeated synchronization points (phases).
    
- Example: parallel stages of a simulation where each step must finish for all workers before the next step starts.
    

---

## Key constructors

```java
CyclicBarrier(int parties)
CyclicBarrier(int parties, Runnable barrierAction)
```

- `parties` — number of threads that must call `await()` to trip the barrier.
    
- `barrierAction` — optional `Runnable` executed once by the last thread that arrives (before the others are released).
    

---

## Important methods

- `int await()` — waits until all parties arrive, then returns an arrival index (0..parties-1) for the calling thread. Can throw `InterruptedException` or `BrokenBarrierException`.
    
- `int await(long timeout, TimeUnit unit)` — same but with timeout; throws `TimeoutException` on timeout.
    
- `void reset()` — resets the barrier to its initial state, breaking any current waiting threads.
    
- `int getParties()` — returns the number of parties required.
    
- `int getNumberWaiting()` — how many threads are currently waiting at the barrier.
    
- `boolean isBroken()` — whether the barrier is in broken state.
    

---

## Exceptions and states

- `BrokenBarrierException` — thrown when the barrier is broken (e.g., because one waiting thread was interrupted or timed out).
    
- If a thread is interrupted while waiting, other waiting threads receive `BrokenBarrierException` and `isBroken()` becomes `true`.
    
- After a barrier is broken, you can call `reset()` to reuse it.
    

---

## Example

```java
import java.util.concurrent.*;

public class CyclicBarrierExample {
    public static void main(String[] args) {
        final int WORKERS = 3;
        CyclicBarrier barrier = new CyclicBarrier(WORKERS, () ->
            System.out.println("All parties arrived — barrier action running by " + Thread.currentThread().getName())
        );

        ExecutorService ex = Executors.newFixedThreadPool(WORKERS);
        for (int i = 0; i < WORKERS; i++) {
            final int id = i;
            ex.submit(() -> {
                try {
                    System.out.println("Worker " + id + " is doing phase 1");
                    Thread.sleep(500 + id * 200);
                    int index = barrier.await(); // wait for others
                    System.out.println("Worker " + id + " passed barrier with index " + index);

                    // Next phase reuse
                    System.out.println("Worker " + id + " is doing phase 2");
                    Thread.sleep(300);
                    barrier.await();
                    System.out.println("Worker " + id + " finished");
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                } catch (BrokenBarrierException e) {
                    System.err.println("Barrier broken for worker " + id);
                }
            });
        }
        ex.shutdown();
    }
}
```

---

## Pitfalls & tips

- `CyclicBarrier` is reusable; `CountDownLatch` is one-shot. Choose based on reuse requirement.
    
- The `barrierAction` runs in **the last thread to arrive**. Keep it short and non-blocking.
    
- Be careful with timeouts and interruptions — they break the barrier and wake other threads with `BrokenBarrierException`.
    
- Always handle `BrokenBarrierException` and `InterruptedException` to avoid silent thread death.
    
- Monitoring helpers: `getNumberWaiting()` and `isBroken()` help debugging.
    

---

## Quick comparison

|Feature|`CyclicBarrier`|`CountDownLatch`|
|---|--:|--:|
|Reusable|✅|❌|
|Wait by N threads|✅|✅ (but one-shot)|
|Barrier action|✅|❌|

---

## One-line summary

`CyclicBarrier` lets a fixed number of threads wait for each other at a barrier and can be reused across multiple phases; handle interrupts/timeouts carefully because they break the barrier.


##### *Tags : [[44 - Threads 🧀]]