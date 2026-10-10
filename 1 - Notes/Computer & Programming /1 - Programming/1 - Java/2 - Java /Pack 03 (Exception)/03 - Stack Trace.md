
A **stack trace** is a report that shows **the sequence of method calls that were active when an exception or error occurred**.

Think of it as a **history of how the program got to the point where it failed**.

### Example

Suppose you have:

```java
public static void main(String[] args) {
    methodA();
}

static void methodA() {
    methodB();
}

static void methodB() {
    int x = 10 / 0;
}
```

Java produces something like:

```text
Exception in thread "main" java.lang.ArithmeticException: / by zero
    at Main.methodB(Main.java:12)
    at Main.methodA(Main.java:8)
    at Main.main(Main.java:4)
```

This is the **stack trace**.

### How to read it

Look at the first line:

```text
java.lang.ArithmeticException: / by zero
```

This tells you **what happened**.

Then:

```text
at Main.methodB(Main.java:12)
```

This tells you **where it happened**:

```text
Main.java
line 12
methodB()
```

Then:

```text
at Main.methodA(Main.java:8)
at Main.main(Main.java:4)
```

This tells you **how you got there**:

```text
main()
   ↓
methodA()
   ↓
methodB()
   ↓
ERROR
```

### Call Stack vs Stack Trace

These two concepts are closely related but aren't the same:

**Call stack** = the runtime structure tracking active method calls.

```text
main()
  ↓
methodA()
  ↓
methodB()
```

**Stack trace** = a **record/report of that call stack**, usually produced when an exception or error occurs.

```text
at Main.methodB(Main.java:12)
at Main.methodA(Main.java:8)
at Main.main(Main.java:4)
```

So an easy way to remember it:

> **Call stack = what's currently happening inside the JVM.**  
> **Stack trace = a report showing the path of method calls.**

And when you're debugging Java/Spring Boot applications, you'll see stack traces **all the time**. Learning to read them is one of the most important debugging skills.


[[Exception]]
[[Java]]