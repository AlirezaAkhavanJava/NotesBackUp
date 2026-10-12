

`@SpringBootTest` goes on a test class and tells Spring: "Before running these tests, start up my application, the real thing, with all its beans wired together." Your tests can then ask Spring for any piece of the app and use it exactly as it would behave in production.

```java
@SpringBootTest
class UserServiceTest {

    @Autowired
    private UserService userService;

    @Test
    void createsAUser() {
        User user = userService.create("alireza");
        assertNotNull(user.getId());
    }
}
```

Notice there's no `new UserService(...)` anywhere. Spring built the service, gave it its repository, and connected the repository to the database config, just like when you run the app. The test only asks for the finished product with `@Autowired`.

**What happens behind the scenes**

When the test starts, Spring Boot searches upward through your packages until it finds the class annotated with `@SpringBootApplication`. It uses that class as the starting point, builds the full application context (component scanning, auto-configuration, your `application.properties`, everything), and then injects beans into your test. It also caches that context, so if many test classes share the same configuration, Spring doesn't rebuild it each time.

**A technical analogy**

Think of it like booting your whole app inside a test harness instead of testing one function in isolation. Where the analogy bends: by default, it doesn't start a real web server listening on a port. It sets up a mock web environment. If you want a real server on a random port (useful for testing with an actual HTTP client), you ask for it:

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
```

**The trade-off you should know about**

Because it loads everything, `@SpringBootTest` is slow compared to a plain unit test. That's fine for a few integration tests that check "do all my pieces actually work together?", but it's a poor choice for every little test. As you aim for senior-level thinking, the habit to build is this: use plain JUnit tests (with Mockito) for logic in a single class, and save `@SpringBootTest` for end-to-end-ish checks.

There are also "slice" annotations that load only part of the app, which are faster:

- `@WebMvcTest` loads just the web layer (controllers), good for testing endpoints
- `@DataJpaTest` loads just the JPA/repository layer, with an in-memory database by default

**Replacing a bean with a fake**

Sometimes you want the full context but need one piece faked, like an email sender you don't want firing for real. You can swap a bean for a Mockito mock:

```java
@SpringBootTest
class NotificationTest {

    @MockitoBean
    private EmailSender emailSender;   // Spring uses this mock instead of the real one
    ...
}
```

You'll see older tutorials use `@MockBean` for this. It was deprecated in favor of `@MockitoBean`, so prefer the newer one.




[[Spring Framework]]
[[Testing]]
