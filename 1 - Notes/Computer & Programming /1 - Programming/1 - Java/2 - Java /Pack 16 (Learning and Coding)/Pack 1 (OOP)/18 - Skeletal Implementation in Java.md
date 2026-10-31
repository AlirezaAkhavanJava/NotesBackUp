

The **Skeletal Implementation pattern** is a way of designing a type in three layers. First, an **interface** defines the contract, meaning what the type can do. Second, an **abstract class** (the "skeleton") implements most of that contract, so the common work is written once. Third, **concrete classes** extend the skeleton and fill in only the few parts that are truly different.

You get the best of both worlds. Callers depend on the interface, which keeps your design flexible. Implementers extend the skeleton, which saves them from rewriting the same code over and over. The name comes from _Effective Java_ (Item 20), and you already use it daily: `List` (interface), `AbstractList` (skeleton), `ArrayList` (concrete).

---

## 1. The three layers

|Layer|Role|Contains|Example|
|---|---|---|---|
|Interface|The contract: what callers can rely on|Method signatures, maybe a few `default` methods|`MessageSender`|
|Abstract class|The skeleton: shared logic and shared state|Real methods, a few `abstract` methods|`AbstractMessageSender`|
|Concrete class|The details: only what is unique|Implementations of the abstract methods|`EmailSender`, `SmsSender`|

The rule of thumb: **the interface says _what_, the skeleton says _how in general_, and the concrete class says _how exactly_.**

---

## 2. Building one step by step

Let's build a message-sending system. Every sender must validate the message, format it, deliver it, and log it. Only the formatting and delivery differ between email and SMS.

### Step 1: The interface (the contract)

```java
public interface MessageSender {
    void send(String to, String message);
}
```

This is all a caller ever needs to know. A caller writes `MessageSender sender = ...; sender.send(...)` and never cares which class is behind it.

### Step 2: The abstract class (the skeleton)

```java
public abstract class AbstractMessageSender implements MessageSender {

    @Override
    public final void send(String to, String message) {
        validate(to, message);
        String formatted = format(message);
        deliver(to, formatted);
        log(to);
    }

    private void validate(String to, String message) {
        if (to == null || to.isBlank()) {
            throw new IllegalArgumentException("Recipient is required");
        }
        if (message == null || message.isBlank()) {
            throw new IllegalArgumentException("Message is required");
        }
    }

    protected abstract String format(String message);

    protected abstract void deliver(String to, String formatted);

    private void log(String to) {
        System.out.println("Message sent to " + to);
    }
}
```

Line by line:

- `abstract class AbstractMessageSender implements MessageSender`: the skeleton promises to fulfil the contract, but it is allowed to leave some methods unfinished because it is abstract.
- `public final void send(...)`: this is the **template method**. It fixes the _order_ of the steps: validate, format, deliver, log. `final` means no subclass can reorder or skip them.
- `validate(...)` and `log(...)` are `private`. They are shared work that subclasses neither need nor are allowed to touch. That is encapsulation.
- `protected abstract String format(...)` and `protected abstract void deliver(...)` are the **hooks**, the gaps a subclass must fill. They are `protected` because only subclasses should call them, never outside code.

### Step 3: The concrete classes (the details)

```java
public class EmailSender extends AbstractMessageSender {

    @Override
    protected String format(String message) {
        return "<html><body>" + message + "</body></html>";
    }

    @Override
    protected void deliver(String to, String formatted) {
        System.out.println("SMTP -> " + to + ": " + formatted);
    }
}

public class SmsSender extends AbstractMessageSender {

    @Override
    protected String format(String message) {
        return message.length() > 160 ? message.substring(0, 160) : message;
    }

    @Override
    protected void deliver(String to, String formatted) {
        System.out.println("SMS gateway -> " + to + ": " + formatted);
    }
}
```

Each class is tiny. Neither one repeats validation or logging, and neither one can break the order of steps.

### Step 4: Using it

```java
MessageSender sender = new EmailSender();
sender.send("ana@example.com", "Hello!");
```

The variable type is the **interface**. Switch to `new SmsSender()` and nothing else changes. That is polymorphism working for you.

---

## 3. A real JDK example you can try

`AbstractList` is a skeleton. To make a read-only list you only implement two methods:

```java
import java.util.AbstractList;

public class Countdown extends AbstractList<Integer> {
    private final int start;

    public Countdown(int start) { this.start = start; }

    @Override
    public Integer get(int index) { return start - index; }

    @Override
    public int size() { return start + 1; }
}
```

