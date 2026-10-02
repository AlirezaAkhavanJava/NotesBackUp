Date : 2025-09-04



## 1. Introduction

- **Lambda Expression:** Anonymous function that can be treated as a method argument or stored as a variable.
    
- **Purpose:** Enable **functional programming**, reduce boilerplate code, and implement functional interfaces.
    
- Introduced in **Java 8**, enhanced in subsequent versions.
    

**Tip:** Think of lambdas as **inline methods** that simplify code and support higher-order programming.

---

## 2. Syntax

```java
(parameters) -> expression
(parameters) -> { statements; }
```

### Examples

```java
// No parameters
() -> System.out.println("Hello World");

// Single parameter
x -> x * x;

// Multiple parameters
(a, b) -> a + b;

// Block of statements
(a, b) -> {
    int sum = a + b;
    return sum;
};
```

---

## 3. Functional Interfaces

- **Definition:** Interface with exactly one abstract method.
    
- Lambdas can only implement functional interfaces.
    

**Common Functional Interfaces:**

- `Runnable` – `void run()`
    
- `Callable<V>` – `V call()`
    
- `Comparator<T>` – `int compare(T o1, T o2)`
    
- `Consumer<T>` – `void accept(T t)`
    
- `Function<T,R>` – `R apply(T t)`
    
- `Predicate<T>` – `boolean test(T t)`
    

```java
@FunctionalInterface
interface Calculator {
    int add(int a, int b);
}
Calculator calc = (a, b) -> a + b;
System.out.println(calc.add(5, 3)); // 8
```

**Tip:** Lambdas cannot introduce new abstract methods.

---

## 4. Scoping Rules

### 4.1 Local Variables

- Variables must be **effectively final** to be used inside lambdas.
    

```java
int factor = 2;
Function<Integer, Integer> multiply = x -> x * factor;
```

### 4.2 `this` Keyword

- Refers to **enclosing class instance**, not lambda itself.
    

### 4.3 Shadowing

- Lambda parameters can **shadow outer variables** but not redefine local variables.
    

---

## 5. Types of Lambda Expressions

1. **No Parameter:** `() -> System.out.println("Hello")`
    
2. **Single Parameter:** `x -> x * x`
    
3. **Multiple Parameters:** `(a, b) -> a + b`
    
4. **Block Body:** `(a, b) -> { int sum = a + b; return sum; }`
    

---

## 6. Advanced Features

### 6.1 Method References (Java 8+)

- Short-hand for lambda expressions calling a method.
    

```java
List<String> names = Arrays.asList("Alice", "Bob");
names.forEach(System.out::println);
```

Types:

- **Static method reference:** `ClassName::staticMethod`
    
- **Instance method reference:** `object::instanceMethod`
    
- **Constructor reference:** `ClassName::new`
    

### 6.2 Capturing Variables

- Lambdas can access **final or effectively final variables**.
    

### 6.3 Streams API Integration

- Lambdas work seamlessly with **Java Streams** for functional-style operations.
    

```java
List<Integer> numbers = Arrays.asList(1,2,3);
numbers.stream().map(x -> x * 2).forEach(System.out::println);
```

### 6.4 Exception Handling

- Lambda body can throw exceptions if functional interface allows it.
    

```java
@FunctionalInterface
interface Task { void execute() throws IOException; }
```

### 6.5 Serializing Lambdas (Java 8+)

- Lambdas can be **serialized** if functional interface extends `Serializable`.
    

---

## 7. Best Practices

1. Use lambdas to **replace anonymous classes**.
    
2. Prefer **method references** when possible.
    
3. Keep lambda expressions **short and readable**.
    
4. Avoid side-effects in lambdas; keep them **stateless**.
    
5. Combine with Streams API for **functional programming patterns**.
    
6. Document lambdas for complex logic.
    

---

## 8. Real-World Usage

- Event handling in GUI frameworks.
    
- Stream processing (filter, map, reduce).
    
- Functional APIs in libraries like `CompletableFuture`, `Optional`.
    
- Custom comparators and strategies.
    

**Tip:** Lambdas simplify code, improve readability, and enable **concise functional programming**.

---

## 9. Summary

- Lambda expressions provide **inline, anonymous function implementation**.
    
- Must implement a **functional interface**.
    
- Support **method references, streams, and functional programming**.
    
- Modern Java (up to 25) enhances lambda usage with **records, sealed classes, and virtual threads**.
    
- Best practices: keep them short, stateless, readable, and prefer method references when appropriate.
    

This guide ensures mastery of **Java Lambda Expressions from beginner to senior-level**, including all updates up to Java 25.



##### *Tags : [[Java]]