

Below is a **complete, structured list of ways to create Java Streams**, with **what you start from**, **what you get**, and **why/when to use it**.  
Concise but technical.

---

## 1️⃣ From Collections (MOST COMMON)

```java
Collection<T> c = List.of(1, 2, 3);
Stream<T> s = c.stream();
Stream<T> ps = c.parallelStream();
```

**Returns:** `Stream<T>`  
**Why:** Safe, ordered, reusable source  
**Rule:** A stream is **single-use**

---

## 2️⃣ From Arrays

### Object arrays

```java
String[] arr = {"a", "b"};
Stream<String> s = Arrays.stream(arr);
```

### Primitive arrays

```java
int[] nums = {1,2,3};
IntStream s = Arrays.stream(nums);
```

**Why:** Zero boxing for primitives

---

## 3️⃣ Using `Stream.of(...)`

```java
Stream<Integer> s = Stream.of(1,2,3);
Stream<String> s2 = Stream.of("a","b");
```

⚠️ `Stream.of(null)` → **NPE**

---

## 4️⃣ Empty Stream

```java
Stream<String> s = Stream.empty();
```

**Why:** Avoid returning `null`

---

## 5️⃣ From Primitive Ranges

```java
IntStream a = IntStream.range(1, 5);      // 1..4
IntStream b = IntStream.rangeClosed(1, 5); // 1..5
LongStream c = LongStream.range(0, 10);
```

**Why:** Fast, no boxing

---

## 6️⃣ Infinite Streams (Generated)

### `Stream.generate`

```java
Stream<Double> s = Stream.generate(Math::random);
```

### `Stream.iterate`

```java
Stream<Integer> s =
    Stream.iterate(0, n -> n + 2);
```

### Java 9+ (with condition)

```java
Stream.iterate(0, n -> n < 10, n -> n + 1);
```

⚠️ **Must** use `limit()` or termination condition

---

## 7️⃣ From I/O Sources

### Files

```java
Stream<String> lines = Files.lines(Path.of("file.txt"));
```

### Directory listing

```java
Stream<Path> paths = Files.list(Path.of("."));
```

⚠️ **Must close** (try-with-resources)

---

## 8️⃣ From Strings

### Characters

```java
IntStream chars = "hello".chars();
```

### Unicode code points

```java
IntStream codes = "hello".codePoints();
```

---

## 9️⃣ From Optional

```java
Optional<String> opt = Optional.of("x");
Stream<String> s = opt.stream(); // Java 9+
```

**Why:** Clean optional → stream integration

---

## 🔟 From Map

```java
map.keySet().stream();
map.values().stream();
map.entrySet().stream();
```

**Most used:** `entrySet()`

---

## 1️⃣1️⃣ From Builder

```java
Stream<String> s = Stream.<String>builder()
    .add("a")
    .add("b")
    .build();
```

**Why:** Conditional construction

---

## 1️⃣2️⃣ From Random

```java
IntStream ints = new Random().ints(5);
DoubleStream doubles = new Random().doubles();
```

---

## 1️⃣3️⃣ From Spliterator (ADVANCED)

```java
Stream<T> s =
    StreamSupport.stream(spliterator, false);
```

**Why:** Custom data sources

---

## Summary Table

|Source|Method|Stream Type|
|---|---|---|
|Collection|`stream()`|`Stream<T>`|
|Array|`Arrays.stream()`|`Stream / IntStream`|
|Static|`Stream.of()`|`Stream<T>`|
|Empty|`Stream.empty()`|`Stream<T>`|
|Range|`IntStream.range()`|`IntStream`|
|Infinite|`generate / iterate`|`Stream<T>`|
|File|`Files.lines()`|`Stream<String>`|
|String|`chars()`|`IntStream`|
|Optional|`optional.stream()`|`Stream<T>`|
|Map|`entrySet().stream()`|`Stream<Entry<K,V>>`|

---

### Hard truth (important):

- Streams are **NOT data structures**
    
- Streams are **pipelines**
    
- Streams are **single-use**
    

---
### What is the difference between Stream.of() and ObjectType.stream() ? 


Short answer: **they look similar, but they are NOT the same thing**.  
Here’s the **clean, technical breakdown**.

---

## 1️⃣ `Stream.of(...)`

### What it is

A **static factory method**.

```java
Stream<Integer> s = Stream.of(1, 2, 3);
```

### What it takes

- **Varargs**: `T...`
    
- Or a **single object**
    

```java
Stream.of(obj1, obj2, obj3)
```

### What it creates

- A stream **from the values you pass**
    
- **Not tied** to any collection
    

### Key behaviors

- `Stream.of(null)` → ❌ **NullPointerException**
    
- `Stream.of((String) null)` → ✅ one element = `null`
    
- Fixed elements at creation time
    

---

## 2️⃣ `objectType.stream()` (e.g. `Collection.stream()`)

### What it is

An **instance method** on **Collection**

```java
List<Integer> list = List.of(1, 2, 3);
Stream<Integer> s = list.stream();
```

### What it takes

- **No arguments**
    

### What it creates

- A stream **backed by the collection**
    
- Reflects the collection’s **encounter order**
    

### Key behaviors

- Safe with empty collections
    
- Changes to collection **after stream creation** → ❌ undefined behavior
    
- Supports `parallelStream()`
    

---

## Side-by-Side Comparison

|Feature|`Stream.of()`|`collection.stream()`|
|---|---|---|
|Method type|Static factory|Instance method|
|Source|Explicit values|Existing collection|
|Accepts null|❌ (varargs)|✅ (if collection has nulls)|
|Order|Order of arguments|Collection order|
|Parallel support|`.parallel()` only|`.parallelStream()`|
|Backed by data source|No|Yes|
|Typical use|Small, ad-hoc streams|Real data pipelines|

---

## ❗ Common Mistake (IMPORTANT)

```java
List<Integer> list = List.of(1,2,3);
Stream<List<Integer>> s = Stream.of(list); // WRONG
```

You get **ONE element: the list itself**.

Correct:

```java
Stream<Integer> s = list.stream();
```

---

## When to use which

### Use `Stream.of()` when:

- You have **a few known values**
    
- You’re writing **tests**
    
- You’re composing streams inline
    

### Use `collection.stream()` when:

- Data already lives in a **Collection**
    
- You care about **ordering**
    
- You want **parallelStream()**
    

---

## Bottom line (truth):

> `Stream.of()` creates a stream **from values**  
> `collection.stream()` creates a stream **from data**



###### Tags : [[1 - Stream api|1 - Stream api]]