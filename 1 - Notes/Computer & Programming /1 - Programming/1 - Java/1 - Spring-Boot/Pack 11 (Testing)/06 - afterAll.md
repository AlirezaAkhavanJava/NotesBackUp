
`@AfterAll` is the mirror image of `@BeforeAll`: it runs once, after the last test in the class has finished, and never again for that class. It's where you put the cleanup for anything you created once at the start.

```java
@SpringBootTest
class ReportServiceTest {

    private static Path tempDir;

    @BeforeAll
    static void createSharedFolder() throws IOException {
        tempDir = Files.createTempDirectory("reports");
    }

    @AfterAll
    static void deleteSharedFolder() throws IOException {
        FileSystemUtils.deleteRecursively(tempDir);   // runs once, at the very end
    }

    @Test
    void writesAReport() { /* uses tempDir */ }

    @Test
    void writesAnotherReport() { /* uses tempDir */ }
}
```

The pattern is simple: whatever `@BeforeAll` opens, `@AfterAll` closes. Created a temp folder? Delete it. Started a mock server? Stop it. Started a Postgres container? Shut it down.

**The same `static` rule applies**

Since JUnit creates a fresh instance of the test class for each test by default, there's no single instance to run `@AfterAll` on, so the method must be `static`. And just like before, a static method can't use `@Autowired` fields. If you need beans in there, add `@TestInstance(TestInstance.Lifecycle.PER_CLASS)` to the class and the method can be a normal instance method.

**A guarantee worth knowing**

Like `@AfterEach`, `@AfterAll` still runs even if some tests fail. That's what makes it safe for releasing resources: a failing test won't leave your temp files or containers hanging around. One caveat is that if `@BeforeAll` itself throws an exception, the tests are skipped, but `@AfterAll` still runs, so write it defensively. For example, check that `tempDir` isn't `null` before deleting it, because setup may have failed before assigning it.

**The full order, start to finish**

For a class with two tests, it looks like this:

1. `@BeforeAll` (once)
2. `@BeforeEach`, test one, `@AfterEach`
3. `@BeforeEach`, test two, `@AfterEach`
4. `@AfterAll` (once)

**Where it fits with Spring**

Here's the part that surprises people. `@AfterAll` does _not_ shut down the Spring application context. Spring caches the context and reuses it across test classes, so it stays alive after your `@AfterAll` runs and only closes when the whole test run ends (a JVM shutdown hook handles it). So `@AfterAll` is for cleaning up _your_ resources, not Spring's. If a test genuinely changes the context in a way that would poison later tests, you'd use `@DirtiesContext`, which tells Spring to throw that cached context away after the class.




[[Spring Framework]]
[[Testing]]

