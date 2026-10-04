

## The mental model: foreseeable shortages vs. dropped trays

Back in the kitchen: the cook knows the egg supplier is sometimes out of stock. That's a **foreseeable, external condition**, and a competent kitchen has a **written fallback plan** for it. Imagine the restaurant owner (the compiler) refusing to let any cook start a shift until each station has declared either "I'll handle missing eggs myself" or "I'm passing that problem up to the head chef." That's a **checked exception**.

Now the cook drops a tray because he tripped on his own untied shoelace. Nobody writes a per-dish plan for that. It's a **mistake**, and the fix is to tie your shoes, not to wrap every dish in a recovery procedure. If it happens, the shift is disrupted until someone higher up deals with it. That's an **unchecked exception**.

One idea underlies the whole distinction: **checked exceptions put certain failure modes into the method's signature, and the compiler enforces that every caller deals with them.** Unchecked ones don't.

## The precise rules

### Classification is purely by position in the hierarchy

```
Throwable
├── Error                      → UNCHECKED
└── Exception                  → CHECKED (by default)
    └── RuntimeException       → UNCHECKED
```

- **Unchecked** = `RuntimeException`, `Error`, and all their subclasses.
- **Checked** = every other `Throwable`, including `Exception` itself and a class that extends `Throwable` directly.

Which one you get when you write `class MyEx extends ...` is decided by the **parent you pick**, and nothing else.

### The "catch or declare" rule

If a statement can throw a checked exception, the enclosing code must do one of two things, or it won't compile:

```java
// Option 1: handle it here
void a() {
    try {
        Files.readString(Path.of("x.txt"));
    } catch (IOException e) {
        // recover, log, or translate
    }
}

// Option 2: declare it, making it the caller's problem
void b() throws IOException {
    Files.readString(Path.of("x.txt"));
}
```

If you choose option 2, the same rule now applies to everyone who calls `b()`. The obligation **propagates upward through signatures** until somebody catches it.

### It's a compile-time-only concept

The JVM **has no concept of checked exceptions.** At the bytecode level, `athrow` throws any `Throwable`. The `throws` clause is stored as metadata (the `Exceptions` attribute in the class file) that the compiler and reflection can read, but the runtime ignores it. This has a surprising consequence, shown below under "sneaky throws."

So checked exceptions are really a **static analysis feature**: a rule about what the compiler will accept, not a different runtime mechanism.

## The "why": two philosophies

Java's designers wanted a method's failure modes to be part of its **contract**, visible in the signature, so you couldn't call `readFile()` without being told "this can fail with an I/O problem." The guidance, popularized by Joshua Bloch, splits errors into two kinds:

||**Contingency** (→ checked)|**Programming error** (→ unchecked)|
|---|---|---|
|Cause|External world: disk, network, user data|Bug in the caller's code|
|Can the caller reasonably recover?|Yes (retry, fall back, ask user)|No, the code needs fixing|
|Examples|`IOException`, `SQLException`, `TimeoutException`|`NullPointerException`, `IllegalArgumentException`, `ArrayIndexOutOfBoundsException`|
|Why this type|Forcing handling prevents ignoring a real possibility|Forcing handling would litter code with pointless try/catch|

Imagine if `NullPointerException` were checked: every `obj.method()` would need a `try/catch`. It would be unusable. `Error` is unchecked for similar reasons: nothing you can do about `OutOfMemoryError` at the call site.

## Where the model breaks down (and why people argue about it)

The tidy theory runs into trouble in practice.

**1. The recoverability line is blurry.**  
`Integer.parseInt("abc")` throws `NumberFormatException` (unchecked), even though bad user input is a perfectly foreseeable condition. Meanwhile `Thread.sleep()` forces you to handle `InterruptedException` (checked), which most callers can't do anything meaningful about. The JDK itself isn't consistent, because the right category depends on the _caller's context_, which the API author doesn't know.

**2. Lambdas and streams fight them.**

```java
List<String> contents = paths.stream()
    .map(p -> Files.readString(p))   // COMPILE ERROR: unreported IOException
    .toList();
```

