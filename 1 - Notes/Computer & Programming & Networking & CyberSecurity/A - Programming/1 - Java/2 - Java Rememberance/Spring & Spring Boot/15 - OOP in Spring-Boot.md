
## Mental Model First

Here's the core intuition to hold onto before we get technical: **Spring doesn't replace OOP — it's a runtime that _exploits_ OOP's polymorphism mechanism to inject behavior it decides on, instead of behavior your code decides on.**

Think of a stage play. In "plain" OOP, _you_ are both the director and the actor — you write the script (the class) and you also decide who plays which role and when they walk on stage (`new SomeClass()`). In Spring, you're only the **playwright** — you write classes and interfaces (the script), but the **director** (the IoC container) decides which actor plays which role, when they enter, and even secretly swaps in a **stunt double** (a proxy) without the audience — your other code — knowing.

Every "magic" Spring behavior we've discussed so far (DI, AOP, `@Transactional`, Spring Data proxies) is, underneath, **just OOP polymorphism being driven by someone other than you.** That's the whole trick. Let's build this up properly.

---

## Part 1: The Four Pillars, Re-mapped for Spring

### Encapsulation — deliberately _weakened_ by the framework

Classic OOP: hide internal state, expose behavior through methods. Spring **needs to violate this on purpose** to do its job — that's why reflection exists as a concept for you to know:

```java
public class UserService {
    @Autowired
    private UserRepository userRepository; // private!
}
```

`private` is supposed to mean "nobody outside this class touches this." But Spring, via reflection, calls `field.setAccessible(true)` and writes to it directly from outside the class. **This is a deliberate, framework-level backdoor around encapsulation.**

This is exactly why field injection is philosophically uncomfortable, beyond the testability argument I gave earlier — it requires the framework to break the encapsulation contract Java itself enforces. Constructor injection doesn't need this: a public constructor is an intentional, encapsulation-respecting "front door."

### Abstraction — becomes the primary API surface, not an afterthought

In basic OOP courses, abstraction (interfaces, abstract classes) is often taught as "nice to have — good practice." In Spring, **it's structurally load-bearing**, because the container needs a _type_ to match against, separate from a concrete implementation, so it can decide _which_ implementation to hand you at runtime:

```java
public interface PaymentGateway {
    PaymentResult charge(Money amount);
}

@Service
@Profile("prod")
public class StripePaymentGateway implements PaymentGateway {
    public PaymentResult charge(Money amount) { /* real API call */ }
}

@Service
@Profile("test")
public class FakePaymentGateway implements PaymentGateway {
    public PaymentResult charge(Money amount) { return PaymentResult.success(); }
}
```

```java
@Service
public class OrderService {
    private final PaymentGateway paymentGateway; // depends on the ABSTRACTION

    public OrderService(PaymentGateway paymentGateway) {
        this.paymentGateway = paymentGateway;
    }
}
```

`OrderService` never knows or cares whether it got `StripePaymentGateway` or `FakePaymentGateway` — this is **classic Dependency Inversion Principle** (the "D" in SOLID), and Spring's entire DI mechanism exists to make this pattern effortless instead of requiring you to manually wire "give the real one in prod, the fake one in tests."

### Inheritance — de-emphasized; Spring pushes you toward composition

This is a genuine philosophical shift from "textbook OOP," worth being explicit about. Early OOP teaching (and old Java frameworks, like early Servlet APIs where you `extends HttpServlet`) leaned heavily on inheritance: "get behavior by extending a base class."

Spring almost never wants you to `extend` its own classes. Instead, it wants you to **implement interfaces or use annotations**, and it composes behavior around your object via **proxies** (composition happening dynamically, at runtime) rather than you composing it statically via `extends`.

```java
// Old-style inheritance-driven (rare in modern Spring, but you'll see it in legacy code)
public class MyController extends AbstractController { }

// Modern Spring: composition via annotation + injected collaborators
@RestController
public class MyController {
    private final MyService service; // "has-a", not "is-a"
}
```

This matters because inheritance creates **tight, compile-time coupling to a specific superclass's implementation details**. Composition (injecting collaborators, implementing thin interfaces) keeps things loosely coupled — which is exactly what lets the container swap implementations, wrap proxies, and manage lifecycle without your classes needing to know or care.

### Polymorphism — this is the one Spring is _built on top of_

Everything above funnels into this. Let's go deep on it, because it's the mechanical key to Spring, and I want to show you the actual runtime picture, not just describe it abstractly.

---

## Part 2: Polymorphism as Spring's Load-Bearing Mechanism

### The core trick, stated precisely

Recall from our AOP/proxy discussions: when a class gets proxied (AOP, `@Transactional`, Spring Data repositories), the object placed in the container isn't your object — it's a proxy that either:

