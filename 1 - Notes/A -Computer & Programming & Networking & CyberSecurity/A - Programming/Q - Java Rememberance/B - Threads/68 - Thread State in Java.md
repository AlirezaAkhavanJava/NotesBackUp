

## Definition

**Thread state** represents where a thread currently is in its lifecycle — from creation to termination. Java exposes this directly through the `Thread.State` enum, which `Thread.getState()` returns. There are exactly **six** possible states, and every thread is always in exactly one of them at any given moment.

```java
public enum Thread.State {
    NEW,
    RUNNABLE,
    BLOCKED,
    WAITING,
    TIMED_WAITING,
    TERMINATED
}
```

```java
Thread t = new Thread(() -> {});
System.out.println(t.getState()); // returns one of the six values above
```

This formalizes something you've already seen used throughout the last several tutorials — now let's define each state precisely, with what causes a thread to enter and leave it.

---

## The six states, one at a time

### 1. `NEW`

**The thread object has been created, but `start()` has not yet been called.**

```java
Thread t = new Thread(() -> System.out.println("Hello"));
System.out.println(t.getState()); // NEW
```

At this point, no OS-level thread exists yet — `t` is just a plain Java object sitting in memory, not yet handed off to the scheduler at all.

---

### 2. `RUNNABLE`

**The thread is eligible to run — it's either currently executing on a core, or waiting in line for the scheduler to give it a turn.**

```java
Thread t = new Thread(() -> {
    for (int i = 0; i < 1_000_000; i++) { /* busy work */ }
});
t.start();
System.out.println(t.getState()); // RUNNABLE (likely, if still working)
```

**Important subtlety:** `RUNNABLE` covers _both_ "actually executing right now" and "ready and waiting for the scheduler to pick it." Java doesn't distinguish between these two — this maps directly to the CPU scheduler tutorial: a `RUNNABLE` thread is competing for core time via time-sharing, whether or not it's getting a slice at this exact instant.

---

### 3. `BLOCKED`

**The thread is trying to enter a `synchronized` block/method, but another thread currently holds that lock.**

```java
class Resource {
    synchronized void access() {
        try { Thread.sleep(5000); } catch (InterruptedException e) {}
    }
}

Resource resource = new Resource();

Thread t1 = new Thread(resource::access); // grabs the lock first
Thread t2 = new Thread(resource::access); // will be BLOCKED waiting for the lock

t1.start();
Thread.sleep(100); // give t1 time to grab the lock first
t2.start();

System.out.println(t2.getState()); // BLOCKED — waiting to enter the synchronized method
```

**`BLOCKED` is specifically about lock contention** — it's the state that directly corresponds to the "waiting to acquire a lock another thread holds" scenario from the synchronization/deadlock discussions earlier.

---

### 4. `WAITING`

**The thread is waiting indefinitely for another thread to explicitly wake it up** — no timeout, it stays here until something else acts.

Caused by:

- `Object.wait()` (no timeout argument)
- `Thread.join()` (no timeout argument)
- `LockSupport.park()`

```java
Object lock = new Object();

Thread t = new Thread(() -> {
    synchronized (lock) {
        try {
            lock.wait(); // waits here FOREVER until notify()/notifyAll() is called
        } catch (InterruptedException e) {}
    }
});
t.start();
Thread.sleep(100);
System.out.println(t.getState()); // WAITING
```

```java
Thread worker = new Thread(() -> {
    try { Thread.sleep(3000); } catch (InterruptedException e) {}
});
worker.start();

Thread waiter = new Thread(() -> {
    try {
        worker.join(); // WAITING for worker to finish — no timeout given
    } catch (InterruptedException e) {}
});
waiter.start();
Thread.sleep(100);
System.out.println(waiter.getState()); // WAITING
```

**Key distinguishing factor from `BLOCKED`:** `BLOCKED` is specifically about waiting for a **lock**; `WAITING` is about waiting for **another thread's explicit action** (a `notify()` call, or another thread finishing via `join()`) — different cause, different state.

---

### 5. `TIMED_WAITING`

**Same as `WAITING`, but with a timeout — the thread will wake up on its own after a specified duration, even if nothing else happens.**

Caused by:

