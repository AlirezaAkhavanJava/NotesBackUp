


A **process** is a **running instance of a program**.

A program is passive code stored on disk:

```text
my-app
   ↓
program/code on disk
```

When the operating system loads that program into memory and begins executing it, it becomes a **process**:

```text
Program on disk
      ↓
Operating System loads it
      ↓
   PROCESS
```

For example, when you run:

```bash
java MyApplication
```

the `.class` files/JAR are the **program**, while the running Java application is a **process**.

---

# What does a Process contain?

A process isn't just "the code." The OS gives it resources and maintains information about it.

Conceptually:

```text
Process
│
├── Code
├── Data
├── Heap
├── Stack(s)
├── CPU state
├── Open files
├── Network connections
├── Memory mappings
└── Threads
```

Most importantly:

> **A process provides the isolated execution environment, while threads are the execution paths inside that environment.**

So:

```text
Process
│
├── Thread 1
├── Thread 2
├── Thread 3
└── Thread 4
```

This is why we normally say:

**Process = container/resource boundary**  
**Thread = execution unit**

---

# Process Lifecycle

A process goes through several states during its lifetime.

A simplified lifecycle is:

```text
             create
               ↓
          ┌──────────┐
          │   New    │
          └────┬─────┘
               ↓
          ┌──────────┐
          │  Ready   │◄──────────────┐
          └────┬─────┘               │
               ↓                     │
          ┌──────────┐               │
          │ Running  │───────────────┘
          └────┬─────┘    preempted
               │
        ┌──────┴──────┐
        ↓             ↓
     Waiting       Terminated
        │
        └────────→ Ready
```

Let's go through it.

### 1. New / Created

The OS receives a request to create a process.

On Linux, for example, this ultimately involves system calls such as:

```text
fork()
execve()
```

Conceptually:

```text
Shell
  │
  │ "run java"
  ↓
Operating System
  │
  ↓
creates process
```

---

### 2. Ready

The process exists and has everything it needs to execute, but it is **waiting for CPU time**.

```text
Ready queue:

[Process A] [Process B] [Process C]
                   ↑
              waiting for CPU
```

The OS scheduler decides which thread/process gets CPU time.

---

### 3. Running

The scheduler assigns a CPU to the process's thread.

```text
CPU
 ↓
Thread
 ↓
Process
```

The CPU is now executing instructions belonging to that process.

A process can move from:

```text
Ready → Running
```

and later:

```text
Running → Ready
```

if the OS preempts it to give another task CPU time.

---

### 4. Waiting / Blocked

The process may need something that isn't immediately available.

For example:

```java
readFromFile();
```

The thread may need to wait for I/O.

Other examples:

```text
Waiting for:
├── disk I/O
├── network I/O
├── keyboard input
├── another thread
├── synchronization lock
└── some OS event
```

It doesn't make sense to waste CPU time while waiting for the disk, so the OS can run another thread.

Eventually:

```text
Waiting
   ↓
event completed
   ↓
Ready
```

---

### 5. Terminated

When the process finishes its execution:

```text
main()
  ↓
last instruction
  ↓
process terminates
```

The OS then releases its resources.

For example:

```text
Process
   ↓
close/release resources
   ↓
memory released
   ↓
process gone
```

---

# The Complete Mental Model

Think of launching a Java application:

```text
        java MyApp
             │
             ▼
      Operating System
             │
             ▼
     Create Process
             │
             ▼
      Process = MyApp
             │
       ┌─────┴─────┐
       ▼           ▼
   Thread 1     other threads
       │
       ▼
    Running
       │
       ├──── I/O ────→ Waiting
       │                  │
       │                  ▼
       │                Ready
       │                  │
       └──────────────────┘
       │
       ▼
   Program finishes
       │
       ▼
   Terminated
```

### One crucial distinction

Don't think:

> "The OS runs processes."

More precisely:

> **The OS schedules threads for execution, and those threads execute within processes.**

A process can contain **one or many threads**.

```text
Process A                    Process B
│                            │
├── Thread 1                 ├── Thread 1
├── Thread 2                 └── Thread 2
└── Thread 3
```

The OS scheduler ultimately decides **which runnable threads get CPU time**.

That distinction becomes very important when you learn **Java threading, synchronization, executors, virtual threads, and concurrency**.


[[Java]]