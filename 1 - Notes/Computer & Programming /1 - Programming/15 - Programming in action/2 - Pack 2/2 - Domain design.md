
Domain design in Spring Boot 4 isn't about memorizing annotations — it's about making **architectural decisions** before writing a single class. The framework's shift toward Jackson 3, JSpecify null-safety, AOT compilation, and modular starters means the cost of getting your domain model wrong is higher than ever. This tutorial builds the mental model first, then the mechanics, then the concrete code.

---

## 1. The Mental Model: Layers as "Translation Stations"

**Analogy**: Think of your application as an international airport. Passengers (data) arrive from the outside world speaking foreign languages (JSON, HTTP). Before they can move through the terminal, they pass through **translation stations**:

- **The Gate (Controller Layer)**: Where passengers first arrive. They speak the "foreign language" of HTTP requests. A translator (DTO) converts their speech into a standard internal format.
- **The Customs Checkpoint (Service/Domain Layer)**: Where the real rules live. Passengers must have valid documents (business rules), and their identity is verified against the core systems (domain entities).
- **The Baggage Handling (Repository Layer)**: Where luggage (persistent state) is stored and retrieved. The baggage system doesn't care about passenger conversations — it only cares about the physical objects (entities).

**Why this matters for Spring Boot 4**: In earlier versions, developers often used the same class as both the "passenger" (HTTP payload) and the "luggage" (database entity). Spring Boot 4's stricter null-safety, Jackson 3 serialization, and AOT compilation make this conflation dangerous. A class annotated with `@Entity` and used as a `@RequestBody` will serialize **every field**, including lazy-loaded associations, internal IDs, and audit columns. Jackson 3's stricter handling of nullability will expose this immediately.

**The core principle**: **Each layer has its own data representation.** The controller speaks DTOs. The domain layer speaks entities and value objects. The repository speaks entities. The mapping between them is explicit, testable, and — critically — **compile-time safe**.

---

## 2. The Domain Layer: Entities, Value Objects, and Aggregates

### 2.1 Entities: The "Luggage" of Your System

**Definition**: An `@Entity` is a class whose instances represent a row in a database table. It has **identity** (an `@Id`), a **lifecycle** (created, updated, deleted), and **persistent state** (fields mapped to columns). Entities are not just data bags — they should encapsulate business invariants.

**Spring Boot 4 / Jakarta EE 11 changes**: All JPA imports use the `jakarta.persistence.*` namespace. There is no `javax.persistence.*` in Spring Boot 4.

**Basic entity example**:

```java
package com.example.shop.order.domain;

import jakarta.persistence.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "orders", indexes = {
    @Index(name = "idx_orders_customer_id", columnList = "customer_id"),
    @Index(name = "idx_orders_status", columnList = "status")
})
@EntityListeners(AuditingEntityListener.class)
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(nullable = false, updatable = false)
    private UUID id;

    @Column(name = "customer_id", nullable = false)
    private UUID customerId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private OrderStatus status = OrderStatus.PENDING;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal totalAmount;

    @CreatedDate
    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    @Column(nullable = false)
    private Instant updatedAt;

    protected Order() {} // for JPA

    public Order(UUID customerId, BigDecimal totalAmount) {
        this.customerId = customerId;
        this.totalAmount = totalAmount;
        this.status = OrderStatus.PENDING;
    }

    // Business method — NOT a setter
    public void markAsPaid() {
        if (this.status != OrderStatus.PENDING) {
            throw new IllegalStateException("Only pending orders can be paid");
        }
        this.status = OrderStatus.PAID;
    }

    // Getters only — no public setters
    public UUID getId() { return id; }
    public UUID getCustomerId() { return customerId; }
    public OrderStatus getStatus() { return status; }
    public BigDecimal getTotalAmount() { return totalAmount; }
}
```

**Component-by-component explanation**:

| Annotation / Element | Purpose |
|---|---|
| `@Entity` | Declares the class as a JPA entity. Mandatory. |
| `@Table(name = "orders", indexes = ...)` | Optional. Specifies the table name and indexes. The logical name should correspond to the class name; `@Table` is for physical naming deviations. |
| `@EntityListeners(AuditingEntityListener.class)` | Enables Spring Data JPA auditing for `@CreatedDate` and `@LastModifiedDate`. Requires `@EnableJpaAuditing` on a configuration class. |
| `@Id` | Marks the primary key field. Mandatory. |
| `@GeneratedValue(strategy = GenerationType.UUID)` | Generates a UUID primary key. Alternative: `IDENTITY` for auto-increment `Long`. |
| `@Column` | Explicit column mapping. Always declare `nullable` and `length`/`precision` — the schema is generated from the entity. |
| `@Enumerated(EnumType.STRING)` | Stores enum as a string (safe against ordinal reordering). |
| `@CreatedDate` / `@LastModifiedDate` | Spring Data auditing annotations — populated automatically on persist/update. |
| `protected Order()` | JPA requires a no-arg constructor. Use `protected` to prevent accidental use. |
| Business method (`markAsPaid()`) | Encapsulates invariant checks. The entity is **not** anemic — it protects its own state. |

