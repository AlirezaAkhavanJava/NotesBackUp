


Every thread, at any instant, is in exactly one of six well-defined states. Java doesn't leave this as an implementation detail — it's enforced by the `Thread.State` enum, and you can ask any thread which state it's currently in by calling `Thread.getState()`. This matters in practice because when you're debugging a stuck or misbehaving multi-threaded program, knowing _which_ state a thread is parked in tells you exactly what kind of problem you're looking at — a lock issue, a missing wakeup call, or something else entirely.

```java
public enum Thread.State {
    NEW, RUNNABLE, BLOCKED, WAITING, TIMED_WAITING, TERMINATED
}
```

Let's go through each one, what puts a thread there, and what gets it out.

### NEW

A thread is `NEW` the moment you construct it, right up until `start()` is called. At this point it's just a plain Java object — no OS thread has been created for it yet.

```java
Thread t = new Thread(() -> System.out.println("Hello"));
System.out.println(t.getState()); // NEW
```

### RUNNABLE

Once `start()` runs, the thread becomes `RUNNABLE`. This is the one state that's a bit broader than its name suggests: it covers both "actively executing on a core right now" and "ready to run, just waiting for the OS scheduler to give it a turn." Java doesn't split these into two separate states — both count as `RUNNABLE`.

```java
Thread t = new Thread(() -> {
    for (int i = 0; i < 1_000_000; i++) { }
});
t.start();
System.out.println(t.getState()); // RUNNABLE
```

### BLOCKED

A thread is `BLOCKED` when it's trying to enter a `synchronized` block or method, but another thread already holds that lock. It sits here until the lock is released.

```java
class Resource {
    synchronized void access() {
        try { Thread.sleep(2000); } catch (InterruptedException e) {}
    }
}

Resource resource = new Resource();
Thread t1 = new Thread(resource::access);
Thread t2 = new Thread(resource::access);

t1.start();
Thread.sleep(100); // give t1 time to acquire the lock first
t2.start();
Thread.sleep(100); // give t2 time to actually hit the synchronized call
System.out.println(t2.getState()); // BLOCKED
```

Note the second `sleep` before checking `t2`'s state — without it, you might catch `t2` before it's even reached the `synchronized` call, and see `RUNNABLE` instead. State checks like this are inherently timing-sensitive.

### WAITING vs TIMED_WAITING

These two are easy to mix up, so it helps to see them side by side. Both mean "not competing for CPU time, parked on purpose" — the difference is whether there's a deadline.

`WAITING` has no timeout. The thread stays there until another thread explicitly wakes it:

```java
Object lock = new Object();
Thread t = new Thread(() -> {
    synchronized (lock) {
        try { lock.wait(); } catch (InterruptedException e) {} // waits forever
    }
});
t.start();
Thread.sleep(100);
System.out.println(t.getState()); // WAITING
```

It's also what you get from a no-argument `join()` — one thread waiting for another to finish, with no deadline:

```java
Thread worker = new Thread(() -> {
    try { Thread.sleep(2000); } catch (InterruptedException e) {}
});
worker.start();
Thread.sleep(100);
System.out.println(worker.getState()); // TIMED_WAITING (it's the one actually sleeping)
```

`TIMED_WAITING` is the same idea, but with a built-in expiry — `sleep(ms)`, `wait(ms)`, `join(ms)`, or `LockSupport.parkNanos()`. The thread wakes itself up even if nobody calls it:

```java
Thread t = new Thread(() -> {
    try { Thread.sleep(3000); } catch (InterruptedException e) {}
});
t.start();
Thread.sleep(100);
System.out.println(t.getState()); // TIMED_WAITING
```

So the rule of thumb: `BLOCKED` is about a **lock**, `WAITING`/`TIMED_WAITING` are about **time or another thread's signal** — `WAITING` has no deadline, `TIMED_WAITING` does.

### TERMINATED

Once `run()` finishes — normally or via an uncaught exception — the thread becomes `TERMINATED`. This is permanent; a `Thread` object can't be restarted.

```java
Thread t = new Thread(() -> System.out.println("done"));
t.start();
t.join();
System.out.println(t.getState()); // TERMINATED

t.start(); // throws IllegalThreadStateException
```

### How they connect

```
NEW --start()--> RUNNABLE
RUNNABLE --needs a held lock--> BLOCKED --lock acquired--> RUNNABLE
RUNNABLE --sleep()/wait(ms)/join(ms)--> TIMED_WAITING --timeout or notified--> RUNNABLE
RUNNABLE --wait()/join() no timeout--> WAITING --notify()/notifyAll() or target finishes--> RUNNABLE
RUNNABLE --run() completes--> TERMINATED
```

### Full example

```java
public class ThreadStateDemo {
    public static void main(String[] args) throws InterruptedException {
        Thread demo = new Thread(() -> {
            try { Thread.sleep(2000); } catch (InterruptedException e) {}
        });

        System.out.println(demo.getState()); // NEW
        demo.start();
        System.out.println(demo.getState()); // RUNNABLE
        Thread.sleep(500);
        System.out.println(demo.getState()); // TIMED_WAITING
        demo.join();
        System.out.println(demo.getState()); // TERMINATED
    }
}
```

### Quick reference

|State|Meaning|Caused by|
|---|---|---|
|`NEW`|Created, not started|`new Thread(...)`|
|`RUNNABLE`|Executing or ready to execute|`start()`|
|`BLOCKED`|Waiting on a held lock|entering a `synchronized` block another thread holds|
|`WAITING`|Waiting indefinitely for another thread|`wait()`, `join()`, `LockSupport.park()` — no timeout|
|`TIMED_WAITING`|Waiting, with an expiry|`sleep()`, `wait(ms)`, `join(ms)`|
|`TERMINATED`|Finished, final|`run()` returns or throws|


[[Threads]]