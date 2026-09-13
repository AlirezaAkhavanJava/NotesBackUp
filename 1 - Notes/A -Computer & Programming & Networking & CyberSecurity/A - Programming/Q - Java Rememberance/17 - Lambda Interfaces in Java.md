


## What is a Functional Interface?

A **functional interface** is an interface with **exactly one abstract method** (SAM - Single Abstract Method). These are the target types for lambda expressions and method references.

Java does **not** have a `Lambda` interface built-in. Instead, lambdas are assigned to functional interfaces like `Runnable`, `Callable`, `Comparator`, or the `java.util.function.*` types.

---

## 1. Defining a Custom Functional Interface

```java
@FunctionalInterface
public interface Calculator {
    int operate(int a, int b);
}
```

Usage:
```java
Calculator add = (a, b) -> a + b;
Calculator mul = (a, b) -> a * b;

System.out.println(add.operate(3, 4)); // 7
System.out.println(mul.operate(3, 4)); // 12
```

The `@FunctionalInterface` annotation is **optional** but recommended — it causes a compile-time error if the interface has 0 or 2+ abstract methods.

---

## 2. Rules for Functional Interfaces

| Rule | Detail |
|------|--------|
| Abstract methods | Exactly **one** |
| `default` methods | Any number allowed |
| `static` methods | Any number allowed |
| `Object` methods (`equals`, `hashCode`, `toString`) | Do **not** count toward the SAM |
| `private` methods (Java 9+) | Allowed, don't count |
| Variables | Implicitly `public static final` |

### Example with defaults, statics, and Object methods

```java
@FunctionalInterface
public interface Transformer<T> {
    T transform(T input);                 // SAM

    default Transformer<T> andThen(Transformer<T> after) {
        return t -> after.transform(this.transform(t));
    }

    static <T> Transformer<T> identity() {
        return t -> t;
    }

    boolean equals(Object obj);           // ignored (Object method)
}
```

---

## 3. Built-in Functional Interfaces (`java.util.function`)

Introduced in Java 8 and still the standard through JDK 25.

| Interface | Signature | Purpose |
|-----------|-----------|---------|
| `Function<T,R>` | `R apply(T t)` | Transform T → R |
| `BiFunction<T,U,R>` | `R apply(T t, U u)` | Two args → R |
| `Consumer<T>` | `void accept(T t)` | Side effect |
| `BiConsumer<T,U>` | `void accept(T t, U u)` | Two-arg side effect |
| `Supplier<T>` | `T get()` | No arg → value |
| `Predicate<T>` | `boolean test(T t)` | Boolean test |
| `BiPredicate<T,U>` | `boolean test(T t, U u)` | Two-arg test |
| `UnaryOperator<T>` | `T apply(T t)` | T → T |
| `BinaryOperator<T>` | `T apply(T t1, T t2)` | (T,T) → T |
| `Runnable` | `void run()` | No args, no return |
| `Callable<V>` | `V call() throws Exception` | No args, returns V |

### Primitive specializations (avoid boxing)
`IntFunction`, `LongFunction`, `DoubleFunction`, `ToIntFunction`, `IntPredicate`, `IntConsumer`, `IntSupplier`, `IntUnaryOperator`, `IntBinaryOperator`, and the same for `Long` / `Double`.

---

## 4. Writing Your Own Generic Lambda Interface

```java
@FunctionalInterface
public interface ThrowingFunction<T, R, E extends Exception> {
    R apply(T t) throws E;

    static <T, R> Function<T, R> unchecked(ThrowingFunction<T, R, ?> f) {
        return t -> {
            try { return f.apply(t); }
            catch (Exception e) { throw new RuntimeException(e); }
        };
    }
}
```

---

## 5. Functional Interface as Lambda Target

A lambda expression is only legal where a functional interface is expected:

```java
// OK
Runnable r = () -> System.out.println("hi");

// Compile error: Object is not a functional interface
// Object o = () -> System.out.println("hi");
```

You can also **cast** to a functional interface type:
```java
var fn = (Function<Integer, Integer>) x -> x * 2;
```

---

## 6. JDK Evolution Relevant to Lambdas / Functional Interfaces

| JDK | Change |
|-----|--------|
| **8** | Lambdas, `@FunctionalInterface`, `java.util.function`, method references, default/static methods |
| **9** | Private interface methods; `@FunctionalInterface` still one SAM |
| **10** | `var` — works with lambda parameters implicitly |
| **11** | `var` allowed **inside** lambda parameter list: `(var x) -> ...` |
| **16** | `instanceof` pattern matching (useful inside lambdas) |
| **17** | Sealed classes — can seal functional interfaces |
| **21** | Virtual threads (`Runnable` reused heavily); record patterns |
| **25 (LTS)** | No changes to the lambda/functional-interface model itself — it remains stable as defined in JLS §9.8 |

---

## 7. Complete Working Example (JDK 25 compatible)

```java
import java.util.function.*;

public class LambdaDemo {

    @FunctionalInterface
    interface StringOp {
        String apply(String s);

        default StringOp andThen(StringOp next) {
            return s -> next.apply(this.apply(s));
        }
    }

    public static void main(String[] args) {
        StringOp trim   = String::trim;
        StringOp upper  = String::toUpperCase;
        StringOp shout  = trim.andThen(upper).andThen(s -> s + "!");

        System.out.println(shout.apply("  hello  "));  // HELLO!

        // Using built-in functional interfaces
        Function<Integer, Integer> square = x -> x * x;
        Predicate<Integer> isEven         = x -> x % 2 == 0;
        BiFunction<Integer, Integer, Integer> sum = Integer::sum;

        System.out.println(sum.apply(square.apply(4), 10)); // 26
        System.out.println(isEven.test(7));                 // false
    }
}
```

---

### Summary

- A **lambda interface** = a **functional interface** = exactly one abstract method.
- Mark with `@FunctionalInterface` for safety.
- `default`, `static`, `private` methods and `Object`-method overrides are allowed.
- Java 8 introduced lambdas + `java.util.function`; through **JDK 25 LTS**, the model is unchanged and remains the foundation for streams, `Optional`, virtual threads, and modern APIs.

[[Java]]