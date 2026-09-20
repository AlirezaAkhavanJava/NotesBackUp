# Headers in C — Defined

A **header** is a file (conventionally `.h`) that gets **textually pasted** into a `.c` file by the preprocessor via `#include`. It's how C shares declarations (function prototypes, types, macros, constants) across multiple source files — because C has no modules, no packages, and no class files.

**Java anchor:** a header is the closest thing C has to an **interface**, but it's purely textual, has zero enforcement from the language, and can contain much more than declarations (macros, inline functions, even full definitions).

---

## 1. What a Header Actually Is

A header is just a text file. Nothing more. When you write:

```c
#include "myheader.h"
```

the **preprocessor** literally copies the entire contents of `myheader.h` into your `.c` file *before* compilation. The compiler never sees `#include` — it sees the already-expanded text.

```c
// Before preprocessing
#include <stdio.h>
int main(void) { printf("hi\n"); }

// After preprocessing (conceptually)
// ... thousands of lines from stdio.h pasted here ...
int main(void) { printf("hi\n"); }
```

You can see the result yourself:

```bash
gcc -E main.c        # prints the fully preprocessed translation unit
```

So a header is not a compiled unit — it's a **textual fragment** meant to be included.

---

## 2. The Two Forms of `#include`

```c
#include <stdio.h>      // angle brackets: search SYSTEM include paths
#include "myheader.h"   // quotes: search the CURRENT directory first, then system paths
```

| Form | Search order | Use for |
|---|---|---|
| `<...>` | System/compiler include dirs (`/usr/include`, `-I` paths) | Standard library, third-party libs |
| `"..."` | Current file's dir first, then system paths | Your own project headers |

Both ultimately do the same thing — paste the file. The difference is only **where the preprocessor looks first**.

You control the search path with:

```bash
gcc -I./include -I/opt/foo/include main.c -o app
```

---

## 3. What Goes in a Header

A header typically contains **declarations** — things the compiler needs to know exist, without providing the actual implementation:

### Function prototypes (declarations, not definitions)
```c
int add(int a, int b);              // "this function exists somewhere"
void point_move(Point *p, int dx, int dy);
```

### Type definitions
```c
typedef struct Point Point;         // opaque forward declaration
struct Point { int x, y; };         // full definition
typedef enum { RED, GREEN, BLUE } Color;
typedef unsigned long u64;
```

### Macros and constants
```c
#define MAX_BUFFER 1024
#define SQUARE(x) ((x) * (x))
#define MIN(a, b) ((a) < (b) ? (a) : (b))
```

### Global variable declarations (via `extern`)
```c
extern int global_counter;          // "defined in some .c file"
```

### `static inline` functions (full definitions in the header)
```c
static inline int max(int a, int b) { return a > b ? a : b; }
```

### Other headers
```c
#include <stddef.h>                 // headers can include headers
```

**What should NOT go in a header (usually):** function *definitions* (non-inline), global variable *definitions*, anything that would be duplicated across translation units and cause multiple-definition link errors.

---

## 4. Declaration vs Definition — the Core Distinction

This is the concept headers exist to manage.

| | Declaration | Definition |
|---|---|---|
| **Tells the compiler** | "This exists, here's its type/signature" | "Here's the actual code/storage" |
| **Can appear** | Many times (in many headers/files) | **Exactly once** across the whole program |
| **Example** | `int add(int, int);` | `int add(int a, int b) { return a+b; }` |
| **Example** | `extern int counter;` | `int counter = 0;` |
| **Example** | `struct Point;` | `struct Point { int x, y; };` |

**The rule:** declare in headers, define in `.c` files. The linker then matches declarations to definitions.

Java anchor: this is like `interface Foo` (declaration) vs `class FooImpl implements Foo` (definition) — except C enforces it at **link time**, not compile time, and there's no `implements` keyword tying them together. The linker just looks for a symbol named `add` and fails with `undefined reference` if it can't find one.

---

## 5. The Header / Source Split

The canonical C module structure:

```
project/
├── point.h        ← declarations (the "interface")
├── point.c        ← definitions (the "implementation")
├── main.c         ← uses point.h
└── Makefile
```

**`point.h`**
```c
#ifndef POINT_H
#define POINT_H

typedef struct Point Point;

Point *point_create(int x, int y);
void   point_move(Point *p, int dx, int dy);
int    point_sum(const Point *p);
void   point_destroy(Point *p);

#endif
```

**`point.c`**
```c
#include "point.h"
#include <stdlib.h>

struct Point { int x, y; };        // full definition, hidden from users

Point *point_create(int x, int y) {
    Point *p = malloc(sizeof *p);
    if (p) { p->x = x; p->y = y; }
    return p;
}

void point_move(Point *p, int dx, int dy) { p->x += dx; p->y += dy; }
int  point_sum(const Point *p)            { return p->x + p->y; }
void point_destroy(Point *p)              { free(p); }
```

**`main.c`**
```c
#include "point.h"     // only needs the declarations

int main(void) {
    Point *p = point_create(1, 2);
    point_move(p, 3, 4);
    point_destroy(p);
    return 0;
}
```

**Build:**
```bash
gcc -c point.c -o point.o
gcc -c main.c  -o main.o
gcc point.o main.o -o app
```

**Key idea:** `main.c` includes `point.h` and sees only the *declarations*. It has no idea what `struct Point` actually contains — that's in `point.c`. This is **encapsulation by convention**, not by language. It's the C way of hiding implementation details, and it's the closest thing to Java's `private`.

