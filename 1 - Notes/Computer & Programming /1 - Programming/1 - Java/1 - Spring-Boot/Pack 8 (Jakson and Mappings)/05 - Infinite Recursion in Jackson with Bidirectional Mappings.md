

## Core intuition

Picture two mirrors facing each other. Each reflects the other, forever. In a bidirectional mapping, `Customer` holds a list of `Order`s, and each `Order` holds its `Customer`. Jackson is the camera that tries to photograph both, and it never finds an edge.

From the previous lessons, this is exactly the `mappedBy` + `@JoinColumn` setup: two Java fields point at each other, even though the database has only one foreign key.

## What happens, step by step

1. Your controller returns a `Customer`.
2. Jackson serializes `customer` and reaches the `orders` field.
3. For each `Order`, it serializes the `order` and reaches its `customer` field.
4. That `customer` is the same object from step 2, so Jackson serializes it again, reaching `orders` again.
5. This repeats until the stack is full, giving `StackOverflowError` or `HttpMessageNotWritableException: Infinite recursion`.

```java
@Entity
public class Customer {
    @Id @GeneratedValue
    private Long id;

    @OneToMany(mappedBy = "customer")
    private List<Order> orders = new ArrayList<>();
}

@Entity
public class Order {
    @Id @GeneratedValue
    private Long id;

    @ManyToOne
    @JoinColumn(name = "customer_id")
    private Customer customer;
}
```

The database has no problem, because it stores only a number (`customer_id`). The loop exists only in the Java object graph, and JSON has no way to say "this points back to something I already printed."

## The fixes, from quick to correct

### Fix 1: `@JsonManagedReference` / `@JsonBackReference`

The parent side is serialized normally. The child's back-link is skipped.

```java
@Entity
public class Customer {
    @OneToMany(mappedBy = "customer")
    @JsonManagedReference          // serialized normally
    private List<Order> orders;
}

@Entity
public class Order {
    @ManyToOne
    @JoinColumn(name = "customer_id")
    @JsonBackReference             // omitted from JSON
    private Customer customer;
}
```

Result: `Customer` JSON includes its orders, and each order's JSON does **not** include the customer.

Limitation: serializing an `Order` directly will never show its customer. The direction is fixed.

### Fix 2: `@JsonIgnore`

Simply hides one side:

```java
@OneToMany(mappedBy = "customer")
@JsonIgnore
private List<Order> orders;
```

Simple, but that field is gone from JSON in every context.

### Fix 3: `@JsonIgnoreProperties` (more flexible)

Keep the field, but cut the loop at the second level:

```java
@ManyToOne
@JoinColumn(name = "customer_id")
@JsonIgnoreProperties("orders")   // when serializing the customer inside an order, skip its "orders"
private Customer customer;
```

### Fix 4: `@JsonIdentityInfo`

Jackson writes each object once, then uses its id for repeated references:

```java
@JsonIdentityInfo(generator = ObjectIdGenerators.PropertyGenerator.class, property = "id")
@Entity
public class Customer { ... }
```

It works, but the JSON becomes awkward, with ids standing in for nested objects, and clients must understand that format. Most APIs avoid it.

### Fix 5 (the real solution): don't serialize entities, use DTOs

The other fixes treat a symptom. The cause is exposing **database entities** directly as your API's JSON.

```java
public record OrderDto(Long id, Long customerId) {}

public record CustomerDto(Long id, String name, List<OrderDto> orders) {}
```

```java
public CustomerDto toDto(Customer c) {
    return new CustomerDto(
        c.getId(),
        c.getName(),
        c.getOrders().stream()
            .map(o -> new OrderDto(o.getId(), c.getId()))
            .toList()
    );
}
```

The DTO graph is a tree with a defined shape, so no loop is possible. You also control exactly what the client sees.

## Why DTOs are better than annotations

- Entity annotations mix database concerns with API concerns in one class.
- With lazy relationships, Jackson may touch a field and trigger an unwanted query (the N+1 problem), or throw `LazyInitializationException`.
- API shape is locked to your table structure; changing a column changes your public JSON.
- Sensitive fields (like passwords) leak unless you remember to hide each one.

## Gotchas and related loops

**Lombok causes the same problem outside Jackson.** `@Data`, `@ToString`, and `@EqualsAndHashCode` on both entities generate `toString()`, `hashCode()` and `equals()` that call each other:

```java
@Entity
@Getter @Setter
@ToString(exclude = "orders")           // break the loop
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
public class Customer {
    @EqualsAndHashCode.Include
    @Id private Long id;
    ...
}
```

If you see `StackOverflowError` in logs or when debugging, and no JSON is involved, check Lombok first.

**Do not remove `mappedBy` to "fix" it.** Without `mappedBy`, Hibernate creates a second, unwanted join table. The loop is a serialization problem, not a mapping problem.

**Do not use `FetchType.EAGER` as a fix.** It changes when data loads, not how it is serialized, and often makes performance worse.

**`@JsonManagedReference` also affects deserialization.** When JSON is parsed into an entity, Jackson automatically sets the back-reference (`order.customer`) for you, which is a small benefit of Fix 1.

## Which fix should you choose?

|Situation|Choice|
|---|---|
|Learning, quick prototype|`@JsonIgnore` or `@JsonManagedReference` / `@JsonBackReference`|
|One specific field to hide|`@JsonIgnoreProperties`|
|Real project, public API|**DTOs** (records plus a mapper such as MapStruct)|




[[Spring Framework]]