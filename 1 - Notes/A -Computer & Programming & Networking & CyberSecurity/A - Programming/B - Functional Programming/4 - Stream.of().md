
`Stream.of()` is another **static factory method** in Java’s Stream API that creates a **finite stream** from a given set of elements or an array.

Unlike `Stream.generate()`, it’s **not infinite**—it’s like “take these things and make a stream out of them.”

---

### Syntax

```java
static <T> Stream<T> of(T... values)
```

- `<T>` → type of elements in the stream
    
- `values` → a **varargs array** of elements (can be one, many, or even zero)
    

---

### Example: simple values

```java
Stream<String> stream = Stream.of("A", "B", "C");

stream.forEach(System.out::println);
```

**Output:**

```
A
B
C
```

---

### Example: array

```java
String[] arr = {"X", "Y", "Z"};
Stream<String> streamFromArray = Stream.of(arr);

streamFromArray.forEach(System.out::println);
```

**Output:**

```
X
Y
Z
```

---

### Key Points

- Creates a **finite, fixed-size stream**.
    
- Can take **individual elements or an array**.
    
- Useful for quickly turning a small set of items into a stream for processing, e.g., filtering, mapping, or iterating.
    

---



##### Tags : [[1 - Stream]]