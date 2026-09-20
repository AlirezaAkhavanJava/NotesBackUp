
The important thing is: **you don't make everything loosely coupled.** That would often make your code unnecessarily complicated.

The goal is:

> **Couple things where the relationship is naturally permanent; decouple things where implementations are likely to vary.**

---

# 1. A practical rule

Think about a dependency like this:

```java
class OrderService {
    private StripePayment payment = new StripePayment();
}
```

Ask:

> "Could I reasonably want to replace `StripePayment` without changing `OrderService`?"

If **yes** → abstraction/interface is probably useful.

If **no** → direct coupling is often perfectly fine.

---

# 2. What SHOULD usually be loosely coupled?

## A. Business logic → external systems

This is probably the most important case.

Imagine:

```text
OrderService
     |
     v
PaymentService
     |
     v
Stripe
```

You generally don't want your business logic knowing everything about Stripe.

Instead:

```java
public interface PaymentService {
    void pay(BigDecimal amount);
}
```

Then:

```java
public class StripePaymentService implements PaymentService {

    @Override
    public void pay(BigDecimal amount) {
        // Stripe API
    }
}
```

Your business logic:

```java
public class OrderService {

    private final PaymentService paymentService;

    public OrderService(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    public void checkout(BigDecimal amount) {
        // business logic

        paymentService.pay(amount);
    }
}
```

Now:

```text
             ┌── StripePaymentService
             │
OrderService ──> PaymentService
             │
             └── PayPalPaymentService
```

`OrderService` doesn't care which payment provider you're using.

---

# 3. Database access is another major example

Don't do this everywhere:

```java
class UserService {

    MySQLDatabase database = new MySQLDatabase();

    public User getUser(long id) {
        return database.findUser(id);
    }
}
```

Instead:

```java
interface UserRepository {
    User findById(long id);
}
```

Implementation:

```java
class PostgresUserRepository implements UserRepository {

    @Override
    public User findById(long id) {
        // PostgreSQL code
    }
}
```

Then:

```java
class UserService {

    private final UserRepository repository;

    public UserService(UserRepository repository) {
        this.repository = repository;
    }

    public User getUser(long id) {
        return repository.findById(id);
    }
}
```

Now your business logic doesn't care whether the data comes from:

```text
PostgreSQL
MySQL
MongoDB
REST API
Memory
Test fake
```

---

# 4. This becomes VERY important in Spring Boot

Spring makes this pattern extremely convenient.

You could have:

```java
public interface PaymentService {
    void pay(BigDecimal amount);
}
```

```java
@Service
public class StripePaymentService implements PaymentService {

    @Override
    public void pay(BigDecimal amount) {
        // Stripe
    }
}
```

And:

```java
@Service
public class OrderService {

    private final PaymentService paymentService;

    public OrderService(PaymentService paymentService) {
        this.paymentService = paymentService;
    }
}
```

Spring essentially does:

```java
PaymentService payment =
    new StripePaymentService();

OrderService order =
    new OrderService(payment);
```

for you.

That's **Dependency Injection**.

And this:

```java
private final PaymentService paymentService;
```

is the key.

You're saying:

> "I don't need to know the implementation. Give me anything that satisfies `PaymentService`."

---

# 5. What SHOULD be tightly coupled?

This is equally important.

You don't need:

```java
interface StringFormatterFactoryProviderManager
```

for every tiny class.

For example:

```java
class User {

    private String name;

    public String getName() {
        return name;
    }
}
```

There is no reason to create:

```java
interface UserNameProvider
```

just because interfaces exist.

That's **overengineering**.

---

## Another example

Suppose you have:

```java
class Circle {

    private double radius;

    public double area() {
        return Math.PI * radius * radius;
    }
}
```

`Circle` can directly depend on `Math.PI`.

You don't need:

```java
interface PiProvider {
    double getPi();
}
```

That would be ridiculous.

Why?

Because `Circle` has a fundamental relationship with π.

There's no meaningful implementation you expect to swap.

---

# 6. A very useful classification

When designing a system, think about dependencies in categories.

### Usually loosely coupled

```text
Business logic
      ↓
Database

Business logic
      ↓
External API

Business logic
      ↓
Payment provider

Business logic
      ↓
Email provider

Business logic
      ↓
File system

Business logic
      ↓
Message broker

Business logic
      ↓
Cloud service
```

These are **external dependencies** and are likely to change.

---

### Usually tightly coupled

```text
Class
 ↓
Simple value object

Class
 ↓
Utility

Class
 ↓
Mathematical operation

Class
 ↓
Internal implementation detail
```

These relationships are usually stable and don't benefit from abstraction.

---

# 7. The real rule isn't "always use interfaces"

This is where beginners often get confused.

Bad rule:

> ❌ "Interfaces are good, therefore use an interface everywhere."

Better rule:

> ✅ "Introduce an abstraction when you need to protect one part of the system from changes in another part."

That's a much more professional way to think about it.

---

# 8. The "change test"

