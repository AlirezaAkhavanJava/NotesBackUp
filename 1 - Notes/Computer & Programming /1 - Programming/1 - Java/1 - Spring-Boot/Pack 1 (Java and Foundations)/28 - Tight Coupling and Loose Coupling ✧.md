
Coupling describes how much one class knows about and depends on another. In **tight coupling**, a class creates its own dependencies and is locked to one concrete implementation. In **loose coupling**, a class only knows an interface and receives the implementation from outside, so you can swap it without touching the class.

Spring Boot is built around the second style. Its IoC container creates the objects and injects them, so your classes never have to build their dependencies themselves.

## Tight coupling

```java
@Service
public class OrderService {

    private final EmailNotifier notifier = new EmailNotifier(); // hard-wired

    public void placeOrder(Order order) {
        // ...
        notifier.send("Order placed");
    }
}
```

Here are the problems:

- `OrderService` is stuck with `EmailNotifier`. To use SMS instead, you must edit `OrderService`.
- You can't unit test it without a real `EmailNotifier`, because there is no way to pass in a fake.
- If `EmailNotifier`'s constructor changes, `OrderService` breaks too.

## Loose coupling

Step 1: depend on an interface.

```java
public interface Notifier {
    void send(String message);
}

@Component
public class EmailNotifier implements Notifier {
    public void send(String message) { /* send email */ }
}
```

Step 2: let Spring inject it through the constructor.

```java
@Service
public class OrderService {

    private final Notifier notifier;

    public OrderService(Notifier notifier) { // Spring injects the bean
        this.notifier = notifier;
    }

    public void placeOrder(Order order) {
        notifier.send("Order placed");
    }
}
```

Now `OrderService` knows only `Notifier`. It doesn't know which implementation it gets or how it is built.

Here is what you gain:

- **Swapping:** add `@Component SmsNotifier implements Notifier` and mark one with `@Primary` or `@Qualifier("sms")`. `OrderService` stays unchanged.
- **Testing:** pass a mock directly, with no Spring needed:

```java
OrderService service = new OrderService(msg -> System.out.println("fake: " + msg));
```

- **Config-driven choice:** use `@ConditionalOnProperty` or `@Profile("dev")` to pick the implementation per environment.

## Quick comparison

||Tight|Loose|
|---|---|---|
|Dependency created by|the class itself (`new`)|Spring (injected)|
|Depends on|concrete class|interface|
|Swap implementation|edit the class|change a bean or config|
|Unit testing|hard|easy|

Interface plus constructor injection is the standard way to get loose coupling in Spring Boot. Field injection with `@Autowired` also works, but it hides dependencies and makes plain `new` testing awkward.


[[Spring Framework]]