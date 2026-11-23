A Java program runs inside an operating-system **process**, which owns the memory, files, and network ports it uses. Inside that process, **threads** do the actual work. Most Spring Boot problems, such as "port already in use" or "thread pool exhausted," come down to these two ideas.
## Process vs. program

A program is a file on disk. A process is that program while it runs, plus everything the OS tracks about it, including a unique **PID**. When you run `java -jar app.jar`, the process is the `java` executable (the JVM), and your jar is data it loads. So "my Spring Boot app" is really "a JVM process running my code."

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

The OS scheduler switches the CPU between runnable threads. Each switch (a **context switch**) costs time, and *each thread reserves about 1 MB for its stack by default*, so 10,000 threads is a bad idea.

A thread waiting on a database or network reply uses no CPU, but it still occupies a thread slot. 

In a thread dump, Java's `BLOCKED` state specifically means waiting to enter a `synchronized` block. A thread waiting on a socket often shows as `RUNNABLE`. You can capture a dump with `jcmd <pid> Thread.print`.

## How this shows up in Spring Boot

- **Thread pool exhaustion:** Embedded Tomcat handles requests on a pool of threads (default maximum 200). If every request waits on a slow database, all 200 threads sit idle waiting while new requests queue up, even though the CPU is nearly idle.
- **The database pool is often the real limit:** HikariCP defaults to 10 connections. Raising Tomcat's thread count alone won't help if requests are still waiting for connections.
- **Virtual threads** help with waiting. They are cheap, JVM-managed threads, so the JVM can park a waiting one and reuse the OS thread. Enable them with `spring.threads.virtual.enabled=true` (Spring Boot 3.2+). They don't help CPU-heavy work or enlarge your connection pool.

## When a process exits

The JVM exits when all non-daemon threads finish or when `System.exit()` is called. Returning from `main()` alone doesn't stop it, which is why a Spring Boot app keeps running: Tomcat's threads are still alive.

## Processes talking to each other

Separate processes can't share objects. They exchange bytes over sockets (HTTP, TCP), files, or pipes. Your app talking to PostgreSQL is one example, and microservices apply the same idea at a larger scale.



[[Threads]]