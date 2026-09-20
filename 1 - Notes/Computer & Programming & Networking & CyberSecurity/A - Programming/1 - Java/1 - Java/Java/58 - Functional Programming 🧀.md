
## Phase 1: High-Order Functions

### What are High-Order Functions?

High-order functions are functions that take other functions as arguments or return functions as results. In Java, they are implemented using lambda expressions or method references, leveraging functional interfaces.

### Key Characteristics

- **Accept Functions**: Pass lambdas or method references as parameters.
- **Return Functions**: Return lambda expressions for deferred execution.
- **Enable Abstraction**: Simplify code by abstracting behavior.

**Example: High-Order Function with Lambda**

```java
import java.util.function.Function;

public class Main {
    public static void main(String[] args) {
        Function<Integer, Integer> doubleIt = x -> x * 2;
        Function<Integer, Integer> addTen = x -> x + 10;

        // High-order function: applies a given function
        Integer result = applyFunction(5, doubleIt);
        System.out.println("Result: " + result); // 10
    }

    static Integer applyFunction(Integer input, Function<Integer, Integer> func) {
        return func.apply(input);
    }
}
```

**Key Points**:

- Java uses functional interfaces (e.g., `Function<T,R>`) to emulate high-order functions.
- Lambdas (`x -> x * 2`) or method references (`String::toUpperCase`) act as function arguments.

---

## Phase 2: Functional Interfaces

### What are Functional Interfaces?

A functional interface is an interface with a single abstract method (SAM), usable with lambda expressions or method references. Java provides built-in functional interfaces in `java.util.function`.

### Key Functional Interfaces

- **Function<T,R>**: Maps input to output (`apply`).
- **Predicate**: Tests a condition, returns boolean (`test`).
- **Consumer**: Performs an action, no return (`accept`).
- **Supplier**: Produces a value, no input (`get`).
- **UnaryOperator**: Input and output of same type (`apply`).
- **BiFunction<T,U,R>**: Two inputs to output (`apply`).

**Example: Using Functional Interfaces**

```java
import java.util.function.Predicate;
import java.util.function.Consumer;

public class Main {
    public static void main(String[] args) {
        Predicate<String> isLong = s -> s.length() > 3;
        Consumer<String> printUpper = s -> System.out.println(s.toUpperCase());

        String text = "Hello";
        if (isLong.test(text)) {
            printUpper.accept(text); // HELLO
        }
    }
}
```

**Key Points**:

- Annotate custom functional interfaces with `@FunctionalInterface` for clarity.
- Use lambdas or method references to implement functional interfaces.

**Example: Custom Functional Interface**

```java
@FunctionalInterface
interface Transformer {
    String transform(String input);
}

public class Main {
    public static void main(String[] args) {
        Transformer upper = String::toUpperCase;
        System.out.println(upper.transform("hello")); // HELLO
    }
}
```

---

## Phase 3: Functional Composition

### What is Functional Composition?

Functional composition combines multiple functions to create a new function. Java supports composition with methods like `andThen`, `compose`, `and`, `or`, and `negate` in functional interfaces.

### Key Composition Methods

- **Function.andThen**: Applies one function after another (`f(g(x))`).
- **Function.compose**: Applies one function before another (`g(f(x))`).
- **Predicate.and/or/negate**: Combines predicates logically.

**Example: Function Composition**

```java
import java.util.function.Function;

public class Main {
    public static void main(String[] args) {
        Function<Integer, Integer> doubleIt = x -> x * 2;
        Function<Integer, Integer> addTen = x -> x + 10;

        // andThen: doubleIt then addTen
        Function<Integer, Integer> doubleThenAdd = doubleIt.andThen(addTen);
        System.out.println(doubleThenAdd.apply(5)); // (5 * 2) + 10 = 20

        // compose: addTen then doubleIt
        Function<Integer, Integer> addThenDouble = doubleIt.compose(addTen);
        System.out.println(addThenDouble.apply(5)); // (5 + 10) * 2 = 30
    }
}
```

**Example: Predicate Composition**

