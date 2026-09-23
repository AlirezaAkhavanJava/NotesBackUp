

A **virtual address space (VAS)** is the range of **memory addresses that an operating system gives to a running process**, which the process can use as if it had its own private memory.

The key idea:

> **A process does not directly see physical RAM. It sees virtual addresses.**

For example, when the JVM runs:

```text
JVM process
     │
     │ uses virtual addresses
     ▼
┌──────────────────────────────┐
│     JVM Virtual Address      │
│          Space               │
│                              │
│  0x00000000                  │
│      ↓                       │
│  Code                        │
│  Heap                        │
│  Native memory               │
│  Thread stacks               │
│  Shared libraries            │
│      ↑                       │
│  0x7FFFFFFFFFFF              │
└──────────────────────────────┘
              │
              │ OS + CPU translate
              ▼
        Physical memory
             RAM
```

### 1. Virtual ≠ physical

Suppose the JVM accesses:

```text
0x00007F1234560000
```

That is a **virtual address**.

It does **not** mean that the RAM chip has a location with that exact address.

The CPU's **MMU (Memory Management Unit)** translates the virtual address into a physical address:

```text
Virtual address
      │
      ▼
     MMU
      │
      ▼
Physical address
      │
      ▼
     RAM
```

The OS controls the mappings.

---

### 2. Why does the OS do this?

Primarily for **isolation, protection, and flexible memory management**.

Imagine three processes:

```text
Process A                  Process B
┌─────────────┐            ┌─────────────┐
│ 0x1000      │            │ 0x1000      │
│             │            │             │
└─────────────┘            └─────────────┘
```

Both processes can use virtual address `0x1000`.

But those addresses can map to completely different physical RAM:

```text
Process A                         Process B
0x1000                            0x1000
  │                                 │
  ▼                                 ▼
Physical 0x5000                  Physical 0xA000
```

So each process gets the illusion that it owns its own memory.

A normal process cannot simply say:

> "Give me the RAM belonging to another process."

The memory-management hardware and OS enforce the separation.

---

### 3. How this relates to your JVM question

When you say:

> "The OS gives the JVM a virtual address space."

More precisely:

```text
                 Operating System
                       │
                       │ creates process
                       ▼
                  JVM Process
                       │
                       ▼
              Virtual Address Space
                       │
          ┌────────────┼─────────────┐
          ▼            ▼             ▼
        Heap        Thread       JVM/native
                    stacks         memory
                       │
                       ▼
              Virtual → Physical
                    translation
                       │
                       ▼
                      RAM
```

The JVM asks the OS for memory, but the JVM primarily operates using **virtual addresses**.

For example, the JVM might reserve a large virtual address range for the Java heap:

```text
Virtual Address Space

┌─────────────────────────────┐
│                             │
│       Java Heap             │
│                             │
│  0x000000...                │
│          ↓                  │
│      objects live here      │
│                             │
└─────────────────────────────┘
```

The OS then establishes mappings between portions of that virtual space and physical memory.

### Important distinction

Don't think:

```text
JVM → directly gets RAM
```

Think:

```text
JVM
 ↓
requests memory from OS
 ↓
OS manages virtual memory
 ↓
virtual addresses mapped to physical memory
 ↓
RAM
```

And this is one of the fundamental reasons a JVM can have a **large heap without requiring all of that memory to be physically resident in RAM at the exact moment the virtual address space is created**.

---

> **Giving a process a virtual address space does not mean giving it an equal amount of physical RAM.**

### Think of it as an address map

Suppose your machine has:

```text
Physical RAM: 16 GB
```

You might have:

```text
Chrome       → large virtual address space
JVM          → large virtual address space
IntelliJ     → large virtual address space
PostgreSQL   → large virtual address space
GNOME        → virtual address space
...
```

It looks like this:

```text
                Virtual Address Spaces

Chrome       ────────────────┐
JVM          ────────────────┤
IntelliJ     ────────────────┤
PostgreSQL   ────────────────┤
GNOME        ────────────────┤
                             │
                             ▼
                    OS / Memory Manager
                             │
                             ▼
                       16 GB Physical RAM
```

