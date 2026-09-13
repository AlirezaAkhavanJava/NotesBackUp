
`Stream.generate()` is a **static factory method** in Java’s Stream API that creates an **infinite stream** of values supplied by a `Supplier<T>`.

Think of it as a **tap that keeps pouring values** on demand.

![[generate(-).png]]

---

### Syntax

```java
static <T> Stream<T> generate(Supplier<T> s)
```

- `<T>` → the type of elements in the stream
    
- `s` → a `Supplier` that produces a value every time the stream needs one
    
- The resulting stream has **no fixed size**—you have to limit it if you want to avoid infinite loops.
    

---

### Example

```java
import java.util.stream.Stream;

public class Main {
    public static void main(String[] args) {
        Stream<String> greetings = Stream.generate(() -> "Hello");

        greetings
            .limit(5) // must limit an infinite stream!
            .forEach(System.out::println);
    }
}
```

**Output:**

```
Hello
Hello
Hello
Hello
Hello
```

---

### Another Example: Random numbers

```java
Stream<Double> randomNumbers = Stream.generate(Math::random);

randomNumbers
    .limit(10)
    .forEach(System.out::println);
```

Here, every call to the supplier `Math::random` produces a new random number.

---

### Key Points

- `Stream.generate()` → **lazy evaluation**. Values are produced only when needed.
    
- Always **limit** or terminate the stream; otherwise, it runs forever.
    
- Works perfectly with `Supplier<T>` lambdas or method references.
    





##### Tags : [[1 - Stream]]