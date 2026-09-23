

## 1. Big Picture

A Java program passes through several distinct stages before and during execution:

```text
Java Source Code
       │
       │ javac
       ▼
   .class file
   JVM Bytecode
       │
       │ JVM
       ▼
Class Loading
       │
       ▼
   Linking
       │
       ▼
Initialization
       │
       ▼
Execution
       │
       ▼
Machine Code
       │
       ▼
CPU
```

There are two important worlds here:

- **Compilation** — converting `.java` source code into JVM bytecode.
    
- **Runtime** — the JVM loads, prepares, initializes, and executes that bytecode.
    

---

# 2. `javac` — The Java Compiler

`javac` is the standard Java compiler included with the JDK.

Its job is:

```text
.java
  │
  │ javac
  ▼
.class
```

It does **not** normally compile Java source directly into CPU machine code.

Instead:

```text
Java source
     ↓
javac
     ↓
JVM bytecode
     ↓
JVM
     ↓
machine code
```

For example:

```java
public class Hello {

    public static void main(String[] args) {
        System.out.println("Hello");
    }
}
```

Compile:

```bash
javac Hello.java
```

Result:

```text
Hello.java
Hello.class
```

The `.class` file contains JVM bytecode.

You can inspect it with:

```bash
javap -c Hello
```

Example:

```text
public static void main(java.lang.String[]);
  Code:
     0: getstatic
     3: ldc
     5: invokevirtual
     8: return
```

These are JVM instructions, not x86-64 or ARM instructions.

---

# 3. Why Java Uses Bytecode

Different computers have different CPU architectures and operating systems.

For example:

```text
x86-64
ARM64
Windows
Linux
macOS
```

If `javac` generated CPU-specific machine code, Java would need a different compiler output for every platform.

Instead, Java defines a standard intermediate instruction set:

```text
                  JVM Bytecode
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
      Linux JVM    Windows JVM   macOS JVM
          │            │            │
          ▼            ▼            ▼
       x86-64        x86-64        ARM64
```

The `.class` file is therefore largely platform-independent.

Different JVM implementations know how to execute the same JVM bytecode on their respective platforms.

---

# 4. Where `.class` Files Are Stored

If you directly run:

```bash
javac Hello.java
```

the `.class` file normally appears beside the source file:

```text
project/
├── Hello.java
└── Hello.class
```

You can specify an output directory:

```bash
javac -d out Hello.java
```

Then:

```text
project/
├── Hello.java
└── out/
    └── Hello.class
```

Packages affect the directory structure.

For:

```java
package com.example;

public class Hello {
}
```

using:

```bash
javac -d out Hello.java
```

produces:

```text
out/
└── com/
    └── example/
        └── Hello.class
```

---

# 5. Maven Projects

In a Maven project, Java source normally lives under:

```text
src/main/java/
```

For example:

```text
project/
├── pom.xml
└── src/
    └── main/
        └── java/
            └── com/
                └── example/
                    └── Hello.java
```

After:

```bash
mvn compile
```

compiled classes normally appear under:

```text
target/classes/
```

So:

```text
project/
├── pom.xml
├── src/
│   └── main/
│       └── java/
│           └── com/
│               └── example/
│                   └── Hello.java
│
└── target/
    └── classes/
        └── com/
            └── example/
                └── Hello.class
```

`target/classes` is a Maven convention. It isn't a requirement imposed by the JVM.

---

# 6. Does Compilation Allocate Memory?

Yes.

`javac` itself is a program and therefore uses RAM while it runs.

During compilation, it creates internal data structures representing things such as:

```text
Source text
    ↓
Tokens
    ↓
AST
    ↓
Symbols
    ↓
Types
    ↓
Bytecode
```

So memory allocation absolutely happens during compilation.

However, `javac` does **not execute your program**.

For example:

```java
User user = new User();
```

`javac` does not create a `User` object.

It compiles that statement into bytecode.

The actual `User` object is created later, during program execution.

---

# 7. JVM and the Operating System

The JVM is not a separate operating system.

It is a **native program running under the operating system**.

For example:

```bash
java Hello
```

causes the OS to start a JVM process.

Conceptually:

```text
Hardware
   ▲
   │
Operating System / Kernel
   ▲
   │
JVM Process
   ▲
   │
Java Application
```

The JVM interacts with hardware largely through the operating system.

---

## CPU

The JVM creates/manages threads.

The OS scheduler ultimately schedules those threads onto CPU cores.

