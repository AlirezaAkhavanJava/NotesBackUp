

## Definition

**Cascade** tells JPA that when an operation is performed on one entity, the same operation should also be performed on the entities it refers to. "Operation" here means an action on the persistence context, such as saving, deleting, or reloading. You declare it on a relationship annotation with the `cascade` attribute:

```java
@OneToMany(cascade = CascadeType.PERSIST)
```

This line says: "When I persist the owning entity, also persist the entities in this collection."

## The Problem Cascade Solves

Consider an order with several lines. Each `OrderLine` is its own entity with its own table and id.

```java
@Entity
public class Order {

    @Id
    @GeneratedValue
    private Long id;

    private String customerName;

    @OneToMany(mappedBy = "order")
    private List<OrderLine> lines = new ArrayList<>();

    public void addLine(OrderLine line) {
        lines.add(line);
        line.setOrder(this);
    }

    // getters and setters
}
```

```java
@Entity
public class OrderLine {

    @Id
    @GeneratedValue
    private Long id;

    private String product;
    private int quantity;

    @ManyToOne(optional = false)
    @JoinColumn(name = "order_id")
    private Order order;

    // getters and setters
}
```

Now try to save an order with a new line, without cascade:

```java
Order order = new Order();
order.setCustomerName("Alireza");

OrderLine line = new OrderLine();
line.setProduct("Keyboard");
line.setQuantity(1);
order.addLine(line);

orderRepository.save(order);
```

Hibernate fails with an error like `object references an unsaved transient instance`. The `Order` is saved, but the `OrderLine` is a new object that Hibernate has never seen. It refuses to write a row that points to an unsaved object, because it has no id to put in `order_id`.

You can fix this by saving the line yourself:

```java
orderLineRepository.save(line);   // must come first, or the order must be saved first
orderRepository.save(order);
```

That works, but now every caller has to remember to save every child. With deep object graphs, it becomes easy to miss one. Cascade moves that responsibility into the mapping, so the rule lives in one place.

## Adding Cascade

```java
@OneToMany(mappedBy = "order", cascade = CascadeType.PERSIST)
private List<OrderLine> lines = new ArrayList<>();
```

Now the original code works. Saving the `Order` also saves the new `OrderLine`s in its list. Hibernate runs:

```sql
INSERT INTO orders (id, customer_name) VALUES (1, 'Alireza');
INSERT INTO order_line (id, product, quantity, order_id) VALUES (1, 'Keyboard', 1, 1);
```

Notice that Hibernate inserted the `orders` row first, then the child row, and filled `order_id` with the new id. It sorted the order itself, which you did not have to think about.

## The Cascade Types

Each `CascadeType` corresponds to one operation on the persistence context. Here is what each does, with an example.

### PERSIST

Applies when a new entity is saved for the first time, which is `em.persist(...)` or `repository.save(...)` on an entity that has no id yet. This is the one you need for the order example above.

### REMOVE

Applies when an entity is deleted. Deleting the parent also deletes its children.

```java
@OneToMany(mappedBy = "order", cascade = CascadeType.REMOVE)
private List<OrderLine> lines = new ArrayList<>();
```

```java
orderRepository.delete(order);
```

Hibernate runs a `DELETE` for each `order_line` row, then deletes the `orders` row. Without `REMOVE`, the delete would fail with a foreign key violation because `order_line` still points to the order.

### MERGE

Applies when a detached entity is copied back into the persistence context with `em.merge(...)`. Spring Data's `save()` calls `merge` when the entity already has an id. Use `MERGE` when you update a parent and expect its changed children to be saved too.

```java
@OneToMany(mappedBy = "order", cascade = CascadeType.MERGE)
private List<OrderLine> lines = new ArrayList<>();
```

Without `MERGE`, a change to a line inside a detached order is silently ignored when you save the order.

### REFRESH and DETACH

`REFRESH` reloads the children from the database when the parent is reloaded. `DETACH` removes the children from the persistence context when the parent is detached. Both are used less often, but they follow the same pattern.

### ALL

`ALL` means all of the above:

```java
@OneToMany(mappedBy = "order", cascade = CascadeType.ALL)
private List<OrderLine> lines = new ArrayList<>();
```

It is common for true parent-child relationships, where the children never exist without the parent. Read the next section before using it, because it has a dangerous side.

## Cascade Does Not Remove Children from the List

Cascade decides what happens when the parent itself is saved or deleted. It does not handle this case:

```java
order.getLines().remove(someLine);
orderRepository.save(order);
```

The `OrderLine` is still in the database with its `order_id` set, because removing it from a Java list does not delete the row. That is the job of `orphanRemoval`:

```java
@OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
private List<OrderLine> lines = new ArrayList<>();
```

With `orphanRemoval = true`, removing a line from the list deletes its row when the order is saved. A child that has lost its parent is an "orphan," and Hibernate removes it. This is a separate feature from cascade, but it is almost always used together with it. I'll go into it fully when you're ready.

## Where Cascade Goes Wrong

Cascade is powerful, and it is also the cause of some of the most damaging bugs in JPA applications. The main rule is to cascade only from parent to child, when the child cannot exist without the parent.

Consider this mapping:

```java
@Entity
public class OrderLine {

    @Id
    @GeneratedValue
    private Long id;

    @ManyToOne(cascade = CascadeType.ALL)   // dangerous
    @JoinColumn(name = "product_id")
    private Product product;

    // ...
}
```

A `Product` is shared. Many order lines can refer to the same product. With `CascadeType.REMOVE` on this side, deleting one order line deletes the product, which then breaks every other order line that referenced it. The database may refuse the delete, or worse, it may succeed and leave broken data.

The rule of thumb:

- Cascade from a parent to its children when the children are owned by the parent. Examples are `Order` to `OrderLine`, and `Person` to a profile that cannot exist without it.
- Do not cascade `REMOVE` toward shared entities. Products, categories, users, and countries are usually shared, so they should be saved and deleted on their own.
- Do not use `CascadeType.ALL` on `@ManyToMany` relationships without thinking, because deleting one side can remove rows that other entities still need.

## How This Connects to Element Collections

Remember what you saw earlier with `@ElementCollection`: deleting a `Person` deletes its `person_address` rows. That behavior is a built-in kind of cascade. Element collections have no entity identity and no repository, so JPA always treats them as owned by their parent. `@OneToMany` and `@OneToOne` need you to say cascade explicitly, because their children are full entities that could also be used on their own.






[[Spring Framework]]