**Why this design works**: The entity is a **rich domain model**, not an anemic data bag. The `markAsPaid()` method enforces the business rule that only pending orders can be paid. This rule lives in the domain layer, not in a service. In Spring Boot 4's AOT-compiled world, keeping business logic in the entity means it's available during build-time analysis and native image compilation.

**Edge case — Lombok and JPA**: If you use Lombok's `@Data` on an entity, it generates `equals()` and `hashCode()` based on all fields, including the ID. For unsaved entities (ID is null), this breaks `Set` semantics. **Never use `@Data` on JPA entities.** Use `@Getter` and `@Setter` selectively, or write your own `equals()`/`hashCode()` based on the business key.

### 2.2 Value Objects: The "Passports" That Define Identity

**Definition**: A value object is an immutable object that has **no identity** — two value objects with the same attributes are interchangeable. It represents a descriptive aspect of the domain.

**When to use `@Embeddable`**: When a value object is stored **inside the same table** as the entity that owns it. For example, a `Money` value object stored as `amount` and `currency` columns in the `orders` table.

```java
package com.example.shop.shared.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.math.BigDecimal;
import java.util.Currency;
import java.util.Objects;

@Embeddable
public class Money {

    @Column(name = "amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal amount;

    @Column(name = "currency", nullable = false, length = 3)
    private String currencyCode;

    protected Money() {} // for JPA

    public Money(BigDecimal amount, Currency currency) {
        if (amount == null || amount.signum() < 0) {
            throw new IllegalArgumentException("Amount must be non-negative");
        }
        this.amount = amount;
        this.currencyCode = currency.getCurrencyCode();
    }

    public Money add(Money other) {
        if (!this.currencyCode.equals(other.currencyCode)) {
            throw new IllegalArgumentException("Cannot add different currencies");
        }
        return new Money(this.amount.add(other.amount), Currency.getInstance(this.currencyCode));
    }

    public BigDecimal amount() { return amount; }
    public Currency currency() { return Currency.getInstance(currencyCode); }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Money money)) return false;
        return amount.compareTo(money.amount) == 0 && currencyCode.equals(money.currencyCode);
    }

    @Override
    public int hashCode() { return Objects.hash(amount, currencyCode); }
}
```

**Why value objects matter in Spring Boot 4**: JSpecify null-safety annotations (`@NullMarked`, `@Nullable`) make the contract of value objects explicit. A `Money` object is never null — it either exists or it doesn't. This eliminates a whole class of null-pointer bugs at the API boundary.

**Edge case — value objects vs. JPA**: JPA requires a no-arg constructor for `@Embeddable` objects. This violates immutability. The standard workaround is a `protected` no-arg constructor and `final` fields for the actual attributes. Hibernate can set fields via reflection, but your code cannot create invalid instances.

### 2.3 Aggregates: The "Transaction Boundary" Unit

**Definition**: An aggregate is a **cluster of domain objects** (entities and value objects) treated as a single unit for data changes. Every aggregate has one **aggregate root** — the only object that outside objects can reference. The aggregate root enforces all invariants for the cluster.

**The rule**: **One aggregate per transaction.** Cross-aggregate changes go through domain events, not direct object references.

```java
package com.example.shop.order.domain;

import org.springframework.data.domain.AbstractAggregateRoot;
import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "orders")
public class Order extends AbstractAggregateRoot<Order> {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "customer_id", nullable = false)
    private UUID customerId;

    @Enumerated(EnumType.STRING)
    private OrderStatus status = OrderStatus.PENDING;

    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id")
    private List<OrderLine> lines = new ArrayList<>();

    protected Order() {}

    public Order(UUID customerId) {
        this.customerId = customerId;
    }

    public void addLine(ProductId productId, int quantity, Money unitPrice) {
        OrderLine line = new OrderLine(productId, quantity, unitPrice);
        this.lines.add(line);
        registerEvent(new OrderLineAddedEvent(this.id, productId, quantity));
    }

    public void markAsPaid() {
        if (this.status != OrderStatus.PENDING) {
            throw new IllegalStateException("Only pending orders can be paid");
        }
        this.status = OrderStatus.PAID;
        registerEvent(new OrderPaidEvent(this.id, this.customerId));
    }

    public UUID getId() { return id; }
    public OrderStatus getStatus() { return status; }
    public List<OrderLine> getLines() { return List.copyOf(lines); }
}
```

