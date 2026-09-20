

## 🧩 `@Parameters` (JUnit 4)

Used with `@RunWith(Parameterized.class)` to run the **same test multiple times** with **different input data**.

---

### 💡 Example (JUnit 4)

```java
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import java.util.*;

import static org.junit.Assert.*;

@RunWith(Parameterized.class)
public class AdditionTest {

    private int a;
    private int b;
    private int expected;

    // 1️⃣ Constructor receives each set of parameters
    public AdditionTest(int a, int b, int expected) {
        this.a = a;
        this.b = b;
        this.expected = expected;
    }

    // 2️⃣ Define parameters
    @Parameterized.Parameters
    public static Collection<Object[]> data() {
        return Arrays.asList(new Object[][] {
            {1, 2, 3},
            {5, 5, 10},
            {10, -5, 5}
        });
    }

    // 3️⃣ Test method runs for each data set
    @Test
    public void testAddition() {
        assertEquals(expected, a + b);
    }
}
```

🧠 This runs the `testAddition()` **three times** with these inputs:

```
(1,2) → 3
(5,5) → 10
(10,-5) → 5
```

---

## ⚙️ In **JUnit 5**, it’s replaced by new annotations:

|JUnit 4|JUnit 5 Equivalent|Example|
|---|---|---|
|`@RunWith(Parameterized.class)`|`@ParameterizedTest`|`@ParameterizedTest`|
|`@Parameters`|`@ValueSource`, `@CsvSource`, `@MethodSource`, etc.|see below|

### 💡 Example (JUnit 5)

```java
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import static org.junit.jupiter.api.Assertions.*;

class AdditionTest {

    @ParameterizedTest
    @CsvSource({
        "1, 2, 3",
        "5, 5, 10",
        "10, -5, 5"
    })
    void testAddition(int a, int b, int expected) {
        assertEquals(expected, a + b);
    }
}
```

---

### 🧠 TL;DR

|Feature|JUnit 4|JUnit 5|
|---|---|---|
|Enable parameterized test|`@RunWith(Parameterized.class)`|`@ParameterizedTest`|
|Provide data|`@Parameters`|`@ValueSource`, `@CsvSource`, etc.|
|Constructor for data|Yes|No (uses arguments directly)|

---

## 🧩 **1️⃣ Basic: `@ValueSource`**

Test one parameter (primitive or String).

```java
@ParameterizedTest
@ValueSource(strings = {"apple", "banana", "cherry"})
void testFruits(String fruit) {
    assertTrue(fruit.length() > 0);
}
```

Supports types:  
`int`, `long`, `double`, `char`, `String`, `Class<?>`

---

## 🧩 **2️⃣ CSV Data: `@CsvSource`**

Multiple parameters per line.

```java
@ParameterizedTest
@CsvSource({
    "1, 2, 3",
    "5, 5, 10",
    "10, -5, 5"
})
void testAdd(int a, int b, int expected) {
    assertEquals(expected, a + b);
}
```

---

## 🧩 **3️⃣ CSV from File: `@CsvFileSource`**

Loads data from a `.csv` file.

```java
@ParameterizedTest
@CsvFileSource(resources = "/data.csv", numLinesToSkip = 1)
void testAddFromFile(int a, int b, int expected) {
    assertEquals(expected, a + b);
}
```

📁 `src/test/resources/data.csv`

```
a,b,expected
1,2,3
5,5,10
10,-5,5
```

---

## 🧩 **4️⃣ Enum Values: `@EnumSource`**

Iterate over enum constants.

```java
enum Role { ADMIN, USER, GUEST }

@ParameterizedTest
@EnumSource(Role.class)
void testRoles(Role role) {
    assertNotNull(role);
}
```

You can filter:

```java
@EnumSource(value = Role.class, names = {"ADMIN", "USER"})
```

---

## 🧩 **5️⃣ Method Source: `@MethodSource`**

Provide data from a static method.

```java
static Stream<Arguments> numbers() {
    return Stream.of(
        Arguments.of(1, 2, 3),
        Arguments.of(5, 5, 10),
        Arguments.of(10, -5, 5)
    );
}

@ParameterizedTest
@MethodSource("numbers")
void testAddition(int a, int b, int expected) {
    assertEquals(expected, a + b);
}
```

---

## 🧩 **6️⃣ Custom Factory: `@ArgumentsSource`**

You can build your own provider.

```java
class CustomArgsProvider implements ArgumentsProvider {
    @Override
    public Stream<? extends Arguments> provideArguments(ExtensionContext context) {
        return Stream.of(
            Arguments.of("alpha"),
            Arguments.of("beta")
        );
    }
}

@ParameterizedTest
@ArgumentsSource(CustomArgsProvider.class)
void testCustom(String input) {
    assertTrue(input.length() > 0);
}
```

---

## 🧠 TL;DR Table

|Source Type|Annotation|Data Location|Example Input Type|
|---|---|---|---|
|Simple values|`@ValueSource`|Inline|single value|
|CSV inline|`@CsvSource`|Inline|multiple values per test|
|CSV file|`@CsvFileSource`|External file|multiple values|
|Enum|`@EnumSource`|Enum class|constants|
|Method|`@MethodSource`|Static method|custom logic|
|Custom provider|`@ArgumentsSource`|Custom class|full control|

---


##### Tags : [[1 - Junit 5 🥭]]