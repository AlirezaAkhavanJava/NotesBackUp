

Here's the benefit up front. Sometimes a method returns nothing, or its real job is to _call something else_. You can't check it with `assertEquals`. Mockito's `verify` lets you ask: "Did this method really call that collaborator, with the right arguments, the right number of times?"

We'll use one running example. Say you have an `OrderService` that charges a payment gateway and then sends an email:

```java
public class OrderService {
    private final PaymentGateway paymentGateway;
    private final EmailSender emailSender;

    public OrderService(PaymentGateway paymentGateway, EmailSender emailSender) {
        this.paymentGateway = paymentGateway;
        this.emailSender = emailSender;
    }

    public void placeOrder(String customerEmail, int amountCents) {
        boolean paid = paymentGateway.charge(customerEmail, amountCents);
        if (paid) {
            emailSender.send(customerEmail, "Order confirmed");
        }
    }
}
```

`placeOrder` returns `void`. The only way to test it is to check what it did to its collaborators.

## 1. Setting up the mocks

A **mock** is a fake object that records every call made to it. You create it, hand it to the class under test, and inspect it afterwards.

```java
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock PaymentGateway paymentGateway;
    @Mock EmailSender emailSender;
    @InjectMocks OrderService orderService;
}
```

`@Mock` creates the fakes. `@InjectMocks` builds `OrderService` and passes them in. `MockitoExtension` is the JUnit 5 piece that wires this up.

## 2. Stubbing vs. verifying

Beginners mix these up, so let's separate them.

- **Stubbing** (`when(...).thenReturn(...)`) is _before_ the action. You tell the mock how to behave.
- **Verifying** (`verify(...)`) is _after_ the action. You ask the mock what happened to it.

```java
@Test
void sendsEmailWhenPaymentSucceeds() {
    // stub: make the fake gateway say "payment worked"
    when(paymentGateway.charge("a@b.com", 500)).thenReturn(true);

    // act
    orderService.placeOrder("a@b.com", 500);

    // verify: did the email actually go out?
    verify(emailSender).send("a@b.com", "Order confirmed");
}
```

Notice that `verify(emailSender).send(...)` has no `times`. That's deliberate, and the next section explains why.

## 3. `times` and its relatives

`verify(mock)` on its own means **exactly once**. It's shorthand for `verify(mock, times(1))`. When you need a different count, you pass a _verification mode_:

|Mode|Meaning|
|---|---|
|`times(n)`|Called exactly `n` times|
|`never()`|Never called (same as `times(0)`)|
|`atLeastOnce()`|One or more times|
|`atLeast(n)`|`n` or more times|
|`atMost(n)`|`n` or fewer times|
|`only()`|This was the _only_ call made on the mock at all|
|`timeout(ms)`|Called within `ms` milliseconds (useful for async code)|

```java
@Test
void doesNotEmailWhenPaymentFails() {
    when(paymentGateway.charge(anyString(), anyInt())).thenReturn(false);

    orderService.placeOrder("a@b.com", 500);

    verify(paymentGateway, times(1)).charge("a@b.com", 500);
    verify(emailSender, never()).send(anyString(), anyString());
}
```

The `never()` check is one of the most useful. Tests often prove that something did _not_ happen.

## 4. Argument matchers: `any()` and friends

Sometimes you don't care about the exact argument, or you can't know it (a generated ID, a timestamp). **Argument matchers** say "match this _kind_ of value" instead of "match this exact value".

The common ones:

- `any()`: anything at all, including `null`
- `any(String.class)`: any `String`, but **not** `null`
- `anyString()`, `anyInt()`, `anyLong()`, `anyList()`: type-specific versions (also not `null`)
- `eq(value)`: exactly equal to `value`
- `isNull()` / `notNull()`: null checks
- `contains("x")`, `startsWith("x")`, `endsWith("x")`: String matching
- `argThat(...)`: your own custom condition

```java
verify(emailSender).send(eq("a@b.com"), contains("confirmed"));
verify(paymentGateway).charge(anyString(), gt(0));   // gt = greater than
verify(emailSender).send(argThat(e -> e.endsWith("@b.com")), anyString());
```

