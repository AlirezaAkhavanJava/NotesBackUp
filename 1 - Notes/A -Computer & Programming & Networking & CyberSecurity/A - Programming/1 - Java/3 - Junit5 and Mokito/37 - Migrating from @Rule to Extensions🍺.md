
## 1. Introduction

### What Changed?
- **JUnit 4**: Used `@Rule` for test enhancements
- **JUnit 5**: Uses **extension model** with `@ExtendWith` and built-in annotations
- **Status**: `@Rule` is deprecated in JUnit 5+

### Dependencies
```xml
<!-- JUnit 5 -->
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <version>5.10.0</version>
    <scope>test</scope>
</dependency>

<!-- If you need JUnit 4 compatibility -->
<dependency>
    <groupId>org.junit.vintage</groupId>
    <artifactId>junit-vintage-engine</artifactId>
    <version>5.10.0</version>
    <scope>test</scope>
</dependency>
```

## 2. Temporary Files/Directories

### JUnit 4 (Old Way)
```java
import org.junit.Rule;
import org.junit.rules.TemporaryFolder;

public class JUnit4TempTest {
    @Rule
    public TemporaryFolder tempFolder = new TemporaryFolder();
    
    @Test
    public void testWithTempFile() throws IOException {
        File file = tempFolder.newFile("test.txt");
        File folder = tempFolder.newFolder("subfolder");
        // test logic
    }
}
```

### JUnit 5 (New Way)
```java
import org.junit.jupiter.api.io.TempDir;
import java.nio.file.Path;
import java.io.File;

public class JUnit5TempTest {
    
    // Method parameter injection
    @Test
    void testWithTempPath(@TempDir Path tempDir) throws IOException {
        Path file = tempDir.resolve("test.txt");
        Path subfolder = tempDir.resolve("subfolder");
        Files.createDirectories(subfolder);
        
        Files.write(file, "Hello World".getBytes());
        assertTrue(Files.exists(file));
    }
    
    // Field injection - fresh for each test
    @TempDir
    Path instanceTempDir;
    
    @Test
    void testWithInstanceTempDir() {
        Path file = instanceTempDir.resolve("instance.txt");
        // Use the file
    }
    
    // Field injection - shared across tests
    @TempDir
    static Path sharedTempDir;
    
    @Test
    void testWithSharedTempDir1() {
        Path file = sharedTempDir.resolve("shared1.txt");
    }
    
    @Test
    void testWithSharedTempDir2() {
        Path file = sharedTempDir.resolve("shared2.txt");
    }
    
    // Using legacy File API
    @Test
    void testWithTempFile(@TempDir File tempFile) {
        File testFile = new File(tempFile, "test.txt");
        // Use File API
    }
}
```

## 3. Exception Testing

### JUnit 4 (Old Way)
```java
public class JUnit4ExceptionTest {
    @Rule
    public ExpectedException exception = ExpectedException.none();
    
    @Test
    public void testException() {
        exception.expect(RuntimeException.class);
        exception.expectMessage("Error occurred");
        throw new RuntimeException("Error occurred");
    }
    
    @Test
    public void testExceptionWithCause() {
        exception.expect(IllegalStateException.class);
        exception.expectCause(instanceOf(IOException.class));
        throw new IllegalStateException("Wrapper", new IOException("Root cause"));
    }
}
```

### JUnit 5 (New Way)
```java
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;

public class JUnit5ExceptionTest {
    
    @Test
    void testException() {
        Exception exception = assertThrows(RuntimeException.class, () -> {
            throw new RuntimeException("Error occurred");
        });
        assertEquals("Error occurred", exception.getMessage());
    }
    
    @Test
    void testExceptionWithCause() {
        IllegalStateException exception = assertThrows(IllegalStateException.class, () -> {
            throw new IllegalStateException("Wrapper", new IOException("Root cause"));
        });
        
        assertEquals("Wrapper", exception.getMessage());
        assertInstanceOf(IOException.class, exception.getCause());
        assertEquals("Root cause", exception.getCause().getMessage());
    }
    
    @Test
    void testExceptionWithDetailedAssertions() {
        RuntimeException thrown = assertThrows(RuntimeException.class, () -> {
            throw new RuntimeException("Specific error message");
        });
        
        // Multiple assertions on the exception
        assertAll("Exception details",
            () -> assertEquals("Specific error message", thrown.getMessage()),
            () -> assertNull(thrown.getCause()),
            () -> assertTrue(thrown.getMessage().contains("error"))
        );
    }
}
```

