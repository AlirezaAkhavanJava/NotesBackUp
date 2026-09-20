Date : 2025-09-04

# Mockito Full Tutorial

Mockito is a widely-used Java mocking framework that simplifies unit testing by creating mock objects to simulate dependencies. It integrates seamlessly with testing frameworks like JUnit 5 and is ideal for isolating components during testing. This tutorial covers Mockito from beginner to advanced levels, with practical examples and features up to Java 25 (September 2025). It includes recent updates from Mockito 5.14.0 (Dec 2024).

---

## Phase 1: Getting Started with Mockito

### What is Mockito?

Mockito is a Java library for creating mock objects, allowing developers to test code in isolation by simulating the behavior of dependencies. It supports stubbing, verification, and spying, making it ideal for unit testing.

### Key Features

- **Mocking**: Create mock objects for interfaces or classes.
- **Stubbing**: Define behavior for mock methods.
- **Verification**: Check if mock methods were called.
- **Annotations**: Simplify setup with `@Mock`, `@Spy`, `@InjectMocks`.
- **Integration**: Works with JUnit, TestNG, and Spring.

### Setting Up Mockito

Add Mockito and JUnit 5 dependencies to your project.

**Maven (pom.xml)**:

```xml
<dependency>
    <groupId>org.mockito</groupId>
    <artifactId>mockito-core</artifactId>
    <version>5.14.0</version> <!-- Latest as of Dec 2024 -->
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.mockito</groupId>
    <artifactId>mockito-junit-jupiter</artifactId>
    <version>5.14.0</version>
    <scope>test</scope>
</dependency>
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
    testImplementation 'org.mockito:mockito-core:5.14.0'
    testImplementation 'org.mockito:mockito-junit-jupiter:5.14.0'
    testImplementation 'org.junit.jupiter:junit-jupiter:5.11.0'
}
```

### Basic Mocking Example

Test a service that depends on a repository.

**Example: Basic Mock**

```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.*;

public class UserServiceTest {
    @Test
    void testGetUser() {
        // Create mock
        UserRepository repo = mock(UserRepository.class);
        UserService service = new UserService(repo);

        // Stub mock behavior
        when(repo.findById(1)).thenReturn("Alice");

        // Test
        String result = service.getUser(1);
        assertEquals("User: Alice", result);

        // Verify interaction
        verify(repo).findById(1);
    }
}

interface UserRepository {
    String findById(int id);
}

class UserService {
    private final UserRepository repo;

    UserService(UserRepository repo) {
        this.repo = repo;
    }

    String getUser(int id) {
        return "User: " + repo.findById(id);
    }
}
```

**Run Tests**:

- **IDE**: Run via IntelliJ IDEA or Eclipse.
- **Gradle**: `gradlew test`
- **Maven**: `mvn test`

**Output** (if test passes):

```
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
```

**Key Points**:

- Use `mock()` to create a mock object.
- `when(...).thenReturn(...)` stubs method behavior.
- `verify()` checks if a method was called.
- Place test classes in `src/test/java`.

---

## Phase 2: Core Mockito Concepts

### Annotations

Mockito provides annotations to simplify setup:

- **@Mock**: Creates a mock.
- **@InjectMocks**: Injects mocks into the tested object.
- **@Spy**: Creates a partial mock.
- **@MockitoExtension**: Enables Mockito annotations in JUnit 5.

**Example: Using Annotations**

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class UserServiceTest {
    @Mock
    private UserRepository repo;

    @InjectMocks
    private UserService service;

    @Test
    void testGetUser() {
        when(repo.findById(1)).thenReturn("Alice");
        assertEquals("User: Alice", service.getUser(1));
    }
}
```

**Key Points**:

- `@ExtendWith(MockitoExtension.class)` enables annotations.
- `@InjectMocks` automatically injects mocks via constructor, setter, or field injection.

### Stubbing

Stub methods to return specific values or throw exceptions.

**Example: Stubbing Variations**

```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

