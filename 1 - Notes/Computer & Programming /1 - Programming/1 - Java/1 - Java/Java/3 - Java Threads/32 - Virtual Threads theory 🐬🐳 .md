Date : 2025-09-13


---

# Mastering Java Virtual Threads: From Basics to Deep Mechanics

Java’s **virtual threads** are a revolutionary way to handle concurrency, allowing massive scalability for I/O-heavy applications. This guide teaches everything step by step.

---

## **1. Understanding Threads**

### **Platform Threads**

- Classic OS-backed threads.
    
- Each has a fixed native stack (~1 MB).
    
- Expensive to create, limited scalability.
    
- OS handles scheduling and context switching.
    

### **Virtual Threads**

- Managed by the JVM.
    
- Stack lives on heap, grows/shrinks dynamically.
    
- Millions can exist concurrently.
    
- JVM handles scheduling in **user mode**, not the OS.
    

**Key takeaway:** Virtual threads are **lightweight, heap-based threads**, ideal for tasks that block frequently.

---

## **2. CPU-bound vs I/O-bound Tasks**

### **CPU-bound Tasks**

- Bottleneck: CPU computation.
    
- Examples: Rendering, simulations, calculations.
    
- Performance limited by number of CPU cores.
    
- Virtual threads don’t improve CPU-bound work; they only allow many tasks to exist.
    

### **I/O-bound Tasks**

- Bottleneck: External resources (DB, network, file).
    
- Examples: HTTP requests, database queries.
    
- Virtual threads **excel** because blocking doesn’t tie up carriers.
    

**Rule of thumb:** Use virtual threads for I/O-heavy workloads. Use platform threads for CPU-heavy workloads.

---

## **3. Introducing Carriers**

- **Carrier thread:** A real OS thread that executes virtual threads.
    
- Virtual threads **borrow a carrier stack** while running.
    
- Only actively running threads occupy carriers; blocked threads free the carrier.
    

**Analogy:** Carriers = chairs, virtual threads = people. Sitting = running; standing = blocked.

---

## **4. Carrier Pool**

- Virtual threads themselves **aren’t pooled**.
    
- The **pool exists at the carrier level**: a small set of OS threads that execute virtual threads.
    
- Millions of virtual threads can exist; only as many as there are carriers can run simultaneously.
    

### **How It Works**

1. Virtual thread created → small heap footprint.
    
2. Virtual thread started → JVM assigns a **carrier from the pool** (mounting).
    
3. Virtual thread blocks → stack saved to heap, carrier freed.
    
4. Virtual thread resumes → any available carrier executes it (remounting).
    

**Key points:**

- Pool is **small and fixed**, usually tied to number of cores + hyperthreading.
    
- Carriers schedule virtual threads dynamically; no fixed queue bottleneck.
    

**Analogy 🐐:** Carrier pool = checkout counters; virtual threads = customers. Millions can wait; only a few counters active. When one customer pauses (I/O), counter serves another.

---

## **5. Mounting and Unmounting**

### **Mechanics**

1. **Mounting:** Virtual thread assigned to a carrier; stack frames copied to carrier stack; thread executes.
    
2. **Blocking (Unmounting):** Thread hits I/O, sleep, or lock → stack snapshot saved to heap → carrier freed.
    
3. **Remounting:** Operation completes → snapshot restored on a carrier; thread resumes.
    

### **Why It Matters**

- Allows millions of threads to exist without using millions of OS stacks.
    
- Makes blocking extremely cheap.
    

---

## **6. Stack Snapshots**

- Stack frames, local variables, program counter = **saved in heap** when a virtual thread blocks.
    
- Heap-based stacks are **dynamic** → grow/shrink as needed.
    
- Once the thread finishes, heap snapshot is garbage collected.
    

**Analogy 🐐:** Stack snapshot = backpack; person (thread) can leave chair (carrier) while waiting, then sit on any chair later.

---

## **7. Garbage Collection and Memory Management**

- Virtual thread stacks = heap objects → fully managed by GC.
    
- Carrier stacks are temporary and freed immediately when a thread blocks.
    
- Result: massively lower memory usage than platform threads.
    

⚠️ Caveat: Millions of active threads → heap pressure, GC considerations.

---

## **8. Thread Switching**

