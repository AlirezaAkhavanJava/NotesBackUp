


A getter that only does `return name;` and a setter that only does `this.name = name;` are close to useless. If that's all they do, a public field behaves the same way, and you've just written extra code. Many experienced developers agree with you on this point, and it's a known criticism of "getter/setter everywhere" style.

So why do they exist? Because a getter or setter is a **method**, and a method can do things a field can never do: check, convert, calculate, protect, log, notify, or change its mind later. The plain version is only a _placeholder_ that keeps that door open. Let's look at what actually goes inside them in real applications, and then at the one real argument for the plain version.

---

## 1. Why a field can't do what a method can

A public field is a fixed deal: whatever you write is stored, whatever you read is returned, and there's no code in between. A method is code in between.

|Ability|Public field|Getter / setter|
|---|---|---|
|Reject bad values|No|Yes|
|Clean up values before storing|No|Yes|
|Calculate a value instead of storing it|No|Yes|
|Make something read-only|Only with `final`|Yes (getter without setter)|
|Run extra code when changed|No|Yes|
|Return a safe copy|No|Yes|
|Change how it's stored later without breaking callers|No|Yes|
|Be declared in an interface|No|Yes|
|Be overridden by a subclass|No|Yes|

Each row is a real use. Let's walk through them with code.

---

## 2. Setter that validates

```java
public class User {
    private String email;

    public void setEmail(String email) {
        if (email == null || !email.contains("@")) {
            throw new IllegalArgumentException("Invalid email: " + email);
        }
        this.email = email;
    }
}
```

- The setter is the **gate**. Nothing invalid can enter.
- With a public field, `user.email = "banana"` would silently succeed, and you'd find the bug three layers later when sending an email fails.

---

## 3. Setter that cleans the value

```java
public void setEmail(String email) {
    if (email == null) {
        throw new IllegalArgumentException("Email required");
    }
    this.email = email.trim().toLowerCase();
}
```

- Users type `" Sara@Example.COM "`.
- The setter stores `"sara@example.com"`, so lookups and duplicate checks work correctly everywhere.
- The caller doesn't need to remember to clean the input. The class does it every time, automatically.

---

## 4. Getter that calculates (no field behind it at all)

```java
public class Person {
    private String firstName;
    private String lastName;
    private LocalDate birthDate;

    public String getFullName() {
        return firstName + " " + lastName;
    }

    public int getAge() {
        return Period.between(birthDate, LocalDate.now()).getYears();
    }
}
```

Walkthrough:

- There's **no** `fullName` or `age` field. Both are computed when you ask.
- If you stored `age` in a field, it would go stale on every birthday.
- To the caller, `person.getAge()` looks the same as reading a field. The caller doesn't know or care that it's calculated.

A public field can't do this. This is one of the clearest wins.

---

## 5. Getter with no setter (read-only)

```java
public class Order {
    private final Long id;
    private final LocalDateTime createdAt;

    public Order(Long id) {
        this.id = id;
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
```

- An order's ID and creation time should never change after creation.
- No setter means nobody can change them.
- This is the opposite of "getters and setters always come in pairs." **Many fields should have a getter only, or neither.**

---

## 6. Getter that protects (defensive copy)

```java
public class Team {
    private final List<String> members = new ArrayList<>();

    public List<String> getMembers() {
        return List.copyOf(members);   // safe copy
    }

    public void addMember(String name) {
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("Name required");
        }
        members.add(name);
    }
}
```

- The getter returns a copy, so outside code can't sneak around the rules.
- `addMember` is a **behavior method** (not a plain setter), and it validates. This is better design than exposing the list.

---

## 7. Setter that triggers something

```java
public class Product {
    private double price;
    private final List<PriceListener> listeners = new ArrayList<>();

    public void setPrice(double newPrice) {
        if (newPrice < 0) {
            throw new IllegalArgumentException("Price can't be negative");
        }
        double old = this.price;
        this.price = newPrice;
        for (PriceListener l : listeners) {
            l.priceChanged(old, newPrice);
        }
    }
}
```

- When the price changes, other parts (UI, cache, audit log) get notified.
- A public field can't announce "I changed." A setter can. This is how Java GUI binding and many event systems work (`PropertyChangeSupport` in the JDK does exactly this).

---

## 8. Getter with lazy loading and caching

```java
public class Report {
    private List<Row> rows;

    public List<Row> getRows() {
        if (rows == null) {
            rows = loadFromDatabase();   // expensive, only on first use
        }
        return rows;
    }
}
```

- The data is loaded **only when first requested**, then reused.
- Callers just call `getRows()`. They don't know it's lazy.
- Hibernate/JPA uses this same idea with proxies for lazy relationships, which is only possible because access goes through methods.

