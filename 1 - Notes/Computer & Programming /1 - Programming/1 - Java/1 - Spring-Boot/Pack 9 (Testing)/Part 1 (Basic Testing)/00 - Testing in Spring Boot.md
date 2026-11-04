# Testing in Spring Boot: Proving Your Code Works Without Clicking Through It by Hand

## What testing is

A test is a small piece of code whose only job is to run your real code and check that it behaves the way you expect. You write it once, and from then on you can re-run it in seconds, automatically, every time you change something.

In Spring Boot, "testing" also means something more specific. Spring gives you tools to test a piece of your application without starting everything, so you can test just the controller, just the repository, or the whole app, depending on what you want to prove.

## The mental model: a smoke detector, not a fire inspection

Think of your tests as smoke detectors installed in every room of a house. You don't check each room yourself every night. The detector watches, and if something breaks (say you change the validation rule on `username` and accidentally break registration), the detector goes off and tells you which room.

The analogy breaks down in one place: a smoke detector only detects fires it was built for. A test only catches the mistakes you thought to write a test for. Tests give you confidence, not a guarantee.

## Why testing exists and what it solves

- **Fear of changing code.** Without tests, every edit might break something far away and you wouldn't know until a user complains. With tests, you refactor boldly.
- **Manual checking doesn't scale.** Opening Postman and sending 20 requests after every change gets old after the second day.
- **Tests document behavior.** `create_withBlankName_returns400` tells the next person (or you in six months) exactly what the app promises.
- **Bugs are cheaper when found early.** A failing test on your laptop costs a minute. The same bug in production costs a lot more.

## What you get out of the box

When you create a project from Spring Initializr, you get this dependency automatically:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
```

It bundles the tools you'll use constantly:

- **JUnit 5 (Jupiter):** the framework that finds and runs your `@Test` methods.
- **Mockito:** creates fake ("mock") versions of dependencies, so you can test one class in isolation.
- **AssertJ:** readable assertions like `assertThat(x).isEqualTo(y)`.
- **Spring Test / MockMvc:** lets you send fake HTTP requests to your controllers without a real server.
- **JsonPath, JSONassert, Hamcrest:** helpers for checking JSON responses.

## How many types are there?

There's no official count. People usually describe **three main levels**, and a few extras that sit alongside them. Here they are, from smallest to biggest.

### 1. Unit tests: no Spring at all

A unit test checks **one class** alone. Its dependencies are replaced with mocks. Spring doesn't start, so it runs in milliseconds.

```java
@ExtendWith(MockitoExtension.class)
class StudentServiceTest {

    @Mock
    private StudentRepository repository;

    @InjectMocks
    private StudentService service;

    @Test
    void getById_whenStudentMissing_throwsNotFound() {
        when(repository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getById(99L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("99");
    }
}
```

Line by line:

- `@ExtendWith(MockitoExtension.class)` tells JUnit to let Mockito set up the annotated fields. No Spring context is involved.
- `@Mock` creates a fake `StudentRepository`. It has no database behind it; it only does what you tell it to.
- `@InjectMocks` creates a real `StudentService` and hands it the fake repository through its constructor.
- `when(repository.findById(99L)).thenReturn(Optional.empty())` is a script for the fake: "if someone asks for student 99, say nothing was found."
- `assertThatThrownBy(...)` runs the service method and checks that it threw the exception you expect, with a message containing `99`.

The "why": this test proves your **business logic** is right, and it fails only if that logic is wrong. It can't fail because of a database or JSON problem.

### 2. Slice tests: just one layer of Spring

A slice test starts a **small part** of Spring, only the beans one layer needs. This is where Spring Boot's testing shines.

The common ones:

|Annotation|Tests|What it loads|
|---|---|---|
|`@WebMvcTest`|controllers, validation, your exception handler|MVC layer only, no services or repositories|
|`@DataJpaTest`|repositories and entities|JPA, with a test database|
|`@JsonTest`|JSON serialization of your classes|Jackson only|
|`@RestClientTest`|code that calls other APIs|the REST client pieces|
|`@DataMongoTest`|MongoDB repositories|Mongo layer only|

Here's `@WebMvcTest` against the validation handler you've been building:

```java
@WebMvcTest(StudentController.class)
class StudentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private StudentService studentService;

    @Test
    void create_withBlankName_returns400() throws Exception {
        mockMvc.perform(post("/students")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "name": "", "age": -3 }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.name").value("must not be blank"));
    }
}
```

Line by line:

- `@WebMvcTest(StudentController.class)` starts only the web layer for that controller. Your `@RestControllerAdvice` class is picked up automatically, which is exactly why you can test your exception handler here.
- `MockMvc` is a fake HTTP client. It sends the request straight into Spring's `DispatcherServlet` with no real server or port.
- `@MockitoBean` puts a fake `StudentService` into the Spring context, because the controller needs one and `@WebMvcTest` doesn't load your real services. (In older Boot versions this was `@MockBean`; newer versions replaced it, so use whichever your Boot version supports.)
- `post("/students")...content(...)` builds the request: method, path, header, and a JSON body that breaks your rules.
- `status().isBadRequest()` checks for a 400, and `jsonPath("$.name")` reaches into the response JSON and checks the message for that field.

The "why": you've proven validation and error formatting work end to end through Spring MVC, without a database. Notice you never needed to write a `try/catch`, since this is how you verify that your handler really catches things.

And `@DataJpaTest` for a repository:

```java
@DataJpaTest
class StudentRepositoryTest {

