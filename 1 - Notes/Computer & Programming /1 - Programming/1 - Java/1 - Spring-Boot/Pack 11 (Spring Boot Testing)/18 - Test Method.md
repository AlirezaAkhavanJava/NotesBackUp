
A test method is just a regular method with `@Test` on top. JUnit finds every method with that annotation, runs each one, and reports pass or fail. If the method finishes without throwing an exception, the test passes. If an assertion fails (or anything throws), the test fails.

```java
@SpringBootTest
class UserServiceTest {

    @Autowired
    private UserService userService;

    @Test
    void createsUserWithGivenName() {
        // Arrange: get things ready
        String name = "alireza";

        // Act: do the thing you're testing
        User user = userService.create(name);

        // Assert: check the result
        assertEquals("alireza", user.getName());
        assertNotNull(user.getId());
    }
}
```

**The rules for a test method**

- It needs `@Test` (from `org.junit.jupiter.api.Test`, not the old JUnit 4 one).
- It returns `void` and takes no parameters (parameters are only allowed for special cases like `@ParameterizedTest`).
- It doesn't need to be `public`. Package-private is fine in JUnit 5.
- The name can be anything, so make it describe the behavior. `createsUserWithGivenName` tells you what broke when it fails; `test1` doesn't.

**The Arrange, Act, Assert shape**

Almost every good test has three parts, and keeping them visible makes tests easy to read:

1. **Arrange**: set up the input and any state.
2. **Act**: call the one thing you're testing.
3. **Assert**: verify the outcome.

If you find yourself acting twice or asserting unrelated things, that's usually a sign to split it into two tests.

**The assertions you'll use most**

These live in `org.junit.jupiter.api.Assertions`:

```java
assertEquals(expected, actual);      // expected value comes FIRST
assertTrue(user.isActive());
assertNotNull(user.getId());
assertThrows(IllegalArgumentException.class, () -> userService.create(""));
```

Watch the order in `assertEquals`: expected first, actual second. Swap them and the test still works, but the failure message will be confusing ("expected: <actual value>").

`assertThrows` deserves a special mention: it's how you test that something _fails correctly_. You pass the exception type and a lambda containing the code that should throw it.

**Many assertions in one test**

Normally, the first failed assertion stops the test, so you only see one problem at a time. If you want to see all failures at once, group them:

```java
assertAll(
    () -> assertEquals("alireza", user.getName()),
    () -> assertNotNull(user.getId()),
    () -> assertTrue(user.isActive())
);
```

**A nicer assertion library**

Spring Boot's test starter also includes AssertJ, which reads more like English and gives better failure messages. Many teams prefer it:

```java
import static org.assertj.core.api.Assertions.assertThat;

assertThat(user.getName()).isEqualTo("alireza");
assertThat(user.getId()).isNotNull();
```

Both styles work in the same project. Where the "just call a method and check" idea gets bumpy is with Spring: your test talks to _beans_, so most of the Arrange step is really "make sure the right data is in the database," which is where `@BeforeEach` and `@Transactional` from earlier come in.




[[Testing]]
[[Spring Framework]]