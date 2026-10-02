## Overview

Generics in Java allow you to write flexible, reusable code that works with different data types while keeping your code safe and clear. They let you define classes, interfaces, and methods that can work with any type, like a placeholder for a type. This note starts with the basics of generics and moves to advanced topics, explaining everything step-by-step as if you’re learning from scratch.

## 1. Basics of Generics

### What Are Generics?

Generics let you create classes, interfaces, or methods that can work with any data type (e.g., String, Integer, or custom objects) without writing separate code for each type. They were introduced in Java 5 to make code safer and avoid errors when working with objects.

- **Why use generics?**
    - **Type safety**: Catch type-related errors at compile time, not runtime.
    - **No casting**: You don’t need to manually convert (cast) objects to specific types.
    - **Reusable code**: Write one piece of code that works for many types.

### Simple Example

Imagine a box that can hold any one type of item, like a String or an Integer. Without generics, you’d use `Object`, which isn’t safe because you could put the wrong type in the box. Generics let you specify the type.

```java
// Without generics (unsafe)
class Box {
    private Object item;

    public void setItem(Object item) {
        this.item = item;
    }

    public Object getItem() {
        return item;
    }
}

public class Main {
    public static void main(String[] args) {
        Box box = new Box();
        box.setItem("Hello"); // Works, but not type-safe
        String value = (String) box.getItem(); // Needs casting
        // Problem: box.setItem(123); would compile but fail at runtime
    }
}
```

```java
// With generics (safe)
class GenericBox<T> { // T is a placeholder for any type
    private T item;

    public void setItem(T item) {
        this.item = item;
    }

    public T getItem() {
        return item;
    }
}

public class Main {
    public static void main(String[] args) {
        GenericBox<String> box = new GenericBox<>(); // Box for Strings
        box.setItem("Hello"); // Only Strings allowed
        String value = box.getItem(); // No casting needed
        // box.setItem(123); // Compile-time error: wrong type
    }
}
```

- **Key point**: `<T>` is a type parameter, a placeholder for the actual type (e.g., `String`, `Integer`) you specify when using the class.

## 2. Core Concepts

### Type Parameters

- A type parameter (like `T`) is a placeholder for a type. You define it in angle brackets (`< >`).
- Common names: `T` (type), `E` (element), `K` (key), `V` (value).
- Used in classes, interfaces, or methods.

### Generic Classes

A generic class is a class with one or more type parameters.

```java
class Pair<K, V> { // Two type parameters: K and V
    private K key;
    private V value;

    public Pair(K key, V value) {
        this.key = key;
        this.value = value;
    }

    public K getKey() {
        return key;
    }

    public V getValue() {
        return value;
    }
}

public class Main {
    public static void main(String[] args) {
        Pair<String, Integer> pair = new Pair<>("Age", 25);
        System.out.println(pair.getKey() + ": " + pair.getValue()); // Age: 25
    }
}
```

### Generic Methods

A method can be generic, with its own type parameter, even in a non-generic class.

```java
public class Util {
    public static <T> void print(T item) { // Generic method
        System.out.println(item);
    }

    public static void main(String[] args) {
        Util.print("Hello"); // Works with String
        Util.print(123); // Works with Integer
    }
}
```

### Diamond Operator

The `<>` (diamond operator) lets you skip repeating the type when creating an object, as Java infers it.

```java
GenericBox<String> box = new GenericBox<>(); // No need to write <String> twice
```

## 3. Intermediate Concepts

### Bounded Type Parameters

Sometimes, you want to limit the types that can be used with generics. Use `extends` to set an upper bound.

- **Syntax**: `<T extends SomeClass>` (T must be SomeClass or its subclass).
- Can also bound to interfaces: `<T extends SomeInterface>`.

