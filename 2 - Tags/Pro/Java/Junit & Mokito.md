**JUnit** is the framework that **finds, runs, and reports** your tests. **Mockito** is the library that creates **fake dependencies** so a class can be tested alone. In the last lesson you saw both in action. Now we look at how each one actually works and the features you'll use most.

**Analogy:** JUnit is the **exam hall**: it hands out the papers, runs the timer, and marks pass or fail. Mockito is the **film set**: it builds stunt doubles and props that follow a script, so the actor (your class) can perform without real danger.

## Part 1: JUnit 5

### What it is made of

JUnit 5 is three pieces, which explains confusing names in old tutorials:

- **Platform:** launches tests (Maven and your IDE talk to this).
- **Jupiter:** the new API you write tests with (`org.junit.jupiter.api`).
- **Vintage:** runs old JUnit 4 tests.

Always import from `org.junit.jupiter`. If you see `org.junit.Test`, that is JUnit 4, an old tutorial.

### Lifecycle: what runs when

```java
class LifecycleTest {

    @BeforeAll   static void once()      { System.out.println("before all"); }   // once, must be static
    @BeforeEach  void setUp()            { System.out.println("before each"); }  // before every test
    @Test        void testA()            { System.out.println("A"); }
    @Test        void testB()            { System.out.println("B"); }
    @AfterEach   void tearDown()         { System.out.println("after each"); }
    @AfterAll    static void finish()    { System.out.println("after all"); }
}
```

Output order: `before all`, then `before each, A, after each`, then `before each, B, after each`, then `after all`.

**Why it works this way:** JUnit creates a **new instance of the test class for every test method**. So a field set in one test is gone in the next. This enforces the _Isolated_ rule of F.I.R.S.T.: tests cannot secretly depend on each other. `@BeforeEach` is where you rebuild fresh objects.

### Assertions

```java
import static org.junit.jupiter.api.Assertions.*;

assertEquals(90.0, result, 0.001);          // doubles need a tolerance
assertTrue(list.isEmpty());
assertNull(value);
assertThrows(IllegalArgumentException.class, () -> service.pay(-5));

// assertAll: runs ALL checks and reports every failure, not just the first
assertAll("book",
    () -> assertEquals("Clean Code", book.getTitle()),
    () -> assertEquals(2008, book.getYear())
);
```

**Argument order matters:** `assertEquals(expected, actual)`. Swapping them still passes or fails correctly, but the failure message becomes misleading ("expected 5 but was 90").

`assertThrows` also _returns_ the exception, so you can check its message:

```java
var ex = assertThrows(BookNotFoundException.class, () -> service.getBook(99L));
assertEquals("Book 99 not found", ex.getMessage());
```

You can use **AssertJ** instead (it came with `spring-boot-starter-test`), which reads like English and gives better failure messages:

```java
assertThat(books).hasSize(2).extracting(Book::getTitle).contains("SICP");
```

### Making tests readable

```java
@DisplayName("BookService")
class BookServiceTest {

    @Nested
    @DisplayName("getBook")
    class GetBook {
        @Test @DisplayName("returns the book when it exists")
        void found() { ... }

        @Test @DisplayName("throws when the id is unknown")
        void notFound() { ... }
    }
}
```

`@Nested` groups tests by feature or situation, so the report reads like documentation.

### Parameterized tests: one test, many inputs

Instead of copy-pasting a test five times:

```java
@ParameterizedTest
@CsvSource({
    "100, 10, 90",
    "200, 50, 100",
    "50,  0,  50"
})
void appliesDiscount(double price, int percent, double expected) {
    assertEquals(expected, new PriceCalculator().applyDiscount(price, percent));
}

@ParameterizedTest
@ValueSource(strings = {"", " ", "   "})
void rejectsBlankTitles(String title) {
    assertThrows(IllegalArgumentException.class, () -> new Book(null, title, 2000));
}
```

This is the best tool for the **edge cases** (empty, zero, negative, huge) from the last lesson. Other sources: `@MethodSource` (a method supplies the data), `@EnumSource`, `@NullAndEmptySource`.

### Other useful annotations

|Annotation|Use|
|---|---|
|`@Disabled("reason")`|Skip a test temporarily (always give a reason)|
|`@Timeout(2)`|Fail if it takes longer than 2 seconds|
|`@Tag("slow")`|Label tests so you can run groups selectively|
|`@TempDir`|Gives you a temporary folder, deleted afterward|
|`@RepeatedTest(5)`|Run the same test several times|

Run from the terminal:

```bash
mvn test                                        # everything
mvn test -Dtest=BookServiceTest                 # one class
mvn test -Dtest=BookServiceTest#notFound        # one method
```

## Part 2: Mockito

### Three kinds of fake objects

|Kind|What it does|Created with|
|---|---|---|
|**Mock**|Fully fake. Every method does nothing and returns a default, until you script it|`@Mock` / `mock(X.class)`|
|**Stub**|Not a separate class: it is a _mock method you gave an answer to_|`when(...).thenReturn(...)`|
|**Spy**|A **real** object, wrapped so you can fake some methods and verify calls|`@Spy` / `spy(obj)`|

**Default answers of an unscripted mock:** `null` for objects, `0` for numbers, `false` for booleans, and **empty** collections and `Optional.empty()`. This explains many "why is it null?" surprises.

### Two jobs: stubbing and verifying

