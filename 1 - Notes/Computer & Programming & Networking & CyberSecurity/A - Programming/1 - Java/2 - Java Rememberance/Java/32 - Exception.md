

## What an exception is

An **exception** is an object representing an error or unexpected condition that disrupts a program's normal flow. When something goes wrong — a file doesn't exist, you divide by zero, you access an invalid array index — Java doesn't just crash silently or return a garbage value. It creates an **exception object** describing what went wrong and hands control to code designed to deal with it.

```java
int[] numbers = {1, 2, 3};
System.out.println(numbers[5]); // throws ArrayIndexOutOfBoundsException
```

---

## The problem exceptions solve

### Without exceptions — the old way (still used in C)

In languages without exceptions (like C), error handling relies on **return codes**:

```c
FILE *fp = fopen("file.txt", "r");
if (fp == NULL) {
    // caller must remember to check this, every single time
    printf("Error opening file\n");
    return -1;
}
```

This has real problems:

- **Easy to forget.** Nothing forces you to check the return value — ignore it, and the error silently propagates as garbage data.
- **Error handling and normal logic get tangled together.** Every single call needs an `if` check right after it, cluttering the actual logic.
- **No structured information.** A return code like `-1` tells you _that_ something failed, not _what_ failed or _why_.

### With exceptions — Java's way

```java
try {
    FileInputStream in = new FileInputStream("file.txt");
} catch (FileNotFoundException e) {
    System.out.println("Error: " + e.getMessage());
}
```

Exceptions solve this by:

1. **Separating the "happy path" from error handling** — your main logic reads top-to-bottom without `if (failed)` checks after every line.
2. **Making errors impossible to silently ignore** (for checked exceptions — more below) — the compiler forces you to acknowledge them.
3. **Carrying rich information** — an exception object has a message, a type (telling you exactly _what kind_ of failure occurred), and a **stack trace** (the exact chain of method calls that led to the failure).
4. **Automatically propagating up** through multiple method calls until something handles it, without every intermediate method needing to manually check and forward an error code.

---

## The exception class hierarchy

Every exception in Java is a class, and they all descend from `Throwable`:

```
Throwable
├── Error                    (serious JVM-level problems — don't catch these)
│   ├── OutOfMemoryError
│   └── StackOverflowError
└── Exception
    ├── IOException            ─┐
    ├── SQLException            │  Checked exceptions
    ├── ClassNotFoundException ─┘
    └── RuntimeException        ─┐
        ├── NullPointerException │
        ├── ArrayIndexOutOfBoundsException │  Unchecked exceptions
        ├── ArithmeticException  │
        └── IllegalArgumentException ─┘
```

- **`Error`** — represents problems so severe your program generally can't recover (running out of memory, stack overflow from infinite recursion). You don't catch these in normal code.
- **`Exception`** — represents recoverable problems your code is expected to handle. This branch splits into two very different categories:

---

## Checked vs. unchecked exceptions

This is the most important distinction in Java's exception system.

![[Pasted image 20260912124946.png]]

### Checked exceptions — the compiler forces you to deal with them

Any exception that is **not** a `RuntimeException` (and not an `Error`) is "checked." The compiler **will not let your code compile** unless you either catch it or declare that your method might throw it.

```java
// This method reads a file — remember, FileInputStream can fail if the file doesn't exist
void readFile() throws IOException {   // must declare it...
    FileInputStream in = new FileInputStream("data.txt");
}

// ...or catch it directly
void readFile() {
    try {
        FileInputStream in = new FileInputStream("data.txt");
    } catch (IOException e) {          // ...or handle it here
        System.out.println("Failed to read file");
    }
}
```

**Why checked exceptions exist:** for conditions that are _expected to happen sometimes_ in normal operation (a file might legitimately not exist, a network connection might legitimately drop) — Java forces you to consciously decide how to handle that possibility, rather than letting it be an afterthought.

This connects directly to what we covered with I/O: that's exactly why every stream operation we wrote (`new FileInputStream(...)`, `in.read()`) needed a `try` block or a `throws` declaration — `IOException` is checked.

### Unchecked exceptions — the compiler doesn't force anything

`RuntimeException` and its subclasses are "unchecked" — you're **not required** to catch or declare them.

```java
void divide(int a, int b) {
    System.out.println(a / b); // no try/catch required — but ArithmeticException CAN still happen
}
```

