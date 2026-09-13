### Introduction

Suppose you are using two tasks at a time on the computer, be it using Microsoft Word and listening to music. These two tasks are called ****processes**** . So you start typing in Word and at the same time start music app, this is called ****multitasking**** . Now you committed a mistake in a Word and spell check shows exception, this means Word is a process that is broken down into sub-processes. Now if a machine is dual-core then one process or task is been handled by one core and music is been handled by another core.

In Java and computer science, **process** and **multitasking** are fundamental concepts related to how programs and tasks are executed by a computer system. Below, I define each term and provide context specific to Java and computer science:

### **Process**
A **process** is an instance of a program that is being executed by a computer's operating system. It represents a running program, including its code, data, and system resources (e.g., memory, CPU time, and open files). Each process operates in its own isolated memory space, ensuring that processes do not interfere with one another unless explicitly designed to do so (e.g., through inter-process communication).

#### Key Characteristics of a Process:
- **Independent Execution**: Each process has its own address space and execution environment.
- **Components**: A process includes the program code (instructions), data (variables, stack, heap), and a program counter indicating the next instruction to execute.
- **State**: A process can be in various states, such as running, ready, blocked, or terminated.
- **Heavyweight**: Processes are resource-intensive because they require separate memory and system resources.

#### In Java:
In Java, a process typically refers to the execution of a Java Virtual Machine (JVM) instance running a Java program. For example, when you run a Java application using the `java` command, it creates a process. Java provides mechanisms to interact with processes via the `Process` class and `ProcessBuilder` in the `java.lang` package.

**Example**:
```java
ProcessBuilder pb = new ProcessBuilder("notepad.exe");
Process process = pb.start(); // Starts a new process (e.g., opens Notepad)
```

Java applications can also communicate with other processes using input/output streams or inter-process communication mechanisms provided by the operating system.

---

### **Multitasking**
**Multitasking** refers to the ability of an operating system or a program to manage and execute multiple tasks (or processes/threads) concurrently, giving the appearance that they are running simultaneously. In reality, the CPU switches between tasks rapidly (in single-core systems) or executes them in parallel (in multi-core systems).

#### Types of Multitasking:
1. **Preemptive Multitasking**:
   - The operating system allocates time slices (or quanta) to each task and can interrupt (preempt) a task to switch to another.
   - Common in modern operating systems like Windows, Linux, and macOS.
   - Ensures fairness and responsiveness.

2. **Cooperative Multitasking**:
   - Tasks voluntarily yield control to allow others to run.
   - Less common today, as it relies on tasks being well-behaved, which can lead to inefficiencies if a task hogs resources.

#### In Java:
Java supports multitasking primarily through **multithreading**, as Java runs within a single process (the JVM). A **thread** is a lightweight unit of execution within a process, sharing the same memory space as other threads in the same process. Java's threading model allows multiple threads to perform tasks concurrently, enabling multitasking within a Java application.

Key Java classes/interfaces for multithreading:
- `Thread` class
- `Runnable` interface
- `ExecutorService` and the `java.util.concurrent` package for higher-level thread management

**Example of Multitasking in Java (Multithreading)**:
```java
public class MultitaskingExample {
    public static void main(String[] args) {
        Runnable task1 = () -> {
            for (int i = 0; i < 5; i++) {
                System.out.println("Task 1: " + i);
                try { Thread.sleep(100); } catch (InterruptedException e) {}
            }
        };

        Runnable task2 = () -> {
            for (int i = 0; i < 5; i++) {
                System.out.println("Task 2: " + i);
                try { Thread.sleep(100); } catch (InterruptedException e) {}
            }
        };

        Thread thread1 = new Thread(task1);
        Thread thread2 = new Thread(task2);

        thread1.start(); // Start task 1
        thread2.start(); // Start task 2
    }
}
```
**Output** (interleaved due to concurrent execution):
```
Task 1: 0
Task 2: 0
Task 1: 1
Task 2: 1
Task 1: 2
Task 2: 2
...
```

#### Multitasking vs. Multiprocessing:
- **Multitasking**: Multiple tasks (threads or processes) are managed within the same system, often sharing the same CPU or cores.
- **Multiprocessing**: Multiple processes run on separate CPU's or cores, often with no shared memory.

#### Java and Multitasking:
- Java’s threading model leverages the underlying operating system’s multitasking capabilities.
- The JVM schedules threads using the OS’s thread scheduler, which may use preemptive multitasking.
- Java’s `synchronized` keyword and concurrency utilities (e.g., `Lock`, `Semaphore`, `ExecutorService`) help manage shared resources in multithreaded applications.

---

### Summary
- A **process** is a self-contained execution unit with its own memory space, representing a running program.
- **Multitasking** allows multiple tasks to run concurrently, either through processes (multiprocessing) or threads (multithreading in Java).
- In Java, multitasking is primarily achieved through multithreading within a single JVM process, using classes like `Thread` and `Runnable` or the `java.util.concurrent` framework.

If you’d like a deeper dive into specific aspects (e.g., thread synchronization, process management, or performance considerations), let me know!


#### Tags: [[44 - Threads 🧀]]