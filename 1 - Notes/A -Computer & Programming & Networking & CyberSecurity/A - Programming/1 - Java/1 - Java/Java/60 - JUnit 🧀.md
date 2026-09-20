Date : 2025-09-04


# JUnit Full Tutorial

JUnit is a widely-used testing framework for Java that simplifies writing and running unit tests. JUnit 5 (Jupiter) is the latest version, offering a modular architecture, improved annotations, and support for modern Java features. This tutorial covers JUnit 5 from beginner to advanced levels, with practical examples and features up to Java 25 (September 2025). It includes recent updates from JUnit 5.11.0 (Dec 2024).

---

## Phase 1: Getting Started with JUnit

### What is JUnit?

JUnit is a framework for writing and executing unit tests in Java. It helps verify that individual components (e.g., methods, classes) work as expected. JUnit 5 consists of:

- **JUnit Jupiter**: API for writing tests.
- **JUnit Platform**: Foundation for running tests.
- **JUnit Vintage**: Support for JUnit 3/4 tests.

### Key Features

- **Annotations**: `@Test`, `@BeforeEach`, `@AfterEach`, etc., for test lifecycle.
- **Assertions**: Verify expected outcomes (e.g., `assertEquals`).
- **Test Runners**: Execute tests with IDEs, Gradle, or Maven.
- **Modular Design**: Extensible and compatible with other tools (e.g., Mockito).

### Setting Up JUnit 5

Add JUnit 5 dependencies to your project.

**Maven (pom.xml)**:

```xml
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <version>5.11.0</version>
    <scope>test</scope>
</dependency>
```

**Gradle (build.gradle)**:

```groovy
dependencies {
    testImplementation 'org.junit.jupiter:junit-jupiter:5.11.0'
}
```

### Basic Test Example

Create a test class in `src/test/java`.

**Example: Simple JUnit Test**

```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;

public class CalculatorTest {
    @Test
    void testAddition() {
        Calculator calc = new Calculator();
        assertEquals(5, calc.add(2, 3), "2 + 3 should equal 5");
    }
}

class Calculator {
    int add(int a, int b) {
        return a + b;
    }
}
```

**Run Tests**:

- **IDE**: Use IntelliJ IDEA or Eclipse to run tests (right-click and select "Run").
- **Gradle**: `gradlew test`
- **Maven**: `mvn test`

**Output** (if test passes):

```
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
```

**Key Points**:

- Use `@Test` to mark test methods.
- `assertEquals(expected, actual, message)` checks equality with an optional message.
- Place test classes in `src/test/java` to follow convention.

---

## Phase 2: Core JUnit Concepts

### Test Lifecycle Annotations

JUnit 5 provides annotations to manage test setup and teardown.

- **@BeforeEach**: Runs before each test.
- **@AfterEach**: Runs after each test.
- **@BeforeAll**: Runs once before all tests (static method).
- **@AfterAll**: Runs once after all tests (static method).

**Example: Lifecycle Annotations**

```java
import org.junit.jupiter.api.*;

public class LifecycleTest {
    private StringBuilder builder;

    @BeforeAll
    static void setupAll() {
        System.out.println("Before all tests");
    }

    @BeforeEach
    void setup() {
        builder = new StringBuilder();
        System.out.println("Before each test");
    }

    @Test
    void testAppend() {
        builder.append("Test");
        Assertions.assertEquals("Test", builder.toString());
    }

    @AfterEach
    void teardown() {
        builder = null;
        System.out.println("After each test");
    }

    @AfterAll
    static void teardownAll() {
        System.out.println("After all tests");
    }
}
```

**Output**:

```
Before all tests
Before each test
After each test
After all tests
```

### Assertions

JUnit 5 provides `org.junit.jupiter.api.Assertions` for verifying results.

- `assertEquals(expected, actual)`: Check equality.
- `assertTrue(condition)`: Check if true.
- `assertThrows(class, executable)`: Check for expected exceptions.
- `assertTimeout(duration, executable)`: Check execution time.

**Example: Assertions**

```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class AssertionsTest {
    @Test
    void testAssertions() {
        assertEquals(4, 2 + 2, "Math error");
        assertTrue("hello".startsWith("h"), "String should start with h");
        assertThrows(ArithmeticException.class, () -> { int x = 1 / 0; }, "Should throw");
        assertTimeout(Duration.ofSeconds(1), () -> Thread.sleep(500), "Too slow");
    }
}
```

**Key Points**:

- Use descriptive messages for better debugging.
- `assertAll` groups multiple assertions, running all even if some fail.

---

## Phase 3: Advanced JUnit Features

### Parameterized Tests

Run the same test with different inputs using `@ParameterizedTest`.

