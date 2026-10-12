
`@BeforeAll` is the "do this once, at the very start" hook. Where `@BeforeEach` runs before every test, `@BeforeAll` runs a single time, before the first test in the class, and then never again for that class.

```java
@SpringBootTest
class ReportServiceTest {

    @Autowired
    private ReportService reportService;

    private static Path tempDir;

    @BeforeAll
    static void createSharedFolder() throws IOException {
        tempDir = Files.createTempDirectory("reports");   // created once
    }

    @Test
    void writesAReport() {
        reportService.writeTo(tempDir);
        // ...
    }

    @Test
    void writesAnotherReport() {
        reportService.writeTo(tempDir);   // same folder, not a new one
        // ...
    }

    @AfterAll
    static void deleteSharedFolder() throws IOException {
        FileSystemUtils.deleteRecursively(tempDir);   // cleaned once, at the end
    }
}
```

The folder is created one time, both tests use it, and it's removed one time at the end. That's the whole point: `@BeforeAll` is for setup that is expensive or that can safely be shared by every test.

**The `static` rule, and why it exists**

By default, JUnit 5 creates a **new instance of your test class for every test method**. That keeps tests isolated, since instance fields don't leak between them. But it creates a puzzle: `@BeforeAll` runs _before any instance exists_, so it can't be an instance method. That's why it must be `static`.

The catch is that a static method can't touch your instance fields, and it can't use `@Autowired` fields, because those are instance fields too. If you try to use an autowired bean inside a `@BeforeAll` static method, it won't work.

**The way around it**

If you want a non-static `@BeforeAll`, tell JUnit to use one instance for the whole class:

```java
@SpringBootTest
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class ReportServiceTest {

    @Autowired
    private ReportService reportService;

    @BeforeAll
    void loadSharedData() {          // no static needed now
        reportService.preload();     // autowired beans are usable here
    }
}
```

Now there's one instance for all tests, so `@BeforeAll` can be a normal method and can use `@Autowired` fields. The trade-off: instance fields are now shared between tests, so a test that changes a field can affect the next one. You give up some isolation to gain convenience.

**When to reach for it in Spring tests**

Good fits are things that are costly to repeat or live outside Spring: creating a temp directory, starting a container (like a Postgres Testcontainer), or starting a mock server. Poor fits are resetting database rows, because you want that to happen before _each_ test, which is `@BeforeEach` or `@Transactional`.

Where this breaks down compared to the Spring context: you might think `@BeforeAll` is how Spring "starts the app once." It isn't. Spring builds and caches the context on its own, before your `@BeforeAll` runs. `@BeforeAll` is a JUnit feature, and Spring just plugs into it.




[[Spring Framework]]
[[Testing]]