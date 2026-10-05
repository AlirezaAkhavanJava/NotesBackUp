
# Java: OOP, Compilation, Interpretation, and the JVM Execution Engine

## 1. The Big Picture

A common source of confusion when learning Java is hearing all of these statements:

- "Java is an object-oriented language."
    
- "Java is a compiled language."
    
- "Java is interpreted."
    
- "The JVM uses an interpreter."
    
- "The JVM uses a JIT compiler."
    

These statements can all be true, but they describe **different aspects of Java**.

The key is to separate:

1. **Java's programming paradigm**
    
2. **Java's compilation process**
    
3. **JVM bytecode**
    
4. **The JVM interpreter**
    
5. **The JIT compiler**
    
6. **How the JVM executes a running application**
    

---

# 2. Is Java Fully Object-Oriented?

Java is **object-oriented**, but it is not considered a "pure" or "fully" object-oriented language.

Java supports the major object-oriented concepts:

- Encapsulation
    
- Inheritance
    
- Polymorphism
    
- Abstraction
    

For example:

```java
class User {
    private String name;

    public User(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }
}
```

Here, `User` is a class and `name` is encapsulated inside the object.

However, Java also has **primitive types**:

```java
int
long
double
boolean
char
```

These are not objects.

For example:

```java
int age = 25;
```

`age` is a primitive value, not an instance of a Java class.

There are wrapper classes:

```java
Integer
Long
Double
Boolean
Character
```

but the existence of primitives means Java is not purely object-oriented in the strict sense.

Therefore:

> **Java is an object-oriented language, but not a pure object-oriented language.**

---

# 3. Is Java a Compiled Language?

Yes.

Java source code is compiled using the Java compiler:

```text
javac
```

Suppose we have:

```java
public class Main {

    public static void main(String[] args) {
        System.out.println("Hello");
    }
}
```

We compile it:

```bash
javac Main.java
```

The result is:

```text
Main.class
```

But something very important happened here.

`javac` did **not** normally compile the Java source directly into CPU-specific machine code.

Instead:

```text
Java source code
        │
        │ javac
        ▼
   JVM bytecode
        │
        ▼
    Main.class
```

The `.class` file contains **JVM bytecode**.

---

# 4. What Is Bytecode?

Bytecode is an intermediate instruction format designed for the **Java Virtual Machine**.

It is not ordinary source code:

```java
int result = a + b;
```

and it is not CPU-specific machine code such as x86 instructions.

Conceptually:

```text
Java source
    ↓
JVM bytecode
    ↓
CPU
```

The important property is that JVM bytecode is **platform-independent**.

For example, the same:

```text
Main.class
```

can potentially run on:

```text
Linux
Windows
macOS
x86-64
ARM64
```

provided there is a compatible JVM.

This is the foundation behind Java's famous idea:

> **Write once, run anywhere.**

The source code is compiled into bytecode once, while the JVM implementation on each platform handles execution on that platform's CPU.

---

# 5. What Is the JVM?

The JVM stands for:

> **Java Virtual Machine**

It is the runtime environment that executes Java bytecode.

The basic relationship is:

```text
Java source
      │
      │ javac
      ▼
   Bytecode
      │
      │ JVM
      ▼
    CPU
```

The JVM is therefore responsible for taking the `.class` bytecode and making the application actually run.

---

# 6. The JVM Execution Engine

One important part of the JVM is the **Execution Engine**.

Conceptually:

```text
JVM
│
├── Class Loader
│
├── Runtime Data Areas
│
├── Execution Engine
│   │
│   ├── Interpreter
│   │
│   └── JIT Compiler
│
└── Garbage Collector
```

The Execution Engine is responsible for actually executing JVM bytecode.

And this is where the confusing part begins.

---

# 7. Why Does the JVM Have an Interpreter?

You might initially think:

> "Java is compiled, so why does Java need an interpreter?"

Because the thing produced by `javac` is **bytecode**, not necessarily native machine code.

The JVM can execute that bytecode using an **interpreter**.

The interpreter reads JVM bytecode instructions and executes them.

Conceptually:

```text
Bytecode
   │
   ▼
Interpreter
   │
   ▼
CPU performs the operations
```

The interpreter does **not** need to turn the entire program into machine code first.

Instead, it can execute bytecode instructions as the program runs.

For example, imagine bytecode conceptually containing:

```text
iload_1
iload_2
iadd
istore_3
```

The interpreter can process these instructions:

```text
iload_1
    ↓
load local variable 1

iload_2
    ↓
load local variable 2

iadd
    ↓
add the two values

istore_3
    ↓
store the result
```

