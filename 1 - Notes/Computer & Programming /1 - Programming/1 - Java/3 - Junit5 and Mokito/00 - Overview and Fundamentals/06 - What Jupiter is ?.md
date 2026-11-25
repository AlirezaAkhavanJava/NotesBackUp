


**Jupiter** is the name of the actual test-writing API and engine inside JUnit 5 — it's the thing you're using every time you write `@Test`, `assertEquals`, `@ParameterizedTest`, or any other JUnit code shown in this conversation so far. The confusion you're sensing is legitimate: "JUnit 5" is a project name that bundles three separate sub-components together, and Jupiter is only one of those three. People say "JUnit 5" loosely to mean "the new annotations and API I write tests with," but that specific thing has its own name — Jupiter — distinct from the other two pieces that ship alongside it.

So to directly answer "is it something different from each other": yes. JUnit 5, Jupiter, Platform, and Vintage are four related but distinct names, and mixing them up is one of the most common points of confusion for people learning this.

## The four names, disambiguated

- **"JUnit 5"** — the umbrella project/release name. Not a library you import by this name; it's a label for "the generation of JUnit released after JUnit 4," covering everything below.
- **JUnit Platform** — the foundation that _discovers_ tests in your codebase and _launches_ them. It has zero knowledge of what `@Test` means — it just defines a generic `TestEngine` interface and knows how to run whatever engines are registered.
- **JUnit Jupiter** — the actual programming model: the annotations, the assertion methods, the extension mechanism (`@ExtendWith`). It's also a `TestEngine` implementation, meaning it's the thing that plugs into the Platform and tells it "here's how to run a class with `@Test` methods in it."
- **JUnit Vintage** — a _different_ `TestEngine` implementation, whose entire job is running old JUnit 3/4 style tests on the modern Platform, so legacy test suites don't have to be rewritten just to use current tooling.

```java
// This entire block is Jupiter — none of it is "Platform" or "Vintage" code:
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;

class CalculatorTest {
    @Test
    void addsNumbers() {
        assertEquals(5, new Calculator().add(2, 3));
    }
}
```

The `org.junit.jupiter.api` package name is itself the proof — every annotation and assertion you've used in this conversation lives under that package, which is exactly why "Jupiter" is the correct, specific name for it, even though everyday conversation shortens it to "JUnit."

## Why the split matters, not just as trivia

The reason this isn't just pedantic naming: Platform, Jupiter, and Vintage are separate Maven/Gradle dependencies, and understanding which is which explains things you'll actually run into:

- If your project has old JUnit 4 tests _and_ new Jupiter tests in the same codebase, that only works because you've pulled in **both** `junit-jupiter` and `junit-vintage-engine` — two separate engines, both plugging into the same Platform, running side by side in one test run.
- If you ever see a dependency error about a missing `TestEngine`, it means the Platform found no engine capable of running your tests — usually because `junit-jupiter-engine` (or `junit-vintage-engine`) wasn't on the classpath, even though `junit-jupiter-api` (just the annotations) was.
- Spring Boot's `spring-boot-starter-test` pulls in all of this for you bundled together, which is exactly why most people never had to think about the split until they hit a dependency conflict or an unusual multi-engine setup.

## A short note on a related concept: this split carries into JUnit 6 unchanged

The Platform/Jupiter/Vintage three-way split itself didn't change in JUnit 6 — what changed was that all three now share one version number instead of versioning independently (one of the JUnit 6 changes covered earlier). So the architectural answer to "are these different things" stays true across both generations: Jupiter is still specifically the programming model and engine, Platform is still the generic runner underneath it, and Vintage is still the separate engine for legacy tests — JUnit 6 modernized the internals without merging or renaming any of the three.


[[Junit & Mokito]]