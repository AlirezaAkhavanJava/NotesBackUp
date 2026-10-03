
In Java, an **exception table** is a piece of information stored inside a method's **bytecode** that tells the JVM **what to do when an exception occurs**.

It's closely related to `try-catch`.

### Simple example

```java
public static void main(String[] args) {
    try {
        int x = 10 / 0;
    } catch (ArithmeticException e) {
        System.out.println("Cannot divide by zero");
    }
}
```

Conceptually, the JVM needs to know:

```text
Exception occurs inside this range
            ↓
    Is it ArithmeticException?
            ↓
           YES
            ↓
Jump to the catch block
```

The **exception table** contains information that allows the JVM to make this decision.

Conceptually, it looks something like:

|Try range|Exception type|Handler|
|---|---|---|
|bytecode 0 → 10|`ArithmeticException`|bytecode 15|

Meaning:

> "If an `ArithmeticException` happens while executing bytecode instructions 0 through 10, jump to instruction 15."

### Where is the exception table?

When Java code is compiled:

```text
.java
  ↓
javac
  ↓
.class
  ↓
JVM bytecode
```

The `.class` file contains a method's bytecode and metadata, including its **exception table**.

It is **not a Java object** that you normally interact with in your code.

### How does this relate to `try-catch`?

Your code:

```java
try {
    riskyOperation();
} catch (IOException e) {
    handleException();
}
```

is compiled into bytecode where the JVM has information approximately like:

```text
Exception Table

Start     End       Handler     Type
---------------------------------------------
tryStart  tryEnd    catchBlock  IOException
```

If an exception occurs inside the protected range, the JVM searches the exception table for a matching handler.

### Important distinction

Don't confuse an **exception table** with a **stack trace**.

```text
Exception Table
    ↓
JVM mechanism for finding a catch handler

Stack Trace
    ↓
Information showing where the exception traveled through method calls
```

And this connects directly to what we discussed earlier:

```text
Exception occurs
       ↓
JVM looks for a matching handler
       ↓
Exception table
       ↓
catch block found?
    ↙       ↘
  YES        NO
   ↓          ↓
catch      propagate
             ↓
        caller's frame
             ↓
        caller's handler
```

That last part—**propagating the exception up the call stack**—is a very important concept to understand next.


[[Java]]