Therefore:

> **The interpreter executes bytecode.**

It is not primarily responsible for converting the whole application into native machine code.

---

# 8. What Does the JIT Compiler Do?

JIT stands for:

> **Just-In-Time Compiler**

The JIT compiler takes JVM bytecode and can compile frequently executed code into **native machine code**.

The basic flow becomes:

```text
Bytecode
    │
    │ JIT compiler
    ▼
Native machine code
    │
    ▼
CPU
```

For example:

```text
JVM bytecode
     ↓
 x86-64 machine code
     ↓
 Intel/AMD CPU
```

Or on another platform:

```text
JVM bytecode
     ↓
 ARM64 machine code
     ↓
 ARM CPU
```

The resulting machine code is specific to the actual hardware/platform.

---

# 9. Interpreter vs JIT

This distinction is extremely important.

## Interpreter

```text
Bytecode
    ↓
Interpreter
    ↓
Execution
```

The interpreter:

- Reads bytecode
    
- Executes bytecode
    
- Does not need to compile the entire method into native code first
    

## JIT Compiler

```text
Bytecode
    ↓
JIT compiler
    ↓
Native machine code
    ↓
CPU execution
```

The JIT:

- Compiles bytecode
    
- Produces native machine code
    
- Allows frequently executed code to run much more directly on the CPU
    

The simplest sentence to remember is:

> **Interpreter executes bytecode; JIT compiles bytecode into machine code.**

---

# 10. Why Doesn't the JVM Just JIT Everything Immediately?

This is the key question.

Imagine a large application containing:

```text
10,000 methods
```

But during one particular execution, perhaps only:

```text
500 methods
```

are used frequently.

The remaining methods may be:

```text
never called
```

or:

```text
called only once
```

Compiling every method immediately would require work that might never provide any benefit.

JIT compilation itself has a cost:

```text
bytecode
   ↓
JIT compilation
   ↓
analysis + optimization + code generation
```

That takes:

- CPU time
    
- memory
    
- startup time
    

So the JVM has a better strategy.

---

# 11. JVM Startup: Interpret First

The JVM can begin by interpreting bytecode.

Conceptually:

```text
.class file
    ↓
Bytecode
    ↓
Interpreter
    ↓
Application starts running
```

This allows the JVM to get the program running without immediately compiling everything.

At the same time, the JVM can observe what the application is actually doing.

This is called **profiling**.

---

# 12. The JVM Watches the Running Program

While the application is executing, the JVM can gather information such as:

```text
Which methods are called frequently?
Which loops execute many times?
Which code paths are common?
Which runtime types are actually being used?
```

For example:

```java
for (int i = 0; i < 1_000_000_000; i++) {
    calculate(i);
}
```

The method:

```java
calculate()
```

may be called millions or billions of times.

The JVM can recognize that this code is **hot**.

---

# 13. Hot Code

The term **hot code** means code that executes frequently enough that optimizing it becomes worthwhile.

Conceptually:

```text
Application
    │
    ├── method A → called once
    ├── method B → called twice
    ├── method C → called 10 times
    └── method D → called 500,000,000 times 🔥
```

Method `D` is an excellent candidate for JIT compilation.

Instead of repeatedly interpreting its bytecode, the JVM can compile it:

```text
Method D bytecode
        ↓
     JIT compiler
        ↓
Native machine code
```

Future executions can then use that generated machine code.

---

# 14. The JVM Therefore Uses an Adaptive Strategy

The JVM is not simply:

```text
ONLY interpreter
```

and it is not simply:

```text
ONLY compiler
```

Instead, the runtime can adapt based on what the application is doing.

A simplified model is:

```text
                JVM starts
                    │
                    ▼
               Interpret code
                    │
                    ▼
             Collect profiling
                    │
                    ▼
              Is code hot?
                 /     \
               No       Yes
               │         │
               ▼         ▼
          Keep using    JIT compile
          interpreter      │
                           ▼
                    Native machine code
                           │
                           ▼
                       CPU executes
```

This provides a compromise between:

```text
fast startup
```

and:

```text
high long-term performance
```

---

# 15. Runtime Information Gives the JIT an Advantage

There is another important reason this model is powerful.

The normal Java compiler:

```text
javac
```

compiles the source without observing your application's future runtime behavior.

But the JIT compiler operates **while the application is running**.

That means it can make optimization decisions using information gathered from the actual execution.

Consider:

```java
Animal animal = getAnimal();

animal.makeSound();
```

At source-code compilation time, `animal` may potentially refer to:

```text
Dog
Cat
Bird
...
```

At runtime, the JVM might observe that in a particular application:

