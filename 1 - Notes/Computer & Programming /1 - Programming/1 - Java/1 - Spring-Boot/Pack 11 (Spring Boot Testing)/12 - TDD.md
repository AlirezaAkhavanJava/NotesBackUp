
# TDD in Spring Boot

Since you already know Spring Boot and Java, I'll skip the basics and focus on how TDD changes the way you build a Spring Boot feature. We'll build one small feature test-first, layer by layer.

## The core idea: Red → Green → Refactor

1. **Red**: write a test for behavior that doesn't exist yet. It fails (or doesn't even compile, which counts).
2. **Green**: write the _simplest_ code that makes it pass, even if it's embarrassingly naive.
3. **Refactor**: clean up the code (and the tests) while everything stays green.

The discipline is in step 2. You write only what the current failing test demands. That keeps your code small and ensures every line exists for a reason.

## The Spring Boot twist: choose the right test "slice"

In plain Java, TDD is simple. In Spring Boot, the trap is reaching for `@SpringBootTest` every time. It boots the whole application context, which is slow, and slow tests kill the TDD rhythm. Spring gives you _slices_ instead:

|Layer|Test style|Context loaded|
|---|---|---|
|Service (business logic)|Plain JUnit + Mockito|None (no Spring at all)|
|Controller (HTTP)|`@WebMvcTest`|Only the web layer|
|Repository (DB)|`@DataJpaTest`|Only JPA + a database|
|Whole flow|`@SpringBootTest`|Everything (use sparingly)|

A good TDD flow usually goes **from the inside out**: business logic first, then the layers around it.

## Our example feature

> "A user can register with a name and email. Registering with an email that's already taken must be rejected."

### Cycle 1: the service (pure unit test)

**Red.** Write the test before `UserService` exists:

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    UserRepository repository;

    @InjectMocks
    UserService service;

    @Test
    void registersNewUser() {
        when(repository.existsByEmail("ana@example.com")).thenReturn(false);
        when(repository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

        User saved = service.register("Ana", "ana@example.com");

        assertEquals("Ana", saved.getName());
        assertEquals("ana@example.com", saved.getEmail());
        verify(repository).save(any(User.class));
    }
}
```

It won't compile: no `User`, `UserRepository`, or `UserService`. Your IDE can generate empty shells, and that's the red step. Good TDD tip: the test is the first _user_ of your API, so you're designing the method signatures from the caller's point of view.

**Green.** The minimum to pass:

```java
public interface UserRepository extends JpaRepository<User, Long> {
    boolean existsByEmail(String email);
}

@Service
public class UserService {
    private final UserRepository repository;

    public UserService(UserRepository repository) {
        this.repository = repository;
    }

