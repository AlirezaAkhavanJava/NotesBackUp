

`java.lang.Thread` is the class Java uses to represent **one path of execution** inside your program. When you create a `Thread` and call `start()`, the JVM asks the operating system for a real thread, gives it its own stack, and runs your code on it, side by side with the thread that started it. Everything in Java's concurrency world (executors, `CompletableFuture`, parallel streams, Tomcat's request handling) is built on top of this one class.

The most important thing to understand is this: **a `Thread` object is not the running thread. It is a handle to it.** The Java object is just a normal object on the heap that holds a name, a state, a priority, and the work to do. The actual running thread lives in the OS and only comes into existence when you call `start()`. Once you see the object and the running thread as two separate things, almost every method on this class makes sense.

---

## 1. What a `Thread` object holds

Here is the shape of the class, simplified:

```java
public class Thread implements Runnable {
    // simplified view of what it carries
    private String name;          // "Thread-0", "main", or your own name
    private Runnable target;      // the work to run (can be null)
    private int priority;         // hint to the scheduler (1 to 10)
    private boolean daemon;       // background thread or not
    private long threadId;        // unique number
    // ... plus the thread state and a link to the native OS thread
}
```

Two facts follow from this:

- `Thread` **implements `Runnable`**, so a `Thread` itself has a `run()` method.
- The default `run()` is tiny and very important:

```java
public void run() {
    if (target != null) {
        target.run();
    }
}
```

Read it slowly. When the new thread starts, it calls `run()`. If you gave the thread a `Runnable` in the constructor, `run()` forwards to it. If you _override_ `run()` in a subclass, the `target` is ignored, because your version replaced this one.

---

## 2. Two ways to give a thread its work

**Way 1: pass a `Runnable` (preferred)**

```java
Thread t = new Thread(() -> System.out.println("Hi from " + Thread.currentThread().getName()));
t.start();
```

**Way 2: extend `Thread` and override `run()`**

```java
class Greeter extends Thread {
    Greeter(String name) {
        super(name);
    }

    @Override
    public void run() {
        System.out.println("Hi from " + getName());
    }
}

new Greeter("greeter-1").start();
```

Line by line:

- `extends Thread`: your class _is_ a thread.
- `super(name)`: calls the `Thread(String name)` constructor to set the name.
- `@Override public void run()`: the work goes here.
- `.start()`: launches it.

||Pass a `Runnable`|Extend `Thread`|
|---|---|---|
|Separates _what to do_ from _how it runs_|Yes|No, mixed together|
|Can your class extend something else?|Yes|No (Java allows one parent class)|
|Works with thread pools|Yes|Awkward|
|Recommended|Yes|Rarely|

Choose the `Runnable` way. It keeps your task reusable, because the same task can later run in a pool or on a virtual thread without changing it.

---

## 3. Constructors and their parameters

First, what each parameter means:

|Parameter|Type|Meaning|
|---|---|---|
|`target`|`Runnable`|The work the thread will run. If `null`, the thread's own `run()` is used.|
|`name`|`String`|The thread's name. If you skip it, Java names it `Thread-0`, `Thread-1`, and so on. Good names make logs and debugging much easier.|
|`group`|`ThreadGroup`|A group to organize threads (rarely used today). If you skip it, the thread joins the creator's group.|
|`stackSize`|`long`|A _suggested_ stack size in bytes. `0` means "use the default". The JVM may ignore it.|

Now the constructors:

|Constructor|What it does|
|---|---|
|`Thread()`|No work given, auto name. Used when you override `run()`.|
|`Thread(Runnable target)`|Runs `target`, auto name.|
|`Thread(Runnable target, String name)`|Runs `target` with your name. **The one you'll use most.**|
|`Thread(String name)`|No target, named. Used with subclasses via `super(name)`.|
|`Thread(ThreadGroup group, Runnable target)`|Puts the thread in a group.|
|`Thread(ThreadGroup group, String name)`|Same, with a name and no target.|
|`Thread(ThreadGroup group, Runnable target, String name)`|Group, work, and name together.|
|`Thread(ThreadGroup group, Runnable target, String name, long stackSize)`|Also suggests a stack size.|
|`Thread(ThreadGroup group, Runnable target, String name, long stackSize, boolean inheritInheritableThreadLocals)`|Also controls whether it copies the creator's inheritable `ThreadLocal` values.|

### What happens inside a constructor

Creating a thread does **not** start it. The constructor only prepares the object:

