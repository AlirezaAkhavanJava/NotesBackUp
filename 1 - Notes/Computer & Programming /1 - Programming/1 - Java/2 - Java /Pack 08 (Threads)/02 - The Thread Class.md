

`java.lang.Thread` represents **one path of execution** inside your program. When you create a `Thread` and call `start()`, the JVM gives it its own stack and runs your code on it, side by side with the thread that started it. Executors, `CompletableFuture`, parallel streams and Tomcat's request handling are all built on this class.

The key idea: **a `Thread` object is not the running thread. It is a handle to it.** The object is an ordinary heap object holding a name, a state, a priority, and the work to do. For a platform thread, the OS thread only comes into existence when you call `start()`. Keep those two things separate in your head and most of the API becomes obvious. This lesson builds on your concurrency and parallelism lesson (what a thread is on the hardware) and your thread-creation lesson (`Runnable`, pools, virtual threads). Here we go inside the class.

## 1. Where the work comes from

`Thread` implements `Runnable`, so it has a `run()` method. The default version is essentially:

```java
public void run() {
    if (target != null) target.run();
}
```

`target` is the `Runnable` you passed to the constructor. This explains two behaviors:

- Pass a `Runnable` and `run()` forwards to it.
- Extend `Thread` and override `run()`, and the `target` is **ignored**, because your version replaced this one.

```java
new Thread(() -> System.out.println("from a Runnable")).start();

class Greeter extends Thread {
    @Override public void run() { System.out.println("from an override"); }
}
new Greeter().start();
```

Prefer the `Runnable` form. A pool only ever calls `run()` on what you give it. It never calls `start()`, so a `Thread` subclass handed to a pool just becomes a plain task with a useless thread wrapper around it.

## 2. Constructing a thread

Creating a thread does **not** start it. The constructor only prepares the object. Four pieces of information matter:

|Parameter|Meaning|
|---|---|
|`target` (`Runnable`)|The work. May be `null` if you override `run()`.|
|`name` (`String`)|Defaults to `Thread-0`, `Thread-1`... Always name your threads; logs and thread dumps become readable.|
|`group` (`ThreadGroup`)|A legacy grouping mechanism. Ignore it.|
|`stackSize` (`long`)|A _suggestion_ in bytes. `0` means default, and the JVM may ignore it.|

The forms you will actually use are:

```java
new Thread(task);                // auto name
new Thread(task, "worker-1");    // the one you'll use most
new Thread("worker-1");          // from a subclass: super("worker-1")
```

The other constructors just combine these parameters with a group or stack size. The only extra option worth knowing is the last one, which can stop the thread from copying the creator's `InheritableThreadLocal` values.

During construction, the new thread **inherits the daemon flag and priority from the thread that created it** and receives a unique id. The state at this point is `NEW`, and no OS thread exists yet.

## 3. The lifecycle

A thread is always in exactly one of six states (`Thread.State`):

```
NEW --start()--> RUNNABLE <--> BLOCKED / WAITING / TIMED_WAITING --> TERMINATED
```

|State|Meaning|How it gets there|
|---|---|---|
|`NEW`|Object created, not started|`new Thread(...)`|
|`RUNNABLE`|Running, **or** ready and waiting for a core|`start()`|
|`BLOCKED`|Waiting to enter a `synchronized` block another thread holds|contended monitor lock|
|`WAITING`|Waiting indefinitely for another thread|`join()`, `Object.wait()`, `LockSupport.park()`|
|`TIMED_WAITING`|Waiting with a timeout|`sleep(ms)`, `join(ms)`, `wait(ms)`|
|`TERMINATED`|Finished. It can never be restarted.|`run()` returned or threw|

`RUNNABLE` does not mean "on a core right now". It means "eligible to run". The OS scheduler decides when it actually gets a core.

**What `start()` does:**

1. It throws `IllegalThreadStateException` if the state is not `NEW`. A thread starts **once**.
2. The JVM asks the OS for a native thread with its own stack (platform threads).
3. The thread becomes `RUNNABLE`, and `start()` **returns immediately**.
4. Later the scheduler runs the thread, which calls `run()`.
5. When `run()` ends or throws, the thread is `TERMINATED` and its resources are released.

That also settles the common confusion. `t.run()` is an ordinary method call that executes on the **calling** thread. Only `t.start()` creates a new one.

## 4. Pausing and waiting: `sleep` and `join`

```java
public static void main(String[] args) throws InterruptedException {
    Thread t = new Thread(() -> {
        try { Thread.sleep(500); } catch (InterruptedException e) { return; }
    }, "demo");

    System.out.println(t.getState());   // NEW
    t.start();
    Thread.sleep(100);
    System.out.println(t.getState());   // TIMED_WAITING (inside sleep)
    t.join();                           // main waits until demo finishes
    System.out.println(t.getState());   // TERMINATED
}
```

- `Thread.sleep(ms)` is **static**. It always pauses the **current** thread, so `t.sleep(1000)` does not put `t` to sleep. It also does **not** release locks the thread holds.
- `t.join()` makes the caller wait until `t` is `TERMINATED`. `join(ms)` waits at most that long.
- Both throw the checked `InterruptedException`, which is why `main` declares it. Section 5 explains why.

