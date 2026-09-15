

A Java thread moves through a set of **well-defined states** during its lifetime. Java exposes these states through `java.lang.Thread.State`.

There are **6 states**:

```text
NEW
 │
 │ start()
 ▼
RUNNABLE
 │
 ├──────────────┐
 │              │
 │ waiting      │ blocked
 ▼              ▼
WAITING       BLOCKED
 │              │
 └──────┬───────┘
        │
        ▼
    RUNNABLE
        │
        │ run() completes
        ▼
   TERMINATED
```

There is also **TIMED_WAITING**, which is a timed form of waiting.

---

### 1. `NEW`

The `Thread` object has been created, but the thread has **not started yet**.

```java
Thread t = new Thread(() -> {
    System.out.println("Hello");
});
```

At this point:

```text
Thread object exists
        ↓
Thread.State.NEW
```

No execution has started.

---

### 2. `RUNNABLE`

After:

```java
t.start();
```

the thread enters `RUNNABLE`.

```text
NEW
 ↓ start()
RUNNABLE
```

**Important:** `RUNNABLE` does not necessarily mean the thread is currently executing on a CPU.

It means:

> The thread is eligible to run — it may be running or waiting for CPU scheduling.

The JVM/OS scheduler decides when it actually executes.

```text
RUNNABLE
   │
   ├── CPU available → executing
   │
   └── CPU unavailable → waiting for CPU
```

Java deliberately combines the concepts of **ready** and **running** into `RUNNABLE`.

---

### 3. `BLOCKED`

A thread becomes `BLOCKED` when it is waiting to acquire an intrinsic monitor lock.

Example:

```java
synchronized (object) {
    // critical section
}
```

Imagine:

```text
Thread A
    ↓
holds lock on object
    ↓
Thread B
    ↓
tries synchronized(object)
    ↓
BLOCKED
```

When Thread A releases the monitor:

```text
BLOCKED
   ↓
RUNNABLE
```

---

### 4. `WAITING`

A thread enters `WAITING` when it waits **indefinitely** for another thread to perform some action.

For example:

```java
thread.join();
```

The calling thread waits until `thread` terminates.

Other operations that can produce `WAITING` include:

```java
Object.wait();
Thread.join();
LockSupport.park();
```

Conceptually:

```text
Thread A
   │
   │ wait for Thread B
   ▼
WAITING
   │
   │ B performs required action
   ▼
RUNNABLE
```

---

### 5. `TIMED_WAITING`

This is similar to `WAITING`, except the thread waits for a **maximum specified amount of time**.

Examples:

```java
Thread.sleep(1000);
```

or:

```java
thread.join(1000);
```

or:

```java
object.wait(1000);
```

For example:

```text
RUNNABLE
   │
   │ sleep(1000)
   ▼
TIMED_WAITING
   │
   │ 1000 ms passes
   ▼
RUNNABLE
```

The thread does **not** execute while it is sleeping.

---

### 6. `TERMINATED`

When the thread's `run()` method finishes, the thread becomes `TERMINATED`.

```java
Thread t = new Thread(() -> {
    System.out.println("Hello");
});

t.start();
```

Conceptually:

```text
NEW
 ↓
RUNNABLE
 ↓
run()
 ↓
TERMINATED
```

A terminated thread **cannot be started again**.

```java
t.start(); // first time → OK

t.start(); // second time → IllegalThreadStateException
```

---

# The Complete Java Lifecycle

```text
                       start()
             ┌─────────────────────┐
             │                     ▼
          ┌──────┐             ┌───────────┐
          │ NEW  │             │ RUNNABLE  │
          └──────┘             └─────┬─────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                    ▼                 ▼                 ▼
                BLOCKED           WAITING       TIMED_WAITING
                    │                 │                 │
                    └─────────────────┴─────────────────┘
                                      │
                                      ▼
                                  RUNNABLE
                                      │
                                      │ run() ends
                                      ▼
                                TERMINATED
```

### One important correction from the OS model

You may notice that the Java lifecycle doesn't have a separate:

```text
READY
RUNNING
```

state.

That's because Java's `Thread.State` defines both as:

```text
RUNNABLE
```

So don't confuse:

**OS process/thread model:**

```text
Ready → Running → Blocked/Waiting
```

with Java's API-level model:

```text
RUNNABLE ↔ BLOCKED
         ↔ WAITING
         ↔ TIMED_WAITING
```

The Java `Thread.State` enum is an **abstraction over the underlying JVM/OS scheduling machinery**, not a one-to-one representation of every OS scheduler state.


[[Java]]