```text
Dog.makeSound()
```

is overwhelmingly common.

The JIT can use runtime information to perform optimizations that depend on actual execution behavior.

This is one of the major strengths of a managed runtime such as the JVM.

---

# 16. The Full Java Execution Pipeline

Now put everything together.

```text
                COMPILE TIME
                     │
                     ▼
              Java source code
                     │
                     │ javac
                     ▼
                JVM bytecode
                     │
                     │
                     │ RUNTIME
                     ▼
                    JVM
                     │
              ┌──────┴──────┐
              │             │
              ▼             ▼
        Interpreter       JIT Compiler
              │             │
              │             ▼
              │       Machine code
              │             │
              └──────┬──────┘
                     ▼
                    CPU
```

The critical distinction is:

```text
javac
    ↓
Java source → JVM bytecode
```

while:

```text
JIT
    ↓
JVM bytecode → native machine code
```

Those are **different compilation stages**.

---

# 17. Three Different Things You Must Not Confuse

## Java Compiler

```text
javac
```

Purpose:

```text
Java source → JVM bytecode
```

Output:

```text
.class
```

---

## JVM Interpreter

Purpose:

```text
Execute JVM bytecode
```

It does not need to compile the whole application into native machine code.

---

## JVM JIT Compiler

Purpose:

```text
JVM bytecode → native machine code
```

This is done at runtime, especially for code that benefits from optimization.

---

# 18. So Is Java Compiled or Interpreted?

The correct answer is:

> **Java uses compilation and interpretation as part of its overall execution model.**

More precisely:

```text
Java source
      ↓
compiled by javac
      ↓
JVM bytecode
      ↓
interpreted and/or JIT-compiled by the JVM
      ↓
executed by the CPU
```

Therefore, saying:

> "Java is only an interpreted language"

is incomplete.

And saying:

> "Java is compiled directly to machine code"

is also inaccurate as a general description of the standard JVM execution model.

A much better description is:

> **Java source code is compiled into platform-independent JVM bytecode, and the JVM can interpret that bytecode and JIT-compile hot code into native machine code at runtime.**

---

# 19. Is Java "Fully Compiled"?

This depends on what someone means by "fully compiled."

If by "compiled" you mean:

```text
source code → machine code
```

then Java's normal `javac` step does not work that way.

Instead:

```text
source code → bytecode
```

Then, at runtime:

```text
bytecode → interpreted
```

and potentially:

```text
bytecode → JIT → native machine code
```

So Java is not simply a traditional:

```text
C/C++ source
      ↓
native executable
```

pipeline.

---

# 20. Is Java Fully Object-Oriented?

Again, not in the strictest sense.

Java heavily uses object-oriented programming:

```text
Classes
Objects
Encapsulation
Inheritance
Polymorphism
Abstraction
```

but Java also has primitives:

```java
int
double
boolean
char
```

Therefore:

> **Java is object-oriented, but not a pure object-oriented language.**

---

# 21. Final Mental Model

Keep these two ideas separate.

## Language design

This answers:

> "How do I structure and express programs?"

Java is primarily:

```text
Object-oriented + imperative + other language features
```

It is not a pure object-oriented language.

---

## Runtime execution

This answers:

> "How does my Java program actually execute?"

The simplified model is:

```text
Java source
     │
     │ javac
     ▼
JVM bytecode
     │
     │
     ├── Interpreter
     │       ↓
     │    executes bytecode
     │
     └── JIT Compiler
             ↓
       native machine code
             ↓
            CPU
```

The JVM can start by interpreting code, observe what is actually being used, and JIT-compile hot code when doing so is worthwhile.

---

# 22. The One Diagram to Remember

```text
                    JAVA PROGRAM

                 Main.java
                     │
                     │ javac
                     ▼
                 Main.class
               JVM BYTECODE
                     │
                     ▼
                    JVM
                     │
              ┌──────┴──────┐
              │             │
              ▼             ▼
         Interpreter       JIT
              │             │
              │             ▼
              │        Machine Code
              │             │
              └──────┬──────┘
                     ▼
                    CPU
```

And the three most important sentences are:

> **`javac` compiles Java source code into JVM bytecode.**

> **The JVM interpreter executes JVM bytecode directly.**

> **The JVM's JIT compiler can compile frequently executed bytecode into native machine code.**

Once you understand those three sentences, the apparent contradiction between **"Java is compiled"** and **"the JVM has an interpreter"** disappears.

---
[ Compiled vs Interpreted Programming Languages | What’s the Difference?](https://www.youtube.com/watch?v=F64_bwahaWQ)





[[Java]]