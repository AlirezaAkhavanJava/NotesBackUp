
Stream was introduced in Java 8, the Stream API is used to process collections of objects. A stream in Java is a sequence of objects that supports various methods that can be pipelined to produce the desired result.

### Java Stream Features

The features of Java streams are mentioned below:

- A Stream is not a data structure; it just takes input from Collections, Arrays or I/O channels.
- Streams do not modify the original data; they only produce results using their methods.
- Intermediate operations (like filter, map, etc.) are lazy and return another Stream, so you can chain them together.
- A terminal operation (like collect, forEach, count) ends the stream and gives the final result.

> When you work with streams, most operations (such as filtering, mapping, and sorting) are **intermediate operations that are lazily executed**. This means they don't perform any computation until a terminal operation (like collect , forEach , or reduce ) is invoked. Here's an example to illustrate this: Java.

### Different Operations On Streams

There are two types of Operations in Streams:

1. Intermediate Operations
2. Terminal Operations

![[Pasted image 20251215064220.png]]

Intermediate Operations are the types of operations in which multiple methods are chained in a row.

### Characteristics of Intermediate Operations

- Methods are chained together.
- Intermediate operations transform a stream into another stream.
- It enables the concept of filtering where one method filters data and passes it to another method after processing.

Here’s a clean, complete table of Java Stream intermediate operations (Java 8+).  
Intermediate ops are **lazy** and return a new `Stream`.

|Operation|Stream Type|What it does|Example|
|---|---|---|---|
|`filter`|All|Keeps elements that match a condition|`s.filter(x -> x > 10)`|
|`map`|All|Transforms each element|`s.map(x -> x * 2)`|
|`mapToInt`|Stream → IntStream|Converts to `IntStream`|`s.mapToInt(Integer::intValue)`|
|`mapToLong`|Stream → LongStream|Converts to `LongStream`|`s.mapToLong(Long::valueOf)`|
|`mapToDouble`|Stream → DoubleStream|Converts to `DoubleStream`|`s.mapToDouble(Double::valueOf)`|
|`flatMap`|All|Flattens nested streams|`s.flatMap(List::stream)`|
|`flatMapToInt`|Stream → IntStream|Flat-map to `IntStream`|`s.flatMapToInt(x -> IntStream.of(x))`|
|`distinct`|All|Removes duplicates|`s.distinct()`|
|`sorted`|All|Sorts elements (natural)|`s.sorted()`|
|`sorted(Comparator)`|All|Sorts using comparator|`s.sorted(comp)`|
|`peek`|All|Performs action without modifying stream|`s.peek(System.out::println)`|
|`limit`|All|Takes first N elements|`s.limit(5)`|
|`skip`|All|Skips first N elements|`s.skip(3)`|
|`takeWhile`|All (Java 9+)|Takes while condition is true|`s.takeWhile(x -> x < 50)`|
|`dropWhile`|All (Java 9+)|Drops while condition is true|`s.dropWhile(x -> x < 50)`|
|`boxed`|Primitive streams|Converts primitive to boxed stream|`IntStream.range(1,5).boxed()`|
|`sequential`|All|Forces sequential execution|`s.sequential()`|
|`parallel`|All|Enables parallel execution|`s.parallel()`|
|`unordered`|All|Removes ordering constraint|`s.unordered()`|

### Key facts (important):

- **No execution happens** until a **terminal operation** is called.
    
- You can chain **unlimited intermediate operations**.
    
- `peek()` is for **debugging**, not business logic.



>  ***Note:*** Intermediate Operations are running based on the concept of Lazy Evaluation, which ensures that every method returns a fixed value(Terminal operation) before moving to the next method.


---

## Terminal Operations

Terminal Operations are the type of Operations that return the result. These Operations are not processed further just return a final result value.

Terminal ops consume the stream and return a non-stream result (value or side-effect).

|Terminal Operation|Takes (Functional Interface / Params)|Returns|What it Does|
|---|---|---|---|
|`forEach()`|`Consumer<? super T>`|`void`|Performs an action for each element|
|`forEachOrdered()`|`Consumer<? super T>`|`void`|Like `forEach`, but preserves encounter order|
|`toArray()`|— or `IntFunction<A[]>`|`Object[]` or `A[]`|Collects elements into an array|
|`reduce()`|`BinaryOperator<T>`|`Optional<T>`|Reduces elements to a single value|
|`reduce()`|`T identity`, `BinaryOperator<T>`|`T`|Reduces with identity value|
|`reduce()`|`U identity`, `BiFunction<U,? super T,U>`, `BinaryOperator<U>`|`U`|Mutable reduction|
|`collect()`|`Collector<? super T,A,R>`|`R`|Transforms stream into collection or result|
|`collect()`|`Supplier<A>`, `BiConsumer<A,? super T>`, `BiConsumer<A,A>`|`A`|Custom mutable reduction|
|`min()`|`Comparator<? super T>`|`Optional<T>`|Finds minimum element|
|`max()`|`Comparator<? super T>`|`Optional<T>`|Finds maximum element|
|`count()`|—|`long`|Counts elements|
|`anyMatch()`|`Predicate<? super T>`|`boolean`|True if any element matches|
|`allMatch()`|`Predicate<? super T>`|`boolean`|True if all elements match|
|`noneMatch()`|`Predicate<? super T>`|`boolean`|True if no elements match|
|`findFirst()`|—|`Optional<T>`|Returns first element|
|`findAny()`|—|`Optional<T>`|Returns any element (parallel-friendly)|
|`iterator()`|—|`Iterator<T>`|Returns iterator (rarely used)|
|`spliterator()`|—|`Spliterator<T>`|Advanced traversal (low-level)|
|`summaryStatistics()` _(primitive streams)_|—|`IntSummaryStatistics`, etc.|Min, max, avg, sum, count|


### Key Truths (no sugarcoating)

- **Once a terminal operation runs → the stream is dead**
    
- **Lazy execution ends here**
    
- `collect()` and `reduce()` are the **most powerful**
    
- `forEach()` is **side-effect oriented** (use carefully)
    

---




###### Tags : [[Java]]