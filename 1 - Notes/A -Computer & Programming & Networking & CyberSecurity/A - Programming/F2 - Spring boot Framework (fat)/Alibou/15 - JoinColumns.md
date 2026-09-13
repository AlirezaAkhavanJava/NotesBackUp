
## 1️⃣ `@JoinColumn` (single column)

### What it is

Defines **ONE foreign key column** used to join two tables.

### Where used

- `@ManyToOne`
    
- `@OneToOne`
    
- Owning side of relationships
    

### Example

```java
@ManyToOne
@JoinColumn(name = "user_id")
User user;
```

### Resulting table

```
order
-----
id
user_id  ← FK → user.id
```

### Key points

- Default column name: `<field>_id`
    
- Holds **foreign key**
    
- **Single column only**
    

---

## 2️⃣ `@JoinColumns` (multiple columns – composite key)

### What it is

Container for **multiple `@JoinColumn`s**  
Used when the **target entity has a composite primary key**.

### When required

- Composite PK (`@EmbeddedId` or `@IdClass`)
    
- Composite FK
    

---

### Example with `@EmbeddedId`

#### Parent key

```java
@Embeddable
class OrderId {
    Long orderId;
    Long storeId;
}
```

```java
@Entity
class Order {
    @EmbeddedId
    OrderId id;
}
```

#### Child entity

```java
@Entity
class OrderItem {

    @ManyToOne
    @JoinColumns({
        @JoinColumn(name = "order_id", referencedColumnName = "orderId"),
        @JoinColumn(name = "store_id", referencedColumnName = "storeId")
    })
    Order order;
}
```

### Generated table

```
order_item
----------
order_id
store_id
```

---

## 3️⃣ `@JoinColumn` vs `@JoinColumns`

|Feature|`@JoinColumn`|`@JoinColumns`|
|---|---|---|
|Columns|1|Multiple|
|FK type|Simple|Composite|
|Common use|90% cases|Rare / advanced|
|Required for composite PK|❌|✅|

---

## 4️⃣ Common mistakes

❌ Using `@JoinColumn` with composite PK  
❌ Forgetting `referencedColumnName`  
❌ Using `@JoinColumns` without composite key

---

## Rule of thumb (remember this)

> **One FK column → `@JoinColumn`**  
> **Multiple FK columns → `@JoinColumns`**



###### Tags : [[0 - Spring Framework]]