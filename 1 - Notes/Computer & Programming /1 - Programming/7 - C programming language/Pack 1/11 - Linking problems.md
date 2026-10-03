
# Linking Problems and Compiling with Special Libraries in C

This becomes much easier once you separate **compilation** from **linking**.

When you write:

```c
#include <math.h>

int main(void)
{
    double x = sqrt(25.0);
}
```

there are actually several stages involved.

```text
source.c
   │
   │ preprocessing
   ▼
expanded source
   │
   │ compilation
   ▼
object file (.o)
   │
   │ linking
   ▼
executable
```

The important point is:

> **`#include` tells the compiler about declarations. Linking provides the actual compiled implementation.**

---

## 1. What is a library?

A library is reusable code that your program can use instead of implementing everything yourself.

For example, C's standard library provides functions such as:

```c
printf()
fopen()
strlen()
malloc()
```

Other libraries provide additional functionality.

For example:

```text
libm  → mathematics
libpthread → threading on some Unix systems
libssl → TLS/cryptography
libcurl → HTTP/network transfers
```

On Linux, libraries commonly exist as:

```text
static libraries
    libsomething.a

shared libraries
    libsomething.so
```

---

# 2. Header files vs libraries

This distinction is extremely important.

Suppose:

```c
#include <math.h>
```

`math.h` is a **header file**.

It provides declarations such as:

```c
double sqrt(double);
```

It does **not** contain the compiled implementation of `sqrt()` in the normal sense.

The actual implementation is provided by a library.

Conceptually:

```text
math.h
   │
   │ declaration
   ▼
compiler knows:
sqrt() exists
   │
   ▼
libm
   │
   │ implementation
   ▼
actual sqrt() code
```

---

# 3. Compilation problem vs linking problem

Consider:

```c
#include <math.h>

int main(void)
{
    double x = sqrt(25.0);
    return 0;
}
```

You might compile:

```bash
gcc main.c
```

Depending on the compiler/toolchain and platform, you may get something like:

```text
undefined reference to `sqrt'
```

This is a **linking error**.

The compiler understood:

```c
sqrt(25.0)
```

because you included:

```c
#include <math.h>
```

But the linker couldn't find the implementation of `sqrt()`.

---

# 4. Linking the math library

On Linux, traditionally:

```bash
gcc main.c -lm
```

The:

```text
-l
```

option means:

> Link against a library.

Therefore:

```bash
-lm
```

means approximately:

```text
link against libm
```

The library name:

```text
libm.so
```

or:

```text
libm.a
```

becomes:

```bash
-lm
```

The `lib` prefix and `.so`/`.a` suffix are conventionally omitted.

---

# 5. Why does the linker exist?

Imagine your program uses:

```c
printf()
sqrt()
strlen()
```

Your source code doesn't necessarily contain the machine code implementing those functions.

Instead:

```text
main.c
 │
 ├── printf()
 ├── sqrt()
 └── strlen()
```

The compiler generates code containing references to those functions.

The linker then resolves those references:

```text
main.o
 │
 ├── printf() ──────► libc
 ├── sqrt() ────────► libm
 └── strlen() ──────► libc
                         │
                         ▼
                    executable
```

---

# 6. What does "undefined reference" mean?

Suppose you see:

```text
/usr/bin/ld: undefined reference to `sqrt'
collect2: error: ld returned 1 exit status
```

The important part is:

```text
undefined reference
```

It generally means:

> The compiler accepted the reference, but the linker could not find a definition for the referenced symbol.

This is fundamentally different from:

```text
fatal error: math.h: No such file or directory
```

The latter is generally a **compilation/preprocessing** problem.

So:

```text
math.h not found
        ↓
compiler/header problem

undefined reference to sqrt
        ↓
linker/library problem
```

---

# 7. Static vs shared libraries

Linux commonly uses two major library forms.

### Static

```text
libfoo.a
```

The linker can copy required object code into your executable.

Conceptually:

```text
program.o + libfoo.a
       │
       ▼
   executable
```

The resulting executable contains the linked code from the static library.

---

### Shared

```text
libfoo.so
```

The executable can instead contain references to a shared library that is loaded at runtime.

Conceptually:

```text
executable
    │
    └──────► libfoo.so
                  │
                  ▼
             loaded at runtime
```

This reduces duplication when many programs use the same library.

---

# 8. Finding libraries on Debian

You can inspect libraries installed on your system.

For example:

```bash
ldconfig -p | grep libm
```

You may see something similar to:

```text
libm.so.6 (libc6,x86-64) => /lib/x86_64-linux-gnu/libm.so.6
```

You can also use:

```bash
find /usr/lib /lib -name 'libm.so*' 2>/dev/null
```

For development, packages often contain both headers and linker files.

For example, a library might provide:

```text
/usr/include/foo.h
/usr/lib/x86_64-linux-gnu/libfoo.so
```

---

# 9. `-I` vs `-L` vs `-l`

These three options are extremely important.

### `-I`

Tell the compiler where to search for headers:

```bash
gcc main.c -I/path/to/include
```

Example:

```bash
gcc main.c -I/home/alireza/libs/foo/include
```

