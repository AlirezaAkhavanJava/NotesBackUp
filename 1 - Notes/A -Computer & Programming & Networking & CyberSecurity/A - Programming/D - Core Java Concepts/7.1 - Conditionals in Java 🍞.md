
Date : 2025-09-04



This document explains **conditional statements** in Java and introduces **modern features available in Java 21+**.

---

## 1. `if`, `else if`, `else`

- Standard conditional blocks.
    

```java
int num = 10;
if (num > 0) {
    System.out.println("Positive");
} else if (num < 0) {
    System.out.println("Negative");
} else {
    System.out.println("Zero");
}
```

---

## 2. `switch` Statement

- Used to select one of many code blocks based on **value**.
    

```java
int day = 3;
switch (day) {
    case 1 -> System.out.println("Monday");
    case 2 -> System.out.println("Tuesday");
    case 3 -> System.out.println("Wednesday");
    default -> System.out.println("Other day");
}
```

### Java 12+ Switch Expressions (Arrow `->`)

- Returns a value.
    

```java
String dayName = switch (day) {
    case 1 -> "Monday";
    case 2 -> "Tuesday";
    case 3 -> "Wednesday";
    default -> "Other";
};
System.out.println(dayName);
```

---

## 3. Conditional (Ternary) Operator `? :`

- Short form of `if-else`.
    

```java
int num = 5;
String result = (num % 2 == 0) ? "Even" : "Odd";
System.out.println(result); // Odd
```

---

## 4. Pattern Matching for `switch` (Java 21 Preview)

- Allows matching **types** and extracting values.
    

```java
Object obj = 42;
switch (obj) {
    case Integer i -> System.out.println("Integer: " + i);
    case String s  -> System.out.println("String: " + s);
    default        -> System.out.println("Other type");
}
```

### Pattern Matching with `if` (Java 21+)

```java
Object value = "Hello";
if (value instanceof String s) {
    System.out.println("String length: " + s.length());
}
```

---

## 5. Guard Clauses (Modern Approach)

- Instead of nested `if-else`, use early returns.
    

```java
void process(int num) {
    if (num <= 0) return;
    // process positive number
}
```

---

## 6. Comparison Methods (Java 21+)

- **`Integer.compare(int, int)`** or `Comparable` interface.
    
- Works well with **switch expressions** and pattern matching.
    

---

## 7. Summary

- **Traditional conditionals**: `if`, `else if`, `else`, `switch`
    
- **Ternary operator**: `? :` for inline decisions
    
- **Modern Java 21+**:
    
    - `switch` expressions with arrows (`->`) and yield values
        
    - Pattern matching in `switch` and `if` for type extraction
        
    - Guard clauses to reduce nesting
        

These modern features make condition



##### *Tags : [[Java]]