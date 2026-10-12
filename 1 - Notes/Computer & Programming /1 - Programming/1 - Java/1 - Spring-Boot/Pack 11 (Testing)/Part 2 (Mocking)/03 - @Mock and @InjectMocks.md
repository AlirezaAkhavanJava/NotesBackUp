

These two annotations work as a pair. **`@Mock`** creates the fakes, and **`@InjectMocks`** builds the real object you're testing and plugs those fakes into it. Together they replace the manual wiring you'd otherwise write by hand.

## `@Mock`: create a fake collaborator

```java
@Mock
PaymentGateway gateway;
```

This is equivalent to writing `gateway = mock(PaymentGateway.class);` yourself, except the annotation is processed for you before each test.

What you get is a fake object where:

- every method returns a default (`null`, `0`, `false`, empty collection, `Optional.empty()`),
- every call is recorded, so you can verify it later,
- nothing real ever runs.

You then customize it per test with stubbing (`given(...).willReturn(...)`).

A fresh mock is created **for every test method**, so stubbing and recorded calls never leak from one test to another.

### It only works when something processes the annotation

Annotations alone do nothing. Something must activate them. The usual way:

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {
    @Mock PaymentGateway gateway;
}
```

Without `@ExtendWith(MockitoExtension.class)`, `gateway` stays `null`, and you get a `NullPointerException` the first time you use it. This is probably the most common beginner mistake. The older alternatives are `MockitoAnnotations.openMocks(this)` in a `@BeforeEach`, or `@RunWith(MockitoJUnitRunner.class)` for JUnit 4.

## `@InjectMocks`: build the object under test

```java
@InjectMocks
OrderService service;
```

Mockito creates a **real** `OrderService` and tries to fill it with the mocks declared in the test class. It tries three strategies, in this order:

1. **Constructor injection**: it picks the _biggest_ constructor and passes mocks for the parameters it can match by type. If no mock matches a parameter, that parameter gets `null`.
2. **Setter (property) injection**: if constructor injection wasn't used, it calls setters whose types match a mock.
3. **Field injection**: as a last resort, it sets fields directly, even private ones, by type (and by name if several candidates share a type).

Only one strategy is used. If constructor injection succeeds, Mockito stops there and doesn't also try setters or fields.

### Example

```java
public class OrderService {
    private final PaymentGateway gateway;
    private final OrderRepository repository;

    public OrderService(PaymentGateway gateway, OrderRepository repository) {
        this.gateway = gateway;
        this.repository = repository;
    }
}
```

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock PaymentGateway gateway;
    @Mock OrderRepository repository;

    @InjectMocks OrderService service;   // new OrderService(gateway, repository)
}
```

Mockito matches the constructor parameters to the mocks **by type**, so you don't need to name or order anything.

## The manual equivalent

It helps to see what the annotations save you:

```java
class OrderServiceTest {

    PaymentGateway gateway = mock(PaymentGateway.class);
    OrderRepository repository = mock(OrderRepository.class);
    OrderService service = new OrderService(gateway, repository);
}
```

Both versions behave the same. The manual one is more explicit and has no hidden magic, which is why many experienced developers prefer it for small classes. The annotations pay off when you have several mocks and many tests.

## Rules and gotchas

**1. `@InjectMocks` fails silently.**  
If Mockito can't satisfy a dependency, it doesn't throw a clear error. It leaves a `null` and carries on. You then see a `NullPointerException` deep inside your service, far from the real cause. If you ever hit one, check whether the mock was actually injected, or just switch to `new`.

**2. Matching is by type, then by name.**  
If two mocks have the same type, Mockito can't know which goes where by type alone, so it falls back to matching the **field name** against the mock's name:

```java
@Mock PaymentGateway primaryGateway;
@Mock PaymentGateway backupGateway;   // same type, so names must line up with the target's fields
```

This is fragile. Two mocks of the same type in one test is often a hint to rethink the design.

**3. Mockito won't mix strategies.**  
If your class has a constructor taking only the repository, and a separate setter for the gateway, Mockito uses the constructor and **leaves the gateway unset**. This catches people who half-migrate from field injection to constructor injection.

**4. `@InjectMocks` isn't for interfaces.**  
It needs a concrete class to instantiate. The field's type must be the real class under test.

**5. Don't put `@Mock` on the class under test.**  
The object under test must be real. If it's a mock, you're testing nothing.

**6. Only use it for the class under test.**  
Don't put `@InjectMocks` on a collaborator. It's meant for the single subject of the test.

## Quick comparison

||`@Mock`|`@InjectMocks`|
|---|---|---|
|Creates|A fake object|A real object|
|Used for|Collaborators (gateway, repository)|The class under test|
|Methods run real code?|No|Yes|
|Requires|Mockito extension/runner|Mockito extension/runner, plus `@Mock` fields to inject|

## How it differs from Spring's annotations

These are **plain Mockito** annotations and know nothing about Spring. They work in a test with no application context, which is why such tests run in milliseconds.

If you need to replace a bean inside a running Spring context (for example in `@WebMvcTest`), use **`@MockitoBean`** (or `@MockBean` on older Spring Boot versions), not `@Mock`. A rule of thumb: `@Mock` for tests without Spring, `@MockitoBean` for tests with Spring.

## When to skip `@InjectMocks`

- **The class has one or two dependencies.** Writing `new OrderService(gateway, repository)` is just as short and completely clear.
- **You want to see the construction.** Explicit code makes it obvious when a constructor changes.
- **You hit the silent-`null` problem.** Switching to `new` makes the failure loud and immediate.

A reasonable default: use `@Mock` freely, and use `@InjectMocks` when it keeps the test tidy, but fall back to `new` the moment it confuses you.

## Common errors

|Symptom|Likely cause|
|---|---|
|`NullPointerException` on a `@Mock` field in the test|Missing `@ExtendWith(MockitoExtension.class)`|
|`NullPointerException` inside the service|`@InjectMocks` couldn't inject a dependency (missing `@Mock`, type mismatch, mixed injection strategies)|
|`UnnecessaryStubbingException`|A stub was set up but never used by the code|
|Wrong mock injected when two share a type|Field names don't match, so rename or construct manually|





[[Spring Framework]]
[[Testing]]