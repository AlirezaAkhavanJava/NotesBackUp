

**JNI = Java Native Interface.**

JNI is the mechanism that allows **Java code running inside the JVM to interact with native code**, such as C or C++ code.

The core idea:

> **JNI is the bridge between Java/JVM code and native code outside the JVM's normal Java execution model.**

---

# 1. Why does JNI exist?

Java tries to give you a platform-independent environment:

```text
Java
  ↓
JVM
  ↓
OS
  ↓
Hardware
```

But sometimes Java needs to interact with something that exists at the native/OS level.

For example:

- An operating-system API
    
- A native C/C++ library
    
- A hardware-specific feature
    
- Existing native software that you want to reuse
    
- Very low-level system functionality
    

Suppose you already have a C library:

```c
int calculate(int x, int y) {
    return x + y;
}
```

You want Java to call it:

```java
int result = calculate(10, 20);
```

JNI provides the machinery to cross that boundary.

---

# 2. The basic architecture

Without JNI:

```text
Java code
   ↓
JVM
   ↓
JIT / Interpreter
   ↓
CPU
```

With JNI:

```text
Java code
   ↓
JVM
   ↓
JNI
   ↓
Native C/C++ code
   ↓
OS / CPU
```

So JNI is effectively an **interface between the JVM and native code**.

---

# 3. Simple example

Java:

```java
public class NativeCalculator {

    public native int add(int a, int b);

    static {
        System.loadLibrary("calculator");
    }
}
```

Notice this:

```java
public native int add(int a, int b);
```

`native` means:

> "The implementation of this method is not written in Java. It exists in native code."

Then:

```java
System.loadLibrary("calculator");
```

asks the JVM to load a native library.

On Linux, that might correspond to something like:

```text
libcalculator.so
```

Then the execution path becomes approximately:

```text
Java:
calculator.add(10, 20)
        │
        ▼
JVM
        │
        ▼
JNI
        │
        ▼
libcalculator.so
        │
        ▼
C function
        │
        ▼
return 30
```

---

# 4. What does "native" mean here?

**Native code** generally means code compiled for the **actual platform/CPU**, rather than JVM bytecode.

For your Debian machine, for example:

```text
Java source
    ↓
javac
    ↓
JVM bytecode
    ↓
JVM
```

whereas C might be compiled into native machine code:

```text
C source
   ↓
gcc
   ↓
x86-64 machine code
```

So:

```text
Java bytecode        → JVM understands
Native machine code  → CPU understands
```

JNI lets those worlds communicate.

---

# 5. JNI and the JVM Stack

This connects directly to the Runtime Data Areas we were discussing.

Suppose Java calls:

```java
nativeMethod(10);
```

A Java method normally gets a JVM stack frame:

```text
JVM Stack

┌──────────────────────┐
│ Java method frame    │
├──────────────────────┤
│ nativeMethod() call  │
└──────────────────────┘
```

When execution crosses into native code, the JVM needs to interact with the native execution environment.

That's related to the **Native Method Stack** we mentioned earlier.

Very simplified:

```text
Java thread
    │
    ▼
JVM Stack
    │
    │ JNI call
    ▼
Native execution
    │
    ▼
Native Method Stack / native stack
```

The exact implementation details are JVM-specific, but conceptually this is the boundary.

---

# 6. JNI isn't the same as the Native Method Stack

This distinction matters.

### JNI

A **programming interface/bridge**.

It defines how Java/native code communicate.

### Native Method Stack

A **runtime data area associated with execution of native methods**.

So:

```text
JNI
= "How do Java and native code communicate?"

Native Method Stack
= "Where native method execution state can be maintained."
```

They're related, but they're not the same thing.

---

# 7. What can cross the JNI boundary?

JNI can allow native code to interact with Java objects and values.

For example:

```text
Java int
   ↕
native jint

Java String
   ↕
JNI representation

Java object
   ↕
JNI object reference
```

Native code can also call Java methods and access Java fields through JNI mechanisms.

So the relationship is not just:

```text
Java → C
```

It can also be:

```text
Java ↔ C/C++
```

---

# 8. Why JNI is dangerous compared with normal Java

This is an important reason Java developers don't use JNI everywhere.

Native code operates outside many of Java's safety guarantees.

For example, in C:

```c
int *p = NULL;
*p = 10;
```

can cause a native crash.

Java normally prevents that sort of direct arbitrary memory access.

With JNI, you're crossing into a world where bugs can involve:

- Invalid native memory access
    
- Memory corruption
    
- Native crashes
    
- Incorrect pointer handling
    
- Resource leaks
    
- Threading problems
    
- Incorrect interaction with the JVM
    

A JVM process can therefore terminate because of a native-code problem.

---

# 9. JNI and Garbage Collection

This is especially relevant to your current GC study.

Imagine Java has:

```java
User user = new User();
```

and native code needs to keep referring to that Java object.

The JVM's Garbage Collector needs to know:

> "Is this native-side reference keeping the Java object alive?"

JNI provides mechanisms for native code to create/manage references to Java objects, including **local references** and **global references**.

Conceptually:

```text
GC Root
   │
   ▼
JNI reference
   │
   ▼
Java object
   │
   ▼
Heap
```

This is one reason JNI references can participate in GC-root/reachability considerations.

A native reference managed incorrectly can therefore affect object lifetime.

---

# 10. A practical example from Java

Java itself uses native functionality extensively internally.

For example:

```java
System.out.println("Hello");
```

eventually interacts with OS-level I/O mechanisms.

And many parts of the Java platform are implemented using native code inside the JVM and platform libraries.

So the JVM isn't:

```text
100% Java
```

A more realistic model is:

```text
Java application
       │
       ▼
       JVM
 ┌───────────────┐
 │ Java runtime  │
 │ JVM internals │
 │ native code   │
 └───────────────┘
       │
       ▼
      OS
```

JNI is one standardized mechanism for Java/native interaction.

---

# 11. JNI vs JIT

Don't confuse these two.

### JIT

```text
Bytecode
   ↓
compile
   ↓
native machine code
```

It's about **optimizing Java bytecode execution**.

### JNI

```text
Java
   ↓
native interface
   ↓
C/C++
```

It's about **communicating with native code**.

So:

```text
JIT → "How can the JVM execute Java code faster?"

JNI → "How can Java communicate with native code?"
```

---

# 12. Full picture

Now connect it with everything we've covered:

```text
                 Java source
                      │
                    javac
                      │
                      ▼
                  .class
                      │
                 Class Loader
                      │
             Loading / Linking
                      │
               Initialization
                      │
                      ▼
                Execution Engine
                 /            \
                /              \
        Interpreter             JIT
             │                   │
             └────────┬──────────┘
                      ▼
                 JVM execution
                      │
               ┌──────┴──────┐
               │             │
            Java code      JNI
                             │
                             ▼
                        Native code
                        (C/C++)
                             │
                             ▼
                            OS
                             │
                             ▼
                          Hardware
```

And alongside execution:

```text
Runtime Data Areas

Shared:
├── Heap
└── Method Area

Per-thread:
├── JVM Stack
├── PC Register
└── Native Method Stack
```

The particularly useful mental model is:

> **The JVM normally executes JVM bytecode, while JNI provides a controlled doorway from that Java/JVM world into native code.**

And this connects directly to the next Runtime Data Area you haven't fully unpacked yet: **the PC Register**.


[[Java]]