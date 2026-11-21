

Given / When / Then is a way of describing a test as a tiny story about behavior. Each word names one part of that story:

- **Given**: the starting situation, meaning the state of the world before anything happens.
- **When**: the single action or event that you're testing.
- **Then**: the outcome you expect to observe afterward.

It reads like plain English: _"Given this situation, when this happens, then I expect that result."_

## How it maps to what we already saw

If you remember **Arrange, Act, Assert** from the first answer, this is the same rhythm with different vocabulary:

|Given / When / Then|Arrange / Act / Assert|
|---|---|
|**Given**: set up the situation|**Arrange**: create objects, stubs, inputs|
|**When**: perform the action|**Act**: call the method|
|**Then**: check the outcome|**Assert**: verify results|

The structure is identical. The difference is in the _mindset_. Arrange/Act/Assert talks about code mechanics, while Given/When/Then talks about **behavior** in language that a non-programmer (a product owner, a tester, a client) could read and agree with. That's why it comes from **BDD (Behavior-Driven Development)**, where tests double as shared specifications.

## Example from our registration feature

In words:

> **Given** a user with the email `ana@example.com` is already registered,  
> **When** someone registers again with that same email,  
> **Then** the registration is rejected and nothing is saved.

And as a Java test:

```java
@Test
void rejectsDuplicateEmail() {
    // Given
    when(repository.existsByEmail("ana@example.com")).thenReturn(true);

    // When
    Executable registering = () -> service.register("Ana", "ana@example.com");

    // Then
    assertThrows(EmailAlreadyUsedException.class, registering);
    verify(repository, never()).save(any());
}
```

Notice how the comments tell the whole story. Someone reading only those three lines of prose understands the rule without reading the code.

## Mockito's BDD style

Mockito has a built-in vocabulary for this, `BDDMockito`, so the code itself reads as Given/When/Then:

```java
import static org.mockito.BDDMockito.*;

@Test
void registersNewUser() {
    // Given
    given(repository.existsByEmail("ana@example.com")).willReturn(false);
    given(repository.save(any(User.class))).willAnswer(inv -> inv.getArgument(0));

    // When
    User saved = service.register("Ana", "ana@example.com");

    // Then
    assertEquals("ana@example.com", saved.getEmail());
    then(repository).should().save(any(User.class));
}
```

`given(...)` replaces `when(...)`, which avoids the confusing situation where the word "when" appears in the _Given_ section. `then(...).should()` replaces `verify(...)`. It's purely cosmetic, but it makes the structure much clearer.

## Rules of thumb

- **One When per test.** If you find two actions, you're probably testing two behaviors and should split them. A test with several Whens is hard to name and hard to debug.
- **Given describes state, not steps.** Keep it to what must be true for the scenario to make sense.
- **Then checks outcomes, not internals.** "The user is rejected" is a behavior; "method X was called three times" is usually an implementation detail.
- **Use "And" to extend a section.** _Given a registered user, **and** the account is active, **when**..._ is perfectly normal.

## Beyond Java code: Gherkin and Cucumber

The same keywords are used in a more formal way in **Gherkin**, the language of tools like **Cucumber**. There, scenarios are written in plain text files:

```gherkin
Scenario: Duplicate email is rejected
  Given a user with email "ana@example.com" is already registered
  When a new user registers with email "ana@example.com"
  Then the registration is rejected
  And no new user is saved
```

Each line is then linked to Java code ("step definitions") that actually performs it. That's useful when business people or QA write and review scenarios, but it adds overhead. For most developer-owned unit tests, just using Given/When/Then as **comments or naming style** in plain JUnit gives you most of the benefit with none of the tooling.

## Naming tests in this style

Some teams encode the structure directly in test names:

```java
void givenEmailAlreadyUsed_whenRegistering_thenThrowsException() { ... }
```

It's verbose, but it makes failures self-explanatory in the test report. Others prefer short behavior names like `rejectsDuplicateEmail` and keep the Given/When/Then as comments in the body. Both are valid. Pick one convention per project and stick to it.




[[Testing]]
[[Spring Framework]]