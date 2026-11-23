A Java program executes inside a single operating-system **process**, which owns the memory, open files, and network ports it reserves. Within that process, **threads** carry out the actual work — and most Spring Boot problems, from "port already in use" to "thread pool exhausted," trace back to these two concepts.
## Process vs. program

A **program** is just a file sitting on disk, doing nothing on its own. It only becomes a **process** once it's actually running — and a process is more than just "the program in motion." It's the program plus everything the operating system tracks about it: its own private memory space, open file handles, network connections, and a unique **PID** (process ID) that the OS uses to identify it.

Here's where it gets interesting for Spring Boot developers. When you run `java -jar app.jar`, the actual process the OS creates is the **JVM** — the `java` executable itself. Your `app.jar` isn't the process; it's just data the JVM reads and executes. The JVM is what gets the PID, what the OS schedules on the CPU, and what owns the memory.

So when people say "my Spring Boot app is running," what's technically true is: **a JVM process is running, and it happens to be executing your code.** This distinction matters later — for example, when you check `ps aux | grep java` and see a process, you're looking at the JVM, not your application directly.

- **Program:** A passive set of instructions stored on a storage device (such as an executable file).
    
- **Process:** An instance of a program that is currently being executed by the operating system.
 When we execute a Java application, the operating system starts a **JVM process** to run it.

## What a process owns

- **Private memory:** Each process gets its own virtual address space, so one process cannot read or corrupt another's memory. This isolation is why one crashing program doesn't take down the others.

- **Ports and files:** Only one process can hold a given port at a time. If you see `Port 8080 was already in use`, another process (often an old copy of your app) still owns it. On Debian, run `sudo ss -ltnp | grep 8080` to find its PID, then stop it or change your port.

- **Memory limits beyond the heap:** `-Xmx` caps only the Java heap. The JVM also needs memory for thread stacks, class metadata, and native buffers. In a container with a 1 GB limit, `-Xmx1g` can get the process killed, so leave headroom.

## Threads

Threads are the units that execute code. Within one process:

- All threads **share the heap**, where every object lives.
- Each thread has its **own stack** for local variables and method calls.

Sharing is fast but risky. If two threads run `count++` on the same variable, their read-modify-write steps can interleave and lose updates. This is a **race condition**. 
Fixes include :

- AtomicInteger
- synchronized
- ConcurrentHashMap

The OS scheduler switches the CPU between runnable threads. Each switch (a **context switch**) costs time, and each thread reserves about 1 MB for its stack by default — so 10,000 threads is a bad idea. Push the thread count too high and the costs compound: the scheduler spends more time switching than running your code, the run queue backs up as threads wait their turn, and all those 1 MB stacks can exhaust available memory before you even get to your actual workload.
A thread waiting on a database or network reply uses no CPU, but it still occupies a thread slot. 


A thread dump is a snapshot of every thread in a running JVM, showing each thread's state and full call stack at that exact moment — useful when an app seems frozen or is burning CPU for no clear reason. 

In a thread dump, Java's `BLOCKED` state specifically means a thread is waiting to enter a `synchronized` block that another thread already holds. By contrast, a thread waiting on a socket (or other OS-level I/O) often shows as `RUNNABLE`, since from the JVM's perspective it's just sitting in a system call rather than waiting on a JVM-managed lock — so `RUNNABLE` can mean either "actively running" or "stuck in the OS," and you have to check the stack trace underneath to tell which. You can capture a dump at any time with `jcmd <pid> Thread.print`, passing the process ID of the running JVM.

## How this shows up in Spring Boot

- **Thread pool exhaustion:** Embedded Tomcat handles requests on a pool of threads (default maximum 200). If every request waits on a slow database, all 200 threads sit idle waiting while new requests queue up, even though the CPU is nearly idle.
- **The database pool is often the real limit:** HikariCP defaults to 10 connections. Raising Tomcat's thread count alone won't help if requests are still waiting for connections.
- **Virtual threads** help with waiting. They are cheap, JVM-managed threads, so the JVM can park a waiting one and reuse the OS thread. Enable them with `spring.threads.virtual.enabled=true` (Spring Boot 3.2+). They don't help CPU-heavy work or enlarge your connection pool.

## When a process exits

The JVM exits when all non-daemon threads finish or when `System.exit()` is called. Returning from `main()` alone doesn't stop it, which is why a Spring Boot app keeps running: Tomcat's threads are still alive.

## Processes talking to each other

Separate processes can't share objects. They exchange bytes over sockets (HTTP, TCP), files, or pipes. Your app talking to PostgreSQL is one example, and microservices apply the same idea at a larger scale.



[[Threads]]