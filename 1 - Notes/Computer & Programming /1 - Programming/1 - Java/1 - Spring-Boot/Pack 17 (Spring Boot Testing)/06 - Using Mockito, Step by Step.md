

We'll build up one example from nothing: a service that places an order by charging a payment gateway and saving the order. At each step you'll add one Mockito concept, so you can see why it exists.

## Step 0: The code we want to test

```java
public interface PaymentGateway {
    boolean charge(String customerId, double amount);
}

public interface OrderRepository {
    Order save(Order order);
}

public record Order(Long id, String customerId, double amount) {}

public class OrderService {
    private final PaymentGateway gateway;
    private final OrderRepository repository;

    public OrderService(PaymentGateway gateway, OrderRepository repository) {
        this.gateway = gateway;
        this.repository = repository;
    }

    public Order placeOrder(String customerId, double amount) {
        if (!gateway.charge(customerId, amount)) {
            throw new PaymentFailedException();
        }
        return repository.save(new Order(null, customerId, amount));
    }
}

public class PaymentFailedException extends RuntimeException {}
```

`OrderService` depends on two collaborators. We don't want a real payment provider or database in a unit test, so we'll fake both with Mockito.

## Step 1: Make sure Mockito is available

In a Spring Boot project, `spring-boot-starter-test` already includes Mockito, JUnit 5, and AssertJ. Nothing to add.

Outside Spring Boot, with Maven:

```xml
<dependency>
    <groupId>org.mockito</groupId>
    <artifactId>mockito-junit-jupiter</artifactId>
    <version>5.x.x</version>
    <scope>test</scope>
</dependency>
```

(Use the current 5.x release; the `mockito-junit-jupiter` artifact brings in `mockito-core` too.)

## Step 2: Create the test class and the mocks

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.*;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    PaymentGateway gateway;

    @Mock
    OrderRepository repository;

    @InjectMocks
    OrderService service;
}
```

What each piece does:

- `@ExtendWith(MockitoExtension.class)` tells JUnit to create the mocks before each test and to enable strict checking.
- `@Mock` creates a fake `PaymentGateway` and a fake `OrderRepository`.
- `@InjectMocks` builds a real `OrderService` and passes those mocks into its constructor.

At this point both mocks are "blank": every method returns a default (`false`, `null`, `0`).

## Step 3: Write your first test, stubbing a return value

We'll test the happy path. We need the gateway to say "payment succeeded" and the repository to hand back the saved order.

```java
@Test
void placesOrderWhenPaymentSucceeds() {
    // Given: the gateway accepts the payment, and the repository returns what it's given
    given(gateway.charge("c-1", 50.0)).willReturn(true);
    given(repository.save(any(Order.class)))
            .willAnswer(invocation -> invocation.getArgument(0));

    // When
    Order result = service.placeOrder("c-1", 50.0);

    // Then
    assertEquals("c-1", result.customerId());
    assertEquals(50.0, result.amount());
}
```

Two new things here:

- **`given(...).willReturn(...)`** is stubbing: "when this call happens, return this."
- **`any(Order.class)`** is an _argument matcher_: "I don't care which `Order`, any one will do." We use it because the service creates the `Order` internally, so we can't construct the exact same instance ahead of time.
- **`willAnswer(...)`** computes the return value from the call's arguments. Here it simply echoes the saved order back, like a real repository would.

Run it. It should pass.

## Step 4: Verify that a side effect happened

The test above checks the _result_. But did the service actually save the order? A result alone might not prove it, so add a **verification**:

```java
@Test
void savesOrderWhenPaymentSucceeds() {
    given(gateway.charge("c-1", 50.0)).willReturn(true);
    given(repository.save(any(Order.class)))
            .willAnswer(invocation -> invocation.getArgument(0));

    service.placeOrder("c-1", 50.0);

    then(repository).should().save(any(Order.class));
}
```

`then(mock).should().method(...)` reads as "the mock should have received this call exactly once." If the call never happened, you get a `WantedButNotInvoked` error.

## Step 5: Stub an unhappy path

Now the failure case: the payment is declined.

```java
@Test
void throwsWhenPaymentFails() {
    given(gateway.charge("c-1", 50.0)).willReturn(false);

    assertThrows(PaymentFailedException.class,
            () -> service.placeOrder("c-1", 50.0));
}
```

You didn't stub `repository.save`, and you don't need to: the service should never reach it. That leads to the next step.

## Step 6: Verify that something did _not_ happen

The most important thing about a declined payment is that **no order gets saved**. Prove it:

```java
@Test
void doesNotSaveOrderWhenPaymentFails() {
    given(gateway.charge("c-1", 50.0)).willReturn(false);

    assertThrows(PaymentFailedException.class,
            () -> service.placeOrder("c-1", 50.0));

    then(repository).should(never()).save(any());
    // or, even stricter: then(repository).shouldHaveNoInteractions();
}
```

Tests like this catch a real bug class: code that charges, fails, and saves anyway.

## Step 7: Make a mock throw

What if the gateway itself blows up, for example a network timeout?

```java
@Test
void propagatesGatewayErrors() {
    given(gateway.charge(anyString(), anyDouble()))
            .willThrow(new IllegalStateException("gateway down"));

    assertThrows(IllegalStateException.class,
            () -> service.placeOrder("c-1", 50.0));

    then(repository).shouldHaveNoInteractions();
}
```

Note the matchers `anyString()` and `anyDouble()`. Remember the rule: if one argument uses a matcher, **all** arguments must use matchers (`eq("c-1")` for an exact value).

## Step 8: Capture an argument to inspect it

Suppose you want to check exactly _what_ was saved, not just that something was. Use an `ArgumentCaptor`:

```java
@Captor
ArgumentCaptor<Order> orderCaptor;