**`AbstractAggregateRoot<Order>`** is a Spring Data class that provides the `registerEvent()` method. Events registered here are published when the aggregate is saved through a Spring Data repository. `@DomainEvents` on a method (or `registerEvent()` with `AbstractAggregateRoot`) makes publication automatic.

**Why aggregates matter**: In Spring Boot 4's modularized architecture, each aggregate is a natural **module boundary**. The `Order` aggregate owns `OrderLine` — no other aggregate references `OrderLine` directly. This enforces encapsulation and makes the domain model resistant to cross-module coupling.

**Edge case — `@DomainEvents` only works with repositories**: Domain events are published only when `save()`, `saveAll()`, `delete()`, or `deleteAll()` is invoked. If you modify an aggregate outside a repository call, events will not fire. Always persist the aggregate root after state changes.

---

## 3. The DTO Layer: The "Translation Contract"

### 3.1 Why DTOs Are Non-Negotiable in Spring Boot 4

**The rule**: **Never expose an `@Entity` directly from a controller.** This is not a style preference — it's a correctness requirement.

**What goes wrong without DTOs**:
1. **Over-exposure**: The client sees internal fields (`createdAt`, `updatedAt`, internal status enums).
2. **Over-acceptance**: The client can set fields it should never control (e.g., `id`, `status`).
3. **Lazy loading exceptions**: Jackson serializes a lazy collection outside a transaction → `LazyInitializationException`.
4. **Jackson 3 strictness**: Jackson 3's nullability handling will fail on `null` values for non-null fields, exposing internal state.
5. **AOT compilation**: Entities with lazy proxies are difficult to serialize in native images. DTOs are plain records — fully AOT-compatible.

### 3.2 Request DTOs: Java Records with Jakarta Validation

**Why records**: Java records are immutable, concise, and work perfectly with Jackson 3's constructor-based deserialization and MapStruct's constructor mapping. They also carry JSpecify null-safety annotations naturally.

```java
package com.example.shop.order.web;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record CreateOrderRequest(
    @NotNull UUID customerId,
    @NotEmpty @Valid List<OrderLineRequest> lines
) {}

public record OrderLineRequest(
    @NotNull UUID productId,
    @Min(1) @Max(100) int quantity,
    @NotNull @DecimalMin("0.01") BigDecimal unitPrice
) {}
```

**Critical validation rules for Spring Boot 4**:

| Rule | Why |
|---|---|
| Use `jakarta.validation.*` | `javax.validation.*` is gone. Spring Boot 4 uses Jakarta EE 11. |
| Add `@Valid` on nested object fields | Without it, validation does **not** cascade to `OrderLineRequest` fields. |
| Add `@Valid` on the controller parameter | Without it, Spring never triggers validation. |
| Include `spring-boot-starter-validation` | Without it, `@Valid` and all constraints silently do nothing. |
| Use `@NotNull` for UUIDs and objects, `@NotBlank` for strings | `@Size` treats `null` as valid; `@NotNull` rejects it. |

**Edge case — validation groups**: If you use the same DTO for create and update, you can use validation groups to apply different rules:

```java
public interface OnCreate {}
public interface OnUpdate {}

public record UserRequest(
    @Null(groups = OnCreate.class)
    @NotNull(groups = OnUpdate.class)
    UUID id,

    @NotBlank(groups = {OnCreate.class, OnUpdate.class})
    String name
) {}
```

Then in the controller:

```java
@PostMapping
public ResponseEntity<Void> create(@Validated(OnCreate.class) @RequestBody UserRequest request) { ... }

@PutMapping("/{id}")
public ResponseEntity<Void> update(@Validated(OnUpdate.class) @RequestBody UserRequest request) { ... }
```

### 3.3 Response DTOs: Records Without Validation

Response DTOs should be **immutable projections** of the domain state. They do not need validation annotations (the data is already valid — it came from your domain).

```java
package com.example.shop.order.web;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record OrderResponse(
    UUID id,
    UUID customerId,
    String status,
    BigDecimal totalAmount,
    List<OrderLineResponse> lines,
    Instant createdAt
) {}

public record OrderLineResponse(
    UUID productId,
    int quantity,
    BigDecimal unitPrice
) {}
```