### **Platform Threads**

- OS switches context: save CPU registers, stack pointer, program counter.
    
- Expensive, involves kernel mode.
    

### **Virtual Threads**

- JVM handles switching in user mode.
    
- Mount/unmount + stack snapshots = **low-cost context switches**.
    
- Only actively running threads occupy carriers.
    

---

## **9. Cores, Virtual Cores, and Scaling**

- **Physical cores:** Real CPU cores.
    
- **Virtual cores / Hyperthreading:** Logical cores that share execution units.
    
- **Carrier threads:** One per (physical or virtual) core can execute a virtual thread simultaneously.
    

**Effect:** More cores → more carriers → more virtual threads actively running.

**Analogy:** Ovens = cores, mini-ovens = virtual cores, bakers = carriers, millions of bakers lining up = virtual threads.

---

## **10. Real-World Web Application Example**

- Multi-core, hyperthreaded servers → more carriers → more requests handled simultaneously.
    
- Virtual threads allow **one thread per request** without exhausting OS threads.
    
- Perfect for I/O-heavy workloads: APIs, microservices, database-backed apps.
    
- CPU-heavy work still limited by core count; virtual threads do not increase raw computation speed.
    

---

## **11. Bottom Line**

Virtual threads combine **blocking-style programming** with **massive scalability**:

- Stack snapshots + mount/unmount → cheap, efficient concurrency.
    
- Carrier pool ensures CPU usage is efficient and limited.
    
- Millions of tasks without memory blowup.
    
- Block safely without wasting OS threads.
    
- Scale perfectly on modern multi-core servers for I/O-heavy workloads.
    

**Caveats:**

- Shared mutable state still requires synchronization.
    
- CPU-heavy tasks are limited by cores.
    
- Heap memory still constrains total virtual threads.
    

---

In Java (from **Java 19+ preview, officially in Java 21**), **virtual threads** are lightweight threads managed by the JVM rather than the OS. They allow massive concurrency with minimal overhead. Here are the main ways to create them:

---

### 1. **Using `Thread.ofVirtual().start()`**

```java
Thread vThread = Thread.ofVirtual().start(() -> {
    System.out.println("Running in virtual thread");
});
```

- Simple, single virtual thread.
    
- `start()` immediately starts it.
    
- No blocking of OS threads.
### **Thread may finish before main exits**

In your case, the main thread will wait for the virtual thread to finish because `start()` starts the thread immediately. But if you launch multiple virtual threads or do async tasks, you may want to **join** them:

```java
Thread vThread = Thread.ofVirtual().start(() -> {
    for (int i = 0; i < 10; i++) {
        System.out.println("Thread : " + Thread.currentThread().getName());
    }
});

vThread.join(); // wait for the virtual thread to finish

```
    

---

### 2. **Using `Thread.ofVirtual().unstarted()`**

```java
Thread vThread = Thread.ofVirtual().unstarted(() -> {
    System.out.println("Running later");
});
vThread.start(); // start when you want
```

- Creates a virtual thread but **doesn’t start it immediately**.
    
- Useful if you want to prepare threads before running.
    

---

### 3. **Using `Executors.newVirtualThreadPerTaskExecutor()`**

```java
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    executor.submit(() -> {
        System.out.println("Task running in virtual thread");
    });
}
```

- Creates a **thread-per-task executor**.
    
- Each submitted task runs in its own virtual thread.
    
- Automatically shuts down and manages threads efficiently.
    

---

### 4. **Using `Executors.newThreadPerTaskExecutor(ThreadFactory)`**

```java
var executor = Executors.newThreadPerTaskExecutor(Thread.ofVirtual().factory());
executor.submit(() -> System.out.println("Virtual thread task"));
```

- Flexible if you want **custom thread factories** or more control.
    
- Similar to `newVirtualThreadPerTaskExecutor()` but more configurable.
    

---

### Notes:

- **Virtual threads are not a replacement for all threads**; they are ideal for **blocking tasks like I/O**.
    
- They reduce overhead of thousands of concurrent tasks compared to platform threads.
    

---






##### Course : [YouTube](https://www.youtube.com/watch?v=1HSdq9zvym4&t=2104s)
##### *Tags : [[44 - Threads 🧀]]