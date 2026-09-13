
## 1. Definition

`Predicate<T>` is a **functional interface** that:

- takes **one input**
    
- returns a **boolean**
    
- answers a **yes / no** question
    

```java
@FunctionalInterface
public interface Predicate<T> {
    boolean test(T t);
}
```

Think: **condition**, **rule**, **filtering logic**.

---

## 2. Why it exists

Java needed a **standard boolean function type** so APIs (Streams, Collections, etc.) could:

- accept conditions
    
- stay generic
    
- support lambdas
    

Without `Predicate`, every API would invent its own interface → chaos.

---

## 3. How it’s used

### Example with `filter()`

```java
Predicate<Integer> isEven = n -> n % 2 == 0;

numbers.stream()
       .filter(isEven)
       .forEach(System.out::println);
```

Execution per element:

```
test(n) → true  → keep
test(n) → false → drop
```

---

## 4. Built-in default methods (IMPORTANT)

### `and()`

```java
Predicate<Integer> positive = n -> n > 0;
Predicate<Integer> even = n -> n % 2 == 0;

Predicate<Integer> positiveAndEven = positive.and(even);
```

### `or()`

```java
positive.or(even)
```

### `negate()`

```java
even.negate()   // NOT even
```

### `isEqual()`

```java
Predicate<String> isHello = Predicate.isEqual("hello");
```

These **compose logic cleanly** — no nested `if` mess.

---

## 5. Predicate vs similar interfaces (don’t confuse them)

|Interface|Input|Output|Purpose|
|---|---|---|---|
|`Predicate<T>`|1|`boolean`|Condition|
|`Function<T,R>`|1|`R`|Transform|
|`Consumer<T>`|1|`void`|Side effect|
|`Supplier<T>`|0|`T`|Produce value|
|`BiPredicate<T,U>`|2|`boolean`|Two-input condition|

---

## 6. Real-world predicates

```java
user -> user.isActive()
order -> order.getTotal() > 100
file -> file.exists()
str -> str.startsWith("A")
```

Every `if` condition you write can be a `Predicate`.

---

## 7. Rules you must follow

- ✅ **Stateless**
    
- ✅ **No side effects**
    
- ❌ Don’t mutate data
    
- ❌ Don’t do I/O or logging
    

If you break this, streams become **bug factories**, especially in parallel.

---

## 8. Mental model (lock this in)

> **Predicate = gatekeeper**

Each element walks up to the gate.  
`true` → pass  
`false` → rejected

---

### Final truth

`Predicate` is the **boolean backbone** of:

- `filter`
    
- `removeIf`
    
- `anyMatch / allMatch / noneMatch`
    


---
## 1. What `filter()` **is**

`filter()` is an **intermediate, lazy operation** that **keeps or discards elements** based on a condition.

**Definition**

```java
Stream<T> filter(Predicate<? super T> predicate)
```

---

## 2. What it **takes**

### `Predicate<T>`

```java
@FunctionalInterface
public interface Predicate<T> {
    boolean test(T t);
}
```

**Meaning:**  
For each element `t`:

- `true` → element **passes**
    
- `false` → element **is dropped**
    

---

## 3. What it **returns**

- **A new `Stream<T>`**
    
- Same type, fewer (or equal) elements
    
- Original stream remains untouched (streams are immutable views)
    

---

## 4. How it **works internally**

- **Lazy**: nothing runs until a terminal operation
    
- **Short-circuiting friendly**: combined with `findFirst`, `anyMatch`, etc.
    
- **One element at a time** (not batch processing)
    

Pipeline reality:

```text
element → filter → next op → terminal
```

---

## 5. Basic example

```java
List<Integer> evens =
    numbers.stream()
           .filter(n -> n % 2 == 0)
           .toList();
```

✔ keeps even numbers  
✘ removes odd numbers

---

## 6. Multiple filters (best practice)

```java
stream
   .filter(user -> user.isActive())
   .filter(user -> user.getAge() >= 18)
   .filter(user -> user.hasEmail());
```

✅ **Readable**  
❌ Avoid cramming logic into one predicate

---

## 7. `filter()` vs `map()` (critical difference)

|Operation|Purpose|Output Size|
|---|---|---|
|`filter()`|Remove elements|Same or smaller|
|`map()`|Transform elements|Same size|

Wrong mental model = bugs.

---

## 8. Performance & behavior truths

- **Cheap predicates = fast streams**
    
- Heavy logic in `filter()` = slow pipeline
    
- In **parallel streams**, predicate **must be stateless**
    
- Order preserved in sequential streams
    

---

## 9. Common mistakes (be ruthless)

❌ Side effects inside `filter`

```java
.filter(x -> { log(x); return x > 5; }) // bad
```

❌ Using `filter` to “transform”

```java
.filter(x -> x + 1) // illegal & wrong
```

❌ Null checks instead of Optional discipline

```java
.filter(x -> x != null) // smells
```

---

## 10. Real-world use cases

- Authorization checks
    
- Validation pipelines
    
- Searching & querying
    
- Cleaning data streams
    
- Pre-processing before `map()` or `collect()`
    

---

### Bottom line

`filter()` is:

- **Boolean gate**
    
- **Lazy**
    
- **Pure logic only**
    
- **Foundational to stream pipelines**
    

---



###### Tags : [[1 - Stream api|1 - Stream api]]