Here's a great rule you can actually use while programming.

Imagine this:

```java
class OrderService {
    private final StripePaymentService payment;
}
```

Ask:

> **"If Stripe disappears tomorrow, how much code do I have to change?"**

If the answer is:

```text
OrderService
CheckoutController
OrderController
Order
...
```

you have probably coupled your architecture too tightly to Stripe.

Instead:

```java
class OrderService {
    private final PaymentService payment;
}
```

Now:

```text
Stripe disappears
       ↓
replace StripePaymentService
       ↓
OrderService remains unchanged
```

That's useful decoupling.

---

# 9. There's another extremely important principle

This is called:

**Dependency Inversion Principle (DIP)**

The simplified version is:

> **High-level business logic should not depend directly on low-level implementation details. Both should depend on abstractions.**

For example:

### Bad

```text
OrderService
     ↓
PostgresUserRepository
     ↓
PostgreSQL
```

Your business logic directly knows the database implementation.

### Better

```text
           UserRepository
          /              \
         /                \
OrderService        PostgresUserRepository
                          |
                          v
                      PostgreSQL
```

Now:

```text
OrderService
     ↓
 abstraction
     ↑
implementation
```

This is one of the foundations of serious application architecture.

---

# 10. But don't abstract prematurely

This is another professional rule.

Suppose you have:

```java
class UserRepository {
    public User findById(long id) {
        // PostgreSQL
    }
}
```

And you're building a tiny application.

Don't automatically create:

```java
interface UserRepository
class PostgresUserRepository implements UserRepository
```

just because "SOLID says so."

Ask yourself:

> **Is there a real reason for this abstraction?**

For example:

### Good reason

You're building:

```text
Production → PostgreSQL
Testing    → FakeRepository
```

Interface makes sense.

### Good reason

You might support:

```text
PostgreSQL
MySQL
```

Interface makes sense.

### Good reason

Your business logic shouldn't know about infrastructure.

Interface makes sense.

### Bad reason

> "My Java teacher said interfaces are good."

Don't do it.

---

# 11. A practical programmer's contract

If I were giving you a set of rules to keep beside your keyboard, I'd use these:

### Rule 1 — Depend on abstractions when implementations can vary

```java
PaymentService
```

rather than:

```java
StripePaymentService
```

when multiple payment implementations are possible.

---

### Rule 2 — Keep business logic independent from infrastructure

Try to avoid:

```java
OrderService → PostgreSQL
OrderService → Stripe
OrderService → SMTP
OrderService → AWS
```

Prefer:

```text
             ┌→ PaymentService
OrderService ├→ UserRepository
             └→ EmailService
```

---

### Rule 3 — Don't create interfaces for everything

This:

```java
interface UserNameGetter
```

is usually nonsense.

Interfaces should represent **meaningful contracts**.

---

### Rule 4 — Prefer composition + dependency injection

Instead of:

```java
class OrderService {
    PaymentService payment = new StripePaymentService();
}
```

prefer:

```java
class OrderService {

    private final PaymentService payment;

    OrderService(PaymentService payment) {
        this.payment = payment;
    }
}
```

Now the dependency is supplied from outside.

---

### Rule 5 — Concrete classes are completely fine

This is perfectly normal:

```java
class Order {

    private final long id;
    private final BigDecimal total;
}
```

You don't need:

```java
interface Order
class OrderImpl implements Order
```

That pattern is often pointless.

---

### Rule 6 — Abstract at the boundary

This is probably the **most useful rule** to remember.

Put abstractions around things that form boundaries:

```text
                 SYSTEM
──────────────────────────────────

Business Logic
      |
      | interface
      ↓
  Repository
      |
      ↓
 PostgreSQL


Business Logic
      |
      | interface
      ↓
 PaymentService
      |
      ↓
    Stripe


Business Logic
      |
      | interface
      ↓
 EmailService
      |
      ↓
     SMTP
```

The interface creates a **boundary** between your core logic and the outside world.

---

# 12. The big picture

You can think of a professional Java application like this:

```text
                 ┌───────────────────┐
                 │   Controllers     │
                 └─────────┬─────────┘
                           │
                           ↓
                 ┌───────────────────┐
                 │   Business Logic  │
                 │                   │
                 │   OrderService    │
                 │   UserService     │
                 └───────┬───┬───────┘
                         │   │
                 interfaces
                         │   │
              ┌──────────┘   └──────────┐
              ↓                         ↓
       UserRepository             PaymentService
              ↓                         ↓
       PostgreSQL                    Stripe
```

The **core of your application doesn't need to know the details of the outside world.**

That's what you're trying to achieve with loose coupling.

---

## The one sentence I'd memorize

> **Use tight coupling for things that are naturally and permanently part of the same implementation; use loose coupling at boundaries where implementations may change, especially between business logic and infrastructure.**

And one more:

> **Don't use an interface because you can. Use an interface because you need a contract that allows implementations to vary.**

That's the mindset that will serve you much better than memorizing "always use interfaces."

[[Java]]