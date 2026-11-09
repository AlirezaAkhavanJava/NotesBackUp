

A thread's **lifecycle** is the sequence of states it moves through from creation to death. Java exposes it as the `Thread.State` enum with six values: `NEW`, `RUNNABLE`, `BLOCKED`, `WAITING`, `TIMED_WAITING` and `TERMINATED`. A thread is always in exactly one of them, and `getState()` tells you which. The **control methods** (`join`, `sleep`, `yield`, `isAlive`) are the tools that move a thread between states or let you observe it.

Your `Thread` class lesson covered the handle-vs-thread idea, `start()` vs `run()`, interruption and daemon threads. This lesson goes deeper on one question: **why is a thread in the state it's in, and what gets it out?** That is what you need when you debug a stuck program or read a thread dump. It builds on your thread-creation lesson, where tasks were started and pooled.

## 1. The six states and what causes them

|State|What the thread is doing|What put it there|What gets it out|
|---|---|---|---|
|`NEW`|Object exists, no thread yet|`new Thread(...)`|`start()`|
|`RUNNABLE`|Running, or ready and waiting for a core|`start()`, or leaving any state below|the scheduler picks it, or it blocks|
|`BLOCKED`|Wants to enter a `synchronized` block that another thread holds|contended monitor lock|the other thread releases the lock|
|`WAITING`|Waiting **with no timeout** for another thread's action|`join()`, `Object.wait()`, `LockSupport.park()`|that action happens (target ends, `notify()`, `unpark()`)|
|`TIMED_WAITING`|Same, but with a timeout|`sleep(ms)`, `join(ms)`, `wait(ms)`|the action happens **or** time runs out|
|`TERMINATED`|Finished|`run()` returned or threw|nothing. It is permanent|

Three facts the note never stated:

- **`BLOCKED` and `WAITING` are different things.** `BLOCKED` means "I want a lock someone else holds". `WAITING` means "I'm waiting for another thread to do something". Only `synchronized` entry produces `BLOCKED`. `ReentrantLock` waits show up as `WAITING`, because they use `park()`.
- **A thread blocked on socket or file I/O shows as `RUNNABLE`.** The JVM only tracks Java-level waits. If a thread dump shows `RUNNABLE` threads that seem stuck, check whether they are inside a native I/O call.
- **No thread ever goes back to `NEW`, and `TERMINATED` is final.** That is why `start()` works only once.

## 2. Seeing each state in code

Reading a table is not the same as watching it happen. This program creates one thread in each interesting state:

```java
public class StatesDemo {
    static final Object lock = new Object();

    static void pause(long ms) {
        try { Thread.sleep(ms); }
        catch (InterruptedException e) { Thread.currentThread().interrupt(); }
    }

    public static void main(String[] args) {
        Thread sleeper = new Thread(() -> pause(1000), "sleeper");
        Thread holder  = new Thread(() -> { synchronized (lock) { pause(1000); } }, "holder");
        Thread blocked = new Thread(() -> { synchronized (lock) { } }, "blocked");
        Thread joiner  = new Thread(() -> {
            try { sleeper.join(); }
            catch (InterruptedException e) { Thread.currentThread().interrupt(); }
        }, "joiner");

        sleeper.start();
        holder.start();
        pause(100);            // let holder grab the lock first
        blocked.start();
        joiner.start();
        pause(100);

        for (Thread t : new Thread[] {sleeper, holder, blocked, joiner}) {
            System.out.println(t.getName() + ": " + t.getState());
        }
    }
}
```

Output (timing-based, but reliable on a normal machine):

```
sleeper: TIMED_WAITING
holder:  TIMED_WAITING
blocked: BLOCKED
joiner:  WAITING
```

What it shows:

- `holder` is `TIMED_WAITING`, **not** `BLOCKED`, because it is sleeping. It also **keeps the lock while sleeping**, which is exactly why `blocked` is stuck in `BLOCKED`.
- `joiner` is `WAITING`: it called `join()` with no timeout and is waiting for `sleeper` to finish.
- The `pause` helper handles the exception the correct way: restore the flag. Use it as your template.

## 3. `isAlive()`: has it started and not yet died?

`isAlive()` returns `true` from the moment `start()` succeeds until the thread is `TERMINATED`. So it is `false` in `NEW` and in `TERMINATED`, and `true` in the other four states.

```java
Thread t = new Thread(() -> pause(500));
t.isAlive();    // false (NEW)
t.start();
t.isAlive();    // true
t.join();
t.isAlive();    // false (TERMINATED)
```

**How not to use it:** `if (t.isAlive()) t.join();` is useless. `join()` already returns immediately on a dead thread, and the thread could die between your check and your call.

**Where it is genuinely useful:** after a timed join, to find out whether the thread finished or you just ran out of time (next section).

## 4. `join()`: wait for another thread to finish

`t.join()` makes the **calling** thread wait until `t` is `TERMINATED`. The caller sits in `WAITING` (or `TIMED_WAITING` for the timed forms).

