


An entity looks like an ordinary Java class, but it is not one. Hibernate creates it, fills it, watches it for changes, and sometimes replaces it with a hidden stand-in object called a **proxy**. Because of that, the usual habits (generate everything with `@Data`, make every field settable, print everything in `toString`) can cause real bugs: infinite loops, surprise database queries, broken `HashSet`s, and leaked passwords.

In this lesson you will go through each kind of method an entity can have: constructors, getters, setters, `equals` and `hashCode`, `toString`, relationship helpers, lifecycle callbacks, and business methods. For each one, you will learn what it means, what Hibernate expects, and how to design it safely.

---

## 1. What Hibernate needs from your class

Before designing anything, know the rules the JPA specification sets:

|Rule|Reason|
|---|---|
|The class needs a **no-argument constructor** (public or protected)|Hibernate builds objects with `new Product()` and then fills the fields|
|The class must **not be `final`**|Hibernate creates a subclass (the proxy) for lazy loading|
|Persistent fields must **not be `final`**|Hibernate sets them after construction|
|Persistent methods should not be `final`|A proxy must be able to override them|
|Have an `@Id`|Identity of the row|

One more fact makes everything easier to understand: **where you put `@Id` decides how Hibernate reads your data.** If `@Id` is on a _field_ (the normal way), Hibernate reads and writes the fields directly. It does **not** call your getters and setters. So getters and setters are not for Hibernate. They are for _your_ code, and you decide which ones to offer.

---

## 2. Constructors

An entity usually needs two constructors, with two different audiences.

```java
@Entity
@NoArgsConstructor(access = AccessLevel.PROTECTED)   // for Hibernate
public class Product {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private BigDecimal price;

    public Product(String name, BigDecimal price) {  // for your code
        this.name = Objects.requireNonNull(name, "name is required");
        this.price = Objects.requireNonNull(price, "price is required");
    }
}
```

|Constructor|Who uses it|Design|
|---|---|---|
|**No-args**|Hibernate (and proxies)|`protected`, so your own code can't create a half-empty object by accident|
|**Business constructor**|Your services|Takes only the fields a valid object _must_ have|

Line by line:

- `@NoArgsConstructor(access = AccessLevel.PROTECTED)` makes Lombok write `protected Product() {}`. Hibernate can still reach it, but other packages can't call `new Product()`.
- The business constructor does not take `id`. The database creates it.
- `Objects.requireNonNull(...)` makes the object **valid from the first moment**. A `Product` without a name never exists.

**What to avoid:**

- `@AllArgsConstructor`: it includes `id` and `version`, which you should never set yourself.
- A public no-args constructor plus setters for everything: it lets anyone build an invalid object.

**About `@Builder`:** it is tempting, but it needs an all-args constructor underneath and makes it easy to skip required fields. For entities, a plain constructor with the required fields is clearer. Builders are great for DTOs and tests.

---

## 3. Getters

A getter lets other code **read** a field. It means "you may look at this value."

```java
@Getter
public class Product { ... }
```

Lombok's `@Getter` on the class gives you `getId()`, `getName()`, `getPrice()`, and so on. This is safe, since reading a value does not change anything.

Things to design carefully:

|Situation|What to do|
|---|---|
|`boolean` field|Lombok names it `isActive()`, and that is the correct Java convention|
|Collection field (`List<OrderItem>`)|Return an **unmodifiable view**, so outsiders can't change your list behind your back|
|Lazy relationship|Remember that calling the getter can trigger a query, or a `LazyInitializationException` outside a transaction|
|Sensitive field (`password`)|Needed by `UserDetails`, but never put it in a DTO|

```java
public List<OrderItem> getItems() {
    return Collections.unmodifiableList(items);
}
```

---

## 4. Setters

A setter lets other code **change** a field. It means "anyone may overwrite this value, with no checks." That is a much bigger promise than a getter, so give it out carefully.

Ask this for every field:

|Field|Setter?|Why|
|---|---|---|
|`id`|**No**|The database owns it|
|`version`|**No**|Hibernate owns it|
|`createdAt`|**No**|Set once at creation|
|`name`|Yes, or a method like `rename`|Normal editable data|
|`price`|A **method** with a rule|Must be positive|
|`status`|A **method** (`cancel()`, `ship()`)|Only some changes are legal|
|`password`|A method taking the **hash**|Raw passwords must never arrive here|

A setter that does nothing but assign adds no safety. Compare:

```java
// anyone can do this, even setPrice(new BigDecimal("-5"))
product.setPrice(price);

// the entity protects itself
public void changePrice(BigDecimal newPrice) {
    if (newPrice == null || newPrice.signum() <= 0) {
        throw new IllegalArgumentException("Price must be positive");
    }
    this.price = newPrice;
}
```

The second version is called a **business method**. Its name says what is happening in your domain (`changePrice`, `cancel`, `markAsPaid`), and it guards the rule in one place.

