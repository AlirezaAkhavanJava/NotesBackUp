**What this lesson covers:** Not every field of an entity comes from the user. Some values the user types, such as a note or a quantity. Others the server must decide: the ID, the creation time, the owner, the status, the computed total, and the password hash. Mixing these up is one of the most common security and data-quality mistakes in production, because a client that can set a field the server should control can often do things the system never intended. In this lesson you'll learn to classify each field by its source, to keep request data separate from entity data, and to build the entity on the server side from the user's input.

## The core idea: a trust boundary

Think of your application as having a boundary. Everything that crosses it from outside (an HTTP request body, a query parameter, a file upload) is **untrusted**. Anything the server computes itself, such as the current time, the logged-in user, or a price read from the database, is **trusted**. The rule is simple: **untrusted input may only fill the fields that the user is allowed to decide.** Every other field must be set inside the server.

That's why the request body and the entity should be different classes. The request describes what the client _asks for_. The entity describes what the server _stores_.

## Step 1: Classify every field by its source

For each field, ask "who is allowed to decide this value?" The answer falls into one of five groups:

|Source|Examples|Who sets it|Can the client send it?|
|---|---|---|---|
|**User decision**|`note`, `quantity`, `displayName`|The user, through the request|Yes, after validation|
|**Authenticated context**|`customer`, `createdBy`, `grantedBy`|The security context (the logged-in user)|No|
|**Clock**|`createdAt`, `placedAt`, `updatedAt`|The server's clock|No|
|**Server rule or default**|`status = PENDING`, `enabled = true`, `role = USER`|The application's business rules|No|
|**Derived or stored by the system**|`id`, `version`, `totalAmount`, `passwordHash`, `unitPrice`|The database, Hibernate, or a calculation|No|

The last two groups carry the most risk. A `totalAmount` sent by the client can be a lie, and a `passwordHash` sent by the client bypasses hashing completely. The server always recalculates or refuses those values.

## Step 2: Build a request type that only holds user decisions

Here's an order-placement request. Notice what it leaves out:

```java
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import java.util.List;

public record PlaceOrderRequest(
        @NotEmpty List<@Valid OrderLineRequest> lines,   // At least one line; each line is checked too
        @Size(max = 500) String note                      // Optional, limited in length
) {}

public record OrderLineRequest(
        @NotBlank String sku,                             // Which product the user wants
        @Min(1) @Max(100) int quantity                    // How many, within a sensible range
) {}
```

- The request has no `id`, `customer`, `status`, `placedAt`, `totalAmount`, or prices. The user cannot send them, even by accident.
- `List<@Valid OrderLineRequest>` applies validation to each element of the list. Without `@Valid` there, the nested rules are skipped.
- `@Min(1)` and `@Max(100)` are business limits decided by you, so they belong at the boundary where input enters.

## Step 3: Build the entity from the request on the server

The entity receives the user's decisions as parameters, and it gets everything else from the server:

```java
@Entity
@Table(name = "orders")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)      // Database decides: never set in code
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "customer_id", nullable = false)      // From the logged-in user, never the request
    private AppUser customer;

    @Column(length = 500)
    private String note;                                     // From the user

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private OrderStatus status;                              // Server rule: always starts as PENDING

    @Column(name = "placed_at", nullable = false, updatable = false)
    private Instant placedAt;                                // Server clock

    @Column(name = "total_amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal totalAmount;                          // Calculated by the server

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderLine> lines = new ArrayList<>();

    @Version
    private Long version;                                    // Hibernate manages it

    protected Order() {}

    private Order(AppUser customer, String note, Instant placedAt) {
        this.customer = customer;
        this.note = note;
        this.status = OrderStatus.PENDING;                   // Business rule lives here
        this.placedAt = placedAt;
        this.totalAmount = BigDecimal.ZERO;
    }

    // Factory method: the only public way to start an order
    public static Order open(AppUser customer, String note, Instant now) {
        return new Order(customer, note, now);
    }

    // Price is copied from the product at this moment, not taken from the client
    public void addLine(Product product, int quantity) {
        OrderLine line = new OrderLine(this, product, quantity, product.getPrice());
        lines.add(line);
        totalAmount = totalAmount.add(line.lineTotal());
    }
}
```

What this gives you:

- The constructor is private, and the static `open` method is the only entry point. Callers can't pass a status or a total, because those parameters don't exist.
- The status is set by a rule (`PENDING`), not by a parameter.
- `unitPrice` is copied from the product at the moment of ordering. If prices change later, old orders keep the price the customer actually paid. This is a _snapshot_, and it's a classic reason to derive a field on the server rather than trust either the client or a later database value.
- `totalAmount` is calculated from the lines, so the stored total always matches the lines.

