

The **Operand Stack** is a fundamental data structure used by the Java Virtual Machine (JVM) during bytecode execution. It's part of each method's **stack frame** and serves as a workspace for executing instructions.

## Key Characteristics

- **LIFO (Last-In-First-Out)** structure
- Stores operands for bytecode instructions
- Each method invocation gets its own operand stack
- Size is determined at compile time (stored in the `max_stack` attribute of the method)
- Stores values of type `int`, `long`, `float`, `double`, `reference`, or `returnAddress`

## Stack Frame Layout

Each method call creates a stack frame containing:

```
┌─────────────────────┐
│   Local Variables   │  ← Parameters + local vars
├─────────────────────┤
│   Operand Stack     │  ← Working area for computation
├─────────────────────┤
│  Frame Data (refs)  │  ← Constant pool ref, return addr
└─────────────────────┘
```

## How It Works — Example

Consider this simple Java code:

```java
int a = 5;
int b = 3;
int c = a + b;
```

The JVM bytecode looks like:

```
iload_1        // push local var 1 (a) onto operand stack
iload_2        // push local var 2 (b) onto operand stack
iadd           // pop two ints, add, push result
istore_3       // pop result into local var 3 (c)
```

**Operand stack evolution:**

| Instruction | Operand Stack (top → bottom) |
|-------------|------------------------------|
| `iload_1`   | `[5]`                        |
| `iload_2`   | `[3, 5]`                     |
| `iadd`      | `[8]`                        |
| `istore_3`  | `[]`                         |

## Common Bytecode Instructions Using It

| Category | Examples | Effect on Stack |
|----------|----------|-----------------|
| Load | `iload`, `aload`, `fload` | Push local variable |
| Store | `istore`, `astore` | Pop into local variable |
| Arithmetic | `iadd`, `isub`, `imul` | Pop 2, push 1 |
| Constants | `iconst_1`, `ldc` | Push constant |
| Method calls | `invokevirtual` | Pop args, push return value |
| Branch | `ifeq`, `if_icmpgt` | Pop for comparison |

## Why It Matters

1. **Stack-based execution model** — Unlike register-based VMs (e.g., Dalvik), the JVM uses a stack, making bytecode compact and portable.
2. **Verification** — The JVM verifier checks that the operand stack never overflows or underflows.
3. **Performance** — Since operands are on a stack, instructions don't need to encode register numbers.

## Example with Method Call

```java
int result = Math.max(10, 20);
```

Bytecode:
```
bipush 10       // stack: [10]
bipush 20       // stack: [20, 10]
invokestatic Math.max:(II)I   // pops 20, 10; pushes 20
istore_1        // store result
```

## Stack Overflow

If a method's operand stack exceeds `max_stack` at runtime, you'd get a `StackOverflowError` — though in practice this is rare because `max_stack` is computed correctly by `javac`.

## Summary

The operand stack is the JVM's per-method scratch pad where bytecode instructions push and pop values during execution. Combined with local variables, it forms the complete execution context for any running Java method.


[[Java]]