**Example: Parameterized Test**

```java
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class ParameterizedTestExample {
    @ParameterizedTest
    @ValueSource(strings = {"hello", "world", "java"})
    void testStringNotEmpty(String input) {
        assertTrue(!input.isEmpty(), "String should not be empty");
    }
}
```

**Key Points**:

- Use `@ValueSource`, `@CsvSource`, or `@MethodSource` for test data.
- Requires `junit-jupiter-params` dependency:
    
    ```xml
    <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter-params</artifactId>
        <version>5.11.0</version>
        <scope>test</scope>
    </dependency>
    ```
    

### Repeated Tests

Run tests multiple times with `@RepeatedTest`.

**Example: Repeated Test**

```java
import org.junit.jupiter.api.RepeatedTest;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class RepeatedTestExample {
    @RepeatedTest(3)
    void testRandomNumber(RepetitionInfo info) {
        double random = Math.random();
        assertTrue(random >= 0 && random < 1, "Random should be in [0,1)");
        System.out.println("Repetition: " + info.getCurrentRepetition());
    }
}
```

**Output**:

```
Repetition: 1
Repetition: 2
Repetition: 3
```

### Conditional Test Execution

Enable or disable tests based on conditions.

- **@Disabled**: Skip a test.
- **@EnabledOnOs**: Run on specific OS.
- **@EnabledIfSystemProperty**: Run if a system property matches.

**Example: Conditional Test**

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledOnOs;
import org.junit.jupiter.api.condition.OS;

public class ConditionalTest {
    @Test
    @EnabledOnOs(OS.WINDOWS)
    void testOnWindows() {
        System.out.println("Running on Windows");
    }
}
```

---

## Phase 4: Recent Updates (JUnit 5.11.0, Dec 2024)

- **Improved Assertions**: Enhanced `assertAll` with better reporting.
- **Dynamic Tests**: Better support for `@TestFactory` with improved lifecycle hooks.
- **GraalVM Support**: Optimized for native image builds.
- **Performance**: Reduced memory overhead for large test suites.
- **New Extensions**: Added support for structured concurrency in test execution.

**Example: Dynamic Tests**

```java
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;
import static org.junit.jupiter.api.Assertions.assertEquals;
import java.util.stream.Stream;

public class DynamicTestExample {
    @TestFactory
    Stream<DynamicTest> dynamicTests() {
        return Stream.of(1, 2, 3)
                     .map(i -> DynamicTest.dynamicTest("Test " + i, 
                         () -> assertEquals(i * 2, i + i)));
    }
}
```

---

## Phase 5: Concurrent Testing with Virtual Threads

JUnit 5 integrates well with Java’s concurrency features, including virtual threads (Java 21+).

**Example: Concurrent Tests with Virtual Threads**

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.parallel.Execution;
import org.junit.jupiter.api.parallel.ExecutionMode;
import java.util.concurrent.Executors;

@Execution(ExecutionMode.CONCURRENT)
public class ConcurrentTest {
    @Test
    void testConcurrent() {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            executor.submit(() -> {
                Assertions.assertTrue(true);
                System.out.println("Running in " + Thread.currentThread().getName());
            }).get();
        } catch (Exception e) {
            Assertions.fail("Concurrent test failed");
        }
    }
}
```

**Output**:

```
Running in VirtualThread[#1]
```

**Key Points**:

- Use `@Execution(ExecutionMode.CONCURRENT)` for parallel test execution.
- Virtual threads scale I/O-bound test tasks efficiently.
- Configure parallel execution in `junit-platform.properties`:
    
    ```properties
    junit.jupiter.execution.parallel.enabled=true
    junit.jupiter.execution.parallel.mode.default=concurrent
    ```
    

---

## Phase 6: Integration with Other Tools

### Mockito

Mock dependencies for unit testing.

**Maven Dependency**:

```xml
<dependency>
    <groupId>org.mockito</groupId>
    <artifactId>mockito-junit-jupiter</artifactId>
    <version>5.14.0</version> <!-- Check latest -->
    <scope>test</scope>
</dependency>
```

**Example: Mockito with JUnit**

```java
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

public class ServiceTest {
    @Test
    void testMock() {
        MyService service = Mockito.mock(MyService.class);
        when(service.getValue()).thenReturn("Mocked");
        assertEquals("Mocked", service.getValue());
    }
}

interface MyService {
    String getValue();
}
```

### Spring Boot Testing

Use JUnit with Spring Boot for integration tests.

**Example: Spring Boot Test**

```java
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
public class SpringBootTestExample {
    @Autowired
    private MyService service;

    @Test
    void testService() {
        Assertions.assertNotNull(service);
    }
}
```