## Step 4: Connect the pieces in a service

The service is where user input, the logged-in user, the clock, and the database meet:

```java
@Service
@RequiredArgsConstructor
public class OrderService {

    private final ProductRepository products;
    private final OrderRepository orders;
    private final Clock clock;                 // Injected, so tests can control the time

    @Transactional
    public Order placeOrder(AppUser currentUser, PlaceOrderRequest request) {
        Order order = Order.open(currentUser, request.note(), clock.instant());

        for (OrderLineRequest line : request.lines()) {
            Product product = products.findBySku(line.sku())
                    .orElseThrow(() -> new IllegalArgumentException("Unknown SKU: " + line.sku()));
            order.addLine(product, line.quantity());
        }

        return orders.save(order);
    }
}
```

- `currentUser` comes from Spring Security, usually through `@AuthenticationPrincipal`. It never comes from the request body.
- The `Clock` bean is declared once, for example `@Bean Clock clock() { return Clock.systemUTC(); }`. In tests you can pass a fixed clock and check timestamps deterministically.
- Unknown products fail with a clear message, instead of creating an order with a missing price.

## Step 5: Return a response that exposes only what the client should see

The entity is the wrong thing to return, because it includes internal fields such as `version`, the full `AppUser`, and anything added later. Map it to a response type:

```java
public record OrderResponse(
        Long id,
        String status,
        BigDecimal totalAmount,
        Instant placedAt,
        List<OrderLineResponse> lines
) {
    public static OrderResponse from(Order order) {
        return new OrderResponse(
                order.getId(),
                order.getStatus().name(),
                order.getTotalAmount(),
                order.getPlacedAt(),
                order.getLines().stream().map(OrderLineResponse::from).toList()
        );
    }
}
```

The response is a one-way mapping. Nothing in the response gets written back into the entity, so the output shape can change without affecting storage.

## Step 6: Why you must never bind the entity directly

Consider this tempting shortcut:

```java
@PostMapping("/orders")
public Order place(@RequestBody Order order) { ... }   // DANGEROUS
```

Spring would copy every JSON field into the entity. A client could send:

```json
{"status":"SHIPPED","totalAmount":0.01,"placedAt":"2020-01-01T00:00:00Z","customer":{"id":99}}
```

and the server would store exactly that. This is called **mass assignment**, and it has caused real breaches. The fix is always the same: bind a request type that contains only user decisions, and let the server fill in the rest.

## Updating existing data

The same classification applies to edits, and it adds one new idea: the user may change only some fields, and some fields may never change after creation.

```java
public record UpdateProfileRequest(
        @NotBlank @Size(max = 100) String displayName,   // User may change this
        @Size(max = 500) String bio                       // User may change this
) {}                                                      // No email, role, or id: those are not editable here
```

On the entity, `createdAt` has `updatable = false`, and `version` is managed by Hibernate. Changing an email belongs in its own flow, with verification, so it never sits inside a general "update profile" request.

One exception deserves attention. Optimistic locking uses a version number that the client may echo back, usually in an `If-Match` or `ETag` header. Here the client does send a value the server issued, but the server still decides whether it's current. The client never sets the version freely.

## Common mistakes

1. **Binding the entity as `@RequestBody`.** This is mass assignment. Always use a request type.
2. **Trusting a client-sent total or price.** Recalculate from the database on the server.
3. **Taking `customerId` from the request.** Use the authenticated user. Otherwise one user can create orders for another.
4. **Letting the client choose the status.** Status should follow business rules, and changing it should go through named methods such as `cancel()` or `markPaid()`.
5. **Using `new Date()` or `Instant.now()` scattered through the code.** Inject a `Clock` so timestamps are consistent and testable.
6. **Accepting input without validation.** Every field that comes from the user needs a constraint, such as `@NotBlank`, `@Size`, or `@Min`.
7. **Returning the entity from the controller.** It leaks internal fields and locks your storage shape to your API.

## Try it yourself

1. Take a `Product` entity with `id`, `sku`, `name`, `price`, `active`, `createdAt`, and `version`. Write a `CreateProductRequest` containing only the fields an administrator may choose, and explain for each excluded field who or what sets it.
2. Add a `cancel()` method to `Order` that is allowed only when the status is `PENDING`, and throws an exception otherwise. Explain why a `setStatus` method would be a weaker design.
3. Write a test that places an order with a `Clock` fixed to a known instant, and check that `placedAt` equals that instant, even though the test never passed it in the request.


[[Spring Framework]]