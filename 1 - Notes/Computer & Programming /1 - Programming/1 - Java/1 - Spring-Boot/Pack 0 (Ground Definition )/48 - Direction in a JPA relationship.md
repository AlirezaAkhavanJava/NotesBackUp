Direction in a JPA relationship is a question about your Java classes, not about your database. In the database, a one-to-many relationship is just a foreign key column in one table, and that column has no direction. In Java you decide whether one entity holds a reference to the other (unidirectional) or both entities hold a reference to each other (bidirectional).

In production, the rule is simple: **start unidirectional, and add the second side only when you can name the concrete reason.** Every extra side adds code you must keep correct, and Hibernate will not warn you when you get it wrong. This lesson shows what each side costs, which direction to pick for each relationship type, and how to write a bidirectional relationship safely when you really need one.

## One foreign key, one owner

Take `Order` and `OrderItem`. The table `order_item` has an `order_id` column. That column is the only thing the database stores. So JPA needs to know which Java field controls that column. That field is the **owning side**. The other field, if you add one, is the **inverse side**, and Hibernate ignores it when writing to the database. You mark the inverse side with `mappedBy`.

**Unidirectional**: only the child knows the parent.

```java
@Entity
public class OrderItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    private String product;
    private int quantity;
}
```

`Order` has no list. When you need the items, you ask the repository:

```java
public interface OrderItemRepository extends JpaRepository<OrderItem, Long> {
    List<OrderItem> findByOrderId(Long orderId);
    Page<OrderItem> findByOrderId(Long orderId, Pageable pageable);
}
```

**Bidirectional**: now `Order` also holds the list.

```java
@Entity
@Table(name = "orders")
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderItem> items = new ArrayList<>();

    public List<OrderItem> getItems() {
        return Collections.unmodifiableList(items);
    }

    public void addItem(OrderItem item) {
        items.add(item);
        item.setOrder(this);
    }

    public void removeItem(OrderItem item) {
        items.remove(item);
        item.setOrder(null);
    }
}
```

New things here:

- `mappedBy = "order"` says "the owning side is the field called `order` in `OrderItem`". This is why `Order` never needs a `@JoinColumn`.
- `cascade = ALL` means saving, updating or deleting an `Order` does the same to its items.
- `orphanRemoval = true` means an item removed from the list is deleted from the table.
- `addItem` and `removeItem` keep both sides in sync. You need them, as the next section shows. (`order` is a reserved SQL word, so the `@Table(name = "orders")` from your `@Table` lesson matters here.)

## What the second side costs you

**1. Two sides to keep in sync.** Hibernate only reads the owning side. This code looks fine but saves `order_id = NULL`:

```java
order.getItems().add(item);   // inverse side only, item.order is still null
```

Your constructor `optional = false` and `nullable = false` turn this into an error at flush time, which is good. Without them it is a silent bug. Helper methods like `addItem` remove the problem, and an unmodifiable getter forces everyone to use them.

**2. Infinite recursion.** `order.toString()` prints items, each item prints its order, and you get a `StackOverflowError`. The same loop happens in `equals`/`hashCode` and in JSON serialization. From your entity-methods lesson: keep relationship fields out of `toString`, `equals` and `hashCode` (with Lombok, `@ToString.Exclude` and `@EqualsAndHashCode.Exclude`). From your DTO lesson: never return the entity from a controller. Map to a record DTO, so the loop cannot happen.

**3. Unbounded collections.** If `Customer` has `List<Order> orders` and one customer has 200,000 orders, then `customer.getOrders()` loads all of them into memory. A repository method with `Page<Order>` (from your return-types lesson) does the same job safely. A collection field can't be paged.

**4. Hidden queries.** Looping over `order.getItems()` for 50 orders runs 50 extra selects (the **N+1 problem**). Calling it outside a transaction throws `LazyInitializationException`. A repository query with `JOIN FETCH` is easier to see and control.

**5. Cascade is a delete button.** `CascadeType.ALL` on a relationship that is not truly "owned" can delete data you did not intend to touch.

## Choosing by relationship type

### @ManyToOne / @OneToMany

Always put `@ManyToOne` on the child, with `FetchType.LAZY`. That one field is the default relationship.

Add the parent's `@OneToMany(mappedBy = ...)` only when **all** of these are true:

- The children cannot exist without the parent, so cascade and `orphanRemoval` are correct (`OrderItem` only lives inside an `Order`).
- The collection is small and bounded. An order has a few items, never millions.
- Your code saves or changes the parent and its children together as one unit.

If any of these is false, stay unidirectional and use a repository query. `Customer → Orders` fails the second test, so `Order` gets `@ManyToOne Customer` and `Customer` gets nothing.

Avoid the third option, a **unidirectional `@OneToMany`** (list on the parent, nothing on the child). Without `@JoinColumn` Hibernate creates an extra join table. With `@JoinColumn` it usually inserts the child first and then runs a separate `UPDATE` to set the foreign key. Both are wasteful, and the child cannot see its parent.

### @OneToOne

Stay unidirectional, with the foreign key on the dependent side. Making it bidirectional has a real cost: Hibernate cannot lazy-load the inverse side, because it can't tell whether a related row exists without querying, so it loads it eagerly. When the child's primary key is the parent's, use `@MapsId`:

```java
@Entity
public class UserProfile {

    @Id
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "id")
    private User user;
}
```

`@MapsId` means this table's `id` column is also the foreign key to `user`. You skip a separate id column and a unique constraint.

### @ManyToMany

Don't use it in production. The moment the link needs a column (enrolled date, status), a plain `@ManyToMany` can't hold it. Model the link as its own entity with two `@ManyToOne` fields, each one unidirectional:

```java
@Entity
public class Enrollment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    private Student student;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    private Course course;

    private LocalDate enrolledOn;
}
```

You can start with this version and never need to migrate later.

## Quick decision table

|Situation|Choice|
|---|---|
|Child needs to reach its parent|`@ManyToOne` on the child (always)|
|Parent owns a small, bounded list and cascades to it|Bidirectional, with helper methods|
|Parent could have thousands of children|Unidirectional, repository with `Page`|
|Children are shared or queried on their own|Unidirectional|
|One-to-one|Unidirectional, `@MapsId` if the key is shared|
|Many-to-many|Join entity, two unidirectional `@ManyToOne`|
|Only a report or screen needs the parent plus children|Unidirectional + `JOIN FETCH` query or DTO projection|

## Short related concepts

- **Aggregate root**: a design idea where one entity (`Order`) is the single entry point for a small cluster of objects that live and change together (`OrderItem`s). Bidirectional with cascade fits inside an aggregate. Across aggregates (`Order` → `Customer`) you point one way, or just keep the id.
- **`JOIN FETCH` / `@EntityGraph`**: ways to load a parent and its children in one SQL query for one specific use case, instead of making the collection eager everywhere. They are what prevent N+1 when you need the children.


[[Spring Framework]]