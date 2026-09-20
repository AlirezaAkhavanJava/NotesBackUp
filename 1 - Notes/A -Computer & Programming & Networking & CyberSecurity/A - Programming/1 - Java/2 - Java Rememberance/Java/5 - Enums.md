The key is to understand **why `enum` exists**, not just memorize its syntax.

## 1. What is an `enum` class in Java?

An `enum` is a special kind of class used to represent a **fixed, finite set of named constants**.

For example, suppose your application has order states:

```java
public enum OrderStatus {
    PENDING,
    PAID,
    SHIPPED,
    DELIVERED,
    CANCELLED
}
```

Now you can write:

```java
OrderStatus status = OrderStatus.PAID;
```

Instead of:

```java
String status = "PAID";
```

The important difference is that `OrderStatus` defines a **closed set of valid values**.

You cannot accidentally do:

```java
status = "PAIDDDDD"; // possible with String
```

With the enum:

```java
status = OrderStatus.PAID;
```

the compiler knows exactly what values are legal.

---

# 2. Why did Java "come up with" enums?

Before Java had enums, developers commonly represented states using things like:

```java
int PENDING = 0;
int PAID = 1;
int SHIPPED = 2;
```

This is dangerous.

You could do:

```java
int status = 999999;
```

and Java has no idea that `999999` is an invalid order status.

Another approach was:

```java
String status = "PAID";
```

Better readability, but still no compile-time protection.

You could accidentally write:

```java
String status = "paidd";
```

So Java introduced `enum` in **Java 5 (2004)** to provide a type-safe way of representing a fixed set of constants.

Conceptually:

```text
int
 ↓
any integer

String
 ↓
any string

enum OrderStatus
 ↓
only valid OrderStatus values
```

That's the real reason enums exist:

> **To model a domain concept whose possible values are known and constrained.**

---

# 3. The important part: an enum is actually a class

This is where Java's design gets interesting.

When you write:

```java
public enum OrderStatus {
    PENDING,
    PAID,
    SHIPPED
}
```

you're not creating primitive constants.

You're defining a special class.

You can therefore do things like:

```java
OrderStatus status = OrderStatus.PAID;

System.out.println(status.name());
System.out.println(status.ordinal());
```

And:

```java
OrderStatus.valueOf("PAID");
```

You can also:

```java
for (OrderStatus status : OrderStatus.values()) {
    System.out.println(status);
}
```

Output:

```text
PENDING
PAID
SHIPPED
```

So mentally, think:

```text
enum
 │
 └── special Java class
      │
      ├── fixed instances
      ├── type safety
      ├── methods
      ├── fields
      └── behavior
```

---

# 4. Enums can have behavior

This is where you start moving from **beginner Java** toward good object-oriented Java.

For example:

```java
public enum OrderStatus {

    PENDING,
    PAID,
    SHIPPED,
    DELIVERED;

    public boolean isFinished() {
        return this == DELIVERED;
    }
}
```

Then:

```java
OrderStatus status = OrderStatus.DELIVERED;

if (status.isFinished()) {
    System.out.println("Order completed.");
}
```

That's much better than scattering logic throughout your application:

```java
if (status == OrderStatus.DELIVERED) {
    ...
}
```

everywhere.

The enum itself knows something about its domain.

---

# 5. Enums can have fields and constructors

For example, an HTTP status category:

```java
public enum HttpStatus {

    OK(200),
    NOT_FOUND(404),
    INTERNAL_SERVER_ERROR(500);

    private final int code;

    HttpStatus(int code) {
        this.code = code;
    }

    public int code() {
        return code;
    }
}
```

Usage:

```java
HttpStatus status = HttpStatus.NOT_FOUND;

System.out.println(status.code());
```

Output:

```text
404
```

Notice something important:

```java
OK(200)
NOT_FOUND(404)
INTERNAL_SERVER_ERROR(500)
```

These are enum **instances**.

The constructor is called when the enum instances are created.

---

# 6. When should a senior developer use an enum?

Here's the practical rule I would give you:

> **Use an enum when the domain has a small, well-defined set of values that are conceptually one type.**

Good examples:

```java
OrderStatus
UserRole
PaymentStatus
HttpMethod
LogLevel
Direction
DayOfWeek
ConnectionState
```

For example:

```java
public enum UserRole {
    USER,
    ADMIN,
    MODERATOR
}
```

That's an excellent enum candidate.

---

## Don't use an enum when the values are open-ended

For example:

```java
String username;
```

Obviously not:

```java
enum Username {
    ALIREZA,
    JOHN,
    BOB,
    ...
}
```

Because usernames aren't a finite predefined domain.

Likewise:

```java
String country;
```

