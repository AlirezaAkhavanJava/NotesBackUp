Date : 2025-09-04


# Cucumber-JVM Full Tutorial

Cucumber-JVM is a Java implementation of the Cucumber framework, enabling Behavior-Driven Development (BDD) by allowing teams to write executable specifications in plain text. It bridges business and technical teams by using Gherkin syntax for feature files, which are linked to Java step definitions for test automation. This tutorial covers Cucumber-JVM from beginner to advanced levels, with practical examples and features up to Java 25 (September 2025). It includes recent updates from Cucumber-JVM 7.20.1 (Dec 2024).

---

## Phase 1: Getting Started with Cucumber-JVM

### What is Cucumber-JVM?

Cucumber-JVM enables BDD by letting developers write tests in Gherkin, a human-readable format, and map them to Java code. It supports collaboration between developers, testers, and stakeholders by defining application behavior in plain text.

### Key Features

- **Gherkin Syntax**: Write feature files with `Feature`, `Scenario`, `Given`, `When`, `Then`.
- **Step Definitions**: Java methods that implement Gherkin steps.
- **Integration**: Works with JUnit, TestNG, Spring, and REST Assured.
- **Plugins**: Generate reports (e.g., HTML, JSON).
- **Extensibility**: Supports hooks, tags, and data-driven testing.

### Setting Up Cucumber-JVM

Add Cucumber-JVM and JUnit 5 dependencies to your project.

**Maven (pom.xml)**:

```xml
<dependency>
    <groupId>io.cucumber</groupId>
    <artifactId>cucumber-java</artifactId>
    <version>7.20.1</version> <!-- Latest as of Dec 2024 -->
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>io.cucumber</groupId>
    <artifactId>cucumber-junit</artifactId>
    <version>7.20.1</version>
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
    testImplementation 'io.cucumber:cucumber-java:7.20.1'
    testImplementation 'io.cucumber:cucumber-junit:7.20.1'
    testImplementation 'org.junit.jupiter:junit-jupiter:5.11.0'
}
```

### Basic Cucumber Test

Create a feature file and step definitions to test a simple calculator.

**Feature File (src/test/resources/features/calculator.feature)**:

```gherkin
Feature: Calculator
  Scenario: Add two numbers
    Given I have a calculator
    When I add 2 and 3
    Then the result should be 5
```

**Step Definitions (src/test/java/com/example/CalculatorSteps.java)**:

```java
package com.example;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.When;
import io.cucumber.java.en.Then;
import static org.junit.jupiter.api.Assertions.assertEquals;

public class CalculatorSteps {
    private Calculator calculator;
    private int result;

    @Given("I have a calculator")
    public void i_have_a_calculator() {
        calculator = new Calculator();
    }

    @When("I add {int} and {int}")
    public void i_add_and(int a, int b) {
        result = calculator.add(a, b);
    }

    @Then("the result should be {int}")
    public void the_result_should_be(int expected) {
        assertEquals(expected, result);
    }
}

class Calculator {
    int add(int a, int b) {
        return a + b;
    }
}
```

**JUnit Runner (src/test/java/com/example/RunCucumberTest.java)**:

```java
package com.example;

import io.cucumber.junit.Cucumber;
import io.cucumber.junit.CucumberOptions;
import org.junit.runner.RunWith;

@RunWith(Cucumber.class)
@CucumberOptions(features = "src/test/resources/features", glue = "com.example")
public class RunCucumberTest {
}
```

**Run Tests**:

- **IDE**: Run `RunCucumberTest` in IntelliJ IDEA or Eclipse.
- **Gradle**: `gradlew test`
- **Maven**: `mvn test`

**Output** (if test passes):

```
1 Scenarios (1 passed)
3 Steps (3 passed)
```

**Key Points**:

- Feature files go in `src/test/resources/features`.
- Step definitions go in `src/test/java`.
- `@CucumberOptions` specifies feature and glue (step definition) paths.
- Use `{int}` in Gherkin for parameter matching.

---

## Phase 2: Core Cucumber Concepts

### Gherkin Syntax

Gherkin uses keywords like `Feature`, `Scenario`, `Given`, `When`, `Then`, and `And` to describe behavior.

**Example: Enhanced Feature File**

```gherkin
Feature: Advanced Calculator
  Scenario: Subtract two numbers
    Given I have a calculator
    When I subtract 5 from 8
    Then the result should be 3

  Scenario Outline: Multiply numbers
    Given I have a calculator
    When I multiply <a> and <b>
    Then the result should be <expected>
    Examples:
      | a | b | expected |
      | 2 | 3 | 6        |
      | 4 | 5 | 20       |
```

**Step Definitions**:

