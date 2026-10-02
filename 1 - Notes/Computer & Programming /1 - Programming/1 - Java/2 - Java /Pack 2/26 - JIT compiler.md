

**JIT = Just-In-Time Compiler.**

It is part of the JVM's **Execution Engine**, and its job is to take **JVM bytecode that is being executed at runtime and compile it into native machine code** for the current CPU.

The core idea:

> **Interpreter: execute bytecode directly.**  
> **JIT: compile frequently executed bytecode into native code, then execute that native code directly.**

This is one of the most important ideas in understanding why Java can be both portable and fast.

[Jit compiler](https://www.youtube.com/watch?v=d7KHAVaX_Rs)

---

# 1. Where JIT fits

Our journey is now:

```text
.java
  │
  │ javac
  ▼
.class
  │
  ▼
Class Loader
  │
  ▼
Loading → Linking → Initialization
  │
  ▼
JVM Execution
  │
  ├── Interpreter
  │
  └── JIT Compiler
          │
          ▼
    Native Machine Code
          │
          ▼
         CPU
```

So `javac` and JIT are **two completely different compilation stages**.

### `javac`

Runs **before the program starts**:

```text
Java source
    ↓
javac
    ↓
JVM bytecode
```

### JIT

Runs **while the program is running**:

```text
JVM bytecode
    ↓
JIT
    ↓
native machine code
```

---

# 2. Why do we need JIT?

Because the CPU does not understand JVM bytecode.

Suppose:

```java
static int add(int a, int b) {
    return a + b;
}
```

`javac` might produce bytecode conceptually like:

```text
iload_0
iload_1
iadd
ireturn
```

The interpreter can execute those instructions.

But imagine:

```java
for (int i = 0; i < 1_000_000_000; i++) {
    add(i, 10);
}
```

The same method is being executed **an enormous number of times**.

Instead of repeatedly interpreting:

```text
iload
iload
iadd
ireturn
```

the JVM can notice:

> "This code is executed constantly. It is worth compiling."

The JIT can turn the method into native code suitable for the actual CPU.

Conceptually:

```text
bytecode:

iload_0
iload_1
iadd
ireturn

        ↓ JIT

native CPU code
```

Now future calls can execute the compiled native code directly.

---

# 3. Why is it called "Just-In-Time"?

Because compilation happens **at runtime, shortly before or while the code is needed**.

Compare:

### Traditional ahead-of-time compiler

```text
source
  ↓
compiler
  ↓
machine code
  ↓
run
```

### Java's classic model

```text
source
  ↓
javac
  ↓
bytecode
  ↓
JVM starts
  ↓
interpreter executes
  ↓
JIT notices hot code
  ↓
native compilation
  ↓
CPU executes compiled code
```

The JVM therefore postpones some compilation decisions until it has **runtime information**.

That gives it something a traditional compile-only model doesn't have:

> **It can observe the actual behavior of the running program before deciding how to optimize it.**

---

# 4. The really important part: profiling

The JIT isn't just a dumb:

```text
bytecode → machine code
```

converter.

Modern JVMs **profile the running application**.

The JVM can gather information such as:

```text
How often is this method called?
Which branches are usually taken?
Which classes actually appear here?
Is this code a hot loop?
Are calls usually going to the same implementation?
```

For example:

```java
void process(User user) {
    user.save();
}
```

At compile time, the JVM may not know exactly which implementation of `save()` will usually be used.

But during execution, suppose it observes:

```text
process() called 10 million times

9,999,500 times:
    UserImpl.save()
```

That runtime information can help the JIT make aggressive optimizations.

This is called **profile-guided optimization**, and it is a major reason JIT compilation can be powerful.

---

# 5. Hot code

The JVM pays special attention to **hot code**.

"Hot" basically means:

> **code that executes frequently enough to justify optimization/compilation.**

For example:

```java
for (int i = 0; i < 1_000_000_000; i++) {
    calculate(i);
}
```

`calculate()` is likely to become hot.

Conceptually:

```text
calculate()
   │
   ├── executed 1 time
   ├── executed 10 times
   ├── executed 1,000 times
   ├── executed 100,000 times
   └── executed millions of times
                 ↓
              HOT
                 ↓
              JIT
```

Not every method needs to go through expensive optimization.

A method called once doesn't offer much opportunity to amortize compilation cost.

---

# 6. Interpreter → JIT

This is the basic runtime story:

```text
                 Bytecode
                    │
                    ▼
               Interpreter
                    │
                    │ execute + profile
                    ▼
              Is code hot?
                 /      \
               No        Yes
               │          │
               │          ▼
               │         JIT
               │          │
               │          ▼
               │    Native machine code
               │          │
               └──────────┴──────► CPU
```

So the interpreter is not necessarily something the JIT replaces immediately.

They cooperate.

---

# 7. JIT doesn't usually compile everything immediately

This is an important nuance.

Imagine your application has:

```text
10,000 methods
```

It would be wasteful to compile all 10,000 methods immediately, because many might rarely execute.

Instead, the JVM can start execution relatively quickly and compile important code progressively.

That's one reason the JVM uses **adaptive compilation**.

The runtime continuously learns:

```text
Which code matters?
Which code is worth optimizing?
What assumptions appear to be valid?
```

Then it invests optimization effort where it matters.

---

# 8. HotSpot and tiered compilation

Since you're learning modern Java/JVM internals, you'll encounter **HotSpot**.

HotSpot has historically used multiple compilation levels, commonly described using **tiered compilation**.

A simplified mental model:

```text
Bytecode
   │
   ▼
Interpreter
   │
   ▼
C1 compiler
   │
   ▼
C2 compiler
```

Very roughly:

### C1

The **client compiler**.

Typically aims for relatively fast compilation with useful optimizations.

### C2

The more aggressive optimizing compiler.

It can spend more time analyzing hot code and applying deeper optimizations.

So conceptually:

```text
Cold code
   ↓
Interpreter

Warm code
   ↓
C1

Very hot code
   ↓
C2
```

This is simplified—the actual tiering logic is more nuanced.

---

# 9. JIT can optimize Java code in ways `javac` can't

This is probably the most important reason JIT exists.

Suppose:

```java
interface Payment {
    void pay();
}
```

and:

```java
Payment payment = new CreditCardPayment();

payment.pay();
```

At the source level:

```text
Payment
   ↓
interface call
```

There could theoretically be many implementations:

```text
Payment
├── CreditCardPayment
├── PaypalPayment
├── CryptoPayment
└── ...
```

But suppose the running application shows:

```text
payment.pay()
```

is effectively always:

```text
CreditCardPayment
```

The JIT can use that runtime information when optimizing.

This can enable optimizations such as **speculative optimization** and **devirtualization**.

Conceptually:

```text
Before:

payment.pay()
    ↓
"Which implementation?"
    ↓
dynamic dispatch


After JIT optimization:

payment.pay()
    ↓
likely CreditCardPayment.pay()
```

But the JVM must preserve Java semantics if its assumption becomes false.

That leads to one of the coolest JIT concepts:

# Deoptimization

Suppose the JIT makes an assumption:

```text
"This call always receives CreditCardPayment."
```

Then later:

```java
Payment payment = new PaypalPayment();
payment.pay();
```

The assumption is no longer valid.

The JVM can **deoptimize** the compiled code and return execution to a safer representation, often interpreted/recompiled code.

Conceptually:

```text
Bytecode
   ↓
JIT compilation
   ↓
Optimized native code
   ↓
assumption becomes invalid
   ↓
DEOPTIMIZE
   ↓
back to JVM-managed execution
```

This is possible because the JIT is part of the JVM runtime and understands the semantics of the bytecode.

---

# 10. JIT can do much more than simply translate instructions

A naïve model would be:

```text
bytecode → equivalent machine instructions
```

But a JIT can perform optimizations.

Examples include:

### Method inlining

Instead of:

```java
int result = add(10, 20);
```

with a method call:

```text
caller
   ↓
add()
   ↓
return
```

the JIT may inline the method:

```text
caller
   ↓
10 + 20
```

Conceptually eliminating the method-call overhead.

---

### Dead-code elimination

If code can be proven to have no observable effect:

```java
int x = 10;
int y = 20;
int z = x + y;

return 5;
```

the JIT may eliminate work whose result is never needed.

---

### Loop optimizations

Hot loops are especially interesting:

```java
for (int i = 0; i < array.length; i++) {
    sum += array[i];
}
```

The JIT can apply sophisticated loop optimizations depending on what it can prove about the program.

---

### Escape analysis

This one becomes especially relevant to your Heap/GC studies.

Suppose:

```java
void test() {
    Point p = new Point(10, 20);
    System.out.println(p.x);
}
```

The JIT can analyze whether `p` **escapes** the method/thread.

If it can prove that the object doesn't need normal Heap allocation, certain optimizations may be possible.

This doesn't mean:

> "Java objects normally go on the stack."

That's a bad rule.

The JVM specification says objects are allocated in the Heap; JIT optimizations can eliminate an allocation or replace its representation when semantics allow it.

---

# 11. Where does the generated native code go?

This connects back to memory.

The JIT generates machine code and stores it in a JVM-managed area commonly referred to as the **Code Cache** in HotSpot.

Conceptually:

```text
JVM Process

Heap
├── Java objects

Method Area / class metadata
├── class information
└── runtime constant pool

JVM Stacks
├── stack frames

Code Cache
├── JIT-compiled native code
```

Notice something important:

> **JIT-generated machine code is not simply another Java object sitting in the Heap.**

The JVM manages it separately as executable code memory.

---

# 12. A complete example

Consider:

```java
public class Main {

    static int square(int x) {
        return x * x;
    }

    public static void main(String[] args) {
        long sum = 0;

        for (int i = 0; i < 1_000_000_000; i++) {
            sum += square(i);
        }

        System.out.println(sum);
    }
}
```

The journey is roughly:

```text
Main.java
   │
   │ javac
   ▼
Main.class
   │
   ▼
Class Loader
   │
   ▼
JVM
   │
   ▼
Interpreter starts executing bytecode
   │
   │
   ├── executes main()
   ├── executes square()
   ├── profiles execution
   └── notices square()/loop are hot
                    │
                    ▼
                  JIT
                    │
                    ▼
           optimized native code
                    │
                    ▼
                   CPU
```

And now the CPU may execute optimized native instructions instead of repeatedly interpreting the original bytecode.

---

# 13. Why not just compile everything with JIT immediately?

Because compilation itself costs:

```text
CPU time
Memory
Compilation analysis
Optimization work
```

Imagine:

```java
void methodA() {}   // called once
void methodB() {}   // called once
void methodC() {}   // called 500 million times
```

Spending enormous optimization effort on `methodA()` would be wasteful.

The JVM wants to balance:

```text
startup speed
      ↕
runtime performance
      ↕
compilation cost
      ↕
memory usage
```

That's why the JVM doesn't treat all methods identically.

---

# 14. Interpreter vs JIT

|Interpreter|JIT Compiler|
|---|---|
|Executes bytecode directly|Compiles bytecode to native code|
|Usually good for quick startup|Better for hot long-running code|
|Executes repeatedly|Compiled code can execute repeatedly|
|Little upfront compilation work|Compilation itself costs CPU/time|
|Works directly from bytecode|Produces machine code|
|Helps gather runtime profiling data|Uses profiling data for optimization|

The relationship is:

```text
Interpreter
   │
   │ execute + observe
   ▼
Profiling information
   │
   ▼
JIT
   │
   ▼
Native optimized code
```

---

# 15. The deeper JVM mental model

You can now visualize the Execution Engine like this:

```text
                       .class
                         │
                         ▼
                      Bytecode
                         │
             ┌───────────┴───────────┐
             │                       │
             ▼                       ▼
        Interpreter               Profiling
             │                       │
             └───────────┬───────────┘
                         ▼
                    Hot code?
                         │
                         ▼
                   JIT Compiler
                         │
             ┌───────────┴───────────┐
             │                       │
             ▼                       ▼
        Optimization          Native code
                                     │
                                     ▼
                                    CPU
```

And the really important conceptual distinction is:

```text
javac:
"Convert Java source into a portable JVM representation."

Interpreter:
"Execute that JVM representation."

JIT:
"Use runtime knowledge to compile frequently executed JVM
code into optimized native code for this machine."
```

That is the **JVM's fundamental execution strategy**: start from portable bytecode, observe the real workload, and optimize the parts that actually matter.


[[Java]]