The virtual address spaces can be **much larger than physical RAM**.

---

## 1. Virtual memory is not automatically physical memory

Suppose the JVM has:

```text
Virtual address:
0x0000001000000000
```

The JVM can have that address available, but there doesn't necessarily need to be a RAM page behind it yet.

You can conceptually have:

```text
Virtual address space

0x1000 ────────┐
0x2000         │
0x3000         │
0x4000         │
               │
               │       No physical RAM currently mapped
               │
0x9000 ────────┘
```

The OS can say:

> "This virtual address range belongs to this process, but I haven't assigned physical memory to all of it."

This is one reason **reserving virtual address space** and **committing/using physical memory** are different concepts.

---

## 2. Physical RAM is allocated when memory is actually needed

Suppose your Java program creates:

```java
byte[] data = new byte[1024 * 1024 * 1024];
```

The JVM needs roughly **1 GB** of memory for that object.

As the memory is actually touched, the OS establishes mappings to physical pages.

Conceptually:

```text
Virtual memory
┌───────────────┐
│ JVM heap      │
│               │
│  Page 1 ──────┼──────► RAM page
│  Page 2 ──────┼──────► RAM page
│  Page 3 ──────┼──────► RAM page
│  Page 4 ──────┼──────► RAM page
│      ...      │
└───────────────┘
```

Memory is managed in **pages**, commonly 4 KiB on many systems.

So the OS doesn't normally manage every byte independently.

---

## 3. What happens when RAM becomes full?

This is the really important part.

Suppose:

```text
RAM = 16 GB
```

and your active processes need more than 16 GB of memory.

Linux can use **swap**.

For example:

```text
                 Virtual Memory
                       │
             ┌─────────┴─────────┐
             ▼                   ▼
            RAM                Swap
           16 GB                disk
             │                   │
       frequently used      less active pages
          pages
```

The kernel can move relatively inactive memory pages from RAM to swap:

```text
RAM
┌──────────────┐
│ Page A       │
│ Page B       │
│ Page C       │
│ Page D       │
│ ...          │
└──────────────┘
       │
       │ move inactive page
       ▼
    Swap space
┌──────────────┐
│ Page X       │
│ Page Y       │
└──────────────┘
```

Then RAM can be reused for something currently active.

If the process later accesses that swapped-out page:

```text
Process
   │
   ▼
Virtual address
   │
   ▼
Page isn't in RAM
   │
   ▼
Page fault
   │
   ▼
Kernel loads page from swap
   │
   ▼
RAM
```

This is called a **page fault**.

---

## 4. But we can still run out of memory

Virtual memory isn't infinite magic.

You can eventually reach a situation where the system cannot satisfy memory demands.

For example:

```text
Processes want:

JVM          8 GB
Chrome       6 GB
IntelliJ     5 GB
PostgreSQL   3 GB
GNOME        2 GB
Other        3 GB
------------------
Total       27 GB
```

But suppose:

```text
RAM  = 16 GB
Swap =  4 GB
```

The system has roughly **20 GB of physical backing available**, depending on configuration and other details.

If processes genuinely require more than the system can back, Linux can no longer satisfy allocations.

Eventually you can get:

```text
Out of Memory
```

and Linux's **OOM killer** may terminate processes to recover memory.

---

# The mental model

This is the model I recommend keeping in your head:

```text
             PROCESS
                │
                │ uses
                ▼
       Virtual Address Space
                │
                │ virtual pages
                ▼
          ┌───────────┐
          │    MMU    │
          └─────┬─────┘
                │
         ┌──────┴──────┐
         ▼             ▼
       RAM            Swap
    fast storage    disk storage
```

And the most important distinction is:

```text
Virtual address space
        ≠
Physical memory
```

You can have **many processes with huge virtual address spaces** because those address spaces are largely just **address ranges and mappings**.

What actually limits the system is the amount of memory that needs **physical backing**—RAM, and potentially swap/backing storage—not simply the size of every process's virtual address space added together.


[[Java]]
[[Computer]]