### The golden rule of matchers

**If you use a matcher for one argument, you must use a matcher for all of them.** Mockito can't mix raw values and matchers in one call.

```java
// ❌ Throws InvalidUseOfMatchersException
verify(emailSender).send("a@b.com", anyString());

// ✅ Wrap the raw value in eq()
verify(emailSender).send(eq("a@b.com"), anyString());
```

This is the single most common Mockito error, and `eq()` is the fix.

### A small trap with primitives

`any()` returns `null`, so using it where a method takes an `int` can cause a `NullPointerException`. Use `anyInt()` for primitives.

## 5. Capturing what was passed: `ArgumentCaptor`

Matchers _filter_ arguments. A **captor** _grabs_ an argument so you can inspect it with normal assertions. This is great when the argument is a big object.

```java
@Captor ArgumentCaptor<String> messageCaptor;

@Test
void emailBodyIsCorrect() {
    when(paymentGateway.charge(anyString(), anyInt())).thenReturn(true);

    orderService.placeOrder("a@b.com", 500);

    verify(emailSender).send(eq("a@b.com"), messageCaptor.capture());
    assertEquals("Order confirmed", messageCaptor.getValue());
}
```

If the method was called several times, `getAllValues()` returns a list of every captured value in order.

## 6. Checking order: `InOrder`

By default `verify` doesn't care _when_ things happened. If order matters (charge the card **before** emailing), use `InOrder`:

```java
InOrder inOrder = inOrder(paymentGateway, emailSender);
inOrder.verify(paymentGateway).charge("a@b.com", 500);
inOrder.verify(emailSender).send("a@b.com", "Order confirmed");
```

If the email were sent first, this test would fail.

## 7. "Nothing else happened" checks

- `verifyNoInteractions(mock)`: the mock was never touched at all.
- `verifyNoMoreInteractions(mock)`: every call on the mock was already verified; nothing unexpected is left over.

```java
verify(paymentGateway).charge("a@b.com", 500);
verifyNoMoreInteractions(paymentGateway);
```

Use these sparingly. They make tests strict, so a harmless refactor that adds one extra call will break them.

## 8. Void methods that should throw

Stubbing a `void` method works differently, because there's no return value to hand to `thenReturn`. You flip the order and use the `doX` family:

```java
doThrow(new RuntimeException("SMTP down"))
    .when(emailSender).send(anyString(), anyString());
```

Others in this family: `doNothing()`, `doReturn(...)`, `doAnswer(...)`.

## 9. Using it in Spring Boot

You already know Spring Boot, so here's the bridge. In a Spring test, you often want a mock to _replace_ a real bean in the application context:

- Spring Boot 3.4+: use `@MockitoBean` (from `org.springframework.test.context.bean.override.mockito`)
- Older versions: `@MockBean`

Everything after that, `when`, `verify`, `any`, `times`, works exactly the same.

## 10. Habits that keep your tests healthy

1. **Verify behavior that matters**, such as side effects like emails, saves, and payments. Don't verify every internal call.
2. **Don't verify what you stubbed.** If a `when(...)` already returns a value your code needs, the test fails anyway if it wasn't called. Extra verification is noise.
3. **Prefer assertions on results** when a method returns something. Use `verify` for `void` methods and side effects.
4. **Be as specific as is reasonable.** `anyString()` everywhere can hide bugs. If the exact value matters, use it.
5. **Use `never()` for negative cases.** It's cheap and catches real mistakes.

## Quick cheat sheet

```java
verify(mock).method(arg);                       // exactly once
verify(mock, times(3)).method(arg);             // exactly 3 times
verify(mock, never()).method(any());            // never
verify(mock, atLeastOnce()).method(anyString());
verify(mock).method(eq("x"), anyInt());         // mixed? wrap raw values in eq()
verifyNoMoreInteractions(mock);

ArgumentCaptor<Foo> c = ArgumentCaptor.forClass(Foo.class);
verify(mock).save(c.capture());
assertEquals("x", c.getValue().getName());
```




[[Testing]]
[[Spring Framework]]