    @Autowired
    private StudentRepository repository;

    @Test
    void findByUsername_returnsSavedStudent() {
        repository.save(new Student("alice_99"));

        Optional<Student> found = repository.findByUsername("alice_99");

        assertThat(found).isPresent();
    }
}
```

- `@DataJpaTest` loads only JPA stuff and, by default, swaps your real database for an in-memory one. Each test also rolls back afterward, so tests don't pollute each other.
- The test saves a row, queries it back through your derived query method, and asserts it's there. This checks that your query method name and entity mapping actually work, which a mock could never tell you.

The catch: an in-memory database isn't PostgreSQL. SQL differences can hide bugs. That's what Testcontainers (below) solves.

### 3. Integration tests: the whole application

`@SpringBootTest` starts the **full application context**: controllers, services, repositories, everything wired together, just like in real life.

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class StudentApiIntegrationTest {

    @Autowired
    private TestRestTemplate rest;

    @Test
    void createStudent_thenFetchIt() {
        var request = new StudentRequest("alice_99", 20);

        ResponseEntity<Void> created = rest.postForEntity("/students", request, Void.class);
        assertThat(created.getStatusCode()).isEqualTo(HttpStatus.CREATED);
    }
}
```

- `@SpringBootTest` loads everything.
- `RANDOM_PORT` starts a real embedded server on a free port, so there are no conflicts with other tests or your running app.
- `TestRestTemplate` is an HTTP client already pointed at that port, so `"/students"` just works.
- The test goes through real controller, real service, real repository, real database.

The "why": this finds the bugs that live **between** layers, such as a wrong mapping or a missing bean. The cost is speed. Starting the whole app takes seconds, so you write fewer of these.

## The extras around those three

- **Testcontainers:** starts a real PostgreSQL or MongoDB in Docker for your test. Since you're learning PostgreSQL, this is the "right" way to test repositories against the real thing. Spring Boot supports it directly through `@ServiceConnection`. It needs Docker running on your Debian machine.
- **Security tests:** `spring-security-test` gives you `@WithMockUser` so you can test protected endpoints without real logins.
- **Contract tests (Spring Cloud Contract, Pact):** verify that a backend and its clients agree on the API shape. This matters later for your Angular and Android clients.
- **End-to-end (E2E) tests:** drive a real browser (Selenium, Playwright, Cypress) against the running system. This is outside Spring itself.
- **Performance and load tests:** tools like JMeter or Gatling. Also outside Spring.

## The testing pyramid: how many of each?

The common guideline is a pyramid:

- **Many** unit tests, because they're fast and precise.
- **A moderate number** of slice tests.
- **Few** `@SpringBootTest` tests, because they're slow, and they only need to cover the important flows.

The analogy to a pyramid is just a guideline. Some teams, especially those with thin business logic, deliberately write more integration tests, because that's where their bugs actually live.

## Edge cases and gotchas

- **Naming matters for build tools.** Maven's Surefire plugin runs `*Test` by default, and the Failsafe plugin runs `*IT` for integration tests. Name things consistently or tests won't run.
- **`@SpringBootTest` is not "better" than `@WebMvcTest`.** Beginners often reach for it for everything and end up with a suite that takes minutes. Use the smallest tool that proves what you care about.
- **Spring caches contexts.** Tests with the same configuration reuse one started context, which is why adding a `@MockitoBean` to one test class can make the suite slower: it forces a new context.
- **Don't test the framework.** A test that only checks `repository.save()` returns what you saved, with no custom logic involved, proves nothing about your code.
- **Run them from the terminal:** `./mvnw test` (Maven) or `./gradlew test` (Gradle).
- **Boot versions move things around.** Package names of the test annotations and the mocking annotations changed across recent Boot versions, so if an import won't resolve, check your version's documentation first.






[[Spring Framework]]
[[Testing]]