**Visibility rule:** everything a thread did _before_ calling `start()` is visible to the new thread. Everything the new thread did is visible to whoever returns from `join()` on it. Those two guarantees are why you can safely hand data into a thread and read its result after `join()`. Between `start()` and `join()`, if both threads touch the same field, nothing is guaranteed. That is a race condition, and you need synchronization (the next lesson).

## 5. Stopping a thread: interruption

Java has no safe "kill thread" command. `stop()`, `suspend()` and `resume()` are deprecated and unsafe, since they could freeze or kill a thread while it holds locks and leave data half-updated. In recent versions they throw `UnsupportedOperationException`, and `destroy()` was removed. The replacement is **cooperative cancellation**: you ask, and the thread decides how to stop.

```java
Thread worker = new Thread(() -> {
    while (!Thread.currentThread().isInterrupted()) {
        System.out.println("working...");
        try {
            Thread.sleep(300);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();   // restore the flag
            break;
        }
    }
    System.out.println("stopping cleanly");
}, "worker");

worker.start();
Thread.sleep(1000);
worker.interrupt();   // the request
worker.join();
```

How it works:

- `interrupt()` sets a boolean **interrupt flag** on the target thread.
- If the thread is inside `sleep`, `wait` or `join`, it wakes immediately and throws `InterruptedException`. **That exception clears the flag**, so the example restores it with `interrupt()`. Otherwise code higher up never learns about the request.
- If the thread is running normal code, only the flag is set. Your code must check it, as the `while` condition does.
- Blocking on a plain socket read or a `synchronized` lock usually ignores interrupts.

Two methods look alike and behave differently:

|Method|Which thread|Clears the flag?|
|---|---|---|
|`t.isInterrupted()`|the thread `t`|no|
|`Thread.interrupted()` (static)|the **current** thread|**yes**|

The rule for your own code: never swallow `InterruptedException` with an empty `catch`. Either rethrow it or restore the flag.

## 6. Daemon threads

The JVM exits when the last **non-daemon** (user) thread ends. **Daemon** threads are background helpers: the JVM does not wait for them, and it stops them abruptly.

```java
Thread flusher = new Thread(() -> { while (true) { /* flush logs */ } });
flusher.setDaemon(true);   // must be before start(), else IllegalThreadStateException
flusher.start();
```

Never put work that must complete (saving data) on a daemon thread, because it can be cut off mid-way. Virtual threads are always daemon, so a program whose `main` finishes will not wait for them. You must `join()` them or use an executor that waits.

## 7. Exceptions inside a thread

An uncaught exception kills **only that thread**. Other threads keep running, and nothing is thrown to the code that called `start()`:

```java
Thread t = new Thread(() -> { throw new IllegalStateException("boom"); }, "faulty");
t.setUncaughtExceptionHandler((thread, ex) ->
        System.out.println(thread.getName() + " died: " + ex.getMessage()));
t.start();
```

- Without a handler, Java prints the stack trace to `System.err`.
- A `try/catch` around `t.start()` catches nothing, because the failure happens on a different thread.
- `Thread.setDefaultUncaughtExceptionHandler(...)` sets one for all threads that lack their own.

## 8. Modern creation and virtual threads (Java 21+)

```java
Thread p = Thread.ofPlatform().name("worker-", 1).start(task);   // worker-1, worker-2...
Thread v = Thread.ofVirtual().name("v-1").start(task);
Thread.startVirtualThread(task);
```

- `.start(task)` builds and starts. `.unstarted(task)` builds without starting.
- A virtual thread is a `Thread` too, and `isVirtual()` tells them apart. Its name is **empty by default**, so name it if you log it.

## 9. Everyday inspection methods

|Method|Returns|
|---|---|
|`Thread.currentThread()`|the thread executing this line|
|`getName()` / `threadId()`|name / unique id (`getId()` is deprecated since Java 19)|
|`getState()`|one of the six states|
|`isAlive()`|`true` from `start()` until `TERMINATED`|
|`getStackTrace()`|that thread's current call stack|

**Priority and `yield()`:** `setPriority(1..10)` and `Thread.yield()` are only hints, and the OS may ignore them. Never use them to make code correct. If task A must finish before task B, use `join` or a lock.

## Related concepts in one line each

- **`Callable` / `ExecutorService`:** run tasks that return results, with threads managed for you (see your thread-creation lesson).
- **`ThreadLocal`:** gives each thread its own private copy of a variable.
- **`wait()` / `notify()`:** live on `Object`, not `Thread`. They coordinate threads inside `synchronized` blocks.

## What to carry into real code

1. The `Thread` object is a handle. The running thread starts at `start()`.
2. `start()` once, never `run()`. Name every thread.
3. `join()` to wait, and what a thread wrote before it ended is visible after `join()`.
4. Stop with `interrupt()` and handle `InterruptedException` properly.
5. Uncaught exceptions kill only their own thread, so set a handler.
6. Anything two threads both modify needs synchronization. That is the next lesson.


[[Threads]]