> **A practical note.** In the MapStruct lesson, the update mapper used setters so it could write into the entity. That is a fine, pragmatic choice for simple fields. If you prefer stricter entities, keep `@Setter` off the class, put it only on harmless fields, or let the service call business methods. The important part is that you _chose_ it.

---

## 5. `equals()` and `hashCode()`

These two methods answer a question: **"Are these two objects the same thing?"** Java collections like `HashSet` and `HashMap` rely on them. This is the trickiest part of entity design, so take your time.

### Why the defaults and `@Data` are risky

By default, Java compares **memory addresses**: two objects are equal only if they are literally the same object. That is wrong for entities, because two Java objects can represent the _same row_.

The opposite extreme is comparing **all fields** (what `@Data` and `@EqualsAndHashCode` do). This breaks too:

- Fields change over time, so an entity's `hashCode` changes, and it gets "lost" inside a `HashSet`.
- A lazy relationship would be loaded just to compare, causing queries.
- With two-way relationships, it can loop forever.

### The id problem

The obvious idea is "compare by `id`." But for a new entity, `id` is `null` until it is saved:

```java
Set<Product> set = new HashSet<>();
Product p = new Product("Pen", new BigDecimal("1.50"));
set.add(p);                  // hashCode computed while id == null
productRepository.save(p);   // id becomes 7, hashCode would change
set.contains(p);             // false, the object is lost!
```

### A safe pattern: id-based equals, constant hashCode

```java
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof Product other)) return false;
    return id != null && id.equals(other.getId());
}

@Override
public int hashCode() {
    return Hibernate.getClass(this).hashCode();
}
```

Line by line:

- `this == o`: the same object is always equal to itself.
- `o instanceof Product other`: works even when `o` is a Hibernate **proxy**, because a proxy is a subclass of `Product`. A plain `getClass() != o.getClass()` check would wrongly say "not equal" for a proxy.
- `other.getId()`: use the **getter**, not `other.id`. On a proxy, the field is empty, but the getter fetches the real value.
- `id != null && ...`: a new, unsaved entity equals only itself. Two different unsaved products are never "the same row."
- `hashCode` returns the same number for every product, and it never changes, so a product stays findable in a `HashSet` before and after saving. `Hibernate.getClass(this)` unwraps a proxy to the real class, so both give the same value.

A constant hash code looks odd, but it only makes large `HashSet`s of entities slower, and those are rare. Correctness wins.

### The other approach: a business key

When an entity has a natural, unique, stable value (a `username`, an `isbn`, an `email`), you can use it:

```java
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof User other)) return false;
    return username != null && username.equals(other.getUsername());
}

@Override
public int hashCode() {
    return Objects.hashCode(username);
}
```

This works well as long as the key is **never null and never changes**. If users can change their username, use the id approach instead.

|Approach|Good when|Watch out|
|---|---|---|
|Id-based, constant hash|Most entities|Unsaved entities equal only themselves|
|Business key|A natural unique key exists|Key must be set at creation and never change|
|All fields (`@Data`)|Never for entities|Mutable, lazy, can loop|

---

## 6. `toString()`

`toString()` creates text for logs and the debugger. It is called more often than you expect: in log lines, in exception messages, and when you hover in an IDE.

An entity's `toString` is dangerous in three ways:

|Danger|What happens|
|---|---|
|**Lazy fields**|Printing a collection triggers a database query, or an exception outside a transaction|
|**Two-way relationships**|`Order` prints its items, each item prints its `Order`, forever (`StackOverflowError`)|
|**Secrets**|A password hash lands in your log files|

So keep it small: print the id and a few simple fields.

```java
@Override
public String toString() {
    return "Product{id=" + id + ", name='" + name + "'}";
}
```

Or with Lombok, but only by choosing fields explicitly:

```java
@ToString(onlyExplicitlyIncluded = true)
public class Product {
    @ToString.Include private Long id;
    @ToString.Include private String name;
    private BigDecimal costPrice;     // not printed
    private Category category;        // not printed
}
```

---

## 7. Relationship helper methods

When two entities point at each other, both sides must stay in sync. A helper method does this for you.

```java
@Entity
public class Order {

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderItem> items = new ArrayList<>();

    public void addItem(OrderItem item) {
        items.add(item);
        item.setOrder(this);
    }

    public void removeItem(OrderItem item) {
        items.remove(item);
        item.setOrder(null);
    }

    public List<OrderItem> getItems() {
        return Collections.unmodifiableList(items);
    }
}
```

- The database stores the link on the **owning side** (`OrderItem.order`, the foreign key column). If you only call `items.add(item)`, the foreign key may stay empty.
- `addItem` updates **both** sides in one call, so your objects never disagree.
- The list is initialized (`new ArrayList<>()`), so it is never `null`.
- The getter returns a read-only view, so outside code must use `addItem` and `removeItem`.