```java
import java.util.function.Predicate;

public class Main {
    public static void main(String[] args) {
        Predicate<String> isLong = s -> s.length() > 3;
        Predicate<String> startsWithA = s -> s.startsWith("A");

        Predicate<String> longAndStartsWithA = isLong.and(startsWithA);
        System.out.println(longAndStartsWithA.test("Apple")); // true
        System.out.println(longAndStartsWithA.test("Ant")); // false
    }
}
```

**Key Points**:

- Composition creates reusable, modular code.
- Use `andThen` for sequential operations, `compose` for reversed order.

---

## Phase 4: Streams API

### What is the Streams API?

The Streams API (`java.util.stream`) processes collections in a functional, declarative way. Streams support operations like filtering, mapping, and reducing, with parallel execution for performance.

### Key Stream Operations

- **Intermediate**: `filter`, `map`, `sorted` (return a new stream).
- **Terminal**: `collect`, `forEach`, `reduce` (produce a result or side effect).
- **Short-Circuiting**: `findFirst`, `anyMatch` (stop early).

**Example: Basic Stream Operations**

```java
import java.util.List;
import java.util.stream.Collectors;

public class Main {
    public static void main(String[] args) {
        List<String> names = List.of("Alice", "Bob", "Charlie");
        List<String> result = names.stream()
                                  .filter(s -> s.length() > 3)
                                  .map(String::toUpperCase)
                                  .collect(Collectors.toList());
        System.out.println(result); // [ALICE, CHARLIE]
    }
}
```

**Key Points**:

- Streams are lazy; intermediate operations execute only when a terminal operation is called.
- Use `Collectors` for common operations like `toList()`, `toMap()`.

### Parallel Streams

Parallel streams use multiple threads for faster processing of large datasets.

**Example: Parallel Stream**

```java
import java.util.List;

public class Main {
    public static void main(String[] args) {
        List<Integer> numbers = List.of(1, 2, 3, 4, 5);
        numbers.parallelStream()
               .map(n -> n * 2)
               .forEach(n -> System.out.println(n + " by " + Thread.currentThread().getName()));
    }
}
```

**Output** (varies by thread):

```
2 by ForkJoinPool.commonPool-worker-1
4 by ForkJoinPool.commonPool-worker-2
6 by main
8 by ForkJoinPool.commonPool-worker-1
10 by main
```

---

## Phase 5: Advanced Functional Programming

### Combining Streams and Functional Composition

Use composed functions within streams for complex transformations.

**Example: Composed Functions in Streams**

```java
import java.util.List;
import java.util.function.Function;

public class Main {
    public static void main(String[] args) {
        Function<String, String> trim = String::trim;
        Function<String, String> upper = String::toUpperCase;
        Function<String, String> transform = trim.andThen(upper);

        List<String> names = List.of("  alice  ", "  bob  ");
        List<String> result = names.stream()
                                  .map(transform)
                                  .collect(Collectors.toList());
        System.out.println(result); // [ALICE, BOB]
    }
}
```

### Concurrent Streams with Virtual Threads

Use virtual threads (Java 21+) for scalable stream processing.

**Example: Concurrent Stream Processing**

```java
import java.util.List;
import java.util.concurrent.Executors;

public class Main {
    public static void main(String[] args) {
        List<String> data = List.of("Alice", "Bob", "Charlie");
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            data.stream().forEach(item -> 
                executor.submit(() -> 
                    System.out.println(item.toUpperCase() + " by " + Thread.currentThread().getName())
                )
            );
        }
    }
}
```

**Output**:

```
ALICE by VirtualThread[#1]
BOB by VirtualThread[#2]
CHARLIE by VirtualThread[#3]
```

### Custom Collectors

Create custom collectors for specialized stream operations.

**Example: Custom Collector**

```java
import java.util.stream.Collector;
import java.util.Set;

public class Main {
    public static void main(String[] args) {
        Collector<String, StringBuilder, String> toConcatString = 
            Collector.of(StringBuilder::new, 
                         StringBuilder::append, 
                         StringBuilder::append, 
                         StringBuilder::toString);
        
        String result = List.of("a", "b", "c").stream()
                                             .collect(toConcatString);
        System.out.println(result); // abc
    }
}
```

---

## Java Features Up to Java 25 for Functional Programming

