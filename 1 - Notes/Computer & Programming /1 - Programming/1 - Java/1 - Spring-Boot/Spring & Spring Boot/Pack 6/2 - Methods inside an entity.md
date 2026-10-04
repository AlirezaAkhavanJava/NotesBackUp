# Methods inside an entity: constructors, `equals`/`hashCode`, `toString`, and the Lombok shortcuts

## Mental model: an ID card

An entity object is like a **person known to a registry**. Two questions come up constantly:

1. **How was this person created?** → constructors
2. **Are these two records the same person?** → `equals` / `hashCode`
3. **How do I describe this person in a log line?** → `toString`

The difficulty is that an entity lives in two worlds at once (Java memory and the database row), so the default Java behavior for each of these is wrong or dangerous for entities.

---

# 1. Constructors

## What you need

|Constructor|Required?|Purpose|
|---|---|---|
|**No-arg** (`protected`)|**Yes, mandatory**|Hibernate creates an empty object by reflection, then fills fields from the row|
|**Business constructor** (the fields a valid new object needs, **without `id`**)|Strongly recommended|_You_ create valid objects in your code|
|All-args including `id`|Avoid|Lets code invent an id, which the database should assign|

```java
@Entity
public class Product {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private BigDecimal price;

    protected Product() { }                       // for Hibernate only

    public Product(String name, BigDecimal price) {   // for YOUR code
        this.name = name;
        this.price = price;
    }
}
```

## Why it works this way

Hibernate loads a row in two steps: call the no-arg constructor to get a blank object, then set the fields directly. It never calls your business constructor. That is why:

- **No-arg is mandatory.** Without it, startup or first load fails (_"No default constructor for entity"_).
- **`protected`, not `public`.** Hibernate can still reach it (and its proxy subclasses can), but your own code can't create half-empty objects by accident. Making it `private` breaks lazy-loading proxies.
- **Business constructor without `id`:** a new object has no id until the database assigns one. If any caller can pass an id, `save()` may treat it as an existing row (a merge) instead of an insert.

If you write **no constructor at all**, Java gives you an implicit public no-arg one, so it works. The moment you add a business constructor, the implicit one disappears, and you must add the no-arg one back yourself. This is the classic "it worked until I added a constructor" bug.

## Lombok shortcuts

