

Automated testing is the practice of writing code whose job is to check other code, and running that checking code automatically instead of a person manually operating the software to see if it works. The distinction matters because the alternative — manual testing — means a human opens the application, clicks through some scenario, and visually judges whether the output looks right. That works, but it doesn't scale: every time you change one line of code, someone has to manually re-check everything that line might have affected, which is slow, inconsistent (humans miss things, get bored, test differently each time), and expensive to repeat.

An automated test replaces that human judgment with a program that runs the exact same check every time, in milliseconds, and reports pass or fail with no ambiguity:

```java
// Manual approach: run the app, create an order, look at the database, eyeball the total.

// Automated approach:
@Test
void orderTotalIncludesTax() {
    Order order = new Order(List.of(new LineItem("widget", 10.00, 2)));
    assertEquals(21.60, order.getTotal()); // 20.00 + 8% tax
}
```

Once that test exists, it can run every single time the code changes — part of a build, a commit, a deployment — without anyone needing to remember to check it, and it will fail loudly the instant someone breaks that behavior.

## Why "automated" is the key word

The value isn't just "a test exists" — it's that the test _runs itself, repeatedly, without human involvement_, which is what makes a few things possible:

- **Regression detection.** When you change code in one place, automated tests for unrelated parts of the system still run and catch cases where your change broke something you didn't expect to touch.
- **Speed and frequency.** A suite of thousands of automated tests can run in seconds to minutes. The same coverage done manually could take a team days — so automated tests get run far more often (every commit, instead of once before a release).
- **CI/CD integration.** Automated tests are what make continuous integration/continuous deployment possible at all: a pipeline can refuse to deploy code unless the automated test suite passes, which is not something you can wire a manual tester into.
- **Executable documentation.** A well-named test (`orderTotalIncludesTax`) describes expected behavior in a way that stays accurate, because if the described behavior ever stops being true, the test fails — unlike a comment or a wiki page, which can silently go stale.

## Levels of automated testing

Automated tests aren't all the same kind of check — they differ in _scope_, which is usually drawn as a pyramid, narrow and plentiful at the bottom, broad and sparse at the top:

- **Unit tests** — test one class or method in isolation, with dependencies faked out (this is exactly what `JUnit` plus `Mockito` give you: Jupiter runs the test, Mockito fakes the collaborators). They're fast and numerous — a healthy codebase might have thousands of these.
- **Integration tests** — test that two or more real components work together correctly: your repository class talking to a real (often test-container) database, or your HTTP client actually hitting a real API. These catch problems unit tests can't, like a wrong SQL query or a mismatched JSON field, but they're slower and there are usually far fewer of them.
- **System / end-to-end tests** — exercise the whole application as a user or external caller would, often through its actual API or UI. These verify that everything wired together behaves correctly, but they're the slowest and most brittle — a small UI change can break an e2e test that has nothing to do with the logic it's meant to check.
- **Acceptance tests** — verify the system meets a specific business requirement, often written in a form stakeholders can read (e.g. "given a cart with $200 of items, when the customer applies a 10% coupon, the total should be $180"). These can be implemented at the unit, integration, or e2e level depending on what's being verified.

The general principle behind the pyramid shape: push coverage as low as it can go. A unit test that catches a bug runs in milliseconds and pinpoints exactly which class is wrong; the same bug caught only by an e2e test might take minutes to run and tell you very little about _where_ the problem is.

## A short note on test doubles

You've already seen this in practice without the formal name: a **test double** is any fake object substituted for a real dependency in a test — a mock (behavior you stub and verify, as with Mockito) is one kind, but there are others: a **stub** (returns canned answers but isn't verified), a **fake** (a working but simplified implementation, like an in-memory list standing in for a database), and a **dummy** (passed in only to satisfy a method signature, never actually used). The term "test double" is the umbrella category; "mock" is specifically the kind that records calls so you can assert they happened.

[[Junit & Mokito]]
