
Date : 2025-09-04


This document explains **basic arithmetic, operators, and the Math class** in Java.

---

## 1. Arithmetic Operators

- `+` → Addition
    
- `-` → Subtraction
    
- `*` → Multiplication
    
- `/` → Division
    
- `%` → Modulus (remainder)
    

**Example:**

```java
int a = 10, b = 3;
System.out.println(a + b); // 13
System.out.println(a - b); // 7
System.out.println(a * b); // 30
System.out.println(a / b); // 3
System.out.println(a % b); // 1
```

---

## 2. Increment and Decrement

- `++a` → Pre-increment (increase before use)
    
- `a++` → Post-increment (increase after use)
    
- `--a` → Pre-decrement
    
- `a--` → Post-decrement
    

```java
int x = 5;
System.out.println(++x); // 6
System.out.println(x++); // 6 (then x = 7)
```

---

## 3. Assignment Operators

- `=` → Assign
    
- `+=` → Add and assign
    
- `-=` → Subtract and assign
    
- `*=` → Multiply and assign
    
- `/=` → Divide and assign
    
- `%=` → Modulus and assign
    

```java
int n = 10;
n += 5; // n = 15
n *= 2; // n = 30
```

---

## 4. Relational Operators

- `==` → Equal to
    
- `!=` → Not equal to
    
- `>` → Greater than
    
- `<` → Less than
    
- `>=` → Greater or equal
    
- `<=` → Less or equal
    

```java
System.out.println(5 > 3); // true
System.out.println(5 == 3); // false
```

---

## 5. Logical Operators

- `&&` → Logical AND
    
- `||` → Logical OR
    
- `!` → Logical NOT
    

```java
System.out.println((5 > 3) && (8 > 6)); // true
System.out.println((5 < 3) || (8 > 6)); // true
System.out.println(!(5 == 3));          // true
```

---

## 6. The `Math` Class

Java provides the `java.lang.Math` class for advanced operations.

### Common Methods

```java
Math.abs(-10);       // 10 (absolute value)
Math.max(5, 9);      // 9 (maximum)
Math.min(5, 9);      // 5 (minimum)
Math.sqrt(16);       // 4.0 (square root)
Math.pow(2, 3);      // 8.0 (power)
Math.round(4.6);     // 5 (round)
Math.ceil(4.3);      // 5.0 (round up)
Math.floor(4.9);     // 4.0 (round down)
Math.random();       // random number between 0.0 and 1.0


(int)(Math.random() * (max - min) + min) //ranfom number with a range

```

---

## 7. Trigonometric Functions

```java
Math.sin(Math.toRadians(30)); // 0.5
Math.cos(Math.toRadians(60)); // 0.5
Math.tan(Math.toRadians(45)); // 1.0
```

---

## 8. Constants

```java
Math.PI;    // 3.141592653589793
Math.E;     // 2.718281828459045
```

---

## Summary

- Use **arithmetic, assignment, relational, and logical operators** for basic math.
    
- Use the **`Math` class** for advanced calculations.
    
- Important methods: `abs`, `max`, `min`, `sqrt`, `pow`, `round`, `ceil`, `floor`, `random`.
    
- Includes **trigonometric functions** and constants (`PI`, `E`).



##### *Tags : [[Java]]