|Annotation|Generates|Entity advice|
|---|---|---|
|`@NoArgsConstructor(access = AccessLevel.PROTECTED)`|the protected no-arg constructor|**Use it on every entity**|
|`@AllArgsConstructor`|constructor with every field, `id` included|Avoid public. If needed, `access = PRIVATE` for a builder|
|`@RequiredArgsConstructor`|constructor for `final` / `@NonNull` fields|Rarely useful (entity fields usually aren't final)|
|`@Builder`|a fluent builder|Use with care (below)|

### `@Builder` done safely

```java
@Entity
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Product {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private BigDecimal price;

    @Builder // on the CONSTRUCTOR, not the class
    public Product(String name, BigDecimal price) {
        this.name = name;
        this.price = price;
    }
}

Product p = Product.builder().name("Keyboard").price(new BigDecimal("49.90")).build();
```

Putting `@Builder` on the constructor (not the class) keeps `id` out of the builder. On the class, it would include `id` and require an all-args constructor.

**Builder gotcha:** field initializers are ignored by the builder:

```java
private List<Item> items = new ArrayList<>();   // builder leaves this null!
```

Fix with `@Builder.Default`, or initialize inside the constructor.

---

# 2. Getters and setters

## What you need

Hibernate with **field access** (annotations on fields) does **not** need them; it reads fields directly. _Your_ code (mappers, services, Jackson if you ever serialize) does.

|Rule|Why|
|---|---|
|**Getters: yes**|Reading state from outside the class|
|**Setters: only where change is legitimate**|Each setter is a way to put the object into an invalid state|
|**No setter for `id`**|The database owns identity|
|Prefer intention-revealing methods (`changePrice(...)`, `rename(...)`) over blind setters|Lets the entity enforce rules in one place|

```java
public void changePrice(BigDecimal newPrice) {
    if (newPrice.signum() <= 0) throw new IllegalArgumentException("price must be positive");
    this.price = newPrice;
}
```

## Lombok

```java
@Getter                    // all fields
public class Product {

    @Id @GeneratedValue
    @Setter(AccessLevel.NONE)       // explicit: never a setter for the id
    private Long id;

    @Setter               // setter only on fields that may change
    private String name;
}
```

Class-level `@Setter` generates a setter for **every** field, including `id` and `version`. Prefer field-level `@Setter`.

---

# 3. `equals()` and `hashCode()`

## What they are

- `equals(a, b)`: "are these the same thing?"
- `hashCode()`: a number used by `HashSet`, `HashMap`, and `HashSet`-backed JPA collections to find objects quickly.

**The contract:** if `a.equals(b)`, then `a.hashCode() == b.hashCode()`. And the hash must **not change while the object sits in a hash collection**.

## Why the default is wrong for entities

Java's default `equals` compares **references** (same object in memory):

```java
Product a = repo.findById(1L).get();   // transaction 1
Product b = repo.findById(1L).get();   // transaction 2
a == b           // false: two Java objects...
a.equals(b)      // false with the default... but they are the SAME database row
```

Within a single transaction Hibernate's first-level cache returns the same object, so identity works. Across transactions, detached objects, and collections, it doesn't.

## When you actually need them

- Entities placed in a **`Set`** (`Set<OrderItem>`, `@ManyToMany`), which is the most common reason.
- Removing or checking `contains()` in collections (`order.getItems().remove(item)`).
- Comparing a detached entity with a freshly loaded one.
- Using entities as `Map` keys.

If you never do any of these, the default is acceptable. But it's cheap insurance to define them properly on entities involved in relationships.

## Why it's hard: three problems

**Problem 1: the id is `null` until saved.**

```java
Product p = new Product("Keyboard", price);   // id == null
set.add(p);                                   // hash computed from id=null → bucket X
repo.save(p);                                 // id becomes 7 → hash changes
set.contains(p);                              // false! the object is "lost" in the wrong bucket
```

**Problem 2: all-field `equals` is wrong.** If `equals` compares `name` and `price`, then after a rename, the same row isn't equal to itself, and loading triggers lazy fields inside `equals`.

**Problem 3: proxies.** For lazy loading, Hibernate hands you a **subclass proxy** (`Product$HibernateProxy$abc`) whose fields are empty until initialized. So:

- `getClass() != o.getClass()` comparisons fail between a proxy and a real object.
- Reading `other.id` (field) on a proxy returns `null`; you must call `other.getId()`.

## The three strategies

|Strategy|`equals` based on|Pros|Cons|
|---|---|---|---|
|**A. Business/natural key** (`sku`, `email`, `isbn`)|an immutable, unique, always-present field|simple, stable before and after save|needs a truly immutable unique value|
|**B. Assigned UUID** (generated in the constructor)|the UUID|stable from creation; unguessable ids|UUID column, slightly bigger indexes|
|**C. Database id + constant hashCode**|`id`, only when non-null|works with generated ids|all instances share one hash (fine for small collections)|

### Strategy A / B example (the cleanest)

```java
@Entity
public class Product {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, updatable = false)
    private String sku;                       // immutable business key

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Product other)) return false;     // instanceof works with proxies
        return sku != null && sku.equals(other.getSku());    // getter, not field (proxy-safe)
    }

    @Override
    public int hashCode() {
        return Objects.hash(sku);              // stable for the object's lifetime
    }
}
```

### Strategy C example (when you only have the generated id)

```java
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof Product other)) return false;
    return id != null && id.equals(other.getId());    // two unsaved objects are never equal
}

@Override
public int hashCode() {
    return Hibernate.getClass(this).hashCode();       // constant per class, survives save()
}
```

How it solves the problems:

- Unsaved objects: `id == null` → equal only to themselves, which is correct (two new, unsaved products are different).
- `hashCode` doesn't depend on `id`, so it never changes when `save()` assigns the id (**Problem 1** solved).
- Uses `instanceof` + `getId()` (**Problem 3** solved).
- `Hibernate.getClass(this)` unwraps proxies so a proxy and its real object share one hash.

## Lombok for `equals`/`hashCode`

```java
@EqualsAndHashCode(onlyExplicitlyIncluded = true)     // start from NOTHING
public class Product {

    @Id @GeneratedValue
    private Long id;

    @EqualsAndHashCode.Include                        // only the business key
    @Column(nullable = false, unique = true, updatable = false)
    private String sku;

    private String name;                              // not part of equality
}
```

`onlyExplicitlyIncluded = true` flips Lombok from "everything" to "only what I mark". This fits **Strategy A/B** perfectly. For **Strategy C** (id-based, null-aware, constant hash) Lombok can't express it, so write it by hand.

**Never** use a bare `@EqualsAndHashCode` or `@Data` on an entity: they include _all_ fields, including lazy collections (hidden queries, infinite loops through bidirectional relationships) and the generated id (the hash that changes after `save`).

---

# 4. `toString()`

## What it is, and why you need it

`toString()` turns an object into text for **logs, debugging, and error messages**. Without it you get `Product@3f2a1b`, useless in a log.

## Why it's dangerous on entities

```java
@Entity class Order {
    @ManyToOne private User user;
    @OneToMany(mappedBy = "order") private List<OrderItem> items;

    @Override public String toString() { return "Order{" + user + ", " + items + "}"; }
}
@Entity class OrderItem {
    @ManyToOne private Order order;          // points back
    @Override public String toString() { return "Item{" + order + "}"; }
}
```

|Hazard|What happens|
|---|---|
|**Bidirectional recursion**|`Order.toString()` → `OrderItem.toString()` → `Order.toString()` ... → `StackOverflowError`|
|**Lazy loading**|printing `items` fires a SQL query, or throws `LazyInitializationException` outside a transaction, **just from a log statement**|
|**Sensitive data**|`toString` of a `User` may print the password hash into logs|
|**Performance**|a log line at DEBUG level can silently load thousands of rows|

**Rule:** `toString()` prints only the **id and a few basic, non-lazy, non-sensitive fields**. Never relationships, never secrets.

## Manual version

```java
@Override
public String toString() {
    return "Product{id=" + id + ", name='" + name + "'}";
}
```

## Lombok

```java
@ToString(onlyExplicitlyIncluded = true)       // allow-list approach
public class Product {
    @ToString.Include private Long id;
    @ToString.Include private String name;
    private BigDecimal price;                  // not printed
    @OneToMany(mappedBy = "product") private List<Review> reviews;   // not printed
}
```

The opposite approach is a deny-list:

```java
@ToString
public class Order {
    @ToString.Exclude @ManyToOne private User user;
    @ToString.Exclude @OneToMany(mappedBy = "order") private List<OrderItem> items;
}
```

The allow-list is safer: when someone adds a new relationship later, it isn't printed by accident.

---

# 5. The Lombok shortcut table

|Lombok|Replaces|Safe on entities?|
|---|---|---|
|`@Getter`|getters|Yes|
|`@Setter` (field level)|setters|Yes, selectively|
|`@Setter` (class level)|setters for all fields|Risky (exposes `id`, `version`)|
|`@NoArgsConstructor(access = PROTECTED)`|JPA constructor|**Yes, always**|
|`@AllArgsConstructor`|all-field constructor|Avoid public (includes `id`)|
|`@RequiredArgsConstructor`|constructor for final fields|Rarely relevant|
|`@Builder` (on a constructor)|builder|Yes, with `@Builder.Default` for initializers|
|`@ToString(onlyExplicitlyIncluded = true)`|`toString`|Yes|
|`@ToString` (bare)|`toString` of all fields|**No** (recursion, lazy loading)|
|`@EqualsAndHashCode(onlyExplicitlyIncluded = true)`|`equals`/`hashCode` on a business key|Yes|
|`@EqualsAndHashCode` (bare)|all-field version|**No**|
|`@Data`|getters + setters + `toString` + `equals`/`hashCode` + required constructor|**No, never on entities**|
|`@Value`|immutable class (final, all-final fields)|**No**, entities can't be final|
|`@Slf4j`|a `log` field|Not on entities (they're not beans; log in services)|

`@Data` is perfect on **DTOs and POJOs** (though for DTOs, Java **records** are now usually better). It is a trap on entities because it bundles the dangerous `toString`, `equals`, and `hashCode`.

## A recommended entity, putting it all together

```java
@Entity
@Table(name = "products")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@ToString(onlyExplicitlyIncluded = true)
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @ToString.Include
    private Long id;                               // no setter

    @EqualsAndHashCode.Include
    @ToString.Include
    @Column(nullable = false, unique = true, updatable = false)
    private String sku;                            // business key, immutable

    @Setter
    @ToString.Include
    @Column(nullable = false, length = 100)
    private String name;

    @Setter
    private BigDecimal price;

    @Builder
    public Product(String sku, String name, BigDecimal price) {
        this.sku = sku;
        this.name = name;
        this.price = price;
    }
}
```

## Setup (Maven, on Debian)

```xml
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
</dependency>
```

Spring Boot manages the version, and Spring Initializr adds the lombok exclusion to the build plugin for you. Lombok is a **compile-time annotation processor**: it rewrites your class during compilation, so the generated methods exist in the `.class` file but not in your source. Your IDE needs Lombok support (IntelliJ includes it, and Eclipse/VS Code need the plugin or extension), otherwise it shows false "method not found" errors even though Maven builds fine.

---

# Nuances and gotchas

**1. Lombok is optional.** Everything above can be written by hand. Lombok removes boilerplate but also hides what is generated, which is why the safe defaults (`onlyExplicitlyIncluded`, protected constructor) matter. Some teams ban it on entities entirely.

**2. Lombok-generated `equals` accesses fields.** For `@EqualsAndHashCode.Include` on a **field** it uses the getter if one exists, which is proxy-safe, but only because `@Getter` is present. Keep getters when relying on it.

**3. Use `instanceof` with proxies, not `getClass()`.** A `getClass() != o.getClass()` check breaks equality between a proxy and its target (the "IntelliJ default generated equals" trap).

**4. Constant `hashCode` isn't a performance disaster in practice.** Entity collections are typically small. Hash collision degradation only matters for sets with thousands of elements.

**5. If `equals` uses a mutable field, objects vanish from sets.** Change `sku` on an object inside a `HashSet` and `contains` fails. That is why the business key is `updatable = false`.

**6. Records vs entities.** A record can't be an entity (final, no no-arg constructor), but is ideal for the DTOs, where its generated `equals`, `hashCode`, `toString`, and constructor are exactly what you want. This is why entities need this manual care and records don't.

**7. Hibernate doesn't call `equals` for dirty checking.** It compares field values against its snapshot, so `equals` is purely for **your** collections and comparisons.

**8. `@Version` field and equals.** Never include `version` in `equals`/`hashCode`; it changes on every update.

**9. Inheritance.** With `@MappedSuperclass` base classes, put `id`, `equals`, and `hashCode` in the base once, so every entity gets the same correct behavior.

## Quick reference

|Need|Do|
|---|---|
|Hibernate can instantiate it|`@NoArgsConstructor(access = PROTECTED)`|
|Create valid new objects|constructor without `id` (+ `@Builder` on it)|
|Read state|`@Getter`|
|Controlled mutation|field-level `@Setter` or domain methods; never for `id`|
|Safe in `Set`s|`@EqualsAndHashCode(onlyExplicitlyIncluded = true)` on a business key, or hand-written id-based with constant hash|
|Safe logging|`@ToString(onlyExplicitlyIncluded = true)`, no relationships|
|Avoid|`@Data`, bare `@ToString`, bare `@EqualsAndHashCode`, public all-args constructor|




[[Spring Framework]]
[[Lombok]]