```java
package com.example;

import io.cucumber.java.en.When;
import io.cucumber.java.en.Then;
import static org.junit.jupiter.api.Assertions.assertEquals;

public class CalculatorSteps {
    private Calculator calculator;
    private int result;

    @Given("I have a calculator")
    public void i_have_a_calculator() {
        calculator = new Calculator();
    }

    @When("I subtract {int} from {int}")
    public void i_subtract_from(int a, int b) {
        result = calculator.subtract(b, a);
    }

    @When("I multiply {int} and {int}")
    public void i_multiply_and(int a, int b) {
        result = calculator.multiply(a, b);
    }

    @Then("the result should be {int}")
    public void the_result_should_be(int expected) {
        assertEquals(expected, result);
    }
}

class Calculator {
    int add(int a, int b) { return a + b; }
    int subtract(int a, int b) { return a - b; }
    int multiply(int a, int b) { return a * b; }
}
```

**Key Points**:

- `Scenario Outline` with `Examples` supports data-driven testing.
- Use `{int}`, `{string}`, `{float}`, etc., for parameterized steps.

### Hooks

Hooks (`@Before`, `@After`) run setup/teardown code for scenarios.

**Example: Hooks**

```java
package com.example;

import io.cucumber.java.Before;
import io.cucumber.java.After;

public class Hooks {
    @Before
    public void setup() {
        System.out.println("Setting up scenario");
    }

    @After
    public void teardown() {
        System.out.println("Cleaning up scenario");
    }
}
```

**Output**:

```
Setting up scenario
... (test execution)
Cleaning up scenario
```

### Tags

Tags (`@tag`) filter scenarios for execution.

**Example: Tagged Feature File**

```gherkin
Feature: Calculator
  @Smoke
  Scenario: Add two numbers
    Given I have a calculator
    When I add 2 and 3
    Then the result should be 5

  @Regression
  Scenario: Subtract two numbers
    Given I have a calculator
    When I subtract 5 from 8
    Then the result should be 3
```

**Runner with Tags**:

```java
@RunWith(Cucumber.class)
@CucumberOptions(features = "src/test/resources/features", glue = "com.example", tags = "@Smoke")
public class RunCucumberTest {
}
```

**Key Points**:

- Use `tags = "@Smoke and not @Regression"` for complex filtering.
- Tags help organize tests (e.g., `@Smoke`, `@Regression`).

---

## Phase 3: Advanced Cucumber Features

### Data Tables

Use data tables in Gherkin to pass structured data.

**Example: Data Table**

```gherkin
Feature: User Login
  Scenario: Validate user credentials
    Given the following users exist:
      | username | password |
      | alice    | pass123  |
      | bob      | pass456  |
    When I login with username "alice" and password "pass123"
    Then login should be successful
```

**Step Definitions**:

```java
package com.example;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.When;
import io.cucumber.java.en.Then;
import io.cucumber.datatable.DataTable;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class LoginSteps {
    private Map<String, String> users = new HashMap<>();
    private boolean loginSuccess;

    @Given("the following users exist:")
    public void users_exist(DataTable dataTable) {
        users.putAll(dataTable.asMap());
    }

    @When("I login with username {string} and password {string}")
    public void i_login(String username, String password) {
        loginSuccess = users.get(username).equals(password);
    }

    @Then("login should be successful")
    public void login_should_be_successful() {
        assertTrue(loginSuccess);
    }
}
```

**Key Points**:

- `DataTable` supports `asMap()`, `asList()`, or `asMaps()` for data extraction.
- Ideal for testing multiple inputs.

### Background

Use `Background` to share common steps across scenarios.

**Example: Background**

```gherkin
Feature: Calculator
  Background:
    Given I have a calculator

  Scenario: Add two numbers
    When I add 2 and 3
    Then the result should be 5
```

**Key Points**:

- `Background` runs before each scenario in the feature file.
- Reduces duplication in feature files.

### Custom Parameter Types

Define custom Gherkin parameter types for complex objects.

**Example: Custom Parameter Type**

```java
package com.example;

import io.cucumber.java.ParameterType;

public class CustomTypes {
    @ParameterType("(\\d+),(\\d+)")
    public Point point(String x, String y) {
        return new Point(Integer.parseInt(x), Integer.parseInt(y));
    }
}

class Point {
    int x, y;
    Point(int x, int y) { this.x = x; this.y = y; }
}
```

**Feature File**:

```gherkin
Feature: Geometry
  Scenario: Calculate distance
    Given a point at 3,4
    When I calculate distance from origin
    Then the distance should be 5
```

**Step Definitions**:

```java
package com.example;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.When;
import io.cucumber.java.en.Then;
import static org.junit.jupiter.api.Assertions.assertEquals;

public class GeometrySteps {
    private Point point;
    private double distance;

    @Given("a point at {point}")
    public void a_point_at(Point point) {
        this.point = point;
    }

    @When("I calculate distance from origin")
    public void i_calculate_distance() {
        distance = Math.sqrt(point.x * point.x + point.y * point.y);
    }

    @Then("the distance should be {int}")
    public void the_distance_should_be(int expected) {
        assertEquals(expected, (int) distance);
    }
}
```

---

## Phase 4: Recent Updates (Cucumber-JVM 7.20.1, Dec 2024)

- **Improved JUnit 5 Integration**: Enhanced support for parallel test execution.
- **Performance**: Optimized step matching for large feature sets.
- **GraalVM Support**: Better compatibility with native image builds.
- **New Plugins**: Added JSON report enhancements and cloud reporting integrations.
- **Bug Fixes**: Improved handling of complex data tables and custom parameter types.

**Example: JSON Report Configuration**

```java
@RunWith(Cucumber.class)
@CucumberOptions(
    features = "src/test/resources/features",
    glue = "com.example",
    plugin = {"pretty", "json:target/cucumber-reports.json"}
)
public class RunCucumberTest {
}
```

**Key Points**:

- Use `plugin` for report formats (e.g., `pretty`, `html`, `json`).
- JSON reports are useful for CI/CD pipelines.

---

## Phase 5: Concurrent Testing with Virtual Threads

Use Java 21+ virtual threads for parallel scenario execution.

**Example: Concurrent Cucumber Tests**

```java
package com.example;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class ConcurrentSteps {
    @Given("a task {int}")
    public void a_task(int taskId) {
        System.out.println("Task " + taskId + " started on " + Thread.currentThread().getName());
    }

    @When("I process task {int}")
    public void i_process_task(int taskId) {
        // Simulate work
    }

    @Then("task {int} should complete")
    public void task_should_complete(int taskId) {
        assertTrue(true);
    }
}
```

**Feature File**:

```gherkin
Feature: Concurrent Tasks
  @Concurrent
  Scenario: Process task 1
    Given a task 1
    When I process task 1
    Then task 1 should complete

  @Concurrent
  Scenario: Process task 2
    Given a task 2
    When I process task 2
    Then task 2 should complete
```

**Runner with Parallel Execution**:

```java
package com.example;

import io.cucumber.junit.CucumberOptions;
import io.cucumber.junit.platform.engine.Cucumber;
import org.junit.platform.suite.api.ConfigurationParameter;
import org.junit.platform.suite.api.SelectClasspathResource;
import org.junit.platform.suite.api.Suite;

import static io.cucumber.junit.platform.engine.Constants.EXECUTION_MODE;
import static io.cucumber.junit.platform.engine.Constants.GLUE_PROPERTY_NAME;

@Suite
@SelectClasspathResource("features")
@ConfigurationParameter(key = GLUE_PROPERTY_NAME, value = "com.example")
@ConfigurationParameter(key = EXECUTION_MODE, value = "concurrent")
public class RunCucumberTest {
}
```

**junit-platform.properties (src/test/resources)**:

```properties
cucumber.execution.parallel.enabled=true
cucumber.execution.parallel.config.strategy=fixed
cucumber.execution.parallel.config.fixed.parallelism=4
```

**Output**:

```
Task 1 started on VirtualThread[#1]
Task 2 started on VirtualThread[#2]
```

**Key Points**:

- Use JUnit Platform runner for parallel execution.
- Configure parallelism in `junit-platform.properties`.
- Virtual threads scale I/O-bound scenarios efficiently.

---

## Phase 6: Integration with Other Tools

### REST Assured

Test REST APIs with Cucumber and REST Assured.

**Dependency**:

```xml
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>rest-assured</artifactId>
    <version>5.6.0</version>
    <scope>test</scope>
</dependency>
```

**Feature File**:

```gherkin
Feature: API Testing
  Scenario: Get user details
    Given the API is available
    When I send a GET request to "/users/1"
    Then the response status should be 200
    And the response should contain "id" with value 1
```

**Step Definitions**:

```java
package com.example;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.When;
import io.cucumber.java.en.Then;
import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.equalTo;

public class ApiSteps {
    @Given("the API is available")
    public void api_is_available() {
        baseURI = "https://jsonplaceholder.typicode.com";
    }

    @When("I send a GET request to {string}")
    public void send_get_request(String path) {
        given().when().get(path).then().extract().response();
    }

    @Then("the response status should be {int}")
    public void response_status_should_be(int status) {
        given().when().get().then().statusCode(status);
    }

    @Then("the response should contain {string} with value {int}")
    public void response_should_contain(String field, int value) {
        given().when().get().then().body(field, equalTo(value));
    }
}
```

### Spring Boot

Test Spring Boot applications with Cucumber.

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
package com.example;