## 4. Timeout Testing

### JUnit 4 (Old Way)
```java
public class JUnit4TimeoutTest {
    @Rule
    public Timeout globalTimeout = Timeout.seconds(5);
    
    @Test
    public void testWithTimeout() throws InterruptedException {
        Thread.sleep(4000); // OK
        // Thread.sleep(6000); // Would fail
    }
    
    @Test(timeout = 2000)
    public void testWithMethodTimeout() throws InterruptedException {
        Thread.sleep(1000); // OK
    }
}
```

### JUnit 5 (New Way)
```java
public class JUnit5TimeoutTest {
    
    @Test
    @Timeout(5) // 5 seconds
    void testWithTimeout() throws InterruptedException {
        Thread.sleep(4000); // OK
    }
    
    @Test
    @Timeout(value = 500, unit = TimeUnit.MILLISECONDS)
    void testWithMilliseconds() throws InterruptedException {
        Thread.sleep(300); // OK
    }
    
    @Test
    @Timeout(2)
    void timeoutExceeded() {
        // The following assertion fails with an error message similar to:
        // execution exceeded timeout of 2000 ms by 42 ms
        assertTimeoutPreemptively(ofSeconds(2), () -> {
            // Simulate task that takes more than 2 seconds
            Thread.sleep(2500);
        });
    }
    
    @Test
    void assertTimeoutExample() {
        // Doesn't abort test if timeout exceeded (runs in same thread)
        String result = assertTimeout(Duration.ofSeconds(1), () -> {
            return "result after some computation";
        });
        assertEquals("result after some computation", result);
    }
}
```

## 5. Conditional Test Execution

### JUnit 5 Only (No direct @Rule equivalent)
```java
public class ConditionalTest {
    
    @Test
    @EnabledOnOs({OS.LINUX, OS.MAC})
    void onLinuxOrMac() {
        // Only runs on Linux or Mac
    }
    
    @Test
    @DisabledOnOs(OS.WINDOWS)
    void notOnWindows() {
        // Won't run on Windows
    }
    
    @Test
    @EnabledOnJre({JRE.JAVA_11, JRE.JAVA_17})
    void onJava11Or17() {
        // Only on Java 11 or 17
    }
    
    @Test
    @DisabledOnJre(JRE.JAVA_8)
    void notOnJava8() {
        // Won't run on Java 8
    }
    
    @Test
    @EnabledIfSystemProperty(named = "os.arch", matches = ".*64.*")
    void onlyOn64BitArch() {
        // Only on 64-bit architecture
    }
    
    @Test
    @EnabledIfEnvironmentVariable(named = "CI", matches = "true")
    void onlyOnCI() {
        // Only when CI environment variable is "true"
    }
    
    @Test
    @EnabledIf("customCondition")
    void onlyIfCustomCondition() {
        // Only runs if customCondition returns true
    }
    
    boolean customCondition() {
        return someCustomLogic();
    }
}
```

## 6. Test Ordering

### JUnit 5 Only
```java
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class OrderedTest {
    
    @Test
    @Order(1)
    void firstTest() {
        System.out.println("First test");
    }
    
    @Test
    @Order(3)
    void thirdTest() {
        System.out.println("Third test");
    }
    
    @Test
    @Order(2)
    void secondTest() {
        System.out.println("Second test");
    }
}

@TestMethodOrder(MethodOrderer.Random.class)
class RandomOrderTest {
    // Tests will run in random order
}

@TestMethodOrder(MethodOrderer.MethodName.class)
class MethodNameOrderTest {
    // Tests ordered by method name
}
```

## 7. Parameterized Tests

### JUnit 5 Only
```java
public class ParameterizedTestExample {
    
    @ParameterizedTest
    @ValueSource(strings = {"racecar", "radar", "able was I ere I saw elba"})
    void palindromes(String candidate) {
        assertTrue(StringUtils.isPalindrome(candidate));
    }
    
    @ParameterizedTest
    @CsvSource({
        "1, John, true",
        "2, Jane, false", 
        "3, Bob, true"
    })
    void testWithCsv(int id, String name, boolean active) {
        User user = new User(id, name, active);
        assertEquals(active, user.isActive());
    }
    
    @ParameterizedTest
    @CsvFileSource(resources = "/test-data.csv")
    void testWithCsvFile(int id, String name) {
        assertNotNull(name);
    }
    
    @ParameterizedTest
    @MethodSource("stringProvider")
    void testWithMethodSource(String argument) {
        assertNotNull(argument);
    }
    
    static Stream<String> stringProvider() {
        return Stream.of("apple", "banana", "orange");
    }
}
```