This affects:

```c
#include <foo.h>
```

---

### `-L`

Tell the linker where to search for libraries:

```bash
gcc main.c -L/path/to/lib
```

For example:

```bash
gcc main.c -L/home/alireza/libs/foo/lib -lfoo
```

---

### `-l`

Tell the linker which library to use:

```bash
-lfoo
```

The linker searches for something like:

```text
libfoo.so
libfoo.a
```

So:

```bash
-lfoo
```

corresponds conceptually to:

```text
libfoo.so / libfoo.a
```

---

# 10. Putting them together

Suppose you have:

```text
myproject/
├── main.c
└── libs/
    ├── include/
    │   └── foo.h
    └── lib/
        └── libfoo.so
```

You could compile with:

```bash
gcc main.c \
    -I./libs/include \
    -L./libs/lib \
    -lfoo \
    -o app
```

Meaning:

```text
-I./libs/include
        ↓
where are the headers?

-L./libs/lib
        ↓
where are the libraries?

-lfoo
        ↓
which library?

-o app
        ↓
what should the executable be called?
```

---

# 11. Library order matters

This is a classic linking issue.

Suppose:

```bash
gcc main.c -lm
```

works.

Generally prefer:

```bash
gcc main.c -lm
```

rather than:

```bash
gcc -lm main.c
```

because traditional Unix linkers process libraries largely **left-to-right**.

Think:

```text
main.o
  │
  │ needs sqrt()
  ▼
libm
  │
  └── provides sqrt()
```

So the object needing the symbol normally comes before the library providing it.

For multiple libraries:

```bash
gcc main.o -lfoo -lbar
```

if `foo` depends on `bar`.

The order can matter.

---

# 12. Compile and link separately

You can explicitly see the stages.

First:

```bash
gcc -c main.c -o main.o
```

This creates:

```text
main.o
```

No final executable is produced.

Then:

```bash
gcc main.o -lm -o app
```

Now the linker creates:

```text
app
```

So:

```text
main.c
  │
  │ gcc -c
  ▼
main.o
  │
  │ gcc + libraries
  ▼
app
```

This is extremely useful when debugging build problems.

---

# 13. `gcc` is more than a compiler

When you run:

```bash
gcc main.c -lm -o app
```

GCC is acting as a **driver** coordinating several tools:

```text
gcc
 │
 ├── preprocessor
 │
 ├── compiler
 │
 ├── assembler
 │
 └── linker
```

You can inspect what commands GCC actually executes:

```bash
gcc -v main.c -lm -o app
```

or:

```bash
gcc -### main.c -lm -o app
```

This is a great way to start understanding what is actually happening underneath the build command.

---

# 14. Runtime linking problems

You can successfully compile and link an application and still have a problem when executing it.

For example:

```text
error while loading shared libraries:
libfoo.so: cannot open shared object file
```

This is no longer a compilation or normal link-time problem.

It is a **runtime dynamic linking** problem.

The chain becomes:

```text
Source
  ↓
Preprocessing
  ↓
Compilation
  ↓
Assembly
  ↓
Linking
  ↓
Executable
  ↓
Dynamic loader
  ↓
Shared libraries loaded
  ↓
Program runs
```

Linux's dynamic linker/loader is responsible for resolving shared-library dependencies when the program starts, and sometimes during execution.

You can inspect an executable's shared-library dependencies with:

```bash
ldd ./app
```

For example:

```text
linux-vdso.so.1
libc.so.6
libm.so.6
...
```

---

# 15. The three problems you should distinguish

When working with external libraries, think in three layers:

```text
                 LIBRARY PROBLEM
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
   Header problem   Link problem   Runtime problem
        │              │              │
   foo.h missing   undefined       libfoo.so
                   reference       not found
        │              │              │
       -I             -L/-l       loader config
```

### Example

```text
fatal error: foo.h: No such file
```

→ header/include problem.

```text
undefined reference to `foo'
```

→ link problem.

```text
error while loading shared libraries: libfoo.so
```

→ runtime shared-library problem.

---

# 16. The deeper mental model

When you use an external C library:

```c
#include <foo.h>

int main(void)
{
    foo();
}
```

there are actually **three separate relationships**:

```text
             foo.h
               │
               │ declaration
               ▼
           COMPILER
               │
               │ generates reference
               ▼
             main.o
               │
               │ unresolved symbol: foo
               ▼
            LINKER
               │
               │ finds implementation
               ▼
           libfoo.so
               │
               │ runtime dependency
               ▼
        DYNAMIC LOADER
               │
               ▼
            PROGRAM
```

This distinction is foundational for C, Linux, GCC, Make, CMake, and eventually systems programming.

### Core commands to remember

```bash
gcc main.c -o app
gcc main.c -lm -o app

gcc -I/path/to/include ...
gcc -L/path/to/lib -lfoo ...

ldd ./app
ldconfig -p
```

The key principle is:

> **Headers tell the compiler what exists; libraries provide the compiled implementations; the linker connects your program to those implementations; the dynamic loader handles shared libraries at runtime.**


[[CS 50]]
[[C]]