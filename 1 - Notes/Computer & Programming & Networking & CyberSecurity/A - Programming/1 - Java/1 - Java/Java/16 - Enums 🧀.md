Date : 2025-09-04


# Java Enums – Complete Guide (Up to Java 25)

This guide covers **Enums in Java**, including syntax, methods, advanced features, design patterns, and real-world usage, from beginner to senior-level concepts with learning tips.

---

## 1. Introduction

- **Enum (Enumeration):** A special Java type used to define a collection of constants.
    
- **Purpose:** Makes code more readable and type-safe.
    

**Example:**

```java
enum Day { MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY }
```

**Tip:** Use enums instead of `int` or `String` constants for better type safety.

---

## 2. Basic Enum Usage

### Beginner Level

```java
Day today = Day.MONDAY;
if(today == Day.MONDAY) {
    System.out.println("Start of the work week");
}
```

- Use `==` to compare enums.
    
- Use `values()` to iterate over enum constants.
    

```java
for(Day d : Day.values()) System.out.println(d);
```

**Tip:** Enums are implicitly `static` and `final`.

---

## 3. Enum Methods

- **name()** – returns enum constant name
    
- **ordinal()** – returns position (starting at 0)
    
- **valueOf(String name)** – returns enum constant by name
    

```java
System.out.println(Day.MONDAY.name());    // MONDAY
System.out.println(Day.MONDAY.ordinal()); // 0
Day d = Day.valueOf("FRIDAY");
```

**Tip:** Avoid relying on `ordinal()` for logic; use explicit fields instead.

---

## 4. Enums with Fields and Methods

### Intermediate Level

```java
enum Size {
    SMALL(1), MEDIUM(2), LARGE(3);

    private final int level;

    Size(int level) { this.level = level; }
    public int getLevel() { return level; }
}

System.out.println(Size.MEDIUM.getLevel()); // 2
```

- Enums can have **constructors, fields, and methods**.
    
- Constructors are **private by default**.
    

**Tip:** Use fields to store additional info like IDs, labels, or descriptions.

---

## 5. Advanced Enum Features

- **Abstract methods in enums:** Each constant can implement differently.
    

```java
enum Operation {
    PLUS { double apply(double x, double y) { return x + y; }},
    MINUS { double apply(double x, double y) { return x - y; }};

    abstract double apply(double x, double y);
}
```

- **Interfaces in enums:** Implement common interfaces.
    

```java
interface Printable { void print(); }
enum Shape implements Printable { CIRCLE, SQUARE;
    public void print() { System.out.println(this); }
}
```

- **Switch expressions (Java 14+):**
    

```java
switch(today) {
    case MONDAY, FRIDAY -> System.out.println("Start or end week");
    case SATURDAY, SUNDAY -> System.out.println("Weekend");
}
```

**Tip:** Use switch expressions with enums for concise logic.

---

## 6. EnumSet and EnumMap

- **EnumSet:** High-performance Set for enums.
    

```java
EnumSet<Day> weekend = EnumSet.of(Day.SATURDAY, Day.SUNDAY);
```

- **EnumMap:** Map keys with enums.
    

```java
EnumMap<Day, String> map = new EnumMap<>(Day.class);
map.put(Day.MONDAY, "Work");
```

**Tip:** Prefer EnumSet/EnumMap for performance and clarity.

---

## 7. Modern Java (21–25) Features

- Pattern matching with enums.
    
- Switch expressions with arrows.
    
- Sealed classes can work alongside enums for exhaustive control flows.
    

**Tip:** Combine enums with sealed classes for type-safe hierarchy.

---

## 8. Best Practices

1. Use enums instead of `int`/`String` constants.
    
2. Add meaningful fields for additional data.
    
3. Keep enum methods concise.
    
4. Use EnumSet and EnumMap for collections.
    
5. Combine with modern Java features (switch expressions, pattern matching).
    

---

## 9. Real-World Usage

- Status codes: `OrderStatus { PENDING, SHIPPED, DELIVERED }`
    
- Config options: `LogLevel { INFO, DEBUG, ERROR }`
    
- Command patterns with enums implementing behavior.
    

**Tip:** Enums make business logic safer, readable, and maintainable.

---

## 10. Summary

- Enums are **special constants with type safety**.
    
- Can have **fields, methods, abstract methods, and implement interfaces**.
    
- Use **EnumSet/EnumMap** for collections.
    
- Leverage **modern Java features** for clean and safe code.
    

This guide ensures mastery of **Java Enums from beginner to senior-level**, including all updates up to Java 25.

---
Here’s a complete, up-to-date guide to **Java Enums** (as of Java 21/22/23+ in 2025) — from basic usage to advanced features that many developers still don’t know exist.

### 1. What is a Java Enum? (It’s much more than a constant list)

```java
public enum Day {
    MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY
}
```

A Java `enum` is a **special class** that:
- Extends `java.lang.Enum<E>`
- Is `final` (cannot be subclassed)
- Has private constructor(s)
- All enum constants are `public static final` instances created at class loading time.

### 2. Enums with Fields, Constructors, and Methods (Most Useful Form)

