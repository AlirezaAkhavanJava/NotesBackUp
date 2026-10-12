> A _unit test_ is a small automated test that checks if _one specific piece of code_ works exactly as expected.
### 1️⃣ What is JUnit 5?

- JUnit 5 is the modern version of JUnit (successor of JUnit 4) for **unit testing in Java**.
    
- Modular and more powerful.
    
- It consists of three main modules:
    
    1. **JUnit Platform** → Launches the testing framework, supports running tests from IDEs or build tools.
        
    2. **JUnit Jupiter** → Provides the new programming model and annotations (core of JUnit 5).
        
    3. **JUnit Vintage** → Allows running old JUnit 3/4 tests.
        

---

### 2️⃣ Core Annotations

Here’s a cleaned-up, corrected, and more consistent version of your table:

| Annotation           | Description                                          | When to use / Notes                                                                                                                                          | Convention / Typical Name             |
| -------------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------- |
| `@Test`              | Marks a method as a test.                            | Use on any test method.                                                                                                                                      | `methodName()`                        |
| `@BeforeEach`        | Runs **before each test method**.                    | Use when you need a fresh setup before every test. If most tests use the same setup, put it here to avoid repetition.                                        | `setUp()`                             |
| `@AfterEach`         | Runs **after each test method**.                     | Rarely needed—only when a test creates resources or dirt that must be cleaned (files, DB connections, threads, static state).                                | `tearDown()`                          |
| `@BeforeAll`         | Runs **once before all tests** in the class.         | Use for shared or expensive setup that is safe to share across all tests. Must be static unless using `@TestInstance(Lifecycle.PER_CLASS)`.                  | `setUpAll()` – usually static fields  |
| `@AfterAll`          | Runs **once after all tests** in the class.          | Use for cleanup of shared resources created in `@BeforeAll` (connections, servers, files). Must be static unless using `@TestInstance(Lifecycle.PER_CLASS)`. | `tearDownAll()` – usually static      |
| `@Disabled`          | Skips a test (like `@Ignore` in JUnit 4).            | Use to temporarily disable a test or test class.                                                                                                             | —                                     |
| `@Nested`            | Creates nested test classes for better organization. | Use for complex classes with multiple scenarios, allowing each nested group to have its own setup/teardown.                                                  | —                                     |
| `@DisplayName`       | Sets a custom name for the test method or class.     | Use to make test names readable in reports or IDEs.                                                                                                          | `"Descriptive name"`                  |
| `@RepeatedTest`      | Runs a test multiple times.                          | Use when you want to repeat a test (e.g., for flaky behavior or probabilistic tests).                                                                        | `@RepeatedTest(5)`                    |
| `@ParameterizedTest` | Runs the same test with different parameters.        | Use when you want to test the same logic with multiple input values.                                                                                         | See `@ValueSource`, `@CsvSource` etc. |
| `@Tag`               | Tags a test for filtering in test runs.              | Use to categorize tests (unit, integration, slow, fast, etc.) so you can selectively run certain groups without changing code.                               | `"fast"`, `"integration"`, etc.       |


---

### 3️⃣ Assertions

JUnit 5 uses `org.junit.jupiter.api.Assertions`:

```java
import static org.junit.jupiter.api.Assertions.*;

@Test
void testAssertions() {
    assertEquals(5, 2 + 3);
    assertTrue(3 < 5);
    assertFalse(5 < 3);
    assertNotNull(new Object());
    assertThrows(ArithmeticException.class, () -> { int x = 1/0; });
}
```

---

### 4️⃣ Example Test Class

```java
import org.junit.jupiter.api.*;

class CalculatorTest {

    Calculator calc;

    @BeforeEach
    void setup() {
        calc = new Calculator();
    }

    @Test
    @DisplayName("Test addition")
    void testAdd() {
        Assertions.assertEquals(5, calc.add(2, 3));
    }

    @Test
    void testDivideByZero() {
        Assertions.assertThrows(ArithmeticException.class, () -> calc.divide(1, 0));
    }

    @AfterEach
    void cleanup() {
        calc = null;
    }
}
```

---

### 5️⃣ Parameterized Test Example

```java
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class MathTest {

    @ParameterizedTest
    @ValueSource(ints = {2, 4, 6, 8})
    void testEvenNumbers(int number) {
        Assertions.assertTrue(number % 2 == 0);
    }
}
```

---

### 6️⃣ Key Features

- **No need for public test classes/methods** (unlike JUnit 4).
    
- Supports **Lambda expressions** in assertions.
    
- Integrates well with **Maven/Gradle**.
    
- Better support for **nested tests**, **dynamic tests**, and **parameterized tests**.
    
