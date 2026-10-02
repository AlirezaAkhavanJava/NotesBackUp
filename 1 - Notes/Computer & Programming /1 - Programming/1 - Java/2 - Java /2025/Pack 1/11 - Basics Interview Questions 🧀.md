
Date : 2025-09-04


This document contains **interview questions with answers** covering Java OOP, loops, conditionals, arrays, strings, math operations, memory, type casting, variables, and modern Java 21–25 features.

---

## 1. OOP Questions

1. **What are the four pillars of OOP in Java?**
    
    - **Encapsulation, Inheritance, Polymorphism, Abstraction.**
        
2. **Explain encapsulation with an example.**
    
    - Hiding internal state using private fields and exposing public methods.
        
    
    ```java
    class Person {
        private String name;
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
    }
    ```
    
3. **What is inheritance? How does Java implement it?**
    
    - Inheritance allows a class to acquire properties and methods from another class. Implemented using `extends` keyword.
        
4. **Difference between method overloading and overriding.**
    
    - Overloading: same method name, different parameters (compile-time).
        
    - Overriding: subclass redefines method of superclass (runtime).
        
5. **What is abstraction? How is it achieved in Java?**
    
    - Hiding implementation and exposing functionality. Achieved with `abstract` classes and interfaces.
        
6. **What are records and when would you use them?** (Java 16+)
    
    - Immutable data classes that automatically generate methods like `toString()`, `hashCode()`, `equals()`. Use for simple data carriers.
        
7. **What are sealed classes? Give an example.** (Java 17+)
    
    - Restrict which classes can extend a superclass.
        
    
    ```java
    sealed class Vehicle permits Car, Bike {}
    final class Car extends Vehicle {}
    final class Bike extends Vehicle {}
    ```
    
8. **How does pattern matching simplify instanceof checks?** (Java 21+)
    
    - Automatically casts object if it matches type.
        
    
    ```java
    if (obj instanceof Dog d) { d.bark(); }
    ```
    
9. **Explain virtual threads and their advantage.** (Java 21+)
    
    - Lightweight threads managed by JVM, allowing scalable concurrency with minimal overhead.
        
10. **Difference between abstract class and interface.**
    
    - Abstract class: can have fields, constructors, concrete methods.
        
    - Interface: methods are public abstract by default (before Java 8), supports multiple inheritance.
        
11. **Explain enhanced switch expressions with an example.** (Java 12+)
    
    - Switch can return a value and use `->` syntax.
        
    
    ```java
    String dayName = switch(day) {
        case 1 -> "Monday";
        default -> "Other";
    };
    ```
    
12. **How can private methods in interfaces be used?** (Java 9+)
    
    - To share reusable code among default methods in an interface.
        

---

## 2. Variables and Memory

1. **What are local, instance, and static variables?**
    
    - Local: declared in methods, exist during method execution.
        
    - Instance: tied to objects, each object has its copy.
        
    - Static: belongs to class, shared among all objects.
        
2. **Explain variable scope in Java.**
    
    - The region of the program where a variable is accessible.
        
3. **Difference between heap and stack memory.**
    
    - Heap: stores objects, shared across threads.
        
    - Stack: stores method calls and local variables, per thread.
        
4. **What is the String pool?**
    
    - Special memory for storing string literals to avoid duplicates.
        
5. **How does garbage collection work in Java?**
    
    - Automatically removes objects no longer referenced.
        
6. **What are memory leaks in Java, and how can they occur?**
    
    - Objects still referenced but not needed. Example: unused objects in collections.
        
7. **Explain escape analysis and stack allocation optimization.**
    
    - JVM can allocate short-lived objects on stack instead of heap if they do not escape method scope.
        

---

## 3. Data Types and Type Casting

1. **Difference between widening and narrowing type casting.**
    
    - Widening: small type → large type, automatic.
        
    - Narrowing: large type → small type, requires explicit cast.
        
2. **Explain upcasting and downcasting with examples.**
    
    - Upcasting: subclass → superclass reference (safe).
        
    - Downcasting: superclass → subclass (needs `instanceof` check).
        
3. **What is the instanceof keyword used for?**
    
    - To check the type of an object before casting.
        
