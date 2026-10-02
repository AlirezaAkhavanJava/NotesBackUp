
## 1️⃣ What is `@Before`?

- `@Before` is a **JUnit 4 annotation**.
    
- It marks a method to **run before each test method** in the class.
    
- Used to **set up common objects or state** needed by tests.
    

---

### Example in JUnit 4:

```java
import org.junit.Before;
import org.junit.Test;
import static org.junit.Assert.*;

public class CalculatorTest {

    Calculator calc;

    @Before
    public void setup() {
        calc = new Calculator(); // runs before every test
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

✅ Here, `setup()` is executed **before every test**, so each test gets a fresh `Calculator` instance.

---

## 2️⃣ JUnit 5 Equivalent

- In JUnit 5, `@Before` is **replaced by `@BeforeEach`**.
    
- Syntax is slightly different (methods **don’t need to be `public`**).
    

```java
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class CalculatorTest {

    Calculator calc;

    @BeforeEach
    void setup() {
        calc = new Calculator();
    }

    @Test
    void testAdd() {
        assertEquals(5, calc.add(2, 3));
    }
}
```

---

### TL;DR 🐐

- **`@Before` (JUnit 4)** → runs **before each test**.
    
- **`@BeforeEach` (JUnit 5)** → same, modern version.
    
- Use it to **initialize objects or state** common to multiple tests.
    

-----
### 1️⃣ `@BeforeEach`

- Runs **before every test method**.
    
- Good when you want **fresh objects** for each test so **state doesn’t leak**.
    
- Example: new mocks, new service instances.
    

```java
@BeforeEach
void setup() {
    repository = mock(UserRepository.class);
    service = new UserService(repository);
}
```

- Every test gets its **own clean objects**.
    
- Useful when tests **modify the object**.
    

---

### 2️⃣ `@BeforeAll`

- Runs **once before all tests**.
    
- Good for **expensive objects** that don’t change across tests.
    
- Must be **static** (in JUnit 5 unless you use `@TestInstance(Lifecycle.PER_CLASS)`).
    

```java
@BeforeAll
static void globalSetup() {
    databaseConnection = new DatabaseConnection();
}
```

- All tests share the **same object**.
    
- Be careful: if tests modify it, **state can leak** into other tests.
    

---

💡 Rule of thumb:

- **Stateful or mutable objects** → `@BeforeEach`
    
- **Expensive, immutable, shared objects** → `@BeforeAll`
    



##### Tags : [[1 - Junit 5 🥭]]