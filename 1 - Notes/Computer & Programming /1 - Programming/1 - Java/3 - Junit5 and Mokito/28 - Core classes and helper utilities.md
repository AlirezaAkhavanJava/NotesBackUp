

# 🧩 1️⃣ **JUnit 5 (Jupiter)**

**Package:** `org.junit.jupiter.*`

### ✅ Core Annotations

|Annotation|Purpose|
|---|---|
|`@Test`|Marks a test method|
|`@BeforeEach`|Runs before each test|
|`@AfterEach`|Runs after each test|
|`@BeforeAll`|Runs once before all tests|
|`@AfterAll`|Runs once after all tests|
|`@DisplayName`|Custom test name (readable output)|
|`@Disabled`|Temporarily skip a test|
|`@Nested`|Groups tests in inner classes|
|`@Tag`|Marks tests with tags for selective execution|
|`@ParameterizedTest`|Runs test with multiple inputs|
|`@ValueSource`, `@CsvSource`, `@MethodSource`|Provide parameters for parameterized tests|

---

### ✅ Core Assertion Classes

|Class|Description|
|---|---|
|`org.junit.jupiter.api.Assertions`|Basic assertions (e.g., `assertEquals`, `assertTrue`, etc.)|
|`org.junit.jupiter.api.Assumptions`|Conditional test execution (`assumeTrue`, etc.)|
|`org.junit.jupiter.api.TestInstance`|Controls test instance lifecycle|
|`org.junit.jupiter.api.TestReporter`|Used for logging/reporting extra info|

---

### ✅ Common Assertion Methods

|Method|Description|
|---|---|
|`assertEquals(expected, actual)`|Equality|
|`assertTrue(condition)`|Must be true|
|`assertFalse(condition)`|Must be false|
|`assertNull(value)` / `assertNotNull(value)`|Null checks|
|`assertThrows(Exception.class, code)`|Expect exception|
|`fail(message)`|Force fail|

---

# 🧩 2️⃣ **Mockito**

**Package:** `org.mockito.*`

### ✅ Core Classes

|Class / Interface|Description|
|---|---|
|`Mockito`|Static utility for mocks, stubbing, verifying|
|`ArgumentCaptor<T>`|Captures arguments passed to mock methods|
|`InOrder`|Verifies call order between mocks|
|`MockedStatic<T>`|Mocks static methods (try-with-resources)|
|`MockSettings`|Customizes mock creation (name, behavior, etc.)|
|`Answers`|Predefined behaviors (e.g., RETURNS_DEFAULTS, RETURNS_SMART_NULLS)|

---

### ✅ Core Annotations

|Annotation|Purpose|
|---|---|
|`@Mock`|Declares a mock object|
|`@Spy`|Wraps a real object with partial mocking|
|`@InjectMocks`|Injects mocks into the tested class|
|`@Captor`|Shortcut for creating `ArgumentCaptor`|
|`@ExtendWith(MockitoExtension.class)`|Enables Mockito in JUnit 5 tests|

---

### ✅ Verification Helpers

|Method|Purpose|
|---|---|
|`verify(mock)`|Verifies interaction occurred|
|`verify(mock, times(n))`|Verifies call count|
|`verify(mock, never())`|Ensures no call occurred|
|`verifyNoInteractions(mock)`|Asserts no calls at all|
|`verifyNoMoreInteractions(mock)`|Ensures no unverified calls|
|`inOrder(mock1, mock2)`|Order verification|

---

### ✅ Stubbing Helpers

|Method|Purpose|
|---|---|
|`when(mock.method()).thenReturn(value)`|Define return value|
|`when(mock.method()).thenThrow(exception)`|Throw exception|
|`doReturn(value).when(mock).method()`|Alternative syntax (for voids)|
|`doThrow(exception).when(mock).voidMethod()`|Throw in void method|
|`doAnswer(invocation -> {...})`|Custom behavior|
|`doNothing()`|Explicitly skip void behavior|
|`doCallRealMethod()`|Call real implementation on spy|