- `Thread.sleep(millis)`
- `Object.wait(millis)`
- `Thread.join(millis)`
- `LockSupport.parkNanos()` / `parkUntil()`

```java
Thread t = new Thread(() -> {
    try { Thread.sleep(5000); } catch (InterruptedException e) {}
});
t.start();
Thread.sleep(100);
System.out.println(t.getState()); // TIMED_WAITING
```

This is exactly the state `Thread.sleep()` puts a thread into, as covered in the last tutorial — directly connecting the "sleep removes a thread from CPU competition" concept to its formal state name.

---

### 6. `TERMINATED`

**The thread has finished executing `run()` — either it completed normally, or it exited due to an uncaught exception.** This is a final state — a `Thread` object cannot be restarted once terminated.

```java
Thread t = new Thread(() -> System.out.println("Quick task"));
t.start();
t.join(); // wait for it to actually finish
System.out.println(t.getState()); // TERMINATED
```

```java
t.start(); // throws IllegalThreadStateException — can't restart a TERMINATED thread
```

---

## The full state transition diagram

```
        new Thread(...)
              │
              ▼
            NEW
              │  start()
              ▼
         ┌─────────┐
    ┌───▶│ RUNNABLE │◀───┐
    │    └─────────┘     │
    │       │   │         │
    │  lock  │   │ sleep()/wait(timeout)/join(timeout)
    │  needed│   │         │
    │       ▼   ▼         │
    │  ┌───────┐ ┌───────────────┐
    │  │BLOCKED│ │ TIMED_WAITING  │
    │  └───────┘ └───────────────┘
    │       │   │         │
    │  lock  │   │ timeout expires /
    │  acquired│  │ notified / interrupted
    └───────┴───┴─────────┘
              │
     wait()/join() (no timeout)
              ▼
         ┌─────────┐
         │ WAITING  │
         └─────────┘
              │ notify()/notifyAll()/
              │ target thread finishes
              ▼
         (back to RUNNABLE)

    RUNNABLE, when run() completes:
              │
              ▼
         TERMINATED
```

---

## A worked example demonstrating several transitions

```java
public class ThreadStateDemo {
    public static void main(String[] args) throws InterruptedException {
        Object lock = new Object();

        Thread demo = new Thread(() -> {
            synchronized (lock) {
                try {
                    Thread.sleep(2000); // → TIMED_WAITING
                } catch (InterruptedException e) {}
            }
        });

        System.out.println("1. " + demo.getState()); // NEW

        demo.start();
        System.out.println("2. " + demo.getState()); // RUNNABLE

        Thread.sleep(500); // let demo reach its sleep() call
        System.out.println("3. " + demo.getState()); // TIMED_WAITING

        demo.join(); // wait for it to fully finish
        System.out.println("4. " + demo.getState()); // TERMINATED
    }
}
```

---

## Summary table

|State|Meaning|Caused by|
|---|---|---|
|`NEW`|created, not yet started|`new Thread(...)`, before `start()`|
|`RUNNABLE`|eligible to run — executing or waiting for a CPU turn|`start()` called|
|`BLOCKED`|waiting to acquire a lock held by another thread|trying to enter a `synchronized` block another thread holds|
|`WAITING`|waiting indefinitely for another thread's action|`wait()`, `join()`, `LockSupport.park()` — no timeout|
|`TIMED_WAITING`|waiting, but with a timeout that will end it|`sleep()`, `wait(ms)`, `join(ms)`|
|`TERMINATED`|finished executing — final state, cannot restart|`run()` completes (normally or via exception)|

## Where this connects to everything else

This is the formal, six-state version of the informal `RUNNABLE`/`BLOCKED`/`WAITING` picture sketched in the CPU scheduler tutorial — `BLOCKED` and `WAITING`/`TIMED_WAITING` are both "not competing for CPU time" states, just triggered by different causes (lock contention vs. explicit coordination vs. timed pause). Understanding exactly which state a thread is in is genuinely useful for debugging real concurrency issues — a thread stuck in `BLOCKED` points you toward lock contention/possible deadlock, while one stuck in `WAITING` points you toward a missing `notify()` call somewhere in your coordination logic.


[[Java]]