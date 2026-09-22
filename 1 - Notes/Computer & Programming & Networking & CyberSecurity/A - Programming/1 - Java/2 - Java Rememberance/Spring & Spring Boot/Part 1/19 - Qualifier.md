
`@Qualifier` solves ambiguity when Spring has multiple beans of the same type and doesn't know which one to inject.

## The problem

```java
public interface PaymentService {
    void pay();
}

@Service
public class CreditCardPaymentService implements PaymentService {
    public void pay() { System.out.println("Paying by credit card"); }
}

@Service
public class PaypalPaymentService implements PaymentService {
    public void pay() { System.out.println("Paying by PayPal"); }
}
```

Now if you try:

```java
@Autowired
private PaymentService paymentService;
```

Spring finds **two** beans implementing `PaymentService` and throws:

```
NoUniqueBeanDefinitionException: expected single matching bean but found 2
```

## The fix: `@Qualifier`

You tell Spring exactly which bean to pick, by its bean name (default = class name with lowercase first letter).

```java
@Autowired
@Qualifier("creditCardPaymentService")
private PaymentService paymentService;
```

Works the same way on constructor injection (the preferred style):

```java
@Service
public class CheckoutService {

    private final PaymentService paymentService;

    public CheckoutService(@Qualifier("paypalPaymentService") PaymentService paymentService) {
        this.paymentService = paymentService;
    }
}
```

## Giving beans custom names

Instead of relying on the auto-generated name, you can name them explicitly:

```java
@Service("creditCard")
public class CreditCardPaymentService implements PaymentService { ... }

@Service("paypal")
public class PaypalPaymentService implements PaymentService { ... }
```

```java
@Qualifier("creditCard")
private PaymentService paymentService;
```

## Alternative: `@Primary`

If one implementation should just be the default (used whenever no `@Qualifier` is specified), mark it `@Primary` instead:

```java
@Service
@Primary
public class CreditCardPaymentService implements PaymentService { ... }
```

Then plain `@Autowired` (no qualifier) resolves to that one automatically — `@Qualifier` still lets you override it when you specifically want the other bean.

## Rule of thumb

- **One implementation** → plain `@Autowired`, no qualifier needed.
- **Multiple implementations, one usual default** → `@Primary` on the default, `@Qualifier` where you need the others.
- **Multiple implementations, no natural default** → `@Qualifier` everywhere, be explicit.


[[0 - Spring Framework]]
[[Java]]
[[0 - Spring + Spring Boot]]