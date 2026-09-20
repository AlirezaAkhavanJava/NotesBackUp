


**`Supplier<T>`** and **`Consumer<T>`** live in `java.util.function`.  
They are _functional interfaces_, meaning one abstract method each, built for lambdas and streams.

---

### Supplier

A **Supplier** _produces_ a value.  
It **takes nothing** and **returns something**.

```java
@FunctionalInterface
public interface Supplier<T> {
    T get();
}
```

Think of it as a vending machine with no buttons: you ask, it hands you a thing.

Example:

```java
Supplier<String> supplier = () -> "Hello";

System.out.println(supplier.get()); // Hello
```

Common uses:

- Lazy object creation
    
- Default values
    
- Dependency injection (Spring loves this one)
    
- Random or time-based values
    

```java
Supplier<Integer> random = () -> new Random().nextInt();
```

---

### Consumer

A **Consumer** _consumes_ a value.  
It **takes something** and **returns nothing** (`void`).

```java
@FunctionalInterface
public interface Consumer<T> {
    void accept(T t);
}
```

Think of it as a shredder: you feed it paper, you get silence.

Example:

```java
Consumer<String> printer = s -> System.out.println(s);

printer.accept("Hello");
```

Common uses:

- Logging
    
- Printing
    
- Mutating objects
    
- `forEach()` in streams
    

```java
list.forEach(item -> System.out.println(item));
```

---

### Side-by-side truth table

|Interface|Input|Output|Method|
|---|---|---|---|
|Supplier|❌ none|✅ yes|`get()`|
|Consumer|✅ yes|❌ void|`accept()`|

---

### Mental model (important)

- **Supplier = source of data**
    
- **Consumer = sink of data**
    

Pipelines are built by chaining these ideas:  
data flows from _suppliers_, gets transformed, and ends in _consumers_.

This design makes Java’s functional style predictable, fast, and readable—no magic, just discipline.

##### Tags : [[1 - Stream]]