```java
class NumberBox<T extends Number> { // Only Number or subclasses (Integer, Double, etc.)
    private T number;

    public NumberBox(T number) {
        this.number = number;
    }

    public double square() {
        return number.doubleValue() * number.doubleValue();
    }
}

public class Main {
    public static void main(String[] args) {
        NumberBox<Integer> intBox = new NumberBox<>(5);
        System.out.println(intBox.square()); // 25.0
        // NumberBox<String> strBox = new NumberBox<>("Hello"); // Compile error
    }
}
```

### Wildcards

Wildcards (`?`) are used when you don’t care about the exact type or want flexibility.

- **Unbounded wildcard**: `<?>` (any type).
- **Upper-bounded wildcard**: `<? extends SomeClass>` (SomeClass or its subclasses).
- **Lower-bounded wildcard**: `<? super SomeClass>` (SomeClass or its superclasses).

```java
public class Main {
    // Method accepts a List of any type
    public static void printList(List<?> list) {
        for (Object item : list) {
            System.out.println(item);
        }
    }

    // Method accepts a List of Number or its subclasses
    public static void sumNumbers(List<? extends Number> list) {
        double sum = 0;
        for (Number num : list) {
            sum += num.doubleValue();
        }
        System.out.println("Sum: " + sum);
    }

    // Method accepts a List of Number or its superclasses
    public static void addNumber(List<? super Integer> list) {
        list.add(42); // Can add Integers
    }

    public static void main(String[] args) {
        List<String> strings = List.of("A", "B");
        List<Integer> numbers = List.of(1, 2, 3);
        List<Object> objects = new ArrayList<>();

        printList(strings); // Works with any type
        sumNumbers(numbers); // Works with Numbers
        addNumber(objects); // Works with Object (superclass of Integer)
    }
}
```

### PECS Principle

- **PECS**: Producer Extends, Consumer Super.
- Use `<? extends T>` when you only read from a collection (producer).
- Use `<? super T>` when you only write to a collection (consumer).

## 4. Advanced Concepts

### Type Erasure

Java removes generic type information at runtime (type erasure) to maintain compatibility with older Java code.

- At compile time, `<T>` ensures type safety.
- At runtime, `<T>` becomes `Object` (or the bounded type, like `Number`).
- You can’t use generics with `instanceof` or create objects like `new T()`.

```java
// After type erasure, this becomes:
class GenericBox {
    private Object item; // T is erased to Object
    public void setItem(Object item) { this.item = item; }
    public Object getItem() { return item; }
}
```

### Generic Interfaces

Interfaces can be generic, just like classes.

```java
interface Processor<T> {
    T process(T input);
}

class StringProcessor implements Processor<String> {
    @Override
    public String process(String input) {
        return input.toUpperCase();
    }
}

public class Main {
    public static void main(String[] args) {
        Processor<String> processor = new StringProcessor();
        System.out.println(processor.process("hello")); // HELLO
    }
}
```

### Generic Methods with Multiple Bounds

A type parameter can have multiple bounds (e.g., a class and interfaces).

```java
class MultiBound<T extends Number & Comparable<T>> {
    public T max(T a, T b) {
        return a.compareTo(b) > 0 ? a : b;
    }
}

public class Main {
    public static void main(String[] args) {
        MultiBound<Integer> mb = new MultiBound<>();
        System.out.println(mb.max(5, 10)); // 10
    }
}
```

### Generic Constraints in Spring Boot

In Spring Boot, generics are common in repositories and services.

```java
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {
    // User is the entity type, Long is the ID type
}
```

### Raw Types

A raw type is a generic class used without specifying a type (e.g., `List` instead of `List<String>`). Avoid raw types, as they bypass type safety.

```java
List list = new ArrayList(); // Raw type (unsafe)
list.add("Hello");
list.add(123); // No compile-time error, but risky
```

### Generic Type Inference

Java can infer types in some cases, reducing code.

```java
// Before Java 7
Map<String, List<Integer>> map = new HashMap<String, List<Integer>>();

// Java 7+ with diamond operator
Map<String, List<Integer>> map = new HashMap<>();

// Java 10+ with var (local variable type inference)
var map = new HashMap<String, List<Integer>>();
```

### Bridge Methods

