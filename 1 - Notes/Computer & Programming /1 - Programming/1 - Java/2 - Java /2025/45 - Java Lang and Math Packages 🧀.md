# Java Lang and Math Packages (`java.lang` and `java.math`)

The **Java `lang`** (`java.lang`) and **Java `math`** (`java.math`) packages provide foundational and mathematical utilities for Java applications. The `java.lang` package contains core classes and interfaces automatically imported into every Java program, offering essential functionality like object handling, strings, threading, and exceptions. The `java.math` package provides classes for high-precision arithmetic and advanced mathematical operations. Both packages are critical for general-purpose programming and numerical computations.

## 1. Java Lang Package (`java.lang`)

### Overview

- **Purpose**: Provides fundamental classes and interfaces for Java’s core functionality, automatically imported into every program.
- **Key Features**:
    - Core classes for objects, strings, numbers, and threads.
    - Exception and error handling.
    - Runtime and system utilities.
- **Use Cases**: Object manipulation, string processing, thread management, and system interactions.

### Key Interfaces

#### 1. **Comparable**

- **Purpose**: Defines a natural ordering for objects.
- **Key Method**:
    - `int compareTo(T o)`: Compares this object with another, returning negative, zero, or positive for less than, equal to, or greater than.
- **Use Case**: Sorting objects in collections (e.g., `Collections.sort`).
- **Example**:

```java
class Person implements Comparable<Person> {
    String name;
    Person(String name) { this.name = name; }
    @Override
    public int compareTo(Person other) {
        return this.name.compareTo(other.name);
    }
}
```

#### 2. **Runnable**

- **Purpose**: Represents a task that can be executed by a thread.
- **Key Method**:
    - `void run()`: Contains the task’s logic.
- **Use Case**: Creating threads or tasks for executors.
- **Example**:

```java
Runnable task = () -> System.out.println("Running task");
new Thread(task).start();
```

#### 3. **AutoCloseable**

- **Purpose**: Enables objects to be used in try-with-resources for automatic resource management.
- **Key Method**:
    - `void close()`: Closes the resource.
- **Use Case**: Managing resources like files or sockets.
- **Example**:

```java
try (AutoCloseable resource = () -> System.out.println("Closing")) {
    System.out.println("Using resource");
}
```

### Key Classes

#### 1. **Object**

- **Purpose**: The root class for all Java objects.
- **Key Methods**:
    - `equals(Object obj)`: Checks object equality.
    - `hashCode()`: Returns a hash code for the object.
    - `toString()`: Returns a string representation.
    - `getClass()`: Returns the runtime class.
    - `wait()` / `notify()` / `notifyAll()`: Thread synchronization methods.
- **Use Case**: Base for all classes, used for equality checks and synchronization.
- **Example**:

```java
Object obj = new Object();
System.out.println(obj.toString()); // Output: java.lang.Object@<hashcode>
```

#### 2. **String**

- **Purpose**: Represents an immutable sequence of characters.
- **Key Methods**:
    - `length()`: Returns the string length.
    - `charAt(int index)`: Returns the character at the specified index.
    - `substring(int beginIndex)`: Returns a substring.
    - `equalsIgnoreCase(String another)`: Compares strings case-insensitively.
    - `split(String regex)`: Splits the string into an array.
    - `replace(CharSequence target, CharSequence replacement)`: Replaces substrings.
- **Use Case**: Text manipulation and processing.
- **Example**:

```java
String str = "Hello, World";
System.out.println(str.substring(0, 5)); // Output: Hello
```

#### 3. **StringBuilder** / **StringBuffer**

- **Purpose**: Mutable sequences of characters (`StringBuilder` is non-synchronized, `StringBuffer` is thread-safe).
- **Key Methods**:
    - `append(String str)`: Appends data to the sequence.
    - `insert(int offset, String str)`: Inserts data at a position.
    - `delete(int start, int end)`: Deletes a subsequence.
    - `toString()`: Converts to a `String`.
- **Use Case**: Efficient string manipulation.
- **Example**:

```java
StringBuilder sb = new StringBuilder("Hello");
sb.append(", World");
System.out.println(sb); // Output: Hello, World
```

#### 4. **Thread**