@Test
void savesOrderWithCorrectDetails() {
    given(gateway.charge("c-1", 50.0)).willReturn(true);
    given(repository.save(any(Order.class)))
            .willAnswer(invocation -> invocation.getArgument(0));

    service.placeOrder("c-1", 50.0);

    then(repository).should().save(orderCaptor.capture());
    Order saved = orderCaptor.getValue();
    assertEquals("c-1", saved.customerId());
    assertEquals(50.0, saved.amount());
}
```

The captor records the argument passed to `save`, and `getValue()` hands it back so you can assert on it freely.

## Step 9: Check the order of calls (when it matters)

If the sequence is part of the behavior (charge _before_ save), use `InOrder`:

```java
@Test
void chargesBeforeSaving() {
    given(gateway.charge("c-1", 50.0)).willReturn(true);
    given(repository.save(any(Order.class)))
            .willAnswer(invocation -> invocation.getArgument(0));

    service.placeOrder("c-1", 50.0);

    InOrder inOrder = inOrder(gateway, repository);
    inOrder.verify(gateway).charge("c-1", 50.0);
    inOrder.verify(repository).save(any(Order.class));
}
```

Don't use this by default. Only reach for it when a wrong order would be a real bug.

## Step 10: Read the failures

Mockito's error messages are detailed, so it's worth learning to read them. If you deliberately change the stub to `given(gateway.charge("c-2", 50.0))` and run the happy-path test, the service calls `charge("c-1", 50.0)`, which doesn't match, and `charge` returns `false`. The test fails with `PaymentFailedException`. With strict stubs on, Mockito also reports a `PotentialStubbingProblem`, telling you the stub was set up for different arguments than the actual call used. That hint usually points straight at the typo.

Likewise, if you stub something and the code never calls it, you get `UnnecessaryStubbingException`, which means the test setup and the code disagree.

## The complete test class

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock PaymentGateway gateway;
    @Mock OrderRepository repository;
    @InjectMocks OrderService service;

    @Captor ArgumentCaptor<Order> orderCaptor;

    @Test
    void placesOrderWhenPaymentSucceeds() {
        given(gateway.charge("c-1", 50.0)).willReturn(true);
        given(repository.save(any(Order.class)))
                .willAnswer(inv -> inv.getArgument(0));

        Order result = service.placeOrder("c-1", 50.0);

        assertEquals("c-1", result.customerId());
        then(repository).should().save(orderCaptor.capture());
        assertEquals(50.0, orderCaptor.getValue().amount());
    }

    @Test
    void doesNotSaveOrderWhenPaymentFails() {
        given(gateway.charge("c-1", 50.0)).willReturn(false);

        assertThrows(PaymentFailedException.class,
                () -> service.placeOrder("c-1", 50.0));

        then(repository).shouldHaveNoInteractions();
    }

    @Test
    void propagatesGatewayErrors() {
        given(gateway.charge(anyString(), anyDouble()))
                .willThrow(new IllegalStateException("gateway down"));

        assertThrows(IllegalStateException.class,
                () -> service.placeOrder("c-1", 50.0));

        then(repository).shouldHaveNoInteractions();
    }
}
```

## The recipe in short

For any test with Mockito, follow the same loop:

1. **Mock** the collaborators (`@Mock`).
2. **Inject** them into the class under test (`@InjectMocks` or `new`).
3. **Stub** only what the scenario needs (`given(...).willReturn/willThrow/willAnswer`).
4. **Act** by calling the method under test.
5. **Assert** on the result first.
6. **Verify** the side effects that matter (`then(...).should(...)`, `never()`).

## Mistakes to avoid while you practice

- **Stubbing things the test doesn't use.** Strict mode will fail the test, and that's the signal to delete the stub.
- **Verifying everything.** If you verify every internal call, refactoring breaks tests that were never wrong.
- **Forgetting `eq(...)` when mixing matchers and raw values.**
- **Mocking simple data objects** like `Order`. Create real ones.

## Practice exercise

Add a rule: orders over 1000 require approval, so `placeOrder` should throw `ApprovalRequiredException` and never charge the gateway. Write the test first (red), watch it fail, then add the code (green). It combines TDD, `assertThrows`, and `then(gateway).shouldHaveNoInteractions()` in one small exercise.




[[Testing]]
[[Spring Framework]]