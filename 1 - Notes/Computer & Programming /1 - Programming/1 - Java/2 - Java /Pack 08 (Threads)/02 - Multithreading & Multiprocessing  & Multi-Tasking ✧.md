
Multitasking is how your computer runs a browser, an IDE, and a music player at once, even though each CPU core executes only one stream of instructions at a time. The OS rotates tasks on each core, and on a multi-core machine it can also run tasks truly side by side. Java gives you two tools for this: a separate process (`ProcessBuilder`) for running another program, and threads (`Thread` with a `Runnable`) for concurrency inside your own program.

## Concurrency vs. parallelism

- **Concurrency:** several tasks are in progress during the same period. They don't have to run at the same instant. On one core, the OS switches between them so fast that both appear to run.
- **Parallelism:** several tasks run at the same instant on different cores.

Concurrency is about how you structure a program, such as letting one thread wait on a network reply while another computes. Parallelism is about using extra cores for speed. You can check your core count with `Runtime.getRuntime().availableProcessors()`.

## How the CPU gets shared

- **Preemptive:** a hardware timer lets the OS interrupt a task when its time slice ends. Windows, Linux, and macOS work this way, so one task can't freeze the machine. Java platform threads are preemptive because each maps to an OS thread.
- **Cooperative:** a task keeps the CPU until it yields voluntarily. One badly behaved task can freeze everything. Virtual threads behave closer to this model: the JVM moves them off a carrier thread only when they block on I/O or a lock. That suits tasks that spend most of their time waiting.

## Multitasking at two levels

Word and your music player are separate processes, so the OS multitasks between them, and a crash in one doesn't touch the other. Inside Word, the keystroke handling, spell-check, and autosave run as separate threads in one process. That's why spell-check can work on the document you're typing into.

|Term|Meaning|
|---|---|
|Multitasking|Juggling many tasks. The general idea.|
|Multithreading|Multitasking with several threads inside one process.|
|Multiprocessing|Work spread across several processors or processes.|

These aren't rivals. Multithreading is one way to multitask, and multiprocessing describes the hardware or process-level parallelism it may run on.

## Option 1: start another process

Use `ProcessBuilder` when you need another program's work, such as running `git` or a converter:

```java
Process p = new ProcessBuilder("java", "-version")
        .redirectErrorStream(true)   // merge the child's error output into its normal output
        .start();

String output = new String(p.getInputStream().readAllBytes());
int exitCode = p.waitFor();          // wait for the child to finish

System.out.println(output);
System.out.println("exit code: " + exitCode);
```

This program starts `java -version` as a separate process with its own memory and reads what it prints. `getInputStream()` gives you the child's output, since you're reading from its side. Each argument is passed as its own string with no shell involved, which protects you from shell-injection tricks hidden in filenames. A non-zero exit code conventionally means failure, so check it.

**Always read the child's output** (or redirect it to a file). If you don't, the pipe buffer can fill, the child blocks while writing, and `waitFor()` hangs forever.

## Option 2: run threads in your own program

A thread needs a task. In Java, a task is a `Runnable`, which has a single method, `void run()`, that takes no arguments and returns nothing. A lambda is the simplest way to write one:

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
                    Thread.currentThread().interrupt(); // keep the stop request alive
                    return;
                }
            }
        };

        Thread a = new Thread(counter, "Task-A");
        Thread b = new Thread(counter, "Task-B");
        a.start();
        b.start();
        a.join();   // main waits for A to finish
        b.join();   // then for B
        System.out.println("Both finished");
    }
}
```

What each part does:

- **`new Thread(counter, "Task-A")`** wraps the task in a thread and names it, so the output shows which thread printed each line.
- **`start()`** creates a real new thread that runs the task. Calling `counter.run()` instead would run the loop on the main thread, one task after another, with no concurrency. It compiles fine, which makes the mistake easy to miss.
- **`Thread.sleep(100)`** pauses the thread and gives the CPU to others. That's why the output often alternates: `A:1, B:1, A:2, B:2`.
- **`join()`** makes the caller wait for that thread to finish. Without it, "Both finished" would print immediately.
- **The catch block** restores the interrupt flag and exits. An empty catch would swallow a request to stop the thread.
- **The order isn't guaranteed.** `B:1` may print before `A:1`, and the order can change between runs. The OS scheduler decides, and your code can't depend on a particular interleaving.

Both threads live in one JVM process and share its heap. That sharing is the source of classic concurrency bugs, such as two threads updating the same variable, which is covered in the threads lesson.

## Choosing between them

Use a process when you need another program's work. Use threads when several things must progress inside your own application, which is the usual case for back-end work. In real code, manage threads through `java.util.concurrent` thread pools rather than creating raw `Thread` objects one at a time.



[[Threads]]