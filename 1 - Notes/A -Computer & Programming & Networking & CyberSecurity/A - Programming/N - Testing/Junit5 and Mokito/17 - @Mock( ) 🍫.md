
The `@Mock` annotation is part of the Mockito framework, which is commonly used with JUnit for creating mock objects in unit tests. Let me explain it in detail.

## What is @Mock?

The `@Mock` annotation creates a mock implementation of a class or interface, allowing you to stub method calls and verify interactions.

## Basic Usage

```java
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import java.util.List;
import static org.mockito.Mockito.*;

// Manual initialization
public class ManualMockTest {
    @Mock
    private List<String> mockedList;
    
    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }
    
    @Test
    void testMock() {
        mockedList.add("test");
        verify(mockedList).add("test");
    }
}
```

## Using with MockitoExtension (Recommended)

```java
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
public class MockitoExtensionTest {
    @Mock
    private List<String> mockedList;
    
    @Test
    void testMock() {
        when(mockedList.size()).thenReturn(10);
        assertEquals(10, mockedList.size());
    }
}
```

## @Mock Annotation Parameters

### 1. `name` / `value`
```java
@Mock(name = "myMock")
private List<String> namedMock;

@Mock("myMock") // shorthand
private List<String> shorthandNamedMock;
```

### 2. `answer` / `extraInterfaces`
```java
import org.mockito.Answers;

// Different answer strategies
@Mock(answer = Answers.RETURNS_DEFAULTS)
private List<String> defaultMock;

@Mock(answer = Answers.RETURNS_SMART_NULLS)
private List<String> smartNullsMock;

@Mock(answer = Answers.RETURNS_DEEP_STUBS)
private Service deepStubMock;

@Mock(answer = Answers.CALLS_REAL_METHODS)
private ConcreteClass realMethodMock;

// Multiple interfaces
@Mock(extraInterfaces = {Runnable.class, Serializable.class})
private List<String> multiInterfaceMock;
```

## Common Answer Strategies

### RETURNS_DEFAULTS
```java
@Mock(answer = Answers.RETURNS_DEFAULTS)
private List<String> mockList;

@Test
void testReturnsDefaults() {
    // Returns null for objects, 0 for numbers, false for boolean
    assertNull(mockList.get(0));
}
```

### RETURNS_SMART_NULLS
```java
@Mock(answer = Answers.RETURNS_SMART_NULLS)
private Service mockService;

@Test
void testSmartNulls() {
    // Returns SmartNull instead of regular null
    String result = mockService.process();
    // Better error messages when SmartNull is used
}
```

### RETURNS_DEEP_STUBS
```java
class OrderService {
    Order getOrder() { return new Order(); }
}

class Order {
    Customer getCustomer() { return new Customer(); }
}

class Customer {
    String getName() { return "John"; }
}

@Mock(answer = Answers.RETURNS_DEEP_STUBS)
private OrderService orderService;

@Test
void testDeepStubs() {
    // Chain of method calls without individual mocking
    when(orderService.getOrder().getCustomer().getName()).thenReturn("Jane");
    assertEquals("Jane", orderService.getOrder().getCustomer().getName());
}
```

### CALLS_REAL_METHODS
```java
class Calculator {
    public int add(int a, int b) {
        return a + b;
    }
}

@Mock(answer = Answers.CALLS_REAL_METHODS)
private Calculator calculator;

@Test
void testRealMethods() {
    // Actually calls the real method
    assertEquals(5, calculator.add(2, 3));
}
```

## Advanced Usage Examples

### 1. Mock with Custom Settings
```java
@ExtendWith(MockitoExtension.class)
class AdvancedMockTest {
    
    @Mock(lenient = true)
    private Service lenientMock;
    
    @Mock(strictness = Mock.Strictness.LENIENT)
    private Service anotherLenientMock;
    
    @Test
    void testLenientMock() {
        // Unused stubs won't cause failures
        when(lenientMock.unusedMethod()).thenReturn("value");
        // Test other methods...
    }
}
```

### 2. Multiple Mocks with Different Configurations
```java
@ExtendWith(MockitoExtension.class)
class MultipleMocksTest {
    
    @Mock
    private List<String> defaultList;
    
    @Mock(answer = Answers.RETURNS_SMART_NULLS)
    private Service smartService;
    
    @Mock(answer = Answers.RETURNS_DEEP_STUBS)
    private ComplexService deepStubService;
    
    @Test
    void testMultipleMocks() {
        when(defaultList.size()).thenReturn(5);
        assertEquals(5, defaultList.size());
        
        // Smart nulls provide better error messages
        String result = smartService.process();
        
        // Deep stubs allow chaining
        String name = deepStubService.getOrder().getCustomer().getName();
    }
}
```

