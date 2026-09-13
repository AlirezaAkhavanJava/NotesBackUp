
Reactive programming is a programming paradigm focused on asynchronous data streams and the propagation of change. In Java, reactive programming enables building responsive, scalable, and resilient applications by handling streams of data (e.g., events, messages, or data updates) in a non-blocking, event-driven manner. 

## 1. Basics of Reactive Programming

### What is Reactive Programming?

Reactive programming is based on the concept of **data streams** and **asynchronous event handling**. It emphasizes:

- **Asynchronous**: Operations don’t block the main thread, allowing better resource utilization.
- **Event-driven**: Systems react to events (e.g., user inputs, messages, or data changes).
- **Non-blocking**: Processes continue without waiting for operations to complete.
- **Backpressure**: Mechanisms to handle overwhelming data streams gracefully.

The **Reactive Streams Specification** defines a standard for asynchronous stream processing in Java, focusing on:

- Publisher: Emits a stream of data.
- Subscriber: Consumes the data.
- Subscription: Manages the connection between Publisher and Subscriber.
- Processor: Acts as both a Publisher and Subscriber.

### Core Principles (Reactive Manifesto)

- **Responsive**: Systems respond quickly to user requests.
- **Resilient**: Systems handle failures gracefully.
- **Elastic**: Systems scale under varying loads.
- **Message-driven**: Components communicate asynchronously via messages.

### Basic Example: Reactive Streams

Java’s `java.util.concurrent.Flow` API (introduced in Java 9) provides a minimal implementation of the Reactive Streams specification.

```java
import java.util.concurrent.Flow.*;
import java.util.concurrent.SubmissionPublisher;

public class BasicReactiveExample {
    public static void main(String[] args) {
        SubmissionPublisher<String> publisher = new SubmissionPublisher<>();
        Subscriber<String> subscriber = new Subscriber<>() {
            private Subscription subscription;

            @Override
            public void onSubscribe(Subscription subscription) {
                this.subscription = subscription;
                subscription.request(1); // Request one item
            }

            @Override
            public void onNext(String item) {
                System.out.println("Received: " + item);
                subscription.request(1); // Request next item
            }

            @Override
            public void onError(Throwable throwable) {
                System.err.println("Error: " + throwable.getMessage());
            }

            @Override
            public void onComplete() {
                System.out.println("Done");
            }
        };

        publisher.subscribe(subscriber);
        publisher.submit("Hello, Reactive!");
        publisher.close();
    }
}
```

**Output**:

```
Received: Hello, Reactive!
Done
```

This example demonstrates a simple reactive stream where a `Publisher` emits a single item, and a `Subscriber` processes it asynchronously.

## 2. Key Libraries for Reactive Programming in Java

While `Flow` is basic, libraries like **Reactor** and **RxJava** provide richer APIs for reactive programming.

- **Reactor**: Part of Spring, designed for reactive applications, with `Mono` (0 or 1 item) and `Flux` (0 to N items).
- **RxJava**: A popular library for reactive programming, offering `Observable`, `Single`, `Maybe`, and `Completable`.
- **Akka Streams**: Built on the Actor model, suitable for distributed systems.

### Why Use Libraries?

- Simplified handling of streams, operators, and backpressure.
- Rich set of operators (e.g., `map`, `filter`, `flatMap`).
- Integration with modern frameworks like Spring WebFlux.

## 3. Intermediate Concepts

### Reactive Types

- **Mono**: Represents a stream that emits 0 or 1 item.
    - Example: Fetching a single user from a database.
- **Flux**: Represents a stream that emits 0 to N items.
    - Example: Streaming a list of messages from a server.

### Operators

Reactive libraries provide operators to transform, filter, or combine streams:

- **`map`**: Transform each item.
- **`filter`**: Select items based on a condition.
- **`flatMap`**: Transform items into new streams and flatten the result.
- **`zip`**: Combine multiple streams.
- **`onErrorResume`**: Handle errors by switching to a fallback stream.

### Example with Reactor

```java
import reactor.core.publisher.Flux;

public class ReactorExample {
    public static void main(String[] args) {
        Flux.just(1, 2, 3, 4, 5)
            .filter(n -> n % 2 == 0) // Filter even numbers
            .map(n -> n * n) // Square each number
            .subscribe(System.out::println); // Print results
    }
}
```

**Output**:

```
4
16
```

### Backpressure

Backpressure allows Subscribers to control the rate of data emission from Publishers. For example, a Subscriber can request only a certain number of items using `Subscription.request(n)`.

## 4. Advanced Reactive Programming

### Integration with Collections

Reactive programming works seamlessly with Java’s `Collections` framework using `Flux` or `Observable`.

- Example: Converting a `List` to a `Flux` for reactive processing.

```java
import reactor.core.publisher.Flux;
import java.util.Arrays;

public class CollectionsReactive {
    public static void main(String[] args) {
        Flux.fromIterable(Arrays.asList("apple", "banana", "orange"))
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

### Atomics in Reactive Programming

`java.util.concurrent.atomic` classes (e.g., `AtomicInteger`) are often used in reactive applications for thread-safe state management.

- Example: Counting processed items in a reactive stream.

```java
import reactor.core.publisher.Flux;
import java.util.concurrent.atomic.AtomicInteger;

