**Testing** means writing code that automatically checks whether your other code behaves correctly. Instead of running the app and clicking around to see if it works, you write a small program that does it for you, in milliseconds, every time you change something.

**Analogy:** A smoke detector and a safety net for a trapeze artist. You don't test because you expect to fall; you test so that when you change something (and you will, constantly), the net catches you immediately instead of the audience finding out. In the real-projects lesson, testing was item one on the checklist for exactly this reason.

## The core idea: Arrange, Act, Assert

Every test has the same three-part shape:

1. **Arrange:** set up the input and objects.
2. **Act:** call the code you're testing.
3. **Assert:** check that the result is what you expected.

```java
class PriceCalculatorTest {

    @Test
    void appliesTenPercentDiscount() {
        // Arrange
        PriceCalculator calc = new PriceCalculator();

        // Act
        double result = calc.applyDiscount(100.0, 10);

        // Assert
        assertEquals(90.0, result);
    }
}
```

If the code is later changed and returns `91.0`, this test turns red and tells you immediately.

## Why it matters

- **Safety when changing code:** this is called _regression protection_. Without tests, every change is a gamble.
- **Fast feedback:** a test runs in milliseconds; manually checking via Postman or the browser takes minutes.
- **Living documentation:** a test shows exactly how a piece of code is meant to be used.
- **Better design:** code that is hard to test is usually badly structured (too many responsibilities, hidden dependencies). Writing tests pushes you toward the layered design from earlier lessons.

## The testing pyramid

```
        /\
       /E2E\          few, slow, expensive (whole system, real browser)
      /------\
     /Integration\    some, medium (several parts together, real database)
    /------------\
   /  Unit tests  \   many, fast, cheap (one class in isolation)
  /----------------\
```

|Level|What it tests|Speed|Example|
|---|---|---|---|
|**Unit**|One class or method in isolation|Milliseconds|`PriceCalculator`, a service with a fake repository|
|**Integration**|Several parts working together|Seconds|Repository against a real PostgreSQL|
|**End-to-end (E2E)**|The whole system like a user|Slowest|Browser clicks through Angular to Spring Boot to the database|

Many fast unit tests at the base, fewer slow tests as you go up. A pyramid shape keeps your test suite fast and your failures easy to locate.

## The Java testing toolkit

When you create a Spring Boot project, `spring-boot-starter-test` is already in your `pom.xml`. It bundles:

- **JUnit 5:** the test framework (`@Test`, assertions, running tests).
- **Mockito:** creates fake objects ("mocks") for dependencies.
- **AssertJ:** readable, fluent assertions.
- **Spring Test / MockMvc:** test your controllers without starting a real server.
- **Testcontainers** (separate dependency): starts a real database in Docker for integration tests.

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
```

Run them with Maven:

```bash
mvn test
```

This connects to your Maven lesson: `mvn test` is one of the standard lifecycle steps, and `mvn package` runs the tests first and fails the build if any test fails.

## Unit test with a mock (the service layer)

A service depends on a repository. To test the service **alone**, replace the repository with a fake:

```java
@ExtendWith(MockitoExtension.class)
class BookServiceTest {

    @Mock
    BookRepository repository;          // fake, no real database

    @InjectMocks
    BookService service;                // real service, with the fake injected

    @Test
    void returnsBookWhenFound() {
        // Arrange: teach the fake what to answer
        when(repository.findById(5L))
            .thenReturn(Optional.of(new Book(5L, "Clean Code", 2008)));

        // Act
        Book result = service.getBook(5L);

        // Assert
        assertThat(result.getTitle()).isEqualTo("Clean Code");
        verify(repository).findById(5L);   // was the repository really called?
    }

    @Test
    void throwsWhenNotFound() {
        when(repository.findById(99L)).thenReturn(Optional.empty());

        assertThrows(BookNotFoundException.class, () -> service.getBook(99L));
    }
}
```

Mental model: a **mock** is a stunt double. You are testing the actor (the service), so you replace the dangerous or slow co-stars (the database) with doubles that follow a script. This works smoothly because the service takes its repository through the **constructor** (dependency injection, as in the real-projects lesson); that is what makes swapping it for a fake possible.

Notice the second test checks the **unhappy path**. Real projects spend most of their effort there: not found, invalid input, nulls, empty lists.

## Testing the REST layer (controller)

`@WebMvcTest` starts only the web layer, not the whole application:

```java
@WebMvcTest(BookController.class)
class BookControllerTest {