**Dependency**:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <version>3.3.4</version> <!-- Check latest -->
    <scope>test</scope>
</dependency>
```

---

## Java Features Up to Java 25 for JUnit

- **Java 8 (2014)**:
    
    - **Lambda Expressions**: Simplify assertions and test setup.
        
        ```java
        assertAll("numbers",
            () -> assertEquals(4, 2 + 2),
            () -> assertTrue(1 < 2));
        ```
        
    - **Streams**: Generate dynamic test data.
        
        ```java
        Stream.of(1, 2, 3).map(i -> dynamicTest("Test " + i, () -> assertEquals(i, i)));
        ```
        
- **Java 9 (2017)**:
    
    - **Module System**: Use `module-info.java` for modular test suites.
        
        ```java
        module myapp.tests {
            requires org.junit.jupiter.api;
        }
        ```
        
- **Java 10 (2018)**:
    
    - **var**: Cleaner test code.
        
        ```java
        var calc = new Calculator();
        ```
        
- **Java 14 (2020)**:
    
    - **Records**: Use for test data.
        
        ```java
        record User(String name, int age) {}
        @Test
        void testUser() {
            User user = new User("Alice", 25);
            assertEquals("Alice", user.name());
        }
        ```
        
- **Java 17 (2021)**:
    
    - **Pattern Matching for `instanceof`**:
        
        ```java
        if (obj instanceof String s) {
            assertTrue(s.length() > 0);
        }
        ```
        
- **Java 21 (2023)**:
    
    - **Virtual Threads**: Concurrent test execution (shown above).
    - **Structured Concurrency (Preview)**: Manage parallel tests.
        
        ```java
        import java.util.concurrent.StructuredTaskScope;
        
        @Test
        void testStructured() throws Exception {
            try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
                var future = scope.fork(() -> { assertTrue(true); return null; });
                scope.join().throwIfFailed();
            }
        }
        ```
        
- **Java 25 (2025)**:
    
    - **Implicit Classes**: Simplify test utilities.
        
        ```java
        implicit class TestUtils {
            static void assertNotEmpty(String value) {
                Assertions.assertFalse(value.isEmpty());
            }
        }
        ```
        
    - **Flexible Constructor Bodies**: Validate test setups.
        
        ```java
        class TestSetup {
            TestSetup(Object obj) {
                if (obj == null) throw new IllegalArgumentException("Object cannot be null");
            }
        }
        ```
        

---

## Best Practices

1. **Use Descriptive Test Names**: Use `@DisplayName` for readable test names.
    
    ```java
    @Test
    @DisplayName("Addition should work correctly")
    void testAddition() {
        assertEquals(5, 2 + 3);
    }
    ```
    
2. **Keep Tests Independent**: Avoid shared state between tests.
3. **Use Assertions Wisely**: Prefer `assertAll` for multiple checks.
4. **Leverage Parameterized Tests**: Test multiple inputs efficiently.
5. **Integrate with Build Tools**: Use Gradle/Maven for test automation.
    
    ```groovy
    test {
        useJUnitPlatform()
    }
    ```
    
6. **Mock Dependencies**: Use Mockito for unit tests.

**Related Library: AssertJ**  
For fluent assertions:

```xml
<dependency>
    <groupId>org.assertj</groupId>
    <artifactId>assertj-core</artifactId>
    <version>3.26.3</version> <!-- Check latest -->
    <scope>test</scope>
</dependency>
```

**Example: AssertJ**

```java
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;

public class AssertJTest {
    @Test
    void testString() {
        assertThat("hello").startsWith("h").hasSize(5);
    }
}
```

---

## Real-World Applications

- **Unit Testing**: Verify individual methods or classes.
- **Integration Testing**: Test interactions with databases or APIs (e.g., Spring Boot).
- **Regression Testing**: Ensure new changes don’t break existing functionality.
- **CI/CD**: Run tests in Jenkins, GitHub Actions, or Travis CI.

---

## Conclusion

JUnit 5 (Jupiter) is a powerful, flexible testing framework for Java, offering annotations, assertions, and extensibility for modern applications. Start with basic tests, use parameterized and dynamic tests for flexibility, and leverage concurrent testing with virtual threads. Recent updates (JUnit 5.11.0) improve performance and GraalVM support. Java 25 features like virtual threads and implicit classes enhance testing scalability and simplicity.

**Resources**:

- [JUnit 5 User Guide](https://junit.org/junit5/docs/current/user-guide/)
- [JUnit 5 GitHub](https://github.com/junit-team/junit5)
- [Spring Boot Testing Guide](https://spring.io/guides/gs/testing-web/)



##### *Tags : [[Java]]