```text
JVM
 │
 │ JVM threads
 ▼
Operating System
 │
 │ scheduler
 ▼
CPU cores
```

---

## Memory

The JVM requests memory from the operating system.

Conceptually:

```text
JVM
 │
 │ memory requests
 ▼
OS / Kernel
 │
 ▼
Virtual Memory
 │
 ▼
Physical RAM
```

The JVM manages its own runtime memory structures, such as the heap, while the OS manages the process's virtual address space and physical memory resources.

---

## Storage

When classes or resources need to be read:

```text
.class / JAR
     ↓
Filesystem
     ↓
Operating System
     ↓
Storage device
     ↓
RAM
     ↓
JVM
```

The `.class` file itself remains on storage.

The JVM obtains its contents through the OS and works with the class data in memory.

---

# 8. The JVM Is Also Native Software

A JVM implementation such as HotSpot is not written entirely in Java.

It contains substantial native code, including C/C++ and platform-specific code.

Conceptually:

```text
Java Application
       │
       ▼
JVM / HotSpot
├── Class Loading
├── Interpreter
├── JIT Compiler
├── Garbage Collector
├── Thread Management
└── Native / OS Interface
       │
       ▼
Operating System
       │
       ├── CPU
       ├── RAM
       └── Storage
```

This is what makes the JVM capable of presenting a consistent virtual machine to Java applications while adapting to different operating systems and CPU architectures.

---

# 9. What Is a Class Loader?

A **Class Loader** is a JVM mechanism responsible for obtaining the binary representation of a class and defining that class to the JVM.

The simplified model is:

```text
.class file
     │
     │ obtain bytes
     ▼
Class Loader
     │
     ▼
JVM
```

The Class Loader does not necessarily load every `.class` file at application startup.

Classes are generally loaded **on demand**, when they are needed.

For example:

```text
Application starts
       │
       ▼
Need Main
       │
       ▼
Load Main
       │
       ▼
Main needs User
       │
       ▼
Load User
       │
       ▼
User needs Address
       │
       ▼
Load Address
```

---

# 10. The Class Loader Loads Bytes, Not "The File"

This distinction is important.

It is better to say:

> The Class Loader obtains the binary bytes representing the class.

Rather than:

> The Class Loader loads the `.class` file.

The file can remain on storage:

```text
Storage

User.class
┌─────────────────────┐
│ CA FE BA BE ...     │
│ class-file bytes    │
└─────────────────────┘
```

The Class Loader obtains those bytes:

```text
User.class
    │
    │ read
    ▼
Class Loader
    │
    ▼
JVM class representation
```

The bytes do not have to come from an ordinary filesystem.

They can originate from:

- Filesystem
    
- JAR files
    
- Java runtime image
    
- Network
    
- Generated bytecode
    
- Custom sources
    

---

# 11. Types of Class Loaders

The standard JVM class-loader hierarchy is conceptually:

```text
Bootstrap Class Loader
          │
          ▼
Platform Class Loader
          │
          ▼
Application Class Loader
          │
          ▼
Custom Class Loaders
```

---

## 11.1 Bootstrap Class Loader

The Bootstrap Class Loader loads fundamental Java platform classes.

Examples include:

```text
java.lang.Object
java.lang.String
java.lang.System
java.lang.Integer
```

These classes are provided by the Java runtime.

In modern Java, the runtime classes are primarily provided through the runtime image.

A special detail:

```java
System.out.println(Object.class.getClassLoader());
```

prints:

```text
null
```

This does **not** mean `Object` wasn't loaded.

It means the Bootstrap Class Loader is represented as `null` by the Java API.

---

## 11.2 Platform Class Loader

The Platform Class Loader loads Java platform classes outside the fundamental bootstrap classes.

Its parent is the Bootstrap Class Loader.

```text
Bootstrap
    │
    ▼
Platform
```

You can obtain it with:

```java
ClassLoader.getPlatformClassLoader();
```

---

## 11.3 Application Class Loader

The Application Class Loader normally loads application classes and dependencies.

For example:

```text
com.example.Main
com.example.User
com.example.Service
```

and libraries on the application's class path/module path.

You can obtain the system/application loader with:

```java
ClassLoader.getSystemClassLoader();
```

The hierarchy is:

```text
Bootstrap
    │
    ▼
Platform
    │
    ▼
Application
```

---

## 11.4 Custom Class Loaders

Java allows developers and frameworks to create custom Class Loaders.

They can extend:

```java
ClassLoader
```

and implement their own mechanisms for obtaining class bytes.

Custom Class Loaders are useful for:

