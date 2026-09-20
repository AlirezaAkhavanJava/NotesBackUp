
# JUnit 5 Tutorial: From Basic to Advanced


## 1. Introduction to JUnit 5

JUnit 5 is the next generation of the JUnit testing framework, built on three main modules:
- **JUnit Platform**: The foundation for running tests on the JVM, supporting multiple testing engines.
- **JUnit Jupiter**: The API for writing tests and extensions (this is what you'll use most).
- **JUnit Vintage**: For backward compatibility with JUnit 3 and 4 tests.

JUnit 5 emphasizes modularity, extensibility, and modern features like lambda expressions.

## 2. Installation and Setup

### 2.1 Adding Dependencies
Add JUnit Jupiter to your project.

**Maven (`pom.xml`)**:
```xml
<dependencies>
    <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter</artifactId>
        <version>5.12.1</version>  <!-- Use the latest version -->
        <scope>test</scope>
    </dependency>
</dependencies>
```

**Gradle (`build.gradle`)**:
```groovy
dependencies {
    testImplementation 'org.junit.jupiter:junit-jupiter:5.12.1'  // Use the latest version
}
```

For parameterized tests, add:
```xml
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter-params</artifactId>
    <version>5.12.1</version>
    <scope>test</scope>
</dependency>
```

### 2.2 Running Tests
- In IDEs: Right-click and run as JUnit test.
- Maven: `mvn test`
- Gradle: `gradle test`
- Console Launcher: Download from the JUnit site and run `java -jar junit-platform-console-standalone-<version>.jar --class-path <your-classes> --scan-class-path`

Example projects are available on GitHub: [junit-team/junit5-samples](https://github.com/junit-team/junit5-samples).

## 3. Writing Your First Test

Tests are methods annotated with `@Test` in a test class. Import from `org.junit.jupiter.api`.

```java
import static org.junit.jupiter.api.Assertions.assertEquals;
import org.junit.jupiter.api.Test;

class MyFirstJUnitTest {
    @Test
    void addition() {
        assertEquals(2, 1 + 1);
    }
}
```

- Test classes don't need to be public or extend anything.
- Methods must not be abstract, private, or return a value (except for advanced cases).
- Run this, and it should pass.

For a more realistic example with a class under test:
```java
// Calculator.java (src/main/java)
public class Calculator {
    public int add(int a, int b) {
        return a + b;
    }
}

// CalculatorTests.java (src/test/java)
import static org.junit.jupiter.api.Assertions.assertEquals;
import org.junit.jupiter.api.Test;

class CalculatorTests {
    private final Calculator calculator = new Calculator();

    @Test
    void addition() {
        assertEquals(2, calculator.add(1, 1));
    }
}
```

## 4. Assertions

Assertions verify expected outcomes. All are static methods in `org.junit.jupiter.api.Assertions`. Provide an optional failure message (String or `Supplier<String>` for lazy evaluation).

### 4.1 Basic Assertions
```java
@Test
void basicAssertions() {
    assertEquals(2, 1 + 1, "1 + 1 should be 2");
    assertTrue(1 < 2, () -> "1 should be less than 2");  // Lazy message
    assertNotNull(new Object());
    assertFalse(1 > 2);
}
```

### 4.2 Grouped Assertions
All assertions run, even if some fail.
```java
@Test
void groupedAssertions() {
    Person person = new Person("Jane", "Doe");
    assertAll("person properties",
        () -> assertEquals("Jane", person.getFirstName()),
        () -> assertEquals("Doe", person.getLastName())
    );
}
```

### 4.3 Dependent Assertions
Inner assertions run only if outer ones pass.
```java
@Test
void dependentAssertions() {
    Person person = new Person("Jane", "Doe");
    assertAll("properties",
        () -> {
            String firstName = person.getFirstName();
            assertNotNull(firstName);
            assertAll("first name",
                () -> assertTrue(firstName.startsWith("J")),
                () -> assertTrue(firstName.endsWith("e"))
            );
        }
    );
}
```

### 4.4 Exception Assertions
```java
@Test
void exceptionTesting() {
    Exception exception = assertThrows(ArithmeticException.class, () -> {
        int result = 1 / 0;
    });
    assertEquals("/ by zero", exception.getMessage());
}

@Test
void exactExceptionTesting() {
    assertThrowsExactly(ArithmeticException.class, () -> 1 / 0);
}

@Test
void noException() {
    assertDoesNotThrow(() -> System.out.println("No exception"));
}
```

### 4.5 Timeout Assertions
Fail if execution exceeds time.
```java
import static java.time.Duration.ofMillis;
import static java.time.Duration.ofMinutes;

@Test
void timeoutNotExceeded() {
    assertTimeout(ofMinutes(2), () -> {
        // Simulate task under 2 minutes
    });
}

@Test
void timeoutExceededWithPreemptive() {
    assertTimeoutPreemptively(ofMillis(10), () -> Thread.sleep(100));  // Fails and interrupts
}
```
Note: `assertTimeoutPreemptively` uses a separate thread and may affect ThreadLocal values.

### 4.6 Third-Party Assertions
Use libraries like AssertJ, Hamcrest, or Truth for more fluent assertions.
```java
import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.MatcherAssert.assertThat;

@Test
void hamcrestAssertion() {
    assertThat(1 + 1, equalTo(2));
}
```

## 5. Assumptions

Assumptions abort tests if conditions aren't met (not a failure). From `org.junit.jupiter.api.Assumptions`.
```java
@Test
void testOnlyOnCI() {
    assumeTrue("CI".equals(System.getenv("ENV")));
    // Rest of test runs only if true
}

@Test
void testInAllEnvs() {
    assumingThat("DEV".equals(System.getenv("ENV")), 
        () -> assertEquals(2, 1 + 1)
    );
    assertTrue(true);  // Always runs
}
```

## 6. Test Lifecycle Annotations

Control setup/teardown with these annotations. Default lifecycle: new instance per test method (`PER_METHOD`). Use `@TestInstance(Lifecycle.PER_CLASS)` for shared instance.

- `@BeforeAll`: Runs once before all tests (static by default).
- `@BeforeEach`: Before each test.
- `@AfterEach`: After each test.
- `@AfterAll`: Once after all tests (static by default).

```java
import org.junit.jupiter.api.*;

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class LifecycleDemo {
    @BeforeAll
    static void initAll() {
        System.out.println("Before all");
    }

    @BeforeEach
    void init() {
        System.out.println("Before each");
    }

    @Test
    void test1() {
        System.out.println("Test 1");
    }

    @Test
    void test2() {
        System.out.println("Test 2");
    }

    @AfterEach
    void tearDown() {
        System.out.println("After each");
    }

    @AfterAll
    static void tearDownAll() {
        System.out.println("After all");
    }
}
```

Output order: Before all → (Before each → Test 1 → After each) → (Before each → Test 2 → After each) → After all.

## 7. Disabling Tests

Use `@Disabled` to skip tests or classes.
```java
@Disabled("Disabled until bug #42 fixed")
class DisabledClass {
    @Test
    void skippedTest() {}
}

class DisabledMethod {
    @Disabled("Reason")
    @Test
    void skipped() {}
}
```

## 8. Conditional Test Execution

Enable/disable based on conditions using annotations in `org.junit.jupiter.api.condition`.

- `@EnabledOnOs` / `@DisabledOnOs`: By OS (e.g., `@EnabledOnOs(OS.MAC)`).
- `@EnabledOnJre` / `@DisabledOnJre`: By Java version.
- `@EnabledIfEnvironmentVariable` / `@DisabledIfEnvironmentVariable`: By env var.
- `@EnabledIfSystemProperty` / `@DisabledIfSystemProperty`: By system property.
- `@EnabledIf` / `@DisabledIf`: Custom script or method.

Example:
```java
@Test
@EnabledOnOs(OS.MAC)
void onlyOnMac() {}

@Test
@EnabledIfEnvironmentVariable(named = "ENV", matches = "staging-server")
void onlyOnStaging() {}
```

## 9. Repeated Tests

Run a test multiple times with `@RepeatedTest`.
```java
import org.junit.jupiter.api.RepeatedTest;
import org.junit.jupiter.api.RepetitionInfo;

class RepeatedDemo {
    @RepeatedTest(5)
    void repeated() {
        // Runs 5 times
    }

    @RepeatedTest(value = 3, name = "Rep {currentRepetition}/{totalRepetitions}")
    void repeatedWithInfo(RepetitionInfo info) {
        System.out.println("Rep: " + info.getCurrentRepetition());
    }
}
```

## 10. Parameterized Tests

Run tests with different inputs using `@ParameterizedTest` and sources. Requires `junit-jupiter-params`.

### 10.1 Basic Parameterized Test
```java
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

@ParameterizedTest
@ValueSource(strings = {"racecar", "radar"})
void isPalindrome(String candidate) {
    assertTrue(candidate.equals(new StringBuilder(candidate).reverse().toString()));
}
```

### 10.2 Other Sources
- `@EnumSource`: For enums.
- `@MethodSource`: From a factory method returning `Stream<Arguments>`.
- `@CsvSource`: Comma-separated values.
- `@CsvFileSource`: From a CSV file.
- `@NullSource`, `@EmptySource`, `@NullAndEmptySource`: For null/empty values.

Multi-argument example with `@CsvSource`:
```java
import org.junit.jupiter.params.provider.CsvSource;

@ParameterizedTest
@CsvSource({"apple,1", "banana,2"})
void testWithCsv(String fruit, int rank) {
    assertNotNull(fruit);
    assertTrue(rank > 0);
}
```

### 10.3 Argument Conversion and Aggregation
Use `ArgumentsAccessor` or custom aggregators for complex params.
```java
import org.junit.jupiter.params.provider.ArgumentsAccessor;

@ParameterizedTest
@CsvSource({"Jane,Doe"})
void testAccessor(ArgumentsAccessor args) {
    String first = args.getString(0);
    String last = args.getString(1);
    // ...
}
```

### 10.4 Parameterized Classes (Experimental)
Annotate the class with `@ParameterizedClass`.
```java
@ParameterizedClass
@ValueSource(strings = {"apple", "banana"})
class ParamClass {
    @Parameter
    String fruit;

    @Test
    void testFruit() {
        assertNotNull(fruit);
    }
}
```

## 11. Dynamic Tests

Generate tests at runtime with `@TestFactory`.
```java
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;
import java.util.stream.Stream;

@TestFactory
Stream<DynamicTest> dynamicTests() {
    return Stream.of("A", "B")
        .map(str -> DynamicTest.dynamicTest("Test " + str, () -> assertNotNull(str)));
}
```

## 12. Nested Tests

Organize tests hierarchically with `@Nested`.
```java
class NestedDemo {
    @Test
    void outer() {}

    @Nested
    class Inner {
        @Test
        void innerTest() {}
    }
}
```

Use `@TestClassOrder` to order nested classes.

## 13. Test Ordering

Control execution order with `@TestMethodOrder`.
- `@Order(1)` on methods.
- Implementations: `MethodOrderer.Alphanumeric`, `Random`, `OrderAnnotation`.

```java
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class OrderedTests {
    @Test
    @Order(1)
    void test1() {}

    @Test
    @Order(2)
    void test2() {}
}
```

## 14. Tagging and Filtering

Use `@Tag` for categorization and filtering (e.g., in build tools).
```java
@Tag("fast")
@Test
void fastTest() {}
```

Filter in Maven: Configure `surefire-plugin` with `<groups>fast</groups>`.

## 15. Extensions

Extend JUnit with custom behavior via `Extension` interface. Register with `@ExtendWith`.

Example custom extension:
```java
import org.junit.jupiter.api.extension.BeforeEachCallback;
import org.junit.jupiter.api.extension.ExtensionContext;

public class LoggingExtension implements BeforeEachCallback {
    @Override
    public void beforeEach(ExtensionContext context) {
        System.out.println("Starting test: " + context.getDisplayName());
    }
}

@ExtendWith(LoggingExtension.class)
class ExtendedTest {
    @Test
    void test() {}
}
```

## 16. Built-in Extensions

### 16.1 @TempDir
Injects a temporary directory.
```java
@Test
void tempDirTest(@TempDir Path tempDir) throws IOException {
    Path file = tempDir.resolve("test.txt");
    Files.writeString(file, "Hello");
    assertEquals("Hello", Files.readString(file));
}
```

Customize cleanup or use custom factory.

### 16.2 @AutoClose
Auto-closes resources.
```java
class AutoCloseDemo {
    @AutoClose
    AutoCloseable resource = () -> System.out.println("Closing");

    @Test
    void test() {}
}
```

Specify custom close method: `@AutoClose("shutdown")`.

## 17. Parallel Execution

Enable with `junit.jupiter.execution.parallel.enabled=true` in `junit-platform.properties`.

- Modes: `SAME_THREAD` or `CONCURRENT`.
- Strategies: `dynamic` (based on cores), `fixed`, `custom`.

Use `@Execution(ExecutionMode.CONCURRENT)` on classes.

### Synchronization
Use `@ResourceLock` for shared resources.
```java
@Execution(ExecutionMode.CONCURRENT)
class ParallelDemo {
    @Test
    @ResourceLock(value = "systemProperties", mode = ResourceAccessMode.READ_WRITE)
    void modifyProperties() {
        System.setProperty("key", "value");
    }
}
```

Use `@Isolated` for sequential execution.

## 18. Advanced Topics

### 18.1 Test Templates
Use `@TestTemplate` with providers for repeated invocations.

### 18.2 Kotlin Support
JUnit 5 supports Kotlin, including coroutines with `suspend` functions.

```kotlin
import org.junit.jupiter.api.Test

class KotlinTest {
    @Test
    suspend fun coroutineTest() {
        // Use coroutines
    }
}
```

### 18.3 Integration with Other Tools
- Spring: Use `@SpringBootTest`.
- Mocking: Integrate with Mockito via extensions.
- CI/CD: Filter tags in pipelines.

### 18.4 Best Practices
- Keep tests independent and fast.
- Use descriptive names with `@DisplayName`.
- Avoid shared state; use lifecycle methods wisely.
- Parameterize for data-driven tests.
- Enable parallel execution for large suites.



### Tags : [[0 - Spring Framework]]