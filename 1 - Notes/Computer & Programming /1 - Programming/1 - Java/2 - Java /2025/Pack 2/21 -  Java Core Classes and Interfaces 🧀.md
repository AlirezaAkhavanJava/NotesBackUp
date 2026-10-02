Date : 2025-09-04

This guide covers essential Java classes and interfaces used in collections, functional programming, iteration, sorting, and concurrency, with practical examples and features up to Java 25 (September 2025). It’s designed for beginners to senior developers, focusing on clarity and real-world applications.

---

## Phase 1: Base Object / Core Classes

### Key Classes

- **Object**: Root class for all Java objects, providing methods like `toString()`, `equals()`, `hashCode()`, and `clone()`.
- **Class**: Used for reflection to inspect class metadata.
- **Enum**: Base for enum types, used in collections like `EnumSet`.
- **String**: Immutable text, widely used in collections.
- **StringBuilder/StringBuffer**: Mutable text for efficient concatenation (`StringBuilder` is faster, `StringBuffer` is thread-safe).
- **Optional**: Avoids null checks, common in streams.
- **Throwable/Exception/RuntimeException**: Handles errors in collection operations.

**Example: Custom Object with equals() and hashCode()**

```java
public class Person {
    private String name;
    private int id;

    public Person(String name, int id) {
        this.name = name;
        this.id = id;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Person person)) return false;
        return id == person.id && name.equals(person.name);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, id);
    }

    public static void main(String[] args) {
        Set<Person> set = new HashSet<>();
        set.add(new Person("Alice", 1));
        set.add(new Person("Alice", 1));
        System.out.println(set.size()); // 1 (duplicates removed)
    }
}
```

**Why Important?**

- `equals()` and `hashCode()` are critical for `HashSet`/`HashMap`.
- `Optional` simplifies null handling in collections.

---

## Phase 2: Functional Interfaces (java.util.function)

Functional interfaces (Java 8+) enable lambda expressions and are used in streams and collections.

### Key Interfaces

- **Function<T,R>**: Maps input to output (`apply`).
- **BiFunction<T,U,R>**: Two inputs to output.
- **Predicate**: Tests condition, returns boolean (`test`).
- **Consumer**: Performs action on input (`accept`).
- **Supplier**: Produces value (`get`).
- **UnaryOperator**: Input and output same type.
- **BinaryOperator**: Two inputs, same type output.
- **Runnable/Callable**: Used in concurrency (covered later).

**Example: Stream with Functional Interfaces**

```java
import java.util.List;
import java.util.function.Predicate;
import java.util.function.Function;

public class Main {
    public static void main(String[] args) {
        List<String> names = List.of("Alice", "Bob", "Charlie");
        Predicate<String> isLong = s -> s.length() > 3;
        Function<String, String> toUpper = String::toUpperCase;
        
        names.stream()
             .filter(isLong)
             .map(toUpper)
             .forEach(System.out::println); // CHARLIE
    }
}
```

**Practice: Frequency Counting with BiConsumer**

```java
import java.util.HashMap;
import java.util.function.BiConsumer;

public class Main {
    public static void main(String[] args) {
        HashMap<String, Integer> map = new HashMap<>();
        BiConsumer<String, Integer> updateCount = (k, v) -> map.merge(k, v, Integer::sum);
        updateCount.accept("apple", 1);
        updateCount.accept("apple", 1);
        System.out.println(map); // {apple=2}
    }
}
```

---

## Phase 3: Iteration & Traversal

### Key Interfaces

- **Iterable**: Enables `for-each` loops in collections.
- **Iterator**: Traverses elements, supports `remove()`.
- **ListIterator**: Bidirectional for lists, supports `add()`, `set()`.
- **Spliterator**: For parallel stream processing, can split data.

**Example: ListIterator for Bidirectional Traversal**

```java
import java.util.ArrayList;
import java.util.ListIterator;

public class Main {
    public static void main(String[] args) {
        ArrayList<String> list = new ArrayList<>(List.of("A", "B", "C"));
        ListIterator<String> iterator = list.listIterator(list.size());
        while (iterator.hasPrevious()) {
            System.out.println(iterator.previous()); // C, B, A
        }
    }
}
```

**Practice: Spliterator with Parallel Streams**

```java
import java.util.List;
import java.util.Spliterator;

public class Main {
    public static void main(String[] args) {
        List<Integer> numbers = List.of(1, 2, 3, 4);
        Spliterator<Integer> spliterator = numbers.spliterator();
        spliterator.forEachRemaining(System.out::println); // 1, 2, 3, 4
    }
}
```

**Key Concept**: Iterators are fail-fast; modifying a collection during iteration throws `ConcurrentModificationException`.

---

## Phase 4: Comparators / Sorting

### Key Interfaces

- **Comparable**: Defines natural ordering (`compareTo`).
- **Comparator**: Custom ordering for collections (`compare`).

**Example: Sorting with Comparator**

```java
import java.util.ArrayList;
import java.util.Comparator;

public class Main {
    public static void main(String[] args) {
        ArrayList<String> list = new ArrayList<>(List.of("Bob", "Alice", "Charlie"));
        list.sort(Comparator.comparingInt(String::length).reversed());
        System.out.println(list); // [Charlie, Alice, Bob]
    }
}
```

**Practice: Custom Comparable**

