
`catchException()` is not a standard Java method — it usually refers to a **testing utility method** from **AssertJ** or **Mockito**, used to **capture exceptions** thrown by code under test so you can make assertions on them.

Let’s go through the main versions:

---

### 🧩 1. AssertJ `catchException()`

**Library:** `org.assertj.core.api.Assertions` (old AssertJ API)  
**Purpose:** Execute code and capture the exception it throws, so you can assert on it.

**Example:**

```java
import static org.assertj.core.api.Assertions.*;
import static org.assertj.core.api.AssertionsForClassTypes.catchException;

@Test
void shouldCatchException() {
    // When
    Exception exception = catchException(() -> {
        throw new IllegalArgumentException("Invalid input");
    });

    // Then
    assertThat(exception)
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessage("Invalid input");
}
```

✅ **Modern replacement:**  
`assertThatThrownBy()` is now preferred:

```java
assertThatThrownBy(() -> {
    throw new IllegalArgumentException("Invalid input");
})
.isInstanceOf(IllegalArgumentException.class)
.hasMessage("Invalid input");
```

---

### 🧩 2. Mockito / JUnit Alternative

If you’re not using AssertJ, you can do the same with JUnit:

```java
import static org.junit.jupiter.api.Assertions.assertThrows;

@Test
void shouldThrow() {
    Exception e = assertThrows(IllegalArgumentException.class, () -> {
        throw new IllegalArgumentException("Invalid input");
    });
    assertEquals("Invalid input", e.getMessage());
}
```

---

### 🧠 Summary

|Library|Method|Description|
|---|---|---|
|**AssertJ (old)**|`catchException(() -> ...)`|Captures thrown exception for later assertion|
|**AssertJ (new)**|`assertThatThrownBy(() -> ...)`|Fluent, preferred modern API|
|**JUnit 5**|`assertThrows(Exception.class, () -> ...)`|Built-in JUnit way to test exceptions|


##### Tags : [[1 - Junit 5 🥭]]