1. Sets the name (yours, or `Thread-N`).
2. **Inherits** two settings from the thread that is creating it: the **daemon** flag and the **priority**.
3. Joins a thread group.
4. Stores the `target`.
5. Assigns a unique thread id.

At this point no OS thread exists yet. The state is `NEW`.

---

## 4. The flow: from `new` to `TERMINATED`

A thread is always in exactly one of six states, shown by the `Thread.State` enum.

```
        new Thread(...)
              |
              v
            NEW
              |  start()
              v
         RUNNABLE  <------------------------------+
        /    |    \                               |
       /     |     \                              |
      v      v      v                             |
 BLOCKED  WAITING  TIMED_WAITING ------------------+
 (waiting (wait(), (sleep(ms), join(ms),            (when the lock is free /
  for a    join(),  wait(ms), ...)                   notified / time is up)
  lock)    park)
              |
              |  run() finishes or throws
              v
         TERMINATED
```

|State|Meaning|How a thread gets there|
|---|---|---|
|`NEW`|Object created, not started|`new Thread(...)`|
|`RUNNABLE`|Running now, _or_ ready and waiting for a CPU core|`start()`|
|`BLOCKED`|Waiting to enter a `synchronized` block held by another thread|Trying to take a busy monitor lock|
|`WAITING`|Waiting with no time limit for another thread's action|`join()`, `Object.wait()`, `LockSupport.park()`|
|`TIMED_WAITING`|Waiting with a time limit|`sleep(ms)`, `join(ms)`, `wait(ms)`|
|`TERMINATED`|Finished; cannot be restarted|`run()` ended or threw an exception|

A thread in `RUNNABLE` is not necessarily on a core right now. It means "eligible to run." The scheduler (from the hardware lesson) decides when it gets a core.

### What `start()` actually does

```java
Thread t = new Thread(task, "worker");
t.start();
```

Step by step:

1. `start()` checks the state. If it's not `NEW`, it throws **`IllegalThreadStateException`**. A thread can be started **only once**.
2. The JVM asks the OS to create a native thread and allocate its stack.
3. The new thread is marked `RUNNABLE`.
4. `start()` **returns immediately** to the caller. The caller does not wait.
5. Later, when the scheduler gives the new thread a core, it calls `run()`.
6. When `run()` finishes (or throws), the thread becomes `TERMINATED` and the OS resources are released.

### `start()` vs `run()`

```java
t.run();    // just a normal method call, on the CURRENT thread. No new thread.
t.start();  // creates a new thread, which then calls run()
```

||`start()`|`run()`|
|---|---|---|
|New thread created?|Yes|No|
|Who executes the code?|The new thread|The calling thread|
|Can call twice?|No, throws exception|Yes, it's an ordinary method|

### Watching the states in code

```java
Thread t = new Thread(() -> {
    try {
        Thread.sleep(500);
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
    }
}, "demo");

System.out.println(t.getState());   // NEW
t.start();
System.out.println(t.getState());   // usually RUNNABLE
Thread.sleep(100);
System.out.println(t.getState());   // TIMED_WAITING (it is inside sleep)
t.join();
System.out.println(t.getState());   // TERMINATED
```

Line by line:

- Before `start()`, the object exists, but no thread does: `NEW`.
- Right after `start()`, the thread is ready or running: `RUNNABLE`.
- After 100 ms, the thread is inside `sleep(500)`: `TIMED_WAITING`.
- `join()` makes `main` wait for `demo` to finish. After it returns: `TERMINATED`.

---

## 5. The methods, grouped by purpose

### A. Controlling execution

|Method|What it does|
|---|---|
|`start()`|Starts the thread (once only).|
|`run()`|The work itself. You don't call it directly.|
|`join()`|The caller waits until this thread finishes.|
|`join(long millis)`|Waits at most that long.|
|`static sleep(long millis)`|Pauses the **current** thread for that time.|
|`static yield()`|A hint: "I'm happy to let another thread run." The scheduler may ignore it.|
|`interrupt()`|Politely asks the thread to stop what it's doing.|
|`isInterrupted()`|Checks the interrupt flag without clearing it.|
|`static interrupted()`|Checks the **current** thread's flag **and clears it**.|

Notes worth remembering:

- `sleep` is **static** and always affects the thread that calls it. `t.sleep(1000)` does _not_ put `t` to sleep. It sleeps the current thread.
- `sleep` does **not** release locks. A thread sleeping inside a `synchronized` block still holds the lock.
- `join` is how you say "don't continue until that thread is done."

### B. Information about a thread

