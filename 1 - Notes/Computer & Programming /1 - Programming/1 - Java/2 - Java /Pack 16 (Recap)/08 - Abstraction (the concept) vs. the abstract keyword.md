

Abstraction is a design idea. It means showing people only what they need to use something, and hiding how it works inside. When you drive a car, you use the steering wheel and pedals. You don't think about fuel injection or gear ratios. The car hides that complexity behind a simple surface. In code, abstraction lets other parts of your program say _what_ they want done without knowing _how_ it gets done.

`abstract` is a Java keyword. It's a tool the language gives you: it marks a class as incomplete (you can't create objects from it) or a method as having no body yet. It's one way to build abstraction, but it is not abstraction itself. You can have abstraction with no `abstract` keyword anywhere, and you can use `abstract` without achieving much abstraction at all. Let's see how.

---

## 1. Concept vs. tool: a quick comparison

||Abstraction|`abstract` keyword|
|---|---|---|
|What is it?|A design principle|A Java language feature|
|Where does it live?|In your head and your design|In your source code|
|Language-specific?|No. Python, C#, Go, and others all have it|Yes. Java, C#, and a few others|
|Question it answers|"What should the outside world see?"|"Should this class/method be left incomplete?"|
|Can you do it without the other?|Yes|Yes|

---

## 2. Abstraction without the `abstract` keyword

Look at this code. There isn't a single `abstract` in it:

```java
public class EmailSender {
    public void send(String to, String message) {
        // connects to the SMTP server
        // authenticates
        // formats the headers
        // sends the bytes
        // handles retries
    }
}
```

And the caller:

```java
EmailSender sender = new EmailSender();
sender.send("sara@example.com", "Hello!");
```

Walk through it:

- The caller sees one method: `send`.
- The caller does **not** see SMTP, authentication, headers, or retries.
- If you later change how emails are sent, the caller doesn't change.

That is abstraction. The complexity is hidden behind a simple method. Even a plain class with `private` fields and a `public` method gives you abstraction. This is why we say the concept is bigger than the keyword.

---

## 3. Abstraction with an interface (still no `abstract`)

Interfaces are probably the purest form of abstraction in Java:

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

Line by line:

- `interface PaymentMethod` defines a _contract_: "anything that is a payment method can `pay`."
- `CreditCard` and `PayPal` each fill in their own _how_.
- Code that uses `PaymentMethod` doesn't care which one it got.

```java
void checkout(PaymentMethod method) {
    method.pay(49.99);
}
```

`checkout` only knows the _what_ (`pay`). That's abstraction at work. Notice that Java doesn't make you write `abstract` on interface methods. They're implicitly abstract, but you never type the word. The mechanism is there, the keyword isn't.

---

## 4. What the `abstract` keyword actually does

Now the tool itself. `abstract` has two uses.

**On a class:** "This class is incomplete. You can't instantiate it, only extend it."

**On a method:** "This method has no body. Subclasses must provide one."

```java
public abstract class Shape {
    private String color;

    public Shape(String color) {
        this.color = color;
    }

    public abstract double area();   // no body

    public String describe() {       // normal method, has a body
        return color + " shape with area " + area();
    }
}
```

```java
public class Circle extends Shape {
    private double radius;

    public Circle(String color, double radius) {
        super(color);
        this.radius = radius;
    }

    @Override
    public double area() {
        return Math.PI * radius * radius;
    }
}
```

Line by line:

- `abstract class Shape`: you can never write `new Shape(...)`. A "generic shape" doesn't really exist.
- `abstract double area();`: every shape has an area, but how you calculate it depends on the shape. So there's no body here.
- `describe()` is a normal method. It already works and calls `area()`, which will be filled in by the subclass.
- `Circle extends Shape` **must** implement `area()`, or the compiler gives an error.

So the keyword gives you two things: a _shared base_ (fields and ready-made methods) and a _rule_ (subclasses must complete the missing pieces).

---

## 5. The reverse trap: `abstract` without good abstraction

Using the keyword doesn't guarantee a good design:

```java
public abstract class Utils {
    public abstract void doStuff();
    public abstract void doMoreStuff();
}
```

This uses `abstract`, but it hides nothing and models no clear idea. Nobody can tell _what_ it represents. The keyword is present and the abstraction is missing.

A good abstraction has a clear answer to: **"What is this thing, and what can I ask it to do?"**

---

## 6. Where they overlap

You said they have a "kinda same purpose," and that's right. Both are about separating _what_ from _how_:

|Tool|How it separates what from how|
|---|---|
|Plain class with `private` fields|Hides data and internal steps|
|Interface|Declares _what_, leaves _how_ to implementers|
|Abstract class (`abstract` keyword)|Declares _what_ for some methods, provides _how_ for others|
|Abstract method|Declares _what_ with no _how_ at all|

So `abstract` is one tool in a toolbox. Abstraction is the goal the whole toolbox serves.

---

## 7. Choosing between them in Java

|You need...|Use|
|---|---|
|A pure contract, no shared state|`interface`|
|A contract plus shared fields or ready-made code|`abstract class`|
|To hide internals of a normal class|`private` + a clean public method|

---

## Related concept: Encapsulation (short summary)

People often mix abstraction with **encapsulation**. Encapsulation means bundling data with the methods that use it, and protecting that data (usually with `private`). Abstraction decides _what to show_. Encapsulation is the _protective wall_ that makes hiding possible. They work together, but they're different ideas.

---

## Quick recap

- **Abstraction** = hide the _how_, show the _what_. A design idea that works in any language.
- **`abstract`** = a Java keyword that makes a class or method incomplete so subclasses finish it.
- You can have abstraction with no `abstract` keyword (plain classes, interfaces).
- You can use `abstract` and still have a poor abstraction.
- The keyword is a tool. The concept is the goal.





[[Java]]