```java
public class Item implements Comparable<Item> {
    private String name;
    private int price;

    public Item(String name, int price) {
        this.name = name;
        this.price = price;
    }

    @Override
    public int compareTo(Item other) {
        return Integer.compare(this.price, other.price);
    }

    public static void main(String[] args) {
        TreeSet<Item> set = new TreeSet<>();
        set.add(new Item("Apple", 2));
        set.add(new Item("Banana", 1));
        System.out.println(set); // [Banana, Apple]
    }
}
```

---

## Phase 5: Concurrency / Async

### Key Classes/Interfaces

- **Future**: Represents async computation result.
- **CompletableFuture**: Chains async tasks.
- **ExecutorService**: Manages thread pools.
- **Callable**: Task with return value.
- **Runnable**: Task without return.
- **Lock/ReentrantLock**: Manual thread synchronization.
- **ReadWriteLock**: Separate read/write locks.

**Example: CompletableFuture with Collections**

```java
import java.util.List;
import java.util.concurrent.CompletableFuture;

public class Main {
    public static void main(String[] args) {
        List<Integer> numbers = List.of(1, 2, 3);
        CompletableFuture.supplyAsync(() -> 
            numbers.stream().map(n -> n * 2).collect(Collectors.toList())
        ).thenAccept(System.out::println).join(); // [2, 4, 6]
    }
}
```

**Practice: Thread-Safe Collection with ReentrantLock**

```java
import java.util.ArrayList;
import java.util.concurrent.locks.ReentrantLock;

public class ThreadSafeList<T> {
    private ArrayList<T> list = new ArrayList<>();
    private ReentrantLock lock = new ReentrantLock();

    public void add(T item) {
        lock.lock();
        try {
            list.add(item);
        } finally {
            lock.unlock();
        }
    }
}
```

---

## Phase 6: Other Useful Classes

### Key Classes

- **Optional**: Handles null-safe values in streams.
- **Stream/IntStream/DoubleStream**: Functional operations on collections.
- **Map.Entry<K,V>**: Represents key-value pairs in maps.
- **EnumSet/EnumMap**: Optimized for enums.
- **Properties**: Key-value store for configuration.

**Example: EnumSet and EnumMap**

```java
import java.util.EnumSet;
import java.util.EnumMap;

enum Day { MONDAY, TUESDAY, WEDNESDAY }

public class Main {
    public static void main(String[] args) {
        EnumSet<Day> workDays = EnumSet.of(Day.MONDAY, Day.TUESDAY);
        System.out.println(workDays); // [MONDAY, TUESDAY]

        EnumMap<Day, String> schedule = new EnumMap<>(Day.class);
        schedule.put(Day.MONDAY, "Work");
        System.out.println(schedule.get(Day.MONDAY)); // Work
    }
}
```

**Practice: Properties for Configuration**

```java
import java.util.Properties;

public class Main {
    public static void main(String[] args) {
        Properties props = new Properties();
        props.setProperty("db.url", "jdbc:mysql://localhost:3306");
        System.out.println(props.getProperty("db.url")); // jdbc:mysql://localhost:3306
    }
}
```

---

## Java Features Up to Java 25

- **Java 8 (2014)**:
    - Streams and functional interfaces: `list.stream().filter(Predicate.isEqual("A"))`.
    - Lambda expressions: `(a, b) -> a.compareTo(b)` for `Comparator`.
- **Java 9 (2017)**: Immutable collections: `List.of()`, `Set.of()`, `Map.of()`.
- **Java 10 (2018)**: `var` for cleaner code: `var list = new ArrayList<String>();`.
- **Java 14 (2020)**: Records for immutable data.
    
    ```java
    record User(String name, int id) {}
    List<User> users = List.of(new User("Alice", 1));
    ```
    
- **Java 17 (2021)**: Pattern matching for `instanceof`.
    
    ```java
    if (obj instanceof String s) { System.out.println(s); }
    ```
    
- **Java 21 (2023)**: Virtual threads for concurrent collection processing.
    
    ```java
    try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
        executor.submit(() -> list.forEach(System.out::println));
    }
    ```
    
- **Java 25 (2025)**: Implicit classes for utility methods.
    
    ```java
    implicit class CollectionUtils {
        static <T> void print(List<T> list) { list.forEach(System.out::println); }
    }
    ```
    

---

## Best Practices

1. **Override equals()/hashCode()**: Ensure consistency for collections like `HashSet`/`HashMap`.
2. **Use Optional**: Avoid null pointer exceptions in streams.
3. **Leverage Streams**: For concise collection processing.
4. **Choose Thread-Safe Options**: Use `ConcurrentHashMap` or `ReentrantLock` for concurrency.
5. **Test with JUnit**:
    
    ```xml
    <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter</artifactId>
        <version>5.11.0</version>
        <scope>test</scope>
    </dependency>
    ```
    

---

## Real-World Applications

- **Data Processing**: Use streams with `Function`/`Predicate` for transformations.
- **Configuration**: Store settings in `Properties` or `EnumMap`.
- **Async Processing**: Use `CompletableFuture` for parallel collection tasks.
- **Sorting**: Apply `Comparator` for custom ordering in `TreeSet`/`TreeMap`.

---

## Conclusion

Java’s core classes and interfaces like `Object`, functional interfaces, iterators, comparators, and concurrency utilities are foundational for working with collections. They enable flexible, efficient, and thread-safe data manipulation. Use Java 25 features like records and virtual threads to write modern, concise code.



##### *Tags : [[Java]]