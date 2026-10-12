
# Mocking in Spring Boot Tests

Mocking in Spring Boot comes down to one question: **do I need Spring in this test at all?** The answer decides which mocking tool you use, and mixing them up is the most common source of confusion.

## What mocking is for

A **mock** is a fake object that stands in for a real collaborator. You control what it returns and can check how it was used. We use mocks to cut a unit off from things that are slow (databases, networks), unpredictable (clocks, random values, third-party APIs), or irrelevant to what you're testing.

## Two worlds: Mockito alone vs. Spring-managed mocks

**World 1: plain Mockito (no Spring).** `@Mock` and `@InjectMocks`, with no application context. This is what we used for `UserServiceTest`:

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    UserRepository repository;

    @InjectMocks
    UserService service;   // Mockito builds it and injects the mock

    @Test
    void rejectsDuplicateEmail() {
        given(repository.existsByEmail("ana@example.com")).willReturn(true);

        assertThrows(EmailAlreadyUsedException.class,
                () -> service.register("Ana", "ana@example.com"));
    }
}
```

This is the fastest option, since no Spring context is created. Use it whenever the class under test can be built with `new` and constructor injection, which is one reason constructor injection is so popular.

**World 2: Spring-managed mocks.** When a Spring context _is_ running (`@WebMvcTest`, `@SpringBootTest`, and so on), the bean you want to fake already lives inside the container. You need to replace it there, and `@Mock` can't do that, because Spring doesn't know about it. That's the job of `@MockitoBean`:

```java
@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    MockMvc mvc;

    @MockitoBean
    UserService service;   // replaces the real UserService bean in the context

    @Test
    void returns409WhenEmailTaken() throws Exception {
        given(service.register(any(), any()))
                .willThrow(new EmailAlreadyUsedException("ana@example.com"));

        mvc.perform(post("/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"name": "Ana", "email": "ana@example.com"}
                    """))
           .andExpect(status().isConflict());
    }
}
```

A quick rule: **`@Mock` for tests without Spring, `@MockitoBean` for tests with Spring.**

## `@MockBean` vs `@MockitoBean`

You'll see both in the wild, so it's worth knowing the history:

- **`@MockBean`** and **`@SpyBean`** were the classic Spring Boot annotations.
- Since **Spring Boot 3.4** they're deprecated in favor of **`@MockitoBean`** and **`@MockitoSpyBean`**, which come from Spring Framework itself (`org.springframework.test.context.bean.override.mockito`). They behave almost identically for everyday use.
- In newer Boot versions the old ones are removed, so prefer the new ones in fresh code. If you're on an older Boot version, `@MockBean` is still the right choice.

## Stubbing: telling a mock what to do

```java
// Return a value
given(repository.findByEmail("ana@example.com"))
        .willReturn(Optional.of(user));

// Throw an exception
given(gateway.charge(anyDouble()))
        .willThrow(new PaymentFailedException());

// Compute the result from the arguments
given(repository.save(any(User.class)))
        .willAnswer(inv -> inv.getArgument(0));

// Different results on consecutive calls
given(clock.millis()).willReturn(1000L, 2000L);

// For void methods, the order flips
willThrow(new RuntimeException()).given(emailSender).send(any());
```

Unstubbed methods return "empty" defaults: `null` for objects, `0` for numbers, `false` for booleans, and empty collections for lists and maps. That means a forgotten stub can produce a confusing `NullPointerException`, not a clear error.

## Verifying: checking that something happened

```java
then(repository).should().save(any(User.class));          // called once
then(repository).should(times(2)).save(any());            // exactly twice
then(repository).should(never()).save(any());             // never
then(emailSender).shouldHaveNoInteractions();             // never touched at all
```

Verify **side effects that matter** ("the email was sent", "nothing was saved"). Don't verify every internal call, or your tests become a mirror of the implementation and break whenever you refactor.

## Capturing arguments

Sometimes you need to inspect _what_ was passed to a collaborator, not just that it was called:

```java
@Captor
ArgumentCaptor<User> userCaptor;

@Test
void savesUserWithGivenDetails() {
    given(repository.existsByEmail(any())).willReturn(false);

    service.register("Ana", "ana@example.com");

    then(repository).should().save(userCaptor.capture());
    assertEquals("Ana", userCaptor.getValue().getName());
}
```

This is handy when the object is built _inside_ the method under test, so you can't create it yourself in advance.

## Mocks vs. spies

A **mock** replaces the whole object, so every method is fake unless stubbed. A **spy** wraps a _real_ object: real methods run unless you stub them.

```java
@MockitoSpyBean
PriceCalculator calculator;   // real behavior, but you can verify or override calls
```

Spies are occasionally useful, for example when you want real logic but need to confirm a call happened. If you find yourself reaching for them often, it can be a sign the class has too many responsibilities.

## The context-caching gotcha

This one catches almost everyone eventually. Spring caches application contexts between tests to keep the suite fast, and the cache key includes the **set of bean overrides**. So:

- Test class A has `@MockitoBean UserService`.
- Test class B has `@MockitoBean OrderService` instead.

Those are two different context configurations, so Spring builds **two contexts**, and each one takes seconds to start. Scatter different `@MockitoBean` combinations across dozens of test classes and your suite slows dramatically.

Ways to keep it fast:

- Declare shared mocks in a **common base class or a shared `@TestConfiguration`**, so many tests share one cached context.
- Prefer plain `@Mock` tests (no context at all) wherever you can.
- Keep `@SpringBootTest` tests few.

Also, mocks declared with `@MockitoBean` are reset automatically after each test method, so stubbing from one test doesn't leak into the next.

## Replacing a bean with a hand-written fake

Instead of a Mockito mock, you can supply a simple fake implementation through a test configuration:

```java
@TestConfiguration
class FakeClockConfig {
    @Bean
    @Primary
    Clock clock() {
        return Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
    }
}
```

```java
@SpringBootTest
@Import(FakeClockConfig.class)
class SomeTest { ... }
```

For things like clocks or ID generators, a small fake is often clearer than stubbing a mock in every test.

## What you should _not_ mock

Mockito's maintainers have long advised against this, and it's good advice:

- **Types you don't own** (JDBC, `RestTemplate`, third-party SDK internals). If you mock them, you're testing your _assumption_ of how they behave, and assumptions are often wrong. Wrap them in your own small interface and mock _that_, or test against the real thing.
- **The database, when the query is what matters.** A mocked repository can't tell you whether your `@Query` is correct. That's what `@DataJpaTest` with Testcontainers and Postgres is for.
- **Value objects and simple data classes.** Just create real ones.
- **The class under test itself.** If you need a spy on it to make a test work, the design probably needs rethinking.

For external HTTP services, tools like **WireMock** or **MockWebServer** are better than mocking `RestTemplate` or `WebClient`, because the real HTTP client code still runs and you fake only the remote server.

## Common mistakes

- **Using `@Mock` where you needed `@MockitoBean`.** The test compiles, but the real bean runs inside the context and your stubbing has no effect.
- **Mockito's strict stubs complaining** (`UnnecessaryStubbingException`). With `MockitoExtension`, a stub that's never used fails the test. It's annoying but useful: it flags dead setup or a test that isn't exercising what you think.
- **Over-mocking.** If a test has five mocks and ten stubs, you're probably testing wiring in your head rather than behavior. Consider whether the class does too much.
- **Stubbing with the wrong argument.** `given(repo.find("a"))` only matches `"a"` exactly. If the code calls it with `"A"`, you get `null` back. Use matchers like `any()` or `eq(...)` deliberately, and remember that if you use one matcher in a call, _all_ arguments must be matchers.

## Decision cheat sheet

|Situation|Tool|
|---|---|
|Unit test of a service or plain class|`@ExtendWith(MockitoExtension.class)` + `@Mock` + `@InjectMocks`|
|Controller test with a mocked service|`@WebMvcTest` + `@MockitoBean`|
|Need real logic plus verification|`@MockitoSpyBean` (or `@Spy` without Spring)|
|Testing queries or constraints|No mock: `@DataJpaTest` + Testcontainers|
|Calling an external HTTP API|WireMock or MockWebServer|
|Time, UUIDs, randomness|A small fake injected as a bean|




[[Testing]]
[[Spring Framework]]