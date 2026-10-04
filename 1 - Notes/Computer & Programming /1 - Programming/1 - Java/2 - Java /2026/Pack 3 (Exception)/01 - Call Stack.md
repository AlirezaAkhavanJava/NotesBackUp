

Java has a hierarchy called **`Throwable`**, and it has two main branches:

```text
Throwable
├── Exception
│   ├── RuntimeException
│   └── other Exceptions
│
└── Error
    ├── OutOfMemoryError
    ├── StackOverflowError
    └── ...
```

### 1. `Exception`

An **Exception** represents a problem that an application can often **handle or recover from**.

For example:

```java
try {
    int result = 10 / 0;
} catch (ArithmeticException e) {
    System.out.println("Cannot divide by zero");
}
```

Common exceptions:

- `IOException`
    
- `SQLException`
    
- `NullPointerException`
    
- `ArithmeticException`
    
- `ArrayIndexOutOfBoundsException`
    

Exceptions are further divided into:

**Checked exceptions**

```java
IOException
SQLException
```

**Unchecked exceptions**

```java
RuntimeException
NullPointerException
ArithmeticException
```

---

### 2. `Error`

An **Error** generally represents a serious problem related to the **JVM or runtime environment**, rather than a normal application problem.

For example:

```java
public static void recursive() {
    recursive();
}
```

Eventually:

```text
StackOverflowError
```

Another example:

```text
OutOfMemoryError
```

You generally **don't try to recover from an `Error`** in normal application code.

---

### Important terminology

So instead of saying:

> "Java has two types of errors: Exception and Error"

I'd recommend saying:

> **"`Throwable` has two main subclasses: `Exception` and `Error`."**

Because technically, **`Error` is itself a type of `Throwable`**, while "error" in the general programming sense can refer to many kinds of problems.

And there's another important category: **compile-time errors**. For example:

```java
int x = "hello";
```

This doesn't produce a Java `Exception` or `Error` at runtime. The compiler rejects it before the program runs.



---
A **call stack** is a data structure the JVM uses to keep track of **which methods are currently running and where they should return**.

Think of it like a **stack of plates**: the last method called is the first one that finishes.

### Example

```java
public static void main(String[] args) {
    methodA();
}

static void methodA() {
    methodB();
}

static void methodB() {
    System.out.println("Hello");
}
```

When this runs, the call stack looks roughly like:

```text
┌─────────────────────┐
│ methodB()           │ ← currently running
├─────────────────────┤
│ methodA()           │
├─────────────────────┤
│ main()              │
└─────────────────────┘
```

The execution happens like this:

```text
main()
  ↓
methodA()
  ↓
methodB()
```

When `methodB()` finishes, it is removed from the stack:

```text
methodA()
  ↓
main()
```

Then `methodA()` finishes:

```text
main()
```

Then `main()` finishes and the program ends.

### What is stored in the call stack?

Each method call gets a **stack frame**. A frame contains information needed for that method's execution, such as:

- Local variables
    
- Method parameters
    
- Where the method should return
    
- Some JVM execution information
    

For example:

```java
static void methodB() {
    int x = 10;
    int y = 20;
}
```

While `methodB()` is running, its frame contains information associated with `x`, `y`, and the method's execution.

### Why does this matter for `StackOverflowError`?

Remember the `Error` we discussed:

```text
StackOverflowError
```

Consider:

```java
static void test() {
    test();
}
```

You get:

```text
test()
test()
test()
test()
test()
...
```

Every call creates another stack frame:

```text
┌──────────────┐
│ test()       │
├──────────────┤
│ test()       │
├──────────────┤
│ test()       │
├──────────────┤
│ test()       │
├──────────────┤
│ test()       │
├──────────────┤
│ ...          │
└──────────────┘
```

Eventually the JVM runs out of space allocated for the thread's stack and throws:

```text
java.lang.StackOverflowError
```

So the connection is:

**Method call → stack frame → call stack → too many frames → `StackOverflowError`**

This is also why a Java stack trace is so useful: it shows you the **chain of method calls that led to the problem**.


[[Exception]]
[[Java]]