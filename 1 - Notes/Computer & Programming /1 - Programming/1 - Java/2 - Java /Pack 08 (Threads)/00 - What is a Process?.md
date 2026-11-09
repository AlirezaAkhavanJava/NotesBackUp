

Every Java program you run, including a Spring Boot app, lives inside an operating-system **process**. The process owns the memory, the open files, and the network ports. **Threads**, the things that do the work and cause your concurrency bugs, live inside it.

We'll go in order: why processes exist, what they own, how threads fit inside, who gets the CPU, and how this shows up in a Spring Boot app. By the end, errors like "Port 8080 was already in use" and "thread pool exhausted" should read as plain cause and effect.

---

## Why processes exist

Picture a machine running your IDE, PostgreSQL, your app and a browser at the same time. With no structure, three things break:

- One program writes into memory another one is using, and corrupts it.
- One crashing program takes everything down with it.
- One infinite loop eats the CPU and nothing else runs.

So the OS wraps each running program in a **process**: a protected box with its own memory, its own resources, and a fair share of CPU time.

## Program vs. process

A **program** is just bytes on disk. A **process** is that program while it is running, plus everything the OS tracks about it. Run the same program twice and you get two independent processes, each with its own **PID**.

Here is the part that matters for Java:

```text
java -jar app.jar
```

The process being created is the **JVM** (the `java` executable). Your `app.jar` is only data the JVM loads and executes. "My Spring Boot app" really means "a JVM process executing my code." Everything below, whether memory, ports or crashes, belongs to that JVM process.

You can see the PID yourself:

```java
public class Demo {
    public static void main(String[] args) {
        System.out.println("PID: " + ProcessHandle.current().pid());
    }
}
```

Run it twice and you get two different PIDs, because each run is a new process.

---
## What a process owns

**Private memory.** Each process gets its own virtual address space. The OS maps those addresses to real RAM behind the scenes, so one process has no way to even name another process's memory. That is the isolation from the first section.

**Ports and files.** Open files and network sockets belong to the process. Only one process can own a given port at a time:

```text
Web server failed to start. Port 8080 was already in use.
```

That message means another process (often an old instance of your own app) is still holding 8080. To find it, use `lsof -i :8080` on Linux/macOS or `netstat -ano | findstr 8080` on Windows. Then kill the owner or change your port.

**A memory budget that is bigger than your heap.** `-Xmx` limits only the Java heap. The JVM process also needs memory for thread stacks, class metadata, JIT-compiled code and native buffers. If a container allows 1 GB, setting `-Xmx1g` will get your process killed. Leave headroom.

---
## Threads: the part that actually runs

A process by itself executes nothing. It is a container. The things that execute code are **threads**:

```text
JVM process
├── Shared by all threads: heap (every object), code, open sockets
├── Thread A → its own stack (local variables, call chain)
├── Thread B → its own stack
└── Thread C → its own stack
```

The rule to burn in:

> **Threads in one process share the heap. Each thread has its own stack.**

Objects live on the heap, so two threads can reach the same object. Local variables live on a thread's own stack, so they are private. Shared access is cheap, which is the upside. The downside is that two threads changing the same object at once can overwrite each other. Run this:

```java
public class Race {
    static int count = 0;

    public static void main(String[] args) throws InterruptedException {
        Runnable work = () -> {
            for (int i = 0; i < 100_000; i++) count++;
        };
        Thread a = new Thread(work);
        Thread b = new Thread(work);
        a.start();
        b.start();
        a.join();
        b.join();
        System.out.println(count);
    }
}
```

You would expect 200000, but you will usually get less. `count++` is three steps (read, add one, write back), and when two threads interleave those steps, one thread's update overwrites the other's. This is a **race condition**. The fixes are `AtomicInteger`, `synchronized`, or locks. It is also the reason `ConcurrentHashMap` exists.

Compared with processes, then, threads are cheap to create and cheap to communicate between, but they have no isolation. An uncaught `OutOfMemoryError` or a native crash can take down the whole JVM. A badly behaved thread can hurt every other thread in its process.

## Who gets the CPU

You may have hundreds of threads and 8 cores. The OS **scheduler** gives each runnable thread a short time slice, then switches to another one. A switch is called a **context switch**: save one thread's state, load another's. It is fast but not free, which is why creating 10,000 ordinary threads is a bad idea. Each one also reserves roughly 1 MB for its stack by default.

Note that the scheduler schedules **threads**, not processes. Processes don't run, threads do.

A thread is always in one of three basic situations:

```text
          scheduler picks it
   Ready ───────────────────→ Running
     ↑ ←─────────────────────── │
     │     time slice ends      │ waits for I/O, a lock, a sleep...
     │                          ↓
     └──────────────────────  Waiting
          what it waited for happened
```

A waiting thread uses no CPU, and the OS hands the CPU to someone else. What it does consume is a thread, which is a limited resource.

One detail that trips people up when reading thread dumps: Java has its own state names (`RUNNABLE`, `BLOCKED`, `WAITING`, `TIMED_WAITING`). `BLOCKED` in Java means specifically "waiting to enter a `synchronized` block." A thread stuck waiting for a database reply on a socket usually shows as `RUNNABLE`, even though it is doing nothing. You can take a thread dump of a running app with `jcmd <pid> Thread.print`.

---
## How this plays out in Spring Boot

Embedded Tomcat handles each incoming request on a thread from a pool. The default maximum is 200. Suppose every request calls a slow database. Threads spend most of their time waiting, so 200 concurrent slow requests occupy all 200 threads, and request 201 sits in a queue while your CPU is almost idle. That is the "thread pool exhausted" situation. The machine isn't busy. It just ran out of threads.

Two things are worth knowing here:

- **Your database connection pool is usually the real limit.** HikariCP's default is 10 connections. Even with 200 Tomcat threads, only 10 can talk to the database at once, and the other 190 wait for a connection. Raising the Tomcat limit without looking at this achieves nothing.
- **Virtual threads attack the waiting problem.** They are threads managed by the JVM instead of the OS, so cheap that you can have millions of them. When one waits on I/O, the JVM parks it and reuses the underlying OS thread for other work. In Spring Boot you turn them on with `spring.threads.virtual.enabled=true`, and Tomcat then runs each request on a virtual thread. On JDK 25 this works well with `synchronized` too, since the old problem of virtual threads getting pinned by `synchronized` was fixed in JDK 24. They help when you wait a lot, as with I/O. They do nothing for CPU-heavy work, and they don't enlarge your database connection pool.

---
## When a process ends

A JVM exits when **all non-daemon threads have finished**, or when something calls `System.exit()`. It does not exit just because `main()` returned. Your Spring Boot app keeps running after `main()` finishes because Tomcat's non-daemon threads are still alive. **Daemon** threads are background helpers the JVM doesn't wait for, so they die when the last non-daemon thread ends.

## How separate processes talk

Because of isolation, two processes can't just share objects. They exchange bytes through **sockets** (HTTP, TCP), files or pipes. Your Spring Boot app talking to PostgreSQL is two processes exchanging bytes over a socket, and microservices are the same idea at larger scale. Threads inside one process can share objects directly, but anything crossing a process boundary has to be serialized and sent.





[[Threads]]