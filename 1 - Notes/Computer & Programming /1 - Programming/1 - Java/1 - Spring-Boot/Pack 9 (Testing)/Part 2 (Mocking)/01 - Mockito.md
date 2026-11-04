

Mockito is the most widely used mocking library in the Java world, and it's already included in `spring-boot-starter-test`, so you have it in any Spring Boot project. You've seen pieces of it in the last few answers, so this time I'll focus on **how it works and how to think about it**, then fill in the parts we haven't covered.

## The big idea

Mockito lets you create a **fake version of a class or interface** at runtime. You then do two things with it:

1. **Stub**: tell it how to behave ("when called with X, return Y").
2. **Verify**: ask it afterwards what happened ("was it called with X?").

That's the whole library. Everything else is detail on top of those two ideas.

## How it works under the hood

When you write `mock(UserRepository.class)`, Mockito generates a subclass (or, with its default inline mock maker in recent versions, instruments the class) whose methods don't run real code. Instead each call is **recorded** and checked against your stubbing rules.

That explains several behaviors that otherwise seem odd:

- An unstubbed method returns a default (`null`, `0`, `false`, an empty collection, `Optional.empty()`).
- Mocks remember every call, which is what makes `verify` possible.
- Since Mockito 5, the inline mock maker is the default, so you can mock `final` classes and methods without extra setup. In older versions you needed a config file for that.

## Setting it up

**Without Spring (fastest):**

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock PaymentGateway gateway;
    @Mock OrderRepository repository;

    @InjectMocks OrderService service;
    ...
}
```

**Manually, without annotations:**

```java
PaymentGateway gateway = mock(PaymentGateway.class);
OrderService service = new OrderService(gateway, repository);
```

The manual form is perfectly fine and sometimes clearer, since you see exactly how the object is constructed. `@InjectMocks` tries constructor injection first, then setters, then fields, and it fails _silently_ if it can't satisfy something, leaving a `null`. That is a common source of confusing `NullPointerException`s, so if `@InjectMocks` ever acts strange, just switch to `new`.

## Stubbing in more depth

You've seen `given(...).willReturn(...)`. Here are the other tools you'll need:

```java
// Matchers: match arguments flexibly
given(repository.findByEmail(anyString())).willReturn(Optional.of(user));
given(gateway.charge(eq("EUR"), gt(0.0))).willReturn(true);

// Custom logic based on the arguments
given(repository.save(any(User.class)))
        .willAnswer(inv -> inv.getArgument(0));

// Chained results on consecutive calls
given(gateway.charge(anyDouble()))
        .willReturn(false)
        .willReturn(true);

// Throwing
given(gateway.charge(anyDouble())).willThrow(new PaymentFailedException());

// Void methods: the "do" family
willThrow(new MailException()).given(emailSender).send(any());
willDoNothing().given(emailSender).send(any());
```

**The matcher rule that bites everyone:** if you use a matcher for one argument, you must use matchers for _all_ of them.

```java
// Wrong: mixes a raw value and a matcher
given(gateway.charge("EUR", anyDouble()))

// Right
given(gateway.charge(eq("EUR"), anyDouble()))
```

## Verification in more depth

```java
then(gateway).should().charge(100.0);               // exactly once (default)
then(gateway).should(times(2)).charge(anyDouble());
then(gateway).should(atLeastOnce()).charge(anyDouble());
then(gateway).should(never()).refund(any());
then(gateway).shouldHaveNoMoreInteractions();       // nothing else happened
then(emailSender).shouldHaveNoInteractions();       // never touched
```

When order matters, use `InOrder`:

```java
InOrder inOrder = inOrder(repository, emailSender);
inOrder.verify(repository).save(any(User.class));
inOrder.verify(emailSender).send(any());
```

This proves "save, _then_ email", for example, which can matter if sending the email before a successful save would be a bug.

## Argument captors

When the object under inspection is created _inside_ the method you test, capture it:

```java
@Captor ArgumentCaptor<Order> orderCaptor;

@Test
void savesOrderWithCorrectTotal() {
    service.placeOrder(cart);

    then(repository).should().save(orderCaptor.capture());
    assertEquals(150.0, orderCaptor.getValue().getTotal());
}
```

Captors shine when you want several assertions on one argument. Writing a custom matcher for that would be much clumsier.

## Mocks, spies, and the real thing

- **Mock**: a total fake. Nothing real runs.
- **Spy**: wraps a real object. Real methods run unless you stub them.

```java
List<String> real = new ArrayList<>();
List<String> spy = spy(real);