### 3. Mock with Verification
```java
@ExtendWith(MockitoExtension.class)
class VerificationTest {
    
    @Mock
    private UserRepository userRepository;
    
    @Mock
    private EmailService emailService;
    
    @Test
    void testUserRegistration() {
        User user = new User("john@example.com");
        
        when(userRepository.save(user)).thenReturn(user);
        
        // Call method under test
        registerUser(user);
        
        verify(userRepository).save(user);
        verify(emailService).sendWelcomeEmail(user.getEmail());
        verifyNoMoreInteractions(emailService);
    }
    
    private void registerUser(User user) {
        userRepository.save(user);
        emailService.sendWelcomeEmail(user.getEmail());
    }
}
```

## Best Practices

1. **Use MockitoExtension** instead of manual initialization
2. **Initialize mocks in setup method** when not using the extension
3. **Use meaningful names** for mocks when you have multiple of the same type
4. **Choose appropriate answer strategies** based on your needs
5. **Avoid overusing deep stubs** as they can hide design issues

## Common Pitfalls

```java
@ExtendWith(MockitoExtension.class)
class PitfallsTest {
    
    @Mock
    private List<String> mockList;
    
    @Test
    void commonMistakes() {
        // Wrong: Forgetting to stub method calls
        // mockList.get(0); // Would return null
        
        // Correct: Stub method calls
        when(mockList.get(0)).thenReturn("expected");
        assertEquals("expected", mockList.get(0));
        
        // Wrong: Verifying without calling
        // verify(mockList).clear(); // Would fail if clear() not called
        
        // Correct: Call then verify
        mockList.clear();
        verify(mockList).clear();
    }
}
```

The `@Mock` annotation is fundamental to Mockito testing and understanding its various parameters and configurations will help you write more effective and maintainable unit tests.




## 🧾 Mockito `@Mock` Cheat Sheet

|**Feature**|**Usage / Example**|**Explanation**|
|---|---|---|
|**Basic mock**|`@Mock UserRepository userRepo;`|Creates a mock object of `UserRepository`.|
|**Enable annotations**|`@ExtendWith(MockitoExtension.class)`|Required in JUnit 5 to activate `@Mock`, `@InjectMocks`, etc.|
|**Manual mock (no annotation)**|`UserRepository repo = mock(UserRepository.class);`|Same as `@Mock`, but created manually.|
|**Custom name**|`@Mock(name = "repoMock") UserRepository repo;`|Gives the mock a readable name (useful in logs).|
|**Custom default answer**|`@Mock(answer = Answers.RETURNS_SMART_NULLS) UserRepository repo;`|Defines default behavior for unstubbed calls.|
|**Deep stubs**|`@Mock(answer = Answers.RETURNS_DEEP_STUBS) UserRepository repo;`|Allows chained calls like `repo.getUser().getName()`.|
|**Smart nulls**|`@Mock(answer = Answers.RETURNS_SMART_NULLS)`|Returns “smart nulls” (helpful errors instead of NPEs).|
|**Real methods**|`@Mock(answer = Answers.CALLS_REAL_METHODS)`|Calls real methods on the class instead of mocking them.|
|**With `@InjectMocks`**|`@InjectMocks UserService service;`|Automatically injects `@Mock` fields into the tested class.|
|**Verify calls**|`verify(repo).findById(1L);`|Checks that a method was called on the mock.|
|**Stub behavior**|`when(repo.findById(1L)).thenReturn(Optional.of(user));`|Defines what the mock should return.|
|**Reset mock**|`reset(repo);`|Clears all stubbings and interactions.|
|**Spy alternative**|`@Spy UserRepository repo;`|Partial mock — real methods called unless stubbed.|
|**Argument matchers**|`when(repo.findById(anyLong())).thenReturn(Optional.of(user));`|Matches method arguments flexibly.|

---

### 🧠 Example setup

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    UserRepository userRepository;

    @InjectMocks
    UserService userService;

    @Test
    void testFindUser() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(new User("Ethan")));
        User result = userService.findUserById(1L);
        assertEquals("Ethan", result.getName());
    }
}
```



##### Tags : [[1 - Junit 5 🥭]]