**Why separate response DTOs**: The response contract is **your API's public interface**. Changing an entity field should not automatically change the API response. Separate DTOs give you control over versioning, field inclusion, and serialization format. In Spring Boot 4, this separation is enforced by Jackson 3's stricter type handling.

### 3.4 The DTO Design Decision Matrix

| Decision | Recommendation |
|---|---|
| **Record vs. class** | Records for DTOs. Classes only if you need mutable state (rare). |
| **One DTO for request and response?** | **Never.** Separate `CreateXRequest`, `UpdateXRequest`, `XResponse`. |
| **Where to put validation?** | On request DTOs. Not on entities, not on response DTOs. |
| **Nested DTOs?** | Yes, with `@Valid` on the nested field for cascaded validation. |
| **Shared fields between DTOs?** | Use composition (nested records) over inheritance. Records cannot extend classes. |

---

## 4. Mapping: Entity ↔ DTO Translation

### 4.1 The Mapping Decision Tree

| Scenario | Recommended Approach |
|---|---|
| Simple field-to-field mapping | MapStruct (compile-time generated) |
| Complex mapping with business logic | Manual mapper (a `@Component` class) |
| Mapping in tests | Manual mapping or MapStruct with test fixtures |
| Native image (AOT) | MapStruct (generates plain Java, no reflection) |

### 4.2 MapStruct: Compile-Time, Type-Safe Mapping

**Why MapStruct in Spring Boot 4**: MapStruct generates **plain Java mapper implementations** at compile time. There is no reflection, no runtime overhead, and full compatibility with GraalVM native images. This aligns perfectly with Spring Boot 4's AOT-first philosophy.

```java
package com.example.shop.order.web;

import com.example.shop.order.domain.Order;
import com.example.shop.order.domain.OrderLine;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface OrderMapper {

    @Mapping(target = "status", expression = "java(order.getStatus().name())")
    OrderResponse toResponse(Order order);

    OrderLineResponse toLineResponse(OrderLine line);
}
```

**Component-by-component explanation**:

| Element | Purpose |
|---|---|
| `@Mapper(componentModel = "spring")` | Makes the generated mapper a Spring bean. Injected via constructor. |
| `@Mapping(target = "status", expression = ...)` | Custom mapping for enum → String conversion. |
| `toResponse(Order)` | Generates an implementation that maps all matching fields by name. |
| Nested collection mapping | MapStruct automatically maps `List<OrderLine>` to `List<OrderLineResponse>` if a `toLineResponse` method exists. |

**Spring Boot 4 / MapStruct edge case**: There is a known issue with MapStruct-generated mappers on Spring Boot 4.0.2 + Spring Framework 7.0.3 + Java 21 where mapper beans fail to instantiate. The fix is to use constructor-based injection in the mapper interface (which MapStruct supports via `injectionStrategy = InjectionStrategy.CONSTRUCTOR`). Always verify your MapStruct version is compatible with Spring Boot 4.

### 4.3 Manual Mapping: When MapStruct Isn't Enough

For mappings that require repository lookups, external service calls, or complex business logic, use a **manual mapper component**:

```java
@Component
public class OrderDtoMapper {

    private final CustomerRepository customerRepository;

    public OrderDtoMapper(CustomerRepository customerRepository) {
        this.customerRepository = customerRepository;
    }

    public OrderResponse toResponse(Order order) {
        Customer customer = customerRepository.findById(order.getCustomerId())
            .orElseThrow(() -> new CustomerNotFoundException(order.getCustomerId()));

        return new OrderResponse(
            order.getId(),
            customer.getName(), // enriched from another aggregate
            order.getStatus().name(),
            order.getTotalAmount(),
            order.getLines().stream().map(this::toLineResponse).toList(),
            order.getCreatedAt()
        );
    }

    private OrderLineResponse toLineResponse(OrderLine line) {
        return new OrderLineResponse(line.getProductId(), line.getQuantity(), line.getUnitPrice());
    }
}
```

**Why manual mapping here**: The response needs the customer's **name**, which lives in a different aggregate. MapStruct cannot fetch it automatically. This is a deliberate **enrichment step** — the mapper acts as an assembler that combines data from multiple aggregates into a read model.

---

## 5. The Complete Package Structure

### 5.1 Feature-Oriented (Package-by-Domain) — Recommended

