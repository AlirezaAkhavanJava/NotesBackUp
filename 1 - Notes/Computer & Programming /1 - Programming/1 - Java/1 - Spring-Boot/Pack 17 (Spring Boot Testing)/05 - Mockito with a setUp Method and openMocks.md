

Before `MockitoExtension` existed, you had to activate the annotations yourself. That's what `MockitoAnnotations.openMocks(this)` does inside a `@BeforeEach` method. You'll see this pattern in older codebases, in JUnit 4 projects, and in tests that can't use the extension, so it's worth understanding well.

## The problem it solves

Annotations like `@Mock` and `@InjectMocks` are just markers. Something has to read them and create the objects. Without that step:

```java
class OrderServiceTest {

    @Mock PaymentGateway gateway;        // stays null
    @InjectMocks OrderService service;   // stays null

    @Test
    void test() {
        service.placeOrder("c-1", 50.0);   // NullPointerException
    }
}
```

`openMocks(this)` is the call that scans the test class, creates every `@Mock`, `@Spy`, and `@Captor`, and injects them into the `@InjectMocks` field.

## The setUp pattern

```java
import org.junit.jupiter.api.*;
import org.mockito.*;

class OrderServiceTest {

    @Mock PaymentGateway gateway;
    @Mock OrderRepository repository;
    @InjectMocks OrderService service;

    private AutoCloseable closeable;

    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
    }

    @AfterEach
    void tearDown() throws Exception {
        closeable.close();
    }

    @Test
    void placesOrderWhenPaymentSucceeds() {
        given(gateway.charge("c-1", 50.0)).willReturn(true);
        given(repository.save(any(Order.class)))
                .willAnswer(inv -> inv.getArgument(0));

        Order result = service.placeOrder("c-1", 50.0);

        assertEquals("c-1", result.customerId());
    }
}
```

Step by step:

1. **`@BeforeEach`** runs before every test method, so each test gets fresh mocks.
2. **`openMocks(this)`** initializes all the annotated fields on this test instance.
3. It **returns an `AutoCloseable`**, which we keep in a field.
4. **`@AfterEach`** calls `close()` to release resources and clean up the mocks.

## Why close it?

`openMocks` returns something closeable because Mockito may hold resources (and, in some setups, static or construction mocks) that should be released after each test. Skipping `close()` usually works, but it can leak state between tests in more advanced cases, so the clean pattern is to always close it.

## `initMocks` vs `openMocks`

You'll see an older method in a lot of tutorials:

```java
MockitoAnnotations.initMocks(this);   // old
```

- **`initMocks`** was deprecated in Mockito 3.4 and later **removed in Mockito 4**.
- **`openMocks`** is the replacement and returns the `AutoCloseable` described above.

If you copy old code and `initMocks` doesn't compile, swap it for `openMocks`.

## Do the same thing without a field for the closeable

Some people avoid the extra field with a try-with-resources approach, but that doesn't fit the `@BeforeEach`/`@AfterEach` lifecycle, so the field version above is the standard. A shorter variant is also common if you don't care about closing:

```java
@BeforeEach
void setUp() {
    MockitoAnnotations.openMocks(this);
}
```

It works, but you give up the cleanup.

## `setUp` vs `MockitoExtension`: what's different?

||`openMocks` in `setUp`|`@ExtendWith(MockitoExtension.class)`|
|---|---|---|
|Boilerplate|Setup and teardown methods|One annotation|
|Strict stubs (`UnnecessaryStubbingException`)|**Off** by default|**On** by default|
|Cleanup|You close it manually|Automatic|
|JUnit 4|Works|Use `MockitoJUnitRunner` instead|
|Best for|Legacy code, special setups|New JUnit 5 tests|

The biggest practical difference is **strictness**. With `openMocks`, an unused stub is silently ignored, so stale setup can pile up unnoticed. The extension flags it. That's the main reason to prefer the extension in new code.

If you want strictness while using `openMocks`, you can add a rule or session, but at that point you're rebuilding what the extension already does.

## Using `setUp` for more than just `openMocks`

The setUp method is also the natural home for shared arrangement, for example creating a common test object:

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock PaymentGateway gateway;
    @Mock OrderRepository repository;

    OrderService service;
    Order sampleOrder;

    @BeforeEach
    void setUp() {
        service = new OrderService(gateway, repository);   // manual construction
        sampleOrder = new Order(1L, "c-1", 50.0);
    }
}
```

Note that here `@Mock` is still handled by the extension, while `setUp` is used only for constructing things yourself. This is a very common, clean combination, and it lets you skip `@InjectMocks` entirely.

### A warning about stubbing in `setUp`

You might be tempted to put stubs in `@BeforeEach`:

```java
@BeforeEach
void setUp() {
    given(gateway.charge(anyString(), anyDouble())).willReturn(true);
}
```

With strict stubs, any test that doesn't use that stub fails with `UnnecessaryStubbingException`. Your options:

- Stub inside each test that needs it (clearest, and my default recommendation).
- Use `lenient().when(...)` in `setUp` if the stub is truly shared.
- Keep `setUp` for objects, not behavior.

## Creating mocks manually in `setUp`

You can skip annotations altogether:

```java
class OrderServiceTest {

    PaymentGateway gateway;
    OrderRepository repository;
    OrderService service;

    @BeforeEach
    void setUp() {
        gateway = mock(PaymentGateway.class);
        repository = mock(OrderRepository.class);
        service = new OrderService(gateway, repository);
    }
}
```

No extension, no `openMocks`, no `AutoCloseable`. Everything is visible. For small classes this is perfectly fine and has no hidden behavior. The tradeoff is more lines per mock, and no strict stubs.

## JUnit 4 equivalent

If you maintain older code, the same ideas look like this:

```java
@RunWith(MockitoJUnitRunner.class)
public class OrderServiceTest {
    @Mock PaymentGateway gateway;
    @InjectMocks OrderService service;
}
```

or with `openMocks`:

```java
public class OrderServiceTest {

    private AutoCloseable closeable;

    @Before
    public void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
    }

    @After
    public void tearDown() throws Exception {
        closeable.close();
    }
}
```

The annotations are `@Before` and `@After` in JUnit 4, versus `@BeforeEach` and `@AfterEach` in JUnit 5.

## Which should you use?

For a new JUnit 5 / Spring Boot project:

1. **Default:** `@ExtendWith(MockitoExtension.class)` with `@Mock`, and either `@InjectMocks` or `new` in `setUp`.
2. **Use `openMocks` in `setUp`** when you're in a JUnit 4 project, maintaining old tests, or can't use the extension.
3. **Use plain `mock(...)` calls** when you want zero magic on a small test.

## Common mistakes

- **Using both the extension and `openMocks`.** The mocks get initialized twice, which can cause confusing behavior. Pick one.
- **Forgetting `@BeforeEach`.** Calling `openMocks` in a constructor or a static block means mocks aren't reset per test.
- **Calling `initMocks` on Mockito 4 or later.** It no longer exists, so use `openMocks`.
- **Not importing the JUnit 5 annotations.** `@BeforeEach` comes from `org.junit.jupiter.api`, while `@Before` is the JUnit 4 one. Mixing them means your setup silently never runs.





[[Testing]]
[[Spring Framework]]