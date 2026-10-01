
---
## 1. Writing the Code

- You write Java code in a `.java` file.
    
- The code must be inside a **class**.
    
- Execution starts from the `main` method:
    
    ```java
    public static void main(String[] args) { }
    ```
    

---

## 2. Compilation

- Java source files are compiled using the **Java Compiler (`javac`)**.
    
- The compiler converts `.java` files into **bytecode** stored in `.class` files.
    
- Example:
    
    ```bash
    javac HelloWorld.java
    ```
    

Result: `HelloWorld.class`

---

## 3. Class Loading

- The **ClassLoader** loads `.class` files into JVM memory.
    
- Three main class loaders:
    
    1. **Bootstrap ClassLoader** → Loads core Java classes (`java.lang.*`).
        
    2. **Extension ClassLoader** → Loads extension libraries.
        
    3. **Application ClassLoader** → Loads your application classes.
        

---

## 4. Bytecode Verification

- Before execution, the **Bytecode Verifier** checks for illegal code:
    
    - Stack underflow/overflow
        
    - Invalid typecasts
        
    - Access violations
        
- Ensures security and stability.
    

---

## 5. Execution

- Execution happens inside the **Java Virtual Machine (JVM)**.
    
- Two main components:
    
    1. **Interpreter** → Executes bytecode line by line.
        
    2. **JIT Compiler (Just-In-Time)** → Translates frequently used bytecode into native machine code for speed.
        

---

## 6. Runtime Memory Management

- JVM divides memory into regions:
    
    - **Method Area** → Class structures, method code.
        
    - **Heap** → Objects.
        
    - **Stack** → Local variables & method calls.
        
    - **PC Register** → Tracks instruction execution.
        
    - **Native Method Stack** → For native (C/C++) calls.
        
- Managed by the **Garbage Collector (GC)**:
    
    - Automatically frees unused objects from the heap.
        

---

## 7. Multithreading & Concurrency

- JVM manages multiple threads.
    
- Each thread has its own **stack**.
    
- Shared resources live in the **heap**.
    

---

## 8. Program Termination

- Program ends when:
    
    - `main()` finishes execution.
        
    - All non-daemon threads finish.
        
- Before shutdown:
    
    - **Shutdown hooks** (if registered) are executed.
        
    - Garbage Collector may release memory.
        

---

## Summary

1. **Write Code** → `.java`
    
2. **Compile** → `.class` bytecode
    
3. **Class Loading**
    
4. **Bytecode Verification**
    
5. **Execution (Interpreter + JIT)**
    
6. **Memory Management (Heap, Stack, GC)**
    
7. **Thread Execution**
    
8. **Program Termination**
    

This lifecycle ensures Java’s **portability, security, and efficiency** across platforms.

[[Java]]