    @Autowired
    MockMvc mockMvc;

    @MockitoBean                         // Spring Boot 3.4+; older versions use @MockBean
    BookService service;

    @Test
    void getBookReturnsJson() throws Exception {
        when(service.getBook(5L)).thenReturn(new Book(5L, "Clean Code", 2008));

        mockMvc.perform(get("/books/5"))
               .andExpect(status().isOk())
               .andExpect(jsonPath("$.title").value("Clean Code"));
    }

    @Test
    void returns404WhenMissing() throws Exception {
        when(service.getBook(99L)).thenThrow(new BookNotFoundException(99L));

        mockMvc.perform(get("/books/99"))
               .andExpect(status().isNotFound());
    }
}
```

This verifies the HTTP part of your REST lesson (URL, method, status code, JSON shape) without opening a real port.

## Integration test with a real database

Unit tests with mocks can't catch a wrong SQL query or a broken mapping. For that, test the repository against a real database:

```java
@DataJpaTest
@Testcontainers
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class BookRepositoryTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

    @Autowired
    BookRepository repository;

    @Test
    void findsBooksByYear() {
        repository.save(new Book(null, "SICP", 1985));
        repository.save(new Book(null, "Clean Code", 2008));

        List<Book> result = repository.findByYearGreaterThan(2000);

        assertThat(result).hasSize(1);
    }
}
```

Testcontainers starts a throwaway PostgreSQL in **Docker** (your previous lesson) for the test, then destroys it. Your test runs against the same database type as production, which an in-memory fake would not guarantee. `@DataJpaTest` also rolls back each test's changes automatically, so tests don't pollute each other.

## Full-stack test

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class BookApiIT { ... }
```

`@SpringBootTest` loads the whole application. It is powerful but slow, so use it sparingly, only for a few critical flows.

## What makes a good test

Remember **F.I.R.S.T.**:

- **Fast:** slow tests don't get run.
- **Isolated:** no test depends on another or on run order.
- **Repeatable:** same result every time, on any machine.
- **Self-validating:** pass or fail, no human reading logs.
- **Timely:** written close to the code (or before it).

## TDD (Test-Driven Development)

A workflow where you write the test **first**:

1. **Red:** write a failing test for a feature that doesn't exist yet.
2. **Green:** write the simplest code that makes it pass.
3. **Refactor:** clean up, with the test protecting you.

You don't have to follow TDD strictly, but trying it for a while builds the habit of thinking about behavior before implementation.

## Gotchas

- **Don't test the framework.** A test that only checks that Spring can save an entity, with no logic of your own, proves nothing. Test _your_ rules.
- **Over-mocking:** a test where everything is mocked ends up verifying that your mocks work, not your code. Mock the boundaries (database, external services), not every collaborator.
- **Testing implementation instead of behavior:** asserting that a private detail was called makes tests break every time you refactor. Assert on outcomes (results, status codes, saved data).
- **Flaky tests:** tests that sometimes pass and sometimes fail (because of time, randomness, shared state, or network) destroy trust in the whole suite. Fix or delete them.
- **100% coverage is not the goal.** Coverage tells you which lines _ran_, not whether anything was _checked_. A test with no assertions still counts toward coverage.
- **Naming:** a good test name describes the behavior (`throwsWhenNotFound`), so a red test explains itself without reading the body.
- **Passing tests do not prove correctness,** only that the cases you thought of work. Edge cases (null, empty, zero, negative, huge, duplicate) are where bugs hide.
- **Test files live in `src/test/java`,** mirroring your `src/main/java` package structure. Maven only runs classes there, and they are not packaged into your final `.jar`.
- **Version differences:** `@MockitoBean` replaced `@MockBean` in newer Spring Boot versions (3.4+), so check which one your version expects, and watch for old tutorials.




[[Computer & Programming]]
[[C]]
[[Java]]
[[Spring Framework]]
[[Python]]