spy.add("a");
then(spy).should().add("a");     // verified, and it really was added
assertEquals(1, spy.size());
```

One gotcha with spies: to stub a method _without_ triggering the real one during setup, use the "do" style:

```java
// Dangerous: this actually calls the real method while stubbing
given(spy.expensiveCall()).willReturn("fake");

// Safe
willReturn("fake").given(spy).expensiveCall();
```

## Strictness: Mockito watching your back

With `MockitoExtension`, Mockito runs in **strict stubs** mode:

- A stub you set up but never use fails the test with `UnnecessaryStubbingException`.
- Calling a stubbed method with _different arguments_ than you stubbed produces a `PotentialStubbingProblem` hint.

This is a feature, not a nuisance. Unused stubs usually mean the test isn't exercising what you think, or that setup has gone stale after a refactor. If a stub is legitimately only used in some tests (for example in a `@BeforeEach`), you can mark it with `lenient()`:

```java
lenient().when(clock.millis()).thenReturn(1000L);
```

Use `lenient()` sparingly, because every one is a small hole in that safety net.

## Features worth knowing about

**Mocking static methods** (needs the inline mock maker, which is the default in Mockito 5):

```java
try (MockedStatic<UUID> mocked = mockStatic(UUID.class)) {
    mocked.when(UUID::randomUUID).thenReturn(fixedUuid);
    // code under test here
}
```

The `try` block matters: the static mock is active only inside it and is thread-local. Still, this is a last resort. If you can inject a `Clock` or an ID generator instead, the design gets better and you avoid static mocking entirely.

**Deep stubs** let you stub a chain of calls in one go:

```java
Order order = mock(Order.class, RETURNS_DEEP_STUBS);
given(order.getCustomer().getAddress().getCity()).willReturn("Madrid");
```

It's tempting, but a chain like that is a design smell (a Law of Demeter violation). Needing deep stubs often means the code under test reaches too far into other objects.

**Default answers** change what unstubbed methods return, for example `RETURNS_SMART_NULLS` gives a descriptive failure instead of a bare `NullPointerException`.

**Timeouts** for asynchronous code: `verify(service, timeout(500)).process()` waits up to 500 ms for the call to happen.

## Where Spring fits in

Mockito itself knows nothing about Spring. Spring adds `@MockitoBean` and `@MockitoSpyBean` (and the older `@MockBean` / `@SpyBean`), which create a Mockito mock _and register it as a bean in the application context_. Under the hood, you're still using Mockito's `given`, `then`, `ArgumentCaptor`, and the rest, so everything above applies to those mocks too.

## Mockito's limits (by design)

Mockito deliberately won't do some things, and that is meant to nudge you toward better code:

- It can't mock constructors by default (there's `mockConstruction`, but treat it as a last resort).
- Mocking private methods isn't supported. If you feel the need, the logic probably belongs in its own class.
- It can't make a mock "real" partway through a test.

## Habits that keep Mockito tests healthy

- **Mock roles, not data.** Mock collaborators like `PaymentGateway`. Don't mock `User` or `Money`, just create real ones.
- **Stub what the test needs, nothing more.** Each extra stub is noise that hides the point of the test.
- **Verify outcomes first, interactions second.** Prefer `assertEquals(result, ...)` where you can, and use `verify` for side effects that _are_ the behavior (an email sent, nothing saved).
- **Watch the mock-to-assertion ratio.** If a test has ten lines of stubbing and one assertion, step back and look at the design.
- **Use `BDDMockito`** (`given`/`then`) if you like Given/When/Then, as we discussed earlier. It's the same engine with clearer vocabulary.

## Common errors and what they mean

|Error|Usual cause|
|---|---|
|`NullPointerException` on a mock result|Unstubbed method returned `null`, or the stub's arguments didn't match|
|`InvalidUseOfMatchersException`|Mixed raw values and matchers in one call|
|`UnnecessaryStubbingException`|A stub was never used (strict mode), so remove it or fix the test|
|`WantedButNotInvoked`|The code never made the call you verified, or used different arguments|
|`MissingMethodInvocationException`|You called `when(...)` on something that isn't a mock|
|`NotAMockException`|`verify` or `given` on a real object (use `spy`)|

If you'd like, I can walk you through a complete worked example of a service with several collaborators, written step by step with Mockito, or compare Mockito with alternatives like hand-written fakes so you can judge when each is the better fit.


[[Testing]]
[[Spring Framework]]