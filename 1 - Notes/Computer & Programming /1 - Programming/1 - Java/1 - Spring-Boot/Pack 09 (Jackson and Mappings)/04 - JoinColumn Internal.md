

## Mental model

Think of two paper forms in an office:

- **Customer form**: has `id`, `name`
- **Order form**: has `id`, `date`, and a sticky note saying **"Customer #7"**

The sticky note is the **foreign key column**. It sits on the order form, not on the customer form.

`@JoinColumn` is how you tell Hibernate: **"this Java field is stored as that sticky note column."**

## Which class gets it? Look at the database tables first

Forget Java for a moment and picture the tables:

```
customer                orders
+----+-------+          +----+------------+-------------+
| id | name  |          | id | date       | customer_id |  <-- FK column
+----+-------+          +----+------------+-------------+
| 7  | Ali   |          | 1  | 2026-10-01 | 7           |
+----+-------+          | 2  | 2026-10-02 | 7           |
                        +----+------------+-------------+
```

Ask one question: **which table has the `_id` column that points to another table?**

Answer: `orders`. So the class mapped to `orders` (`Order`) gets `@JoinColumn`, on the field that represents the other side (`customer`).

```java
@Entity
public class Order {
    @Id @GeneratedValue
    private Long id;

    @ManyToOne
    @JoinColumn(name = "customer_id")   // "store this field as the customer_id column"
    private Customer customer;          // a Java object, but the DB stores only a number
}
```

Here is the important idea: in Java the field holds a whole `Customer` object, but in the database there is only a number (`7`). `@JoinColumn` is the bridge between those two worlds.

## How it works internally

1. **Application startup:** Hibernate scans your entity classes and reads the annotations. For the `customer` field it records: "property `customer` of `Order` maps to column `customer_id` in table `orders`, and that column points to `customer.id`." This is stored in an internal metadata model.
    
2. **Table creation (if `ddl-auto=create/update`):** Hibernate uses that metadata to generate:
    
    ```sql
    create table orders (
        id bigint primary key,
        date date,
        customer_id bigint,
        foreign key (customer_id) references customer(id)
    );
    ```
    
3. **Saving:** When you call `orderRepository.save(order)`, Hibernate looks at `order.getCustomer()`, calls `getId()` on it, and puts only that number in the column:
    
    ```sql
    insert into orders (date, customer_id) values (?, 7);
    ```
    
    It does not copy the customer's data into the order table.
    
4. **Loading:** When you load an order, Hibernate runs `select ... customer_id from orders where id = 1`. It reads the number `7` from the column, then:
    
    - **LAZY:** builds an empty proxy `Customer` that only knows its id (7). It runs `select * from customer where id = 7` later, only when you call something like `getName()`.
    - **EAGER:** immediately loads the customer too, with a join or an extra select.

So `@JoinColumn` is a **translation rule**: object reference → FK number when saving, FK number → object when loading.

## Why the other side doesn't get it

`Customer` has `List<Order> orders`, but the `customer` table has no column for it, so there is nothing to configure. That list is just a query Hibernate runs on demand:

```sql
select * from orders where customer_id = 7;
```

`mappedBy = "customer"` tells Hibernate: "to run that query, use the `customer` field in `Order`, which already knows the column." This is why `mappedBy` sits on the side **without** the column, and `@JoinColumn` sits on the side **with** it.

## Quick decision recipe

1. Draw the two tables.
2. Find the table with the `xxx_id` column.
3. Put `@JoinColumn(name = "xxx_id")` on the field in that table's entity.
4. On the other entity, use `mappedBy = "<field name in the first entity>"`.

Whenever the relationship is "many X belong to one Y", the FK is in X's table, so `@JoinColumn` goes in X.

---
# Primary and secondary

JPA doesn't use "primary" and "secondary" for this, but the idea maps cleanly if you think of it as **parent and child**.

## Mental model

|Your word|Database term|JPA term|Example|Has `@JoinColumn`?|
|---|---|---|---|---|
|**Primary**|Parent table (referenced via its primary key)|Inverse side|`Customer`|No, uses `mappedBy`|
|**Secondary**|Child table (holds the foreign key)|Owning side|`Order`|**Yes**|

The primary one exists on its own. A customer can exist without any orders. The secondary one depends on the primary: an order points to a customer, so it carries the sticky note (`customer_id`).

**`@JoinColumn` always goes on the secondary (child) entity**, the one that holds the foreign key.

## In code

```java
// PRIMARY (parent): no FK column in its table
@Entity
public class Customer {
    @Id @GeneratedValue
    private Long id;                       // primary key

    @OneToMany(mappedBy = "customer")      // "the child owns the link"
    private List<Order> orders = new ArrayList<>();
}

// SECONDARY (child): has the FK column
@Entity
public class Order {
    @Id @GeneratedValue
    private Long id;

    @ManyToOne
    @JoinColumn(name = "customer_id")      // FK column lives here
    private Customer customer;
}
```

## One-line test

Ask: **"Which one cannot exist meaningfully without the other?"**

- An order without a customer makes no sense, so `Order` is the secondary and gets `@JoinColumn`.
- A customer without orders is fine, so `Customer` is the primary and gets `mappedBy`.

## A different feature with a similar name

JPA also has `@SecondaryTable`, which splits **one entity across two tables** (for example, `User` with columns in both `users` and `user_details`). That is unrelated to `@JoinColumn` on relationships, so don't mix them up.





[[Spring Framework]]