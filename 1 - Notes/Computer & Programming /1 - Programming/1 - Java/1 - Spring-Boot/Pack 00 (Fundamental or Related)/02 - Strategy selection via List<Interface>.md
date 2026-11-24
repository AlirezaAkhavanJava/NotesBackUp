



Strategy selection via `List<Interface>` is one of Spring's quieter superpowers: it lets you swap out "which implementation runs" logic for a clean, extensible design, without a single `if/else` or `switch` chain. The idea is simple once you see it. 

You define an interface, write several classes that implement it, and instead of asking Spring for _one_ bean of that type, you ask for _all of them at once_, collected into a `List`. Spring finds every bean that implements the interface and hands you the whole group. From there, your code picks the right one at runtime — that's the "strategy selection" part.

## Why this even works

Normally, when you autowire a single interface type, Spring expects exactly one matching bean (or it throws `NoUniqueBeanDefinitionException` if there are several). But Spring's injection logic has a special case: if the declared type is a `Collection` (like `List<T>` or `Set<T>`), Spring doesn't try to find one bean — it switches modes and gathers **every bean assignable to `T`** into that collection. Multiple implementations stop being a conflict and become the whole point.

This also works for arrays (`T[]`) and, interestingly, for `Map<String, T>` — where the keys are automatically the bean names. That variant is handy when you need to look an implementation up by name instead of filtering a list, but the `List` form is more common for "pick the strategy that applies" logic.

## A concrete example

Say you're processing payments and want to support multiple payment methods, each with its own logic:

```java
public interface PaymentStrategy {
    boolean supports(String method);
    void pay(BigDecimal amount);
}

@Component
public class CreditCardStrategy implements PaymentStrategy {
    public boolean supports(String method) {
        return method.equalsIgnoreCase("CREDIT_CARD");
    }
    public void pay(BigDecimal amount) {
        System.out.println("Charging credit card: " + amount);
    }
}

@Component
public class PaypalStrategy implements PaymentStrategy {
    public boolean supports(String method) {
        return method.equalsIgnoreCase("PAYPAL");
    }
    public void pay(BigDecimal amount) {
        System.out.println("Charging via PayPal: " + amount);
    }
}

@Component
public class CryptoStrategy implements PaymentStrategy {
    public boolean supports(String method) {
        return method.equalsIgnoreCase("CRYPTO");
    }
    public void pay(BigDecimal amount) {
        System.out.println("Charging via crypto wallet: " + amount);
    }
}
```

Now the consumer that actually picks the strategy:

```java
@Service
public class PaymentProcessor {

    private final List<PaymentStrategy> strategies;

    public PaymentProcessor(List<PaymentStrategy> strategies) {
        this.strategies = strategies;
    }

    public void process(String method, BigDecimal amount) {
        strategies.stream()
                .filter(s -> s.supports(method))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unsupported method: " + method))
                .pay(amount);
    }
}
```

Spring sees the constructor parameter `List<PaymentStrategy>`, finds `CreditCardStrategy`, `PaypalStrategy`, and `CryptoStrategy` as beans in the context, and injects all three into that list automatically — no manual registration, no factory class, no `switch` statement anywhere. Add a `BankTransferStrategy` class tomorrow, annotate it `@Component`, and `PaymentProcessor` picks it up with zero changes to itself. That's the whole value proposition: **open for extension, closed for modification**.

## Controlling the order

Since it's a `List`, order can matter — for example if you want a "default" strategy checked last, or if several strategies could technically match and you want deterministic priority. Spring lets you control this with `@Order`:

```java
@Component
@Order(1)
public class CreditCardStrategy implements PaymentStrategy { ... }

@Component
@Order(2)
public class PaypalStrategy implements PaymentStrategy { ... }
```

Lower values come first in the injected list. Implementing the `Ordered` interface instead of using the annotation works the same way, and is useful when the order needs to be computed rather than fixed.

## A related idea worth knowing: `Map<String, Interface>`

If instead of filtering you want direct lookup by name, inject a `Map<String, PaymentStrategy>` instead of a `List`. Spring populates it with bean name → bean instance pairs, so `strategies.get("creditCardStrategy")` works out of the box. It's the same underlying mechanism, just keyed instead of filtered — useful when the caller already knows exactly which strategy name it wants (e.g. from a config value) rather than needing to ask each one "do you handle this?".

## How this differs from `@Primary` / `@Qualifier`

`@Primary`/`@Qualifier` solve a _static_ ambiguity problem: "there are multiple beans of this type, so which single one do I wire in _right here, at startup_?" You're telling Spring the answer once, in code, and it's fixed for that injection point.

`List<Interface>` flips that around: you're not resolving ambiguity, you're embracing it. You tell Spring "give me everyone," and the _decision_ of which one actually gets used happens later, at runtime, based on data you only have when the method is called — like the `method` string in the payment example above. That's why it's called strategy selection rather than strategy resolution: the logic that picks the winner is yours, written in regular Java, and can change per call.

A good way to frame it:

||`@Primary` / `@Qualifier`|`List<Interface>`|
|---|---|---|
|When the choice is made|At wiring time (fixed)|At call time (dynamic)|
|Who decides|You, in annotations|Your code, based on runtime input|
|Typical use|"Always use this one unless told otherwise"|"Pick whichever one matches this specific request"|

One nuance worth knowing: these aren't mutually exclusive. You could still mark one strategy `@Primary` so that _if_ some other part of your code injects `PaymentStrategy` directly (singular), it gets a sensible default — while `PaymentProcessor` separately injects the full `List<PaymentStrategy>` to do its own runtime filtering. They solve different problems and can coexist in the same app without conflict.


[[Spring Framework]]