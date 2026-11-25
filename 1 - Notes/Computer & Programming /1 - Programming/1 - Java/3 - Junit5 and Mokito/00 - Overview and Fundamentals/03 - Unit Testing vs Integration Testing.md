

Both unit tests and integration tests are automated tests, but they differ in **what they include in scope** — specifically, whether real dependencies are allowed to participate or whether everything outside the thing being tested gets replaced with a fake.

A **unit test** isolates a single class or method and replaces everything it depends on with test doubles (mocks, stubs, fakes), so the test verifies only that one unit's logic. An **integration test** lets two or more real components interact — your repository talking to an actual database, your HTTP client hitting an actual running service — to verify that the _wiring between_ components works, not just each piece's internal logic.

Neither is "better" — they catch fundamentally different classes of bugs, which is the whole reason both exist.

## Unit test example

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

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
}
```

Here `orderRepository` is a Mockito mock — there's no database anywhere in this test. It runs in a few milliseconds, and if it fails, the bug is guaranteed to be inside `OrderService`'s own logic, because the repository is just a stand-in programmed to return exactly what the test told it to.

## Integration test example

```java
@SpringBootTest
@Testcontainers
class OrderRepositoryIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:16");

    @Autowired
    private OrderRepository orderRepository;

    @Test
    void findByIdReturnsSavedOrder() {
        Order saved = orderRepository.save(new Order("pending"));

        Optional<Order> found = orderRepository.findById(saved.getId());

        assertTrue(found.isPresent());
        assertEquals("pending", found.get().getStatus());
    }
}
```

This test is slower — it starts a real PostgreSQL instance in a container and goes through a real `EntityManager`, real SQL, a real connection pool. There's no mock here: `orderRepository` is the actual Spring Data implementation, backed by an actual database. This test exists to catch things a unit test fundamentally _cannot_ catch: a wrong column mapping, a query that works in H2 but breaks on PostgreSQL's stricter type rules, a missing index that silently returns the wrong row, or a transaction that doesn't commit when you expected it to.

## What each one actually catches

- A unit test catches: wrong business logic, an off-by-one error, a branch of an `if` statement that was never meant to execute, a miscalculated total. It cannot catch: whether your SQL query is syntactically valid, whether your JSON serialization matches what the real API expects, whether two services agree on a field name.
- An integration test catches: broken wiring between components — a mismatched schema, a misconfigured bean, two services disagreeing about a contract, a query that's logically fine in Java but wrong in SQL. It's generally _worse_ at catching deep logic errors inside one class, because by the time a failure surfaces, it could be caused by any of several real components interacting, which makes integration test failures harder to pinpoint than unit test failures.

## Speed and quantity — why the pyramid shape exists

Unit tests are fast (milliseconds, no I/O) and cheap to write, so a codebase typically has thousands of them, run on every single file save or commit. Integration tests are slower — starting a container, hitting a real network call, waiting for a real transaction — so a codebase has far fewer of them, often run only before merging or deploying, not on every keystroke. This is the basis of the "test pyramid" idea: most of your confidence should come from a large base of fast unit tests, with a smaller number of integration tests covering the seams where components meet, because if you tried to cover everything with integration tests, your test suite would take so long to run that nobody would run it often enough for it to be useful.

## A short note on a related concept: system/end-to-end tests

One level broader than integration tests is the **system (or end-to-end) test** — it exercises the whole running application the way a real client would, often hitting a deployed API or driving an actual browser against the UI. It differs from an integration test mainly in scope: an integration test typically checks one seam (your code talking to one real dependency, like a database), while an end-to-end test checks the entire chain from the outside in. These are the slowest and most brittle of all — a one-line UI change can break an e2e test that has nothing to do with the behavior it's actually meant to verify — which is why there are usually the fewest of these in any test suite.


[[Junit6]]
