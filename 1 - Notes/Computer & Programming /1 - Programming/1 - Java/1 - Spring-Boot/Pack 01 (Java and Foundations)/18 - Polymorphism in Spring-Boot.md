

Polymorphism, in Java, means one reference type can point to different concrete implementations, and the caller using that reference never needs to know which implementation it actually holds. Spring Boot doesn't add a new kind of polymorphism — there's no `@Polymorphism` annotation — but it is built almost entirely on top of this one Java mechanism. Dependency injection, Spring Data repositories, Spring Security's authentication pipeline, and AOP proxies are all, underneath, the same "same type, different object" trick doing real architectural work.

## Dependency injection is polymorphism, operationalized

A Spring bean that depends on an interface never knows which class actually fills that dependency. The container decides at startup and wires it in.

```java
public interface PaymentGateway {
    void charge(BigDecimal amount);
}

@Service
public class StripeGateway implements PaymentGateway {
    public void charge(BigDecimal amount) {
        // Stripe-specific logic
    }
}

@Service
public class OrderService {
    private final PaymentGateway gateway;

    public OrderService(PaymentGateway gateway) {
        this.gateway = gateway;
    }

    public void checkout(BigDecimal amount) {
        gateway.charge(amount);
    }
}
```

`OrderService` holds a `PaymentGateway` reference. Nothing in its code says "Stripe." Replace `StripeGateway` with `PaypalGateway` and `OrderService` doesn't change a single line — the polymorphic reference absorbs the change. This is the entire reason "program to an interface, not an implementation" is treated as a rule rather than a suggestion: it's what makes a class replaceable without a rewrite.

If two beans implement the same interface, Spring has no way to guess which one you mean, and you resolve it explicitly:

```java
@Primary
@Service
public class StripeGateway implements PaymentGateway { ... }
```

or at the injection point:

```java
public OrderService(@Qualifier("paypalGateway") PaymentGateway gateway) { ... }
```

That ambiguity only exists _because_ polymorphism allows multiple implementations in the first place.

## Strategy selection via `List<Interface>`

Spring can inject every bean that implements an interface as a single `List`, letting you pick the right one at runtime based on a condition instead of a chain of `if`/`else`:

```java
public interface DiscountStrategy {
    boolean supports(Customer c);
    BigDecimal apply(BigDecimal price);
}

@Component
public class StudentDiscount implements DiscountStrategy {
    public boolean supports(Customer c) { return c.isStudent(); }
    public BigDecimal apply(BigDecimal price) { return price.multiply(BigDecimal.valueOf(0.9)); }
}

@Component
public class SeniorDiscount implements DiscountStrategy {
    public boolean supports(Customer c) { return c.getAge() >= 65; }
    public BigDecimal apply(BigDecimal price) { return price.multiply(BigDecimal.valueOf(0.85)); }
}

@Service
public class PricingService {
    private final List<DiscountStrategy> strategies;

    public PricingService(List<DiscountStrategy> strategies) {
        this.strategies = strategies;
    }

    public BigDecimal priceFor(Customer c, BigDecimal base) {
        return strategies.stream()
            .filter(s -> s.supports(c))
            .findFirst()
            .map(s -> s.apply(base))
            .orElse(base);
    }
}
```

`PricingService` iterates over a list of references it treats identically; the actual decision of which discount applies lives inside each implementation, not inside `PricingService`. Adding a new discount later means adding one new `@Component` — the service that uses them is untouched. That's polymorphism enabling the open/closed principle directly: open to new strategies, closed to modification.

## Repositories: implementations you never write

```java
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
}
```

No class in your codebase implements `UserRepository`. At startup, Spring Data generates a proxy that does — backed by `SimpleJpaRepository` for the inherited methods, with your custom method derived from its name. Code that injects `UserRepository` is holding a reference to a class that doesn't exist in source form anywhere; it was generated. The shape is identical to `Animal a = new Dog()`, except the "Dog" was written by the framework, not by you.

## Authentication as a chain of polymorphic candidates

Spring Security's `AuthenticationProvider` interface looks like this:

```java
public interface AuthenticationProvider {
    Authentication authenticate(Authentication authentication);
    boolean supports(Class<?> authentication);
}
```

`DaoAuthenticationProvider`, `RememberMeAuthenticationProvider`, and any custom JWT provider you write all implement it differently. `ProviderManager` holds a `List<AuthenticationProvider>` and walks through it, asking each one `supports(...)` until one agrees to handle the given `Authentication` object. It's the strategy pattern from above, applied specifically to authentication.

## The one case where polymorphism is used to deceive, not to choose: AOP proxies

Everywhere above, polymorphism exists to let you pick between _several real implementations_. AOP proxying inverts the purpose: there's only one real implementation, but Spring wraps it in a CGLIB subclass or a JDK dynamic proxy that shares its type. Code that calls your `@Transactional` service holds a reference typed as your service (or its interface) and has no way to tell, from the type alone, that it's actually talking to a proxy that opens a transaction, calls your real method, then commits or rolls back. The reference-type abstraction isn't being used to select between competitors here — it's being used to smuggle in behavior around a single implementation without the caller noticing.

**Related, briefly:** this is also why Spring leans on interface-based polymorphism rather than method overloading anywhere its design needs runtime flexibility — overloading is resolved at compile time, so it can never be the mechanism for swapping an implementation after the fact; only a shared reference type resolved at runtime can do that.


[[Spring Framework]]