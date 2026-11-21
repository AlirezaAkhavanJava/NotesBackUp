

## @DirtiesContext

Spring builds the application context once and reuses it across test classes. Usually that's a great thing. But sometimes a test changes something _inside_ the context that you can't easily undo, like a singleton bean holding an in-memory cache, a counter, or a scheduler. The next test then inherits that mess.

`@DirtiesContext` says: "after this test (or class), throw this cached context away and build a fresh one for whoever comes next."

```java
@SpringBootTest
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class CacheWarmupTest {

    @Autowired
    private PriceCache priceCache;

    @Test
    void fillsTheCache() {
        priceCache.put("apple", 3);
        assertEquals(3, priceCache.get("apple"));
    }
}
```

When this class finishes, Spring discards its context. Any later test class starts with a brand-new one, with an empty `PriceCache`.

You can place it on a class or on a single method, and the timing is controllable:

- On a method, the default is `AFTER_METHOD`: the context is discarded right after that test.
- On a class, `AFTER_CLASS` (the usual choice) discards it once after all tests, while `AFTER_EACH_TEST_METHOD` discards it after every test.
- `BEFORE_CLASS` and `BEFORE_METHOD` do the same thing, but _before_ the test runs.

The cost is the important part. Rebuilding the whole context means scanning components, wiring beans, and starting the database connection again, which can take seconds each time. Sprinkle `@DirtiesContext` everywhere and your suite crawls. So treat it as a last resort. If you can reset the state another way (a `clear()` method called in `@BeforeEach`, `@Transactional` rollback), do that instead. `@DirtiesContext` is for cases where resetting is genuinely impossible.

## Testcontainers

This is the real-world use of `@BeforeAll` and `@AfterAll` that I promised. Testcontainers starts a real Docker container (Postgres, Redis, Kafka, and so on) for your tests, and tears it down afterward. Since you already know PostgreSQL, you'll see why this is appealing: your tests run against the same database engine you use in production, instead of an in-memory stand-in like H2 that behaves slightly differently.

It plugs into JUnit's lifecycle, so you rarely write the `@BeforeAll`/`@AfterAll` yourself. The `@Testcontainers` and `@Container` annotations do it for you:

```java
@SpringBootTest
@Testcontainers
class UserRepositoryIT {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres =
            new PostgreSQLContainer<>("postgres:16");

    @Autowired
    private UserRepository userRepository;

    @Test
    void savesAndLoadsAUser() {
        userRepository.save(new User("alireza"));
        assertEquals(1, userRepository.count());
    }
}
```

Here's what's happening:

- **`@Container` on a `static` field** means "start this once before all tests, stop it after all tests." That's exactly `@BeforeAll` and `@AfterAll`, handled for you. Make the field non-static and you get a _new_ container for every test, which is `@BeforeEach`/`@AfterEach` behavior and much slower.
- **`@ServiceConnection`** (Spring Boot 3.1 and later) automatically points Spring's datasource at the container. No URL, username, or password to configure. Before this existed, people wrote a `@DynamicPropertySource` method to inject the container's random port into the properties, and you'll still see that in older tutorials.
- The container needs Docker running on your machine. On Debian, make sure the Docker service is up and your user can access it.

A small heads-up: Testcontainers 2.x reorganized some package and artifact names (the Postgres container moved to its own module), so if an import doesn't resolve, check which version you're on. The idea is identical either way.

## How the two fit together

They solve different problems, and where they meet is worth knowing. A container is _outside_ Spring, so `@DirtiesContext` doesn't touch it. Discarding the Spring context doesn't stop or reset your Postgres container, and stopping the container doesn't rebuild the context. Think of them as two separate caches with two separate lifetimes. The analogy to a "reset button" breaks down here, because there isn't one button, there are two, and each only controls its own side.

That also means data written to the container's database survives between tests in the same class. So you still need the earlier tools (`@Transactional`, or `deleteAll()` in `@BeforeEach`) to keep tests from leaking into each other.




[[Testing]]
[[Spring Framework]]