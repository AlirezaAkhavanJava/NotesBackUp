# Computer Science Notes

This note provides an overview of key concepts in Computer Science based on your query. I've structured it into sections for clarity, covering definitions, explanations, and related details. Where applicable, I've included historical context, algorithms, and operational mechanics.

## Definition of Computer Science
Computer Science (CS) is the scientific and practical study of computation, algorithms, data processing, and the design of computer systems. It encompasses both theoretical foundations (e.g., computability, complexity theory) and applied aspects (e.g., software engineering, hardware design). CS focuses on solving problems efficiently using computers, including topics like artificial intelligence, databases, networking, and human-computer interaction. It originated in the mid-20th century, evolving from mathematics and electrical engineering, with pioneers like Alan Turing (Turing machines, 1936) and John von Neumann (stored-program architecture, 1945). Unlike information technology, CS emphasizes algorithmic thinking and abstraction rather than just tool usage.

## How the CPU Works
The Central Processing Unit (CPU) is the core hardware component that executes instructions from computer programs. It processes data and controls other parts of the system.

### Basic Components
- **Control Unit (CU)**: Directs operations by fetching instructions and coordinating data flow.
- **Arithmetic Logic Unit (ALU)**: Performs arithmetic (e.g., addition, subtraction) and logical operations (e.g., AND, OR).
- **Registers**: Small, fast storage locations inside the CPU for temporary data (e.g., program counter, accumulator).
- **Cache**: On-chip memory for quick access to frequently used data.

### Fetch-Decode-Execute Cycle (Instruction Cycle)
The CPU operates in a continuous loop:
1. **Fetch**: Retrieve the next instruction from main memory (RAM) using the program counter.
2. **Decode**: Interpret the instruction to determine the operation and operands.
3. **Execute**: Perform the action (e.g., ALU computation, memory read/write).
4. **Store/Repeat**: Write results back to registers or memory, then increment the program counter.

Modern CPUs use pipelining (overlapping stages for parallelism), superscalar execution (multiple instructions per cycle), and multi-core designs for efficiency. Clock speed (e.g., GHz) measures cycles per second, but performance also depends on architecture (e.g., x86, ARM).

### History
CPUs evolved from vacuum tubes in the 1940s (e.g., ENIAC) to transistors in the 1950s, integrated circuits in the 1960s (Intel 4004, first microprocessor in 1971), and today's nanoscale chips with billions of transistors (Moore's Law, proposed 1965).

## Operating System (OS)
An Operating System is system software that acts as an intermediary between users/applications and hardware. It manages resources to ensure efficient, secure computing.

### Key Functions
- **Process Management**: Creating, scheduling, and terminating processes (running programs).
- **Memory Management**: Allocating/deallocating memory, handling virtual memory.
- **File System Management**: Organizing files on storage devices.
- **Device Management**: Controlling peripherals via drivers (e.g., printers, keyboards).
- **Security and User Interface**: Access control, authentication, and shells/GUIs.

### Types
- Batch OS (e.g., early IBM systems): Processes jobs sequentially.
- Time-Sharing OS (e.g., Unix, 1969): Allows multiple users to interact concurrently.
- Real-Time OS (e.g., VxWorks): Guarantees timely responses for critical systems.
- Examples: Windows (Microsoft), Linux (open-source, kernel by Linus Torvalds, 1991), macOS (Apple, based on Unix).

### History
OS concepts began in the 1950s with GM-NAA I/O (first OS, 1956). Multiprogramming emerged in the 1960s (e.g., Multics). Modern OSes emphasize multitasking and portability.

## Memory
Memory refers to storage components that hold data and instructions for quick access by the CPU.

### Memory Hierarchy
Organized by speed, cost, and capacity (faster = smaller/expensive):
- **Registers**: Fastest, inside CPU (e.g., 32-64 bits per register).
- **Cache (L1/L2/L3)**: SRAM on/near CPU (e.g., 1-64 MB), reduces RAM access time.
- **Main Memory (RAM)**: Volatile DRAM (e.g., 8-128 GB), holds running programs.
- **Secondary Storage**: Non-volatile (e.g., SSDs with NAND flash, HDDs with magnetic disks; terabytes capacity).
- **Tertiary Storage**: Archival (e.g., tapes).

