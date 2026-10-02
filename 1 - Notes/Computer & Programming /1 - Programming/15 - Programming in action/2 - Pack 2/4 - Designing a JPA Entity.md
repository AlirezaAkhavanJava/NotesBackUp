

## 1. The Mental Model: An Entity Is a "Living Contract"

**Analogy**: Think of a JPA entity as a **passport**. It has:

- **A unique identifier** (the passport number — your `@Id`)
- **Fixed biographical fields** (name, date of birth — your `@Column` fields)
- **A status** (valid, expired — your `@Enumerated` fields)
- **Rules about what can change** (you can renew it, but you can't change your date of birth — your business methods)
- **A relationship to other documents** (visas, stamps — your `@OneToMany`, `@ManyToOne` associations)

But a passport is **not** a diary. You don't write arbitrary notes in it. Similarly, an entity is **not** a DTO, and it is **not** a free-form data bag. It is a **contract** between your application and the database: every field you put in it becomes a column, every relationship becomes a foreign key or join table, and every public method becomes a way for the application to interact with that persistent state.

**The critical question**: *"Does this field represent persistent state that has identity and a lifecycle?"* If yes, it belongs in the entity. If it's computed, derived, or only relevant for a single request/response, it does **not** belong in the entity. This is the single most important distinction, and violating it is the root cause of most entity design problems in Spring Boot.

The search results reinforce this: "Use an `@Entity` only for persistent state with identity and lifecycle. Use records for DTOs, commands, and read models. Use `@Embeddable` for values stored inside an entity table."

---

## 2. The Anatomy of an Entity: Every Component Defined

### 2.1 Class-Level Annotations

```java
@Entity
@Table(name = "tasks", indexes = {
    @Index(name = "idx_tasks_status", columnList = "status"),
    @Index(name = "idx_tasks_due_date", columnList = "due_date")
})
@EntityListeners(AuditingEntityListener.class)
public class Task {
    // ...
}
```

| Annotation | Purpose | Why It Matters |
|---|---|---|
| `@Entity` | Declares the class as a JPA entity. Mandatory. | Without it, JPA ignores the class entirely. |
| `@Table(name = "tasks")` | Maps the entity to a specific table name. Optional, but strongly recommended. | Without it, Hibernate derives the table name from the class name (e.g., `Task` → `task`). Explicit naming avoids surprises. The `indexes` attribute lets you define database indexes declaratively. |
| `@EntityListeners(AuditingEntityListener.class)` | Enables Spring Data JPA auditing for `@CreatedDate` and `@LastModifiedDate`. | Without it, the auditing annotations do nothing. You also need `@EnableJpaAuditing` on a configuration class. |
| `@Index` | Defines a database index on one or more columns. | Critical for query performance. Without an index on `status`, every `findByStatus` query does a full table scan. |

**Edge case — table naming strategy**: Spring Boot 4's default naming strategy converts `Task` to `task` (lowercase, singular). If you want `tasks` (plural), you must either use `@Table(name = "tasks")` or configure `spring.jpa.hibernate.naming.physical-strategy`. Always be explicit with `@Table` to avoid ambiguity across environments.

### 2.2 The Identifier: `@Id` and `@GeneratedValue`

```java
@Id
@GeneratedValue(strategy = GenerationType.IDENTITY)
private Long id;
```

| Element | Options | When to Use |
|---|---|---|
| `@Id` | Mandatory. | Marks the primary key field. |
| `@GeneratedValue(strategy = ...)` | `IDENTITY`, `SEQUENCE`, `UUID`, `AUTO`, `TABLE` | `IDENTITY` for auto-increment `Long` (simplest, but prevents JDBC batch inserts). `SEQUENCE` for databases with sequences (PostgreSQL, Oracle) — allows batching. `UUID` for distributed systems where IDs must be globally unique without coordination. |
| Field type | `Long`, `Integer`, `UUID`, `String` | Use the wrapper type (`Long`, not `long`) so that `null` clearly indicates an unsaved entity. An unpersisted entity has `id == null`; a persisted one does not. |

**Why `GenerationType.IDENTITY` is the default choice for most applications**: It's the simplest to understand and works with MySQL, PostgreSQL, and H2. The trade-off is that Hibernate cannot batch inserts because it must execute an `INSERT` to obtain the generated ID. For high-throughput batch inserts, prefer `SEQUENCE` with a `@SequenceGenerator`. For distributed systems (microservices, event sourcing), prefer `UUID`.

**Critical decision — surrogate key vs. business key**: A **surrogate key** is an artificial identifier (auto-generated ID) with no business meaning. A **business key** (or **natural key**) is a field (or combination of fields) that has meaning to the user and uniquely identifies the entity in the real world (e.g., `email` for a `User`, `slug` for a `Market`). The search results note that "the business key is an entity identifier which, unlike the auto-generated primary key (surrogate key), has some meaning to the user (natural key). You should then override the `equals` method to compare two objects using the business key, and not the auto-generated primary key."

**Recommendation**: Use a surrogate key as the `@Id` (for database efficiency and simplicity) AND a business key field (for domain semantics and `equals`/`hashCode`). For example:

```java
@Id
@GeneratedValue(strategy = GenerationType.IDENTITY)
private Long id;

@Column(nullable = false, unique = true, length = 120)
private String slug; // business key — used in equals/hashCode
```

This is the pattern used in production Spring Boot applications. The surrogate key is the database's concern; the business key is the domain's concern.

### 2.3 Column Fields: The "Biographical" Data

```java
@Column(nullable = false, length = 200)
private String title;

@Column(columnDefinition = "TEXT")
private String description;

@Enumerated(EnumType.STRING)
@Column(nullable = false, length = 20)
private TaskStatus status = TaskStatus.TODO;

@Column(name = "due_date")
private LocalDate dueDate;
```

| Annotation | Purpose | Why It Matters |
|---|---|---|
| `@Column(nullable = false)` | Declares a `NOT NULL` constraint. | The database enforces the constraint. Without it, Hibernate generates a nullable column, and `null` values can silently enter your domain. Always declare `nullable` explicitly. |
| `@Column(length = 200)` | Sets the column length for `VARCHAR` columns. | Without it, Hibernate uses `VARCHAR(255)`. If your data exceeds 255 characters, you get a runtime `DataIntegrityViolationException`. |
| `@Column(precision = 12, scale = 2)` | Sets precision and scale for `BigDecimal` fields. | Without it, Hibernate uses the database's default precision, which may truncate monetary values. |
| `@Column(name = "due_date")` | Maps a Java field name to a differently named database column. | Use when your naming strategy doesn't produce the desired column name. |
| `@Enumerated(EnumType.STRING)` | Stores the enum as a string (`"TODO"`, `"DONE"`). | **Always use `EnumType.STRING`.** The default is `EnumType.ORDINAL`, which stores the enum's position (0, 1, 2). If you reorder the enum constants, existing data is silently corrupted. |
| `@Lob` | Maps to `CLOB`/`BLOB` for large text/binary data. | Use for `TEXT` columns or binary blobs. Note: `@Lob` with PostgreSQL can cause issues with `OID` types; prefer `columnDefinition = "TEXT"` instead. |

**Why explicit `@Column` is non-negotiable**: The search results state: "Always declare `@Column` explicitly with nullable and length, because the schema is generated from the entity." If you rely on defaults, you're trusting Hibernate's assumptions. When you use `spring.jpa.hibernate.ddl-auto=update` (common in development), the schema reflects your entity exactly. If your entity says `VARCHAR(255)` by default but your data needs 500 characters, you'll discover this in production. Be explicit.

**Edge case — `LocalDate` vs. `Instant`**: Use `LocalDate` for date-only fields (due dates, birthdays). Use `Instant` for timestamps (audit fields, event times). Use `ZonedDateTime` only if you genuinely need timezone-aware data. Spring Boot 4 with Jackson 3 serializes `Instant` as ISO-8601 with `Z` suffix by default.

### 2.4 Auditing Fields

```java
@CreatedDate
@Column(nullable = false, updatable = false)
private Instant createdAt;

@LastModifiedDate
@Column(nullable = false)
private Instant updatedAt;
```

| Annotation | Purpose | Why It Matters |
|---|---|---|
| `@CreatedDate` | Automatically populated on first persist. | Spring Data JPA's `AuditingEntityListener` sets it. The `updatable = false` ensures it's never modified. |
| `@LastModifiedDate` | Automatically updated on every save. | The listener updates it on each flush. |

**Prerequisite**: You must enable auditing on a `@Configuration` class:

```java
@Configuration
@EnableJpaAuditing
public class JpaConfig {}
```

The search results confirm: "We provide `@CreatedDate` and `@LastModifiedDate` to capture when the change happened. The annotations can be applied selectively, depending on which information you want to capture."

**Edge case — auditing with embedded objects**: Auditing metadata doesn't have to live at the root entity level. It can be added to an `@Embeddable` object, as shown in the Spring Data documentation.

### 2.5 Relationship Fields

```java
@OneToMany(mappedBy = "task", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
private List<TaskComment> comments = new ArrayList<>();

@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "project_id")
private Project project;
```

| Annotation | Purpose | Critical Rules |
|---|---|---|
| `@OneToMany(mappedBy = "...")` | The "many" side's collection. `mappedBy` points to the field on the owning side. | **Always use `FetchType.LAZY`.** The default for `@OneToMany` is `LAZY`, but explicitly declaring it makes the intent clear. `EAGER` on collections causes the N+1 problem. |
| `@ManyToOne(fetch = FetchType.LAZY)` | The "one" side's reference. | **Always use `FetchType.LAZY`.** The default for `@ManyToOne` is `EAGER`, which is almost never what you want. |
| `@JoinColumn(name = "project_id")` | Defines the foreign key column name. | Use on the owning side (the `@ManyToOne` side, or the `@OneToMany` side if unidirectional). |
| `cascade = CascadeType.ALL` | Persist, merge, remove, refresh, detach operations cascade to children. | Use when the child cannot exist without the parent (e.g., `Order` → `OrderLine`). |
| `orphanRemoval = true` | Removes the child from the database when it's removed from the collection. | Use together with `cascade = ALL` for true composition. |

**The N+1 problem and why `EAGER` is a trap**: When you load 100 `Task` entities and each has an `EAGER` `Project` association, Hibernate executes 1 query for the tasks + 100 queries for the projects = 101 queries. With `LAZY`, it's 1 query until you actually access the project. The search results state: "Default to lazy loading; use `JOIN FETCH` in queries when needed. Avoid `EAGER` on collections; use DTO projections for read paths."

**The bidirectional helper method**: The search results show a pattern for managing both sides of a bidirectional relationship:

```java
public void addFlightInstance(FlightInstance newFlightInstance) {
    newFlightInstance.setFlight(this);
    this.flightInstances.add(newFlightInstance);
}
```

This ensures that both sides of the relationship are consistent before persisting. Without it, you must remember to set the parent reference on the child manually. Always add such a helper method for bidirectional relationships.

### 2.6 Value Objects with `@Embeddable` and `@Embedded`

A value object is an immutable object with no identity, representing a descriptive aspect of the domain. Use `@Embeddable` when the value is stored **inside the same table** as the entity.

```java
@Embeddable
public class Money {
    @Column(name = "amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal amount;

    @Column(name = "currency", nullable = false, length = 3)
    private String currencyCode;

    protected Money() {} // for JPA

    public Money(BigDecimal amount, Currency currency) {
        this.amount = amount;
        this.currencyCode = currency.getCurrencyCode();
    }
    // getters, equals, hashCode
}
```

```java
@Entity
public class Order {
    @Embedded
    private Money totalAmount;
}
```

The search results note: "Use `@Embedded(onEmpty = USE_NULL)` to inline a value object's columns into the parent table, keeping a rich object model while the schema stays flat. Value objects embedded this way have no independent lifecycle and need no separate repository."

**Edge case — primitive fields in `@Embeddable`**: If all columns of an embeddable are `null`, the embeddable object itself is `null` inside the entity. This causes issues with primitive types in embeddable classes, as noted in the search results: "if in all columns of the embeddable (are null), then the embeddable object itself is also null inside the entity. This has ... further causes some issues with primitive types in embeddable classes." Always use wrapper types in embeddables, or ensure at least one column is non-null.

### 2.7 Constructors

```java
protected Task() {} // Required by JPA

public Task(String title, TaskPriority priority) {
    this.title = title;
    this.priority = priority;
    this.status = TaskStatus.TODO;
}
```

JPA **requires** a no-arg constructor (it can be `protected` or `private`; `protected` is conventional). You should **never** use the no-arg constructor in your application code. The public constructor enforces invariants at creation time. If you need to create a task from a DTO, the mapper calls the public constructor, not the no-arg one.

### 2.8 Business Methods (Rich Domain Model)

```java
public void markAsDone() {
    if (this.status == TaskStatus.DONE) {
        throw new IllegalStateException("Task is already done");
    }
    this.status = TaskStatus.DONE;
}

public void changePriority(TaskPriority newPriority) {
    if (newPriority == null) {
        throw new IllegalArgumentException("Priority cannot be null");
    }
    this.priority = newPriority;
}
```

**Why business methods matter**: An entity should not be anemic (a data bag with getters and setters). Business rules that govern state transitions belong in the entity, not in the service. The service orchestrates; the entity enforces. This is a core principle of domain-driven design, and it aligns with Spring Boot 4's AOT-first philosophy: business logic in the entity is plain Java, fully analyzable at build time.

**Edge case — Lombok's `@Data` on entities**: The search results are explicit: "Lombok generates a wrong `equals` and `hashCode` for use with JPA. You would need to create one just based on the id of the object and none of the other fields." `@Data` generates `equals()`/`hashCode()` based on **all** fields, including mutable ones. For JPA entities, this is wrong because: (1) unsaved entities have `null` IDs, so two unsaved entities with the same data are not equal; (2) mutable fields change, causing the entity's hash code to change while it's in a `Set`. **Never use `@Data` on a JPA entity.** Use `@Getter` and `@Setter` selectively, and write your own `equals()`/`hashCode()`.

### 2.9 `equals()` and `hashCode()`

```java
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof Task task)) return false;
    return slug != null && slug.equals(task.slug);
}

@Override
public int hashCode() {
    return getClass().hashCode();
}
```

**The rules**:
1. **Never use the generated ID for equality** if it can be `null` (unsaved entity). Use the business key instead.
2. **If no business key exists**, use `Objects.equals(id, other.id)` but guard against `null`.
3. **`hashCode()` must return a constant** for the entity's lifetime. Using `id` in `hashCode()` is dangerous because the ID changes from `null` to a value on persist. The search results show a common pattern: `public int hashCode() { return getClass().hashCode(); }` — a constant hash code per class.

**Why this matters**: If an entity is in a `HashSet` and its `hashCode()` changes (because the ID was assigned after persist), the set can no longer find the entity. Using a constant `hashCode()` based on the class ensures stability. Using the business key for `equals()` ensures correctness across the transient-to-persistent transition.

---

## 3. The Decision Framework: What Goes In an Entity?

Use this decision tree for every field you're considering:

| Question | If Yes | If No |
|---|---|---|
| Does this field represent persistent state with a lifecycle? | It belongs in the entity as a `@Column`. | It belongs in a DTO, a service, or is computed. |
| Is this field a collection of child objects that cannot exist without the parent? | Use `@OneToMany` with `cascade = ALL, orphanRemoval = true`. | Consider a separate aggregate with its own repository. |
| Is this field a reference to another aggregate? | Use `@ManyToOne` with `@JoinColumn`. Never `@OneToMany` across aggregate boundaries. | — |
| Is this field a value object (Money, Address, Email)? | Use `@Embeddable` + `@Embedded`. | Use a plain `@Column`. |
| Is this field computed from other fields? | It does **not** belong in the entity. Compute it in a DTO or a service. | — |
| Is this field only relevant for a specific API response? | It does **not** belong in the entity. Put it in a DTO. | — |

**The "aggregate" boundary**: In domain-driven design, an aggregate is a cluster of entities and value objects treated as a single unit for data changes. The aggregate root is the only object that outside objects can reference. The search results show the pattern: `@OneToMany(mappedBy = "market", cascade = CascadeType.ALL, orphanRemoval = true)` for children within the same aggregate. Cross-aggregate references should be by ID, not by object reference.

**Example from your DoItLater project**: A `Habit` has many `HabitStatusPerDay` records. These are within the same aggregate — a `HabitStatusPerDay` cannot exist without a `Habit`. So `Habit` is the aggregate root, and `HabitStatusPerDay` is a child. Use `@OneToMany(cascade = ALL, orphanRemoval = true, fetch = LAZY)` on `Habit`. A `Task` belongs to a `Project`. `Project` is a separate aggregate. So `Task` should have a `@ManyToOne Project project` with `@JoinColumn`, not a `@OneToMany` on `Project`.

---

## 4. Edge Cases and Pitfalls

### Pitfall 1: Using `EnumType.ORDINAL`

The default for `@Enumerated` is `ORDINAL`. If you add or reorder enum constants, existing database rows silently point to the wrong constants. **Always use `EnumType.STRING`.**

### Pitfall 2: Eager Loading on `@ManyToOne`

The default fetch type for `@ManyToOne` is `EAGER`. This means every time you load a `Task`, Hibernate also loads its `Project`. In a list of 100 tasks, that's 101 queries. **Always declare `fetch = FetchType.LAZY` on `@ManyToOne`.**

### Pitfall 3: `@Data` on Entities

As discussed, `@Data` generates incorrect `equals`/`hashCode`. Use `@Getter` and `@Setter` selectively, or write your own `equals`/`hashCode`.

### Pitfall 4: Missing `@Column(nullable = false)`

Without it, the column is nullable. `null` values can silently enter your domain, causing `NullPointerException` in business logic. Always declare `nullable` explicitly.

### Pitfall 5: `@Configuration` + `@ConfigurationProperties` on the Same Class

This is not an entity pitfall, but it's worth noting: in Spring Boot 4, combining `@Configuration` with `@ConfigurationProperties` causes property binding to be skipped. Use `@Component` or `@ConfigurationProperties` alone.

### Pitfall 6: `@Lob` with PostgreSQL

`@Lob` with PostgreSQL can map to `OID` instead of `TEXT`, causing issues with large text data. Prefer `@Column(columnDefinition = "TEXT")` for PostgreSQL.

### Pitfall 7: Bidirectional Relationship Without Helper Method

If you have `@OneToMany` and `@ManyToOne`, and you set only one side, the in-memory object graph is inconsistent until you reload from the database. **Always add a helper method** (`addChild`) that sets both sides.

---

## 5. Summary: The Entity Design Checklist

| Component | Decision | Recommendation |
|---|---|---|
| **Class annotation** | `@Entity` + `@Table` + `@EntityListeners` | Always explicit naming; always enable auditing. |
| **ID** | Surrogate key (`Long`/`UUID`) + business key | Use `Long` with `IDENTITY` for simplicity; `UUID` for distributed systems. |
| **Columns** | `@Column(nullable, length, precision)` | Always declare explicitly. |
| **Enums** | `@Enumerated(EnumType.STRING)` | Never use `ORDINAL`. |
| **Auditing** | `@CreatedDate`, `@LastModifiedDate` | Requires `@EnableJpaAuditing`. |
| **Relationships** | `@OneToMany(mappedBy, cascade, orphanRemoval, fetch = LAZY)`, `@ManyToOne(fetch = LAZY)` | Always lazy; helper methods for bidirectional. |
| **Value objects** | `@Embeddable` + `@Embedded` | Use for Money, Address, etc. |
| **Constructor** | `protected` no-arg + public invariant-enforcing constructor | Never use no-arg in application code. |
| **Business methods** | Methods that enforce state transitions | Rich domain model, not anemic. |
| **`equals`/`hashCode`** | Business key for `equals`, constant for `hashCode` | Never use generated ID if it can be `null`. |
| **Lombok** | `@Getter` and selective `@Setter` | Never `@Data`. |

The entity is the **foundation** of your persistence layer. Every decision you make here propagates to the repository, service, DTO, and controller. Get the entity right, and the rest of the application falls into place. Get it wrong, and you'll fight the framework at every layer.


[[Spring Framework]]