isn't necessarily something you should blindly turn into an enum if your application needs to support arbitrary/new countries or external data.

The question isn't:

> "Can I make this an enum?"

The question is:

> **"Is this concept a closed set in my domain?"**

That's a much more senior-level question.

---

# 7. Enum vs `String` — an important architectural decision

Imagine a Spring Boot application.

Bad:

```java
public class User {

    private String role;
}
```

Now the application can receive:

```text
"ADMIN"
"admin"
"Admin"
"admni"
"SUPER_ADMIN"
"whatever"
```

You have to validate strings everywhere.

Better:

```java
public class User {

    private UserRole role;
}
```

with:

```java
public enum UserRole {
    USER,
    ADMIN
}
```

Now your Java type system participates in protecting your domain.

That's one of the biggest benefits.

---

# 8. But there's an important database issue

Since you're working with PostgreSQL/Spring Boot, this matters a lot.

Suppose:

```java
public enum OrderStatus {
    PENDING,
    PAID,
    SHIPPED,
    CANCELLED
}
```

and:

```java
@Entity
public class Order {

    @Enumerated(EnumType.STRING)
    private OrderStatus status;
}
```

Use:

```java
EnumType.STRING
```

rather than:

```java
EnumType.ORDINAL
```

### Why?

`ORDINAL` stores:

```text
PENDING   → 0
PAID      → 1
SHIPPED   → 2
CANCELLED → 3
```

Now imagine you change the enum:

```java
PENDING,
REFUNDED,
PAID,
SHIPPED,
CANCELLED
```

Suddenly:

```text
PAID → 2
SHIPPED → 3
CANCELLED → 4
```

You've changed the meaning of existing database values.

That's a nasty production bug.

With:

```java
@Enumerated(EnumType.STRING)
```

the database stores:

```text
PENDING
PAID
SHIPPED
CANCELLED
```

Much safer and much more maintainable.

---

# 9. The senior-level approach

Don't think:

> "Enums are a convenient replacement for strings."

Think:

> **"Enums are a domain modeling tool."**

For example, imagine you're building an e-commerce system.

Instead of:

```java
String status;
String paymentMethod;
String role;
String shippingType;
```

you might model:

```java
OrderStatus status;
PaymentMethod paymentMethod;
UserRole role;
ShippingType shippingType;
```

Now your domain has explicit types.

```text
Order
 ├── OrderStatus
 ├── PaymentMethod
 ├── ShippingType
 └── ...
```

This reduces invalid states and makes APIs easier to understand.

---

# 10. Avoid the "enum everywhere" trap

A senior developer also knows when **not** to use one.

Don't create enums simply because something has a few values today.

For example:

```java
enum CustomerName {
    ALIREZA,
    JOHN
}
```

Obviously ridiculous.

But there are subtler cases.

Suppose your application gets payment providers dynamically:

```text
Stripe
PayPal
Adyen
FutureProvider
```

If providers are dynamically configured, an enum may be the wrong abstraction.

You might instead use:

```java
String provider;
```

or, better, a proper domain type/interface depending on the architecture.

So the principle is:

```text
Closed + known + meaningful domain values
                    ↓
                  enum

Open + dynamic + externally configured
                    ↓
          String / class / interface
```

---

# 11. One more powerful feature: polymorphic enums

You can even give each enum constant its own behavior.

```java
public enum PaymentMethod {

    CREDIT_CARD {
        @Override
        public void pay() {
            System.out.println("Processing credit card");
        }
    },

    PAYPAL {
        @Override
        public void pay() {
            System.out.println("Processing PayPal");
        }
    };

    public abstract void pay();
}
```

Then:

```java
PaymentMethod method = PaymentMethod.PAYPAL;

method.pay();
```

This is legitimate Java, but **don't use it just because you can**.

In a real application, if payment behavior becomes complicated, an interface + separate implementations may be much cleaner:

```text
PaymentMethod
      │
      ├── CreditCardPayment
      ├── PayPalPayment
      └── StripePayment
```

That's where architectural judgment matters.

---

# The rule I want you to remember

As you progress toward senior Java development, don't focus on:

> "What Java feature can solve this?"

Focus on:

> **"What model best represents the domain and protects the system from invalid states?"**

For enums specifically:

```text
                    Is the set finite?
                           │
                     ┌─────┴─────┐
                    YES           NO
                     │             │
             Is it conceptually    │
                 one type?         │
                     │             │
                  YES              │
                     │             │
                   ENUM       class / String /
                              interface / etc.
```

And one particularly strong Java habit:

**Prefer domain-specific types over primitive/stringly-typed data when the domain warrants it.**

That's one of the differences between merely _writing Java_ and **designing a Java system**.

[[Java]]