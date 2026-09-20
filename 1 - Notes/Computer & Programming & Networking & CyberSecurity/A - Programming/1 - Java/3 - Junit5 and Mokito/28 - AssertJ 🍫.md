


## 🧩 1. What is AssertJ?

**AssertJ** is a **fluent**, **readable**, and **powerful assertion library** for Java.  
It replaces JUnit’s basic `assertEquals`, `assertTrue`, etc., with a **chainable**, **expressive** syntax.

Example:

```java
assertThat(actualName)
    .isNotNull()
    .isEqualTo("Ethan")
    .startsWith("E")
    .endsWith("n");
```

Compare that to old-school JUnit:

```java
assertNotNull(actualName);
assertEquals("Ethan", actualName);
assertTrue(actualName.startsWith("E"));
assertTrue(actualName.endsWith("n"));
```

See how AssertJ reads almost like **English** — that’s the point.  
It’s “fluent” and helps you understand the test at a glance.

---

## 🧱 2. Setup (Maven / Gradle)

**Maven:**

```xml
<dependency>
  <groupId>org.assertj</groupId>
  <artifactId>assertj-core</artifactId>
  <version>3.26.0</version>
  <scope>test</scope>
</dependency>
```

**Gradle:**

```gradle
testImplementation 'org.assertj:assertj-core:3.26.0'
```

Then import it:

```java
import static org.assertj.core.api.Assertions.assertThat;
```

---

## 🧠 3. Basic Syntax: `assertThat()`

Everything starts with:

```java
assertThat(actualValue)
```

Then you **chain assertion methods** depending on the type (string, number, list, etc.).

---

## 🧩 4. String Assertions

```java
String name = "Ethan";

assertThat(name)
    .isNotNull()
    .isEqualTo("Ethan")
    .isNotEmpty()
    .contains("tha")
    .doesNotContain("zzz")
    .startsWith("E")
    .endsWith("n")
    .hasSize(5)
    .matches("[A-Z][a-z]+");
```

---

## 🧩 5. Number Assertions

```java
int score = 95;

assertThat(score)
    .isGreaterThan(90)
    .isLessThan(100)
    .isBetween(90, 100)
    .isPositive();
```

---

## 🧩 6. Collection Assertions

```java
List<String> names = List.of("Ethan", "Alex", "John");

assertThat(names)
    .isNotEmpty()
    .hasSize(3)
    .contains("Ethan")
    .doesNotContain("Bob")
    .startsWith("Ethan")
    .endsWith("John")
    .containsExactly("Ethan", "Alex", "John"); // order-sensitive
```

Or unordered:

```java
assertThat(names).containsExactlyInAnyOrder("John", "Ethan", "Alex");
```

---

## 🧩 7. Object Property Assertions

You can assert object fields directly:

```java
User user = new User("Ethan", 25);

assertThat(user)
    .extracting(User::getName)
    .isEqualTo("Ethan");

assertThat(user)
    .usingRecursiveComparison()
    .isEqualTo(new User("Ethan", 25));
```

`usingRecursiveComparison()` does a **deep comparison** (all fields).

---

## 🧩 8. Exception Assertions

Very powerful and readable:

```java
Throwable thrown = catchThrowable(() -> {
    service.login(null);
});

assertThat(thrown)
    .isInstanceOf(IllegalArgumentException.class)
    .hasMessageContaining("username");
```

Or shorter with `assertThatThrownBy`:

```java
assertThatThrownBy(() -> service.login(null))
    .isInstanceOf(IllegalArgumentException.class)
    .hasMessage("username cannot be null");
```

---

## 🧩 9. Optional & Stream Assertions

```java
Optional<String> opt = Optional.of("Ethan");

assertThat(opt)
    .isPresent()
    .contains("Ethan")
    .hasValueSatisfying(v -> assertThat(v).startsWith("E"));
```

```java
Stream<String> stream = Stream.of("A", "B", "C");

assertThat(stream)
    .contains("A", "B")
    .doesNotContain("Z");
```

---

## 🧩 10. Combining with Mockito & JUnit

AssertJ fits perfectly with Mockito verifications:

```java
verify(repo).save(captor.capture());
User saved = captor.getValue();

assertThat(saved)
    .isNotNull()
    .extracting(User::getName)
    .isEqualTo("Ethan");
```

Or just compare all fields:

```java
assertThat(saved)
    .usingRecursiveComparison()
    .isEqualTo(expectedUser);
```

---

## 🧩 11. Advanced: Custom Assertions (Reusable)

You can write **your own assert class**:

```java
public class UserAssert extends AbstractAssert<UserAssert, User> {
    public UserAssert(User actual) {
        super(actual, UserAssert.class);
    }

    public static UserAssert assertThat(User actual) {
        return new UserAssert(actual);
    }

    public UserAssert hasName(String expectedName) {
        isNotNull();
        if (!actual.getName().equals(expectedName)) {
            failWithMessage("Expected name to be <%s> but was <%s>", expectedName, actual.getName());
        }
        return this;
    }
}
```

Usage:

```java
User user = new User("Ethan", 25);
UserAssert.assertThat(user).hasName("Ethan");
```

---

## 🧠 12. Summary Cheat Sheet

|Type|Example|
|---|---|
|String|`assertThat(name).contains("E").endsWith("n")`|
|Number|`assertThat(score).isGreaterThan(50)`|
|Collection|`assertThat(list).contains("A").hasSize(3)`|
|Object|`assertThat(user).usingRecursiveComparison().isEqualTo(expected)`|
|Exception|`assertThatThrownBy(() -> code).hasMessageContaining("error")`|
|Optional|`assertThat(opt).isPresent().contains("Ethan")`|

---

## 🧠 Why Developers Prefer AssertJ

✅ Fluent, readable syntax  
✅ Works with any test framework (JUnit, TestNG)  
✅ Deep comparison (`usingRecursiveComparison`)  
✅ Type-safe — gives IDE autocomplete per type  
✅ Beautiful failure messages

---



##### Tags : [[1 - Junit 5 🥭]]