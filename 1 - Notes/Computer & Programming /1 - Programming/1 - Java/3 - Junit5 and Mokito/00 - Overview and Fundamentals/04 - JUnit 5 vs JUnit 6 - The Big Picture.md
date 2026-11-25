


JUnit 6 isn't a replacement that makes JUnit 5 obsolete overnight, and it isn't a new testing model either — it's the same Jupiter programming model (`@Test`, `@ParameterizedTest`, the assertion API, all of it) riding on a modernized, cleaned-up foundation. The useful way to think about it: JUnit 4 → JUnit 5 was a redesign (new architecture, new annotations, a totally different way of writing tests). JUnit 5 → JUnit 6 is a generational cleanup — raising baseline requirements, unifying versioning, and removing years of accumulated deprecated cruft, without changing how you actually write a test.

That distinction matters because it shapes the real-world decision: moving from JUnit 4 to 5 used to require rewriting test code. Moving from JUnit 5 to 6 mostly requires checking your Java/Kotlin version and your dependency versions — your existing `@Test` methods keep compiling and running unchanged.

## Why JUnit 6 exists at all

JUnit 5 shipped in 2017, targeting Java 8. Nine years of Java releases later, the language itself had moved — records, pattern matching, virtual threads, sealed classes all became normal in production code — while JUnit 5 was still bound to a Java 8 floor for compatibility. Every year that floor stayed in place, JUnit's own internals accumulated workarounds for APIs that newer Java versions had deprecated or replaced, and the Platform/Jupiter/Vintage version-numbering split kept causing dependency mismatches in people's build files. JUnit 6 is the project drawing a line and saying: we're raising the floor, paying off that debt in one release, and keeping JUnit 5 around for a transition period rather than forcing an abrupt cutover.

## Side-by-side on the things that actually differ

||JUnit 5|JUnit 6|
|---|---|---|
|Minimum Java|8|17|
|Minimum Kotlin|—|2.2|
|Platform/Jupiter/Vintage versions|Independent version numbers|One shared version number|
|Deprecated APIs from JUnit 5's lifetime|Still present|Removed|
|CSV parsing (`@CsvSource`)|univocity-parsers|FastCSV|
|Kotlin coroutine support in tests|Workarounds needed|`suspend` supported directly|
|Nullability contracts|Implicit|Explicit, via JSpecify annotations|
|Cancelling an in-progress test run|Not available|`CancellationToken` API|

Everything in the left-hand "what you write" category — annotations, assertions, parameterized test sources, the lifecycle (`@BeforeEach`/`@AfterEach`/`@BeforeAll`/`@AfterAll`), Mockito integration — is identical between the two. The table above is the complete list of what's genuinely different; there's no second hidden layer of changes to the test-writing API.

## The practical decision

If a project is still on Java 8–16, JUnit 6 simply isn't installable — JUnit 5 remains the only option, and the project said it'll keep maintaining JUnit 5 for at least a year for exactly this reason. If a project is already on Java 17+, upgrading to JUnit 6 is close to a drop-in dependency bump: update the version, remove any explicit per-module version pins (since there's now one shared version), and re-run the suite — the main thing worth specifically re-checking afterward is any test relying on complex or oddly formatted `@CsvSource` data, since the new FastCSV parser handles malformed input differently than the old one did.

## A short note on a related concept: semantic versioning and why "major version" doesn't always mean "rewrite"

JUnit 6 is a good example of what a major version bump is actually _for_ in semantic versioning: it's not a promise that everything changed, it's a promise that something **breaking** changed (here: the Java 8 floor disappearing, deprecated APIs removed) — which by definition requires a major version number, even when the bulk of the API surface, like Jupiter's annotations, is left completely untouched.


[[Junit & Mokito]]
