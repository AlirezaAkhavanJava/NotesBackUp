
Every method below lives in `org.junit.jupiter.api.Assertions`, and the usual habit is a static import so you can write `assertEquals(...)` without the class name:

```java
import static org.junit.jupiter.api.Assertions.*;
```

Every assertion has an optional last parameter, a failure message, so when it fails you see your own explanation: `assertEquals(1, count, "should have exactly one user")`. If building the message is costly, pass a lambda instead (`() -> "..."`) and it only gets built on failure.

## Comparing values

**`assertEquals(expected, actual)`** checks that two values are equal, using `.equals()` for objects. Expected comes first.

```java
assertEquals(3, list.size());
assertEquals("alireza", user.getName());
```

For `double` and `float`, you pass a tolerance as a third argument, because floating-point math isn't exact (`0.1 + 0.2` is not exactly `0.3`):

```java
assertEquals(0.3, 0.1 + 0.2, 0.0001);
```

**`assertNotEquals(unexpected, actual)`** is the opposite: passes when the values differ.

```java
assertNotEquals(oldPassword, user.getPassword());
```

**`assertSame(expected, actual)`** checks that both variables point to the _exact same object_ in memory (it uses `==`). This is different from `assertEquals`, which asks "are they equal in value?" It's handy for singletons or cached objects. **`assertNotSame`** is the reverse.

```java
assertSame(serviceA, serviceB);   // same bean instance
```

One trap: if your class (say, a JPA entity) doesn't override `equals()`, then `assertEquals` falls back to comparing references, and two objects with identical fields will "not be equal." Either implement `equals`/`hashCode`, or compare the fields you care about.

## Booleans and nulls

```java
assertTrue(user.isActive());
assertFalse(list.isEmpty());
assertNull(repository.findByName("ghost"));
assertNotNull(user.getId());
```

These are simple, but prefer `assertEquals` when you can. `assertTrue(a == b)` only tells you "it was false," while `assertEquals(a, b)` tells you what the two values actually were.

## Collections and arrays

**`assertArrayEquals(expectedArray, actualArray)`** compares arrays element by element. Plain `assertEquals` on arrays would compare references and fail.

**`assertIterableEquals(expected, actual)`** compares anything iterable (lists, sets) element by element, in order, regardless of the exact collection type. A `List.of(1, 2)` and an `ArrayList` holding 1, 2 pass.

```java
assertArrayEquals(new int[]{1, 2, 3}, result);
assertIterableEquals(List.of("a", "b"), names);
```

**`assertLinesMatch(expectedLines, actualLines)`** compares lists of strings, where each expected line can be an exact match or a regular expression. It's mostly useful for log or text output.

## Testing exceptions

This is how you test that something fails _correctly_.

**`assertThrows(ExceptionType.class, executable)`** passes if the lambda throws that type _or a subclass_. It also returns the exception, so you can inspect the message:

```java
IllegalArgumentException ex = assertThrows(
    IllegalArgumentException.class,
    () -> userService.create("")
);
assertEquals("name must not be blank", ex.getMessage());
```

**`assertThrowsExactly(...)`** is stricter: the exception must be exactly that type, not a subclass.

**`assertDoesNotThrow(executable)`** passes if nothing is thrown. It can also return the value of a supplier:

```java
User user = assertDoesNotThrow(() -> userService.create("alireza"));
```

## Types

**`assertInstanceOf(Type.class, object)`** checks the object's type and returns it already cast, so you can keep using it:

```java
Dog dog = assertInstanceOf(Dog.class, animalService.find(1L));
```

## Grouping several checks

**`assertAll(...)`** runs _all_ the assertions inside it, even if some fail, and then reports every failure together. Without it, the first failure stops the test and hides the rest.

```java
assertAll("user",
    () -> assertEquals("alireza", user.getName()),
    () -> assertNotNull(user.getId()),
    () -> assertTrue(user.isActive())
);
```

## Time limits

**`assertTimeout(Duration, executable)`** runs the code, waits for it to finish, and fails if it took too long. **`assertTimeoutPreemptively(...)`** instead aborts the code the moment time runs out.

```java
assertTimeout(Duration.ofSeconds(2), () -> reportService.generate());
```

A Spring-specific warning: the preemptive version runs your code on a _different thread_. That breaks anything tied to the test's thread, like `@Transactional` rollback. In Spring tests, stick with plain `assertTimeout`.

## Failing on purpose

**`fail("message")`** fails the test immediately. It's useful when code should never reach a certain line:

```java
try {
    service.doRiskyThing();
    fail("should have thrown");
} catch (MyException expected) {
    // good
}
```

In practice, `assertThrows` replaces most of these try/catch patterns.

## A close cousin: assumptions

Assumptions live in `org.junit.jupiter.api.Assumptions`, and they work differently. `assumeTrue(condition)` doesn't fail the test when false, it _skips_ it. That's for tests that only make sense in certain conditions, like "only run if Docker is available." The analogy to assertions breaks down right there: an assertion says "this must be true or something is broken," an assumption says "this must be true or this test doesn't apply."

## AssertJ: the fluent alternative

Spring Boot's test starter also gives you AssertJ, where you start with `assertThat(actual)` and chain what you expect. It reads left to right and gives richer failure messages. The same checks look like this:

```java
import static org.assertj.core.api.Assertions.*;

assertThat(user.getName()).isEqualTo("alireza");
assertThat(user.getId()).isNotNull();
assertThat(user.isActive()).isTrue();
assertThat(count).isGreaterThan(0).isLessThan(10);
```

It really shines with strings and collections:

```java
assertThat(name).startsWith("ali").endsWith("reza").hasSize(7);
assertThat(names).hasSize(3)
                 .contains("alireza")
                 .doesNotContain("ghost")
                 .containsExactly("a", "b", "c");   // exact items, exact order
assertThat(names).containsExactlyInAnyOrder("c", "a", "b");
assertThat(users).extracting(User::getName).contains("alireza");
assertThat(optional).isPresent().hasValue("x");
```

And exceptions:

```java
assertThatThrownBy(() -> userService.create(""))
    .isInstanceOf(IllegalArgumentException.class)
    .hasMessageContaining("blank");
```

## Spring's own assertions

When you test controllers with `MockMvc`, you'll meet another family, used inside `.andExpect(...)`:

```java
mockMvc.perform(get("/users/1"))
       .andExpect(status().isOk())
       .andExpect(jsonPath("$.name").value("alireza"));
```

Those check HTTP status, headers, and JSON fields, and they're a topic of their own once you reach `@WebMvcTest`.

If you want one rule of thumb to start with: learn `assertEquals`, `assertTrue`, `assertNotNull`, `assertThrows`, and `assertAll` first, which covers most tests you'll write, then pick up AssertJ when you want more readable checks on collections.




[[Testing]]
[[Spring Framework]]