- Plugin systems
    
- Application servers
    
- Class isolation
    
- Hot deployment
    
- Reloading
    
- Unusual class sources
    
- Framework infrastructure
    

---

# 12. Parent Delegation

Class Loaders normally follow a **parent delegation model**.

Suppose the Application Class Loader is asked for:

```text
java.lang.String
```

It doesn't immediately try to load it itself.

Instead:

```text
Application Class Loader
          │
          │ ask parent
          ▼
Platform Class Loader
          │
          │ ask parent
          ▼
Bootstrap Class Loader
          │
          ▼
java.lang.String
```

This prevents application classes from simply replacing fundamental platform classes.

The general idea is:

> Ask the parent first; only attempt to find the class yourself if the parent cannot provide it.

---

# 13. Class Lifecycle

Once we enter JVM internals, a useful high-level lifecycle is:

```text
.class
  │
  ▼
┌──────────┐
│ Loading  │
└────┬─────┘
     ▼
┌──────────┐
│ Linking  │
└────┬─────┘
     ▼
┌────────────────┐
│ Initialization │
└────┬───────────┘
     ▼
  Execution
```

Linking itself consists of:

```text
Linking
   │
   ├── Verification
   ├── Preparation
   └── Resolution
```

---

# 14. Loading

The **Loading** phase obtains the class's binary representation and creates the JVM's representation of that class.

Conceptually:

```text
.class bytes
     │
     ▼
Class Loader
     │
     ▼
Loaded class
```

For example:

```text
com/example/User.class
          │
          ▼
Class Loader
          │
          ▼
com.example.User
```

Loading does not mean that the class's methods have executed.

---

# 15. Linking

After loading, the JVM performs linking.

Linking makes the loaded class structurally ready for use.

It consists of:

```text
Verification
Preparation
Resolution
```

---

# 16. Verification

Verification checks that the class-file data is valid according to JVM rules.

The JVM can receive bytecode from sources other than `javac`, so it cannot blindly assume that the bytecode is valid.

Conceptually:

```text
.class
  │
  ▼
Verification
  │
  ├── valid ──→ continue
  │
  └── invalid → reject
```

Verification checks things such as:

- Class-file structure
    
- Valid bytecode instructions
    
- Type correctness
    
- JVM constraints
    

---

# 17. Preparation

Preparation deals with the class's static storage.

Consider:

```java
public class User {

    static int count = 10;

    static String name = "Alireza";
}
```

During preparation, static fields receive their **default values**.

Conceptually:

```text
count → 0
name  → null
```

Not:

```text
count → 10
name  → "Alireza"
```

Those programmer-specified values are established during initialization.

Therefore:

```text
Preparation
     │
     ├── count = 0
     └── name = null
```

Later:

```text
Initialization
     │
     ├── count = 10
     └── name = "Alireza"
```

---

# 18. Resolution

Resolution is about **symbolic references** contained in class files.

Suppose:

```java
public class Main {

    public static void main(String[] args) {
        User user = new User();
        user.sayHello();
    }
}
```

`Main.class` needs to refer to:

```text
User
User.sayHello()
```

But the `.class` file doesn't simply contain a physical RAM address for `User`.

Instead, it contains symbolic information identifying what it needs.

Conceptually:

```text
"com/example/User"
```

and:

```text
"com/example/User.sayHello:()V"
```

The JVM eventually needs to connect these symbolic references with the actual classes and methods they refer to.

That's **resolution**.

---

## Symbolic Reference Example

Before resolution:

```text
Main.class

"com/example/User"
"User.sayHello"
```

After resolution:

```text
Main
 │
 ├──────────────► User class
 │                    │
 │                    └──► sayHello()
 │
 └──────────────► other referenced classes
```

A useful analogy is a phone contact:

```text
"Alice"
   │
   ▼
look up Alice
   │
   ▼
actual contact information
```

Similarly:

```text
"com/example/User"
        │
        ▼
find the referenced class
        │
        ▼
actual JVM class representation
```

Resolution can involve symbolic references to:

- Classes
    
- Interfaces
    
- Fields
    
- Methods
    

---

# 19. Resolution Is Not the Same as Loading

These concepts are related but different.

### Loading

> "Obtain the class's binary representation and define the class."

### Resolution

> "Connect symbolic references in that class to the actual classes, fields, and methods they refer to."

Conceptually:

```text
                 Main.class
                     │
                     ▼
                  Loading
                     │
                     ▼
                Main loaded
                     │
                     ▼
                Resolution
                     │
                     ▼
      "User" ──────────────► User class
      "sayHello" ──────────► User.sayHello()
```

