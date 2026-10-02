

Project Reactor is a reactive programming library for Java, designed to build non-blocking, asynchronous applications on the JVM. It implements the **Reactive Streams** specification and is widely used in Spring WebFlux for reactive web applications. This tutorial covers Project Reactor from basic concepts to advanced techniques in a simple, step-by-step manner, with examples tailored for beginners and advanced developers. We’ll explore its integration with primitives, collections, atomics, and threads.

## 1. Introduction to Project Reactor

### What is Project Reactor?

Project Reactor provides a framework for handling asynchronous data streams with **backpressure** support. It’s built around two core types:

- **Mono**: Represents a stream that emits 0 or 1 item (e.g., a single database query result).
- **Flux**: Represents a stream that emits 0 to N items (e.g., a stream of log messages).

### Key Features

- Non-blocking and asynchronous processing.
- Rich set of operators for transforming, filtering, and combining streams.
- Backpressure to manage data flow between producers and consumers.
- Integration with Spring for reactive web applications.

### Setup

To use Reactor, add the following dependency to your `pom.xml` (Maven):

```xml
<dependency>
    <groupId>io.projectreactor</groupId>
    <artifactId>reactor-core</artifactId>
    <version>3.5.10</version>
</dependency>
```

For Gradle:

```groovy
implementation 'io.projectreactor:reactor-core:3.5.10'
```

## 2. Basic Concepts

### Creating Mono and Flux

- **Mono**: Use `Mono.just()` for a single item or `Mono.empty()` for no items.
- **Flux**: Use `Flux.just()` for a fixed set of items or `Flux.fromIterable()` for collections.

**Example: Basic Mono and Flux**

```java
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public class BasicReactor {
    public static void main(String[] args) {
        // Mono: Single item
        Mono<String> mono = Mono.just("Hello, Reactor!");
        mono.subscribe(System.out::println);

        // Flux: Multiple items
        Flux<String> flux = Flux.just("Apple", "Banana", "Orange");
        flux.subscribe(System.out::println);
    }
}
```

**Output**:

```
Hello, Reactor!
Apple
Banana
Orange
```

### Subscribing to Streams

To process items, you must **subscribe** to a `Mono` or `Flux`. Without a subscription, no data is emitted (lazy evaluation).

**Example: Subscription**

```java
Flux.just(1, 2, 3)
    .subscribe(
        item -> System.out.println("Item: " + item), // onNext
        error -> System.err.println("Error: " + error), // onError
        () -> System.out.println("Completed") // onComplete
    );
```

**Output**:

```
Item: 1
Item: 2
Item: 3
Completed
```

### Operators

Operators transform or manipulate streams. Common ones include:

- **`map`**: Transform each item.
- **`filter`**: Select items based on a condition.
- **`delayElements`**: Add delays between emissions.

**Example: Basic Operators**

```java
import reactor.core.publisher.Flux;

public class BasicOperators {
    public static void main(String[] args) {
        Flux.just(1, 2, 3, 4, 5)
            .filter(n -> n % 2 == 0) // Keep even numbers
            .map(n -> n * n) // Square them
            .subscribe(System.out::println);
    }
}
```

**Output**:

```
4
16
```

## 3. Intermediate Concepts

### Creating Streams

Beyond `just`, Reactor offers ways to create streams:

- **`Flux.fromIterable`**: From a collection (e.g., List, Set).
- **`Flux.range`**: Generate a sequence of numbers.
- **`Mono.fromSupplier`**: Create from a supplier (lazy evaluation).

**Example: From Collections**

```java
import reactor.core.publisher.Flux;
import java.util.List;

public class CollectionsExample {
    public static void main(String[] args) {
        List<String> fruits = List.of("Apple", "Banana", "Orange");
        Flux.fromIterable(fruits)
            .map(String::toUpperCase)
            .subscribe(System.out::println);
    }
}
```

**Output**:

```
APPLE
BANANA
ORANGE
```

### Error Handling

Reactor provides robust error handling:

- **`onErrorReturn`**: Return a default value on error.
- **`onErrorResume`**: Switch to a fallback stream.
- **`onErrorContinue`**: Skip erroneous items and continue.

