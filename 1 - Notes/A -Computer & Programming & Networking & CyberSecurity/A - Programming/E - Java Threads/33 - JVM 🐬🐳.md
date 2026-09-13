Date : 2025-09-15


![[1_bSYQtrFC2fiqybMszGhgow.png]]


## **Class Loader**

- They are the **first stage of execution** once the JVM starts.
    
- Their job: **find `.class` files in storage or network → load bytecode into JVM memory (Method Area)**.
    
- Without them, JVM has nothing to execute.
    



### **The Workflow**

1. **Loading**
    
    - Reads the `.class` file from storage (disk, JAR, or even network).
        
    - Brings the raw bytecode into RAM.
        
2. **Linking** (before execution)
    
    - **Verify:** Ensure bytecode is valid (security checks, type safety).
        
    - **Prepare:** Allocate memory for static variables, set defaults.
        
    - **Resolve:** Replace symbolic references (like `java/lang/Object`) with actual pointers in memory.
        
3. **Initialization**
    
    - Run class initializers (`static {}` blocks, static variable assignments).
        



### **Types of Class Loaders (Hierarchy)**

JVM follows the **Parent Delegation Model**:

1. **Bootstrap Class Loader**
    
    - Written in native code, part of JVM.
        
    - Loads **core Java classes** from `JAVA_HOME/lib` (e.g., `java.lang.String`, `java.util.*`).
        
2. **Extension (Platform) Class Loader**
    
    - Loads classes from `JAVA_HOME/lib/ext` or platform-specific extensions.
        
3. **Application (System) Class Loader**
    
    - Loads classes from your **classpath** (your compiled `.class` files, JARs).
        
4. **Custom Class Loaders**
    
    - You can write your own loader to fetch classes from network, database, or encrypted files.

### **How it works at runtime**

1. JVM starts and Bootstrap loads `java.base` classes.
    
2. Platform ClassLoader loads other standard JDK modules (`java.sql`, `java.xml`, etc.).
    
3. Application ClassLoader scans your **classpath** (project classes + Maven dependencies).
    
4. Classes from Spring Boot, Hibernate, etc., are loaded **on demand** into JVM memory.
    

✅ **Ruthless fact:**

- Your dependencies **never get loaded by Bootstrap or Platform**.
    
- If you add hundreds of JARs via Maven, **Application ClassLoader is the one managing all of them**.

>**Bootstrap ClassLoader** and **Platform (Extension) ClassLoader** only load **classes that come with the JDK itself**.
  They do **not** load your application classes or third-party libraries on your classpath.

### **Where ClassLoaders get files from**

- **ClassLoaders load classes from storage**:
    
    - `.class` files on disk (your project, JARs, Maven dependencies)
        
    - JDK modules (`java.base`, `java.sql`, etc.)
        
- The **“storage”** is typically:
    
    - **SSD/HDD** for your project files or JDK installation
        
    - Sometimes network locations if using custom loaders
        



### **Where ClassLoaders put them**

- Loaded classes (bytecode) go into **JVM memory** in RAM.
    
- JVM memory includes **Method Area, Heap, Stack, Code Cache, PC Registers**, etc.
    



### **Where JVM itself lives**

- JVM is a **native process** running on your **OS**.
    
- The OS loads the JVM executable from storage (SSD/HDD) into **RAM**.
    
- CPU executes **JVM machine instructions** from RAM.



> ## **Parent Delegation Model**

- When a class loader is asked to load a class, it first **delegates to its parent**.
    
- Only if the parent can’t find it, does it try itself.
    

**Flow:**

```java
Application → Extension → Bootstrap
```

- Prevents core classes (`java.lang.String`) from being overridden by malicious user classes.

----

## Runtime Data Area


>The **Runtime Data Area** in the JVM is the memory structure the JVM uses **at runtime** to manage classes, objects, methods, and threads. It’s basically where the JVM lives while running your program.
### 1. **Thread-Shared Areas**

These are accessible by all threads:

- **Method Area**  
    Stores class-level data: bytecode of methods, field and method metadata, runtime constant pool.  
    _(Think of it as a “class library” in memory.)_
    
- **Heap**  
    Stores all **objects and arrays** created at runtime. Managed by the garbage collector.  
    _(Objects live here until GC cleans them.)_
### 2. **Per-Thread Areas**

Each thread has its own memory spaces:

- **PC (Program Counter) Register**  
    Holds the address of the JVM instruction the thread is executing.  
    _(Each thread tracks its own “current line of code.”)_
    
- **Java Stack**  
    Stores **stack frames**, which include local variables, operand stacks, and return addresses for method calls.  
    _(Every method call gets a frame, which disappears when the method returns.)_
    
- **Native Method Stack**  
    Similar to Java Stack, but for **native methods** written in C/C++ that the JVM calls.

💡 **Summary:**  
	The Runtime Data Area = JVM’s working memory. Some parts are **shared** (heap, method area), some are private to threads (stack, PC register). This is where classes get loaded, objects live, and methods execute.


----

## Execution Engine

> **Execution Engine** is the **heart of the JVM**. It’s the component that actually runs your bytecode. Without it, your `.class` files are just dead text.


> ### **What it does**

1. **Reads bytecode** from the **method area**.
    
2. **Executes instructions** one by one.
    
3. Interacts with the **runtime data area** (stack, heap, PC, etc.) while executing.

> ### **Components of the Execution Engine**

1. **Interpreter**
    
    - Reads bytecode **line by line** and executes it.
        
    - Fast to start but slow overall because it interprets each instruction every time.
        
2. **Just-In-Time (JIT) Compiler**
    
    - Converts bytecode into **native machine code** at runtime.
        
    - Speeds up repeated method calls.
        
    - JVM often starts with the interpreter, then JIT-compiles “hot” methods.
        
3. **Garbage Collector Interface**
    
    - Execution engine calls GC when it needs memory cleared.
        
4. **Native Method Interface**
    
    - Lets Java call native (C/C++) code if needed.

---
## Garbage Collector

The **Garbage Collector (GC)** is **the JVM’s memory janitor**—it automatically cleans up memory that your program no longer uses so you don’t have to.
 
 > ### **Purpose**

- Free memory in the **heap** by removing objects that are no longer reachable.
    
- Prevent **memory leaks** and **OutOfMemoryErrors**.

> ### **How GC Works**

1. **Mark** – Identify objects that are still reachable (referenced by variables, stacks, etc.).
    
2. **Sweep** – Delete objects that are **not marked**.
    
3. **Compact (optional)** – Move surviving objects together to reduce fragmentation.

> ### **Memory Areas Relevant to GC**

- **Heap** is the main target.
    
    - **Young Generation** – Newly created objects; collected frequently.
        
        - Eden Space
            
        - Survivor Spaces
            
    - **Old Generation** – Long-lived objects; collected less frequently.
        
- **Permanent/Metaspace** – Stores class metadata; may also be cleaned up occasionally.
	![[java-collection-6.png]]
> ### **Types of GC in HotSpot JVM**

1. **Serial GC** – Single-threaded, simple, good for small apps.
    
2. **Parallel GC** – Multi-threaded, faster for multi-core CPUs.
    
3. **G1 GC (Garbage-First)** – Splits heap into regions; tries to minimize pause times.
    
4. **ZGC / Shenandoah** – Ultra-low pause collectors for huge heaps.

> ### **Key Notes**

- You **don’t call GC manually** (calling `System.gc()` is just a suggestion).
    
- GC affects **performance**, because during collection, some threads may pause.
    
- Proper object design and avoiding unnecessary object creation can **reduce GC overhead**.

> 💡 **Analogy:**  
Heap = your storage room. Objects pile up.  
GC = cleaning crew: tosses unused junk, rearranges the room, and makes space for new stuff.  
Young generation = “temporary clutter,” cleaned often.  
Old generation = “long-term items,” cleaned less frequently.

##### *Tags : [[Java]]