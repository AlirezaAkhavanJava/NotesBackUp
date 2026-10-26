

Inheritance lets one class (the child) automatically get the fields and methods of another class (the parent), so you write shared code once instead of copying it. It also creates an "is-a" relationship: a `Dog` _is an_ `Animal`. That relationship is what lets you treat many different child objects as one parent type.
 Inheritance's own job is **reuse and classification**. Polymorphism is something inheritance _makes possible_, and abstraction is something you can _build with_ it. But neither one _needs_ inheritance. Let's separate these carefully, because this is a very common point of confusion.

---

## 1. Inheritance has two jobs

|Job|What it means|Example|
|---|---|---|
|Code reuse|The child gets the parent's code for free|`Dog` gets `eat()` and `sleep()` without rewriting them|
|Type relationship ("is-a")|A child can be used wherever the parent is expected|`Animal a = new Dog();`|

Everything else people say about inheritance grows from these two.

---

## 2. Job one: code reuse

```java
public class Employee {
    private String name;
    private double baseSalary;

    public Employee(String name, double baseSalary) {
        this.name = name;
        this.baseSalary = baseSalary;
    }

    public String getName() { return name; }
    public double getBaseSalary() { return baseSalary; }
}

public class Manager extends Employee {
    private double bonus;

    public Manager(String name, double baseSalary, double bonus) {
        super(name, baseSalary);
        this.bonus = bonus;
    }

    public double totalPay() {
        return getBaseSalary() + bonus;
    }
}
```

Line by line:

- `Manager extends Employee`: a `Manager` gets `name`, `baseSalary`, `getName()`, and `getBaseSalary()` without rewriting them.
- `super(name, baseSalary)`: calls the parent's constructor so the inherited part is set up first.
- `totalPay()`: new behavior that only managers have.

Without inheritance, you'd copy `name`, `baseSalary`, and both getters into `Manager`. Then a bug fix in one copy would need to be repeated in the other.

---

## 3. Job two: the "is-a" relationship

Because `Manager` is an `Employee`, this is legal:

```java
Employee e = new Manager("Sara", 4000, 500);
```

This is what unlocks polymorphism. Any method that accepts an `Employee` now accepts a `Manager` too:

```java
void printName(Employee e) {
    System.out.println(e.getName());
}

printName(new Manager("Sara", 4000, 500));   // works
```

---

## 4. Is inheritance for polymorphism? Not exactly

Here's the nuance that clears things up.

|Statement|True?|
|---|---|
|Inheritance _enables_ polymorphism|Yes|
|Polymorphism _requires_ inheritance|No|
|Inheritance exists _in order to_ give polymorphism|Not really, reuse and is-a are its own purpose|

Polymorphism in Java needs a shared **type** between objects. There are two ways to get one:

|Way to share a type|Keyword|Gives you|
|---|---|---|
|Class inheritance|`extends`|Shared code **and** shared type|
|Interface|`implements`|Shared type **only**, no inherited code (except `default` methods)|

So you can have full polymorphism with **no class inheritance at all**:

```java
public interface Notifier { void send(String msg); }

public class EmailNotifier implements Notifier { ... }
public class SmsNotifier implements Notifier { ... }

Notifier n = new SmsNotifier();   // polymorphism, no extends
```

Two unrelated classes, no parent class, and polymorphism works. Inheritance isn't required for it.

A technical note: Java people often say "inheritance" for both `extends` and `implements`. A cleaner way to talk is:

- **Implementation inheritance**: `extends` a class. You inherit code.
- **Interface inheritance**: `implements` an interface. You inherit a promise (a contract).

---

## 5. Is inheritance for abstraction? Also only partly

Abstraction means hiding the "how" and showing the "what." Inheritance can _help_ build it:

```java
public abstract class Shape {
    public abstract double area();
}

public class Circle extends Shape { ... }
public class Square extends Shape { ... }
```

Here `Shape` is an abstraction, and `Circle` and `Square` extend it. But look at what created the abstraction: the **design choice** to define `Shape` with an `area()` promise. Inheritance was just the wiring.

And again, abstraction exists without inheritance:

```java
public class EmailService {
    public void send(String to, String msg) { /* hidden SMTP details */ }
}
```

No parent, no child. Still abstraction, because the details are hidden behind `send`.

|Concept|Needs inheritance?|Other ways to get it|
|---|---|---|
|Abstraction|No|Private fields + public methods, interfaces, packages|
|Polymorphism|No|Interfaces|
|Code reuse|No|Composition (putting one object inside another)|

---

## 6. What inheritance is genuinely best at

Inheritance fits well when:

- There's a **true "is-a"** relationship (`Manager` is an `Employee`).
- Children share **real, stable code** with the parent.
- The parent is designed to be extended (a base class with clear hooks).

Examples you've already met: `ArrayList` extends `AbstractList`, `RuntimeException` extends `Exception`, and in Spring, your classes often extend framework base classes.

---

## 7. The warning: inheritance is the strongest coupling

A child is tightly tied to its parent. If the parent changes, every child can break.

```java
class Stack extends ArrayList<String> { ... }   // bad idea
```

A `Stack` is not really an `ArrayList`. Now it exposes `add(index, item)`, `remove(index)`, and everything else, which breaks stack rules. This is a classic misuse: using inheritance **only for code reuse** when there's no real "is-a."

The better version uses **composition** ("has-a"):

```java
class Stack {
    private final List<String> items = new ArrayList<>();

    public void push(String s) { items.add(s); }
    public String pop() { return items.remove(items.size() - 1); }
}
```

Walkthrough:

- `Stack` _has_ a list inside. It doesn't _become_ a list.
- Only `push` and `pop` are visible, so the abstraction stays clean.
- You can change the inside to a `LinkedList` later without breaking callers.

A well-known guideline from _Effective Java_ says: **favor composition over inheritance.** Use inheritance when the is-a relationship is real, and composition when you just want to reuse code.

---

## 8. Quick decision table

|Your situation|Choose|
|---|---|
|Real is-a, shared code, you control the parent|Inheritance (`extends`)|
|Want shared type with no shared code|Interface (`implements`)|
|Just want to reuse some behavior|Composition (has-a)|
|Many unrelated classes need the same capability|Interface|

---

## Related concept: Composition (short summary)

Composition means building a class by holding other objects as fields and delegating work to them. It's a "has-a" relationship (a `Car` has an `Engine`). It reuses code without the tight coupling of inheritance, which is why many developers prefer it as the default.

---

## Quick recap

- Inheritance's own purpose: **code reuse** and an **is-a type relationship**.
- It _enables_ polymorphism and can _help build_ abstraction, but it isn't the only way for either.
- Interfaces give you polymorphism and abstraction with no inherited code.
- Use `extends` for real is-a relationships. Otherwise, prefer composition.
- Rule of thumb: if you can't say "X **is a** Y" honestly, don't inherit.





[[Java]]