---

## 9. Real JPA entity in Spring Boot

Since you use Spring Boot and PostgreSQL, here's what a realistic entity looks like:

```java
@Entity
public class Customer {

    @Id
    @GeneratedValue
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    private String firstName;
    private String lastName;

    @OneToMany(mappedBy = "customer", cascade = CascadeType.ALL)
    private List<Order> orders = new ArrayList<>();

    protected Customer() {}   // for JPA only

    public Customer(String email, String firstName, String lastName) {
        setEmail(email);
        this.firstName = firstName;
        this.lastName = lastName;
    }

    public Long getId() { return id; }          // no setId: database owns it

    public String getEmail() { return email; }

    public void setEmail(String email) {
        if (email == null || !email.contains("@")) {
            throw new IllegalArgumentException("Invalid email");
        }
        this.email = email.trim().toLowerCase();
    }

    public String getFullName() {               // calculated, not stored
        return firstName + " " + lastName;
    }

    public List<Order> getOrders() {            // read-only view
        return Collections.unmodifiableList(orders);
    }

    public void addOrder(Order order) {         // behavior, keeps both sides in sync
        orders.add(order);
        order.setCustomer(this);
    }
}
```

Line by line:

- `getId()` only: the database generates the ID, so nobody should set it.
- `setEmail(...)` validates and normalizes. The constructor also calls it, so the rules apply from the start.
- `getFullName()` is computed. It's not a column in the table.
- `getOrders()` returns a read-only view, so outside code can't edit the list directly.
- `addOrder(...)` is not a getter or setter at all. It's a **business method** that keeps the two sides of the relationship in sync. This is a very common pattern in JPA.

Notice that this class has about as many "special" methods as plain ones. That's what real encapsulation looks like.

---

## 10. The one honest argument for plain getters and setters

Here's the fair case for the plain `return field;` version. Suppose you publish a class with a public field:

```java
public class Account {
    public double balance;
}
```

A hundred places use `account.balance`. A year later you need validation, or want to store cents instead of dollars. You **can't** add code without changing every caller, because they access the field directly. If it had been:

```java
public double getBalance() { return balance; }
```

you could change the inside any time, and all hundred callers stay the same. The plain getter is **insurance**: cheap now, and expensive to add later.

The cost of that insurance is a few lines. In a small private project where you control all the code, you can reasonably skip it. In libraries, shared code, or frameworks that use reflection and proxies (JPA, Jackson, Spring), it's the standard because those tools expect it.

|Situation|Reasonable choice|
|---|---|
|Library or code other teams depend on|Methods, so you can change the inside later|
|Framework entities (JPA, Jackson)|Getters (and often setters) because the tools use them|
|Small private helper class, one owner|Plain fields can be fine|
|Pure data carrier|A `record`, which removes the boilerplate entirely|

---

## 11. Better than getters and setters: behavior methods

This ties back to what you sensed. If you keep writing `getX()` and `setX()` for everything, the object is just a bag of data and all the logic ends up elsewhere. A stronger design asks the object to do the work:

```java
// Weak: caller does the logic
if (account.getBalance() >= 50) {
    account.setBalance(account.getBalance() - 50);
}

// Strong: the object does its own logic
account.withdraw(50);
```

The second version has no raw getter or setter in sight, and the rule "can't overdraw" lives inside `Account`. This idea is often called **"Tell, Don't Ask."**

---

## 12. Modern shortcuts so it's not extra work

- **Lombok:** `@Getter` and `@Setter` generate the plain ones for you. You write code by hand only where the logic is special.
- **Records:** `record Point(int x, int y) {}` gives you private final fields and read-only accessors in one line.
- **IDE generators:** IntelliJ and Eclipse generate them in seconds.

So the "extra work" you noticed is mostly handled by tools, and your effort goes to the methods that actually contain logic.

---

## Related concept: JavaBeans convention (short summary)

JavaBeans is a naming convention: a no-argument constructor, private fields, and `getX()` / `setX()` (or `isX()` for booleans). Frameworks like Spring, Jackson, and Hibernate rely on it to read and write your objects through reflection. That's a big practical reason plain getters and setters are everywhere: the tools you use expect them.

---

## Quick recap

- A plain `return field` / `this.field = value` getter and setter does nearly the same as a public field. You're right about that.
- Their real value is what can go **inside**: validation, cleaning, calculation, read-only access, safe copies, notifications, lazy loading.
- Plain ones are insurance: you can add logic later without breaking callers, and frameworks expect them.
- Not every field needs both. Use getter only, or neither, when that fits.
- The best encapsulated classes expose **behavior** (`withdraw`, `addOrder`) more than raw getters and setters.





[[Java]]