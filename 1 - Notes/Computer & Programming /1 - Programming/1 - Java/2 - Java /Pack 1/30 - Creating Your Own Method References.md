

## Important clarification first

You don't "create" the `::` syntax itself — that's built into Java. What you _can_ create is:

1. **Your own methods** that are shaped so they _can be_ referenced with `::`
2. **Your own functional interfaces** to hold those references (when the built-in ones like `Function`/`Consumer` don't fit)

So this tutorial is really: **"how to design your own methods and functional interfaces so `::` works cleanly with them."**

---

## Step 1: Understand the requirement — a functional interface

`::` only works where a **functional interface** is expected — an interface with exactly **one abstract method** (called a SAM: Single Abstract Method).

```java
@FunctionalInterface
interface Greeter {
    String greet(String name); // the one abstract method
}
```

The `@FunctionalInterface` annotation is optional but recommended — it makes the compiler enforce "exactly one abstract method" and error out if you (or a future teammate) accidentally add a second one.

---

## Step 2: Write a method whose signature matches

For a method reference to work, your method's parameter types and return type must **match the functional interface's single method** (matching by parameter types/return type, not by name — method names never need to match).

```java
class MyUtils {
    static String uppercaseGreet(String name) {
        return "HELLO, " + name.toUpperCase();
    }
}
```

`Greeter.greet(String) -> String` matches `MyUtils.uppercaseGreet(String) -> String`. Now you can reference it:

```java
Greeter g = MyUtils::uppercaseGreet;
System.out.println(g.greet("Alireza")); // HELLO, ALIREZA
```

---

## Step 3: The four patterns, applied to your own code

### Static method reference (your own static method)

```java
class MathUtils {
    static int square(int x) { return x * x; }
}

Function<Integer, Integer> sq = MathUtils::square;
System.out.println(sq.apply(5)); // 25
```

### Instance method reference — specific object

```java
class Logger {
    void log(String msg) { System.out.println("[LOG] " + msg); }
}

Logger logger = new Logger();
Consumer<String> logIt = logger::log;
logIt.accept("Something happened"); // [LOG] Something happened
```

### Instance method reference — arbitrary object of your type

```java
class User {
    private String name;
    User(String name) { this.name = name; }
    String getName() { return name; }
}

Function<User, String> nameGetter = User::getName;
System.out.println(nameGetter.apply(new User("Alireza"))); // Alireza
```

### Constructor reference — your own class

```java
class User {
    private String name;
    User(String name) { this.name = name; }
}

Function<String, User> userFactory = User::new;
User u = userFactory.apply("Alireza"); // new User("Alireza")
```

---

## Step 4: A complete, realistic example

```java
@FunctionalInterface
interface Validator<T> {
    boolean isValid(T value);
}

class UserValidator {
    static boolean hasValidName(User user) {
        return user.getName() != null && !user.getName().isBlank();
    }
}

// Usage
Validator<User> validator = UserValidator::hasValidName;
System.out.println(validator.isValid(new User("Alireza"))); // true
System.out.println(validator.isValid(new User("")));         // false
```

This is the real payoff: `Validator` didn't exist in the JDK, so you built it — a one-method interface — and now `UserValidator::hasValidName` slots into it exactly like `String::length` slots into `Function`.

---

## Common mistakes and compile errors

### 1. Signature mismatch (the #1 error you'll hit)

```java
interface Greeter {
    String greet(String name);
}

static void printGreeting(String name) { // returns void, not String!
    System.out.println("Hi " + name);
}

Greeter g = MyUtils::printGreeting; // COMPILE ERROR
```

**Error:** `incompatible types: invalid method reference` — the return types don't match (`void` vs `String`). The compiler checks this _before_ you ever call the method — method references are fully type-checked at compile time, not resolved lazily at runtime.

**Fix:** match the return type exactly (or make the interface method also `void`).

### 2. Ambiguous overloads

```java
class Printer {
    static void print(String s) { System.out.println(s); }
    static void print(int i) { System.out.println(i); }
}

Consumer<Object> p = Printer::print; // COMPILE ERROR — ambiguous
```

**Error:** `reference to print is ambiguous` — the compiler can't tell which overload you mean because `Consumer<Object>` doesn't narrow it down.

**Fix:** be specific about the type (`Consumer<String>` instead of `Consumer<Object>`), or don't overload the method.

### 3. Confusing "arbitrary object" vs "specific object" reference (silent logic bug, not a compile error)

```java
class Account {
    private double balance;
    Account(double balance) { this.balance = balance; }
    void withdraw(double amount) { balance -= amount; }
}

Account acc = new Account(100);

// This calls withdraw() on `acc` for EVERY item passed in — probably not what you meant
Consumer<Double> withdrawFromAcc = acc::withdraw;
```

This compiles fine and _looks_ reasonable, but it's easy to accidentally reference one fixed instance (`acc::withdraw`) when you actually meant "withdraw from whichever account is passed in" (`Account::withdraw`, used as `BiConsumer<Account, Double>`). This is a common source of confusing bugs — the code compiles, runs, but silently operates on the wrong object.

### 4. `NullPointerException` from an instance method reference

```java
User user = getUserFromDatabase(); // returns null if not found
Supplier<String> nameGetter = user::getName; // NPE happens HERE, not later
```

A specific-object method reference (`user::getName`) evaluates `user` **immediately**, at the point the reference is created — if `user` is `null` at that moment, you get an NPE right there, even before `nameGetter.get()` is ever called. This surprises people who expect the NPE to happen only on invocation.

**Fix:** null-check before creating the reference, or use `Optional`:

```java
Optional.ofNullable(getUserFromDatabase())
    .map(User::getName) // arbitrary-object ref — safe, only runs if present
    .ifPresent(System.out::println);
```

### 5. Overusing method references where a lambda is clearer

```java
// Technically works, but unreadable
list.stream().collect(Collectors.toMap(Function.identity(), User::getAge));

// A plain lambda is sometimes just more readable than forcing a method reference
list.stream().map(x -> process(x, someConfig)); // extra args needed — can't be a plain method ref anyway
```

**Rule:** if you find yourself fighting the syntax or adding an intermediate wrapper method _just_ to make `::` work, it's a sign a lambda would be clearer. Method references are a readability tool, not an obligation.

---

## Pitfalls & "vulnerabilities" — things that bite you in real systems

### 1. Serialized lambdas / method references are a security risk if deserialized from untrusted sources

If you make a lambda or method reference `Serializable`:

```java
Function<String, String> f = (Serializable & Function<String, String>) String::toUpperCase;
```

Serialized lambdas embed enough information to reconstruct **which method to call** on deserialization. Deserializing a lambda/method-reference from an **untrusted source** is dangerous for the same reason raw `ObjectInputStream` deserialization is (which we covered earlier) — a malicious payload could potentially cause arbitrary method invocation. **Avoid serializing lambdas/method references at all** unless you fully control both ends and trust the data source.

### 2. Method references capture their enclosing context (memory/closure gotcha)

```java
class ReportGenerator {
    private byte[] hugeDataset = loadGiantArray(); // 500MB

    Runnable getTask() {
        return this::processData; // captures `this` — including hugeDataset!
    }
}
```

An instance method reference (`this::processData`) implicitly holds a reference to the **entire enclosing object** (`this`), not just the method. If that `Runnable` is stored somewhere long-lived (a thread pool queue, a cache), it keeps the _whole_ `ReportGenerator` object alive — including `hugeDataset` — even if you only needed one small method's behavior. This is a real memory-leak pattern in long-running applications.

**Fix:** if you don't need the whole object's state, extract just what you need before creating the reference, or use a static method reference instead.

### 3. Exception handling gets awkward

Method references (like lambdas) can't throw checked exceptions unless the functional interface's method declares them:

```java
interface RiskyReader {
    String read(String path) throws IOException; // must declare it
}

RiskyReader reader = Files::readString; // fine, because RiskyReader allows IOException
```

But standard JDK functional interfaces like `Function<T,R>` **don't** declare checked exceptions, so this fails:

```java
Function<String, String> reader = Files::readString; // COMPILE ERROR
// Files.readString throws IOException, but Function.apply() doesn't declare it
```

**Fix:** wrap it in a try/catch inside a lambda (loses the clean method-reference syntax), or define your own functional interface that declares the checked exception, as shown above.

---

## Checklist for building your own method-reference-friendly code

- [ ] Define a `@FunctionalInterface` with exactly one abstract method, if none of the JDK's built-ins fit
- [ ] Make sure your method's parameter types and return type match that single abstract method exactly
- [ ] Avoid overloading methods you intend to reference — it creates ambiguity
- [ ] Be deliberate about static vs. instance method references — know which object gets captured
- [ ] Watch for NPEs on instance method references evaluated against a possibly-null object
- [ ] Don't serialize lambdas/method references unless you fully trust the data's origin
- [ ] Be aware instance method references capture the _whole_ enclosing object, not just the method
- [ ] If a checked exception is involved, either declare it in your custom functional interface or handle it before forming the reference



[[Java]]