public class StubbingTest {
    @Test
    void testStubbing() {
        UserRepository repo = mock(UserRepository.class);

        // Stub return value
        when(repo.findById(1)).thenReturn("Alice");

        // Stub exception
        when(repo.findById(2)).thenThrow(new RuntimeException("User not found"));

        // Stub multiple calls
        when(repo.findById(3)).thenReturn("Bob").thenReturn("Charlie");

        assertEquals("Alice", repo.findById(1));
        assertThrows(RuntimeException.class, () -> repo.findById(2));
        assertEquals("Bob", repo.findById(3));
        assertEquals("Charlie", repo.findById(3));
    }
}
```

**Key Points**:

- Use `thenReturn` for values, `thenThrow` for exceptions.
- Chain `thenReturn` for consecutive calls.

### Verification

Verify interactions with mocks.

**Example: Verification**

```java
import org.junit.jupiter.api.Test;
import static org.mockito.Mockito.*;

public class VerificationTest {
    @Test
    void testVerification() {
        UserRepository repo = mock(UserRepository.class);
        UserService service = new UserService(repo);

        service.getUser(1);

        // Verify method call
        verify(repo).findById(1);

        // Verify no more interactions
        verifyNoMoreInteractions(repo);

        // Verify number of calls
        verify(repo, times(1)).findById(1);

        // Verify no interaction with specific method
        verify(repo, never()).findById(2);
    }
}
```

**Key Points**:

- `verify(mock).method()` checks if a method was called.
- `times(n)`, `never()`, `atLeast(n)` control verification.

---

## Phase 3: Advanced Mockito Features

### Spying

Spies wrap real objects, allowing partial mocking.

**Example: Spy**

```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.*;

public class SpyTest {
    @Test
    void testSpy() {
        UserRepository realRepo = new RealUserRepository();
        UserRepository spyRepo = spy(realRepo);

        // Stub specific behavior
        when(spyRepo.findById(1)).thenReturn("Mocked");

        assertEquals("Mocked", spyRepo.findById(1));
        assertEquals("Real User", spyRepo.findById(2)); // Calls real method

        verify(spyRepo).findById(1);
    }
}

class RealUserRepository implements UserRepository {
    @Override
    public String findById(int id) {
        return "Real User";
    }
}
```

**Key Points**:

- Use `spy()` to wrap real objects.
- Stubbed methods return mocked values; others call real methods.

### Argument Matchers

Use matchers for flexible method stubbing/verification.

**Example: Argument Matchers**

```java
import org.junit.jupiter.api.Test;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.*;

public class MatcherTest {
    @Test
    void testMatchers() {
        UserRepository repo = mock(UserRepository.class);
        when(repo.findById(anyInt())).thenReturn("Any User");

        UserService service = new UserService(repo);
        assertEquals("User: Any User", service.getUser(999));

        verify(repo).findById(anyInt());
    }
}
```

**Key Points**:

- Use `anyInt()`, `anyString()`, `any()` for flexible matching.
- Combine with `eq(value)` for specific arguments.

### BDD-Style Testing

Mockito supports Behavior-Driven Development (BDD) with `BDDMockito`.

**Example: BDD Style**

```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.BDDMockito.*;

public class BDDTest {
    @Test
    void testBDD() {
        UserRepository repo = mock(UserRepository.class);
        UserService service = new UserService(repo);

        // Given
        given(repo.findById(1)).willReturn("Alice");

        // When
        String result = service.getUser(1);

        // Then
        assertEquals("User: Alice", result);
        then(repo).should().findById(1);
    }
}
```

**Key Points**:

- Use `given().willReturn()` instead of `when().thenReturn()`.
- Use `then().should()` instead of `verify()`.

---

## Phase 4: Recent Updates (Mockito 5.14.0, Dec 2024)

- **Improved JUnit 5 Integration**: Enhanced `@MockitoExtension` for parallel tests.
- **GraalVM Support**: Optimized for native image builds.
- **Performance**: Reduced overhead for large mock setups.
- **New Features**: Added support for mocking static methods with `mockStatic`.
- **Bug Fixes**: Improved handling of deep stubs and inline mocks.

**Example: Mocking Static Methods**

```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mockStatic;

