

JUnit is the standard testing framework for Java — it's the tool you use to write small, automated checks ("tests") that verify a piece of code behaves the way you expect, and then run all of those checks automatically instead of testing things by hand every time you change code. JUnit 6 is the newest major version of it, released in September 2025, and it's less "new features to learn" and more "the project cleaning house" — most of what changed is about how the framework is versioned, packaged, and maintained, not about how you write `@Test` methods day to day.

## The naming change you need to understand first

Before JUnit 6, "JUnit 5" was really an umbrella name for three separately-versioned modules:

- **JUnit Platform** — the engine that discovers and runs tests, and lets other test frameworks plug into it
- **JUnit Jupiter** — the actual `@Test`, `@BeforeEach`, assertions API you write your tests against
- **JUnit Vintage** — a compatibility layer so old JUnit 4 tests can still run on the new platform

These three used to drift to different version numbers (e.g. Platform 1.10 + Jupiter 5.10). From JUnit 6 onward, all three are versioned together as one unit — Platform 6.1, Jupiter 6.1, and Vintage 6.1 all move in lockstep. So "JUnit 6" isn't a rewrite of Jupiter the way JUnit 4 → 5 was a rewrite; it's JUnit 5's three modules finally sharing one version number, plus some cleanup that came along with that reset.

## What actually requires your attention

**Java 17 is now the floor.** JUnit 6 needs Java 17 or newer to run. You're on JDK 25, so this changes nothing for you — but it matters if you ever touch an older codebase still on Java 8 or 11, since that project simply cannot upgrade past JUnit 5.

**Two modules were deleted outright, not deprecated:**

- `junit-platform-runner` — this let you run JUnit 5 tests from a JUnit 4 runner (useful mid-migration). Gone. If a project still needs that bridge, it has to stay on JUnit 5.
- `junit-platform-jfr` — emitted Java Flight Recorder events during test discovery/execution, for profiling test runs. That capability didn't disappear — it moved into `junit-platform-launcher` directly, so nothing is lost, it's just not a separate dependency anymore.

**`@Nested` classes now have a deterministic default order.** This is a real behavioral fix, so it's worth a concrete look:

```java
class OrderServiceTest {

    @Nested
    class WhenCartIsEmpty {
        @Test
        void placingOrderThrows() { /* ... */ }
    }

    @Nested
    class WhenCartHasItems {
        @Test
        void placingOrderSucceeds() { /* ... */ }
    }
}
```

Before JUnit 6, the order in which `WhenCartIsEmpty` and `WhenCartHasItems` ran relative to each other was essentially undefined — the engine picked an order and it wasn't guaranteed to be consistent or intuitive. In JUnit 6, `@Nested` classes get the same `MethodOrderer.Default` / `ClassOrderer.Default` treatment as top-level test classes, and that ordering is now inherited by nested classes inside nested classes too. If you'd never noticed flaky-seeming test run orders before, this is why that category of surprise goes away.

**Nullability is now explicit via JSpecify.** Every JUnit 6 module annotates its public API with JSpecify's `@Nullable` / `@NonNull`-style annotations. This doesn't change how you call JUnit's methods, but if you use a static analysis tool or an IDE that understands JSpecify, it can now warn you in advance if you're about to pass `null` somewhere JUnit doesn't accept it, or if you're not null-checking a value JUnit might hand back.

**The Maven setup changed slightly.** JUnit 6 ships its own BOM (Bill of Materials) for dependency version management. If your `pom.xml` imports it, you lock all JUnit artifacts to matching 6.x versions in one place rather than specifying each module's version separately — and it protects you from accidentally pulling in a stray JUnit 5 artifact transitively through some other library, which would otherwise create a version mismatch at runtime.

```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.junit</groupId>
            <artifactId>junit-bom</artifactId>
            <version>6.1.3</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

## What stayed the same

The day-to-day API — `@Test`, `@BeforeEach`, `@AfterEach`, `@ParameterizedTest`, `assertEquals`, `assertThrows`, extensions via `@ExtendWith` — is unchanged. A JUnit 5 test class compiles and runs on JUnit 6 without edits, assuming you're already on Java 17+. The "unified extension model" you may see mentioned in release blogs refers to this version-unification work making the extension API (how third-party libraries hook into JUnit's lifecycle) more consistent across Platform and Jupiter now that they're guaranteed to be the same version — it's not a new API you need to learn.



[[Java]]
[[Spring Framework]]