When a generic class implements a generic interface, Java creates synthetic "bridge methods" to handle type erasure.

```java
interface Container<T> {
    T get();
}

class StringContainer implements Container<String> {
    public String get() {
        return "Hello";
    }
}

// After type erasure, Java adds a bridge method:
// Object get() { return get(); } // Calls String get()
```

### Recursive Type Bounds

Used for types that reference themselves, common in enums or comparable types.

```java
class Node<T extends Comparable<T>> implements Comparable<Node<T>> {
    private T value;

    public Node(T value) {
        this.value = value;
    }

    @Override
    public int compareTo(Node<T> other) {
        return value.compareTo(other.value);
    }
}
```

### Generic Wildcard Capture

Sometimes, you need to "capture" a wildcard type for use in a method.

```java
public static void reverse(List<?> list) {
    // Helper method to capture wildcard
    reverseHelper(list);
}

private static <T> void reverseHelper(List<T> list) {
    Collections.reverse(list);
}
```

## 5. Using Generics in Spring Boot

### Generic Repositories

Spring Data JPA uses generics to define repositories for different entities.

```java
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProductRepository extends JpaRepository<Product, Long> {
    List<Product> findByName(String name);
}
```

### Generic Services

Services can use generics to handle multiple types.

```java
@Service
class GenericService<T> {
    private final JpaRepository<T, Long> repository;

    public GenericService(JpaRepository<T, Long> repository) {
        this.repository = repository;
    }

    public T save(T entity) {
        return repository.save(entity);
    }
}
```

### REST Controllers with Generics

Generic DTOs or responses in REST APIs.

```java
@RestController
public class GenericController<T> {
    @GetMapping("/items")
    public List<T> getItems() {
        return List.of(); // Example
    }
}
```

## 6. Best Practices

- **Use generics for type safety**: Avoid raw types.
- **Choose meaningful type parameter names**: Use `T`, `E`, `K`, `V`, or descriptive names like `Item`.
- **Use bounded types when needed**: Restrict types to avoid errors (e.g., `<T extends Number>`).
- **Follow PECS**: Use `extends` for reading, `super` for writing.
- **Avoid complex generics in public APIs**: Keep them simple for readability.
- **Document generic types**: Use Javadoc to explain type parameters.
- **Test generic code**: Ensure it works with different types.

## 7. Common Pitfalls

- **Type erasure limitations**: You can’t create `new T()` or use `instanceof` with generic types.
- **Raw type warnings**: Always specify types to avoid compiler warnings.
- **Wildcard overuse**: Use wildcards only when needed to keep code clear.
- **Generic arrays**: Avoid creating arrays of generic types (e.g., `T[]`) due to type erasure.

## 8. Advanced Example: Generic DAO

A generic Data Access Object (DAO) pattern in Spring Boot.

```java
import org.springframework.data.jpa.repository.JpaRepository;

public interface GenericDao<T, ID> extends JpaRepository<T, ID> {
}

@Service
class GenericService<T, ID> {
    private final GenericDao<T, ID> dao;

    public GenericService(GenericDao<T, ID> dao) {
        this.dao = dao;
    }

    public T save(T entity) {
        return dao.save(entity);
    }

    public Optional<T> findById(ID id) {
        return dao.findById(id);
    }
}

@Entity
class Product {
    @Id
    private Long id;
    private String name;

    // Getters and setters
}

@Repository
interface ProductRepository extends GenericDao<Product, Long> {
}

@RestController
@RequestMapping("/products")
class ProductController {
    private final GenericService<Product, Long> service;

    public ProductController(GenericService<Product, Long> service) {
        this.service = service;
    }

    @PostMapping
    public Product createProduct(@RequestBody Product product) {
        return service.save(product);
    }
}
```

## Resources

- [Java Generics Tutorial (Oracle)](https://docs.oracle.com/javase/tutorial/java/generics/index.html)
- [Baeldung: Java Generics](https://www.baeldung.com/java-generics)
- [Spring Data JPA Documentation](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/)

## Tags

[[Java]]