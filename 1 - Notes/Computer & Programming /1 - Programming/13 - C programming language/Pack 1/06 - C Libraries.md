

# C Libraries — The Big Picture

A library in C is just **precompiled code (`.a` / `.so` / `.lib` / `.dll`) plus header files (`.h`)** that you reuse instead of writing everything from scratch. The header declares *what exists*; the binary provides *the actual machine code*.

## 1. The Standard C Library (libc)

Every conforming C implementation ships one. It's not one monolithic thing — it's a family of headers, each covering a domain:

| Header | Purpose | Key functions |
|--------|---------|---------------|
| `<stdio.h>` | Input/output | `printf`, `scanf`, `fopen`, `fread`, `fprintf` |
| `<stdlib.h>` | General utilities | `malloc`, `free`, `exit`, `atoi`, `qsort`, `rand` |
| `<string.h>` | String & memory | `strlen`, `strcpy`, `strcmp`, `memset`, `memcpy` |
| `<math.h>` | Math | `sqrt`, `pow`, `sin`, `floor` (link with `-lm` on Linux!) |
| `<ctype.h>` | Character classification | `isdigit`, `isspace`, `toupper` |
| `<time.h>` | Date & time | `time`, `clock`, `strftime` |
| `<limits.h>` / `<float.h>` | Implementation limits | `INT_MAX`, `CHAR_BIT` |
| `<stdbool.h>` | Boolean type | `bool`, `true`, `false` |
| `<stdint.h>` | Fixed-width integers | `uint32_t`, `int64_t` |
| `<errno.h>` | Error reporting | `errno`, `perror` |

**Key gotcha:** headers only give you *declarations*. The actual code lives in a binary that the linker must find. On Linux, `gcc main.c -lm` is needed for `<math.h>` because it's a separate library file (`libm.so`), not part of the default libc.

## 2. How the Linker Finds Them

```
gcc main.c -lfoo        → looks for libfoo.so or libfoo.a
gcc main.c -L/path -lfoo → searches /path first
gcc main.c /path/libfoo.a → link a specific file directly
```

- **Static linking (`.a` / `.lib`):** library code is copied *into* your executable. Self-contained, but bigger binaries and no easy updates.
- **Dynamic linking (`.so` / `.dll` / `.dylib`):** your binary stores *references*; the OS loads the library at runtime. Smaller binaries, shared memory across processes, but you depend on the library being present on the target system (the "DLL hell" problem on Windows).

## 3. Popular Third-Party Libraries

- **General purpose:** GLib (data structures, utilities), SQLite (embedded DB), zlib (compression)
- **Networking:** libcurl, OpenSSL
- **Graphics/UI:** SDL, GLFW, GTK, ncurses (terminal UI)
- **JSON:** cJSON, jansson
- **Testing:** Unity, CMocka, Check

## 4. Building Your Own Library

```bash
# Compile with position-independent code (required for shared libs)
gcc -c -fPIC mylib.c -o mylib.o

# Static library
ar rcs libmylib.a mylib.o

# Shared library
gcc -shared mylib.o -o libmylib.so
```

Gotchas worth knowing:
- **Order matters on the linker command line:** libraries must come *after* the objects that use them (`gcc main.o -lmylib`, not the reverse).
- **Header guards / `#pragma once`** keep headers safe to include multiple times.
- When distributing a shared library, the client needs both the `.h` and the `.so`/`.dll`.



[[C]]
[[CS 50]]