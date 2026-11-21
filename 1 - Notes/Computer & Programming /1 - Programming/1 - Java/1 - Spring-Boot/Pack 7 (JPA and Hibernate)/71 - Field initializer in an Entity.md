
**What this lesson covers:** A field initializer is a value assigned right where a field is declared, like `private Instant createdAt = Instant.now();`. It's convenient, but it runs at a different time than most people expect, and JPA runs it in a way that can surprise you. This lesson explains when initializers run, how they interact with Hibernate, how they compare with `@CreationTimestamp`, and which fields should and shouldn't use them.

## What a field initializer is

When Java creates an object, it runs the steps in a fixed order:

1. The superclass constructor runs.
2. Every field initializer runs, from top to bottom.
3. The body of the constructor you called runs.

```java
@Entity
@Table(name = "customers")
public class Customer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();   // Field initializer: runs before the constructor body

    protected Customer() {}                      // JPA constructor

    public Customer(String fullName) {
        // createdAt already has a value here, set by the initializer
    }
}
```

- `private Instant createdAt = Instant.now();` assigns the current time as soon as the object is created.
- `updatable = false` tells Hibernate never to include this column in an `UPDATE`, so the first value is kept.
- Because the initializer runs for every constructor, you don't have to repeat the assignment in each one. That's the main benefit.

## The hidden part: Hibernate runs initializers too

Hibernate creates entity objects using the no-argument constructor, which is the `protected Customer() {}` we wrote for JPA. That means **initializers run every time Hibernate creates an object, including when it loads a row from the database.**

The sequence when you load customer 42 is:

1. Hibernate calls `new Customer()`, and `createdAt` is set to `Instant.now()`.
2. Hibernate then sets every column from the row, so `createdAt` is overwritten with the stored value.

The initial value is thrown away, but the work still happens. If the initializer does something expensive or has a side effect, it runs on every load. For example:

```java
private String token = UUID.randomUUID().toString();   // Runs on every load, then gets overwritten
private Logger log = LoggerFactory.getLogger(...);      // Harmless, but still runs each time
```

The rule that follows: **initializers should be cheap, pure, and have no side effects.** `Instant.now()`, an empty list, and a default enum value are fine. Calling a service, writing a log line, or generating a secret is not. Generated secrets belong in the constructor or in `@PrePersist`, where they run only for new objects.

## Initializer, constructor, `@CreationTimestamp`, or `@PrePersist`?

All four can fill `createdAt`. They differ in *when* the value is chosen:

| Approach | Value is chosen | Runs on load? | Best for |
|---|---|---|---|
| Field initializer `= Instant.now()` | When the Java object is created | Yes | Simple defaults, fine for short-lived objects |
| Constructor assignment | When your code calls the constructor | No | Values the caller should influence, or that depend on parameters |
| `@CreationTimestamp` | When Hibernate inserts the row | No | Timestamps that must reflect the database write |
| `@PrePersist` callback | Just before the insert | No | Logic that needs several fields or conditions |

Here's the important timing difference. Suppose you build an object at 10:00 and save it at 10:05:

```java
Customer c = new Customer("Ana");   // createdAt initializer runs now (10:00)
Thread.sleep(5 * 60_000);
repository.save(c);                 // Saved at 10:05, but createdAt still says 10:00
```

With the initializer, `createdAt` records when the object was built, which may be earlier than when it was stored. With `@CreationTimestamp`, Hibernate sets the value during the insert, so it records 10:05. For most business data, the insert time is the truer answer, which is why `@CreationTimestamp` is usually the better choice for `createdAt`.

## Using `@CreationTimestamp` with an initializer

You'll sometimes see both together:

```java
@CreationTimestamp
@Column(name = "created_at", nullable = false, updatable = false)
private Instant createdAt = Instant.now();
```

This is redundant. Hibernate overwrites the value during insert, so the initializer has no lasting effect, and it still runs on every load. Pick one. For a creation timestamp, use `@CreationTimestamp` alone:

```java
@CreationTimestamp
@Column(name = "created_at", nullable = false, updatable = false)
private Instant createdAt;
```

## Initializers that are good to use

Two kinds of initializer are almost always right.

**Collections.** Initialize them so you never have to check for `null`:

```java
@OneToMany(mappedBy = "customer")
private List<Order> orders = new ArrayList<>();
```

Hibernate replaces the list with its own collection type when it loads the data, so this is safe. Without the initializer, a new customer's `getOrders()` would return `null`, and calling `.add()` on it would fail.

**Simple business defaults** that don't depend on the outside world:

```java
@Column(nullable = false)
private boolean enabled = true;

@Enumerated(EnumType.STRING)
@Column(nullable = false, length = 20)
private OrderStatus status = OrderStatus.PENDING;
```

These are constant values, so running them on every load costs nothing and has no effect.

## The Lombok trap

When you use Lombok's `@Builder`, initializers are ignored by the builder unless you mark them with `@Builder.Default`:

```java
@Builder
public class Product {

    @Builder.Default
    private boolean active = true;   // Without @Builder.Default, the builder sets this to false
}
```

Lombok builds the object through its own all-args constructor, and it doesn't keep the initializer unless you tell it to. This is a common source of bugs, and it's the one place where an initializer behaves differently from what you wrote.

## Testing time-based initializers

`Instant.now()` in an initializer reads the real system clock, and that makes tests hard to write. For values that tests check, pass the time in through the constructor, where you can control it:

```java
public Customer(String fullName, Instant createdAt) {
    this.fullName = fullName;
    this.createdAt = createdAt;
}
```

The service then passes `clock.instant()`, which you injected as described in the previous lesson. A test can supply a fixed instant and check the result exactly.

## Common mistakes

1. **Putting side effects in initializers.** They run on every load, not only when a new object is created.
2. **Combining `@CreationTimestamp` and `= Instant.now()`.** The initializer is wasted work.
3. **Forgetting `@Builder.Default`.** The initializer is silently ignored by Lombok's builder.
4. **Assuming `createdAt` equals the save time.** An initializer records when the object was built.
5. **Leaving collections uninitialized.** Use `new ArrayList<>()` to avoid `NullPointerException`.
6. **Using `Instant.now()` in code that tests check.** Inject a `Clock` or pass the time explicitly.

## Try it yourself

1. Add a `System.out.println("constructed")` inside the field initializer of an entity with a `protected` no-argument constructor. Load the same row twice with a fresh session each time, and count how often the message prints. Explain why the count is more than one.
2. Create two entities: one with `private Instant createdAt = Instant.now();` and one with `@CreationTimestamp`. Build both, wait five seconds, then save them. Compare the stored times and explain the difference.
3. Remove `@Builder.Default` from a field with an initializer and build an object without setting that field. Describe what value you get, and why.



[[Spring Framework]]