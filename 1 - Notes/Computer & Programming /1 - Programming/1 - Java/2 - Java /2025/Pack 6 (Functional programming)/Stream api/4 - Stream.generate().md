
## `Stream.generate()` — what it is, how it works, and when to use it

### Definition

```java
static <T> Stream<T> generate(Supplier<T> supplier)
```

---

## 1️⃣ What it TAKES

### `Supplier<T>`

```java
T get();
```

- **Input:** nothing
    
- **Output:** a value of type `T`
    
- Called **every time** the stream needs a new element
    

Example:

```java
Supplier<Double> random = Math::random;
```

---

## 2️⃣ What it RETURNS

- `Stream<T>`
    
- **Infinite** stream
    
- **Unordered** by default
    
- **Lazy**
    

---

## 3️⃣ Basic Example

```java
Stream<Integer> s =
    Stream.generate(() -> 1);

s.limit(5).forEach(System.out::println);
// 1 1 1 1 1
```

Without `limit()` → ❌ **infinite loop**

---

## 4️⃣ Real Examples

### Random values

```java
Stream<Double> randoms =
    Stream.generate(Math::random).limit(10);
```

### UUIDs

```java
Stream<String> ids =
    Stream.generate(() -> UUID.randomUUID().toString())
          .limit(5);
```

---

## 5️⃣ Stateful Supplier (IMPORTANT)

`Supplier` **can hold state**, but **you must be careful**.

```java
AtomicInteger counter = new AtomicInteger(0);

Stream<Integer> s =
    Stream.generate(counter::getAndIncrement)
          .limit(5);
```

⚠️ In **parallel streams**, stateful suppliers = **race conditions**

---

## 6️⃣ `Stream.generate()` vs `Stream.iterate()`

|Feature|`generate()`|`iterate()`|
|---|---|---|
|Input|`Supplier<T>`|`UnaryOperator<T>`|
|Depends on previous value|❌ No|✅ Yes|
|Typical use|Random, external source|Sequences|
|Order|Unordered|Ordered|

---

## 7️⃣ When to use `generate()`

✅ Random data  
✅ External generators  
✅ Infinite lazy sources

❌ Counters / sequences → use `iterate()`  
❌ Parallel logic with shared state

---

## Mental Model

```
Supplier.get()
Supplier.get()
Supplier.get()
   ↓
Stream<T>
```

Each element is **pulled on demand**.

---

## Hard truth

- `generate()` is powerful but **easy to misuse**
    
- Forgetting `limit()` is a classic bug
    
- Parallel + stateful supplier = **broken code**
    



###### Tags : [[1 - Stream api|1 - Stream api]]