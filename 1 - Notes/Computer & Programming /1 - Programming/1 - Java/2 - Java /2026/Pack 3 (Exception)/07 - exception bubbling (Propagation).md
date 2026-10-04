

Think of **exception propagation** as one of the fundamental mechanisms of Java's exception-handling system.

### Definition

> **Exception propagation is the process by which an exception that is not handled in the method where it occurs is automatically passed to the caller of that method, and then potentially to the caller's caller, until a matching exception handler is found or the exception reaches the top of the call stack.**

In simpler terms:

> **If a method doesn't handle an exception, Java gives the exception to the method that called it.**

---

### Consider this example

```java
public void top() {
    second();
}

public void second() {
    theLast();
}

public void theLast() {
    throw new IllegalArgumentException("Something went wrong");
}
```

The call chain is:

```text
main()
  ↓
top()
  ↓
second()
  ↓
theLast()
```

The exception occurs here:

```text
theLast()
    ↓
  THROW 
```

`theLast()` has no `catch`, so Java **propagates** the exception to `second()`.

```text
theLast()
    │
    │ exception not handled
    ▼
second()
```

If `second()` doesn't handle it either:

```text
theLast()
    ↓
second()
    ↓
top()
```

And if `top()` doesn't handle it:

```text
theLast()
    ↓
second()
    ↓
top()
    ↓
main()
```

If `main()` doesn't handle it either, the exception eventually reaches the JVM's uncaught-exception handling mechanism.

---

### Why do we call it "bubbling"?

The informal term **exception bubbling** comes from the idea that the exception moves upward through the call hierarchy:

```text
          main()
            ↑
          top()
            ↑
        second()
            ↑
        theLast()
            
```

The exception starts **deep inside the call stack** and moves upward looking for a handler.

However, **"exception propagation" is the more formal and preferred term** when discussing Java.

---

### What happens at each level?

Suppose:

```java
public void second() {
    theLast();
}
```

There is no `try-catch`.

When `theLast()` throws:

```text
1. Exception is thrown
2. JVM searches theLast() for a matching handler
3. No handler is found
4. theLast()'s stack frame is unwound
5. JVM moves to second()
6. JVM searches second() for a matching handler
7. No handler is found
8. second()'s frame is unwound
9. JVM moves to top()
10. Search continues...
```

So **propagation and stack unwinding work together**.

### The key distinction

Don't think:

> "The exception is physically passed as an object from one method to another."

Instead, think:

> **The JVM searches upward through the call stack for a method that has a matching exception handler.**

That's the important mental model.

```text
Exception thrown
       ↓
Find handler in current method
       ↓
     Found?
    ↙      ↘
  YES       NO
   ↓         ↓
handle    unwind frame
             ↓
       caller's method
             ↓
       search again
```

And this is exactly why the **exception table** you asked about earlier matters: at each method/frame, the JVM uses the method's exception-handling information to determine whether there is a suitable handler.


[[Exception]]
[[Java]]