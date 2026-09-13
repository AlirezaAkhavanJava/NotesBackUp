


## 1. The Problem (before threads existed)

Imagine a program as a single worker doing tasks one at a time, in a strict line — task 1, then task 2, then task 3. This is called **single-threaded** execution.

Now imagine a real app, like a chat application:

- It needs to **listen for new messages** coming in
- It needs to **let you type and send** a message
- It needs to **update the screen** (UI)
- It needs to **save data** to disk

If the program does these one at a time, in one line, a problem shows up immediately: if "listen for new messages" takes a long time (waiting on the network), everything else **freezes**. You couldn't type. The screen wouldn't update. The whole app looks stuck.

This is the core problem: **a single line of execution can only do one thing at a time**, so slow tasks block everything else, and you can't use your CPU's full power (modern CPUs have multiple cores that can work simultaneously).

## 2. The Solution: Threads

A **thread** is an independent path of execution inside a program. Think of your program (called a **process**) as a company, and threads as **workers** inside that company. Each worker can do a task at the same time as the others, instead of everyone waiting in a single line.

So instead of one worker doing everything in sequence:

- Worker A (Thread 1): listens for messages
- Worker B (Thread 2): handles your typing
- Worker C (Thread 3): updates the screen

They all work **at the same time** (or take turns very fast), so the app stays responsive.

Key idea: **threads share the same memory/resources of the process** they belong to (like workers sharing the same office and filing cabinet), but each thread has its own **path of execution** (its own to-do list and current step).

Let me show you the difference visually.Each thread has its **own stack** (its own current step, its own local variables) but they all reach into the **same shared memory** — that's the key trait that makes threads different from separate programs.

## 3. Types of Threads

- **Main thread**: every program starts with one thread automatically — the "first worker hired." In Java, this is the thread that runs your `main()` method.
- **Worker threads (user threads)**: extra threads you create yourself to run tasks alongside the main thread.
- **Daemon threads**: background helper threads that don't stop the program from exiting (e.g. a garbage collector thread). If only daemon threads are left running, the program shuts down anyway.
- **OS threads vs Green threads**: OS threads are managed directly by the operating system (heavier, more overhead). Green threads (or "virtual threads" — new in modern Java) are managed by the language runtime itself, and are much lighter, so you can create thousands of them cheaply.

## 4. Threads vs Processes (a common confusion)

||Process|Thread|
|---|---|---|
|What it is|A running program|A worker inside a program|
|Memory|Has its own separate memory|Shares memory with other threads in the same process|
|Cost to create|Expensive (heavy)|Cheap (light)|
|Crash impact|One process crashing doesn't kill another process|A bad thread can corrupt shared memory and crash the whole process|
|Communication|Needs special tools (sockets, pipes) to talk to another process|Can just read/write the same variables directly|

## 5. Why this matters for you (Java)

Since you're learning Java and Spring Boot: every Spring Boot web app is **multi-threaded by default**. When two users hit your API at the same time, Spring Boot typically handles each request on a **separate thread**, so one slow user doesn't block another. This is exactly why understanding threads matters — it explains things you'll soon run into like:

- **Thread safety** — making sure shared data (like a shopping cart total) isn't corrupted when two threads touch it at once
- **`synchronized`** keyword — a way to say "only one thread at a time may enter this section"
- **Thread pools** — a fixed group of reusable worker threads (so you're not creating a brand new thread for every single request, which would be wasteful)




[[Java]] [[Computer science]]