public class AtomicReactive {
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

### Threading and Schedulers

Reactive programming is inherently asynchronous, and libraries like Reactor and RxJava use **Schedulers** to manage threads.

- **Schedulers.parallel()**: For CPU-intensive tasks.
- **Schedulers.boundedElastic()**: For I/O-bound tasks (e.g., database or network calls).
- Example:

```java
import reactor.core.publisher.Flux;
import reactor.core.scheduler.Schedulers;

public class SchedulerExample {
    public static void main(String[] args) {
        Flux.range(1, 5)
            .publishOn(Schedulers.parallel())
            .map(n -> "Item " + n + " on thread " + Thread.currentThread().getName())
            .subscribe(System.out::println);
    }
}
```

**Output** (thread names may vary):

```
Item 1 on thread parallel-1
Item 2 on thread parallel-1
...
```

### Error Handling

Reactive streams provide robust error-handling mechanisms:

- `onErrorResume`: Switch to a fallback stream on error.
- `onErrorReturn`: Return a default value on error.
- Example:

```java
import reactor.core.publisher.Flux;

public class ErrorHandlingExample {
    public static void main(String[] args) {
        Flux.just(1, 2, 0, 4)
            .map(n -> 10 / n)
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

Advanced operations like `merge`, `concat`, and `zip` combine multiple streams.

- Example with `zip`:

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

### Integration with Spring WebFlux

Spring WebFlux is a reactive framework for building web applications.

- Example: A reactive REST controller.

```java
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

@RestController
public class ReactiveController {
    @GetMapping("/items")
    public Flux<String> getItems() {
        return Flux.just("Item1", "Item2", "Item3");
    }
}
```

This endpoint streams items asynchronously to clients.

## 5. Advanced Patterns

### Hot vs. Cold Publishers

- **Cold Publishers**: Emit data from the beginning for each new Subscriber (e.g., `Flux.just()`).
- **Hot Publishers**: Emit data regardless of Subscribers, sharing the same stream (e.g., `ConnectableFlux`).
- Example (Hot Publisher):

```java
import reactor.core.publisher.ConnectableFlux;
import reactor.core.publisher.Flux;

public class HotPublisherExample {
    public static void main(String[] args) throws InterruptedException {
        ConnectableFlux<Integer> hotFlux = Flux.range(1, 5).publish();
        hotFlux.subscribe(n -> System.out.println("Subscriber 1: " + n));
        hotFlux.connect(); // Start emitting
        Thread.sleep(100);
        hotFlux.subscribe(n -> System.out.println("Subscriber 2: " + n));
    }
}
```

**Output** (Subscriber 2 misses earlier items):

```
Subscriber 1: 1
Subscriber 1: 2
Subscriber 2: 3
Subscriber 2: 4
Subscriber 2: 5
```

### Testing Reactive Code

Use `StepVerifier` (Reactor) or `TestObserver` (RxJava) for testing reactive streams.

- Example with Reactor:

```java
import reactor.core.publisher.Flux;
import reactor.test.StepVerifier;

public class TestReactive {
    public static void main(String[] args) {
        Flux<Integer> flux = Flux.just(1, 2, 3);
        StepVerifier.create(flux)
            .expectNext(1, 2, 3)
            .verifyComplete();
    }
}
```

### Backpressure Strategies

- **BUFFER**: Store items until the Subscriber is ready.
- **DROP**: Discard items if the Subscriber is overwhelmed.
- **LATEST**: Keep only the latest item.
- Example:

```java
import reactor.core.publisher.Flux;

public class BackpressureExample {
    public static void main(String[] args) {
        Flux.range(1, 100)
            .onBackpressureDrop()
            .subscribe(n -> System.out.println("Processed: " + n));
    }
}
```

## 6. Best Practices

- Use `Mono` for single-value operations (e.g., fetching a single record).
- Use `Flux` for multi-value streams (e.g., streaming logs).
- Prefer `Schedulers` for thread management over manual thread creation.
- Handle errors explicitly with `onErrorResume` or `onErrorReturn`.
- Use backpressure to prevent resource exhaustion in high-throughput systems.
- Test reactive streams thoroughly with tools like `StepVerifier`.

## 7. Example: Advanced Reactive Application

This example combines collections, atomics, threads, and error handling in a reactive pipeline.

```java
import reactor.core.publisher.Flux;
import reactor.core.scheduler.Schedulers;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.List;

public class AdvancedReactiveApp {
    public static void main(String[] args) {
        AtomicInteger processedCount = new AtomicInteger(0);
        List<String> data = List.of("data1", "data2", "data3", "error", "data5");

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
            .subscribe(item -> System.out.println("Processed: " + item));

        System.out.println("Total processed: " + processedCount.get());
    }
}
```

**Output**:

```
Processed: DATA1
Processed: DATA2
Processed: DATA3
Processed: RECOVERED
Processed: DATA5
Total processed: 5
```

## 8. Conclusion

Reactive programming in Java, powered by libraries like Reactor and RxJava, enables building scalable, non-blocking applications. From basic streams with `Flow` to advanced patterns with `Flux`, `Mono`, and `Schedulers`, it integrates well with primitives, atomics, collections, and threading models. By mastering operators, error handling, and backpressure, developers can create robust, responsive systems.

For further exploration, check out:

- Reactor: [https://projectreactor.io](https://projectreactor.io/)
- RxJava: [https://github.com/ReactiveX/RxJava](https://github.com/ReactiveX/RxJava)
- Spring WebFlux: [https://spring.io/reactive](https://spring.io/reactive)


[[Java]] 