```
com.example.shop
├── ShopApplication.java          // @SpringBootApplication (root package)
├── order/
│   ├── domain/
│   │   ├── Order.java            // @Entity, aggregate root
│   │   ├── OrderLine.java        // @Entity, child of Order
│   │   ├── OrderStatus.java      // enum
│   │   ├── OrderPaidEvent.java   // domain event record
│   │   └── OrderRepository.java  // Spring Data repository
│   ├── application/
│   │   └── OrderService.java     // @Service, transactional
│   └── web/
│       ├── OrderController.java  // @RestController
│       ├── CreateOrderRequest.java
│       ├── OrderResponse.java
│       └── OrderMapper.java      // MapStruct
├── customer/
│   ├── domain/
│   │   ├── Customer.java
│   │   └── CustomerRepository.java
│   └── application/
│       └── CustomerService.java
└── shared/
    └── domain/
        └── Money.java            // @Embeddable value object
```

**Why this structure**: Each feature (`order`, `customer`) is a **bounded context**. The `domain/` package contains entities, value objects, events, and repository interfaces. The `application/` package contains services that orchestrate domain operations. The `web/` package contains controllers, DTOs, and mappers. Cross-feature dependencies go through public service interfaces, **never** through direct repository injection.

### 5.2 The Critical Rule: Main Class in Root Package

`@SpringBootApplication` defines a **search base package** for component scanning, entity scanning, and configuration property scanning. If your main class is in `com.example.shop`, Spring scans everything below it. If it's in `com.example.shop.order`, Spring scans only `order` and misses `customer`, `shared`, and any class above it. **Always put the main class in the root package.**

---

## 6. Edge Cases and Pitfalls

### Pitfall 1: `@Data` on JPA Entities

Lombok's `@Data` generates `equals()` and `hashCode()` based on all fields. For a JPA entity with a generated ID, two unsaved entities with the same business data but `null` IDs are **not equal** by `@Data` semantics. This breaks `Set` operations and repository queries. **Never use `@Data` on entities.** Use `@Getter` and a manual `equals()` based on the business key.

### Pitfall 2: Eager Loading Collections

`@OneToMany(fetch = FetchType.EAGER)` is the most common performance mistake in JPA. Every `findById()` will load the entire collection, even if you don't need it. **Always use `LAZY`** and fetch with `JOIN FETCH` or `@EntityGraph` when needed:

```java
@Query("select o from Order o left join fetch o.lines where o.id = :id")
Optional<Order> findWithLines(@Param("id") UUID id);
```

### Pitfall 3: Missing `@Valid` on Nested Objects

```java
public record CreateOrderRequest(
    @NotNull UUID customerId,
    @NotEmpty List<OrderLineRequest> lines  // validation does NOT cascade!
) {}
```

Without `@Valid` on `lines`, the `@Min(1)` on `OrderLineRequest.quantity` is ignored. The request passes validation, and invalid data reaches your service. **Always add `@Valid` to nested object fields and collection element types.**

### Pitfall 4: DTO Validation Without the Starter

Spring Boot 4's modularized starters mean `spring-boot-starter-webmvc` does **not** include validation. You must explicitly add `spring-boot-starter-validation`. Without it, `@Valid` and all Jakarta Validation annotations are silently ignored — no error, no warning.

### Pitfall 5: `@ConfigurationProperties` on `@Configuration`

In Spring Boot 4, combining `@Configuration` with `@ConfigurationProperties` on the same class causes property binding to be skipped. Use `@Component` or `@ConfigurationProperties` alone, or register via `@EnableConfigurationProperties`.

---

## 7. Summary: The Domain Design Decision Matrix

| Decision | Choice | Why |
|---|---|---|
| **Entity vs. DTO** | Never the same class | Different lifecycles, different serialization rules |
| **DTO type** | Java records | Immutable, Jackson 3-friendly, AOT-compatible |
| **Validation location** | Request DTOs | Boundary enforcement, not domain logic |
| **Mapping strategy** | MapStruct for simple, manual for complex | Compile-time safety, no reflection |
| **Aggregate design** | One aggregate root per transaction | Enforces invariants, avoids cross-aggregate coupling |
| **Domain events** | `AbstractAggregateRoot.registerEvent()` | Automatic publication on repository save |
| **Package structure** | Feature-oriented (`order/`, `customer/`) | Bounded contexts, module boundaries |
| **Null-safety** | JSpecify `@NullMarked` / `@Nullable` | Spring Boot 4 baseline, eliminates NPEs |
| **Eager vs. lazy** | Lazy by default | Performance; fetch explicitly when needed |
| **Main class location** | Root package | Component scanning correctness |

The domain layer is where your business rules live. The web layer is where your API contract lives. The mapping between them is the **seam** where most production bugs hide. Spring Boot 4's stricter null-safety, Jackson 3 serialization, and AOT compilation make this seam more visible — and more important to get right — than ever before.


[[Java]]
[[0 - Spring Framework]]