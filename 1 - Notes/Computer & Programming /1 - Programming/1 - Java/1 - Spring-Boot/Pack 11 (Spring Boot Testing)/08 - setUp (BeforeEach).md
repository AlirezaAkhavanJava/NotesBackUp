In JUnit 5, which is what Spring Boot uses by default, a "set up method" is simply a method annotated with `@BeforeEach`. JUnit runs it before every single test method in the class, so each test starts from a known state.

```java
@SpringBootTest
class UserServiceTest {

    @Autowired
    private UserService userService;

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
        userRepository.save(new User("existing-user"));
    }

    @Test
    void findsExistingUser() {
        assertTrue(userService.exists("existing-user"));
    }

    @Test
    void startsWithExactlyOneUser() {
        assertEquals(1, userRepository.count());
    }
}
```

Before each of those two tests, `setUp()` wipes the table and inserts one user. The tests can't affect each other, and they pass in any order. The name `setUp` is just a convention; the annotation is what matters. The method also doesn't need to be `public`, which is a small difference from JUnit 4.

**The family of lifecycle annotations**

- `@BeforeEach` runs before every test.
- `@AfterEach` runs after every test, which is handy for cleanup.
- `@BeforeAll` runs once before all tests in the class. It must be `static`, unless you add `@TestInstance(TestInstance.Lifecycle.PER_CLASS)` to the class.
- `@AfterAll` runs once after all tests, with the same `static` rule.

**The part that trips people up with Spring**

Here's where Spring Boot adds a twist. Remember that Spring builds the application context once and caches it. Your beans (services, repositories) are singletons shared by every test. `@BeforeEach` runs again for each test, but the context does not. So if one test saves a row to the database, it's still there when the next test starts, unless something removes it.

That's the real reason setup methods matter in Spring tests: they're your chance to reset shared state. You have a few options:

1. Clean up manually in `@BeforeEach`, like `deleteAll()` above.
2. Put `@Transactional` on the test class. Spring then rolls back each test's database changes automatically, so you don't need to clean anything.
3. Use `@Sql` to run a SQL script before a test.

The analogy to keep in mind is that `@BeforeEach` is like resetting a whiteboard between exercises. It breaks down because the whiteboard here is the _shared_ application context and database, which Spring deliberately doesn't rebuild. You're erasing the board, not buying a new one.

One catch with `@Transactional`: if you use `webEnvironment = RANDOM_PORT` and make real HTTP calls, the server handles the request on a different thread, outside your test's transaction. The rollback won't cover those changes, so you'd need manual cleanup in `@BeforeEach` or `@AfterEach` there.





[[Spring Framework]]
[[Testing]]