|Method|What it does|
|---|---|
|`static currentThread()`|Returns the thread running this very line of code.|
|`getName()` / `setName(String)`|Read or change the name.|
|`threadId()`|The unique id (use this one; `getId()` is deprecated since Java 19).|
|`getState()`|Returns the `Thread.State`.|
|`isAlive()`|`true` if started and not yet terminated.|
|`isDaemon()` / `setDaemon(boolean)`|Read or set daemon status (before `start()`).|
|`getPriority()` / `setPriority(int)`|Read or set priority, from `1` (`MIN_PRIORITY`) to `10` (`MAX_PRIORITY`), default `5`.|
|`getThreadGroup()`|The group it belongs to.|
|`isVirtual()`|`true` for virtual threads (Java 21+).|

### C. Handling errors

|Method|What it does|
|---|---|
|`setUncaughtExceptionHandler(handler)`|Code to run if **this** thread dies from an uncaught exception.|
|`static setDefaultUncaughtExceptionHandler(handler)`|The same, for **all** threads without their own handler.|

### D. Creating threads the modern way (Java 21+)

```java
Thread p = Thread.ofPlatform().name("worker-", 1).start(() -> System.out.println("platform"));
Thread v = Thread.ofVirtual().name("virtual-1").start(() -> System.out.println("virtual"));
Thread q = Thread.startVirtualThread(() -> System.out.println("quick virtual"));
```

- `Thread.ofPlatform()`: a builder for ordinary OS-backed threads.
- `Thread.ofVirtual()`: a builder for cheap virtual threads.
- `.name("worker-", 1)`: names them `worker-1`, `worker-2`, and so on.
- `.start(runnable)`: builds and starts in one step. `.unstarted(runnable)` builds without starting.
- `startVirtualThread(...)`: a shortcut for starting a virtual thread.

### E. Debugging helpers

|Method|What it does|
|---|---|
|`getStackTrace()`|The current call stack of that thread.|
|`static getAllStackTraces()`|Stacks of all live threads.|
|`static dumpStack()`|Prints the current thread's stack.|

### F. Deprecated, never use

`stop()`, `suspend()`, `resume()`, `destroy()`. They are unsafe because they can freeze or kill a thread while it holds locks, leaving data half-updated. Use **interruption** instead.

---

## 6. Interruption: the right way to stop a thread

Java has no safe "kill thread" command. Instead, you **ask** the thread to stop, and the thread cooperates. This is called **cooperative cancellation**.

```java
Thread worker = new Thread(() -> {
    while (!Thread.currentThread().isInterrupted()) {
        System.out.println("working...");
        try {
            Thread.sleep(300);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            break;
        }
    }
    System.out.println("worker stopping cleanly");
}, "worker");

worker.start();
Thread.sleep(1000);
worker.interrupt();
worker.join();
```

Line by line:

- `while (!Thread.currentThread().isInterrupted())`: keep working until someone asks us to stop.
- `Thread.sleep(300)`: while sleeping, if `interrupt()` is called, `sleep` wakes up immediately and throws `InterruptedException`.
- **Important:** when `InterruptedException` is thrown, the interrupt flag is **cleared**. So we call `Thread.currentThread().interrupt()` to put the flag back, so code higher up can still see it.
- `break`: leave the loop and finish.
- In `main`: after one second, `worker.interrupt()` sends the request, and `join()` waits for the clean exit.

How interrupt affects each state:

|Thread is...|`interrupt()` effect|
|---|---|
|In `sleep`, `wait`, `join`|Wakes it up with `InterruptedException` (flag cleared)|
|Running normal code|Just sets the flag. The code must check it.|
|Blocked reading a normal socket or lock|Usually no effect (some `java.nio` and `Lock.lockInterruptibly` calls do react)|

---

## 7. Daemon threads

A JVM stays alive as long as at least one **non-daemon (user)** thread is running. **Daemon** threads are background helpers, and the JVM does not wait for them. When the last user thread ends, the JVM exits and daemon threads are stopped abruptly.

```java
Thread logger = new Thread(() -> {
    while (true) { /* flush logs forever */ }
});
logger.setDaemon(true);
logger.start();
```

- `setDaemon(true)` must be called **before** `start()`, otherwise you get `IllegalThreadStateException`.
- Daemon status is inherited from the creating thread.
- Don't use daemon threads for work that must finish (like saving data), since they can be cut off mid-way. The garbage collector is a classic daemon.

---

## 8. What happens when a thread throws an exception

