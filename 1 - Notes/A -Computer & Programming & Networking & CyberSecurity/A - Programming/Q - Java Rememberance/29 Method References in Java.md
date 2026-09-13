


## The name: **Method Reference**

`Integer::sum` is called a **method reference** — a shorthand syntax for a lambda that does nothing but **call an existing method**. The `::` operator is the method reference operator.

```java
BinaryOperator<Integer> add = Integer::sum;
// is exactly equivalent to:
BinaryOperator<Integer> add = (a, b) -> Integer.sum(a, b);
```

---

## The problem it solves

Once you start writing lambdas, you quickly notice a pattern: **a lot of lambdas do nothing except forward their arguments to an already-existing method.**

```java
names.forEach(name -> System.out.println(name));   // just calls println
numbers.stream().map(num -> String.valueOf(num));  // just calls String.valueOf
names.stream().sorted((a, b) -> a.compareTo(b));    // just calls compareTo
```

Writing `param -> someMethod(param)` is redundant — you're inventing a parameter name (`name`, `num`, `a`/`b`) purely to immediately hand it to a method that already exists and already does the job. It adds visual noise without adding meaning.

**Method references remove that redundancy** — if your lambda's _entire body_ is "call this one method," you can just point directly at the method:

```java
names.forEach(System.out::println);
numbers.stream().map(String::valueOf);
names.stream().sorted(String::compareTo);
```

Same behavior, less code, and arguably clearer intent — you're saying "use _this_ method" rather than "here's a mini function that calls this method."

---

## The four kinds of method references

|Kind|Syntax|Equivalent Lambda|Example|
|---|---|---|---|
|**Static method reference**|`ClassName::staticMethod`|`(args) -> ClassName.staticMethod(args)`|`Integer::sum`|
|**Instance method reference (particular object)**|`object::instanceMethod`|`(args) -> object.instanceMethod(args)`|`System.out::println`|
|**Instance method reference (arbitrary object of a type)**|`ClassName::instanceMethod`|`(obj, args) -> obj.instanceMethod(args)`|`String::compareTo`|
|**Constructor reference**|`ClassName::new`|`(args) -> new ClassName(args)`|`ArrayList::new`|

---

## 1. Static method reference

Points to a `static` method — the method belongs to the class itself, not an instance.

```java
BinaryOperator<Integer> add = Integer::sum;
System.out.println(add.apply(3, 4)); // 7
```

**Problem it solves:** avoids writing `(a, b) -> Integer.sum(a, b)` when `Integer.sum` already exists and does exactly that.

---

## 2. Instance method reference — on a specific, already-existing object

Points to a method that will be called **on one particular object you already have a reference to**.

```java
String greeting = "Hello";
Supplier<Integer> lengthGetter = greeting::length;
System.out.println(lengthGetter.get()); // 5
```

```java
List<String> names = List.of("Alireza", "Sara");
names.forEach(System.out::println); // System.out is one specific PrintStream object
```

**Problem it solves:** you already have the object (`greeting`, `System.out`) — you just want to call a method _on that specific object_ for each incoming value, without writing `x -> greeting.someMethod(x)`.

---

## 3. Instance method reference — on an arbitrary object of a type (the tricky one)

This is different from #2: here, the object **isn't fixed in advance** — it's supplied later, as one of the lambda's parameters, at call time.

```java
Function<String, Integer> length = String::length;
System.out.println(length.apply("Alireza")); // 7
// equivalent to: str -> str.length()
```

```java
List<String> names = new ArrayList<>(List.of("banana", "Apple", "cherry"));
names.sort(String::compareToIgnoreCase);
// equivalent to: (a, b) -> a.compareToIgnoreCase(b)
```

**Problem it solves:** when your lambda's **first parameter is the object the method is called on**, this avoids naming that parameter at all — `String::length` directly says "call `.length()` on whatever string shows up."

**How to tell #2 apart from #3:** ask "do I already have the object, or does the lambda receive it as an argument?" `System.out::println` — you already have `System.out`. `String::length` — the string comes in as the lambda's parameter.

---

## 4. Constructor reference

Points to a constructor — used to create new objects.

```java
Supplier<ArrayList<String>> listMaker = ArrayList::new;
ArrayList<String> list = listMaker.get(); // new ArrayList<>()
```

```java
Function<String, User> userMaker = User::new; // assuming User(String name) constructor
User u = userMaker.apply("Alireza"); // new User("Alireza")
```

**Problem it solves:** avoids writing `() -> new ArrayList<>()` or `name -> new User(name)` when all the lambda does is call `new`.

---

## Full example — all four in context of a stream pipeline

```java
List<String> names = List.of("alireza", "sara", "ali");

List<String> result = names.stream()
    .map(String::toUpperCase)        // #3 — arbitrary object method ref
    .sorted(String::compareTo)       // #3 — arbitrary object method ref
    .toList();

result.forEach(System.out::println); // #2 — specific object method ref

Function<String, StringBuilder> toBuilder = StringBuilder::new; // #4 — constructor ref
StringBuilder sb = toBuilder.apply("Hello");

BinaryOperator<Integer> sum = Integer::sum; // #1 — static method ref
```

---

## Summary: what problem method references solve overall

|Without method reference|With method reference|Saved|
|---|---|---|
|`(a, b) -> Integer.sum(a, b)`|`Integer::sum`|naming 2 params just to forward them|
|`x -> System.out.println(x)`|`System.out::println`|naming a param to forward to a known object|
|`str -> str.length()`|`String::length`|naming a param that's just "the receiver"|
|`() -> new ArrayList<>()`|`ArrayList::new`|writing `new` inside a lambda wrapper|

The general rule: **if a lambda's body is _just_ calling one existing method (or constructor) with the exact parameters it received, in the exact same order — replace it with a method reference.** If the lambda does _anything_ extra (transforms a value first, combines two calls, adds logic), you need a real lambda instead.


[[Java]]