


Unlike the string classes, these are primarily **utility classes** (with static methods) or **configuration objects**. Because they return primitive values (`double`, `int`) rather than themselves, they don't "chain" the same way `StringBuilder` does. Instead, they are **composed** (nested) or used to feed other methods. I'll show you exactly how that works.

---

## 1. `Math` (java.lang)

A **final utility class** containing static methods for performing basic numeric operations (exponents, logarithms, square roots, trigonometry, rounding). You cannot instantiate it (`new Math()` is a compile error).

### Most common methods

```java
// Absolute value & signs
Math.abs(-5);              // 5
Math.abs(-3.14);           // 3.14
Math.negateExact(5);       // -5
Math.signum(-10.5);        // -1.0

// Min / Max
Math.max(10, 20);          // 20
Math.min(10.5, 3.2);       // 3.2

// Powers & Roots
Math.pow(2, 10);           // 1024.0
Math.sqrt(144);            // 12.0
Math.cbrt(27);             // 3.0

// Rounding
Math.round(3.14);          // 3 (long)
Math.round(3.99);          // 4 (long)
Math.ceil(3.01);           // 4.0
Math.floor(3.99);          // 3.0

// Trigonometry (radians)
Math.sin(Math.PI / 2);     // 1.0
Math.cos(0);               // 1.0
Math.toRadians(180);       // 3.14159...

// Random
Math.random();             // 0.0 to 1.0

// Constants
Math.PI;                   // 3.141592653589793
Math.E;                    // 2.718281828459045
```

### Visual Examples

**Basic usage:**
```java
double radius = 5.0;
double area = Math.PI * Math.pow(radius, 2);
System.out.println(area); // 78.53981633974483
```

**Nesting (Math's version of chaining):**
Since `Math` methods return `double` or `int`, you can feed the output of one directly into another.
```java
// Calculate the hypotenuse of a triangle
double a = 3.0;
double b = 4.0;

double c = Math.sqrt(Math.pow(a, 2) + Math.pow(b, 2));
// Inner: Math.pow(3,2) -> 9.0, Math.pow(4,2) -> 16.0
// Inner: 9.0 + 16.0 -> 25.0
// Outer: Math.sqrt(25.0) -> 5.0
```

**Combining with String formatting (a real chain):**
```java
String result = String.format("Hypotenuse: %.2f", Math.sqrt(Math.pow(3, 2) + Math.pow(4, 2)));
// "Hypotenuse: 5.00"
```

---

## 2. `MathContext` (java.math)

An **immutable object** that encapsulates two things: **precision** (total number of digits) and **rounding mode** (e.g., HALF_UP, CEILING). It is used exclusively with `BigDecimal` to control how precise calculations should be.

### Most common methods

```java
// Constructors
MathContext mc1 = new MathContext(5);                     // 5 digits, HALF_UP
MathContext mc2 = new MathContext(5, RoundingMode.CEILING); // 5 digits, CEILING
MathContext mc3 = MathContext.UNLIMITED;                  // No precision limit
MathContext mc4 = MathContext.DECIMAL32;                  // IEEE 754R 32-bit
MathContext mc5 = MathContext.DECIMAL64;                  // IEEE 754R 64-bit

// Getters
mc1.getPrecision();       // int (5)
mc1.getRoundingMode();    // RoundingMode (HALF_UP)
mc1.toString();           // "precision=5 roundingMode=HALF_UP"
```

### Visual Examples

**Using with BigDecimal:**
```java
BigDecimal bd = new BigDecimal("3.1415926535");

// Round to 3 significant digits using HALF_UP
MathContext mc = new MathContext(3, RoundingMode.HALF_UP);
BigDecimal rounded = bd.round(mc);
System.out.println(rounded); // 3.14

// Arithmetic with context
BigDecimal a = new BigDecimal("10");
BigDecimal b = new BigDecimal("3");

BigDecimal result = a.divide(b, new MathContext(4, RoundingMode.HALF_UP));
System.out.println(result); // 3.333
```

**Chaining with BigDecimal:**
`MathContext` isn't chainable itself, but it enables chaining on `BigDecimal`:
```java
String result = new BigDecimal("123.456789")
        .round(new MathContext(5))             // 123.46
        .multiply(new BigDecimal("2"))          // 246.92
        .setScale(1, RoundingMode.HALF_UP)      // 246.9
        .toString();
// "246.9"
```

---

## 3. `StrictMath` (java.lang)

A **mirror of `Math`** (same method signatures). The difference: `StrictMath` guarantees **bit-for-bit identical results** across all platforms (using the `fdlibm` library). `Math` may use platform-specific hardware instructions for speed, which can yield tiny differences in the last decimal place. 

For 99% of applications, use `Math`. Use `StrictMath` only if you need absolute reproducibility (e.g., scientific computing, cryptographic algorithms, cross-platform simulations).

### Most common methods (identical to Math)

```java
StrictMath.abs(-5);          // 5
StrictMath.max(10, 20);      // 20
StrictMath.pow(2, 10);       // 1024.0
StrictMath.sqrt(144);        // 12.0
StrictMath.sin(Math.PI / 2); // 1.0
StrictMath.round(3.14);      // 3
StrictMath.PI;               // 3.141592653589793
StrictMath.E;                // 2.718281828459045
```

### Visual Examples

**Basic usage:**
```java
double result = StrictMath.pow(2, 10);
System.out.println(result); // 1024.0
```

**Why use it? (Comparison example):**
```java
double m = Math.sin(0.5);
double sm = StrictMath.sin(0.5);
// On some architectures, m and sm might differ by 1 ULP (unit in last place).
// With StrictMath, sm is guaranteed to be exactly the same on Windows, Linux, Mac, ARM, x86, etc.
```

**Chaining (same nesting as Math):**
```java
double distance = StrictMath.sqrt(
    StrictMath.pow(x2 - x1, 2) + StrictMath.pow(y2 - y1, 2)
);
```

**Combining with formatting:**
```java
String s = String.format("Strict result: %.4f", StrictMath.log(StrictMath.E));
// "Strict result: 1.0000"
```

---

## Summary Table: Chaining & Composition

| Class | Type | Return Type | Chainable? | How it chains |
|-------|------|-------------|------------|---------------|
| `Math` | Static utility | `double`, `int`, `long` | ❌ No (direct) | **Nesting** (`Math.sqrt(Math.pow(x,2))`) or feeding into `String.format()` |
| `MathContext` | Immutable config | `MathContext`, `int`, `RoundingMode` | ❌ No | Passed as an **argument** to `BigDecimal` methods (`bd.round(mc)`) |
| `StrictMath` | Static utility | `double`, `int`, `long` | ❌ No (direct) | **Nesting** (same as `Math`) or feeding into formatters |

### The "Chain" that actually works
While these math classes don't return themselves, you can build powerful pipelines by composing them:

```java
// A real-world chain: math -> BigDecimal -> String formatting
String report = String.format("Result: %s",
    new BigDecimal(StrictMath.sqrt(2))               // 1.4142135623730951
        .round(new MathContext(4, RoundingMode.HALF_UP)) // 1.414
        .multiply(new BigDecimal("100"))             // 141.4
        .toString()
);
// "Result: 141.4"
```





[[Java]]