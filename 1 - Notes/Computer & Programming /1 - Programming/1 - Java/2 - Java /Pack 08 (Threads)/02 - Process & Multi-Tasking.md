

You listen to music while typing in Word, and it feels like the computer is doing both at the same instant. This tutorial explains how that's pulled off, what "at the same time" actually means (there are two different meanings, and mixing them up causes real confusion), and what tools Java gives you to do the same thing in your own programs.

We'll go from the problem, to the OS's solution, to the vocabulary people mix up, and then to the two ways Java lets you run things at once.

---

## The problem: a core runs one thing at a time

A CPU core executes one stream of instructions at a time. Yet your machine has a browser, an IDE, a database and a music player all alive at once, and often far more threads than cores. Something has to share the hardware between them. That something is the operating system, and the technique is called **multitasking**: managing many tasks so they all make progress.

## Concurrency vs. parallelism

These two words describe different things, and the rest of the tutorial depends on telling them apart.

- **Concurrency** means several tasks are _in progress_ during the same period. They don't have to be executing at the same instant.
- **Parallelism** means several tasks are _executing at the same instant_, on different cores.

On a single core you can only get concurrency. The OS runs task A for a few milliseconds, pauses it, runs task B for a few milliseconds, pauses it, and keeps rotating. It switches so fast that you perceive both as running continuously, the way a movie is many still frames.

On a multi-core machine you get both. Two tasks can truly run at once on two cores, and if you have more tasks than cores, the OS still rotates them within each core.

This tells you something practical. Concurrency is a way of _structuring_ your program so tasks can overlap (one waits on a network reply while another computes). Parallelism is a way of _getting speed_ from extra cores. You can have concurrency with no speedup at all, and you can check how much real parallelism your machine offers:

```java
System.out.println(Runtime.getRuntime().availableProcessors());
```

## Who decides when to switch: preemptive vs. cooperative

There are two ways to share the CPU.

**Preemptive multitasking.** The OS owns a hardware timer. When a task's time slice runs out, the OS forcibly interrupts it and switches to another, whether the task likes it or not. Windows, Linux and macOS all work this way. The benefit is that no task can hog the machine, and a task stuck in an infinite loop can't freeze everything else.

**Cooperative multitasking.** A task keeps the CPU until it voluntarily gives it up. Old operating systems worked this way. One badly behaved program that never yielded would freeze the whole system.

Java's ordinary threads (called platform threads) are preemptive, because each one is backed by an OS thread. Virtual threads work differently: the JVM only moves them off a carrier thread when they block (on I/O or a lock, for example), not on a timer, so they are closer to the cooperative idea. That is fine for them because they're designed for tasks that wait a lot.

## Two levels of multitasking

Multitasking happens at two levels, and this is where the Word example from the start becomes useful.

**Between programs.** Word and the music player are two separate processes. The OS multitasks between them. They are isolated, so a crash in the music player doesn't touch your document.

**Inside one program.** Word itself does several things at once: it accepts your keystrokes, checks spelling in the background, and autosaves. Those are not separate programs. They are separate **threads** inside the one Word process, which is why spell-check can work on the same document you're typing into. Java programs work the same way.

The vocabulary people mix up:

|Term|What it means|
|---|---|
|Multitasking|The OS (or a program) juggling many tasks. The general idea.|
|Multithreading|Multitasking with several threads inside one process.|
|Multiprocessing|Using more than one processor/core, or several cooperating processes, so work happens in parallel.|

They aren't competing concepts. Multithreading is one way of getting multitasking, and multiprocessing describes the hardware or process-level parallelism it may run on.

---

## In Java: two ways to run things at once

### 1. Start another process

Sometimes the work you want is another program: calling `git`, running a converter, launching a script. `ProcessBuilder` starts it as a separate process with its own memory:

```java
Process p = new ProcessBuilder("java", "-version")
        .redirectErrorStream(true)      // merge the child's stderr into its stdout
        .start();

String output = new String(p.getInputStream().readAllBytes());
int exitCode = p.waitFor();             // wait for it to finish

System.out.println(output);
System.out.println("exit code: " + exitCode);
```

Points that matter when you use this:

- `getInputStream()` is the child's _output_, viewed from your side. It reads what the child prints.
- Each argument is passed as its own string, with no shell involved. That keeps you safe from shell-injection tricks like `"; rm -rf /"` hiding inside a filename.
- **Always read the child's output** (or redirect it to a file). If you don't, the pipe's buffer can fill up, the child blocks forever trying to write, and your `waitFor()` hangs.
- A non-zero exit code conventionally means failure, so check it.

This is heavyweight, and it's the right tool only when you genuinely need another program.

### 2. Start threads inside your own program

For concurrency inside your own code, you use threads. A thread needs a task, and in Java a task is a `Runnable`, a function with no arguments and no return value, so a lambda works:

```java
public class Multitasking {
    public static void main(String[] args) throws InterruptedException {
        Runnable counter = () -> {
            String name = Thread.currentThread().getName();
            for (int i = 1; i <= 3; i++) {
                System.out.println(name + ": " + i);
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();   // keep the "stop" request alive
                    return;
                }
            }
        };

        Thread a = new Thread(counter, "Task-A");
        Thread b = new Thread(counter, "Task-B");
        a.start();
        b.start();
        a.join();   // main waits for A to finish
        b.join();   // ...and for B
        System.out.println("Both finished");
    }
}
```

What's going on:

- `start()` creates a real new thread, which then calls the task. If you called `counter.run()` instead, no thread would be created and Task-A would run completely, then Task-B, one after the other on the main thread. Calling `run()` directly compiles fine and silently gives you no concurrency.
- `join()` makes the caller wait until that thread has finished. Without it, `main` would print "Both finished" immediately.
- `Thread.sleep` pauses the thread and hands the CPU to others. That's why the output tends to alternate (`A:1, B:1, A:2, B:2...`). Remove the sleep and a short loop often finishes in one go before the other thread even starts, because starting a thread takes a moment.
- **The order is not guaranteed.** You may see `B:1` before `A:1`, and it can differ between runs. The OS scheduler decides, and your code can't rely on any particular interleaving.
- The `catch` block restores the thread's interrupt flag and exits instead of ignoring the exception. An empty catch would swallow a request to stop this thread.

All threads in that program live in one JVM process and share its heap. That sharing is the source of the classic concurrency bugs (two threads changing the same data), which is the subject of the threads material on its own.

---

## How to choose

If you need another program's work done, use a process (`ProcessBuilder`). If you need several things to progress inside your own application, which is almost always what a back-end developer needs, use threads, and in real code you'll manage them through `java.util.concurrent` (thread pools) rather than creating raw `Thread` objects one by one.





[[Threads]]