With just `get` and `size`, you automatically get `iterator()`, `contains()`, `indexOf()`, `equals()`, `hashCode()`, `toString()`, `stream()` and more, all built by the skeleton on top of your two methods. Try `System.out.println(new Countdown(3));` and you will see `[3, 2, 1, 0]`.

---

## 4. Why not just use `default` methods in the interface?

Since Java 8, interfaces can have `default` methods, so people often ask why we still need the skeleton.

||Interface with `default` methods|Abstract class skeleton|
|---|---|---|
|Can hold fields (state)|No (only constants)|Yes|
|Can have `private`/`protected` helpers for subclasses|Only `private` (Java 9+), no `protected`|Yes, any visibility|
|Can use `final` to lock the algorithm|No|Yes|
|Can have constructors|No|Yes|
|Class can combine several|Yes, many interfaces|No, only one superclass|

So default methods are great for small, stateless conveniences. The skeleton is better when you need state, locked steps or protected hooks. In practice they work together: the interface may offer a few defaults, and the skeleton does the heavy lifting.

---

## 5. Rules and guidelines for doing it well

1. **Callers depend on the interface, never on the skeleton.** Declare variables, parameters and return types as `MessageSender`, not `AbstractMessageSender`.
2. **The skeleton is a helper, not a requirement.** Anyone must still be able to implement the interface directly, without extending your abstract class.
3. **Name it `AbstractXxx`.** This is the Java convention (`AbstractList`, `AbstractMap`, `AbstractSet`).
4. **Make the template method `final`** when the order of steps matters.
5. **Make hooks `protected abstract`**, so they are visible only to subclasses.
6. **Document self-use.** If one overridable method calls another, write that in the Javadoc. Otherwise subclasses cannot know what overriding will affect.
7. **Never call overridable methods from the skeleton's constructor.** The subclass's fields are not initialised yet, so you can get surprising `null` values.

---

## 6. What if your class already extends something else?

Java allows only one superclass. If `LoggingEmailSender` must extend `SomeOtherBase`, it cannot also extend the skeleton. The classic workaround is **simulated multiple inheritance**:

```java
public class LoggingEmailSender extends SomeOtherBase implements MessageSender {

    private final InnerSender delegate = new InnerSender();

    @Override
    public void send(String to, String message) {
        delegate.send(to, message);
    }

    private class InnerSender extends AbstractMessageSender {
        @Override protected String format(String m) { return m; }
        @Override protected void deliver(String to, String f) { /* ... */ }
    }
}
```

The outer class implements the interface and forwards calls to a private inner class that extends the skeleton. It is more code, but it keeps all your options open.

---

## 7. Checking it against the OOP rules

|Principle|How the pattern respects it|
|---|---|
|**Abstraction**|The interface hides all details. Callers see only `send(...)`.|
|**Encapsulation**|`validate` and `log` are private. Hooks are protected. Nothing leaks.|
|**Inheritance**|Concrete classes reuse the skeleton's code with a true "is-a" relationship.|
|**Polymorphism**|Any `MessageSender` can be swapped in at runtime.|
|**Liskov Substitution**|Every concrete class works wherever the interface is expected, because `final send()` guarantees the same behaviour.|
|**Open/Closed**|Add `PushSender` without editing any existing class.|
|**Dependency Inversion**|High-level code depends on the interface, not on concrete classes.|

---

## 8. Common mistakes

- **Using the skeleton as a type** (`AbstractMessageSender s = ...`). This ties callers to inheritance and defeats the purpose.
- **Forgetting `final` on the template method**, so a subclass accidentally skips validation.
- **Too many hooks.** If a subclass must implement ten methods, the skeleton is not doing its job. Aim for as few as possible.
- **Making the hierarchy deep.** Interface, skeleton, concrete is the sweet spot. More layers become hard to follow.

---

## 9. Related concepts, in short

- **Template Method pattern:** the skeleton's `send()` _is_ this pattern. A fixed algorithm in a superclass, with some steps deferred to subclasses. Skeletal implementation is Template Method plus an interface on top.
- **Strategy pattern:** the alternative based on _composition_. Instead of extending, you pass in a `Formatter` and a `Deliverer` object. It is more flexible at runtime, but a bit more wiring.
- **Default methods:** small interface-level conveniences, covered in the comparison above.

---

## Quick recap

Interface = contract. Abstract class = shared code and locked steps. Concrete classes = only what differs. Callers talk to the interface alone.





[[Java]]