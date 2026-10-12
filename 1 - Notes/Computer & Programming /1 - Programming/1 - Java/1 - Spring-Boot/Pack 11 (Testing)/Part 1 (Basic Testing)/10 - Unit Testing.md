

Unit testing is the practice of writing small, automated pieces of code that check whether a single "unit" of your program behaves the way you expect. A **unit** is the smallest piece of logic that makes sense to test on its own, usually a single method or a small class.

Think of building a car. Before assembling the whole thing, you'd test each part separately: does the brake pad grip, does the spark plug fire? If you only test the finished car and it won't start, you have no idea which part is at fault. Unit tests give you that part-by-part confidence in software.

## A concrete example

Say you have a simple Java class:

```java
public class PriceCalculator {
    public double applyDiscount(double price, int percent) {
        if (percent < 0 || percent > 100) {
            throw new IllegalArgumentException("Invalid percent");
        }
        return price - (price * percent / 100.0);
    }
}
```

A unit test using JUnit 5 might look like this:

```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class PriceCalculatorTest {

    private final PriceCalculator calculator = new PriceCalculator();

    @Test
    void appliesDiscountCorrectly() {
        double result = calculator.applyDiscount(200.0, 25);
        assertEquals(150.0, result);
    }

    @Test
    void zeroPercentLeavesPriceUnchanged() {
        assertEquals(80.0, calculator.applyDiscount(80.0, 0));
    }

    @Test
    void rejectsNegativePercent() {
        assertThrows(IllegalArgumentException.class,
                () -> calculator.applyDiscount(100.0, -5));
    }
}
```

Each test follows the same rhythm, often called **Arrange, Act, Assert**:

1. **Arrange**: set up the object and inputs.
2. **Act**: call the method you're testing.
3. **Assert**: check that the result is what you expected.

Notice that the tests cover the normal case, an edge case (0%), and an error case (invalid input). Good unit tests think about all three.

## What makes a unit test a _unit_ test

- **Isolated**: it tests one piece of logic and doesn't depend on a real database, network, file system, or other services.
- **Fast**: it runs in milliseconds, so you can run thousands of them in seconds.
- **Repeatable**: it gives the same result every time, on any machine, in any order.
- **Self-checking**: it passes or fails by itself, with no human needing to eyeball output.

## Dealing with dependencies: mocks and stubs

Real code rarely lives alone. A `OrderService` might call a `PaymentGateway` or a repository that talks to PostgreSQL. In a unit test, you don't want to hit a real payment provider or database, because that would be slow, flaky, and no longer isolated.

Instead you replace those collaborators with **test doubles**, fake stand-ins you control. In the Java world, Mockito is the most common tool:

```java
@Test
void placesOrderWhenPaymentSucceeds() {
    PaymentGateway gateway = mock(PaymentGateway.class);
    when(gateway.charge(100.0)).thenReturn(true);

    OrderService service = new OrderService(gateway);

    assertTrue(service.placeOrder(100.0));
    verify(gateway).charge(100.0);
}
```

Here you decide that the payment gateway "succeeds," and you test only the `OrderService` logic around it.

## Why bother?

- **Catch bugs early**: problems show up minutes after you write the code, not weeks later in production.
- **Safe refactoring**: if you restructure code and all tests still pass, you can be fairly confident you haven't broken anything.
- **Living documentation**: tests show how a piece of code is meant to be used.
- **Better design**: code that's hard to unit test is often too tightly coupled, so testing pushes you toward cleaner, more modular code.
- **Faster debugging**: when a test fails, it points you at a very specific place.

## Where unit tests fit in the bigger picture

Unit tests are the base of the **testing pyramid**:

- **Unit tests** (many): small, fast, isolated.
- **Integration tests** (some): check that pieces work together, such as your code with a real database.
- **End-to-end tests** (few): simulate a real user going through the whole system.

Unit tests don't replace the others. They verify that the parts work, while integration and end-to-end tests verify that the parts fit together.

## Common pitfalls

- **Testing implementation instead of behavior**: if tests break every time you rename a private method, they're too tightly bound to the internals. Test _what_ the code does, not _how_.
- **Over-mocking**: mocking everything can leave you testing your mocks rather than real logic.
- **Chasing 100% coverage**: coverage tells you which lines ran, not whether the tests are meaningful. A test with no assertions can still "cover" code.
- **Slow or order-dependent tests**: these erode trust, and people stop running them.

## A helpful mindset

Many developers also practice **TDD (Test-Driven Development)**: write a failing test first, write just enough code to make it pass, then clean up. You don't have to adopt it fully, but trying it on a small feature is a great way to feel how testing shapes design.




[[Testing]]
[[Spring Framework]]