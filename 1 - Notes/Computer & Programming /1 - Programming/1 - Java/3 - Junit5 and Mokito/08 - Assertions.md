

## 1️⃣ What are Assertions?

- Assertions are **methods that check if a condition is true** during a test.
    
- If an assertion fails, the test **fails immediately**.
    
- Used in **JUnit** (and other test frameworks) to **validate expected behavior**.
    

---

## 2️⃣ JUnit 5 Assertions

All are in `org.junit.jupiter.api.Assertions`.

|Assertion|Description|Example|
|---|---|---|
|`assertEquals(expected, actual)`|Checks equality|`assertEquals(5, calc.add(2,3));`|
|`assertNotEquals(unexpected, actual)`|Checks inequality|`assertNotEquals(0, calc.add(2,3));`|
|`assertTrue(condition)`|Checks if true|`assertTrue(3 < 5);`|
|`assertFalse(condition)`|Checks if false|`assertFalse(5 < 3);`|
|`assertNull(object)`|Checks if null|`assertNull(calc.getValue());`|
|`assertNotNull(object)`|Checks if not null|`assertNotNull(calc);`|
|`assertThrows(Exception.class, executable)`|Checks if exception thrown|`assertThrows(ArithmeticException.class, () -> 1/0);`|
|`assertAll("heading", exec1, exec2, ...)`|Group multiple assertions|`assertAll("Math", () -> assertEquals(5, calc.add(2,3)), () -> assertEquals(1, calc.subtract(3,2)));`|
|`fail(message)`|Fails test immediately|`fail("This should not happen");`|

---

## 3️⃣ Example Usage

```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class CalculatorTest {

    @Test
    void testCalculator() {
        Calculator calc = new Calculator();

        assertEquals(5, calc.add(2,3));
        assertTrue(calc.subtract(3,2) > 0);
        assertNotNull(calc);

        assertThrows(ArithmeticException.class, () -> calc.divide(1,0));

        assertAll("Multiple checks",
            () -> assertEquals(6, calc.multiply(2,3)),
            () -> assertEquals(2, calc.divide(6,3))
        );
    }
}
```

---

### 4️⃣ Key Notes

- Assertions **fail the test if the condition is not met**.
    
- `assertAll` is great for checking multiple conditions in **one test** without stopping at the first failure.
    
- `assertThrows` is essential for testing **exception scenarios**.
    
- Use descriptive messages in assertions to make **test failures readable**:
    

```java
assertEquals(5, calc.add(2,3), "Addition should be 5");
```

---

### TL;DR 🐐

Assertions = **checks inside tests** that ensure your code behaves as expected.  
If an assertion fails → test fails → you know something is broken.

---

All the essential assertions in **one scrollable block**.

```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class AssertionsCheatSheet {

    @Test
    void allAssertions() {
        Calculator calc = new Calculator();

        // ======================
        // 1️⃣ Equality
        // ======================
        assertEquals(5, calc.add(2,3), "2+3 should be 5");   // equal
        assertNotEquals(0, calc.add(2,3), "Sum should not be 0"); // not equal

        // ======================
        // 2️⃣ Boolean
        // ======================
        assertTrue(calc.subtract(3,2) > 0, "3-2 should be positive"); // true
        assertFalse(calc.subtract(2,3) > 0, "2-3 should not be positive"); // false

        // ======================
        // 3️⃣ Null checks
        // ======================
        assertNull(calc.getValue(), "Value should be null");    // null
        assertNotNull(calc, "Calculator should not be null");   // not null

        // ======================
        // 4️⃣ Exceptions
        // ======================
        assertThrows(ArithmeticException.class, () -> calc.divide(1,0), "Division by zero"); 

        // ======================
        // 5️⃣ Grouped assertions
        // ======================
        assertAll("Multiple checks",
            () -> assertEquals(6, calc.multiply(2,3), "2*3=6"),
            () -> assertEquals(2, calc.divide(6,3), "6/3=2")
        );

        // ======================
        // 6️⃣ Fail manually
        // ======================
        if(calc.add(1,1) != 2) {
            fail("Addition failed"); // force fail
        }
    }
}
```

✅ **Quick Notes:**

- `assertEquals` / `assertNotEquals` → check values.
    
- `assertTrue` / `assertFalse` → boolean conditions.
    
- `assertNull` / `assertNotNull` → null checks.
    
- `assertThrows` → exception testing.
    
- `assertAll` → multiple assertions in one test.
    
- `fail()` → immediately fail a test manually.
    


##### Tags : [[1 - Junit 5 🥭]]