import io.cucumber.spring.CucumberContextConfiguration;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;

@CucumberContextConfiguration
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class SpringSteps {
    @LocalServerPort
    private int port;

    @Given("the Spring API is running")
    public void spring_api_running() {
        RestAssured.baseURI = "http://localhost:" + port;
    }
}
```

**Feature File**:

```gherkin
Feature: Spring API
  Scenario: Test hello endpoint
    Given the Spring API is running
    When I send a GET request to "/api/hello"
    Then the response status should be 200
```

---

## Java Features Up to Java 25 for Cucumber-JVM

- **Java 8 (2014)**:
    
    - **Lambda Expressions**: Simplify step definitions.
        
        ```java
        @When("I add {int} and {int}")
        public void i_add(int a, int b) -> calculator.add(a, b);
        ```
        
    - **Streams**: Process scenario data.
        
        ```java
        dataTable.asList().stream().forEach(System.out::println);
        ```
        
- **Java 9 (2017)**:
    
    - **Module System**: Use `module-info.java` for modular tests.
        
        ```java
        module myapp.tests {
            requires io.cucumber.java;
            requires org.junit.jupiter.api;
        }
        ```
        
- **Java 10 (2018)**:
    
    - **var**: Cleaner step definitions.
        
        ```java
        var calculator = new Calculator();
        ```
        
- **Java 14 (2020)**:
    
    - **Records**: Use for test data.
        
        ```java
        record User(String username, String password) {}
        @Given("user {user}")
        public void user_exists(User user) { /* ... */ }
        ```
        
- **Java 15 (2020)**:
    
    - **Text Blocks**: Simplify Gherkin-like strings in tests.
        
        ```java
        String feature = """
            Feature: Test
              Scenario: Example
                Given a step
            """;
        ```
        
- **Java 17 (2021)**:
    
    - **Pattern Matching for `instanceof`**:
        
        ```java
        if (data instanceof DataTable table) {
            table.asMap();
        }
        ```
        
- **Java 21 (2023)**:
    
    - **Virtual Threads**: Concurrent scenario execution (shown above).
    - **Structured Concurrency (Preview)**: Manage parallel scenarios.
        
        ```java
        import java.util.concurrent.StructuredTaskScope;
        
        @Before
        public void setup() throws Exception {
            try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
                scope.fork(() -> { /* Setup task */ return null; });
                scope.join().throwIfFailed();
            }
        }
        ```
        
- **Java 25 (2025)**:
    
    - **Implicit Classes**: Simplify step utilities.
        
        ```java
        implicit class CucumberUtils {
            static void assertResult(int actual, int expected) {
                Assertions.assertEquals(expected, actual);
            }
        }
        ```
        
    - **Flexible Constructor Bodies**: Validate test setups.
        
        ```java
        class TestSetup {
            TestSetup(String featurePath) {
                if (!Files.exists(Paths.get(featurePath))) throw new IllegalArgumentException("Feature file not found");
            }
        }
        ```
        

---

## Best Practices

1. **Write Clear Gherkin**: Use business-readable language in feature files.
2. **Reuse Step Definitions**: Keep steps generic and reusable.
3. **Use Tags**: Organize scenarios with `@Smoke`, `@Regression`, etc.
4. **Leverage Hooks**: Manage setup/teardown for consistent test state.
5. **Generate Reports**: Use `plugin` for HTML/JSON reports in CI/CD.
6. **Test with JUnit**: Integrate with JUnit 5 for robust test execution.

**Related Library: Cucumber Reports**  
Generate detailed HTML reports:

```java
@CucumberOptions(
    features = "src/test/resources/features",
    glue = "com.example",
    plugin = {"pretty", "html:target/cucumber-reports.html"}
)
```

---

## Real-World Applications

- **BDD Collaboration**: Align business and technical teams with Gherkin.
- **API Testing**: Test REST APIs with REST Assured and Cucumber.
- **Integration Testing**: Validate Spring Boot or microservices.
- **Regression Testing**: Automate acceptance tests in CI/CD pipelines.

---

## Conclusion

Cucumber-JVM enables BDD by combining human-readable Gherkin specifications with Java automation. Start with simple feature files and step definitions, use tags and hooks for flexibility, and integrate with REST Assured or Spring for advanced testing. Recent updates (Cucumber-JVM 7.20.1) improve JUnit 5 integration and performance. Java 25 features like virtual threads and implicit classes enhance scalability and simplicity for Cucumber tests.

**Resources**:

- [Cucumber-JVM Documentation](https://cucumber.io/docs/cucumber/)
- [Cucumber-JVM GitHub](https://github.com/cucumber/cucumber-jvm)
- [Spring Boot Cucumber Guide](https://spring.io/guides/gs/testing-web/)



##### *Tags : [[Java]]