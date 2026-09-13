

# Lambda Expressions in Java

A **lambda expression** is a concise way to represent an anonymous function (a function without a name) that can be passed around as a value. It was introduced in **Java 8** to enable functional programming features.

## Syntax

```java
(parameters) -> expression
```
or
```java
(parameters) -> { statements; }
```

## Basic Examples

### 1. No parameters
```java
() -> System.out.println("Hello");
```

### 2. One parameter (parentheses optional)
```java
x -> x * x;
```

### 3. Multiple parameters
```java
(a, b) -> a + b;
```

### 4. With a block body
```java
(a, b) -> {
    int sum = a + b;
    return sum;
};
```

## Why Lambda? — Comparison

**Before Java 8 (anonymous inner class):**
```java
Runnable r = new Runnable() {
    @Override
    public void run() {
        System.out.println("Running");
    }
};
```

**With lambda:**
```java
Runnable r = () -> System.out.println("Running");
```

## Functional Interfaces

Lambdas work only with **functional interfaces** — interfaces with exactly one abstract method.

```java
@FunctionalInterface
interface Calculator {
    int operate(int a, int b);
}

Calculator add = (a, b) -> a + b;
Calculator mul = (a, b) -> a * b;

System.out.println(add.operate(3, 4)); // 7
System.out.println(mul.operate(3, 4)); // 12
```

## Common Built-in Examples

```java
import java.util.*;
import java.util.function.*;

// Predicate<T>: T -> boolean
Predicate<String> isEmpty = s -> s.isEmpty();

// Function<T,R>: T -> R
Function<Integer, Integer> square = n -> n * n;

// Consumer<T>: T -> void
Consumer<String> print = s -> System.out.println(s);

// Supplier<T>: () -> T
Supplier<Double> random = () -> Math.random();

// BiFunction<T,U,R>
BiFunction<Integer, Integer, Integer> add = (a, b) -> a + b;
```

## Using Lambdas with Collections

```java
List<String> names = Arrays.asList("Alice", "Bob", "Charlie");

// forEach
names.forEach(name -> System.out.println(name));

// Sorting
names.sort((a, b) -> a.compareTo(b));

// Streams
names.stream()
     .filter(n -> n.startsWith("A"))
     .map(String::toUpperCase)
     .forEach(System.out::println);
```

## Variable Capture

Lambdas can capture variables from the enclosing scope, but they must be **effectively final**:

```java
int factor = 3; // effectively final
Function<Integer, Integer> multiply = n -> n * factor;
```

## Key Points to Remember

| Feature | Description |
|---------|-------------|
| **Type** | Lambdas have no type themselves; they take the type of the functional interface they're assigned to |
| **Target typing** | Compiler infers the interface from context |
| **`this` keyword** | Refers to the enclosing instance (unlike anonymous classes) |
| **Access** | Can access `final` or effectively final local variables |
| **Short form** | `String::toUpperCase` is a method reference — a shorthand for `s -> s.toUpperCase()` |

## Summary

A lambda is essentially:
> **A shorter, cleaner way to implement a functional interface.**

It enables you to treat behavior as data, making code more readable and enabling functional-style programming with Streams and the `java.util.function` package.



[[Java]]