

A **lambda expression** is a short, unnamed block of code that you can pass around as a value. It is a compact way to write an implementation of a **functional interface**, the kind we covered last time: an interface with exactly one abstract method.

The general shape is:

```
(parameters) -> body
```

The arrow `->` separates the parameter list from the code that runs when the method is called.

## Why lambdas exist

Before Java 8, passing a piece of behavior required an anonymous class. Sorting a list by length looked like this:

```java
List<String> names = new ArrayList<>(List.of("Charlie", "Al", "Barbara"));

names.sort(new Comparator<String>() {
    @Override
    public int compare(String a, String b) {
        return Integer.compare(a.length(), b.length());
    }
});
```

Most of those lines are ceremony. The only important part is the comparison logic, `Integer.compare(a.length(), b.length())`. The rest is the type name, the method name, the modifiers, and the braces, all repeated for the sake of the compiler.

A lambda keeps the logic and drops the ceremony:

```java
names.sort((a, b) -> Integer.compare(a.length(), b.length()));
```

The compiler already knows that `sort` expects a `Comparator<String>`, and that `Comparator` has one abstract method, `compare`, that takes two strings and returns an `int`. So it can infer the parameter types and the method name from context. You only write what is unique to this piece of behavior.

## How a lambda works

A lambda has three parts, and it is worth understanding each one, because the compiler's rules come from them.

**Target type.** A lambda has no type of its own. It is given a type by the place where it appears, and that type must be a functional interface. The same lambda text can mean different things depending on the target. `() -> "hi"` is a `Supplier<String>` if assigned to a `Supplier`, and a `Runnable`-shaped thing would need `void`, so the target decides what is legal.

**Parameters.** The parameter types are usually inferred from the target. You may write them explicitly, as in `(String a, String b) -> ...`, but you must either write them all or none. Parentheses can be dropped when there is exactly one parameter with an inferred type, so `s -> s.toUpperCase()` is valid.

**Body.** If the body is a single expression, its value is returned automatically and you omit the braces and `return`. If the body needs several statements, use braces and an explicit `return` where a value is needed.

```java
Function<String, Integer> length = s -> s.length();          // expression body
Function<String, String> clean = s -> {                       // block body
    String trimmed = s.trim();
    return trimmed.toUpperCase();
};
```

## What a lambda can capture

A lambda can use variables from the surrounding method, but only if those variables are **effectively final**: never reassigned after they are set. The lambda receives a copy of the value, which is the same rule as pass by value from our earlier lesson.

```java
int base = 10;
Function<Integer, Integer> addBase = x -> x + base;   // allowed: base is never changed
// base = 20;                                         // would make the lambda above illegal
```

The restriction exists because the lambda may run later, possibly on another thread, after the method has finished. If the variable could change, the lambda and the method would disagree about its value. Java prevents that by forbidding the change.

To get around it, use an object whose contents can change, such as a `StringBuilder` or a single-element array, though you should be cautious with that. Usually the better answer is to restructure the code.

## Method references

When a lambda only forwards to an existing method, you can write a **method reference** instead. It is the same behavior, shorter:

```java
names.forEach(n -> System.out.println(n));   // lambda
names.forEach(System.out::println);          // method reference
```

There are four forms:

|Form|Example|Meaning|
|---|---|---|
|Static method|`Integer::parseInt`|`x -> Integer.parseInt(x)`|
|Bound instance method|`System.out::println`|`x -> System.out.println(x)`|
|Unbound instance method|`String::length`|`s -> s.length()`|
|Constructor|`ArrayList::new`|`() -> new ArrayList<>()`|

Use a method reference when it reads more clearly than the lambda. When the lambda does anything beyond a single call, a lambda is usually clearer.

## Running it

Create a folder and save this as `LambdaDemo.java`:

```java
import java.util.*;
import java.util.function.*;

public class LambdaDemo {
    public static void main(String[] args) {
        // 1. Lambda as a Comparator: sort by length
        List<String> names = new ArrayList<>(List.of("Charlie", "Al", "Barbara"));
        names.sort((a, b) -> Integer.compare(a.length(), b.length()));
        System.out.println(names);                 // [Al, Charlie, Barbara]

        // 2. Lambda as a Predicate: filter
        names.removeIf(n -> n.length() < 4);
        System.out.println(names);                 // [Charlie, Barbara]

        // 3. Lambda capturing an effectively final variable
        int minLength = 6;
        names.stream()
             .filter(n -> n.length() >= minLength) // captures minLength
             .map(String::toUpperCase)              // method reference
             .forEach(System.out::println);         // CHARLIE, BARBARA

        // 4. Lambda as a Supplier, with a block body
        Supplier<String> greeting = () -> {
            String base = "Hello";
            return base + ", Alireza";
        };
        System.out.println(greeting.get());        // Hello, Alireza

        // 5. Lambda as your own functional interface
        Transformer shout = s -> s.toUpperCase() + "!";
        System.out.println(shout.apply("lambda")); // LAMBDA!
    }

    @FunctionalInterface
    interface Transformer {
        String apply(String input);
    }
}
```

Compile and run it:

```bash
javac LambdaDemo.java
java LambdaDemo
```

What each example teaches:

- Example 1 is the classic comparator. The lambda's target type is `Comparator<String>`, and the compiler infers `a` and `b` as `String`.
- Example 2 uses `removeIf`, which takes a `Predicate<String>`. The lambda returns `true` for elements to remove.
- Example 3 shows capture. `minLength` is effectively final, so the lambda may read it. The pipeline also mixes a lambda with the method reference `String::toUpperCase`.
- Example 4 shows the block body, with several statements and an explicit `return`.
- Example 5 shows that lambdas work with any functional interface, including ones you write yourself.

## Where you'll see lambdas in Spring Boot

Lambdas are everywhere in modern Spring code. Bean definitions can take a `Supplier` or a `Consumer`. Spring Security configuration is written with lambdas, as in `http.authorizeHttpRequests(auth -> auth.anyRequest().authenticated())`. Repositories accept lambdas for custom queries. Any time you see `->` in a Spring example, it is one of these same functional interfaces at work.

## What happens underneath

A lambda is not an anonymous class in the compiled output. Since Java 8, the compiler emits an `invokedynamic` instruction, which asks the JVM to link the call site to a generated implementation the first time it runs. That is the mechanism we set aside in the dispatch lesson, and it is why lambdas add almost no class-loading overhead. You can see it for yourself with `javap -c -p LambdaDemo.class`, where you will find `invokedynamic` and a `lambda$main$0` method holding your lambda's body.




[[Java]]