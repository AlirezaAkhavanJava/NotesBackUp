

Here's a comprehensive guide to working with C from the command line.

## 1. Basic Compilation with GCC

```bash
# Compile a single file to executable (default name: a.out)
gcc program.c

# Compile with a custom output name
gcc program.c -o program

# Compile and run
gcc program.c -o program && ./program
```

## 2. Clang (Alternative Compiler)

```bash
clang program.c -o program
clang -Wall -Wextra program.c -o program
```

## 3. Common GCC Flags

| Flag | Purpose |
|------|---------|
| `-o <name>` | Output file name |
| `-Wall` | Enable all common warnings |
| `-Wextra` | Extra warnings |
| `-Werror` | Treat warnings as errors |
| `-g` | Include debug info (for GDB) |
| `-O0/-O1/-O2/-O3` | Optimization levels |
| `-std=c99` / `-std=c11` / `-std=c17` | C standard version |
| `-pedantic` | Strict standard compliance |
| `-I<dir>` | Add include directory |
| `-L<dir>` | Add library directory |
| `-l<name>` | Link a library (e.g., `-lm` for math) |
| `-D<macro>` | Define a preprocessor macro |
| `-c` | Compile only (produce `.o`, no link) |
| `-S` | Produce assembly (`.s`) |
| `-E` | Run preprocessor only |
| `-v` | Verbose output |

**Recommended strict build:**
```bash
gcc -Wall -Wextra -Werror -pedantic -std=c17 -g program.c -o program
```

## 4. Multi-File Compilation

```bash
# Compile each file to object files
gcc -c file1.c -o file1.o
gcc -c file2.c -o file2.o

# Link object files together
gcc file1.o file2.o -o program

# Or all in one step
gcc file1.c file2.c main.c -o program

# Using a header (main.c includes mylib.h)
gcc main.c mylib.c -o program -I./include
```

## 5. Make (Build Automation)

**Makefile example:**
```makefile
CC = gcc
CFLAGS = -Wall -Wextra -std=c17 -g
TARGET = program
SRCS = main.c file1.c file2.c
OBJS = $(SRCS:.c=.o)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: clean
```

**Commands:**
```bash
make              # Build default target
make program      # Build specific target
make clean        # Run clean rule
make -j4          # Parallel build (4 jobs)
make -n           # Dry run (show commands)
```

## 6. Running & Debugging

```bash
./program                    # Run executable
./program arg1 arg2          # Run with arguments
echo $?                      # Check exit code (0 = success)

# GDB debugging
gdb ./program                # Start debugger
# Inside gdb:
#   break main       - set breakpoint
#   run              - start program
#   next (n)         - step over
#   step (s)         - step into
#   print var        - inspect variable
#   backtrace (bt)   - show call stack
#   quit (q)         - exit
```

## 7. Inspecting Binaries

```bash
file program             # Identify file type
ldd program              # Show shared library dependencies
nm program               # List symbols
objdump -d program       # Disassemble
size program             # Show section sizes
readelf -h program       # ELF header info
strings program          # Extract printable strings
```

## 8. Memory & Error Tools

```bash
# Valgrind (memory leaks, invalid access)
valgrind --leak-check=full ./program

# AddressSanitizer (compile-time instrumentation)
gcc -fsanitize=address -g program.c -o program
./program

# Static analysis
cppcheck program.c
clang-tidy program.c
gcc -fanalyzer -c program.c
```

## 9. Preprocessing & Assembly Views

```bash
gcc -E program.c                 # Show preprocessor output
gcc -S program.c                 # Generate assembly (program.s)
gcc -c program.c                 # Generate object file (program.o)
```

## 10. Libraries

```bash
# Static library
gcc -c mylib.c -o mylib.o
ar rcs libmylib.a mylib.o
gcc main.c -L. -lmylib -o program

# Shared library
gcc -fPIC -c mylib.c -o mylib.o
gcc -shared -o libmylib.so mylib.o
gcc main.c -L. -lmylib -o program
LD_LIBRARY_PATH=. ./program
```

## 11. Quick Reference: Typical Workflow

```bash
# 1. Write code
vim main.c

# 2. Compile with warnings
gcc -Wall -Wextra -g main.c -o main

# 3. Run
./main

# 4. Debug if needed
valgrind ./main
gdb ./main
```



[[0 - What C is]]