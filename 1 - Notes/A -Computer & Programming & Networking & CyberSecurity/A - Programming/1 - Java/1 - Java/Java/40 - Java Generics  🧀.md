Date : 2025-09-04



## 1. Introduction

- **Generics:** A mechanism to **parameterize types**, introduced in Java 5.
    
- **Purpose:** Enable **type-safe code** and avoid `ClassCastException`.
    
- **Key Benefit:** Write reusable code for multiple types.
    

**Tip:** Think of Generics as **templates** for classes, methods, or interfaces.

---

## 2. Generic Classes

```java
class Box<T> {
    private T content;

    public void set(T content) { this.content = content; }
    public T get() { return content; }
}

Box<String> stringBox = new Box<>();
stringBox.set("Hello");
System.out.println(stringBox.get());
```

- `T` is a **type parameter**.
    
- Can replace `T` with `E`, `K`, `V` for clarity.
    

---

## 3. Generic Methods

```java
public static <T> void printArray(T[] array) {
    for (T element : array) System.out.println(element);
}

Integer[] nums = {1,2,3};
printArray(nums);
```

- `<T>` before return type declares a **generic method**.
    

---

## 4. Wildcards

### 4.1 Unbounded Wildcard `<?>`

- Represents **unknown type**.
    

```java
List<?> list = new ArrayList<String>();
```

### 4.2 Upper-Bounded Wildcard `<? extends T>`

- Accepts **T or its subclasses**.
    

```java
List<? extends Number> numbers;
```

### 4.3 Lower-Bounded Wildcard `<? super T>`

- Accepts **T or its superclasses**.
    

```java
List<? super Integer> list;
```

**Tip:** Use wildcards to **increase API flexibility**.

---

## 5. Generic Interfaces

```java
interface Pair<K, V> {
    K getKey();
    V getValue();
}

class OrderedPair<K, V> implements Pair<K, V> {
    private K key; private V value;
    public OrderedPair(K key, V value) { this.key = key; this.value = value; }
    public K getKey() { return key; }
    public V getValue() { return value; }
}
```

- Provides **type-safe key-value pairs**.
    

---

## 6. Generic Constructors

```java
class MyClass<T> {
    T value;
    <U> MyClass(U data) { System.out.println(data); }
}
```

- Constructors can have **their own type parameters**.
    

---

## 7. Generic Bounds

- **Multiple bounds**: restrict type parameters to **extend a class and implement interfaces**.
    

```java
class Calculator<T extends Number & Comparable<T>> {
    T value;
}
```

- Ensures type safety and flexibility.
    

---

## 8. Type Erasure

- **Generics are erased at runtime**, replaced with `Object` or upper bounds.
    
- Compiler ensures type safety at compile-time.
    
- Can lead to limitations with **instanceof and generic arrays**.
    

```java
// Cannot create generic array
T[] arr = new T[10]; // Error
```

---

## 9. Best Practices

1. Always **use meaningful type parameter names** (`T`, `E`, `K`, `V`).
    
2. Prefer **wildcards for flexibility**.
    
3. Avoid **raw types** to prevent type-safety issues.
    
4. Use **bounded types** to enforce constraints.
    
5. Keep **generic code readable and maintainable**.
    
6. Use **generics with collections** for safer APIs.
    

---

## 10. Real-World Applications

- **Collections Framework:** `List<T>`, `Map<K,V>`, `Set<T>`.
    
- **Utility Methods:** `Collections.max(List<T>)`, `Arrays.asList(T...)`.
    
- **Framework APIs:** Spring Beans, JPA repositories.
    
- **Custom Libraries:** Type-safe utility classes and generic services.
    

---

## 11. Summary

- Generics provide **type safety, reusability, and flexibility**.
    
- Work with classes, methods, constructors, and interfaces.
    
- Use **wildcards, bounds, and meaningful type parameters** for advanced usage.
    
- Modern Java (up to 25) supports generics seamlessly with **collections, streams, and functional APIs**.
    

This guide ensures mastery of **Java Generics from beginner to senior-level**, including all updates up to Java 25.



##### *Tags : [[Java]]