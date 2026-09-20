C is best defined as a **procedural, imperative, statically typed, compiled, low-level (but portable) systems programming language**. Here's the breakdown of the key terms, parallel to how you'd describe Java:

## Core Classification

| Aspect | C |
|---|---|
| **Paradigm** | Procedural / imperative (not OOP) |
| **Typing** | Statically typed, weakly typed (implicit conversions allowed) |
| **Execution model** | Compiled directly to native machine code |
| **Level** | Low-level / mid-level (close to hardware, but portable) |
| **Memory management** | Manual (`malloc`/`free`, pointers) |

## The "Engine" Equivalent

Unlike Java's JVM, C has **no virtual machine**. The toolchain is:

- **Compiler** (e.g., GCC, Clang, MSVC) → translates C to assembly/machine code
- **Assembler** → produces object files
- **Linker** → combines object files + libraries into a native executable
- **C Standard Library (libc)** → provides `printf`, `malloc`, string functions, etc.

So the "runtime" is essentially **the OS + libc**, not a managed environment.

## Defining Characteristics

1. **Procedural** – programs are organized as functions operating on data, not objects.
2. **Imperative** – you describe *how* to do things step by step.
3. **Statically typed** – types are known at compile time, but conversions are permissive.
4. **Compiled & native** – no bytecode, no interpreter, no JIT.
5. **Low-level access** – pointers, direct memory manipulation, bitwise ops.
6. **Minimal runtime** – almost no runtime overhead; "what you write is what runs."
7. **Portable** – the same source compiles on many platforms (the original point of C).
8. **Small language, huge ecosystem** – few keywords (~32), but vast libraries and use cases.
9. **Undefined behavior exists** – the standard leaves many things unspecified, giving compilers freedom and programmers rope to hang themselves.
10. **No built-in safety** – no bounds checking, no garbage collection, no exceptions.

## One-Sentence Definition

> **C is a general-purpose, procedural, statically typed, compiled language that provides low-level memory access with high portability, designed for systems programming.**

## Contrast With Java (Quick)

| | C | Java |
|---|---|---|
| Paradigm | Procedural | OOP |
| Execution | Native machine code | JVM bytecode |
| Memory | Manual | Garbage collected |
| Safety | Low (UB, pointers) | High (managed) |
| Portability | Recompile per platform | "Write once, run anywhere" |
| Runtime | libc + OS | JVM |

So while Java is defined by its **VM and OOP model**, C is defined by its **directness to the machine and procedural simplicity**.

[[CS 50]]