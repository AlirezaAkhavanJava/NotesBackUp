

## Definition

**`Predicate<T>`** is a functional interface in `java.util.function` representing a test that takes **one argument** and returns a **`boolean`** — a yes/no question about a value.

```java
public interface Predicate<T> {
    boolean test(T t);
}
```

```java
Predicate<Integer> isEven = num -> num % 2 == 0;
System.out.println(isEven.test(4)); // true
System.out.println(isEven.test(7)); // false
```

You already met `Predicate` briefly in the lambda types tutorial — this is the full, standalone treatment.

---

## The problem it solves

Before functional interfaces, expressing "a condition to check later" meant either writing an `if` statement inline (fine for one-off use) or manufacturing a full class/anonymous class just to carry a boolean-returning method — verbose for something conceptually this simple.

```java
// Without Predicate — verbose, single-use
if (age >= 18) {
    // ...
}
```

```java
// With Predicate — the condition becomes a reusable, passable VALUE
Predicate<Integer> isAdult = age -> age >= 18;

boolean result1 = isAdult.test(20); // true
boolean result2 = isAdult.test(15); // false
```

**The real payoff:** once a condition is a `Predicate` object, it can be **passed as an argument**, **stored in a variable**, **combined with other predicates**, and **reused** across your code — none of which is possible with a plain `if` statement.

---

## Core method

```java
boolean test(T t)
```

The single abstract method — takes one value of type `T`, returns `true` or `false`.

```java
Predicate<String> isEmpty = str -> str.isEmpty();
System.out.println(isEmpty.test(""));       // true
System.out.println(isEmpty.test("hello"));  // false
```

---

## Where `Predicate` is actually used — `filter()`

The most common real-world use, connecting directly to the Stream API tutorial:

```java
List<Integer> numbers = List.of(1, 2, 3, 4, 5, 6, 7, 8);

List<Integer> evens = numbers.stream()
    .filter(num -> num % 2 == 0) // this lambda IS a Predicate<Integer>
    .toList();

System.out.println(evens); // [2, 4, 6, 8]
```

`Stream.filter()` literally takes a `Predicate<T>` as its parameter:

```java
Stream<T> filter(Predicate<? super T> predicate)
```

Also used in `List.removeIf()` (from the `List` methods tutorial):

```java
List<Integer> nums = new ArrayList<>(List.of(1, 2, 3, 4, 5, 6));
nums.removeIf(n -> n % 2 == 0); // Predicate<Integer>
System.out.println(nums); // [1, 3, 5]
```

And `Collection.stream().anyMatch()`/`allMatch()`/`noneMatch()`:

```java
boolean hasEven = numbers.stream().anyMatch(n -> n % 2 == 0);   // true if ANY match
boolean allEven = numbers.stream().allMatch(n -> n % 2 == 0);     // true if ALL match
boolean noneEven = numbers.stream().noneMatch(n -> n % 2 == 0);    // true if NONE match
```

---

## Creating a `Predicate` — the ways

### Lambda (most common)

```java
Predicate<String> isLong = str -> str.length() > 10;
```

### Method reference

```java
Predicate<String> isEmpty = String::isEmpty; // matches boolean isEmpty() on String
Predicate<String> isBlank = String::isBlank;
```

### Anonymous class (old way, still valid)

```java
Predicate<Integer> isPositive = new Predicate<Integer>() {
    @Override
    public boolean test(Integer num) {
        return num > 0;
    }
};
```

---

## Combining predicates — default methods

`Predicate` provides built-in **default methods** for combining multiple conditions into one, without writing nested `&&`/`||` logic by hand:

### `and(Predicate other)`

```java
Predicate<Integer> isPositive = n -> n > 0;
Predicate<Integer> isEven = n -> n % 2 == 0;

Predicate<Integer> isPositiveAndEven = isPositive.and(isEven);

System.out.println(isPositiveAndEven.test(4));  // true
System.out.println(isPositiveAndEven.test(-4)); // false — fails isPositive
System.out.println(isPositiveAndEven.test(3));   // false — fails isEven
```

### `or(Predicate other)`

```java
Predicate<Integer> isNegative = n -> n < 0;
Predicate<Integer> isZero = n -> n == 0;

Predicate<Integer> isNonPositive = isNegative.or(isZero);

System.out.println(isNonPositive.test(-5)); // true
System.out.println(isNonPositive.test(0));    // true
System.out.println(isNonPositive.test(5));     // false
```

