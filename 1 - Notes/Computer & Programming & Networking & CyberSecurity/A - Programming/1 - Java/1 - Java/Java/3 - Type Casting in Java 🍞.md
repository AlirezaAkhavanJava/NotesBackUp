Date : 2025-09-04


Type casting in Java is the process of converting a variable from one type to another. It applies to both **primitive types** and **reference types (objects)**.

---

## 1. Primitive Type Casting

### a) Widening (Implicit Casting)

- Conversion from a **smaller** data type to a **larger** data type.
    
- Done automatically by the compiler.
    
- No data loss.
    

**Order of widening:**

```
byte → short → int → long → float → double
```

**Example:**

```java
int x = 10;
double y = x; // int → double (widening)
System.out.println(y); // 10.0
```

---

### b) Narrowing (Explicit Casting)

- Conversion from a **larger** data type to a **smaller** one.
    
- Must be done **manually** with cast operator `(type)`.
    
- May cause **data loss** or overflow.
    

**Example:**

```java
double a = 9.78;
int b = (int) a; // double → int (narrowing)
System.out.println(b); // 9
```

---

## 2. Reference Type Casting

### a) Upcasting (Implicit)

- Casting a subclass object to a superclass type.
    
- Always safe.
    

**Example:**

```java
class Animal {}
class Dog extends Animal {}

Animal a = new Dog(); // upcasting
```

### b) Downcasting (Explicit)

- Casting a superclass reference back to a subclass type.
    
- Must be explicit.
    
- Risky → can throw `ClassCastException` if the object is not actually of that type.
    

**Example:**

```java
Animal a = new Dog();
Dog d = (Dog) a; // downcasting
```

---

## 3. Type Casting with `instanceof`

- To prevent runtime errors during downcasting, use `instanceof` to check type.
    

```java
if (a instanceof Dog) {
    Dog d = (Dog) a;
    System.out.println("Downcast successful!");
}
```

---

## 4. String Conversion

- Java provides utility methods for type conversion with Strings.
    

```java
int num = Integer.parseInt("123");
String s = String.valueOf(num);
```

---

## Summary

- **Widening (implicit)** → safe, automatic.
    
- **Narrowing (explicit)** → risky, may lose data.
    
- **Upcasting (implicit)** → subclass → superclass, always safe.
    
- **Downcasting (explicit)** → superclass → subclass, requires caution.
    
- Use `instanceof` to ensure safe casting.
    

Type casting is fundamental for working with **primitive types, polymorphism, and APIs**.




##### *Tags : [[Java]]