**Example: Error Handling**

```java
import reactor.core.publisher.Flux;

public class ErrorHandling {
    public static void main(String[] args) {
        Flux.just(1, 2, 0, 4)
            .map(n -> 10 / n) // Will throw ArithmeticException for 0
            .onErrorResume(e -> Flux.just(-1))
            .subscribe(System.out::println);
    }
}
```

**Output**:

```
10
5
-1
```

### Combining Streams

- **`merge`**: Combine multiple streams, interleaving items.
- **`concat`**: Combine streams sequentially.
- **`zip`**: Pair items from multiple streams.

**Example: Zip**

```java
import reactor.core.publisher.Flux;

public class ZipExample {
    public static void main(String[] args) {
        Flux<Integer> numbers = Flux.just(1, 2, 3);
        Flux<String> letters = Flux.just("A", "B", "C");
        Flux.zip(numbers, letters, (n, l) -> n + l)
            .subscribe(System.out::println);
    }
}
```

**Output**:

```
1A
2B
3C
```

## 4. Advanced Concepts

### Schedulers (Threading)

Reactor uses **Schedulers** to manage threads for non-blocking execution:

- **`Schedulers.single()`**: Single, reusable thread.
- **`Schedulers.parallel()`**: For CPU-intensive tasks.
- **`Schedulers.boundedElastic()`**: For I/O-bound tasks (e.g., database, HTTP).

**Example: Schedulers**

```java
import reactor.core.publisher.Flux;
import reactor.core.scheduler.Schedulers;

public class SchedulerExample {
    public static void main(String[] args) {
        Flux.range(1, 5)
            .publishOn(Schedulers.parallel())
            .map(n -> n + " on thread " + Thread.currentThread().getName())
            .subscribe(System.out::println);
    }
}
```

**Output** (thread names may vary):

```
1 on thread parallel-1
2 on thread parallel-1
...
```

### Backpressure

Backpressure controls the flow of data when a Subscriber is overwhelmed. Strategies include:

- **BUFFER**: Store items until the Subscriber is ready.
- **DROP**: Discard items if the Subscriber can’t keep up.
- **LATEST**: Keep only the latest item.

**Example: Backpressure**

```java
import reactor.core.publisher.Flux;
import java.time.Duration;

public class BackpressureExample {
    public static void main(String[] args) throws InterruptedException {
        Flux.range(1, 10)
            .delayElements(Duration.ofMillis(100))
            .onBackpressureDrop()
            .subscribe(item -> {
                Thread.sleep(200); // Simulate slow consumer
                System.out.println("Processed: " + item);
            });
        Thread.sleep(3000); // Allow time to process
    }
}
```

**Output** (some items may be dropped due to slow processing):

```
Processed: 1
Processed: 3
Processed: 5
...
```

### Hot vs. Cold Publishers

- **Cold Publishers**: Replay all items for each new Subscriber (e.g., `Flux.just()`).
- **Hot Publishers**: Share emissions across Subscribers, potentially missing earlier items (e.g., `ConnectableFlux`).

**Example: Hot Publisher**

```java
import reactor.core.publisher.ConnectableFlux;
import reactor.core.publisher.Flux;
import java.time.Duration;

public class HotPublisher {
    public static void main(String[] args) throws InterruptedException {
        ConnectableFlux<Integer> hotFlux = Flux.range(1, 5)
            .delayElements(Duration.ofMillis(200))
            .publish();
        
        hotFlux.subscribe(n -> System.out.println("Subscriber 1: " + n));
        hotFlux.connect(); // Start emitting
        
        Thread.sleep(500); // Wait before second subscriber
        hotFlux.subscribe(n -> System.out.println("Subscriber 2: " + n));
        
        Thread.sleep(2000); // Allow time to complete
    }
}
```

**Output** (Subscriber 2 misses earlier items):

```
Subscriber 1: 1
Subscriber 1: 2
Subscriber 1: 3
Subscriber 2: 3
Subscriber 1: 4
Subscriber 2: 4
...
```

### Integration with Atomics

