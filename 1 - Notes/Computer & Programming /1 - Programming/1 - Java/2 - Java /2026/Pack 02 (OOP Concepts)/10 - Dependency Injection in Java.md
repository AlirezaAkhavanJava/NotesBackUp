

**Dependency injection** (DI) is a design technique in which a class receives the objects it depends on from outside, instead of creating them itself. A **dependency** is any object a class uses to do its work. **Injection** is the act of supplying that object to the class, usually through its constructor.

The idea is simple, but it changes how you structure a whole program. Once you see the problem it solves, the rest of this lesson follows from it.

## The problem: a class that builds its own dependencies

Consider a class that sends school notices to parents:

```java
class SchoolNotifier {
    private final EmailSender sender = new EmailSender();   // the class creates its own dependency

    void notifyParents(String message) {
        sender.send("parents@school.example", message);
    }
}
```

This works, but it has three costs:

1. **You cannot change the sender without editing `SchoolNotifier`.** If you want SMS later, the class must change.
2. **You cannot test it without sending real email.** Any test of `notifyParents` calls the real `EmailSender`.
3. **The class is responsible for knowing how its dependencies are built.** If `EmailSender` later needs a server address or a password, every class that does `new EmailSender()` must change.

These costs come from **coupling**: the class is tied to one concrete implementation and to the details of creating it.

## The fix: receive the dependency

Here is the same class with the dependency supplied from outside:

```java
interface MessageSender {
    void send(String to, String text);
}

class EmailSender implements MessageSender {
    public void send(String to, String text) {
        System.out.println("Email to " + to + ": " + text);
    }
}

class SchoolNotifier {
    private final MessageSender sender;      // depends on the interface, not the implementation

    SchoolNotifier(MessageSender sender) {   // the dependency arrives through the constructor
        this.sender = sender;
    }

    void notifyParents(String message) {
        sender.send("parents@school.example", message);
    }
}
```

Now `SchoolNotifier` does not know which sender it has. It knows only the `MessageSender` contract. Three things changed:

- The class no longer uses `new` for its dependency, so it is not responsible for building it.
- The field is `final`, so once the object is built, its dependency cannot be swapped by accident.
- The dependency is declared in the constructor signature, so anyone reading the class sees exactly what it needs.

## Inversion of control

The principle behind DI is called **inversion of control** (IoC). Normally, your code calls libraries and decides when and how to create objects. With IoC, something else takes over the job of creating objects and connecting them, and your classes simply declare what they need.

The terms are related but not identical:

- **IoC** is the general principle: the control over object creation and wiring moves away from the class that uses the objects.
- **DI** is the most common way to apply IoC: dependencies are passed in from outside.

Other forms of IoC exist, such as callbacks and template methods, but in Java and Spring the two terms are used together almost always.

## The three injection styles

Java offers three ways to supply a dependency. Knowing the differences is part of using DI well.

**Constructor injection** passes dependencies through the constructor, as shown above. The object cannot exist without them, and `final` fields guarantee they never change.

**Setter injection** passes dependencies through setter methods after construction:

```java
class SchoolNotifier {
    private MessageSender sender;

    void setSender(MessageSender sender) {
        this.sender = sender;
    }

    void notifyParents(String message) {
        sender.send("parents@school.example", message);   // may be null if setSender was never called
    }
}
```

Setter injection allows the object to exist in a half-built state. Use it only for truly optional dependencies, where the class has a sensible behavior without them.

**Field injection** marks a field and lets a framework set it through reflection, with no constructor or setter:

```java
class SchoolNotifier {
    @Inject                       // framework sets this field directly
    MessageSender sender;
}
```

The class can be created with `new SchoolNotifier()` and then has a null `sender` unless a framework fills it. Its dependencies are hidden from anyone reading the constructor. For these reasons, constructor injection is the recommended default, and field injection should be avoided in code you write.

## Doing DI by hand: the composition root

You do not need a framework to use DI. The simplest version creates all objects in one place, called the **composition root**, usually `main`:

```java
public class Main {
    public static void main(String[] args) {
        MessageSender sender = new EmailSender();          // choose the implementation here
        SchoolNotifier notifier = new SchoolNotifier(sender);
        notifier.notifyParents("Field trip on Friday");
    }
}
```

All the decisions about which implementation to use happen in one place. To switch to SMS, you change one line here, and `SchoolNotifier` stays untouched. For a small program this is ideal. The trouble appears when an application has hundreds of classes, each with several dependencies, and the composition root grows large. That is the problem a DI container solves.

## Testing with DI

Constructor injection makes testing simple, because a test can supply its own dependency. No framework or mocking library is needed for this basic case:

```java
class RecordingSender implements MessageSender {
    final java.util.List<String> sent = new java.util.ArrayList<>();

    public void send(String to, String text) {
        sent.add(to + ": " + text);       // records instead of sending
    }
}

public class SchoolNotifierTest {
    public static void main(String[] args) {
        RecordingSender fake = new RecordingSender();
        SchoolNotifier notifier = new SchoolNotifier(fake);

        notifier.notifyParents("Exam moved to Monday");

        System.out.println(fake.sent.get(0));
        // prints: parents@school.example: Exam moved to Monday
    }
}
```

The test verifies the behavior of `SchoolNotifier` without touching real email. This is the most practical benefit of DI, and most of the testing style in Spring applications depends on it.

## DI containers and Spring

A **DI container** is a framework that performs the wiring you did by hand. You declare the classes and their dependencies, and the container creates objects in the right order and passes them in. Spring is the container you will use in Spring Boot.

In Spring, you mark classes so the container knows about them:

