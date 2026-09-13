

## 1. Types of Variables

### a) Local Variables

- Declared **inside a method, constructor, or block**.
    
- Created when the method is invoked.
    
- Destroyed once the method exits.
    
- **Must be initialized** before use.
    

```java
void exampleMethod() {
    int x = 10; // local variable
    System.out.println(x);
}
```

---

### b) Instance Variables (Non-Static Fields)

- Declared inside a class, but **outside any method**.
    
- Created when an object is created.
    
- Each object gets its own copy.
    

```java
class Person {
    String name; // instance variable
}
```

---

### c) Static Variables (Class Variables)

- Declared with the `static` keyword inside a class.
    
- Shared across all objects of the class.
    
- Created when the class is loaded, destroyed when JVM shuts down.
    

```java
class Counter {
    static int count = 0; // static variable
}
```

---

## 2. Variable Scope

### a) Block Scope

- Variables declared inside **{ }** are accessible only within that block.
    

```java
if (true) {
    int y = 5;
    System.out.println(y); // valid
}
// System.out.println(y); // error: y not visible here
```

### b) Method Scope

- Local variables exist only inside the method where they are declared.
    

```java
void test() {
    int z = 100;
    System.out.println(z);
}
// z cannot be accessed outside test()
```

### c) Class Scope

- Instance and static variables are accessible throughout the class.
    

```java
class Example {
    int a = 1; // instance
    static int b = 2; // static
}
```

### d) Global Scope?

- Java **does not support global variables**.
    
- Instead, static variables in classes can simulate global-like access.
    

---

## 3. Lifetime of Variables

- **Local Variables** → created when method/block starts, destroyed when it ends.
    
- **Instance Variables** → live as long as the object exists.
    
- **Static Variables** → live until JVM shutdown.
    

---

## 4. Final Variables (Constants)

- Declared using `final` keyword.
    
- Once assigned, cannot be changed.
    

```java
final double PI = 3.14159;
```

---

## Summary

- **Local** → inside method/block, short-lived.
    
- **Instance** → per object, exists until object destroyed.
    
- **Static** → shared by class, lives until JVM stops.
    
- **Final** → value cannot be changed after initialization.
    

Understanding variable scope prevents errors like **variable shadowing**, **illegal access**, and helps manage memory efficiently.



Date : 2025-09-04
##### *Tags : [[Java]]