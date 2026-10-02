Date : 2025-09-04

# TestNG – Complete Guide (Java Testing Framework)

This guide covers **TestNG**, a powerful testing framework in Java, including setup, annotations, assertions, advanced features, and integration with Mockito, Maven, and modern practices.

---

## 1. Introduction

- **TestNG:** Testing framework inspired by JUnit, designed for **unit, integration, and end-to-end testing**.
    
- **Advantages:**
    
    - Flexible test configuration
        
    - Powerful annotations
        
    - Parallel test execution
        
    - Parameterized tests
        
- Supports Java 8–25 features, including Lambdas, Streams, and Modules.
    

---

## 2. Setup

### 2.1 Maven Dependency

```xml
<dependency>
    <groupId>org.testng</groupId>
    <artifactId>testng</artifactId>
    <version>7.9.0</version>
    <scope>test</scope>
</dependency>
```

### 2.2 Gradle Dependency

```gradle
testImplementation 'org.testng:testng:7.9.0'
```

---

## 3. Core Annotations

|Annotation|Description|
|---|---|
|`@Test`|Marks a method as a test case|
|`@BeforeSuite`|Runs once before all tests in the suite|
|`@AfterSuite`|Runs once after all tests in the suite|
|`@BeforeTest`|Runs before any test method in the `<test>` tag of XML|
|`@AfterTest`|Runs after all test methods in the `<test>` tag|
|`@BeforeClass`|Runs before the first method in the current class|
|`@AfterClass`|Runs after all methods in the current class|
|`@BeforeMethod`|Runs before each test method|
|`@AfterMethod`|Runs after each test method|
|`@DataProvider`|Supplies data for parameterized tests|

**Tip:** Understand the **execution order** to manage setup and teardown efficiently.

---

## 4. Assertions

### 4.1 Basic Assertions

```java
import org.testng.Assert;

Assert.assertEquals(actual, expected);
Assert.assertTrue(condition);
Assert.assertFalse(condition);
Assert.assertNotNull(object);
Assert.assertNull(object);
```

### 4.2 Advanced Assertions

- `assertThrows()` for exception testing (Java 8+ style using lambdas)
    
- `assertEqualsNoOrder()` for arrays ignoring order
    

---

## 5. Test Configuration

### 5.1 Grouping Tests

```java
@Test(groups = {"unit", "fast"})
public void testMethod() {}
```

- Run specific groups via XML or CLI.
    

### 5.2 Dependencies

```java
@Test(dependsOnMethods = {"initTest"})
public void mainTest() {}
```

- Ensures a test runs only after dependent methods.
    

### 5.3 Parameterized Tests

```java
@DataProvider(name = "data")
public Object[][] provideData() {
    return new Object[][] {{"A", 1}, {"B", 2}};
}

@Test(dataProvider = "data")
public void testWithData(String s, int n) {}
```

- Supports data-driven testing.
    

---

## 6. Advanced Features

### 6.1 Parallel Execution

- XML configuration or annotations with `parallel="methods"`
    
- Improves test speed, especially in large suites.
    

### 6.2 Retry Logic

- Implement `IRetryAnalyzer` interface to retry failed tests.
    

### 6.3 Listeners

- Implement `ITestListener`, `ISuiteListener` for logging, reporting, or screenshots.
    

### 6.4 Factory Pattern

```java
@Test
@Factory
public Object[] createTests() {
    return new Object[] {new TestClass(param1), new TestClass(param2)};
}
```

- Create multiple test instances dynamically.
    

---

## 7. Integration with Mockito

- Combine TestNG with Mockito for **unit testing with mocks**.
    

```java
import static org.mockito.Mockito.*;

MyService service = mock(MyService.class);
when(service.getData()).thenReturn("Mocked");
Assert.assertEquals(service.getData(), "Mocked");
```

- Use `@BeforeMethod` to initialize mocks.
    
- Supports `@InjectMocks` and `@Mock` annotations.
    

---

## 8. Real-World Best Practices

1. Separate **unit tests, integration tests, and functional tests**.
    
2. Use **DataProvider** for repeatable, parameterized tests.
    
3. Combine **Mockito** for mocks and stubs.
    
4. Implement **listeners** for reporting and CI/CD integration.
    
5. Prefer **parallel execution** for large suites to save time.
    
6. Maintain **clean test structure** using packages and XML suite files.
    

---

## 9. Common Interview Questions

- Difference between JUnit and TestNG
    
- Execution order of TestNG annotations
    
- How to handle dependent tests
    
- How to perform data-driven testing
    
- Parallel execution vs sequential execution
    
- Integration of TestNG with Mockito and Selenium
    

---

## 10. Summary

- TestNG is a **flexible, powerful testing framework** supporting unit, integration, and end-to-end testing.
    
- Core annotations and configuration enable **structured, maintainable tests**.
    
- Supports **parallel execution, parameterization, retry logic, and listeners**.
    
- Integrates seamlessly with **Mockito, Selenium, and modern Java features (Java 8–25)**.
    
- Mastery of TestNG ensures **robust, maintainable, and scalable test suites**.




##### *Tags : [[Java]]