**Why unchecked exceptions exist:** for conditions that usually represent **programming bugs**, not expected real-world scenarios — a null pointer, an invalid array index, dividing by zero. Forcing a `try/catch` around every single arithmetic operation or object access would make code unreadably defensive. Instead, the philosophy is: _fix the bug that causes it_, rather than catch it everywhere.

### Side-by-side comparison

||Checked|Unchecked|
|---|---|---|
|Extends|`Exception` (not `RuntimeException`)|`RuntimeException`|
|Compiler enforces handling?|Yes — must catch or declare `throws`|No|
|Represents|Expected, recoverable external conditions (file missing, network down)|Programming errors/bugs (null access, bad index, bad argument)|
|Examples|`IOException`, `SQLException`|`NullPointerException`, `ArithmeticException`, `IllegalArgumentException`|

---

## The mechanics: try, catch, finally, throw, throws

```java
public void process(String path) throws IOException {  // "throws" — declares this method might fail this way
    FileInputStream in = null;
    try {
        in = new FileInputStream(path);       // risky code goes here
        // ... process file ...
    } catch (FileNotFoundException e) {       // catches ONE specific exception type
        System.out.println("File not found: " + e.getMessage());
    } catch (IOException e) {                 // catches a broader category
        System.out.println("I/O error: " + e.getMessage());
    } finally {
        // ALWAYS runs — whether an exception happened or not, even if you `return` inside try/catch
        if (in != null) {
            try { in.close(); } catch (IOException e) { /* ignore close failure */ }
        }
    }
}
```

(As covered earlier, **try-with-resources** replaces most manual `finally`-based cleanup for anything `Closeable` — this manual version is shown here just to make `finally`'s behavior explicit.)

```java
throw new IllegalArgumentException("Age cannot be negative"); // manually creating and throwing one
```

- **`try`** — wraps code that might fail
- **`catch`** — handles a specific exception type if it occurs (you can have multiple `catch` blocks, checked most-specific first)
- **`finally`** — runs regardless of outcome (cleanup code)
- **`throw`** — used inside your code to manually raise an exception
- **`throws`** — used in a method signature to declare "calling me might result in this exception"

---

## Custom exceptions

You're not limited to JDK-provided exceptions — you can define your own by extending `Exception` (checked) or `RuntimeException` (unchecked):

```java
// Custom checked exception — caller must handle it
class InsufficientFundsException extends Exception {
    public InsufficientFundsException(String message) {
        super(message);
    }
}

class Account {
    private double balance;

    void withdraw(double amount) throws InsufficientFundsException {
        if (amount > balance) {
            throw new InsufficientFundsException("Not enough balance for this withdrawal");
        }
        balance -= amount;
    }
}
```

**Why create your own:** generic exceptions (`Exception`, `RuntimeException`) don't tell the caller anything specific about _your_ domain's failure modes. A custom `InsufficientFundsException` is self-documenting and lets calling code catch _that specific problem_ separately from, say, a database error.

```java
try {
    account.withdraw(500);
} catch (InsufficientFundsException e) {
    System.out.println("Transaction failed: " + e.getMessage());
}
```

---

## Where this connects to what we've already covered

- Every I/O example we wrote (`FileInputStream`, `ObjectInputStream.readObject()`) throws checked exceptions (`IOException`, `ClassNotFoundException`) — that's _why_ they needed `try-with-resources` blocks.
- `Comparable.compareTo()`, functional interfaces like `Function`, don't declare checked exceptions in their signatures — which is exactly why we hit the compile error earlier trying to use `Files::readString` (which throws `IOException`) as a plain `Function`.

---

## Summary table

|Concept|Purpose|
|---|---|
|`Throwable`|root of everything that can be thrown|
|`Error`|severe, unrecoverable JVM problems — don't catch|
|`Exception`|recoverable problems — the branch you work with|
|Checked exception|compiler-enforced handling — for expected external failures|
|Unchecked (`RuntimeException`)|not enforced — usually signals a bug to fix, not to catch|
|`try` / `catch`|isolate risky code, handle specific failure types|
|`finally`|guaranteed cleanup code|
|`throw`|manually raise an exception|
|`throws`|declare a method might raise a checked exception|
|Custom exception|domain-specific, self-documenting failure types|

[[Java]]