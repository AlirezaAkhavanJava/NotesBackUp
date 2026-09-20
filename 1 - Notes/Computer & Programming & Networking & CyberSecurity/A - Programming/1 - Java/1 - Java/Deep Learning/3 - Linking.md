
### JVM Linking Phase Explained

The **Linking** phase is the **second major phase** of the JVM class loading process (after **Loading** and before **Initialization**).

It takes a class that has already been **loaded** (i.e., its `.class` file has been read and a `Class` object created in memory) and prepares it for use by making sure it is **correct**, **safe**, and **ready** to be initialized.

Linking consists of **three sub-phases**:

| Sub-phase          | Description                                                                 | When it happens                          | Mandatory?       |
|--------------------|-----------------------------------------------------------------------------|------------------------------------------|------------------|
| **1. Verification**    | Checks that the bytecode is correct and safe to run                          | Immediately after loading                | Always required  |
| **2. Preparation**     | Allocates memory for static fields and sets default values                  | After verification                       | Always required  |
| **3. Resolution**      | Converts symbolic references to direct references (e.g., class/method names to actual memory addresses) | Can happen lazily (during execution)     | Optional / lazy  |

### Detailed Breakdown of Each Sub-phase

#### 1. Verification
- **Purpose**: Ensure the bytecode is valid, follows Java language rules, and does not violate security constraints.
- **Checks performed** (non-exhaustive list):
  - Class file format is correct (magic number `CAFEBABE`, correct version, etc.)
  - All methods have valid bytecode instructions
  - No stack overflow/underflow
  - All references (fields, methods, classes) point to valid entries in the constant pool
  - Access control rules are respected (e.g., no private method called from outside)
  - No illegal operations (e.g., calling a method on `null`)
- **Who does it?**: The JVM itself (usually via the `java.lang.ClassLoader`’s internal verifier)
- **When?**: Almost always during linking (can be deferred in some cases, but rare)
- **Outcome if it fails**: `java.lang.VerifyError` is thrown

#### 2. Preparation
- **Purpose**: Allocate storage for **static variables** (class variables) and assign them their **default values**.
- **What happens**:
  - Memory is allocated in the **Method Area** (Metaspace since Java 8) for all `static` fields.
  - Each field is set to its **default value** (not the value in the source code, but the JVM default):
    
    | Type           | Default value |
    |----------------|---------------|
    | `byte`, `short`, `int`, `long` | 0 / 0L        |
    | `float`, `double` | 0.0f / 0.0    |
    | `char`         | ``      |
    | `boolean`      | `false`       |
    | Reference types (`Object`, arrays, etc.) | `null` |

- **Important**: This is **not** where static initializers (`static { ... }`) or explicit field initializers (`static int x = 10;`) are executed — that happens in **Initialization**.
- **Outcome**: All static fields are allocated and set to their zero/null defaults.

#### 3. Resolution (Optional / Lazy)
- **Purpose**: Convert **symbolic references** in the constant pool to **direct references** (actual memory addresses).
- **Symbolic reference examples**:
  - `CONSTANT_Class_info` → reference to another class
  - `CONSTANT_Fieldref_info` → reference to a field
  - `CONSTANT_Methodref_info` → reference to a method
- **How it works**:
  - JVM looks up the referenced class/method/field.
  - If the target class is not yet loaded, it triggers loading (recursively).
  - Replaces the symbolic reference with a **direct pointer** (e.g., memory address or offset).
- **Lazy resolution** (most common):
  - Resolution is usually deferred until the symbolic reference is **first used** (e.g., when a method is invoked or a field is accessed).
  - This is called **lazy resolution** and improves startup time.
- **Eager resolution** (rare):
  - Some JVMs may resolve everything upfront, but it’s not required by the JVM spec.
- **Outcome if it fails**: `LinkageError` (e.g., `NoSuchMethodError`, `NoSuchFieldError`, `ClassNotFoundException`, etc.)

### Summary Table: Linking Sub-phases

| Sub-phase       | What it does                                      | Mandatory? | Can throw errors? | When executed?             |
|-----------------|---------------------------------------------------|------------|-------------------|----------------------------|
| **Verification** | Checks bytecode correctness and security          | Yes        | Yes (`VerifyError`) | During linking             |
| **Preparation**  | Allocates static fields, sets default values      | Yes        | No                | During linking             |
| **Resolution**   | Resolves symbolic → direct references             | Optional (lazy) | Yes (`LinkageError`) | Usually lazily, on first use |

### Key Takeaways
- Linking happens **after Loading** but **before Initialization**.
- **Verification** and **Preparation** are mandatory and happen during linking.
- **Resolution** is often **lazy** — the JVM delays it until the reference is actually needed (better performance).
- If any part of linking fails, the class cannot be used, and an appropriate error is thrown.

### Order of Operations (full class loading)

1. **Loading** → Read `.class` file, create `Class` object  
2. **Linking** → Verify → Prepare → (Resolve lazily)  
3. **Initialization** → Run static initializers and blocks

So, **Linking** ensures that a loaded class is **verified, prepared, and (eventually) fully resolved** — making it safe and ready for initialization and execution.

##### Tags : [[Java]]