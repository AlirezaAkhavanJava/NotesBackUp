
In programming, **provider** and **consumer** are complementary roles.

- **Provider** — something that **supplies** or **produces** a value, object, service, or data on demand.
- **Consumer** — something that **accepts**, **uses**, or **processes** a value, object, service, or data.

In other words:

```
Provider  →  produces / gives  →  Consumer
```

A provider is a source. A consumer is a sink.

---

## In Java

Java has standard functional interfaces for these roles, though the names are slightly different.

### `Consumer<T>`

`java.util.function.Consumer<T>` is the standard **consumer** functional interface.

```java
@FunctionalInterface
public interface Consumer<T> {
    void accept(T t);
}
```

It takes one argument and returns nothing. It “consumes” the value.

Example:

```java
Consumer<String> printer = System.out::println;
printer.accept("Hello");   // prints Hello

List<String> names = List.of("Alice", "Bob");
names.forEach(printer);    // consumes each name
```

Common uses in the Stream API:

```java
stream.forEach(System.out::println);   // Consumer
stream.peek(System.out::println);      // Consumer
```

---

### `Supplier<T>` — the usual “provider” in `java.util.function`

Java’s standard functional interface for supplying a value is `Supplier<T>`, not `Provider<T>`.

```java
@FunctionalInterface
public interface Supplier<T> {
    T get();
}
```

It takes no arguments and returns a value.

Example:

```java
Supplier<LocalDate> today = LocalDate::now;
LocalDate date = today.get();

Supplier<UUID> idGenerator = UUID::randomUUID;
UUID id = idGenerator.get();
```

Common uses in the Stream API:

```java
optional.orElseGet(() -> computeDefault());   // Supplier
stream.collect(
    ArrayList::new,        // Supplier of the mutable container
    ArrayList::add,        // BiConsumer accumulator
    ArrayList::addAll      // BiConsumer combiner
);
```

So in `java.util.function`:

| Role | Interface | Method | Meaning |
|---|---|---|---|
| Provider | `Supplier<T>` | `T get()` | Supplies a value |
| Consumer | `Consumer<T>` | `void accept(T t)` | Consumes a value |

---

## `Provider<T>` in dependency injection

Some Java frameworks use the name `Provider<T>` directly.

- `javax.inject.Provider<T>`
- `jakarta.inject.Provider<T>`

```java
public interface Provider<T> {
    T get();
}
```

It is used to obtain instances, often lazily or within a scope.

Example:

```java
@Inject
Provider<Connection> connectionProvider;

public void useConnection() {
    Connection conn = connectionProvider.get();
    // use conn
}
```

Here the `Provider` is a **provider of objects**, not a standard `java.util.function` interface.

---

## In concurrency: producer / consumer

In concurrent programming, you will more often hear **producer** and **consumer** rather than provider and consumer.

- **Producer** — generates data and puts it into a shared buffer or queue.
- **Consumer** — takes data from the queue and processes it.

Example with `BlockingQueue`:

```java
BlockingQueue<Order> queue = new LinkedBlockingQueue<>();

// Producer
new Thread(() -> {
    queue.put(new Order());
}).start();

// Consumer
new Thread(() -> {
    Order order = queue.take();
    process(order);
}).start();
```

Here “producer” is essentially the provider role: it provides data. The consumer consumes it.

---

## Summary

| Term | General meaning | Java equivalent |
|---|---|---|
| **Provider** | Supplies/produces a value or service | `Supplier<T>` in `java.util.function`; `Provider<T>` in DI frameworks |
| **Consumer** | Accepts/processes a value | `Consumer<T>` in `java.util.function` |
| **Producer** | Generates data into a buffer/queue | Often implemented with threads + `BlockingQueue` |
| **Consumer** (concurrency) | Takes data from a buffer/queue | Often implemented with threads + `BlockingQueue` |

So:

- **Provider** = gives something.
- **Consumer** = takes something.
- In Java’s standard functional API, the provider role is usually called **`Supplier`**, and the consumer role is **`Consumer`**.
- In dependency injection, **`Provider<T>`** is a common interface for obtaining instances.
- In concurrency, the same idea appears as the **producer/consumer** pattern.


[[Java]]