# Tight Coupling and Loose Coupling

**Coupling** is a measure of how much one class knows about another class and depends on it. Whenever class A uses class B, A is coupled to B. You can't avoid that, because objects have to work together. The real question is _how strongly_ they are tied together, and that is what "tight" and "loose" describe.

A **tightly coupled** class knows too much about its helper. It knows the exact concrete class, it creates it itself, and it knows how to build it. A **loosely coupled** class knows only what it needs, which is a small contract (usually an interface), and it doesn't care who built the helper or which implementation it got. Loose coupling matters because real software changes constantly, and loosely coupled code lets you change one part without breaking five others.

---

## What tight coupling looks like

```java
public class EmailSender {
    public void send(String to, String message) {
        System.out.println("Sending email to " + to + ": " + message);
    }
}

public class OrderService {
    private EmailSender sender = new EmailSender();   // <-- the tight coupling

    public void placeOrder(String customerEmail) {
        // ... save the order ...
        sender.send(customerEmail, "Your order is confirmed!");
    }
}
```

Line by line, here is why `OrderService` is tightly coupled:

- `private EmailSender sender` means it depends on the **concrete class** `EmailSender`, not on "something that can notify".
- `= new EmailSender()` means `OrderService` **decides** which object it gets and **builds** it itself.
- `new EmailSender()` also means it must know **how** to build it. If `EmailSender` later needs a host name and port, this line must change.

That's three kinds of knowledge packed into one line. The more a class knows about another, the more tightly the two are glued together.

### Why this causes real problems

|Problem|What happens in the example|
|---|---|
|**Can't swap implementations**|Your boss says "also support SMS". You must open `OrderService` and edit it. The class is now modified every time a requirement changes.|
|**Can't test it**|Every unit test of `placeOrder` creates a real `EmailSender`, which may send real emails or need a real mail server. You can't substitute a fake.|
|**Changes ripple outward**|If `EmailSender`'s constructor becomes `new EmailSender(host, port)`, every class that wrote `new EmailSender()` stops compiling. With 40 such classes, that's 40 edits.|
|**Hidden dependencies**|Reading `OrderService`'s public API, you can't tell it needs an email system. The dependency is buried inside.|
|**Hard to reuse**|You can't take `OrderService` into another project without dragging `EmailSender` along.|
|**No control over lifecycle**|Each `OrderService` makes its own `EmailSender`. If it's expensive (a connection pool), you now have many copies. Sharing one instance is hard.|

This is exactly why Java developers invented the loosely coupled style. They were tired of rewriting working classes every time something around them changed.

---

## What loose coupling looks like

The fix has **two moves**.

**Move 1: depend on an interface (a contract), not a concrete class.**

```java
public interface NotificationSender {
    void send(String to, String message);
}

public class EmailSender implements NotificationSender {
    public void send(String to, String message) { /* email logic */ }
}

public class SmsSender implements NotificationSender {
    public void send(String to, String message) { /* SMS logic */ }
}
```

**Move 2: don't create the helper yourself. Receive it from outside, through the constructor.**

```java
public class OrderService {
    private final NotificationSender sender;           // (1)

    public OrderService(NotificationSender sender) {   // (2)
        this.sender = sender;                          // (3)
    }

    public void placeOrder(String customer) {
        // ... save the order ...
        sender.send(customer, "Your order is confirmed!");
    }
}
```

Line by line:

1. The field's type is the **interface**. `OrderService` only knows "I can call `send`". It has no idea whether that's email, SMS, or a carrier pigeon.
2. The constructor **asks** for the helper instead of building it. The class says "give me whatever I need", and that is the core idea.
3. It stores what it was given. `final` means it can never be swapped by accident later.

Now whoever builds `OrderService` chooses the implementation:

```java
OrderService a = new OrderService(new EmailSender());
OrderService b = new OrderService(new SmsSender());
```

`OrderService` was written once and never touched again, yet it works with both. A test can also pass in a fake:

```java
NotificationSender fake = (to, msg) -> System.out.println("FAKE: " + msg);
OrderService testable = new OrderService(fake);   // no real email, ever
```

---

## `new` versus a constructor: they are not rivals

This is the most common confusion, so let's untangle it.

- A **constructor** is a special method inside a class that sets up a new object (`public OrderService(...) { ... }`).
- **`new`** is the operator you use to _call_ that constructor. It allocates memory for the object, runs the constructor, and gives you back the object.

So `new EmailSender()` already uses a constructor. You never choose between "`new`" and "a constructor". Every object creation uses both.

The comparison you really mean is **where the `new` is written and who decides**:

||`new` inside the class (tight)|Receive through constructor (loose)|
|---|---|---|
|Code|`private EmailSender s = new EmailSender();`|`OrderService(NotificationSender s) { this.s = s; }`|
|Who chooses the implementation?|The class itself, permanently|The caller, every time|
|Class depends on|Concrete class|Interface|
|Swappable?|No, you must edit the class|Yes, just pass something else|
|Testable with fakes?|Hard|Easy|
|Dependencies visible?|Hidden inside|Visible in the constructor signature|