---

## 6. Include Guards — the Mandatory Idiom

Because headers get pasted, and headers include other headers, the same header can be included multiple times in one translation unit. Without protection, you'd get **redefinition errors** (e.g., defining `struct Point` twice).

**The guard:**

```c
#ifndef POINT_H
#define POINT_H

/* contents of the header */

#endif
```

How it works:
1. First inclusion: `POINT_H` is not defined → `#define` it → contents are pasted.
2. Second inclusion: `POINT_H` **is** defined → the whole block is skipped.

**The modern alternative — `#pragma once`:**

```c
#pragma once

/* contents of the header */
```

- Simpler, supported by GCC, Clang, MSVC, and virtually every modern compiler.
- **Not** in the ISO C standard, but universally supported in practice.
- Slightly faster, no name-collision risk.

**Use one or the other. Most projects use include guards for portability, or `#pragma once` for brevity.**

---

## 7. What Can Go Wrong (the classic header pitfalls)

### Multiple definition errors
Defining a function or global variable in a header, then including it in two `.c` files → the linker sees two copies → error.

```c
// BAD: in myheader.h
int counter = 0;                    // definition — duplicated in every includer
int add(int a, int b) { return a+b; }  // definition — same problem

// GOOD:
extern int counter;                 // declaration
int add(int a, int b);              // prototype
```

### Missing include guards
Header gets included twice → redefinition errors.

### Circular includes
`a.h` includes `b.h` includes `a.h` → unless guarded, infinite paste (guards usually break the cycle, but the resulting declarations may be incomplete).

### Leaking implementation details
Putting `struct Point { int x, y; };` in the header exposes the internals. Better: forward-declare `typedef struct Point Point;` in the header, define the struct only in the `.c`. This is the **opaque pointer** / **opaque struct** idiom — C's version of a private class.

```c
// header: opaque
typedef struct Point Point;         // users can only hold pointers to it

// source: full definition hidden
struct Point { int x, y; };
```

### Header ordering dependencies
A header that uses `size_t` without including `<stddef.h>` forces every includer to include `<stddef.h>` first. **Rule: every header should be self-contained** — include what it needs.

---

## 8. The Standard Library Headers

C ships with a set of standard headers — the C equivalent of `java.lang`, `java.util`, etc.:

| Header | Provides | Java-ish analog |
|---|---|---|
| `<stdio.h>` | `printf`, `fopen`, `FILE` | `java.io`, `System.out` |
| `<stdlib.h>` | `malloc`, `free`, `exit`, `atoi` | parts of `java.lang` |
| `<string.h>` | `strlen`, `strcpy`, `memcpy` | `java.lang.String` methods (as functions) |
| `<math.h>` | `sqrt`, `sin`, `pow` | `java.lang.Math` |
| `<stddef.h>` | `size_t`, `NULL`, `offsetof` | — |
| `<stdint.h>` | `int32_t`, `uint64_t` | fixed-width primitives |
| `<stdbool.h>` | `bool`, `true`, `false` (C99) | `boolean` |
| `<ctype.h>` | `isdigit`, `toupper` | `Character` |
| `<time.h>` | `time`, `clock`, `struct tm` | `java.time` |
| `<errno.h>` | `errno`, error codes | exceptions-ish |
| `<assert.h>` | `assert` | `assert` keyword |
| `<stdarg.h>` | `va_list` for varargs | varargs |
| `<limits.h>` | `INT_MAX`, `CHAR_BIT` | `Integer.MAX_VALUE` |
| `<signal.h>` | signal handling | — |
| `<setjmp.h>` | `setjmp`/`longjmp` | crude exceptions |

Include them with angle brackets:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
```

---

## 9. Headers vs Java — the Mental Map

| Java | C |
|---|---|
| `interface Foo` | `foo.h` (declarations) |
| `class FooImpl implements Foo` | `foo.c` (definitions) |
| `import foo.Bar;` | `#include "bar.h"` |
| Package | Directory + naming convention + `-I` flags |
| `public` / `private` | Header exposes; `.c` hides (convention + opaque structs) |
| Compiler enforces interface match | **Linker** enforces it (undefined reference) |
| `javac` checks everything | Compiler checks declarations; linker resolves symbols |
| Modules (Java 9+) | Headers + include guards |

**The big difference:** Java's compiler validates that `FooImpl` actually implements `Foo`. C's compiler does **not** validate that `point.c` provides everything `point.h` promises — you find out at **link time**, when the linker complains about an undefined symbol. And it never checks that a function's definition *matches* its prototype beyond signature compatibility — it's all textual and symbol-based.

---

## 10. Definition (One Sentence)

> **A header is a `.h` file that the C preprocessor textually pastes into a source file via `#include`, used to share declarations (function prototypes, types, macros, constants) across translation units — C's textual, linker-enforced substitute for interfaces and modules.**

**Mental model for a Java dev:** a header is a hand-written `interface` file that the compiler never validates against its implementation; the linker does the matching by symbol name, and `#include` is a literal copy-paste, not a smart import. Include guards (`#ifndef`/`#define`/`#endif` or `#pragma once`) are mandatory to prevent duplicate pasting, and the header/source split (`foo.h` / `foo.c`) is how C separates interface from implementation.

[[0 - What C is]]