Also, the JVM is allowed to perform some resolution lazily rather than resolving every symbolic reference immediately.

---

# 20. Initialization

Initialization is the stage where the JVM executes the class's initialization code.

For example:

```java
public class User {

    static int count = 10;

    static {
        System.out.println("User initialized");
    }
}
```

During preparation:

```text
count = 0
```

During initialization:

```text
count = 10
```

and:

```text
User initialized
```

is printed.

---

# 21. `<clinit>`

The Java compiler can generate a special class initialization method called:

```text
<clinit>
```

It is not a normal Java method that you write or invoke directly.

For example:

```java
class User {

    static int count = 10;

    static {
        System.out.println("Hello");
    }
}
```

is conceptually transformed into something like:

```text
<clinit>() {

    count = 10;

    System.out.println("Hello");
}
```

The JVM executes this class initialization code when the class is initialized.

---

# 22. Initialization Is Not Object Construction

This distinction is extremely important.

Class initialization:

```text
<clinit>
```

deals with the **class itself**, particularly static initialization.

Object construction:

```text
<init>
```

is associated with constructors and an individual object.

For:

```java
User user = new User();
```

there are conceptually two different things happening:

```text
Class initialization
       │
       ▼
    <clinit>

Object construction
       │
       ▼
    <init>
```

They are not the same mechanism.

---

# 23. When Does Initialization Happen?

Classes aren't necessarily initialized immediately after being loaded.

Initialization generally occurs when the JVM encounters an appropriate **active use** of the class.

Examples include:

```java
new User();
```

or:

```java
User.someStaticMethod();
```

or accessing certain static fields.

Conceptually:

```text
Class loaded
     │
     ▼
Class linked
     │
     ▼
Class may remain uninitialized
     │
     ▼
Active use
     │
     ▼
Initialization
```

---

# 24. Static Initialization Happens Once

For a particular class as defined by a particular Class Loader, initialization occurs at most once.

For:

```java
class Counter {

    static {
        System.out.println("Initialized");
    }
}
```

using the class multiple times doesn't repeatedly execute the static initializer:

```text
Initialized
```

happens once for that class definition.

The JVM also guarantees proper synchronization of class initialization when multiple threads attempt to initialize the same class concurrently.

Conceptually:

```text
Thread A ──┐
           ├──► initialization ──► complete
Thread B ──┘
             waits
                │
                ▼
          uses initialized class
```

---

# 25. Superclass Initialization

If a class has a superclass, the superclass is initialized before the subclass.

Example:

```java
class Parent {

    static {
        System.out.println("Parent");
    }
}

class Child extends Parent {

    static {
        System.out.println("Child");
    }
}
```

Using:

```java
new Child();
```

results conceptually in:

```text
Parent initialization
        │
        ▼
Child initialization
```

Output:

```text
Parent
Child
```

---

# 26. Complete JVM Class Lifecycle

Putting everything together:

```text
                       .class
                          │
                          ▼
                    ┌───────────┐
                    │  LOADING  │
                    └─────┬─────┘
                          │
                          ▼
                    ┌───────────┐
                    │  LINKING  │
                    └─────┬─────┘
                          │
              ┌───────────┼───────────┐
              ▼           ▼           ▼
        Verification Preparation Resolution
              │           │           │
              │           │           │
              │      static defaults  │
              │                       │
              └───────────┬───────────┘
                          │
                          ▼
                    Linked Class
                          │
                          │ active use
                          ▼
                 ┌────────────────┐
                 │ INITIALIZATION │
                 └───────┬────────┘
                         │
                         ▼
                      <clinit>
                         │
                         ▼
                Initialized Class
                         │
                         ▼
                     Execution
```

---

# 27. The Core Mental Model

Keep these definitions firmly separated:

### `javac`

```text
.java
  ↓
.class
```

Produces **JVM bytecode**.

### Class Loading

```text
class bytes
     ↓
loaded class
```

Obtains the binary representation and defines the class to the JVM.

### Linking

```text
loaded class
     ↓
verification
     ↓
preparation
     ↓
resolution
```

Makes the class structurally ready for use.

### Initialization

```text
initialized class
     ↓
execute <clinit>
     ↓
static state established
```

Executes the class's initialization code.

### Execution

```text
bytecode
   ↓
Interpreter / JIT
   ↓
machine code
   ↓
CPU
```

This is where the JVM actually begins executing the program's instructions.

[[Java]]