So the constructor is the **doorway** through which dependencies come in. The `new` calls still exist somewhere, but they move _out_ of your business classes and into one place at the edge of your application. That place is sometimes called the **composition root**.

---

## It's a spectrum, not an on/off switch

|Level|Example|Coupling|
|---|---|---|
|Creates the concrete class itself|`new EmailSender()` inside|Very tight|
|Receives the concrete class|constructor takes `EmailSender`|Medium (no creation, but still tied to the type)|
|Receives an interface|constructor takes `NotificationSender`|Loose|

Don't try to make everything loose. A small private helper that will never change doesn't need an interface. Loosen the boundaries where change or testing really matters.

---

## Related concepts, in short

- **Cohesion:** how focused a single class is on one job. Good design is _high cohesion, low coupling_.
- **Dependency Inversion Principle (the "D" in SOLID):** high-level code (`OrderService`) should depend on abstractions, not on low-level details (`EmailSender`). Move 1 above is this principle.
- **Dependency Injection (DI):** the technique of handing a class its dependencies from outside (Move 2 above). It is how you _achieve_ loose coupling.
- **Inversion of Control (IoC):** the bigger idea behind DI. Instead of your class controlling the creation of its helpers, control is handed to someone else.

---

## Now, Spring Boot: someone else calls `new` for you

Manual wiring is fine for 3 classes. In a real app with 200 classes that depend on each other, your `main` method becomes a giant, fragile tower of nested `new` calls:

```java
new OrderController(new OrderService(new EmailSender(), new OrderRepository(new DataSource(...))))
```

That's unpleasant, and you'd have to maintain it by hand. **Spring takes over that job.** It becomes the one who calls `new`, figures out the correct order, and passes everything through constructors. The part of Spring that does this is called the **IoC container**.

```java
@Component
public class EmailSender implements NotificationSender { /* ... */ }

@Service
public class OrderService {
    private final NotificationSender sender;

    public OrderService(NotificationSender sender) {   // same loose design as before
        this.sender = sender;
    }
}
```

What Spring does, in plain steps:

1. At startup it **scans** your packages and finds classes marked `@Component`, `@Service`, `@Repository`, `@Controller`. Each becomes a **bean**, meaning an object the container manages.
2. It sees that `OrderService`'s constructor needs a `NotificationSender`.
3. It finds a bean that implements that interface, which is `EmailSender`.
4. It creates `EmailSender` first, then creates `OrderService` and passes it in.
5. By default each bean is created once and shared (a **singleton**), which solves the "many copies" problem from earlier.

Your `OrderService` code is identical to the hand-wired version. You haven't changed the design, you've only moved the `new` calls to the container.

To swap implementations, you change which bean Spring picks and never edit `OrderService`: use `@Primary`, `@Qualifier("sms")`, or `@Profile("test")`. If two beans match and you give no hint, Spring complains about ambiguity rather than guessing.

**Two honest cautions:**

- Spring does **not** automatically make your code loosely coupled. If your constructor asks for `EmailSender` (the concrete class), you're still tied to that type. The interface is your job.
- Prefer **constructor injection** (above) over `@Autowired` on fields. Field injection hides the dependencies again and brings back the testing pain.

---

## BeanFactory and ApplicationContext: the two faces of the container

"IoC container" is the idea. In Spring it's implemented by two interfaces:

**`BeanFactory`** is the basic, core container. Its job is just: create beans, wire their dependencies, hand them out with `getBean(...)`. It creates beans **lazily** (only when first asked for).

**`ApplicationContext`** _extends_ `BeanFactory`, so it does everything above and adds the features real applications need.

||BeanFactory|ApplicationContext|
|---|---|---|
|Create and wire beans (DI)|Yes|Yes|
|Singleton creation|Lazy (on first request)|**Eager** (all at startup, so wiring errors show up immediately)|
|Annotation scanning (`@Component`, etc.)|Minimal|Full support|
|Events (publish/listen)|No|Yes|
|Environment, profiles, properties|No|Yes|
|Internationalization (messages)|No|Yes|
|Resource loading|Limited|Yes|
|Used in Spring Boot|Behind the scenes|**This is what you actually get**|

When you run a Spring Boot app, `SpringApplication.run(...)` builds an `ApplicationContext` for you:

```java
ApplicationContext ctx = SpringApplication.run(DemoApplication.class, args);
OrderService service = ctx.getBean(OrderService.class);
```

You rarely call `getBean` yourself, because injection does it for you. Think of it this way: **`BeanFactory` is the engine, and `ApplicationContext` is the full car built around that engine.** Because the context creates singletons eagerly, a missing or ambiguous dependency crashes the app at startup, when you can fix it, rather than in the middle of a user's request.

---

## The whole story in one breath

Tight coupling means a class creates and knows its concrete helpers, so it's hard to change or test. Loose coupling means the class depends on an interface and has its helpers handed in through the constructor (DI). Doing that by hand gets tedious, so Spring's IoC container, in the form of the `ApplicationContext` (built on `BeanFactory`), creates and wires all your beans for you.







[[Spring Framework]]