An uncaught exception **kills only that thread**. Other threads keep running, and nothing is thrown to the code that called `start()`.

```java
Thread t = new Thread(() -> {
    throw new IllegalStateException("boom");
}, "faulty");

t.setUncaughtExceptionHandler((thread, ex) ->
        System.out.println(thread.getName() + " died: " + ex.getMessage()));

t.start();
```

- Without a handler, Java prints the stack trace to `System.err`.
- With a handler, you decide what to do: log it, alert, restart a worker.
- A `try/catch` around `t.start()` will **not** catch it, because the error happens on a different thread.

---

## 9. Priority: only a hint

`setPriority(Thread.MAX_PRIORITY)` tells the scheduler "this one is more important." But priority is a **hint**. Different operating systems treat it differently, and some largely ignore it. Never rely on priority for correctness. If one task must happen before another, use `join`, locks, or other coordination tools.

---

## 10. Putting it all together

```java
public class ThreadFlowDemo {
    public static void main(String[] args) throws InterruptedException {
        Runnable task = () -> {
            String me = Thread.currentThread().getName();
            System.out.println(me + " started");
            try {
                Thread.sleep(200);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return;
            }
            System.out.println(me + " finished");
        };

        Thread a = new Thread(task, "A");
        Thread b = new Thread(task, "B");

        System.out.println("main: starting threads");
        a.start();
        b.start();

        a.join();
        b.join();
        System.out.println("main: all done");
    }
}
```

Possible output:

```
main: starting threads
A started
B started
A finished
B finished
main: all done
```

The flow:

|Step|main thread|Thread A|Thread B|
|---|---|---|---|
|1|creates `a`, `b` (both `NEW`)|||
|2|`a.start()`, `b.start()` returns immediately|`RUNNABLE`|`RUNNABLE`|
|3|`a.join()` (main `WAITING`)|prints "started", sleeps (`TIMED_WAITING`)|same|
|4|still waiting|wakes, prints "finished", `TERMINATED`|same|
|5|`join()` returns, prints "all done"|||

The order of "A started" and "B started" can swap between runs. Only the facts guaranteed by `join` are reliable: "all done" always comes last.

---

## 11. Common mistakes

|Mistake|What goes wrong|Fix|
|---|---|---|
|Calling `run()` instead of `start()`|No new thread, code runs on the caller|Use `start()`|
|Starting the same thread twice|`IllegalThreadStateException`|Create a new `Thread` object|
|Thinking `t.sleep()` sleeps `t`|It sleeps the **current** thread|Call `Thread.sleep()` from inside the thread to pause|
|Swallowing `InterruptedException` with an empty `catch`|Cancellation signal is lost|Restore the flag with `interrupt()` or rethrow|
|Using `stop()`|Corrupted state, deprecated|Use interruption|
|Expecting a fixed order of output|Scheduler decides|Use `join`, locks, or other synchronization|
|Creating thousands of platform threads|Memory exhaustion (about 1 MB stack each)|Use a thread pool or virtual threads|

---

## Short summaries of related concepts

- **`Runnable`:** an interface with one method, `void run()`. It describes _work_, with no return value and no checked exceptions.
- **`Callable<V>`:** like `Runnable`, but returns a result and can throw checked exceptions. Used with `ExecutorService` and `Future`.
- **`ExecutorService` (thread pool):** manages and reuses threads for you, so you rarely call `new Thread` directly in real applications.
- **`ThreadLocal`:** gives each thread its own private copy of a variable, so threads don't share it.
- **`ThreadGroup`:** an old way to group threads. Mostly legacy now.
- **`Object.wait()` / `notify()` / `notifyAll()`:** these live on `Object`, not `Thread`. They let threads wait for a condition and be woken, and must be called inside `synchronized`.
- **Virtual threads:** lightweight threads managed by the JVM (Java 21+), created with the same `Thread` class, ideal for many blocking I/O tasks.

---

## Quick recap

1. A `Thread` object is a **handle**. The real OS thread appears only at `start()`.
2. Give it work with a **`Runnable`** (preferred) or by overriding `run()`.
3. Constructors combine **target, name, group, stack size**. Name and priority/daemon are set or inherited at construction.
4. The lifecycle is **NEW → RUNNABLE → (BLOCKED / WAITING / TIMED_WAITING) → TERMINATED**, and a thread starts only once.
5. `start()` creates a new thread. `run()` is a plain method call.
6. Stop threads with **interruption**, never `stop()`.
7. Exceptions kill only their own thread. Use an uncaught exception handler.




[[Java]]