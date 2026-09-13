
# `main` in C — Defined

`main` is the **entry point** of a C program — the function the operating system calls when your program starts. It's not special because of a keyword; it's special because the **C runtime startup code** (part of libc, `crt0`) calls it by name after the OS loads your executable.

---

## 1. The Signature(s)

The C standard allows **two portable forms**:

```c
int main(void) { ... }                          // no command-line arguments
int main(int argc, char *argv[]) { ... }        // with arguments
```

And an equivalent third form for the second one:

```c
int main(int argc, char **argv) { ... }         // same as char *argv[]
```

**Rules:**
- **Return type must be `int`.** `void main()` is *not* standard C — some compilers accept it, but it's undefined behavior per the standard.
- **`argc`** = argument count (always ≥ 1; it counts the program name itself).
- **`argv`** = argument vector; array of strings (`char *`), with `argv[argc] == NULL` guaranteed.
- You may also see `char *envp[]` as a third parameter — that's a common (POSIX-ish) extension, **not** part of ISO C.

---

## 2. What the Parameters Mean

If you run:

```bash
./myprog hello world
```

Then:

| Variable | Value |
|---|---|
| `argc` | `3` |
| `argv[0]` | `"./myprog"` (program name) |
| `argv[1]` | `"hello"` |
| `argv[2]` | `"world"` |
| `argv[3]` | `NULL` |

```c
#include <stdio.h>

int main(int argc, char *argv[]) {
    for (int i = 0; i < argc; i++) {
        printf("argv[%d] = %s\n", i, argv[i]);
    }
    return 0;
}
```

**Java comparison (just for anchoring):** this is roughly Java's `public static void main(String[] args)` — except:
- In C, `argv[0]` is the **program name** (Java's `args` does *not* include it).
- In C, `args` is `char **`, not a managed `String[]`. You parse numbers yourself with `atoi`, `strtol`, etc.

---

## 3. Return Value — the Exit Status

`main` returns an `int` to the **operating system**. Convention:

- **`0`** (or `EXIT_SUCCESS` from `<stdlib.h>`) = success
- **Non-zero** (often `EXIT_FAILURE`, or `1`) = failure

```c
#include <stdlib.h>

int main(void) {
    if (something_failed) return EXIT_FAILURE;
    return EXIT_SUCCESS;
}
```

You can also exit from anywhere with:

```c
exit(0);      // runs atexit handlers, flushes stdio buffers
```

**Special rule:** If `main` reaches the closing `}` without a `return`, C99+ says it implicitly returns `0`. This is the *only* function in C with that privilege.

You can check the exit status in a shell:

```bash
./myprog
echo $?        # prints the exit status
```

---

## 4. What Happens *Before* `main` Runs

This is the part Java devs usually don't think about:

1. **OS loads the executable** into memory.
2. **Loader** sets up the process (stack, heap region, environment).
3. **C runtime startup code** (`crt0` / `_start`) runs — this is *not* your code; the linker inserts it.
4. Startup code:
   - Initializes `argc` / `argv` from the OS-provided stack layout.
   - Sets up the environment (`environ`).
   - Runs **static/global initializers** (C has no constructors, but globals can have constant initializers).
   - Calls **`main(argc, argv)`**.
5. When `main` returns, startup code calls **`exit()`**, which:
   - Runs functions registered with `atexit()`.
   - Flushes and closes all open stdio streams.
   - Passes `main`'s return value to the OS as the exit status.

So `main` is *not* truly the first thing to run — it's the first thing **you** write that runs.

---

## 5. What `main` Is *Not*

- **Not a method** — there are no classes in C; `main` is a free function.
- **Not overloadable** — you can't have two `main`s.
- **Not callable from your own code in a meaningful way** — you *can* call `main()` recursively (it's just a function), but it's terrible style and rarely done.
- **Not required to take arguments** — `int main(void)` is perfectly valid.
- **Not `void`-returning in standard C** — `void main()` is a Microsoft-ism / old K&R habit, not ISO C.

---

## 6. Minimal Complete Program

```c
int main(void) {
    return 0;
}
```

That's a valid, standards-conforming C program. No imports, no classes, no JVM — just a function the runtime calls.

---

## 7. Definition (One Sentence)

> **`main` is the standard entry-point function of a C program — declared as `int main(void)` or `int main(int argc, char *argv[])` — that the C runtime startup code calls after the OS loads the executable, and whose `int` return value becomes the process's exit status.**

**Mental model for a Java dev:** think of `main` as the C equivalent of `public static void main(String[] args)`, except:
- it's a plain free function (no class wrapper),
- its return value is a real OS exit code (`0` = success),
- `argv[0]` is the program name,
- strings are raw `char *`, not managed `String` objects,
- and there's a whole startup/teardown layer (`crt0` → `main` → `exit`) around it that the JVM normally hides from you.

[[0 - What C is]]