## 8. Custom Extensions

### Creating Custom Extensions
```java
// Custom extension for logging
public class LoggingExtension implements 
    BeforeAllCallback, AfterAllCallback,
    BeforeEachCallback, AfterEachCallback,
    BeforeTestExecutionCallback, AfterTestExecutionCallback {
    
    @Override
    public void beforeAll(ExtensionContext context) {
        System.out.println("Before all tests in: " + context.getDisplayName());
    }
    
    @Override
    public void afterAll(ExtensionContext context) {
        System.out.println("After all tests in: " + context.getDisplayName());
    }
    
    @Override
    public void beforeEach(ExtensionContext context) {
        System.out.println("Before test: " + context.getDisplayName());
    }
    
    @Override
    public void afterEach(ExtensionContext context) {
        System.out.println("After test: " + context.getDisplayName());
    }
    
    @Override
    public void beforeTestExecution(ExtensionContext context) {
        System.out.println("Immediately before test: " + context.getDisplayName());
    }
    
    @Override
    public void afterTestExecution(ExtensionContext context) {
        System.out.println("Immediately after test: " + context.getDisplayName());
    }
}

// Custom extension for resource management
public class DatabaseExtension implements BeforeEachCallback, AfterEachCallback {
    
    @Override
    public void beforeEach(ExtensionContext context) {
        System.out.println("Setting up test database");
        // Initialize test database
    }
    
    @Override
    public void afterEach(ExtensionContext context) {
        System.out.println("Tearing down test database");
        // Clean up test database
    }
}
```

### Using Custom Extensions
```java
@ExtendWith({LoggingExtension.class, DatabaseExtension.class})
public class CustomExtensionTest {
    
    @Test
    void testWithCustomExtensions() {
        System.out.println("Running actual test");
        assertTrue(true);
    }
}
```

## 9. Migration Strategy

### Step 1: Update Dependencies
Replace JUnit 4 with JUnit 5 in your build configuration.

### Step 2: Update Imports
```java
// JUnit 4 imports (remove)
import org.junit.*;
import org.junit.rules.*;

// JUnit 5 imports (add)
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.io.TempDir;
import org.junit.jupiter.params.*;
import org.junit.jupiter.params.provider.*;
```

### Step 3: Convert @Rule Usage

| JUnit 4 Rule | JUnit 5 Equivalent |
|-------------|-------------------|
| `TemporaryFolder` | `@TempDir` |
| `ExpectedException` | `assertThrows()` |
| `Timeout` | `@Timeout` |
| `ExternalResource` | Custom extension |
| `ErrorCollector` | Multiple `assertAll()` calls |
| `Verifier` | Custom extension |

### Step 4: Update Test Methods
- Change `@Test` from `org.junit` to `org.junit.jupiter.api`
- Remove `public` modifier (not required in JUnit 5)
- Update exception testing patterns
- Use new assertion methods

## 10. Complete Migration Example

### Before (JUnit 4)
```java
import org.junit.*;
import org.junit.rules.*;

public class JUnit4Example {
    @Rule
    public TemporaryFolder tempFolder = new TemporaryFolder();
    
    @Rule
    public ExpectedException exception = ExpectedException.none();
    
    @Rule
    public Timeout timeout = Timeout.seconds(10);
    
    @Test
    public void testWithRules() throws IOException {
        File file = tempFolder.newFile("test.txt");
        
        exception.expect(IllegalArgumentException.class);
        someMethodThatThrows();
    }
}
```

### After (JUnit 5)
```java
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.io.TempDir;
import java.nio.file.Path;

class JUnit5Example {
    @TempDir
    Path tempDir;
    
    @Test
    @Timeout(10)
    void testWithExtensions() {
        Path file = tempDir.resolve("test.txt");
        
        assertThrows(IllegalArgumentException.class, 
            () -> someMethodThatThrows());
    }
}
```

## Key Benefits of JUnit 5 Extensions

1. **Declarative**: Clear intent through annotations
2. **Composable**: Mix and match multiple extensions
3. **Type-safe**: Better compiler support
4. **Flexible**: Easy to create custom behavior
5. **Modern**: Designed for Java 8+ features
6. **Powerful**: More capabilities than @Rule system

This comprehensive tutorial should help you successfully migrate from JUnit 4's `@Rule` system to JUnit 5's extension model!



##### Tags  : [[1 - Junit 5 🥭]]