    public User register(String name, String email) {
        return repository.save(new User(null, name, email));
    }
}
```

(`User` is a simple `@Entity` with `id`, `name`, `email` and getters.)

Notice we haven't even _called_ `existsByEmail` yet. The test stubs it, but nothing forces us to use it. That's fine, since the next test will.

### Cycle 2: the duplicate rule

**Red.**

```java
@Test
void rejectsDuplicateEmail() {
    when(repository.existsByEmail("ana@example.com")).thenReturn(true);

    assertThrows(EmailAlreadyUsedException.class,
            () -> service.register("Ana", "ana@example.com"));

    verify(repository, never()).save(any());
}
```

The `never().save()` check matters: it proves the rejection happens _before_ anything is persisted.

**Green.**

```java
public User register(String name, String email) {
    if (repository.existsByEmail(email)) {
        throw new EmailAlreadyUsedException(email);
    }
    return repository.save(new User(null, name, email));
}
```

```java
public class EmailAlreadyUsedException extends RuntimeException {
    public EmailAlreadyUsedException(String email) {
        super("Email already in use: " + email);
    }
}
```

**Refactor.** With both tests green, you might tidy naming or extract constants. If you break something, you know within seconds.

### Cycle 3: the controller (`@WebMvcTest`)

Now the HTTP contract. Decide it in the tests: `201 Created` on success, `409 Conflict` on duplicate.

```java
@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    MockMvc mvc;

    @MockitoBean   // use @MockBean on Spring Boot versions before 3.4
    UserService service;

    @Test
    void returns201WhenRegistered() throws Exception {
        when(service.register("Ana", "ana@example.com"))
                .thenReturn(new User(1L, "Ana", "ana@example.com"));

        mvc.perform(post("/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"name": "Ana", "email": "ana@example.com"}
                    """))
           .andExpect(status().isCreated())
           .andExpect(jsonPath("$.email").value("ana@example.com"));
    }

    @Test
    void returns409WhenEmailTaken() throws Exception {
        when(service.register(any(), any()))
                .thenThrow(new EmailAlreadyUsedException("ana@example.com"));

        mvc.perform(post("/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"name": "Ana", "email": "ana@example.com"}
                    """))
           .andExpect(status().isConflict());
    }
}
```

The service is mocked here, because this test only cares that the controller maps requests and exceptions to the right HTTP responses. The green code is a `@RestController` with a `@PostMapping`, plus an `@ExceptionHandler` (or `@RestControllerAdvice`) mapping `EmailAlreadyUsedException` to 409. Write each piece only when its test demands it.

### Cycle 4: the repository (`@DataJpaTest`)

Your `existsByEmail` is a derived query, so Spring Data writes it for you. Do you need to test it? For trivial derived queries, often not. But as soon as you write a custom `@Query` or add constraints, you should. A good example is a **unique constraint** on email, which is your real safety net against two simultaneous registrations:

```java
@DataJpaTest
@Testcontainers
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class UserRepositoryTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

    @Autowired
    UserRepository repository;

    @Test
    void existsByEmailFindsSavedUser() {
        repository.save(new User(null, "Ana", "ana@example.com"));

        assertTrue(repository.existsByEmail("ana@example.com"));
        assertFalse(repository.existsByEmail("nobody@example.com"));
    }

    @Test
    void databaseRejectsDuplicateEmails() {
        repository.saveAndFlush(new User(null, "Ana", "ana@example.com"));

        assertThrows(DataIntegrityViolationException.class,
                () -> repository.saveAndFlush(new User(null, "Ana 2", "ana@example.com")));
    }
}
```

Since you use PostgreSQL, I'd suggest **Testcontainers** over H2. H2 is faster to set up but behaves subtly differently from Postgres (SQL dialect, constraints, types), so a test can pass on H2 and fail in production. Testcontainers runs a real Postgres in Docker; on Debian you just need Docker installed and your user in the `docker` group. `@ServiceConnection` (Spring Boot 3.1+) wires the datasource automatically.

### Cycle 5: one end-to-end test

Finally, a single `@SpringBootTest` that proves the pieces fit together:

```java
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class RegistrationFlowTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

    @Autowired
    MockMvc mvc;

    @Test
    void secondRegistrationWithSameEmailIsRejected() throws Exception {
        String body = """
            {"name": "Ana", "email": "ana@example.com"}
            """;

        mvc.perform(post("/users").contentType(MediaType.APPLICATION_JSON).content(body))
           .andExpect(status().isCreated());

        mvc.perform(post("/users").contentType(MediaType.APPLICATION_JSON).content(body))
           .andExpect(status().isConflict());
    }
}
```

Keep these few. They're your safety net for wiring problems, not the place to test every edge case.

## Habits that make TDD work in practice

- **Keep the cycle tiny.** If you're writing 30 lines before running the tests, the step is too big.
- **Watch the test fail first.** A test you've never seen fail might be passing for the wrong reason (for instance, a missing assertion).
- **Name tests as behaviors**: `rejectsDuplicateEmail` tells you what broke without opening the file.
- **Don't test the framework.** You don't need to verify that `save()` works or that Jackson serializes JSON. Test _your_ decisions.
- **Mock at boundaries, not everywhere.** Mocking the repository in a service test is fine. Mocking five collaborators usually signals the class does too much.
- **Refactor tests too.** Extract helpers or builders so tests stay readable, but keep them simple enough that they don't need their own tests.

## Common stumbling blocks

- **Reaching for `@SpringBootTest` by default**: the suite becomes slow and people stop running it.
- **Writing the implementation first "just this once"**: then the tests merely confirm what you wrote rather than driving the design.
- **Over-specifying with `verify()`**: asserting on every internal call makes tests brittle. Prefer asserting on outputs and visible state, and use `verify` for important side effects, like "nothing was saved".
- **Skipping the refactor step**: green code that's messy is still a debt. The third step is where design quality comes from.

## A practical way to start

Pick one small endpoint in a side project and build it entirely test-first, following this inside-out order: service → controller → repository → one end-to-end test. It will feel slow for the first hour and then surprisingly natural.




[[Testing]]
[[Spring Framework]]