### `negate()`

```java
Predicate<Integer> isEven = n -> n % 2 == 0;
Predicate<Integer> isOdd = isEven.negate();

System.out.println(isOdd.test(3)); // true
System.out.println(isOdd.test(4));  // false
```

### Chaining all three together

```java
Predicate<Integer> isPositive = n -> n > 0;
Predicate<Integer> isEven = n -> n % 2 == 0;
Predicate<Integer> isSmall = n -> n < 100;

Predicate<Integer> combined = isPositive.and(isEven).and(isSmall.negate());

System.out.println(combined.test(50));  // false — fails isSmall.negate() (50 IS small)
System.out.println(combined.test(150)); // true — positive, even, and NOT small
```

**This is a genuinely powerful, real-world pattern** — building complex filtering logic by composing small, named, reusable predicates instead of one large tangled boolean expression.

```java
// Real-world example — filtering a list of users
Predicate<User> isActive = user -> user.isActive();
Predicate<User> isAdult = user -> user.getAge() >= 18;
Predicate<User> hasVerifiedEmail = user -> user.isEmailVerified();

List<User> eligibleUsers = users.stream()
    .filter(isActive.and(isAdult).and(hasVerifiedEmail))
    .toList();
```

### Static helper: `Predicate.not()` (Java 11+)

```java
import static java.util.function.Predicate.not;

List<String> strings = List.of("", "hello", "", "world");

List<String> nonBlank = strings.stream()
    .filter(not(String::isBlank)) // reads more naturally than str -> !str.isBlank()
    .toList();
```

**Why this exists:** `str -> !str.isBlank()` isn't terrible, but when combined with a method reference specifically, negating inline (`!String::isBlank` — not even valid syntax) doesn't work at all; `Predicate.not(String::isBlank)` gives a clean, readable way to negate a method reference directly.

---

## `BiPredicate<T, U>` — the two-argument version

Briefly touched on in the earlier lambda tutorial — worth a concrete example here:

```java
BiPredicate<String, Integer> hasLength = (str, len) -> str.length() == len;
System.out.println(hasLength.test("hello", 5)); // true
System.out.println(hasLength.test("hi", 5));      // false
```

**Use when:** the condition genuinely depends on **two** related inputs, not one.

---

## `IntPredicate`, `LongPredicate`, `DoublePredicate` — primitive specializations

```java
IntPredicate isEven = n -> n % 2 == 0;
System.out.println(isEven.test(4)); // true
```

**Problem these solve:** a plain `Predicate<Integer>` requires **boxing** every `int` into an `Integer` object before testing — for high-volume numeric processing (large streams of primitives), this boxing/unboxing overhead adds up. `IntPredicate`/`LongPredicate`/`DoublePredicate` work directly with primitives, avoiding that cost entirely. This connects to the primitive-specialized streams (`IntStream`, etc.) mentioned in the Java API reference tutorial.

```java
IntStream.range(1, 10)
    .filter(n -> n % 2 == 0) // this is actually an IntPredicate here, not Predicate<Integer>
    .forEach(System.out::println);
```

---

## Summary table

|Aspect|Detail|
|---|---|
|Package|`java.util.function`|
|Abstract method|`boolean test(T t)`|
|Shape|1 input, boolean output|
|Common use|`Stream.filter()`, `List.removeIf()`, `anyMatch`/`allMatch`/`noneMatch`|
|Combine with|`.and()`, `.or()`, `.negate()`|
|Static helper|`Predicate.not(predicate)` — Java 11+|
|Two-argument version|`BiPredicate<T, U>`|
|Primitive versions|`IntPredicate`, `LongPredicate`, `DoublePredicate`|

## Where this fits with everything you've learned

`Predicate` is the exact functional interface behind `Stream.filter()` and `List.removeIf()`, both used constantly throughout the Collections/`List`/`Set` tutorials — you've been using `Predicate` all along without necessarily naming it. The `.and()`/`.or()`/`.negate()` composition methods are a genuinely practical technique worth internalizing: they let you build filtering logic the same way you'd build a `Set` intersection/union in the last tutorial — as small, composable pieces combined into exactly the condition you need, rather than one long, hard-to-read boolean expression.


[[Java]]