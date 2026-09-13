
**each intermediate Stream operation → what it TAKES, what it RETURNS, and the core functional interfaces involved**, with short explanations of those interfaces.

---

## Java Stream Intermediate Operations — Inputs & Outputs

|Operation|Takes (Input)|Returns (Output)|Functional Interface(s)|
|---|---|---|---|
|`filter`|`Predicate<T>`|`Stream<T>`|`Predicate<T>`|
|`map`|`Function<T,R>`|`Stream<R>`|`Function<T,R>`|
|`mapToInt`|`ToIntFunction<T>`|`IntStream`|`ToIntFunction<T>`|
|`mapToLong`|`ToLongFunction<T>`|`LongStream`|`ToLongFunction<T>`|
|`mapToDouble`|`ToDoubleFunction<T>`|`DoubleStream`|`ToDoubleFunction<T>`|
|`flatMap`|`Function<T, Stream<R>>`|`Stream<R>`|`Function<T, Stream<R>>`|
|`flatMapToInt`|`Function<T, IntStream>`|`IntStream`|`Function<T, IntStream>`|
|`distinct`|—|`Stream<T>`|—|
|`sorted`|—|`Stream<T>`|`Comparable<T>` (implicit)|
|`sorted(Comparator)`|`Comparator<T>`|`Stream<T>`|`Comparator<T>`|
|`peek`|`Consumer<T>`|`Stream<T>`|`Consumer<T>`|
|`limit`|`long`|`Stream<T>`|—|
|`skip`|`long`|`Stream<T>`|—|
|`takeWhile`|`Predicate<T>`|`Stream<T>`|`Predicate<T>`|
|`dropWhile`|`Predicate<T>`|`Stream<T>`|`Predicate<T>`|
|`boxed`|—|`Stream<BoxedType>`|—|
|`sequential`|—|`Stream<T>`|—|
|`parallel`|—|`Stream<T>`|—|
|`unordered`|—|`Stream<T>`|—|

---

## Functional Interfaces — What They REALLY Are

### 1️⃣ `Predicate<T>`

```java
boolean test(T t);
```

- Input: `T`
    
- Output: `boolean`
    
- Used for **filtering / conditions**
    

Example:

```java
filter(x -> x > 10)
```

---

### 2️⃣ `Function<T, R>`

```java
R apply(T t);
```

- Input: `T`
    
- Output: `R`
    
- Used for **transformation**
    

Example:

```java
map(String::length)
```

---

### 3️⃣ `Consumer<T>`

```java
void accept(T t);
```

- Input: `T`
    
- Output: nothing
    
- Used for **side effects only**
    

Example:

```java
peek(System.out::println)
```

---

### 4️⃣ `Comparator<T>`

```java
int compare(T a, T b);
```

- Compares two objects
    
- Used in sorting
    

Example:

```java
sorted(Comparator.reverseOrder())
```

---

### 5️⃣ Primitive Mappers

|Interface|Method|Purpose|
|---|---|---|
|`ToIntFunction<T>`|`int applyAsInt(T)`|Map to `int`|
|`ToLongFunction<T>`|`long applyAsLong(T)`|Map to `long`|
|`ToDoubleFunction<T>`|`double applyAsDouble(T)`|Map to `double`|

Used to avoid **boxing overhead**.

---

## Mental Model (IMPORTANT)

Every intermediate operation is basically:

```
Stream<T>  →  (Function-like logic)  →  Stream<R>
```

- **No data is processed immediately**
    
- Each operation **wraps behavior**
    
- Execution happens only at **terminal operation**
    

---



##### Tags : [[1 - Stream api|1 - Stream api]]