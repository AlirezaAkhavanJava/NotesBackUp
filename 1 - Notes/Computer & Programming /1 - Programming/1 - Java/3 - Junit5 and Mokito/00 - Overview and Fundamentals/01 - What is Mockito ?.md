

When you unit test a class, you want to test _that class's own logic_ in isolation — not the logic of everything it depends on. But real classes usually depend on other things: a repository that hits a database, an HTTP client that calls another service, a clock that returns the current time. If your test actually goes through those dependencies, it stops being a fast, isolated unit test and becomes something closer to an integration test — slow, flaky, and testing more than one thing at once.

Mockito solves this by letting you create **fake, controllable substitutes** for a class's dependencies, called **mocks**. A mock looks like the real object (it has the same type), but instead of running real logic, you tell it exactly what to return when its methods are called. This lets you test one class completely on its own, while pretending its dependencies behave however the test needs them to.

## Creating a mock and stubbing behavior

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @InjectMocks
    private OrderService orderService;

    @Test
    void returnsOrderWhenFound() {
        Order fakeOrder = new Order(1L, "pending");
        when(orderRepository.findById(1L)).thenReturn(Optional.of(fakeOrder));

        Order result = orderService.getOrder(1L);

        assertEquals("pending", result.getStatus());
    }
}
```

`@ExtendWith(MockitoExtension.class)` hooks Mockito into JUnit Jupiter's lifecycle, so it knows to process the Mockito annotations before each test. `@Mock` creates a fake `OrderRepository` — no real database behind it, just an object that does nothing until you tell it what to do. `@InjectMocks` creates a real `OrderService` and automatically plugs the mocked `orderRepository` into it (via constructor or field), so you're testing `OrderService`'s real logic while its dependency is fake.

`when(...).thenReturn(...)` is **stubbing**: it tells the mock "when this exact method is called with this exact argument, return this value." Without that line, calling `orderRepository.findById(1L)` on a mock would just return `null` (or an empty `Optional`, or a default value depending on the return type) — mocks do nothing by default until stubbed.

## Verifying interactions

Sometimes a test isn't about a return value at all — it's about whether your code _called_ a dependency the way it should have. For that, Mockito has `verify`:

```java
@Test
void savesOrderAfterCancelling() {
    Order order = new Order(1L, "pending");
    when(orderRepository.findById(1L)).thenReturn(Optional.of(order));

    orderService.cancelOrder(1L);

    verify(orderRepository).save(order);
    verify(orderRepository, times(1)).findById(1L);
    verify(orderRepository, never()).deleteById(anyLong());
}
```

`verify(mock).method(args)` checks that a call actually happened with those exact arguments. `times(1)` makes the expected call count explicit (it's the default if you omit it); `never()` checks a method was _not_ called, which matters when you want to prove your code didn't do something destructive it shouldn't have. `anyLong()` is an **argument matcher** — it says "any long value," used when you don't care about (or can't predict) the exact argument, only that the method was or wasn't called.

One rule worth knowing early: if you use a matcher like `anyLong()` anywhere in a call, every argument in that same call must be a matcher too — you can't mix a raw value with a matcher in one call.

## Stubbing exceptions and multiple calls

```java
when(orderRepository.findById(99L)).thenThrow(new OrderNotFoundException());

when(orderRepository.findById(1L))
    .thenReturn(Optional.of(order))
    .thenReturn(Optional.empty());
```

`thenThrow` makes a stubbed call throw instead of return — useful for testing how your code handles a failing dependency. Chaining multiple `thenReturn` calls makes the mock return a different value on each successive call (first call gets the first value, second call gets the second, and so on) — handy for testing retry logic or anything that calls the same method more than once with different expected outcomes each time.

## A short note on spies

Related to mocks, but different: a **spy** wraps a _real_ object instead of a fully fake one. Calling a method on a spy runs the real implementation unless you explicitly stub that specific method. It's used sparingly — mostly when you need to test legacy code you can't easily restructure, since relying on real behavior in a "unit" test blurs the isolation a plain mock gives you.

[[Junit & Mokito]]