---

### ✅ Argument Matching

|Matcher|Description|
|---|---|
|`any()`|Any type|
|`eq(value)`|Exact equality|
|`isNull()` / `notNull()`|Null checks|
|`argThat(predicate)`|Custom matcher|
|`same(object)`|Same instance|

---

# 🧩 3️⃣ **AssertJ**

**Package:** `org.assertj.core.api.*`

### ✅ Core Entry Point

|Class|Description|
|---|---|
|`Assertions`|Main static import (`assertThat(...)`)|

You usually import it like:

```java
import static org.assertj.core.api.Assertions.assertThat;
```

---

### ✅ Core Helper Classes

|Class|Description|
|---|---|
|`AbstractAssert<S, A>`|Base class for creating **custom assertions**|
|`SoftAssertions`|Collects multiple assertion failures without stopping|
|`RecursiveComparisonConfiguration`|Configures deep comparison|
|`InstanceOfAssertFactory`|Helps type-specific assertions|
|`Condition<T>`|Defines reusable conditions (`has()`, `is()`)|
|`ObjectAssert`, `StringAssert`, `ListAssert`, `MapAssert`, etc.|Type-specific assertion implementations|
|`ThrowableAssert`|For exception assertions|
|`AssertionsForClassTypes`|Assertions for specific types|
|`Offset<T>`|Used for floating point comparisons|
|`Tuple`|Helper for collection assertions (like extracting multiple fields)|

---

### ✅ Common Assertion Helpers

|Method|Purpose|
|---|---|
|`assertThat(value)`|Starts an assertion|
|`catchThrowable(() -> {...})`|Catch and assert exception|
|`assertThatThrownBy(() -> {...})`|Fluent exception assertions|
|`usingRecursiveComparison()`|Deep field-by-field comparison|
|`extracting(User::getName)`|Extract and assert specific field|
|`filteredOn(predicate)`|Filter collections before asserting|
|`containsExactly(...)`, `containsAnyOf(...)`|Collection assertions|
|`isEqualToComparingFieldByField(expected)`|Field-level comparison|
|`isInstanceOf(Class)`|Type check|
|`hasMessageContaining(String)`|Exception message check|
|`usingComparator(Comparator)`|Custom comparison logic|

---

# 🧩 4️⃣ **Spring Boot Test Utilities (if you use Spring)**

|Class / Annotation|Purpose|
|---|---|
|`@SpringBootTest`|Loads full Spring context|
|`@DataJpaTest`|For JPA repository layer testing|
|`@WebMvcTest`|For controller testing|
|`@MockBean`|Mocks a Spring bean in context|
|`TestEntityManager`|Simplified JPA test helper|
|`@AutoConfigureMockMvc`|Enables `MockMvc` for HTTP testing|
|`MockMvc`|Simulates HTTP requests|
|`ResultActions`|Holds response from `MockMvc.perform()`|

---

# 🧠 Summary Table

|Category|Framework|Key Classes|
|---|---|---|
|**Assertions**|JUnit|`Assertions`, `Assumptions`|
|**Mocking**|Mockito|`Mockito`, `ArgumentCaptor`, `InOrder`|
|**Fluent Assertions**|AssertJ|`Assertions`, `SoftAssertions`, `Condition`|
|**Integration Testing**|Spring Boot|`@SpringBootTest`, `MockMvc`, `TestEntityManager`|

---

## 🧠 Tip

For **real-world testing**, your test stack typically includes:

```java
import org.junit.jupiter.api.*;              // JUnit core
import static org.assertj.core.api.Assertions.*; // AssertJ fluent asserts
import static org.mockito.Mockito.*;         // Mockito mocks
import org.mockito.ArgumentCaptor;
import org.mockito.junit.jupiter.MockitoExtension;
```

---



##### Tags : [[1 - Junit 5 🥭]]