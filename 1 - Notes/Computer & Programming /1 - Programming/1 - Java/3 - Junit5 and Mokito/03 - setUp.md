

## 1️⃣ What is `setUp()`?

- `setUp()` is **a common method name** used in unit tests to **initialize objects or state before each test runs**.
    
- It’s **not special by itself**; it gains special behavior when annotated:
    
    - **JUnit 4:** `@Before`
        
    - **JUnit 5:** `@BeforeEach`
        

---

### 2️⃣ Example in JUnit 4

```java
import org.junit.Before;
import org.junit.Test;
import static org.junit.Assert.*;

public class CalculatorTest {

    Calculator calc;

    @Before
    public void setUp() {
        calc = new Calculator(); // Runs before each test
    }

    @Test
    public void testAdd() {
        assertEquals(5, calc.add(2, 3));
    }

    @Test
    public void testSubtract() {
        assertEquals(1, calc.subtract(3, 2));
    }
}
```

✅ `setUp()` runs **before each test**, so every test starts with a fresh `Calculator`.

---

### 3️⃣ Example in JUnit 5

```java
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class CalculatorTest {

    Calculator calc;

    @BeforeEach
    void setUp() {
        calc = new Calculator(); // Runs before each test
    }

    @Test
    void testAdd() {
        assertEquals(5, calc.add(2, 3));
    }
}
```

---

### 4️⃣ Key Notes

- **Purpose:** Initialize test objects, prepare the environment, reset states.
    
- **Runs:** Before **every** test method.
    
- Can have **any method name**, but `setUp()` is a convention.
    
- Helps avoid **duplicate initialization code** in tests.
    


##### Tags : [[1 - Junit 5 🥭]]