- **Purpose**: Represents a thread of execution.
- **Key Methods**:
    - `start()`: Starts the thread.
    - `run()`: Contains the thread’s logic.
    - `sleep(long millis)`: Pauses the thread.
    - `interrupt()`: Interrupts the thread.
    - `join()`: Waits for the thread to complete.
- **Use Case**: Multithreaded programming.
- **Example**:

```java
Thread thread = new Thread(() -> System.out.println("Thread running"));
thread.start();
```

#### 5. **Class**

- **Purpose**: Represents the runtime class of an object.
- **Key Methods**:
    - `getName()`: Returns the class name.
    - `getSuperclass()`: Returns the superclass.
    - `getMethods()`: Returns an array of methods.
- **Use Case**: Reflection and runtime type information.
- **Example**:

```java
Class<?> clazz = String.class;
System.out.println(clazz.getName()); // Output: java.lang.String
```

#### 6. **System**

- **Purpose**: Provides system-level operations and utilities.
- **Key Methods**:
    - `currentTimeMillis()`: Returns the current time in milliseconds.
    - `nanoTime()`: Returns the current time in nanoseconds.
    - `getProperty(String key)`: Gets a system property.
    - `exit(int status)`: Terminates the JVM.
    - `out` / `err`: Standard output and error streams (`PrintStream`).
- **Use Case**: Accessing system resources and environment.
- **Example**:

```java
System.out.println("Hello"); // Output to console
long time = System.currentTimeMillis();
```

### Utility Classes

#### 1. **Math**

- **Purpose**: Provides static methods for common mathematical operations.
- **Key Methods**: (Covered in `java.math` section below, as `Math` is in `java.lang` but serves mathematical purposes.)

#### 2. **Runtime**

- **Purpose**: Provides access to the JVM runtime environment.
- **Key Methods**:
    - `getRuntime()`: Returns the singleton `Runtime` instance.
    - `exec(String command)`: Executes a system command.
    - `availableProcessors()`: Returns the number of available processors.
    - `freeMemory()`: Returns the amount of free memory in the JVM.
- **Use Case**: Interacting with the JVM or executing native processes.
- **Example**:

```java
Runtime runtime = Runtime.getRuntime();
System.out.println(runtime.availableProcessors()); // Output: e.g., 8
```


----

## 2. Java Math Package (`java.math`)

### Overview

- **Purpose**: Provides classes for high-precision arithmetic and mathematical calculations.
- **Key Features**:
    - Arbitrary-precision integers and decimals.
    - Support for rounding modes and financial calculations.
- **Use Cases**: Financial applications, scientific computations, and precise arithmetic.

### Key Classes

#### 1. **BigInteger**

- **Purpose**: Represents arbitrary-precision integers for calculations beyond `long` limits.
- **Key Methods**:
    - `add(BigInteger val)`: Adds another `BigInteger`.
    - `subtract(BigInteger val)`: Subtracts another `BigInteger`.
    - `multiply(BigInteger val)`: Multiplies by another `BigInteger`.
    - `divide(BigInteger val)`: Divides by another `BigInteger`.
    - `pow(int exponent)`: Raises to a power.
    - `valueOf(long val)`: Creates a `BigInteger` from a `long`.
- **Use Case**: Large number calculations (e.g., cryptography).
- **Example**:

```java
BigInteger a = new BigInteger("100");
BigInteger b = new BigInteger("200");
System.out.println(a.add(b)); // Output: 300
```

#### 2. **BigDecimal**

- **Purpose**: Represents arbitrary-precision decimal numbers with precise control over scale and rounding.
- **Key Methods**:
    - `add(BigDecimal augend)`: Adds another `BigDecimal`.
    - `subtract(BigDecimal subtrahend)`: Subtracts another `BigDecimal`.
    - `multiply(BigDecimal multiplicand)`: Multiplies by another `BigDecimal`.
    - `divide(BigDecimal divisor, int scale, RoundingMode roundingMode)`: Divides with specified scale and rounding.
    - `setScale(int newScale, RoundingMode roundingMode)`: Sets the scale.
    - `valueOf(double val)`: Creates a `BigDecimal` from a `double`.
- **Use Case**: Financial calculations requiring exact decimal precision.
- **Example**:

```java
BigDecimal a = new BigDecimal("10.50");
BigDecimal b = new BigDecimal("2.00");
System.out.println(a.divide(b, 2, RoundingMode.HALF_UP)); // Output: 5.25
```

### Utility Classes

#### 1. **Math** (from `java.lang`)

- **Purpose**: Provides static methods for basic mathematical operations on primitive types.
- **Key Methods**:
    - `abs(int/long/float/double a)`: Returns the absolute value.
    - `max(int/long/float/double a, int/long/float/double b)`: Returns the greater value.
    - `min(int/long/float/double a, int/long/float/double b)`: Returns the lesser value.
    - `sqrt(double a)`: Returns the square root.
    - `pow(double a, double b)`: Raises `a` to the power of `b`.
    - `sin(double a)` / `cos(double a)` / `tan(double a)`: Trigonometric functions.
    - `random()`: Returns a random `double` between 0.0 and 1.0.
    - `round(double a)`: Rounds to the nearest `long`.
- **Use Case**: General-purpose mathematical operations.
- **Example**:

```java
System.out.println(Math.sqrt(16)); // Output: 4.0
System.out.println(Math.max(5, 10)); // Output: 10
```

#### 2. **StrictMath**

- **Purpose**: Similar to `Math`, but guarantees consistent results across platforms by adhering strictly to IEEE standards.
- **Key Methods**: Same as `Math` (e.g., `abs`, `sqrt`, `sin`).
- **Use Case**: Platform-independent mathematical calculations.
- **Example**:

```java
System.out.println(StrictMath.sqrt(16)); // Output: 4.0
```

#### 3. **RoundingMode** (Enum in `java.math`)

- **Purpose**: Defines rounding behaviors for `BigDecimal` operations.
- **Key Values**:
    - `UP`: Rounds away from zero.
    - `DOWN`: Rounds towards zero.
    - `HALF_UP`: Rounds to nearest, ties go away from zero.
    - `HALF_DOWN`: Rounds to nearest, ties go towards zero.
- **Use Case**: Controlling precision in `BigDecimal` operations.
- **Example**:

```java
BigDecimal bd = new BigDecimal("2.555");
System.out.println(bd.setScale(2, RoundingMode.HALF_UP)); // Output: 2.56
```

## Example Combining Lang and Math Packages

```java
import java.lang.*;
import java.math.*;
import java.time.LocalDateTime;

public class LangMathExample {
    public static void main(String[] args) {
        // java.lang: StringBuilder for text manipulation
        StringBuilder sb = new StringBuilder("Current time: ");
        sb.append(LocalDateTime.now().toString());
        System.out.println(sb); // Output: Current time: 2025-08-26T12:33:...

        // java.math: BigDecimal for precise calculation
        BigDecimal price = new BigDecimal("19.99");
        BigDecimal tax = new BigDecimal("0.08");
        BigDecimal total = price.multiply(BigDecimal.ONE.add(tax))
                               .setScale(2, RoundingMode.HALF_UP);
        System.out.println("Total: " + total); // Output: Total: 21.59

        // java.lang: Math for basic calculations
        double angle = Math.toRadians(90);
        System.out.println("Sine of 90°: " + Math.sin(angle)); // Output: Sine of 90°: 1.0
    }
}
```

## Benefits

- **java.lang**:
    - Automatically imported, providing essential functionality.
    - Versatile classes for strings, threads, and system operations.
    - Foundation for all Java programs.
- **java.math**:
    - High-precision arithmetic for financial and scientific applications.
    - Flexible rounding modes for precise control.
    - Handles large numbers beyond primitive type limits.
- **Interoperability**: Seamless integration with other Java APIs (e.g., `String` with `java.time`, `BigDecimal` with financial systems).

## Limitations

- **java.lang**:
    - Legacy classes like `Thread` are less flexible than `java.util.concurrent`.
    - `String` immutability can lead to performance overhead for heavy manipulations.
- **java.math**:
    - `BigInteger` and `BigDecimal` are slower than primitive types for simple calculations.
    - Verbose syntax for basic arithmetic compared to primitives.
- **Learning Curve**: Understanding reflection (`Class`) or synchronization (`Object` methods) requires experience.

## Resources

- Oracle Documentation:
    - [java.lang](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/lang/package-summary.html)
    - [java.math](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/math/package-summary.html)


[[Java Packages]]