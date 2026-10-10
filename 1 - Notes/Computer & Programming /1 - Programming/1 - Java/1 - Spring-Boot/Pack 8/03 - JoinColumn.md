

## Core intuition

`@JoinColumn` says: **"this field is backed by a foreign key column, and here is how that column is configured."**

In a database, only one table holds the foreign key. In JPA, the entity mapped to that table is called the **owning side** of the relationship. Put `@JoinColumn` on the owning side's field.

**Rule of thumb: put it on the field whose table physically contains the foreign key column.**

## The most common case: `@ManyToOne`

Many orders belong to one customer, so the `orders` table holds the `customer_id` column.

```java
@Entity
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id")   // FK column in the "orders" table
    private Customer customer;
}
```

```java
@Entity
public class Customer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToMany(mappedBy = "customer")   // NO @JoinColumn here
    private List<Order> orders = new ArrayList<>();
}
```

The `Customer` side uses `mappedBy = "customer"`, which means "I don't own this relationship. The `customer` field in `Order` does." The inverse side never gets `@JoinColumn`.

## Where it goes per relationship type

|Relationship|Where `@JoinColumn` goes|
|---|---|
|`@ManyToOne`|On the `@ManyToOne` field (always the owning side)|
|`@OneToMany` (bidirectional)|**Not** on the `@OneToMany` side. Use `mappedBy` there and put `@JoinColumn` on the `@ManyToOne` side|
|`@OneToOne`|On the side whose table holds the FK. The other side uses `mappedBy`|
|`@OneToMany` (unidirectional)|On the `@OneToMany` field, but the FK lives in the _child_ table (see gotchas)|
|`@ManyToMany`|Not used. Use `@JoinTable` instead|

`@OneToOne` example:

```java
@Entity
public class User {
    @OneToOne
    @JoinColumn(name = "profile_id")   // users.profile_id
    private Profile profile;
}

@Entity
public class Profile {
    @OneToOne(mappedBy = "profile")    // inverse side
    private User user;
}
```

## Useful attributes

```java
@JoinColumn(
    name = "customer_id",              // FK column name
    referencedColumnName = "id",       // column it points to (default: the primary key)
    nullable = false,                  // NOT NULL constraint
    unique = false,                    // UNIQUE constraint (useful for one-to-one)
    foreignKey = @ForeignKey(name = "fk_order_customer")  // constraint name
)
```

If you omit `name`, Hibernate generates `<fieldName>_<referencedColumnName>`, so `customer` pointing at `id` gives `customer_id`.

## Gotchas and edge cases

**1. `mappedBy` and `@JoinColumn` don't go together.** Putting both on the same field is a mistake. `mappedBy` says "I'm the inverse side," and `@JoinColumn` says "I own the column."

**2. A `@OneToMany` with neither `mappedBy` nor `@JoinColumn` creates a join table.** Hibernate invents an extra table like `customer_orders`:

```java
@OneToMany                       // surprise: creates a join table
private List<Order> orders;
```

**3. A unidirectional `@OneToMany` with `@JoinColumn`** puts the FK in the child table, even though the annotation sits on the parent:

```java
@OneToMany
@JoinColumn(name = "customer_id")   // column lives in the "orders" table
private List<Order> orders;
```

This works, but Hibernate often runs extra `UPDATE` statements to set the FK after inserting the child. The bidirectional version (`@ManyToOne` + `mappedBy`) is usually preferred.

**4. Only the owning side writes to the database.** If you add an `Order` to `customer.getOrders()` but never call `order.setCustomer(customer)`, the FK is not saved. This trips up many beginners. Keep both sides in sync with a helper method:

```java
public void addOrder(Order order) {
    orders.add(order);
    order.setCustomer(this);
}
```

**5. Composite keys** use `@JoinColumns({ @JoinColumn(...), @JoinColumn(...) })`.

**6. Lazy loading:** `@ManyToOne` defaults to `EAGER`. Setting `fetch = FetchType.LAZY` explicitly is a good habit to avoid unnecessary queries.

## Related concepts

- **`mappedBy`** is the other half of `@JoinColumn`. One marks the owner, the other marks the inverse.
- **`@JoinTable`** is the `@ManyToMany` equivalent. It configures the separate join table that holds both FKs.
- **Owning vs. inverse side** is the core JPA idea behind all of this.




[[Spring Framework]]