```java
public enum Planet {
    MERCURY(3.303e+23, 2.4397e6),
    VENUS  (4.869e+24, 6.0518e6),
    EARTH  (5.976e+24, 6.3781e6),
    MARS   (6.421e+23, 3.3895e6);

    private final double mass;   // kg
    private final double radius; // meters

    Planet(double mass, double radius) {
        this.mass = mass;
        this.radius = radius;
    }

    public double surfaceGravity() {
        double G = 6.67300E-11;
        return G * mass / (radius * radius);
    }

    public double weightOnPlanet(double humanMass) {
        return humanMass * surfaceGravity();
    }
}
```

Usage:
```java
double myWeight = 75; // kg on Earth
double marsWeight = Planet.MARS.weightOnPlanet(myWeight);
System.out.println("My weight on Mars: " + marsWeight); // ~284 N
```

### 3. Enums with Abstract Methods (Strategy Enum Pattern)

```java
public enum Operation {
    PLUS   { @Override public double apply(double x, double y) { return x + y; } },
    MINUS  { @Override public double apply(double x, double y) { return x - y; } },
    TIMES  { @Override public double apply(double x, double y) { return x * y; } },
    DIVIDE { @Override public double apply(double x, double y) { return x / y; } };

    // Abstract method — each constant must implement it
    public abstract double apply(double x, double y);
}
```

### 4. Enums Implementing Interfaces (Very Powerful)

```java
public interface Describable {
    String getDescription();
}

public enum Color implements Describable {
    RED("#FF0000") {
        @Override public String getDescription() { return "Passion and danger"; }
    },
    GREEN("#00FF00") {
        @Override public String getDescription() { return "Nature and growth"; }
    };

    private final String hex;

    Color(String hex) { this.hex = hex; }
    public String hex() { return hex; }
}
```

### 5. Useful Built-in Methods (Every Enum Has These)

```java
Day today = Day.WEDNESDAY;

today.name();           // "WEDNESDAY" (String)
today.ordinal();        // 2 (position, zero-based — avoid relying on it!)
Day.valueOf("FRIDAY");  // returns Day.FRIDAY
Day.values();           // returns Day[] with all constants

// Safe parsing
Day safe = Day.valueOf("monday".toUpperCase()); // OK
Day maybe = Enum.valueOf(Day.class, "MONDAY");  // same

// Try-parse (Java 14+ pattern)
Optional<Day> opt = Enum.valueOf(Day.class, "TUESDAY", null); // Java 21+ has better ways
```

### 6. Enums in switch (Perfect Match!)

```java
switch (today) {
    case SATURDAY, SUNDAY -> System.out.println("Weekend!");
    case MONDAY           -> System.out.println("Ugh...");
    default               -> System.out.println("Just another day");
}
```

### 7. Enums with Java Records (Java 21+ Best Practice for Simple Cases)

```java
public enum HttpStatus(int code, String reason) {
    OK(200, "OK"),
    NOT_FOUND(404, "Not Found"),
    INTERNAL_SERVER_ERROR(500, "Server Error");

    // No need for fields — record components are used
    public boolean isSuccess() { return code >= 200 && code < 300; }
}
```

### 8. Enums in Sealed Hierarchies (Java 17+)

```java
public sealed interface Command permits Command.Quit, Command.Move {}

public enum Command implements Command {
    QUIT, 
    MOVE_UP, MOVE_DOWN, MOVE_LEFT, MOVE_RIGHT;

    public enum Quit implements Command { INSTANCE }
    public enum Move implements Command { UP, DOWN, LEFT, RIGHT }
}
```

### 9. Constant-Specific Class Bodies (Rare but Awesome)

```java
enum PayrollDay {
    MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY,
    SATURDAY {
        @Override double pay(double hours, double rate) {
            return hours * rate * 1.5; // overtime
        }
    },
    SUNDAY {
        @Override double pay(double hours, double rate) {
            return hours * rate * 2.0; // double time
        }
    };

    abstract double pay(double hours, double rate); // normal days use default

    double pay(double hours, double rate) {
        return hours * rate; // regular pay
    }
}
```

### 10. Best Practices in 2025

| Do                                      | Don’t                                  |
|-----------------------------------------|----------------------------------------|
| Use enums for fixed sets (days, states, HTTP codes) | Use int constants or String constants |
| Add methods/fields when behavior differs | Rely on `ordinal()` for logic          |
| Implement interfaces when needed       | Extend enums (impossible anyway)       |
| Use in `switch` expressions             | Serialize enums by `ordinal()`         |
| Use `EnumSet` and `EnumMap` for performance | Use `ArrayList<Enum>` or `HashMap<Enum, V>` |

```java
// Fastest collections for enums
EnumSet<Day> weekends = EnumSet.of(Day.SATURDAY, Day.SUNDAY);
EnumMap<Day, String> schedule = new EnumMap<>(Day.class);
```

### Bonus: Real-World Example — Spring’s HttpStatus (simplified)

```java
public enum HttpStatus {
    OK(200), BAD_REQUEST(400), UNAUTHORIZED(401), FORBIDDEN(403), NOT_FOUND(404);

    private final int value;
    HttpStatus(int value) { this.value = value; }
    public int value() { return value; }
    public boolean is2xxSuccessful() { return value >= 200 && value < 300; }
}
```

Java enums are **one of the most powerful and underused features** in the language.

Master them — and you’ll write cleaner, safer, and faster code.



##### *Tags : [[Java]]