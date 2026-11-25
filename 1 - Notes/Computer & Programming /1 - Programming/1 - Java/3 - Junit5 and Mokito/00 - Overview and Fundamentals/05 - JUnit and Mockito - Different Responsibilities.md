


JUnit and Mockito often get mentioned together so often that people start treating them as one thing, but they solve two completely separate problems. **JUnit is a test framework** — it answers "how do I define a test, run it, and determine pass or fail?" **Mockito is a mocking library** — it answers a completely different question: "how do I replace a real dependency with a fake one I control?" You could use JUnit without ever touching Mockito (plenty of tests don't need any fakes), and conceptually you could use Mockito's mocking mechanics with a different test runner entirely — they're not actually coupled to each other, they just happen to get used together constantly because most real classes have dependencies worth faking.

## JUnit's job: discovery, execution, and verdict

JUnit owns the entire lifecycle of _running_ a test:

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @BeforeEach
    void setUp() { /* ... */ }

    @Test
    void cancelOrderMarksStatusAsCancelled() {
        // test body
    }

    @AfterEach
    void tearDown() { /* ... */ }
}
```

`@Test`, `@BeforeEach`, `@AfterEach` — all of this is JUnit's responsibility. It's what tells your build tool "this method is a test, run it," what guarantees setup happens before and cleanup happens after, and what collects the results into a report. JUnit also owns **assertions** — `assertEquals`, `assertTrue`, `assertThrows` — the mechanism by which a test states "here's what I expect" and gets a pass/fail verdict out of it. None of that requires Mockito at all. A test with zero dependencies to fake — say, testing a pure function like `Calculator.add(2, 3)` — needs only JUnit, start to finish.

## Mockito's job: standing in for dependencies

Mockito's entire responsibility is narrower and more specific: creating objects that _look_ like a real dependency's type but whose behavior you control, and later checking how those fake objects were used.

```java
@Mock
private OrderRepository orderRepository;

@InjectMocks
private OrderService orderService;

@Test
void cancelOrderMarksStatusAsCancelled() {
    Order order = new Order(1L, "pending");
    when(orderRepository.findById(1L)).thenReturn(Optional.of(order));

    orderService.cancelOrder(1L);

    assertEquals("cancelled", order.getStatus());
    verify(orderRepository).save(order);
}
```

`@Mock`, `@InjectMocks`, `when(...).thenReturn(...)`, and `verify(...)` are all Mockito — none of that exists in JUnit. Mockito has no concept of "running a test" or "marking pass/fail" on its own; it just creates and manages fake objects. Notice the division inside that one test method: `when(...).thenReturn(...)` is Mockito setting up fake behavior, `orderService.cancelOrder(1L)` is calling the real code under test, and `assertEquals` / `verify` are the verdict step — the first belonging to JUnit's assertion API, the second to Mockito's call-tracking.

## Where the hand-off happens

`@ExtendWith(MockitoExtension.class)` is the literal seam between the two libraries. It's a JUnit Jupiter extension — JUnit's own plugin mechanism — that Mockito provides so that JUnit knows to process `@Mock` and `@InjectMocks` annotations before each test runs, and to validate mock usage afterward. Without that line, the `@Mock` annotations are just inert fields; JUnit has no idea Mockito exists unless you explicitly hook it in through JUnit's extension system. This is a clean illustration of the separation: Mockito needs JUnit's extension point to get invoked at the right moment, but the actual work of creating the fake object and recording what was called on it is entirely Mockito's own logic, untouched by JUnit.

## What each one cannot do for you

JUnit alone cannot fake a dependency — if `OrderService` depends on a real `OrderRepository` and you only have JUnit, your test either needs a real repository (making it an integration test, not a unit test) or you'd have to hand-write a fake class yourself. Mockito alone cannot run a test or produce a pass/fail report — a `mock()` object with stubbed behavior, sitting by itself with no JUnit (or other runner) around it, is just an inert object; nothing executes it, collects results, or tells you whether anything passed.

## A short note on a related concept: assertion libraries are a third, separate concern

JUnit ships its own assertions (`assertEquals`, `assertTrue`), but many teams swap them for a separate library like **AssertJ**, which gives more fluent, chainable assertions — `assertThat(order.getStatus()).isEqualTo("cancelled")` — while still running inside JUnit's lifecycle and still faking dependencies with Mockito. That's a third independent responsibility worth noticing: test execution (JUnit), faking dependencies (Mockito), and _how you phrase an assertion_ (JUnit's own assertions, or AssertJ, or Hamcrest) are three separate concerns that all happen to coexist inside the same test method, each pluggable independently of the others.



[[Junit & Mokito]]
