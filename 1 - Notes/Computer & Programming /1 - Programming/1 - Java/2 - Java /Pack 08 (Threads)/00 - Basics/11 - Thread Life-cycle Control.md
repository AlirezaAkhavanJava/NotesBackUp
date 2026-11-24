Now that you know the six states, the natural follow-up is: what actually moves a thread between them, and what do you call to find out? That's what `isAlive()`, `join()`, `sleep()`, and `yield()` are for — plus a couple of state nuances worth knowing before you start reading thread dumps for real.


![[Pasted image 20261124173005.png]]


### Two nuances on the states you already know

A `ReentrantLock` isn't the same as `synchronized`. A thread waiting to acquire one shows up as `WAITING`, not `BLOCKED` — because under the hood it's implemented with `park()`, not a monitor. `BLOCKED` is reserved specifically for contention on a `synchronized` lock.

Also worth knowing: a thread blocked on socket or file I/O still shows as `RUNNABLE`. The JVM only tracks Java-level waits, so if a thread dump shows `RUNNABLE` threads that look stuck, the next thing to check is whether they're sitting inside a native I/O call.

### `isAlive()`

Returns `true` from the moment `start()` succeeds until the thread reaches `TERMINATED`. So it's `false` for `NEW` and `TERMINATED`, `true` for everything in between.

```java
Thread t = new Thread(() -> { try { Thread.sleep(500); } catch (InterruptedException e) {} });
t.isAlive(); // false (NEW)
t.start();
t.isAlive(); // true
t.join();
t.isAlive(); // false (TERMINATED)
```

Don't use it to guard a `join()` — `if (t.isAlive()) t.join();` buys you nothing, since `join()` already returns instantly on a dead thread, and the thread could die in the gap between the check and the call anyway. Where it's actually useful is checking _after_ a timed `join()` whether the thread finished or you simply ran out of time — which leads into `join()` itself.

### `join()`

`t.join()` makes the _calling_ thread wait until `t` reaches `TERMINATED`. The caller itself ends up in `WAITING` or `TIMED_WAITING`, depending on which form you use:

|Form|Behavior|
|---|---|
|`join()`|waits forever|
|`join(long millis)`|waits at most that long, returns nothing|
|`join(Duration d)` (Java 19+)|waits at most that long, returns `true` if the thread had actually ended|

The plain timed form, `join(long)`, returns the same way whether the thread finished or the timeout hit — so you have to check `isAlive()` yourself afterward to tell which happened. `join(Duration)` saves you that step:

```java
worker.start();
if (!worker.join(Duration.ofSeconds(2))) {   // false = still running after 2s
    worker.interrupt();
    worker.join();
}
```

A few things to watch for: an untimed `join()` can hang your program forever if the target never finishes; a thread that calls `join()` on itself also waits forever; and the `InterruptedException` you catch is about _you_ (the waiting thread) being interrupted — it has nothing to do with the target thread. One more useful guarantee: everything the target thread wrote before finishing is visible to you once `join()` returns.

### `sleep()`

`Thread.sleep(ms)` is `static` — it always pauses whichever thread calls it, putting that thread in `TIMED_WAITING`. A `Thread.sleep(Duration)` overload also exists since Java 19.

Three things matter for real code: the duration is a _minimum_, not a guarantee — the thread wakes after at least that long, then still has to wait its turn for a core; sleeping does **not** release any locks the thread is holding; and if the thread is interrupted mid-sleep, it wakes immediately with an `InterruptedException`, with the interrupt flag cleared — so you need to catch that and either rethrow it or restore the flag.

```java
Thread.sleep(1000); // fine for demos/tests

// for real recurring work, don't loop a sleep — use a scheduler:
ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();
scheduler.scheduleAtFixedRate(() -> System.out.println("tick"), 0, 1, TimeUnit.SECONDS);
```

It's also worth keeping `sleep` and `wait` straight: `wait()` must be called inside a `synchronized` block, it _releases_ that lock while waiting, and it's woken by `notify()`. `sleep` needs no lock, keeps whatever locks it holds, and only ends via timeout or interrupt.

### `yield()`

`Thread.yield()` tells the scheduler "I'm willing to give up my slice right now" — but the scheduler is free to ignore it, and behavior varies across operating systems. It doesn't make code more correct, faster, or fairer in any dependable way, and real code almost never uses it. If you ever find yourself writing a spin loop, `Thread.onSpinWait()` (Java 9+) or a proper wait mechanism is the better tool. Thread priorities (`setPriority`) are in the same boat: a hint, not something to build correctness on.

### Putting it together

```java
public class TaskManager {
    private final Thread worker = new Thread(this::loop, "task-worker");

    public void start() {
        worker.setDaemon(true); // must be set before start()
        worker.setUncaughtExceptionHandler((t, e) ->
                System.err.println("Error in " + t.getName() + ": " + e));
        worker.start();
    }

    private void loop() {
        try {
            while (!Thread.currentThread().isInterrupted()) {
                System.out.println("Processing task...");
                Thread.sleep(1000);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt(); // restore the flag
        }
        System.out.println("Worker terminated");
    }

    public void stop() throws InterruptedException {
        worker.interrupt();
        if (!worker.join(Duration.ofSeconds(2))) {
            System.err.println("Worker did not stop in time");
        }
    }
}
```

The one piece here that's genuinely new is `setUncaughtExceptionHandler`: it catches an exception that escapes `run()` without a surrounding `try/catch`, so a bug in the worker gets logged instead of silently killing the thread with no trace. Everything else — the interrupt-flag loop, the timed `stop()`, the daemon flag — is just the `join`/`sleep`/interrupt pieces above, assembled into one stoppable background worker: interrupt as the single stop signal, a timed `join` so `stop()` can't hang forever, and a restored interrupt flag so the loop actually notices it was asked to stop.



[[Threads]]