---

## 8. Lifecycle callbacks

JPA can call methods on your entity at certain moments. They are plain methods marked with an annotation.

|Annotation|Runs|
|---|---|
|`@PrePersist`|Just before the first `INSERT`|
|`@PostPersist`|After the `INSERT`|
|`@PreUpdate`|Just before an `UPDATE`|
|`@PreRemove`|Just before a `DELETE`|
|`@PostLoad`|After the entity is read from the database|

```java
@PrePersist
void onCreate() {
    this.createdAt = Instant.now();
}

@PreUpdate
void onUpdate() {
    this.updatedAt = Instant.now();
}
```

This keeps timestamps correct without anyone remembering to set them. Keep callbacks small and free of database calls. For bigger needs, Spring Data's auditing (`@CreatedDate`, `@LastModifiedDate`) does the same job with less code.

---

## 9. Putting it together

```java
@Entity
@Table(name = "products")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @Column(name = "cost_price", nullable = false, precision = 10, scale = 2)
    private BigDecimal costPrice;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "category_id")
    private Category category;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @Version
    private Long version;

    public Product(String name, BigDecimal price, BigDecimal costPrice, Category category) {
        this.name = Objects.requireNonNull(name);
        this.category = Objects.requireNonNull(category);
        changePrice(price);
        this.costPrice = Objects.requireNonNull(costPrice);
    }

    public void rename(String newName) {
        if (newName == null || newName.isBlank()) {
            throw new IllegalArgumentException("Name is required");
        }
        this.name = newName.trim();
    }

    public void changePrice(BigDecimal newPrice) {
        if (newPrice == null || newPrice.signum() <= 0) {
            throw new IllegalArgumentException("Price must be positive");
        }
        this.price = newPrice;
    }

    public void moveTo(Category newCategory) {
        this.category = Objects.requireNonNull(newCategory);
    }

    @PrePersist
    void onCreate() { this.createdAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { this.updatedAt = Instant.now(); }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Product other)) return false;
        return id != null && id.equals(other.getId());
    }

    @Override
    public int hashCode() {
        return Hibernate.getClass(this).hashCode();
    }

    @Override
    public String toString() {
        return "Product{id=" + id + ", name='" + name + "'}";
    }
}
```

Reading it from top to bottom:

- Only `@Getter` is on the class. There is **no** `@Setter`, so every change goes through a method with a rule.
- The constructor reuses `changePrice`, so the price rule lives in one place.
- `id`, `version`, `createdAt`, and `updatedAt` have no way to be set from outside.
- `costPrice` has a getter for your service layer, but you already know the DTO leaves it out.
- `equals`, `hashCode`, and `toString` follow the safe patterns from above.

---

## 10. Lombok cheat sheet for entities

|Annotation|Use on entities?|Notes|
|---|---|---|
|`@Getter`|Yes|Safe|
|`@Setter`|Selectively|Per field, or skip and use business methods|
|`@NoArgsConstructor(access = PROTECTED)`|Yes|Required by Hibernate|
|`@AllArgsConstructor`|No|Exposes `id` and `version`|
|`@RequiredArgsConstructor`|Rarely|Only for `final` fields, which entities usually don't have|
|`@Builder`|Careful|Fine with a private all-args constructor; easy to skip required fields|
|`@ToString`|Only with explicit includes|Never on relationships or secrets|
|`@EqualsAndHashCode`|No|Write it by hand, as shown|
|`@Data`|**No**|Bundles the risky ones together|

---

## Common mistakes

|Mistake|What goes wrong|Fix|
|---|---|---|
|`@Data` on an entity|Broken `equals`/`hashCode`, loops in `toString`|Use the specific annotations above|
|`equals` comparing all fields|Entity lost in `HashSet` after a change|Compare id or a business key|
|`hashCode` based on a generated id|Changes after `save()`|Constant hash code|
|`getClass() != o.getClass()` in `equals`|A proxy never equals the real object|Use `instanceof`|
|Relationships in `toString`|Queries or infinite recursion|Print only id and simple fields|
|Public setter for `id`|Anyone can overwrite identity|No setter|
|`final` entity class|Lazy proxies cannot be created|Leave it non-final|
|Updating only one side of a relationship|Foreign key is not saved|Use `addItem` helpers|
|Returning the internal list|Outsiders bypass your rules|Return an unmodifiable view|
|Public no-args constructor|Half-empty objects|`protected`|

---

## A related concept: why records cannot be entities

Java **records** are immutable, final, and have no no-args constructor, so they break every rule in section 1. That is why records are wonderful for **DTOs**, as you saw in the earlier lessons, but they cannot be `@Entity` classes. Entities need to be changeable objects that Hibernate controls, while records are fixed snapshots of data. (Newer Hibernate versions do allow records as small embedded value types, but not as full entities.)

---





[[Spring Framework]]