|Form|Behavior|
|---|---|
|`join()`|waits forever|
|`join(long millis)`|waits at most that long, **returns nothing**|
|`join(Duration d)` (Java 19+)|waits at most that long, returns `true` if the thread ended|

The timed `join(long)` returns normally in both cases, so you must check `isAlive()` afterwards. The `Duration` version does that for you:

```java
worker.start();
if (!worker.join(Duration.ofSeconds(2))) {   // false = still running after 2s
    worker.interrupt();                      // ask it to stop
    worker.join();                           // wait for it to actually end
}
```

Pitfalls:

- `join()` with no timeout can hang your program forever if the target never ends.
- A thread that joins **itself** waits forever.
- The `InterruptedException` is about **you** being interrupted while waiting, not about the target.
- Everything the target wrote is visible to you after `join()` returns. This is the visibility guarantee from your `Thread` class lesson.

## 5. `sleep()`: pause the current thread

`Thread.sleep(ms)` is a **static** method. It always pauses the thread that calls it and puts that thread in `TIMED_WAITING`. There is also `Thread.sleep(Duration)` since Java 19.

Rules you need in real code:

- The duration is a **minimum**, not a promise. The thread resumes after _at least_ that long, then still has to wait for a core.
- It **does not release locks** you hold (you saw that with `holder`).
- If the thread is interrupted during the sleep, it wakes at once with `InterruptedException` and the interrupt flag is cleared. So catch it and either rethrow or restore the flag.

```java
// fine for demos and tests:
Thread.sleep(1000);

// production "do this every N seconds": use a scheduler instead of a sleep loop
ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();
scheduler.scheduleAtFixedRate(() -> System.out.println("tick"), 0, 1, TimeUnit.SECONDS);
```

`sleep` is also not `wait`. `Object.wait()` must be called inside `synchronized`, **releases** that lock while waiting, and is woken by `notify()`. `sleep` needs no lock, keeps any it holds, and only ends by timeout or interrupt. `wait`/`notify` is its own lesson.

## 6. `yield()`: a hint you can ignore

`Thread.yield()` tells the scheduler "I'm willing to give up my current time slice". The scheduler is free to ignore it, and behavior differs across operating systems. It does not make code correct, faster or fairer in any dependable way, and modern code almost never uses it. If you find a loop that spins waiting for a condition, the better tool is `Thread.onSpinWait()` (Java 9+) or, better still, a real wait mechanism.

Priorities (`setPriority`) are the same story: a hint, platform-dependent, not something to build correctness on.

## 7. Putting it together: a stoppable background worker

The note's `TaskManager` fixed. It has one stop mechanism (interruption), a named thread, a proper catch block, and a timed join:

```java
import java.time.Duration;

public class TaskManager {
    private final Thread worker = new Thread(this::loop, "task-worker");

    public void start() {
        worker.setDaemon(true);   // must be set before start()
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
            Thread.currentThread().interrupt();   // restore the flag
        }
        System.out.println("Worker terminated");
    }

    public void stop() throws InterruptedException {
        worker.interrupt();
        if (!worker.join(Duration.ofSeconds(2))) {
            System.err.println("Worker did not stop in time");
        }
    }

    public static void main(String[] args) throws InterruptedException {
        TaskManager manager = new TaskManager();
        manager.start();
        Thread.sleep(3000);
        manager.stop();
    }
}
```

Line by line:

- `new Thread(this::loop, "task-worker")`: the task is a method reference, so the work and the thread are separate.
- `loop()`: runs until the interrupt flag is set. If the interrupt arrives during `sleep`, the exception wakes the thread **immediately**. A separate `volatile boolean` could not do that, because a sleeping thread would not see the flag change until the sleep ended.
- `stop()`: sends the interrupt, then waits up to 2 seconds. If the worker is still alive after that, the program reports it instead of hanging forever.
- `setDaemon(true)`: if `main` ends without calling `stop()`, the JVM exits anyway. Use it only for work you can afford to lose.

## Related concepts in one line each

- **`Object.wait()` / `notify()`:** the classic mechanism behind `WAITING`, used inside `synchronized`.
- **`ReentrantLock`:** a lock whose waiting threads show up as `WAITING`, not `BLOCKED`.
- **`ScheduledExecutorService`:** the correct replacement for `sleep`-in-a-loop.
- **`CompletableFuture`:** composes async steps without manual `join()`.

## What to carry into real code

1. `BLOCKED` means a `synchronized` lock. `WAITING` and `TIMED_WAITING` mean waiting for another thread's action. `RUNNABLE` can still hide blocking I/O.
2. `isAlive()` is for "did that timed join finish?", not for guarding a `join()`.
3. Prefer `join(Duration)` over an unbounded `join()` in anything that must not hang.
4. `sleep()` holds locks and gives a minimum time. For recurring work, use a scheduler.
5. Ignore `yield()` and priorities.
6. Use **one** stop mechanism, interruption, and handle `InterruptedException` by restoring the flag.



[[Threads]]