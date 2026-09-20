
`@ExtendWith` is a **JUnit 5** annotation that tells JUnit to load an **extension** for the test class.

An extension is something that adds extra behavior (mocking, lifecycle hooks, parameter injection, etc.).

---

# ✔️ What it does

`@ExtendWith(SomeExtension.class)` means:

> “JUnit, before running these tests, plug in this extension and let it modify how tests run.”

---

# ✔️ Example you used

```java
@ExtendWith(MockitoExtension.class)
class CalculatorTest {
}
```

This tells JUnit:

- Enable Mockito support
    
- Process `@Mock` fields
    
- Initialize mocks before each test
    
- Handle injection
    
- Prevent you from writing `MockitoAnnotations.openMocks(this)`
    

So this:

```
@Mock
Calculator calculatorMock;
```

gets automatically initialized by MockitoExtension.

---

# ✔️ Common JUnit Extensions

|Extension|What it does|
|---|---|
|`MockitoExtension`|Initializes mocks (`@Mock`, `@InjectMocks`, etc.)|
|`SpringExtension`|Enables Spring Boot test context|
|`MySqlExtension`|Custom DB setup/cleanup|
|`LoggingExtension`|Add logging before/after tests|

---

# ✔️ Why JUnit uses extensions

JUnit 4 had “runners” like:

```
@RunWith(MockitoJUnitRunner.class)
```

But you could only have **one** runner.

JUnit 5 replaced runners with extensions → now you can have many:

```
@ExtendWith(MockitoExtension.class)
@ExtendWith(SpringExtension.class)
```

---



### ⚙️ In **JUnit 5**, `@RunWith` is **replaced** by:

👉 `@ExtendWith`

```java
@ExtendWith(MockitoExtension.class)
class ServiceTest {
    @Mock
    private Repository repo;
}
```

---

### 🧠 TL;DR

|JUnit Version|Annotation|Example|
|---|---|---|
|JUnit 4|`@RunWith(MockitoJUnitRunner.class)`|Old way|
|JUnit 5|`@ExtendWith(MockitoExtension.class)`|New way ✅|

---

A **JUnit Runner** is a class in the JUnit testing framework that is responsible for **discovering, executing, and reporting the results** of test cases in a Java application.

### Key Responsibilities of a JUnit Runner:
1. **Find test methods** (annotated with `@Test`, or legacy ones using naming conventions).
2. **Run the tests** in the correct order.
3. **Handle setup/teardown** (e.g., `@Before`, `@After`, `@BeforeClass`, `@AfterClass`).
4. **Collect and report results** (pass/fail, exceptions, etc.).
5. **Support advanced features** like parameterized tests, suites, rules, etc.

---

### How to Use a Runner

You specify a runner using the `@RunWith` annotation on your test class:

```java
import org.junit.runner.RunWith;
import org.junit.runners.JUnit4;
import org.junit.Test;

@RunWith(JUnit4.class)
public class MyTest {
    @Test
    public void shouldDoSomething() {
        // test code
    }
}
```

> Note: In **JUnit 5**, `@RunWith` is **not used**. Instead, JUnit 5 uses the **Jupiter engine** automatically if you're using `@ExtendWith` or no annotation at all for basic tests.

---

### Common Built-in JUnit 4 Runners

| Runner | Purpose |
|--------|--------|
| `JUnit4.class` | Default runner for JUnit 4 |
| `Suite.class` | Run multiple test classes together |
| `Parameterized.class` | Run the same test with different input data |
| `Categories.class` | Group and filter tests by category |
| `Enclosed.class` | Run inner static test classes |
| `SpringJUnit4ClassRunner.class` | Integrates with Spring (from Spring Test) |
| `MockitoJUnitRunner.class` | Initializes Mockito mocks automatically |

#### Example: Parameterized Test
```java
@RunWith(Parameterized.class)
public class MathTest {
    private int input, expected;

    public MathTest(int input, int expected) {
        this.input = input;
        this.expected = expected;
    }

    @Parameters
    public static Collection<Object[]> data() {
        return Arrays.asList(new Object[][] {{1, 2}, {2, 4}, {3, 6}});
    }

    @Test
    public void testDouble() {
        assertEquals(expected, input * 2);
    }
}
```

---

### JUnit 5 (Jupiter) – No `@RunWith`

In **JUnit 5**, the platform uses **extensible engines**. You don’t need `@RunWith`. Instead:
- Use `@ExtendWith` for custom extensions.
- The default runner is the **JUnit Jupiter engine**.

```java
import org.junit.jupiter.api.Test;

class MyModernTest {
    @Test
    void shouldWork() {
        // no @RunWith needed
    }
}
```

---

### Summary

| Feature | JUnit 4 | JUnit 5 |
|--------|--------|--------|
| Runner annotation | `@RunWith(RunnerClass.class)` | Not used |
| Default execution | Explicit runner required | Jupiter engine (automatic) |
| Custom behavior | Via runners | Via `@ExtendWith(Extension.class)` |

---

**TL;DR**:  
A **JUnit Runner** is the engine that runs your tests. In JUnit 4, you pick one with `@RunWith`. In JUnit 5, it's built-in via the Jupiter engine.

##### Tags : [[1 - Junit 5 🥭]]