**C** is a low-level, compiled programming language that gives you direct control over memory and the machine. It is small, extremely fast, and the foundation under most of the software you use, including Linux, Debian, databases, and the JVM that runs your Java.

**Analogy:** Java is driving an automatic car with airbags, lane assist, and a parking sensor. C is a manual car with no safety systems: you control the engine directly, it is as fast as you can drive it, and if you make a mistake, nothing stops you from crashing.

## Core idea

C does very little for you, and that is the point. There are no classes, no garbage collector, no built-in collections, and no exceptions. What you get is:

- Variables, functions, and control flow
- **Pointers**: direct access to memory addresses
- **Manual memory management**: you ask for memory and you must give it back

Your code compiles straight to **machine code** for your CPU. There is no JVM or interpreter in between, which connects to the history lesson: C sits just above assembly.

```
Java:  source -> bytecode -> JVM (interpreted/JIT) -> CPU
C:     source -> machine code -> CPU
```

## A first program on Debian 13

```bash
sudo apt install build-essential    # installs gcc, make, and more
```

```c
#include <stdio.h>

int main(void) {
    printf("Hello, C!\n");
    return 0;
}
```

```bash
gcc hello.c -o hello    # compile
./hello                 # run
```

Unlike Java, the output is a native executable for your OS and CPU. A binary built on Debian won't run on Windows, so the "write once, run anywhere" promise of Java does not apply.

## The compile pipeline

1. **Preprocessor:** handles `#include` and `#define` (text substitution).
2. **Compiler:** turns C into assembly, then into object code.
3. **Linker:** joins your object code with libraries into one executable.

This is why you see errors named "linker error": a different stage failed.

## Pointers: the heart of C

Every variable lives at a **memory address**. A pointer is a variable that stores an address.

```c
int x = 42;
int *p = &x;      // p holds the ADDRESS of x
printf("%d\n", *p);   // *p follows the address: prints 42
*p = 100;         // changes x through the pointer
```

- `&x` means "address of x"
- `*p` means "the thing p points to"

Mental model: memory is a long street of numbered houses. `x` is what's inside a house, and `p` is a note with the house number written on it.

Java has this too, hidden: object variables are **references**, which are safe, managed pointers. In C there are no guard rails: you can do arithmetic on pointers and point anywhere.

## Memory: stack and heap

```c
#include <stdlib.h>

int main(void) {
    int a = 5;                          // stack: automatic, freed at function end
    int *arr = malloc(10 * sizeof(int)); // heap: you asked for it, you must free it
    arr[0] = 1;
    free(arr);                           // give it back
    return 0;
}
```

In Java, `new` allocates and the **garbage collector** cleans up. In C, every `malloc` needs a matching `free`.

## Strings are just arrays

C has no `String` type. A string is an array of `char` ending with a zero byte `'\0'`.

```c
char name[] = "Ali";   // stored as 'A' 'l' 'i' '\0'
```

Forgetting the terminator, or writing past the end of the array, is a classic bug.

## Where C is used

- **Operating systems:** the Linux kernel, and much of Debian's core tools (`ls`, `grep`, `bash`)
- **Embedded systems:** microcontrollers, cars, routers, devices with tiny memory
- **Databases:** SQLite and PostgreSQL are written in C, as is MySQL's core (with C++)
- **Language runtimes:** Python's main interpreter is written in C; the JVM is mostly C++
- **Performance-critical code:** game engines, drivers, networking software

So the databases you just studied are C programs. Your Spring Boot app is ultimately running on C code all the way down.

## C vs Java

||C|Java|
|---|---|---|
|**Memory**|Manual (`malloc`/`free`)|Automatic (garbage collector)|
|**Paradigm**|Procedural|Object-oriented|
|**Runs on**|Directly on the CPU|The JVM|
|**Safety**|None: crashes or corrupts silently|Checks bounds, throws exceptions|
|**Speed**|Maximum, predictable|Fast, with GC pauses and warm-up|
|**Portability**|Recompile per platform|Same bytecode everywhere|
|**Best for**|Systems, hardware, performance|Business applications, back-ends|

## Should you learn it?

You don't need C to build Spring Boot apps. But learning even the basics teaches you what the higher layers hide: how memory really works, why the garbage collector exists, what a reference is, and why Java's design decisions (bounds checking, no pointer arithmetic) exist. Many people also meet C through CS50, which you've already used for SQLite.

## Gotchas

- **Undefined behavior:** reading outside an array, using freed memory, or an uninitialized variable doesn't always crash. It may appear to work, then fail randomly. This is the hardest part of C.
- **Buffer overflows:** writing past the end of an array is the root cause of a large share of historical security vulnerabilities. Many security bugs in old software trace back to this.
- **Memory leaks:** forgetting `free` makes the program grow until it dies. A tool called **Valgrind** (`sudo apt install valgrind`) detects these on Debian.
- **Dangling pointers:** using a pointer after `free` is a bug. Setting it to `NULL` after freeing helps.
- **C is not C++:** C++ is a separate, much larger language built on top of C that adds classes and more. They look similar but are used differently.
- **Compile with warnings:** `gcc -Wall -Wextra -g hello.c -o hello` catches many mistakes before they bite.



[[Computer & Programming]]