public class StaticMockTest {
    @Test
    void testStaticMock() {
        try (var mocked = mockStatic(Utility.class)) {
            mocked.when(Utility::getVersion).thenReturn("1.0");
            assertEquals("1.0", Utility.getVersion());
            mocked.verify(() -> Utility.getVersion());
        }
    }
}

class Utility {
    static String getVersion() {
        return "0.1";
    }
}
```

**Key Points**:

- Use `mockStatic` for static method mocking.
- Requires `mockito-core` or `mockito-inline`.

---

## Phase 5: Concurrent Testing with Virtual Threads

Use Java 21+ virtual threads for concurrent mock testing.

**Example: Concurrent Mocking**

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;
import java.util.concurrent.Executors;

@ExtendWith(MockitoExtension.class)
public class ConcurrentTest {
    @Mock
    private UserRepository repo;

    @InjectMocks
    private UserService service;

    @Test
    void testConcurrent() {
        when(repo.findById(anyInt())).thenReturn("Concurrent User");

        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (int i = 1; i <= 3; i++) {
                int id = i;
                executor.submit(() -> {
                    String result = service.getUser(id);
                    assertEquals("User: Concurrent User", result);
                    System.out.println("Tested ID " + id + " on " + Thread.currentThread().getName());
                });
            }
        }
    }
}
```

**Output**:

```
Tested ID 1 on VirtualThread[#1]
Tested ID 2 on VirtualThread[#2]
Tested ID 3 on VirtualThread[#3]
```

**Key Points**:

- Mockito mocks are thread-safe.
- Virtual threads scale I/O-bound test scenarios.

---

## Phase 6: Integration with Other Tools

### Spring Boot

Test Spring Boot services with Mockito.

**Dependency**:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <version>3.3.4</version> <!-- Check latest -->
    <scope>test</scope>
</dependency>
```

**Example: Spring Boot Test**

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class SpringServiceTest {
    @Mock
    private UserRepository repo;

    @InjectMocks
    private UserService service;

    @Test
    void testSpringService() {
        when(repo.findById(1)).thenReturn("Alice");
        assertEquals("User: Alice", service.getUser(1));
    }
}
```

### Cucumber-JVM

Use Mockito with Cucumber for BDD testing.

**Dependency**:

```xml
<dependency>
    <groupId>io.cucumber</groupId>
    <artifactId>cucumber-java</artifactId>
    <version>7.20.1</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>io.cucumber</groupId>
    <artifactId>cucumber-junit</artifactId>
    <version>7.20.1</version>
    <scope>test</scope>
</dependency>
```

**Feature File (src/test/resources/features/user.feature)**:

```gherkin
Feature: User Service
  Scenario: Get user by ID
    Given a user repository
    When I get user with ID 1
    Then the user name should be "Alice"
```

**Step Definitions**:

```java
package com.example;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.When;
import io.cucumber.java.en.Then;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class UserSteps {
    @Mock
    private UserRepository repo;

    @InjectMocks
    private UserService service;

    private String result;

    @Given("a user repository")
    public void a_user_repository() {
        when(repo.findById(1)).thenReturn("Alice");
    }

    @When("I get user with ID {int}")
    public void i_get_user_with_id(int id) {
        result = service.getUser(id);
    }

    @Then("the user name should be {string}")
    public void the_user_name_should_be(String expected) {
        assertEquals("User: " + expected, result);
    }
}
```

---

## Java Features Up to Java 25 for Mockito

- **Java 8 (2014)**:
    
    - **Lambda Expressions**: Simplify stubbing and verification.
        
        ```java
        when(repo.findById(1)).thenAnswer(inv -> "Alice");
        ```
        
    - **Streams**: Process mock data.
        
        ```java
        List.of(1, 2).stream().forEach(id -> when(repo.findById(id)).thenReturn("User" + id));
        ```
        
- **Java 9 (2017)**:
    
    - **Module System**: Use `module-info.java` for modular tests.
        
        ```java
        module myapp.tests {
            requires org.mockito;
            requires org.junit.jupiter.api;
        }
        ```
        
