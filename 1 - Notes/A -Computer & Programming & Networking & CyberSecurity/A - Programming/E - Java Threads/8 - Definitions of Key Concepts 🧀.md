
### **Multi-Tasking**:
  - This is the broadest term, referring to the OS's ability to handle multiple tasks (which could be processes or threads) concurrently or in parallel, giving the illusion that everything is running at once.
  - It encompasses both running multiple applications (e.g., Microsoft Word and a music app) and handling subtasks within one app (e.g., typing and spell-checking in Word).
  - **Key Idea**: The OS uses a scheduler to decide which task runs next, allocating CPU time. On a single-core CPU, it's concurrency via rapid switching (time-slicing). On a multi-core CPU (e.g., dual-core), it can include parallelism, where tasks run on different cores at the same time.

### **Multi-Threading**:
  - This focuses on a single process (e.g., one app like Microsoft Word) running multiple threads (subtasks) concurrently or in parallel within that process.
  - Threads share the process's resources (e.g., memory), making it efficient for related tasks.
  - **Key Idea**: It's a way for one app to do multiple things "at once," like a web browser loading a page in one thread while rendering the UI in another.

### **Multi-Processing**:
  - This involves running multiple independent processes (e.g., separate apps like Word and a music player) concurrently or in parallel.
  - Each process has its own memory space and resources, so they don't share data easily (unlike threads).
  - **Key Idea**: It's for executing entirely separate programs, often used for heavy workloads or isolation (e.g., one process per app to prevent crashes from affecting others).

---
### How OS and CPU Work Together in the Workflow
The OS and CPU collaborate to manage these concepts through a workflow involving scheduling, execution, and resource allocation. The OS acts as the "manager," while the CPU is the "worker" executing instructions. Here's a step-by-step breakdown:

1. **Task Creation**:
   - When you launch apps or create subtasks:
     - Each app becomes a **process** (multi-processing level).
     - Within a process, an app can create **threads** (multi-threading level).
     - The OS tracks all processes and threads in a queue, assigning priorities and states (e.g., ready, running, blocked).

2. **Scheduling by the OS**:
   - The OS has a **scheduler** (part of the kernel) that decides which process or thread gets CPU time next. This is the core of multi-tasking.
     - It uses algorithms like round-robin (fair time slices) or priority-based scheduling.
     - For **multi-tasking**: The scheduler handles both processes (e.g., switching between Word and music app) and threads within processes (e.g., switching between typing and spell-check threads in Word).
     - Preemptive scheduling (common in modern OS like Windows/Linux) allows the OS to interrupt a running task after a time slice (e.g., 10-100ms) to switch to another, enabling concurrency.
   - On a **single-core CPU**: Everything is concurrent—tasks are interleaved via context switching (saving one task's state and loading another's). No true parallelism.
   - On a **multi-core CPU** (e.g., dual-core): The scheduler can assign tasks to different cores for parallelism. For example:
     - One core runs Word's typing thread.
     - Another core runs the music app's playback thread.
     - This allows true simultaneous execution, but the OS still manages switching if there are more tasks than cores.

3. **Execution by the CPU**:
   - Once scheduled, the CPU executes the thread's instructions (e.g., fetching data, performing calculations).
     - **In Multi-Threading (One Process)**: Threads from the same process can run concurrently (time-sliced on single-core) or in parallel (on different cores if the OS schedules them that way). For example, in Word:
       - Typing thread: Processes keystrokes.
       - Spell-check thread: Scans text in the background.
       - On single-core: The CPU switches rapidly between them (concurrency).
       - On dual-core: The OS might put typing on Core 1 and spell-check on Core 2 (parallelism within the process).
     - **In Multi-Processing (Multiple Apps)**: Processes run independently. For example:
       - Word process on Core 1.
       - Music app process on Core 2.
       - This is parallelism for multiple apps, but each app might also have its own multi-threading (concurrency or parallelism within).
   - The CPU handles low-level details like caching data or pipelining instructions, but the OS controls the big picture.

4. **Context Switching and Overhead**:
   - When switching tasks, the OS saves the current thread/process state (e.g., registers, program counter) and loads the next one's. This happens in multi-tasking, multi-threading, and multi-processing.
   - It's fast but has some overhead, so too much switching can slow things down.

5. **Resource Management**:
   - **Shared in Multi-Threading**: Threads in one process share memory/heap, but each has a private stack. The OS ensures safe access (e.g., via locks to prevent conflicts).
   - **Isolated in Multi-Processing**: Processes don't share memory directly; they communicate via OS mechanisms (e.g., pipes or shared files).
   - The OS allocates CPU cores, memory, and I/O dynamically based on load.

---
### Parallelism vs. Concurrency in This Context
- **Concurrency**: Tasks overlap in time but don't run at the exact same instant. Achieved via time-slicing on a single-core CPU. This is the default for multi-tasking, multi-threading, and multi-processing when cores are limited.
  - Example: On single-core, Word and music app switch rapidly (multi-tasking/multi-processing). Within Word, typing and spell-check switch (multi-threading).
- **Parallelism**: Tasks run at the exact same time on different cores. Requires multi-core hardware and OS support.
  - Example: On dual-core, Word runs fully on Core 1 (with its threads possibly parallelized), and music app on Core 2 (multi-processing parallelism). Within Word, threads can also parallelize across cores if the OS allows.
- **In Summary for Your Question**: 
  - For **multiple apps together** (multi-processing/multi-tasking): It can be parallel (different apps on different cores) or concurrent (switching on single-core).
  - For **within each app** (multi-threading): It can also be parallel (threads on different cores) or concurrent (switching), depending on the CPU and OS scheduling.
  - Overall, multi-tasking is the umbrella: It's concurrent by default, with parallelism added when multi-core hardware is available.
---
### Example Workflow in Your Scenario (Word and Music App on Dual-Core)
- **OS Scheduler**: Sees Word process (with threads: typing, spell-check) and music process (with threads: playback, UI).
- **Assignment**: Puts Word's typing thread on Core 1, spell-check on Core 2 (parallel multi-threading in Word). Music playback on Core 1 after a switch (concurrent with Word).
- **CPU Execution**: Core 1 runs typing, then switches to music; Core 2 runs spell-check uninterrupted if possible.
- **Result**: Feels like everything runs "together" due to multi-tasking.

In Java, this workflow is similar: The JVM manages threads within its process, but the OS schedules them on the CPU. 


[[44 - Threads 🧀]]