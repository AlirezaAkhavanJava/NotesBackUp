

 **for a typical relationship, put `@JoinColumn` on the owning side**, which is the entity whose table actually contains the foreign key.

Example:

```java
class Order {

    @ManyToOne
    @JoinColumn(name = "customer_id")
    Customer customer;
}
```

Here `orders.customer_id` is the FK, so `Order` is the **source of truth / owning side**.

Then:

```java
class Customer {

    @OneToMany(mappedBy = "customer")
    List<Order> orders;
}
```

So the rule is:

**FK lives here → `@JoinColumn` lives here → this is the owning side.**

And the other side uses:

**`mappedBy` → points to the owning side's field.**


---

- `mappedBy` points to the **relationship field itself in the other entity**.
    
- `mappedBy` does **not** point directly to the database foreign-key column.
    
- The field referenced by `mappedBy` is on the **owning side** of the relationship.
    
- The **owning side** is the side that actually manages the relationship mapping in JPA.
    
- In a typical relationship, the owning side is the entity whose table contains the **foreign key**.
    
- `@JoinColumn` is normally placed on the **owning side**.
    
- `@JoinColumn` specifies the **database column used to connect the two tables**.
    
- The column specified by `@JoinColumn` is usually the **foreign key column**.
    
- `mappedBy` uses the **Java field name**, while `@JoinColumn(name = "...")` uses the **database column name**.
    
- The inverse side uses `mappedBy` because the relationship is already mapped by the owning side.
    
- Do not put `mappedBy = "customer_id"` when the Java field is called `customer`; `mappedBy` must reference the Java field.
    
- Think of the relationship as:
    

```text
Owning entity
    │
    ├── relationship field
    │       ↓
    ├── @JoinColumn
    │       ↓
    └── Foreign Key
            ↓
       Other table
```

And the inverse side:

```text
Other entity
    │
    └── relationship field
            ↓
       mappedBy = "owningField"
```

### Example

```java
@Entity
class Order {

    @ManyToOne
    @JoinColumn(name = "customer_id")
    private Customer customer;
}
```

```java
@Entity
class Customer {

    @OneToMany(mappedBy = "customer")
    private List<Order> orders;
}
```

Here:

```text
Order.customer
      ↓
@JoinColumn(name = "customer_id")
      ↓
orders.customer_id
      ↓
Customer.id
```

And:

```java
mappedBy = "customer"
```

points directly to:

```java
Order.customer
```

### Mental Model

**`@JoinColumn` → "Which database column connects these entities?"**

**`mappedBy` → "Which field in the other entity already owns/maps this relationship?"**

**Owning side → "The side responsible for managing the relationship/FK mapping."**


[[9 - Spring Container]]