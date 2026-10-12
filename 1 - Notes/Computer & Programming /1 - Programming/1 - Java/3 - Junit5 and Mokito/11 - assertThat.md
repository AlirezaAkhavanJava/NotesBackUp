

## 🧩 What is `assertThat()`?

- It’s an **alternative assertion style** from libraries like **Hamcrest** or **AssertJ**.
    
- It makes tests **more readable** and **expressive**, like English sentences.
    

---

## ⚙️ 1️⃣ `assertThat()` with **Hamcrest**

Import from:

```java
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.*;
```

### ✅ Example:

```java
@Test
void testHamcrest() {
    int result = 5 + 5;

    assertThat(result, is(10));
    assertThat(result, not(9));
    assertThat(result, greaterThan(5));
    assertThat("hello", startsWith("he"));
    assertThat(Arrays.asList("apple", "banana"), hasItem("apple"));
}
```

🧠 Readable like:

> “assert that result is 10”  
> “assert that result is greater than 5”

---

## 🧠 Common Hamcrest Matchers

|Matcher|Meaning|
|---|---|
|`is(value)`|Equal to value|
|`not(value)`|Not equal to value|
|`nullValue()` / `notNullValue()`|(not) null|
|`greaterThan(x)` / `lessThan(x)`|Comparison|
|`containsString("abc")`|String contains|
|`startsWith("a")` / `endsWith("z")`|String starts/ends|
|`hasItem(x)` / `hasItems(...)`|Collection contains|
|`empty()` / `not(empty())`|Collection check|
|`instanceOf(Class)`|Type check|
|`equalToIgnoringCase(str)`|Case-insensitive string|

---

## ⚙️ 2️⃣ `assertThat()` with **AssertJ** (newer & better)

Import:

```java
import static org.assertj.core.api.Assertions.assertThat;
```

### ✅ Example:

```java
@Test
void testAssertJ() {
    int result = 10;

    assertThat(result)
        .isEqualTo(10)
        .isGreaterThan(5)
        .isLessThan(20);

    assertThat("Hello World")
        .startsWith("Hello")
        .endsWith("World")
        .contains("lo Wo");

    assertThat(Arrays.asList("A", "B", "C"))
        .hasSize(3)
        .contains("A", "C")
        .doesNotContain("Z");
}
```

🧠 Fluent and chainable — better for modern JUnit 5 projects.

---

## ⚖️ **Hamcrest vs AssertJ**

|Feature|Hamcrest|AssertJ|
|---|---|---|
|Syntax|`assertThat(value, matcher)`|`assertThat(value).isEqualTo(...)`|
|Readability|Natural language|Fluent API|
|Chainable|❌ No|✅ Yes|
|Recommended for JUnit 5|⚠️ Optional|✅ Yes (preferred)|

---

### 🐐 TL;DR

- `assertThat()` = **more expressive assertions**.
    
- **Hamcrest** → old style (`assertThat(actual, is(expected))`).
    
- **AssertJ** → new style (`assertThat(actual).isEqualTo(expected)`), used in **modern Spring & JUnit 5** projects.
    
----
### 🧩 Example: Testing simple math and strings

```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;                // JUnit
import static org.hamcrest.MatcherAssert.assertThat;            // Hamcrest
import static org.hamcrest.Matchers.*;                          // Hamcrest
import static org.assertj.core.api.Assertions.assertThat;       // AssertJ

class AssertComparisonTest {

    @Test
    void testAssertions() {
        int result = 10;
        String text = "Hello World";

        // ==================================
        // 1️⃣ JUnit Assertions (classic)
        // ==================================
        assertEquals(10, result);
        assertTrue(result > 5);
        assertFalse(result < 0);
        assertNotNull(text);
        assertEquals("Hello World", text);

        // ==================================
        // 2️⃣ Hamcrest assertThat
        // ==================================
        org.hamcrest.MatcherAssert.assertThat(result, is(10));
        org.hamcrest.MatcherAssert.assertThat(result, greaterThan(5));
        org.hamcrest.MatcherAssert.assertThat(text, startsWith("Hello"));
        org.hamcrest.MatcherAssert.assertThat(text, containsString("World"));

        // ==================================
        // 3️⃣ AssertJ assertThat (modern)
        // ==================================
        org.assertj.core.api.Assertions.assertThat(result)
                .isEqualTo(10)
                .isGreaterThan(5)
                .isLessThan(20);

        org.assertj.core.api.Assertions.assertThat(text)
                .isNotNull()
                .startsWith("Hello")
                .contains("World")
                .endsWith("World");
    }
}
```

---

### 🧠 Quick Comparison

|Feature|JUnit|Hamcrest|AssertJ|
|---|---|---|---|
|Syntax|`assertEquals(10, result)`|`assertThat(result, is(10))`|`assertThat(result).isEqualTo(10)`|
|Readability|Basic|Natural language|Fluent + chainable|
|Custom messages|Manual|Built-in matchers|Chain methods|
|Best for modern Spring/JUnit5|⚠️ OK|⚠️ Aging|✅ Recommended|

---

🐐 **TL;DR:**

- For old tests → JUnit/Hamcrest.
    
- For new Spring/JUnit 5 tests → **AssertJ** all the way.
    



##### Tags : [[1 - Junit 5 🥭]]