4. **How can you safely downcast an object?**
    
    - Use `instanceof` check.
        
    
    ```java
    if(obj instanceof Dog d){ d.bark(); }
    ```
    
5. **Converting String to primitive types and vice versa.**
    
    - `Integer.parseInt("123")`, `String.valueOf(123)`.
        

---

## 4. Strings, StringBuilder, and StringBuffer

1. **Difference between String, StringBuilder, and StringBuffer.**
    
    - String: immutable.
        
    - StringBuilder: mutable, not thread-safe.
        
    - StringBuffer: mutable, thread-safe.
        
2. **Why is String immutable?**
    
    - To allow caching in String pool and thread safety.
        
3. **What are common String methods in Java?**
    
    - `length()`, `charAt()`, `substring()`, `equals()`, `contains()`, `replace()`.
        
4. **When would you use StringBuilder over StringBuffer?**
    
    - When thread safety is not needed; StringBuilder is faster.
        
5. **Explain String interning.**
    
    - `intern()` ensures a string literal exists in String pool.
        
6. **How to convert between String and char array?**
    
    - `String.toCharArray()`, `new String(charArray)`.
        
7. **Difference between == and equals() when comparing strings.**
    
    - `==` checks reference, `equals()` checks value.
        

---

## 5. Arrays and Loops

1. **How to declare and initialize arrays?**
    
    - `int[] arr = new int[5];`, `int[] arr = {1,2,3};`
        
2. **Difference between 1D and 2D arrays.**
    
    - 1D: single row of elements.
        
    - 2D: rows and columns.
        
3. **Explain jagged arrays with an example.**
    
    - Rows of different lengths:
        
    
    ```java
    int[][] jagged = new int[3][];
    jagged[0] = new int[2];
    jagged[1] = new int[4];
    ```
    
4. **How do you iterate over an array using enhanced for loop?**
    
    - `for(int num : arr) { System.out.println(num); }`
        
5. **Difference between while, do-while, and for loops.**
    
    - while: condition first.
        
    - do-while: executes at least once.
        
    - for: initialization, condition, increment.
        
6. **Explain break and continue statements.**
    
    - break: exits loop.
        
    - continue: skips current iteration.
        
7. **What are labeled loops and when would you use them?**
    
    - Allows breaking/continuing outer loops.
        
8. **How can streams replace traditional loops?** (Java 8+)
    
    - `list.stream().forEach(System.out::println);`
        
9. **Explain pattern matching in loops.** (Java 21+)
    
    - Use `instanceof` in loops to safely cast objects.
        
10. **How to destructure records in loops?** (Java 25 preview)
    
    - `for (Point(int x, int y) p : points) { ... }`
        

---

## 6. Conditionals

1. **Difference between if-else and switch.**
    
    - if-else: evaluates boolean conditions.
        
    - switch: evaluates a value against cases.
        
2. **Explain ternary operator with example.**
    
    - `int max = (a > b) ? a : b;`
        
3. **What is a guard clause?**
    
    - Early return to reduce nested ifs.
        
4. **How does pattern matching improve switch expressions?** (Java 21+)
    
    - Matches types and destructures objects safely.
        
5. **Difference between traditional switch and switch expressions.**
    
    - Switch expressions can return a value and use arrow syntax.
        
6. **How do switch expressions return values?** (Java 12+)
    
    - `String dayName = switch(day) { case 1 -> "Mon"; default -> "Other"; };`
        
7. **What are preview features in Java switch (Java 25)?**
    
    - Record destructuring and enhanced iteration in switch expressions.
        

---

## 7. Math Operations

1. **List all arithmetic operators in Java.**
    
    - `+ - * / %`
        
2. **Difference between / and % operators.**
    
    - `/` division, `%` remainder.
        
3. **Explain increment and decrement operators.**
    
    - `++a`, `a++`, `--a`, `a--`
        
4. **Difference between pre-increment and post-increment.**
    
    - Pre: increments before use, Post: increments after use.
        
5. **Common methods of the Math class.**
    
    - `abs()`, `max()`, `min()`, `sqrt()`, `pow()`, `round()`, `ceil()`, `floor()`, `random()`
        
6. **How to generate random numbers using Math?**
    
    - `Math.random()` returns double between 0.0 and


##### *Tags : [[Java]]