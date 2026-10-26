


Encapsulation means keeping an object's data and the code that works on that data together in one class, and protecting that data so outside code can't change it freely. In Java, you do it by making fields `private` and letting other code reach them only through public methods. The class becomes the one place that controls how its own data is read and changed.

Think of a capsule: the medicine is sealed inside, and you take it in a controlled way. Or a bank: you can't walk into the vault and take cash, you ask a teller, and the teller checks the rules first. Encapsulation gives your objects a teller. This is the idea behind the whole topic, so let's build it step by step.

---

## 1. Encapsulation has two parts

People often remember only one, but the definition has both:

| Part | Meaning | In Java |
|---|---|---|
| Bundling | Data and the methods that use it live together | Fields and methods inside one class |
| Protecting | Outside code can't touch the data directly | `private` fields, controlled access through methods |

The second part, protecting, is what makes encapsulation valuable. Bundling alone is just what a class is.

---

## 2. What happens without it

```java
public class BankAccount {
    public double balance;
}
```

```java
BankAccount acc = new BankAccount();
acc.balance = -5000;       // nobody stopped this
acc.balance = 1_000_000;   // or this
```

Walkthrough:

- `balance` is `public`, so any code, anywhere, can set it to anything.
- There's no rule like "balance can't be negative," because there's nowhere to put the rule.
- If the data goes wrong, you'd have to search the **entire program** to find who broke it.

---

## 3. With encapsulation

```java
public class BankAccount {
    private double balance;

    public double getBalance() {
        return balance;
    }

    public void deposit(double amount) {
        if (amount <= 0) {
            throw new IllegalArgumentException("Deposit must be positive");
        }
        balance += amount;
    }

    public void withdraw(double amount) {
        if (amount <= 0 || amount > balance) {
            throw new IllegalArgumentException("Invalid withdrawal");
        }
        balance -= amount;
    }
}
```

Line by line:

- `private double balance;`: only code inside `BankAccount` can touch it. `acc.balance = -5000` now fails to compile.
- `getBalance()`: lets the outside *read* the value. It returns a number, so nobody can change the field through it.
- `deposit(...)`: the only way to add money, and it checks the amount first.
- `withdraw(...)`: the only way to remove money, and it blocks overdrafts.

The rules now live in **one place**. If the balance is ever wrong, you know the bug is inside this class.

| | Public field | Private field + methods |
|---|---|---|
| Who can change the data? | Anyone | Only the class's own methods |
| Where do rules live? | Nowhere (or copied everywhere) | One place |
| Can invalid values get in? | Yes | No, the methods guard it |
| Finding a bug | Search the whole program | Look inside the class |

---

## 4. Getters and setters: the common pattern

You'll see this constantly in Java:

```java
public class User {
    private String email;

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        if (email == null || !email.contains("@")) {
            throw new IllegalArgumentException("Invalid email");
        }
        this.email = email;
    }
}
```

- **Getter** reads a field. **Setter** changes it, usually with validation.

A very common mistake is to think "getters and setters = encapsulation." That's not quite right. Look at this:

```java
public class User {
    private String email;
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }   // no checks
}
```

This is `private` on the outside, but in practice it's the same as a public field, because the setter lets anyone put in anything. It has the *shape* of encapsulation without the *benefit*. The benefit comes from the class controlling its data, not from having the methods.

A better habit is to expose **behavior**, not raw access:

| Weak (exposes the data) | Stronger (exposes behavior) |
|---|---|
| `account.setBalance(account.getBalance() - 50)` | `account.withdraw(50)` |
| `order.setStatus("SHIPPED")` | `order.ship()` |

The stronger version tells the object *what to do*, and the object decides how to update itself.

---

## 4b. The trap with mutable objects

This one surprises many people:

```java
public class Team {
    private final List<String> members = new ArrayList<>();

    public List<String> getMembers() {
        return members;          // leaks the real list
    }
}
```

```java
team.getMembers().add("Intruder");   // modified the private list from outside
```

The field is `private`, and the outside still changed it. You returned a **reference** to the real list, and (as we saw with reference types) whoever holds that reference can modify the object. Fix it by returning a safe view or copy:

```java
public List<String> getMembers() {
    return Collections.unmodifiableList(members);
    // or: return List.copyOf(members);
}
```

Walkthrough:

- `unmodifiableList` gives a read-only view. Any `add` throws an exception.
- `List.copyOf` gives a separate copy, so changes to it don't affect the original.
- The same care applies when accepting a list through a constructor or setter: copy it, don't just store the caller's reference.

---

## 5. Access modifiers: the tools of encapsulation

Java gives you four levels of access. Choose the **narrowest** one that works.

| Modifier | Same class | Same package | Subclass (other package) | Everywhere |
|---|---|---|---|---|
| `private` | Yes | No | No | No |
| (none, package-private) | Yes | Yes | No | No |
| `protected` | Yes | Yes | Yes | No |
| `public` | Yes | Yes | Yes | Yes |

A good default rule: start with `private`, and open up only when something truly needs it.

---

## 6. The benefits

| Benefit | What it means | Example |
|---|---|---|
| Protects data | Invalid values can't get in | No negative balance |
| Rules in one place | Change a rule once | Change minimum deposit in `deposit()` |
| Freedom to change the inside | Callers aren't affected | Store money as `long` cents instead of `double` |
| Easier debugging | Few places can modify the data | Bug is inside the class |

The third benefit is worth seeing:

```java
public class BankAccount {
    private long cents;    // changed from double balance

    public double getBalance() {
        return cents / 100.0;
    }
}
```

The outside still calls `getBalance()` and has no idea the field changed. That could only be done safely because the field was `private`.

---

## 7. Encapsulation vs. abstraction

You asked earlier about abstraction, so here's how they relate. They're close cousins and easy to confuse.

| | Abstraction | Encapsulation |
|---|---|---|
| Main question | "What should the outside see?" | "How do I protect the inside?" |
| Focus | Design level: hide complexity | Implementation level: restrict access |
| Achieved with | Interfaces, abstract classes, clean public methods | `private` fields, access modifiers |
| Result | A simple surface | A guarded interior |

A short way to remember it: abstraction decides **what** to show, and encapsulation is the **lock** that enforces it. They work together: you design a simple surface (abstraction) and use `private` to make sure nobody bypasses it (encapsulation).

---

## 8. Encapsulation in Spring Boot

Since you work with Spring Boot, here's where you'll meet it:

- **Entities and DTOs** use private fields with getters and setters (or Lombok's `@Getter`/`@Setter`).
- **Services** keep dependencies `private final`, injected through the constructor, so nothing outside can swap them.
- **Records** (`record User(String name, String email) {}`) give you private final fields with read-only accessors, so encapsulation with less code.

```java
@Service
public class OrderService {
    private final PaymentMethod payment;   // private and final

    public OrderService(PaymentMethod payment) {
        this.payment = payment;
    }
}
```

---

## Related concept: Immutability (short summary)

An immutable object can't change after it's created: all fields are `private final` and there are no setters. It's the strongest form of encapsulation, because the data can't be modified at all, which also makes it safe to share between threads. `String` and records are common examples.

---

## Quick recap

- Encapsulation = bundle data with its methods **and** protect the data (usually `private` fields).
- The benefit comes from the class controlling its data, not just from having getters and setters.
- Prefer methods that express behavior (`withdraw`) over raw setters (`setBalance`).
- Watch out for leaking mutable objects like lists. Return copies or read-only views.
- Use the narrowest access modifier that works.
- Abstraction decides what to show. Encapsulation enforces it.




[[Java]]