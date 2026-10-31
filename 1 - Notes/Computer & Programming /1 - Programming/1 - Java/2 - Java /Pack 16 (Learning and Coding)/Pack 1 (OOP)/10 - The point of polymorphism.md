

If your code only ever deals with one concrete class, and you know it at the time you write the code, polymorphism gives you nothing. `Dog d = new Dog();` works fine.

The point shows up when the code that **uses** an object shouldn't know, or shouldn't care, which exact class it is. That happens when the type is chosen later: by a config file, a user's click, a database value, a test, or a teammate who adds a new class next month. Polymorphism lets you write your code once and keep it unchanged while the objects change underneath.

Let's see it with a real situation instead of `Animal`.

---

## 1. The same task, without polymorphism

You're building checkout. You support credit card and PayPal:

```java
public class Checkout {
    public void pay(String method, double amount) {
        if (method.equals("card")) {
            CreditCard c = new CreditCard();
            c.chargeCard(amount);
        } else if (method.equals("paypal")) {
            PayPal p = new PayPal();
            p.sendPayPal(amount);
        }
    }
}
```

Now your boss says: "Add Apple Pay and bank transfer."

```java
        } else if (method.equals("applepay")) {
            ApplePay a = new ApplePay();
            a.tapToPay(amount);
        } else if (method.equals("bank")) {
            ...
```

Notice what's happening:

- `Checkout` has to **know every payment class** and every method name each one uses.
- Every new payment type means **editing `Checkout`**.
- Every edit risks breaking the working card and PayPal code.
- The `if` chain grows forever, and the same chain tends to get copied into refunds, receipts, and reports.

You _can_ always make the object. But `Checkout` now has to make the right one and know how to talk to each one.

---

## 2. The same task, with polymorphism

```java
public interface PaymentMethod {
    void pay(double amount);
}

public class CreditCard implements PaymentMethod {
    public void pay(double amount) { /* card logic */ }
}

public class PayPal implements PaymentMethod {
    public void pay(double amount) { /* PayPal logic */ }
}
```

```java
public class Checkout {
    public void pay(PaymentMethod method, double amount) {
        method.pay(amount);
    }
}
```

Walkthrough:

- `Checkout` knows one thing: "something that can `pay`."
- It has **no `if`**, no `new`, and no payment class names.
- Adding Apple Pay means writing a new class `ApplePay implements PaymentMethod`.
- You **don't touch `Checkout` at all**. The working code stays working.

Your point "I can always make the object" is true, and it still happens, just somewhere else:

```java
PaymentMethod chosen = new ApplePay();   // decided here, once
checkout.pay(chosen, 49.99);
```

The creation moves to one place at the edge of your program. Everything in the middle works with the general type.

||Without polymorphism|With polymorphism|
|---|---|---|
|Who knows all payment types?|`Checkout` (and every other class that pays)|Only the place that creates the object|
|Adding a new type|Edit existing, working code|Add a new class only|
|Risk of breaking old features|High|Low|
|Code that grows|The `if` chains|Nothing in the user code|

---

## 3. Where you can't "just make the object": testing

Say `Checkout` calls a real bank. In a unit test, you don't want a real payment.

```java
public class FakePayment implements PaymentMethod {
    public void pay(double amount) {
        System.out.println("Pretend paid " + amount);
    }
}
```

```java
checkout.pay(new FakePayment(), 10.0);
```

Because `Checkout` accepts the general type, you can hand it a fake. If `Checkout` had `new CreditCard()` hardcoded inside, you could never test it without touching the real card system.

---

## 4. Where you can't "just make the object": you don't know the type yet

```java
List<PaymentMethod> saved = user.getSavedPaymentMethods();  // card, PayPal, mixed
for (PaymentMethod m : saved) {
    m.pay(5.0);
}
```

Here a list comes from a database, and the types are decided by what the user saved. You _can't_ write `new` for each one in your code, because you don't know them until the program runs. One loop, one call, and every object handles itself.

---

## 5. You've already used this

You work with Spring Boot, so you've used polymorphism, even if you didn't notice:

```java
@Service
public class OrderService {
    private final PaymentMethod payment;

    public OrderService(PaymentMethod payment) {
        this.payment = payment;
    }
}
```

Spring decides which implementation to inject. `OrderService` never calls `new`. Also, the Java collections work this way:

```java
List<String> names = new ArrayList<>();   // later you can switch to LinkedList
```

You write against `List`, and you can swap the implementation without changing the rest of the code.

---

## 6. When polymorphism is NOT worth it

Being honest here matters, because overusing it is a real mistake:

|Situation|Use polymorphism?|
|---|---|
|One class, will never have siblings|No. Just use the class|
|Small script or one-off code|No|
|You can imagine 2+ variants now or soon|Yes|
|You need to swap or fake behavior (tests, config)|Yes|
|The `if/else` or `switch` on a "type" keeps growing|Yes, this is the warning sign|

A good rule: if you see the same `if (type == ...)` chain in several places, that's the code asking for polymorphism.

---

## Related concept: Program to an interface (short summary)

This is the design habit that makes polymorphism useful. It means declaring variables and parameters with the **general** type (`PaymentMethod`, `List`) instead of the specific one (`CreditCard`, `ArrayList`). Polymorphism is the Java feature, and "program to an interface" is the way you use it on purpose.

---

## Quick recap

- If you always know the exact class, polymorphism isn't needed.
- It matters when the code **using** an object shouldn't depend on **which** object it is.
- The payoff: add new types without editing working code, swap fakes in for tests, and handle types you only learn at runtime.
- Object creation doesn't disappear. It moves to one place at the edge, and the rest of your code stays general.





[[Java]]