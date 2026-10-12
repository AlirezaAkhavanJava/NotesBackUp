


`@Test` is an annotation from JUnit, the testing framework commonly used by Spring Boot applications. It marks a method as a test method that JUnit should execute.

The important distinction is that `@Test` belongs to JUnit, not Spring Boot itself. Spring Boot integrates with JUnit and provides additional tools for testing your application.

## 1. Why do we need `@Test`?

Suppose you have a service in your Spring Boot application:

```
@Service
public class CalculatorService {

    public int add(int a, int b) {
        return a + b;
    }
}
```

You want to verify that `add(2, 3)` returns `5`.

You could run your application and check it manually. However, manual testing is repetitive and doesn't reliably catch regressions when you change your code.

Instead, write a test:

```
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class CalculatorServiceTest {

    @Test
    void shouldAddTwoNumbers() {
        CalculatorService service = new CalculatorService();

        int result = service.add(2, 3);

        assertEquals(5, result);
    }
}
```

Here's what happens:

1. JUnit discovers the method annotated with `@Test`.
    
2. It executes the method.
    
3. `CalculatorService` calculates the result.
    
4. `assertEquals(5, result)` checks whether the actual result equals the expected result.
    
5. The test passes if the assertion succeeds; otherwise, it fails.
    

Notice that we did not start Spring Boot. We are testing ordinary Java logic, so creating the service directly is sufficient.

## 2. Understand the three important parts

### `@Test`

Test discovery

Tells JUnit that this method is a test to execute.

### `assertEquals(expected, actual)`

Verification

Checks whether the actual result matches what you expect.

### `CalculatorServiceTest`

Test class

Holds related tests. The `Test` suffix is a naming convention, not a requirement imposed by `@Test`.

## 3. Where does `@Test` come from?

In Spring Boot 4, you typically use JUnit Jupiter, provided through Spring Boot's test starter.

```
import org.junit.jupiter.api.Test;
```

The dependency is normally included in your Gradle build:

```
dependencies {
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
}
```

Or Maven:

```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
```

You generally don't need to add JUnit separately when using this starter.

Test classes normally live under `src/test/java`, with the same package structure as the corresponding production classes.

```
src/
├── main/
│   └── java/com/example/demo/
│       └── CalculatorService.java
└── test/
    └── java/com/example/demo/
        └── CalculatorServiceTest.java
```

## 4. Multiple tests in one class

Each `@Test` method should verify a particular behavior.

```
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class CalculatorServiceTest {

    private final CalculatorService service =
            new CalculatorService();

    @Test
    void shouldAddNumbers() {
        assertEquals(5, service.add(2, 3));
    }

    @Test
    void shouldAddNegativeNumbers() {
        assertEquals(-5, service.add(-2, -3));
    }

    @Test
    void shouldReturnZeroWhenAddingZero() {
        assertEquals(0, service.add(0, 0));
    }
}
```

JUnit runs each test independently, and you shouldn't rely on their execution order.

Other useful assertions include:

|Assertion|Purpose|
|---|---|
|`assertEquals(a, b)`|Checks equality|
|`assertTrue(condition)`|Checks that a condition is true|
|`assertFalse(condition)`|Checks that a condition is false|
|`assertNull(value)`|Checks for `null`|
|`assertNotNull(value)`|Checks that a value is not `null`|
|`assertThrows(...)`|Checks that an operation throws an expected exception|

## 5. The critical distinction: `@Test` vs. `@SpringBootTest`

These annotations solve different problems.

|Annotation|Purpose|
|---|---|
|`@Test`|Marks a JUnit test method|
|`@SpringBootTest`|Loads the Spring application context for integration testing|

For example:

```
@SpringBootTest
class ApplicationTests {

    @Test
    void applicationContextLoads() {
    }
}
```

Here, `@SpringBootTest` tells Spring Boot to load the application context. The empty `@Test` method passes if that process succeeds without an error.

By contrast, the earlier `CalculatorServiceTest` doesn't need Spring's application context at all.

Professional rule: Prefer ordinary unit tests for isolated business logic. Use `@SpringBootTest` when you need to verify behavior involving the actual Spring application configuration and components.




[[Testing]]
[[Spring Framework]]