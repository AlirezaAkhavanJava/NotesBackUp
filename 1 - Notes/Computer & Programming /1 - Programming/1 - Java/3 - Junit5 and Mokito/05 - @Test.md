
## 1️⃣ What is `@Test`?

- `@Test` marks a method as a **test case** in a unit test class.
    
- Both **JUnit 4** and **JUnit 5** use it, though the package differs:
    

|Version|Package|
|---|---|
|JUnit 4|`org.junit.Test`|
|JUnit 5|`org.junit.jupiter.api.Test`|

- Methods annotated with `@Test` are **executed by the test runner** automatically.
    

---

## 2️⃣ Basic Example (JUnit 5)

```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class CalculatorTest {

    @Test
    void testAdd() {
        Calculator calc = new Calculator();
        assertEquals(5, calc.add(2, 3));
    }

    @Test
    void testSubtract() {
        Calculator calc = new Calculator();
        assertEquals(1, calc.subtract(3, 2));
    }
}
```

✅ Each method with `@Test` is treated as **a separate test**.

---

## 3️⃣ Key Notes

- `@Test` methods **don’t need to be public** in JUnit 5 (JUnit 4 requires `public`).
    
- Can be combined with:
    
    - `@DisplayName("Custom Name")` → friendly name for reports
        
    - `@Disabled` → skip a test
        
    - Assertions (`assertEquals`, `assertTrue`, etc.)
        
    - Exception testing (`assertThrows` in JUnit 5)
        

---

### TL;DR 🐐

`@Test` → tells JUnit: “Hey, run this method as a test.”  
Without it, the method is **ignored by the test runner**.



##### Tags : [[1 - Junit 5 🥭]]