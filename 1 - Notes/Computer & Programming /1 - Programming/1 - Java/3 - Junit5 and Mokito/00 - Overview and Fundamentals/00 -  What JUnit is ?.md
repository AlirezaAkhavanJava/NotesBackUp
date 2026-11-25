


When you write code, you need some way to check that it actually does what you intended — and that it keeps doing that as you change things later. The crude way is to run your whole application and manually poke at it. The better way is **unit testing**: writing small, independent pieces of code whose only job is to call a piece of your production code with known inputs and check that the output matches what you expect. A "unit" here usually means something small and isolated — a single method, or a single class — tested on its own, separate from databases, networks, or other classes it might depend on.

JUnit is the de facto standard framework for doing this in Java. It gives you:

- A way to _mark_ a method as a test (so tooling knows to run it, instead of treating it as regular code).
- A way to _run_ all your tests with one command and get a report of which passed and which failed.
- A way to _assert_ — state an expected outcome, so the test can automatically decide pass/fail instead of you eyeballing output.

JUnit has gone through several major generations: JUnit 3 (reflection-based, tests had to extend `TestCase` and method names had to start with `test`), JUnit 4 (introduced annotations like `@Test`, a big improvement), and then JUnit 5 and now JUnit 6, which is what the rest of this covers. Every Java build tool (Maven, Gradle) and every IDE has built-in support for discovering and running JUnit tests, which is part of why it's so dominant — you rarely have to configure anything to get tests running.

## JUnit 5: the three sub-projects

Unlike JUnit 4, which was one monolithic library, JUnit 5 is split into three parts that cooperate:

- **JUnit Platform** — the foundation layer. It knows how to _discover_ and _launch_ tests in the JVM, but it has no opinion on what a test looks like. It exposes a `TestEngine` interface that any testing framework can implement to plug in underneath it.
- **JUnit Jupiter** — the new test-writing API and the `TestEngine` implementation for it. This is what you actually write code against — the `@Test`, `@BeforeEach`, assertion methods, etc. When developers casually say "JUnit 5," they almost always mean Jupiter.
- **JUnit Vintage** — a second `TestEngine` implementation that lets old JUnit 3 and JUnit 4 style tests still run on the JUnit 5 Platform, so a legacy codebase with thousands of old tests doesn't have to rewrite them all just to upgrade.

The reason for this split: JUnit 4 tangled "how tests are run" together with "how tests are written," which made it hard for anyone to extend or replace just one piece. By separating them, a build tool only ever needs to talk to the Platform, and Jupiter, Vintage, or even a totally different framework (like Spock) can sit underneath it interchangeably.

## Writing a Jupiter test

```java
import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

class CalculatorTest {

    private Calculator calculator;

    @BeforeEach
    void setUp() {
        calculator = new Calculator();
    }

    @Test
    @DisplayName("adding two positive numbers returns their sum")
    void addsTwoPositiveNumbers() {
        assertEquals(5, calculator.add(2, 3));
    }

    @AfterEach
    void tearDown() {
        calculator = null;
    }
}
```

`@Test` marks a method as a test case that the engine should run. `@BeforeEach` runs before _every_ test method in the class, which is how you get a clean, isolated starting state for each test instead of tests silently depending on leftover state from a previous one. `@AfterEach` is the mirror image, for cleanup. `@DisplayName` only affects what shows up in test reports, not behavior. If setup/teardown is expensive and can be shared across the whole class (e.g. opening one database connection), `@BeforeAll`/`@AfterAll` run it just once — but the methods must be `static`, because they execute before any instance of the test class is created.

Two more annotations worth knowing: `@Disabled("reason")` skips a test while keeping it in the codebase (better than deleting it or commenting it out), and `@Nested` lets you group tests by scenario inside inner classes — e.g. a `WhenAccountIsEmpty` class nested inside `AccountTest`, each with its own `@BeforeEach`.

## Assertions and assumptions

```java
assertEquals(expected, actual);
assertTrue(condition);
assertThrows(IllegalArgumentException.class, () -> calculator.divide(1, 0));

assertAll("account properties",
    () -> assertEquals("Ethan", account.getName()),
    () -> assertTrue(account.getBalance() >= 0)
);

Assumptions.assumeTrue(System.getenv("CI") != null);
```

`assertThrows` checks that a block of code throws the expected exception type — this is how you test error-handling paths. `assertAll` groups assertions together so that if several fail, the test reports _all_ of them at once rather than stopping at the first failure (a plain sequence of standalone assertions aborts on the first one that fails). `Assumptions.assumeTrue` is a different concept from an assertion — instead of failing the test, a false assumption _aborts_ it, marking it "skipped." This is for conditions like "only run this test if a certain environment variable is present," where the test isn't wrong, it's just inapplicable right now.

## Parameterized tests

```java
@ParameterizedTest
@ValueSource(ints = {1, 3, 5, -1})
void oddNumbersReturnTrue(int number) {
    assertTrue(NumberUtils.isOdd(number));
}

@ParameterizedTest
@CsvSource({
    "1, 2, 3",
    "4, 5, 9"
})
void addsTwoNumbers(int a, int b, int expectedSum) {
    assertEquals(expectedSum, calculator.add(a, b));
}
```

`@ParameterizedTest` replaces `@Test` when you want the same test body to run once per supplied input, instead of duplicating near-identical test methods. `@ValueSource` is the simplest source — a flat list of literal values. `@CsvSource` supplies comma-separated rows that get split across multiple method parameters, which is what you reach for once a test needs more than one input per run.

## JUnit 6: what it adds on top

JUnit 6 builds on all the releases since JUnit 5.14, with JUnit 6.0.0 released on September 30, 2025. It's a modernization of JUnit 5, not a rewrite — your Jupiter test code above still works unchanged. The notable changes:

- **Higher minimum versions.** JUnit 6 raises the minimum required Java version from 8 to 17, and requires Kotlin 2.2 or later for Kotlin users. JUnit 5 stays maintained for at least another year for projects stuck on older Java.
- **One version number for everything.** JUnit 6 unifies versioning so Platform, Jupiter, and Vintage all share the same version — previously Platform versioned independently from Jupiter/Vintage, a frequent source of dependency-mismatch bugs.
- **Dead code removed.** JUnit 6 does a significant cleanup of the codebase, removing deprecated APIs and behaviors accumulated over JUnit 5's lifetime.
- **Kotlin coroutine support.** Test and lifecycle methods can be marked `suspend` directly, without workarounds.
- **CSV engine swap.** JUnit 6 migrated CSV parsing (used by `@CsvSource`) from the unmaintained univocity-parsers library to FastCSV, giving more consistent handling of malformed input and better error messages — worth re-checking complex `@CsvSource` tables after upgrading.
- **Explicit null-safety.** JUnit 6 adds JSpecify annotations for nullability, treating non-annotated types as non-nullable by default — mostly relevant if you're writing JUnit extensions against its own APIs.
- **Execution improvements in later 6.x releases**: cancelling a whole run via a `CancellationToken`, a new parallel test executor, an experimental memory-cleanup mode for very large suites, and built-in `@DefaultLocale`/`@DefaultTimeZone` extensions absorbed from the community JUnit Pioneer project.

Almost none of this changes how you _write_ a test day-to-day — `@Test`, `@ParameterizedTest`, the assertion methods, all stay identical. JUnit 6's changes are concentrated in the platform's minimum requirements, internal plumbing, and dependency versioning rather than the API surface you code against.


[[Junit & Mokito]]