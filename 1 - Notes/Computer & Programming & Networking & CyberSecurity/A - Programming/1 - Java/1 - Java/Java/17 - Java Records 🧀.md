
Date : 2025-09-04



# Java Records – Complete Guide (Java 16 to Java 25)

This guide covers **Java Records**, including their syntax, features, use cases, best practices, and modern enhancements up to Java 25, from beginner to senior level.

>  A Java record is a special kind of class introduced in Java 14 as a preview feature, and stabilized in Java 16. It is designed to make it very easy and concise to create immutable data-carrier classes (also called data transfer objects, DTOs, or value objects).

---

## 1. Introduction

- **Record:** Special type of class in Java used to store **immutable data**.
    
- **Purpose:** Reduces boilerplate code (getters, setters, constructors, equals, hashCode, toString).
    

**Example:**

```java
record Point(int x, int y) {}
Point p = new Point(1, 2);
System.out.println(p.x()); // 1
System.out.println(p.y()); // 2
```

**Tip:** Use records when your class is primarily **data carrier**.

---

## 2. Basic Record Features

- **Fields are final and private**.
    
- **Implicit methods:** `equals()`, `hashCode()`, `toString()`, getters (named after fields).
    
- **Constructor:** Canonical constructor automatically generated.
    

```java
Point p1 = new Point(3, 4);
Point p2 = new Point(3, 4);
System.out.println(p1.equals(p2)); // true
System.out.println(p1); // Point[x=3, y=4]
```

**Tip:** Records are immutable; no setters.

---

## 3. Custom Constructors and Validation

### Intermediate Level

- Add validation or additional logic.
    

```java
record Person(String name, int age) {
    public Person {
        if(age < 0) throw new IllegalArgumentException("Age cannot be negative");
    }
}

Person p = new Person("Alice", 25); // Valid
```

**Tip:** Use compact constructors for validation and additional logic.

---

## 4. Methods in Records

- Records can have **additional methods**.
    

```java
record Rectangle(int width, int height) {
    int area() { return width * height; }
}
Rectangle r = new Rectangle(5, 10);
System.out.println(r.area()); // 50
```

**Tip:** Keep methods **pure** to maintain immutability.

---

## 5. Implementing Interfaces

- Records can implement interfaces.
    

```java
interface Shape { int area(); }
record Square(int side) implements Shape {
    public int area() { return side * side; }
}
```

**Tip:** Combine with interfaces for polymorphic behavior.

---

## 6. Inheritance Limitations

- Records **cannot extend other classes**, but **can implement interfaces**.
    
- All fields are final; records are implicitly **final**.
    

**Tip:** Use composition instead of inheritance for records.

---

## 7. Pattern Matching and Records (Java 16+)

- Records can be used in **switch expressions** and **pattern matching**.
    

```java
record Point(int x, int y) {}
Object obj = new Point(1,2);
if(obj instanceof Point(int a, int b)) {
    System.out.println(a + "," + b);
}
```

**Tip:** Use pattern matching to destructure record fields easily.

---

## 8. Serialization

- Records are **serializable** by default if all fields are serializable.
    
- No extra code required unless custom serialization is needed.
    

**Tip:** Ensure immutability and serializability when using records for DTOs.

---

## 9. Real-World Usage

- **Data Transfer Objects (DTOs)** in APIs.
    
- **Immutable configuration objects**.
    
- **Key objects for maps/sets**.
    
- **Pattern matching with records** for cleaner code.
    

**Tip:** Use records wherever you need **simple, immutable data structures**.

---

## 10. Best Practices

1. Use records for **data-only classes**.
    
2. Avoid mutable fields.
    
3. Use compact constructors for validation.
    
4. Implement interfaces for polymorphism.
    
5. Combine with **pattern matching** for expressive, clean code.
    
6. Do not try to use records for inheritance hierarchies.
    

---

## 11. Summary

- Records are **immutable, final, and concise** classes.
    
- Automatically generate **constructors, getters, equals, hashCode, toString**.
    
- Can have **methods, implement interfaces**, but cannot extend other classes.
    
- Use **modern Java features (pattern matching, switch expressions)** with records.
    

This guide ensures mastery of **Java Records from beginner to senior-level**, including updates up to Java 25.


##### *Tags : [[Java]]