- **implements the same interface** as your class (**JDK dynamic proxy**), or
- **extends your concrete class** (**CGLIB proxy**, used when there's no interface)

Both of these are only possible **because of polymorphism**. Java lets you assign a subtype/interface-implementer wherever the supertype/interface is expected:

```java
UserRepository realOrProxy = ...; // caller genuinely cannot tell which
```

Anyone holding a `UserRepository` reference can't distinguish "the real class" from "a dynamically generated stand-in" — **because polymorphism, by design, only cares about the declared type's contract, not the concrete runtime class.** Spring is essentially _weaponizing_ the Liskov Substitution Principle: "anywhere a `UserRepository` is expected, any object that honestly fulfills that contract is acceptable" — including one Spring invented at 2am during startup via bytecode generation.

### Why this explains the `final` gotcha precisely

```java
@Service
public final class UserService { } // DON'T do this
```

If a class is `final`, **CGLIB literally cannot subclass it** — Java forbids extending `final` classes, full stop, this is a JVM-level rule with no exceptions. If `UserService` needs a proxy (say, you add `@Transactional` to a method later), Spring will fail at startup, because the entire proxy mechanism depends on ordinary Java inheritance/interface-implementation rules — it has zero special JVM privileges. Same applies to individual `final` **methods**: CGLIB can't override a `final` method to insert advice around it, so `@Transactional` silently does nothing on a `final` method (no error, which is the sneaky part — this is a genuinely nasty gotcha).

```java
@Service
public class OrderService {
    @Transactional
    public final void placeOrder() { } // @Transactional is SILENTLY ignored — no exception, just doesn't work
}
```

### Why private methods can never be proxied — ever, by design, not as a limitation

```java
@Service
public class OrderService {
    @Transactional
    private void placeOrder() { } // also silently does nothing
}
```

This isn't a Spring bug or shortcoming to fix in some future version — it's a **hard architectural consequence of how polymorphism works in Java.** `private` methods aren't part of a class's _overridable contract_ at all — they're not virtual, they're resolved statically at compile time, and subclasses can't override them even conceptually. Since both CGLIB and JDK proxies rely entirely on **overriding/implementing** methods to insert their interception logic, and `private` methods are invisible to subclasses by the language's own rules, there is **no possible implementation** of Spring that could proxy a private method. This isn't a missing feature — it's a logical impossibility given how the JVM defines method dispatch.

This is worth sitting with, because it reframes something we discussed earlier (self-invocation breaking `@Transactional`) as not "a Spring quirk" but **a direct, unavoidable consequence of Java's own polymorphism rules.** The proxy is a _subtype_; a subtype can only intercept what it can override; what it can override is governed entirely by ordinary OOP method-visibility rules that predate Spring by decades.

---

## Part 3: Design Patterns Spring Embodies (classic OOP patterns, applied)

Every one of these is a named, textbook Gang-of-Four pattern — Spring didn't invent new OOP theory, it industrialized existing patterns:

|Pattern|Where in Spring|
|---|---|
|**Proxy**|AOP, `@Transactional`, Spring Data repositories — everything we just covered|
|**Factory**|`ApplicationContext.getBean(...)`, `@Bean` factory methods|
|**Singleton**|Default bean scope (though it's a _container-scoped_ singleton, not the classic static-instance-field GoF singleton — an important distinction)|
|**Template Method**|`JdbcTemplate`, `RestTemplate` — fixed skeleton algorithm, you supply the varying part via a callback/lambda|
|**Strategy**|Multiple `@Service` implementations of one interface, chosen via `@Qualifier`/`@Primary`/`@Profile` — exactly the `PaymentGateway` example above|
|**Observer**|`ApplicationEventPublisher` + `@EventListener` — the circular-dependency fix we discussed earlier|
|**Decorator**|AOP advice conceptually "decorates" a method call with extra behavior before/after|
|**Front Controller**|`DispatcherServlet` — single entry point routing all HTTP requests|

Worth internalizing: Spring's "singleton" scope is subtly different from the textbook GoF Singleton pattern. GoF Singleton = "only one instance can _ever_ exist in the JVM, enforced by a private constructor + static instance." Spring's singleton = "only one instance exists _per container_, but nothing stops you from calling `new UserService(...)` yourself elsewhere, and nothing stops two separate `ApplicationContext`s in the same JVM from each having their own singleton instance." It's a **scope**, not a hard language-level guarantee.

---

## Part 4: Advanced/Nuanced Territory — JPA Entity Inheritance

This is where "real" OOP inheritance (not Spring's proxy-composition trick, but genuine `extends`) intersects with Spring Boot in a way that has real, gnarly database consequences — an advanced topic worth knowing exists.

Say you have:

```java
public abstract class Employee {
    @Id @GeneratedValue
    private Long id;
    private String name;
}

public class Manager extends Employee {
    private int teamSize;
}

public class Developer extends Employee {
    private String primaryLanguage;
}
```

Classic OOP: `Manager` and `Developer` are both `Employee`s (inheritance = "is-a"). But **relational databases have no native concept of inheritance** — tables don't extend other tables. JPA has to pick a strategy to flatten this OOP concept into SQL tables, and each has real trade-offs:

```java
@Entity
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "employee_type")
public abstract class Employee { ... }
```

- **`SINGLE_TABLE`**: one table for all subtypes, with a discriminator column (`employee_type = 'MANAGER'`) and nullable columns for fields that only apply to some subtypes. Fast (no joins), but denormalized — lots of `NULL`s.
- **`JOINED`**: one table per class, linked by shared primary keys, joined at query time. Normalized, but every query on `Manager` needs a `JOIN` back to `employee`.
- **`TABLE_PER_CLASS`**: one full table per concrete subclass, duplicating shared columns. No joins needed, but polymorphic queries (`findAll Employees`) require `UNION`s, and it's the least commonly recommended strategy.

The reason I'm flagging this: **this is a place where "clean OOP modeling" and "clean relational modeling" genuinely pull in different directions**, and picking the wrong `InheritanceType` for your access patterns causes real performance problems later — it's not just an academic choice.

---

## Nuances & Gotchas Worth Internalizing

### 1. `equals()`/`hashCode()` on JPA entities — a classic OOP trap made worse by proxies

```java
@Entity
public class User {
    @Id
    private Long id;

    @Override
    public boolean equals(Object o) {
        if (!(o instanceof User)) return false;
        return id != null && id.equals(((User) o).id);
    }

    @Override
    public int hashCode() {
        return getClass().hashCode(); // NOT id.hashCode() — deliberately
    }
}
```

Why not the "obvious" field-based `equals`/`hashCode`? Because **Hibernate itself returns proxies for lazily-loaded entities** (a _different_ kind of proxy than Spring AOP — Hibernate's own lazy-loading proxy, but built on the exact same OOP polymorphism trick we've been discussing all along). A lazy-loaded `Manager` proxy might report `getClass()` as `Manager$HibernateProxy$abc123`, not `Manager` — so naive `instanceof` or `getClass() == other.getClass()` checks break unpredictably depending on whether an entity came from cache, a fresh query, or a lazy relationship. This is a very well-known, very advanced gotcha that trips up even experienced developers — it's the same "proxy pretends to be your object polymorphically, but isn't literally your object" issue as everywhere else in this conversation, just showing up in the persistence layer instead of the service layer.

### 2. `@Autowired` and polymorphism — collection injection

```java
public interface NotificationSender {
    void send(String message);
}

@Component public class EmailSender implements NotificationSender { ... }
@Component public class SmsSender implements NotificationSender { ... }

@Service
public class NotificationService {
    private final List<NotificationSender> senders; // Spring injects ALL implementations, in a List!

    public NotificationService(List<NotificationSender> senders) {
        this.senders = senders;
    }

    public void notifyAll(String msg) {
        senders.forEach(sender -> sender.send(msg)); // polymorphic dispatch across ALL implementations
    }
}
```

This is a beautiful, very "advanced OOP" use of polymorphism + DI together: Spring recognizes "you're asking for a `List<Interface>`," finds **every bean implementing that interface**, and hands you all of them — you get true runtime polymorphic fan-out without a single `if/else` or `instanceof` check anywhere in your code. This is the Strategy pattern taken to its natural conclusion.

---

## Two Questions to Test Real Understanding

**1.** Suppose you have this class:

```java
@Service
public class ReportService {

    @Transactional
    public void generateReport() {
        exportToFile(); // calling a method on 'this'
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void exportToFile() {
        // ...
    }
}
```

Will `exportToFile()`'s `REQUIRES_NEW` (which should suspend the current transaction and start a brand-new one) actually take effect when called this way? Explain **why**, tracing it back to which object is calling which — not just "yes/no."

**2.** You have an interface `Shape` with a method `area()`, implemented by `Circle` and `Square`, both registered as `@Component` beans. You inject `List<Shape> shapes` into another bean and it works fine — polymorphism across multiple beans, no `@Transactional`, no AOP involved anywhere.

Now, separately, you have a single class `OrderService` with a `@Transactional` method, and Spring wraps it in a CGLIB proxy that `extends OrderService`.

---

**Question:** both scenarios rely on polymorphism, but they're using _fundamentally different Java language mechanisms_ to achieve it. Name the two distinct mechanisms, and explain concretely why `Shape`'s case _cannot_ use the same mechanism as `OrderService`'s case (hint: think about what `Circle` and `Square` have in common structurally, versus what CGLIB needs `OrderService` to have).


[[Java]]
[[0 - Spring + Spring Boot]]
[[37 - Spring Boot]]