- **Java 10 (2018)**:
    
    - **var**: Cleaner mock declarations.
        
        ```java
        var repo = mock(UserRepository.class);
        ```
        
- **Java 14 (2020)**:
    
    - **Records**: Use for test data.
        
        ```java
        record User(int id, String name) {}
        when(repo.findUser(1)).thenReturn(new User(1, "Alice"));
        ```
        
- **Java 17 (2021)**:
    
    - **Pattern Matching for `instanceof`**:
        
        ```java
        if (obj instanceof UserRepository repo) {
            when(repo.findById(1)).thenReturn("Alice");
        }
        ```
        
- **Java 21 (2023)**:
    
    - **Virtual Threads**: Concurrent testing (shown above).
    - **Structured Concurrency (Preview)**: Manage parallel tests.
        
        ```java
        import java.util.concurrent.StructuredTaskScope;
        
        @Test
        void testConcurrent() throws Exception {
            UserRepository repo = mock(UserRepository.class);
            when(repo.findById(1)).thenReturn("Alice");
        
            try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
                var future = scope.fork(() -> new UserService(repo).getUser(1));
                scope.join().throwIfFailed();
                assertEquals("User: Alice", future.get());
            }
        }
        ```
        
- **Java 25 (2025)**:
    
    - **Implicit Classes**: Simplify test utilities.
        
        ```java
        implicit class MockUtils {
            static <T> T mockAndStub(Class<T> clazz, String returnValue) {
                T mock = mock(clazz);
                when(mock.toString()).thenReturn(returnValue);
                return mock;
            }
        }
        ```
        
    - **Flexible Constructor Bodies**: Validate test setups.
        
        ```java
        class TestSetup {
            TestSetup(UserRepository repo) {
                if (repo == null) throw new IllegalArgumentException("Repository cannot be null");
                this.repo = mock(UserRepository.class);
            }
        }
        ```
        

---

## Best Practices

1. **Mock Only Dependencies**: Avoid mocking the system under test.
2. **Use Annotations**: Simplify setup with `@Mock` and `@InjectMocks`.
3. **Verify Sparingly**: Focus on key interactions to avoid brittle tests.
4. **Use BDD Style**: For readable test code in collaborative projects.
5. **Integrate with Build Tools**: Use Gradle/Maven for test automation.
    
    ```groovy
    test {
        useJUnitPlatform()
    }
    ```
    
6. **Combine with Other Tools**: Use with Cucumber or Spring Boot for comprehensive testing.

**Related Library: AssertJ**  
For fluent assertions with Mockito:

```xml
<dependency>
    <groupId>org.assertj</groupId>
    <artifactId>assertj-core</artifactId>
    <version>3.26.3</version> <!-- Check latest -->
    <scope>test</scope>
</dependency>
```

**Example: AssertJ with Mockito**

```java
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

public class AssertJTest {
    @Test
    void testWithAssertJ() {
        UserRepository repo = mock(UserRepository.class);
        when(repo.findById(1)).thenReturn("Alice");

        UserService service = new UserService(repo);
        assertThat(service.getUser(1)).isEqualTo("User: Alice");
    }
}
```

---

## Real-World Applications

- **Unit Testing**: Isolate and test service logic.
- **Integration Testing**: Mock external dependencies (e.g., databases, APIs).
- **BDD**: Combine with Cucumber for behavior-driven tests.
- **CI/CD**: Run Mockito tests in Jenkins or GitHub Actions.

---

## Conclusion

Mockito is a powerful mocking framework for Java, enabling isolated unit testing with a simple, expressive API. Start with basic mocks and stubs, use annotations and spies for advanced scenarios, and integrate with JUnit, Spring, or Cucumber for comprehensive testing. Recent updates (Mockito 5.14.0) improve JUnit 5 integration and GraalVM support. Java 25 features like virtual threads and implicit classes enhance testing scalability and simplicity.

**Resources**:

- [Mockito Documentation](https://site.mockito.org/)
- [Mockito GitHub](https://github.com/mockito/mockito)
- [Spring Boot Testing Guide](https://spring.io/guides/gs/testing-web/)




##### *Tags : [[Java]]