`Function.apply` doesn't declare `throws`, so a lambda body can't throw a checked exception. (Contrast `Callable.call() throws Exception`, which can, and `Runnable.run()`, which can't.) Your options:

```java
// a) catch inside the lambda and translate to unchecked
.map(p -> {
    try { return Files.readString(p); }
    catch (IOException e) { throw new UncheckedIOException(e); }
})

// b) a generic functional interface that carries the exception type
@FunctionalInterface
interface ThrowingFunction<T, R, E extends Exception> {
    R apply(T t) throws E;
}
```

`UncheckedIOException` exists in the JDK for exactly this purpose. Note also that `Files.lines()` and `Files.walk()` return lazy streams, so I/O errors can surface _later_, during iteration, as `UncheckedIOException`, and you won't see them at the call site.

**3. Signature leakage and API rot.**  
Say `Repository.find()` declares `throws SQLException`. Now your service layer and controller layer must declare or wrap it, and your interface is married to JDBC. Switching to a REST backend means changing every signature. Adding a new checked exception to an existing method **breaks every caller at compile time**, a source-incompatible change.

The usual fix is **exception translation** at layer boundaries: catch the low-level exception and throw one that fits your layer's abstraction, **with the original as the cause**.

```java
catch (SQLException e) {
    throw new UserLookupException("failed to load user " + id, e);
}
```

**4. Pressure toward bad habits.**  
When the compiler forces you to handle something you can't handle, the path of least resistance is `catch (Exception e) {}` or `throws Exception` on everything. That is arguably _worse_ than no checking at all, because it hides failures while looking compliant.

Because of all this, many modern frameworks (Spring's `DataAccessException`, Hibernate) deliberately wrap everything in unchecked exceptions, and Kotlin and C# dropped checked exceptions entirely. Java's checked exceptions remain a debated design.

## Edge cases and details

### The compiler checks only what it can prove

```java
try {
    System.out.println("hi");
} catch (IOException e) { }   // COMPILE ERROR: body can never throw IOException
```

Catching a checked exception the body _cannot_ throw is an error. But `catch (Exception e)` and `catch (Throwable e)` are always legal, because the body might throw unchecked subtypes.

### `throws` on an unchecked exception is legal but cosmetic

```java
void f() throws IllegalArgumentException { }   // allowed; callers need not handle it
```

It serves as documentation only. Prefer a Javadoc `@throws` tag for unchecked exceptions that callers should know about.

### Overriding narrows, never widens

```java
class Parent { void m() throws IOException { } }
class Child extends Parent {
    void m() throws FileNotFoundException { }   // OK, narrower
    // void m() throws Exception { }            // ERROR, wider
    // void m() { }                             // OK, may throw nothing
}
```

Reason: code holding a `Parent` reference was told only about `IOException`. A subclass can't spring a new checked surprise on it. This is the Liskov substitution principle enforced by the compiler. (Unchecked exceptions are exempt, since callers never agreed to anything about them.)

### Constructors and initializers

- A constructor can declare `throws`.
- A subclass constructor **must** declare any checked exceptions thrown by the superclass constructor it calls, including through the implicit `super()`.
- A **static initializer block cannot throw checked exceptions** (nobody could catch them). Failures there become `ExceptionInInitializerError`.

### Precise rethrow and generic `throws`

Since Java 7, `catch (Exception e) { throw e; }` only requires your method to declare the checked types the `try` body can _actually_ throw, not `Exception`. And with a generic exception type parameter (like `ThrowingFunction` above), when you use it with a lambda that throws nothing checked, the compiler infers `E` as `RuntimeException`, so no handling is required. That makes the pattern pleasant to use.

### Sneaky throws: proof that it's compile-time only

```java
@SuppressWarnings("unchecked")
static <E extends Throwable> void sneaky(Throwable t) throws E {
    throw (E) t;     // the cast is erased, so no runtime check happens
}
// call: Util.<RuntimeException>sneaky(new IOException());
```

Because of **type erasure**, the cast to `E` disappears at runtime, so a checked exception flies out of a method that doesn't declare it. Lombok's `@SneakyThrows` does this. It's legal but dangerous, because callers can't catch `IOException` with a normal pattern (the compiler will complain that the body can't throw it), so the exception travels past them unseen.

### Unchecked doesn't mean unimportant

Unchecked exceptions are still part of your API's behavior. Document them, and **validate arguments early** with a clear message (`IllegalArgumentException`, or `Objects.requireNonNull`), so failures point at the real cause.

## How to choose for your own exceptions

A practical decision guide:

1. **Is it a bug in the caller (null, out-of-range, violated precondition)?** → **Unchecked.**
2. **Is it an unrecoverable infrastructure failure** where no caller would do anything but log and abort? → **Unchecked.**
3. **Is it an expected, external failure that a typical caller can meaningfully act on** (retry, use a default, tell the user)? → **Checked is defensible**, particularly in a library where forcing awareness is valuable.
4. **Unsure?** → The modern default is **unchecked**, since you can always add documentation, but removing a checked exception from the API later is much easier than adding one.

## How it connects

- **Type system and substitution:** the overriding rules are Liskov enforced at compile time.
- **Generics and erasure:** explain both the elegant generic-`throws` trick and the sneaky-throw loophole.
- **Functional programming:** lambda friction is the main reason the debate is still alive; it's why `Optional`, `Either`-style results, and wrapper utilities are popular for _expected_ failures.
- **Layered architecture:** exception translation and cause chaining keep abstractions from leaking.
- **Resource handling:** `AutoCloseable.close()` declares `throws Exception`, while `Closeable.close()` narrows to `IOException`, an overriding-narrowing example that matters in try-with-resources.



[[Exception]]
[[Java]]