```java
public interface MessageSender {
    void send(String to, String text);
}

@Component
public class EmailSender implements MessageSender {
    public void send(String to, String text) {
        System.out.println("Email to " + to + ": " + text);
    }
}

@Service
public class SchoolNotifier {
    private final MessageSender sender;

    public SchoolNotifier(MessageSender sender) {   // Spring supplies this automatically
        this.sender = sender;
    }

    public void notifyParents(String message) {
        sender.send("parents@school.example", message);
    }
}
```

With a single constructor, Spring uses it and injects the dependency without any annotation on the constructor. The `@Component` and `@Service` annotations are the labels from our annotation lessons: they tell Spring's scanner to create and manage these classes, which are called **beans**. Your code never calls `new SchoolNotifier(...)`. Spring does, when the application starts.

### When there are two implementations

If two classes implement `MessageSender`, Spring cannot decide which one to inject and fails at startup. You resolve this in one of two ways:

```java
@Component
@Primary                         // used when no other choice is specified
public class EmailSender implements MessageSender { ... }

@Component
public class SmsSender implements MessageSender { ... }
```

or, to choose explicitly at the injection point:

```java
public SchoolNotifier(@Qualifier("smsSender") MessageSender sender) {
    this.sender = sender;
}
```

Spring names beans after their class with a lowercase first letter by default, so `SmsSender` becomes `smsSender`.

### Scopes

A bean's **scope** controls how many instances Spring creates. The default is **singleton**: one instance per application context, shared by everything that injects it. That is why a singleton bean should not store per-request data in a field, because all users would share it. Other scopes, such as `prototype` (a new instance each time), exist for special cases.

## How a container works underneath

To understand what Spring is doing, build a tiny container. It uses the reflection skills from earlier lessons: it reads a class's constructor parameter types and recursively creates the dependencies. Save this as `MiniContainer.java` with the `MessageSender`, `EmailSender`, and `SchoolNotifier` classes from the previous section in the same folder:

```java
import java.lang.reflect.Constructor;
import java.util.HashMap;
import java.util.Map;

class MiniContainer {
    private final Map<Class<?>, Class<?>> bindings = new HashMap<>();    // interface -> implementation
    private final Map<Class<?>, Object> singletons = new HashMap<>();    // one instance per type

    void bind(Class<?> contract, Class<?> implementation) {
        bindings.put(contract, implementation);
    }

    <T> T get(Class<T> type) throws ReflectiveOperationException {
        if (singletons.containsKey(type)) {
            return type.cast(singletons.get(type));                      // reuse the existing instance
        }

        Class<?> implementation = bindings.getOrDefault(type, type);     // resolve the interface, if bound
        Constructor<?> constructor = implementation.getDeclaredConstructors()[0];
        Class<?>[] neededTypes = constructor.getParameterTypes();        // what the constructor asks for

        Object[] args = new Object[neededTypes.length];
        for (int i = 0; i < neededTypes.length; i++) {
            args[i] = get(neededTypes[i]);                               // build each dependency recursively
        }

        Object instance = constructor.newInstance(args);
        singletons.put(type, instance);
        return type.cast(instance);
    }
}

public class ContainerDemo {
    public static void main(String[] args) throws ReflectiveOperationException {
        MiniContainer container = new MiniContainer();
        container.bind(MessageSender.class, EmailSender.class);          // declare the wiring once

        SchoolNotifier notifier = container.get(SchoolNotifier.class);   // container builds the graph
        notifier.notifyParents("Parent evening on Thursday");
    }
}
```

Run it:

```bash
javac *.java
java ContainerDemo
```

The output is `Email to parents@school.example: Parent evening on Thursday`.

What the container does:

- `get(SchoolNotifier.class)` looks at its constructor and sees it needs a `MessageSender`.
- `get(MessageSender.class)` finds the binding to `EmailSender` and builds that instead.
- `EmailSender` has no parameters, so the recursion stops there.
- The container then calls `newInstance` on each class in dependency order, and caches the result so later requests share it.

Spring does the same job with a much richer set of rules: it scans for annotations, handles circular references, manages scopes and proxies, and reports errors at startup. The core idea is what you see here: read the constructor, build the dependencies, pass them in.

Two limitations of this mini version are worth noting. It takes the first constructor and would fail if a class had several. It also does not detect cycles, so two classes that need each other would recurse forever. Spring handles both cases with explicit rules.

## Pitfalls to avoid

**Circular dependencies.** If `A` needs `B` and `B` needs `A` through constructors, neither can be built first. Spring fails at startup with a clear error. The fix is usually a design change: extract the shared logic into a third class that both depend on.

**Too many constructor parameters.** A constructor with eight dependencies is a warning sign that the class does too much. DI makes the cost visible, which is a benefit. Split the class.

**Injecting an interface when only one implementation will ever exist.** This is not wrong, but it can add noise. Interfaces pay off at boundaries you actually need to swap or test.

**Using `new` for a dependency inside a bean.** If a bean creates its own collaborator with `new`, Spring cannot manage it, cannot inject a test double, and cannot apply annotations such as `@Transactional` to it. Let the container create the dependency.

**Field injection in code you write.** It hides dependencies, prevents `final`, and makes unit tests depend on Spring. Use constructor injection.

**Storing state in singleton beans.** Because one instance is shared, fields that hold request-specific data can leak between users.

## How you'll use this

Almost every Spring Boot class you write will follow this pattern: a `@Service` or `@Controller` that receives its repositories and helpers through its constructor. In tests, you will construct the class with fakes, as in the `RecordingSender` example, which requires no Spring at all. When you read Spring code later, you will recognize the `final` fields and constructor parameters as the wiring that the container performs.

For Family Inbox, a `MessageDeliveryService` could receive a `MessageRepository` and a `NotificationSender` through its constructor. Your web controller would receive the service the same way. The web layer, business rules, and storage stay separate, and you can test the business rules without a database or a server.




[[Java]]