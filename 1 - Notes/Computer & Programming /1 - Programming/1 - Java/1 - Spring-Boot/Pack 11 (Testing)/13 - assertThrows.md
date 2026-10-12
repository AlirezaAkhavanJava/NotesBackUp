

`assertThrows` checks that a piece of code **throws a specific exception**. If the exception is thrown, the test passes. If nothing is thrown, or a different exception type is thrown, the test fails. You've already seen it in the duplicate-email tests:

```java
assertThrows(EmailAlreadyUsedException.class,
        () -> service.register("Ana", "ana@example.com"));
```

(The method name is `assertThrows`, with an "s".)

## The signature

```java
<T extends Throwable> T assertThrows(Class<T> expectedType, Executable executable)
<T extends Throwable> T assertThrows(Class<T> expectedType, Executable executable, String message)
```

- **`expectedType`**: the exception class you expect.
- **`executable`**: a lambda containing the code that should throw. `Executable` is a functional interface whose single method may throw `Throwable`, so you don't need try/catch inside the lambda.
- **Return value**: the exception that was thrown, so you can inspect it further.

## Why it exists: the old way was clumsy

Before JUnit 5, you'd write this:

```java
@Test
void rejectsNegativePercent() {
    try {
        calculator.applyDiscount(100.0, -5);
        fail("Expected IllegalArgumentException");
    } catch (IllegalArgumentException e) {
        // expected
    }
}
```

It's noisy, and it's easy to forget the `fail(...)` line, which would make the test pass even when nothing was thrown. `assertThrows` removes that whole class of mistakes.

## Inspecting the exception

Because it returns the exception, you can assert on its message or other details:

```java
@Test
void rejectsDuplicateEmailWithHelpfulMessage() {
    when(repository.existsByEmail("ana@example.com")).thenReturn(true);

    EmailAlreadyUsedException ex = assertThrows(EmailAlreadyUsedException.class,
            () -> service.register("Ana", "ana@example.com"));

    assertEquals("Email already in use: ana@example.com", ex.getMessage());
}
```

Use this when the message or a field (an error code, say) is part of the behavior you care about. Don't assert on message text that is just incidental wording, or the test will break whenever someone rephrases it.

## Subclasses count, exact matching doesn't

`assertThrows` passes if the thrown exception is the expected type **or a subclass** of it:

```java
// Passes if the code throws IllegalArgumentException or NumberFormatException
// (NumberFormatException extends IllegalArgumentException)
assertThrows(IllegalArgumentException.class, () -> Integer.parseInt("abc"));
```

If you need the _exact_ class and nothing more specific, use `assertThrowsExactly`:

```java
assertThrowsExactly(IllegalArgumentException.class, () -> ...);
```

Be careful with overly broad types like `Exception.class` or `RuntimeException.class`. They'll pass for almost any failure, including bugs like a `NullPointerException`, so the test stops proving anything specific.

## Keep the lambda small

Put only the call that should throw inside the lambda, and do your setup outside:

```java
// Good: setup outside, one action inside
User user = new User(null, "Ana", "ana@example.com");
assertThrows(IllegalStateException.class, () -> user.activate().activate());

// Risky: if the setup line throws, the test might pass for the wrong reason
assertThrows(IllegalStateException.class, () -> {
    User user = new User(null, "Ana", "ana@example.com");
    user.activate().activate();
});
```

In the second version, an exception thrown while _constructing_ the object would also satisfy the assertion, hiding a real problem.

## Related: `assertDoesNotThrow`

The opposite check, useful for confirming that valid input is accepted:

```java
assertDoesNotThrow(() -> calculator.applyDiscount(100.0, 50));
```

It's handy, but often redundant. If the test already calls the method and asserts on the result, any exception would fail the test anyway.

## AssertJ alternative

If your project uses AssertJ (very common with Spring Boot, since `spring-boot-starter-test` includes it), there's a fluent version:

```java
import static org.assertj.core.api.Assertions.*;

assertThatThrownBy(() -> service.register("Ana", "ana@example.com"))
        .isInstanceOf(EmailAlreadyUsedException.class)
        .hasMessage("Email already in use: ana@example.com");

// Or, when you only care about the type:
assertThatExceptionOfType(EmailAlreadyUsedException.class)
        .isThrownBy(() -> service.register("Ana", "ana@example.com"));
```

It chains the checks on type, message, and cause into one readable statement. Which one you use is mostly taste; just stay consistent within a project.

## Common mistakes

- **Wrong exception type**: the test fails with a message like `Unexpected exception type thrown, expected: <X> but was: <Y>`, which is actually useful, since it tells you what was really thrown.
- **Nothing thrown**: fails with `Expected X to be thrown, but nothing was thrown`. This usually means the validation you thought existed doesn't.
- **Forgetting that checked exceptions are fine**: unlike old try/catch patterns, `Executable` allows checked exceptions to propagate, so you don't need `throws` clutter in the lambda.
- **Testing too much in one lambda**: if two different calls could each throw, split them into two tests.




[[Testing]]
[[Spring Framework]]