### Types and Management
- **Volatile vs. Non-Volatile**: RAM loses data on power-off; ROM/Flash retains it.
- **Virtual Memory**: Uses disk as extension of RAM via paging/swapping (introduced in Atlas system, 1962). Pages (fixed-size blocks) are swapped to handle larger programs.
- **Addressing**: Physical (hardware) vs. Virtual (OS-managed for isolation).

Issues: Fragmentation (wasted space), Thrashing (excessive swapping).

## Concurrency
Concurrency involves executing multiple tasks seemingly simultaneously, improving efficiency in multi-user/multi-task systems.

### Key Concepts
- **Processes vs. Threads**: Processes are independent with own memory; threads share memory within a process (lighter-weight).
- **Parallelism**: True simultaneous execution (e.g., multi-core CPUs) vs. Concurrency (interleaved on single core).
- **Issues**:
  - Race Conditions: Unpredictable outcomes from unsynchronized access.
  - Deadlocks: Processes waiting cyclically for resources.
  - Starvation: Low-priority tasks never running.
  - Livelock: Processes busy responding but no progress.

### Algorithms and Synchronization
- **Primitives**:
  - Locks/Mutexes: Ensure mutual exclusion (e.g., spinlocks, sleep locks).
  - Semaphores: Counters for resource control (binary for mutex, counting for limited resources).
  - Monitors: High-level constructs with condition variables (e.g., in Java).
  - Barriers: Synchronize threads at a point.
- **Algorithms**:
  - Peterson's Algorithm: Software mutual exclusion for two processes.
  - Dekker's Algorithm: Early solution for critical sections.
  - Dining Philosophers: Classic deadlock example/solution using resource hierarchy.
  - Reader-Writer Problem: Prioritizes readers or writers with semaphores.
- **Models**: Actor Model (e.g., Erlang), CSP (Communicating Sequential Processes by Hoare), Async/Await in languages like Python/JavaScript.

### History
- 1960s: Emergence with multiprogramming. Dijkstra introduced semaphores (1965) and THE multiprogramming system (1968). Per Brinch Hansen developed monitors (1970s).
- 1970s: Hoare's CSP (1978); Unix popularized threads.
- 1980s-1990s: Pthreads standard (1995); Java threads (1995).
- 2000s+: Rise of multi-core (Intel Core Duo, 2006), leading to frameworks like OpenMP, MPI for parallelism. Modern focus on concurrent programming in languages like Go (channels, 2009) and Rust (ownership for safety).

## Dispatcher, Process Queue, and Related Concepts
These are part of OS process scheduling, managing how processes share CPU time.

### Dispatcher
The Dispatcher (or Short-Term Scheduler) is the OS module that selects the next process from the ready queue and allocates the CPU to it. It performs context switching: saving the state of the current process (registers, program counter) and loading the new one's state. This happens frequently (e.g., every 10-100 ms in time-sharing systems) and must be fast to minimize overhead.

### Process Queues
- **Ready Queue**: Holds processes loaded in memory and ready to execute (e.g., FIFO or priority-based).
- **Job Queue**: All processes in the system (long-term scheduling).
- **Waiting/IO Queue**: Processes blocked for IO, events, or resources.
- **Device Queues**: Per-device waiting lists.

Queues are often implemented as linked lists or priority heaps for efficiency.

### Scheduling Algorithms
- **Non-Preemptive**: Process runs to completion (e.g., First-Come-First-Served - FCFS: Simple but convoy effect).
- **Preemptive**: Can interrupt processes (e.g., Round-Robin: Time slices/quantum, fair but high context switches).
- **Others**:
  - Shortest Job First (SJF): Minimizes wait time but needs burst time prediction.
  - Priority Scheduling: Higher priority first; can cause starvation (solved by aging).
  - Multilevel Queue: Separate queues for foreground/background.
  - Multilevel Feedback Queue: Adaptive, promotes/demotes based on behavior.

### Related Concepts
- **Scheduler Types**: Long-Term (admits jobs to ready queue), Medium-Term (swapping for memory management).
- **Context Switch Overhead**: Includes saving PCB (Process Control Block: PID, state, memory info).
- **Multitasking**: Enabled by these mechanisms, crucial for modern OSes.

This framework ensures fair resource allocation, responsiveness, and throughput. For deeper dives, refer to OS textbooks like "Operating System Concepts" by Silberschatz.


[[Computer & Programming & Networking & CyberSecurity]]