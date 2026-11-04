
Teardown is the mirror image of setup: code that runs _after_ tests to clean up. In JUnit 5 you have two annotations for it, and the difference between them is the same as with setup.

```java
@SpringBootTest
class UserServiceTest {

    @Autowired
    private UserRepository userRepository;

    @AfterEach
    void tearDown() {
        userRepository.deleteAll();   // runs after every single test
    }

    @AfterAll
    static void afterEverything() {
        System.out.println("All tests in this class are done");   // runs once, at the end
    }

    @Test
    void savesAUser() {
        userRepository.save(new User("alireza"));
        assertEquals(1, userRepository.count());
    }
}
```

`@AfterEach` runs after each test method, so it's the place to undo whatever that one test did: delete rows, reset a mock, clear a cache. `@AfterAll` runs once after the last test in the class, and like `@BeforeAll` it must be `static` unless you use `@TestInstance(TestInstance.Lifecycle.PER_CLASS)`. Use it for expensive, shared things, like stopping an external resource you started for the whole class.

**One useful guarantee**

`@AfterEach` runs even if the test fails or throws an exception. That's exactly why teardown code lives there instead of at the bottom of the test method: if an assertion fails halfway through, the lines after it never execute, but your cleanup still does.

**Order of execution**

For one test, the sequence is: `@BeforeEach`, then the `@Test`, then `@AfterEach`. And for the whole class: `@BeforeAll` once at the start, all the tests, then `@AfterAll` once at the end.

**Do you actually need teardown in Spring tests?**

Often, less than you'd think. Since the Spring context and database are shared between tests, you need _some_ way to reset state, but it doesn't have to be a teardown method:

- `@Transactional` on the test class rolls back each test's changes automatically, so there's nothing to clean up.
- Cleaning in `@BeforeEach` (as in the last lesson) works just as well, and has a small advantage: if a previous run crashed and left junk behind, the next run still starts clean.

Teardown shines when the thing to clean up lives _outside_ the database transaction: temp files you created, a mock server you started, or data written through real HTTP calls with `RANDOM_PORT`, where the rollback can't reach.

Where the "mirror image" idea breaks down: setup and teardown aren't always paired one-to-one. Many teams only write setup (reset at the start) and skip teardown entirely, because a clean start is what the next test really cares about.



[[Testing]]
[[Spring Framework]]