- **Java 8 (2014)**:
    
    - **Streams API**: Enabled functional-style data processing.
    - **Lambda Expressions**: Simplified functional interface implementations.
        
        ```java
        List.of(1, 2, 3).stream().map(x -> x * 2).forEach(System.out::println);
        ```
        
    - **Functional Interfaces**: Added `Function`, `Predicate`, etc., in `java.util.function`.
- **Java 9 (2017)**:
    
    - **Stream Enhancements**: Added `takeWhile`, `dropWhile`, `ofNullable`.
        
        ```java
        Stream.of(1, 2, 0, 3).takeWhile(n -> n > 0).forEach(System.out::println); // 1, 2
        ```
        
- **Java 10 (2018)**:
    
    - **var**: Cleaner code for lambda parameters.
        
        ```java
        var list = List.of("a", "b");
        list.stream().map(s -> s.toUpperCase()).forEach(System.out::println);
        ```
        
- **Java 14 (2020)**:
    
    - **Records**: Use for immutable data in streams.
        
        ```java
        record User(String name, int age) {}
        List.of(new User("Alice", 25)).stream().map(User::name).forEach(System.out::println);
        ```
        
- **Java 17 (2021)**:
    
    - **Pattern Matching for `instanceof`**:
        
        ```java
        if (obj instanceof List<?> list) {
            list.stream().forEach(System.out::println);
        }
        ```
        
- **Java 21 (2023)**:
    
    - **Virtual Threads**: Scalable stream processing (shown above).
    - **Structured Concurrency (Preview)**: Manage parallel stream tasks.
        
        ```java
        import java.util.concurrent.StructuredTaskScope;
        
        try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
            var future = scope.fork(() -> List.of(1, 2).stream().map(x -> x * 2).toList());
            scope.join().throwIfFailed();
            System.out.println(future.get()); // [2, 4]
        }
        ```
        
- **Java 25 (2025)**:
    
    - **Implicit Classes**: Simplify functional utilities.
        
        ```java
        implicit class StreamUtils {
            static <T> void printStream(Stream<T> stream) {
                stream.forEach(System.out::println);
            }
        }
        ```
        
    - **Flexible Constructor Bodies**: Validate functional configurations.
        
        ```java
        class Processor {
            private Function<String, String> transformer;
            Processor(Function<String, String> transformer) {
                this.transformer = transformer;
                if (transformer == null) throw new IllegalArgumentException("Transformer cannot be null");
            }
        }
        ```
        

---

## Best Practices

1. **Use Functional Interfaces**: Prefer built-in interfaces like `Function` or `Predicate` for clarity.
2. **Compose Functions**: Combine functions to reduce code duplication.
3. **Optimize Streams**: Avoid unnecessary stream operations; use short-circuiting where possible.
4. **Handle Parallel Streams Carefully**: Use for CPU-bound tasks, but monitor resource usage.
5. **Test with JUnit**:
    
    ```xml
    <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter</artifactId>
        <version>5.11.0</version>
        <scope>test</scope>
    </dependency>
    ```
    

**Related Library: Vavr**  
For advanced functional programming:

```xml
<dependency>
    <groupId>io.vavr</groupId>
    <artifactId>vavr</artifactId>
    <version>0.10.4</version> <!-- Check latest -->
</dependency>
```

**Example with Vavr**:

```java
import io.vavr.Function1;

public class Main {
    public static void main(String[] args) {
        Function1<Integer, Integer> doubleIt = x -> x * 2;
        Function1<Integer, Integer> addTen = x -> x + 10;
        Function1<Integer, Integer> composed = doubleIt.andThen(addTen);
        System.out.println(composed.apply(5)); // 20
    }
}
```

---

## Real-World Applications

- **Data Processing**: Transform and filter large datasets with streams.
- **API Development**: Map request/response data using functional composition.
- **Concurrent Processing**: Use parallel streams or virtual threads for scalable data handling.
- **Testing**: Validate functional transformations with JUnit.

---

## Conclusion

Java’s functional programming features, including high-order functions, functional interfaces, composition, and streams, enable concise, declarative code. Start with lambdas and built-in interfaces, use composition for modularity, and leverage streams for data processing. Java 25 features like virtual threads and implicit classes enhance scalability and simplicity for functional programming tasks.



##### *Tags : [[Java]]