Everything in Mockito is one of these two:

1. **Stubbing:** "when this is called, answer like this" (the _Arrange_ step).
2. **Verifying:** "check this was called" (the _Assert_ step).

```java
// Stubbing
when(repository.findById(5L)).thenReturn(Optional.of(book));
when(repository.findById(99L)).thenReturn(Optional.empty());
when(repository.save(any())).thenThrow(new DataIntegrityViolationException("duplicate"));

// Answer computed from the input (e.g., simulate the DB assigning an id)
when(repository.save(any(Book.class))).thenAnswer(inv -> {
    Book b = inv.getArgument(0);
    b.setId(1L);
    return b;
});

// Verifying
verify(repository).save(book);               // called exactly once
verify(repository, times(2)).findById(5L);
verify(repository, never()).deleteById(any());
verifyNoMoreInteractions(repository);        // nothing else happened
```

### Argument matchers

`any()`, `anyLong()`, `eq(5L)`, `argThat(...)` let you match values loosely.

**The all-or-nothing rule:** if one argument uses a matcher, **all** must.

```java
verify(repository).update(eq(5L), any());     // correct
verify(repository).update(5L, any());         // InvalidUseOfMatchersException
```

### ArgumentCaptor: inspecting what your code passed

When the service builds an object internally, you can't reference it directly. Capture it:

```java
@Captor ArgumentCaptor<Book> captor;

@Test
void createsBookWithTrimmedTitle() {
    service.create(new CreateBookRequest("  Clean Code  ", 2008));

    verify(repository).save(captor.capture());
    assertThat(captor.getValue().getTitle()).isEqualTo("Clean Code");
}
```

This tests the **outcome** (what was saved), which is more robust than testing how it was done.

### Void methods and spies

`when(...)` can't wrap a void method (nothing to return), so use the `do...` family:

```java
doThrow(new RuntimeException("mail down")).when(mailSender).send(any());
doNothing().when(mailSender).send(any());
```

For **spies**, also prefer `doReturn(...).when(spy).method()`. With `when(spy.method())`, the _real_ method actually runs once while you're setting up the stub.

### Readable style: BDD

`BDDMockito` renames the same calls to match Arrange/Act/Assert:

```java
given(repository.findById(5L)).willReturn(Optional.of(book));   // Arrange
Book result = service.getBook(5L);                              // Act
then(repository).should().findById(5L);                         // Assert
```

Same behavior, just words that match the three-part shape.

### A complete example

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock OrderRepository orderRepository;
    @Mock PaymentClient paymentClient;
    @InjectMocks OrderService service;

    @Test
    void doesNotSaveOrderWhenPaymentFails() {
        given(paymentClient.charge(anyDouble())).willReturn(false);

        assertThrows(PaymentFailedException.class,
                     () -> service.placeOrder(new Order(50.0)));

        then(orderRepository).should(never()).save(any());   // the important guarantee
    }
}
```

This is a good mock test: it checks a _business rule_ (no payment, no saved order), and the database and payment gateway are the boundaries being faked.

## How Mockito works (the mental model)

Mockito generates a **subclass or proxy at runtime** that records every call. `when(mock.x())` works by _calling_ `x()` first (the mock records "x was just called"), and then `thenReturn` attaches an answer to that last recorded call. That is why the `when(spy.realMethod())` problem above exists, and why matchers must be all-or-nothing: they are queued up in a hidden list, and mixing raw values breaks the count.

`@ExtendWith(MockitoExtension.class)` is the JUnit-Mockito bridge: JUnit calls it before each test, and it creates the `@Mock`s and injects them. Without that line, your `@Mock` fields stay `null` and you get a `NullPointerException`.

## Gotchas

- **`UnnecessaryStubbingException`:** with `MockitoExtension`, strict mode fails a test if you script an answer that is never used. It looks annoying, but it is catching dead setup code. Remove the unused stub.
- **Mocking what you don't own:** don't mock `String`, `List`, or simple data objects. Use real ones. Mock only boundaries (repositories, HTTP clients, mail senders, clocks).
- **Mocking the class under test:** never `@Mock` the thing you are testing. `@InjectMocks` creates the real one.
- **`@InjectMocks` is quiet when it fails:** it tries constructor, then setter, then field injection, and silently leaves things `null` if types don't match. Constructor injection (your real-projects habit) makes it reliable, and you can also just write `new BookService(repository)` yourself.
- **Over-verifying:** `verifyNoMoreInteractions` and many `verify` calls make tests break whenever you refactor, even if behavior is unchanged. Verify only the interactions that matter.
- **`@Mock` vs `@MockitoBean`:** `@Mock` is plain Mockito, used in fast unit tests with no Spring. `@MockitoBean` puts a mock into a **Spring context** (for `@WebMvcTest`). Don't mix them up.
- **Final classes, static methods:** Mockito 5 (included in Spring Boot 3) can mock final classes by default. Static methods need `mockStatic`, which is usually a sign to redesign instead (for example, inject a `Clock` instead of calling `LocalDate.now()`).
- **Time and randomness:** inject a `Clock` or a random source so you can control them, otherwise your tests become _flaky_.
- **Don't mock to avoid learning:** if a repository query is the thing at risk, a mock proves nothing about it. Use the Testcontainers integration test from the last lesson.





[[Testing]]
[[Java]]
[[Spring Framework]]
[[Data-base]]