- Runs JUnit 3 & 4 tests via **Vintage** module.
    

---



All you need for fast reference while coding tests.

```java
// ======================
// 1️⃣ Basic Setup
// ======================
import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.*;

class ExampleTest {

    // ======================
    // 2️⃣ Lifecycle Methods
    // ======================
    @BeforeAll        // Runs once before all tests (static)
    static void initAll() {
        System.out.println("Before all tests");
    }

    @BeforeEach       // Runs before each test
    void init() {
        System.out.println("Before each test");
    }

    @AfterEach        // Runs after each test
    void tearDown() {
        System.out.println("After each test");
    }

    @AfterAll         // Runs once after all tests (static)
    static void tearDownAll() {
        System.out.println("After all tests");
    }

    // ======================
    // 3️⃣ Basic Tests
    // ======================
    @Test
    @DisplayName("Simple addition test")
    void additionTest() {
        assertEquals(5, 2 + 3);             // Check equality
        assertTrue(3 < 5);                   // Boolean true
        assertFalse(5 < 3);                  // Boolean false
        assertNotNull(new Object());         // Not null
        assertThrows(ArithmeticException.class, () -> { int x = 1/0; }); // Exception
    }

    @Disabled("Test skipped for now")     // Skip a test
    @Test
    void skippedTest() {
    }

    // ======================
    // 4️⃣ Parameterized Tests
    // ======================
    @ParameterizedTest
    @ValueSource(ints = {2, 4, 6, 8})
    void evenNumbersTest(int number) {
        assertTrue(number % 2 == 0);
    }

    @ParameterizedTest
    @CsvSource({"2,4,6", "3,3,6", "5,5,10"})
    void addNumbersTest(int a, int b, int expected) {
        assertEquals(expected, a + b);
    }

    // ======================
    // 5️⃣ Nested Tests
    // ======================
    @Nested
    @DisplayName("Nested Math Tests")
    class NestedMath {

        @Test
        void multiplyTest() {
            assertEquals(6, 2 * 3);
        }
    }

    // ======================
    // 6️⃣ Repeated Test
    // ======================
    @RepeatedTest(3)
    void repeatedTest() {
        System.out.println("Runs 3 times");
    }

    // ======================
    // 7️⃣ Tags (filter tests)
    // ======================
    @Test
    @Tag("fast")
    void fastTest() {
        assertTrue(true);
    }
}
```

✅ **Quick Notes:**

- No need for public classes/methods.
    
- `@DisplayName` → makes reports readable.
    
- `assertThrows` → easy exception testing with lambdas.
    
- `@ParameterizedTest` + `@ValueSource` or `@CsvSource` → run tests with multiple inputs.
    
- `@Nested` → organize tests like folders.
    
- Tags → filter tests in IDE or Maven/Gradle (`mvn test -Dgroups=fast`).
    

---

🐐 **JUnit 4 → JUnit 5 Annotations Cheat Sheet** 🐐

Quick reference for migrating or learning both.

|JUnit 4|JUnit 5|Description|
|---|---|---|
|`@Before`|`@BeforeEach`|Runs **before each test**. Initialize objects here.|
|`@After`|`@AfterEach`|Runs **after each test**. Cleanup after tests.|
|`@BeforeClass`|`@BeforeAll`|Runs **once before all tests**. Method must be `static`.|
|`@AfterClass`|`@AfterAll`|Runs **once after all tests**. Method must be `static`.|
|`@Test`|`@Test`|Marks a test method.|
|`@Ignore`|`@Disabled`|Skips a test.|
|`@RunWith`|`@ExtendWith`|Extends test class functionality (e.g., Mockito, Spring).|
|`@Rule` / `@ClassRule`|`@TestInstance` / Extensions|JUnit 5 replaces rules with extensions or lifecycle control.|
|`@Parameterized`|`@ParameterizedTest`|Runs tests with multiple inputs. Use `@ValueSource`, `@CsvSource`, etc.|
|`@Category`|`@Tag`|Tags tests for filtering or grouping.|
|`@Assume`|`Assumptions`|Conditional test execution based on runtime conditions.|

---

### Key Notes:

- **JUnit 5 does not require `public` methods**; JUnit 4 did.
    
- Extensions replace many `@Rule` usages (`MockitoExtension`, `SpringExtension`, etc.).
    
- `@BeforeAll` and `@AfterAll` require `static` unless you use `@TestInstance(Lifecycle.PER_CLASS)`.
    
- Use `@Disabled` instead of `@Ignore` for clarity and better reporting.
    

----

## Rules : 

> The test class name  should match the name of the actual class + Test  like if the class name was Scooter the test class should be name ScooterTest

##### Tags : [[Java]]