`java.util.concurrent.atomic` classes (e.g., `AtomicInteger`) are useful for thread-safe state in reactive applications.

**Example: Counting with AtomicInteger**

```java
import reactor.core.publisher.Flux;
import java.util.concurrent.atomic.AtomicInteger;

public class AtomicExample {
    public static void main(String[] args) {
        AtomicInteger counter = new AtomicInteger(0);
        Flux.range(1, 10)
            .doOnNext(n -> counter.incrementAndGet())
            .subscribe();
        System.out.println("Processed items: " + counter.get());
    }
}
```

**Output**:

```
Processed items: 10
```

### Testing with StepVerifier

`StepVerifier` is used to test reactive streams.

**Example: Testing**

```java
import reactor.core.publisher.Flux;
import reactor.test.StepVerifier;

public class TestExample {
    public static void main(String[] args) {
        Flux<Integer> flux = Flux.just(1, 2, 3);
        StepVerifier.create(flux)
            .expectNext(1, 2, 3)
            .verifyComplete();
    }
}
```

This verifies the stream emits `1, 2, 3` and completes successfully.

### Spring WebFlux Integration

Spring WebFlux uses Reactor for reactive web applications.

**Example: Reactive REST Controller**

```java
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

@RestController
public class ReactiveController {
    @GetMapping("/items")
    public Flux<String> getItems() {
        return Flux.just("Item1", "Item2", "Item3")
                   .delayElements(Duration.ofMillis(500));
    }
}
```

This streams items with a 500ms delay between each.

## 5. Advanced Example: Combining Concepts

This example combines collections, atomics, schedulers, error handling, and backpressure.

```java
import reactor.core.publisher.Flux;
import reactor.core.scheduler.Schedulers;
import java.time.Duration;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

public class AdvancedReactorApp {
    public static void main(String[] args) throws InterruptedException {
        AtomicInteger processedCount = new AtomicInteger(0);
        List<String> data = List.of("data1", "data2", "error", "data4");

        Flux.fromIterable(data)
            .publishOn(Schedulers.boundedElastic())
            .map(item -> {
                if (item.equals("error")) {
                    throw new RuntimeException("Invalid data");
                }
                return item.toUpperCase();
            })
            .onErrorResume(e -> Flux.just("RECOVERED"))
            .doOnNext(item -> processedCount.incrementAndGet())
            .delayElements(Duration.ofMillis(200))
            .onBackpressureBuffer()
            .subscribe(item -> System.out.println("Processed: " + item));

        Thread.sleep(2000);
        System.out.println("Total processed: " + processedCount.get());
    }
}
```

**Output**:

```
Processed: DATA1
Processed: DATA2
Processed: RECOVERED
Processed: DATA4
Total processed: 4
```

## 6. Best Practices

- Use `Mono` for single-value operations (e.g., fetching a single record).
- Use `Flux` for multi-value streams (e.g., streaming logs).
- Use `Schedulers` for thread management instead of manual threads.
- Handle errors explicitly with `onErrorResume` or `onErrorReturn`.
- Apply backpressure (e.g., `onBackpressureBuffer`) for high-throughput streams.
- Test streams with `StepVerifier` for reliability.
- Use `log()` operator for debugging stream operations.

## 7. Advanced Tips

- **Context Propagation**: Use `Mono.deferContextual` to pass contextual data (e.g., user IDs) through the reactive pipeline.
- **ParallelFlux**: Process items in parallel for performance (e.g., `Flux.parallel().runOn(Schedulers.parallel())`).
- **Retry and Timeout**: Use `retry()` or `timeout()` for resilience in network operations.
- **Custom Operators**: Create reusable operators for complex transformations.

## 8. Conclusion

Project Reactor simplifies reactive programming in Java with `Mono` and `Flux`, offering powerful operators, thread management, and error handling. From basic stream creation to advanced patterns like hot publishers and WebFlux integration, Reactor is ideal for building scalable, non-blocking applications. For further learning, explore:

- [Project Reactor Documentation](https://projectreactor.io/)
- [Spring WebFlux](https://spring.io/reactive)

[[44 - Threads 🧀]]