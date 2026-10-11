

---
## 1. Mental model: two layers of settings

Every relation has two layers of configuration:

- **Behavior layer** (on `@ManyToOne`, `@OneToMany`, ...): _how Java should treat the link._ Load it lazily? Cascade operations? Can it be null?
- **Physical layer** (on `@JoinColumn`, `@JoinTable`): _how the link looks in the database._ Which column? Which name? Which constraint?

The relation annotation is the **steering wheel** (behavior). `@JoinColumn`/`@JoinTable` is the **engine** (physical schema).

---
## 2. Parameters of the relation annotations

> `mappedBy` points to the field itself in the other entity.

|Parameter|`@ManyToOne`|`@OneToOne`|`@OneToMany`|`@ManyToMany`|Default|
|---|---|---|---|---|---|
|`fetch`|✅|✅|✅|✅|EAGER for to-one, LAZY for to-many|
|`cascade`|✅|✅|✅|✅|none|
|`optional`|✅|✅|❌|❌|`true`|
|`mappedBy`|❌|✅|✅|✅|none (means "I own the FK")|
|`orphanRemoval`|❌|✅|✅|❌|`false`|
|`targetEntity`|✅|✅|✅|✅|inferred from the field type|

`@ManyToOne` has no `mappedBy` because it is always the owning side. It always holds the FK.

### 2.1 `fetch`

```java
@ManyToOne(fetch = FetchType.LAZY)
```

- `LAZY`: Hibernate puts a **proxy** (an empty stand-in subclass) in the field. The SELECT runs on first real access.
- `EAGER`: the data is loaded together with the owner, always.

**Why it works this way:** `EAGER` is a _contract_ (JPA must load it), while `LAZY` is only a _hint_ (the provider may ignore it, though Hibernate honors it for collections and for to-one relations on the owning side). Eager is global, so you can't say "eager only for this query". Lazy plus `JOIN FETCH`/`@EntityGraph` is flexible per query, which is why you default to `LAZY` and fetch on demand.

### 2.2 `cascade`

```java
@OneToMany(mappedBy = "author", cascade = {CascadeType.PERSIST, CascadeType.MERGE})
```

An array: you can pick several types instead of `ALL`. Values: `PERSIST`, `MERGE`, `REMOVE`, `REFRESH`, `DETACH`, `ALL`.

A common safe choice for a parent-owned collection is `{PERSIST, MERGE}`, which gives you convenient saving without cascading deletion. Add `REMOVE` or `orphanRemoval` only when the child truly has no life of its own.

### 2.3 `optional`

```java
@ManyToOne(optional = false)
```

Declares "this relation must never be null."

**`optional` vs `@JoinColumn(nullable = ...)`** is a classic confusion:

||`optional = false`|`nullable = false`|
|---|---|---|
|Layer|JPA/Java|Database column|
|Effect|Hibernate throws an exception **before** sending SQL if the field is null|Adds `NOT NULL` to the generated DDL; violation caught by the DB|
|Bonus|Lets Hibernate use an **INNER JOIN** instead of LEFT JOIN when fetching|None for fetching|

Use **both** together. They protect different layers.

### 2.4 `mappedBy`

```java
@OneToMany(mappedBy = "author")   // "author" = field name in Book, NOT a column name
```

Its value is the **Java field name** in the owning entity. A typo is caught at startup (`mappedBy reference an unknown target entity property`).


> `mappedBy` is used to say that this side of the relationship is mapped by a field in the other entity, which is the side that actually owns the relationship and usually contains the foreign key. It points to the Java field, not directly to the foreign key column.



### 2.5 `orphanRemoval`

Covered conceptually before. Two extra details:

1. It implies a delete on **removal from the collection**, and also on parent delete.
2. It makes Hibernate treat the collection as **owned**, which is why replacing it with `setBooks(newList)` throws an exception.

### 2.6 `targetEntity`

```java
@OneToMany(targetEntity = Book.class, mappedBy = "author")
private List books;   // raw type
```

Only needed when the field uses a raw or non-generic type. With `List<Book>` Hibernate infers it, so you almost never write this.

---
## 3. `@JoinColumn`: the FK column

`@JoinColumn` is used to tell JPA which column in the table is used to connect this entity to another entity. In a relationship, it usually represents the foreign key column. For example, `@JoinColumn(name = "customer_id")` means the `customer_id` column in this table is the foreign key that connects to the other entity.

```java
@ManyToOne(fetch = FetchType.LAZY, optional = false)
@JoinColumn(
    name = "author_id",
    referencedColumnName = "id",
    nullable = false,
    unique = false,
    insertable = true,
    updatable = true,
    foreignKey = @ForeignKey(name = "fk_book_author")
)
private Author author;
```

|Parameter|Meaning|Default|
|---|---|---|
|`name`|FK column name in **this** table|`<fieldName>_<PKcolumn>` → `author_id`|
|`referencedColumnName`|Column in the **other** table it points to|the other entity's PK|
|`nullable`|`NOT NULL` in DDL|`true`|
|`unique`|`UNIQUE` constraint (this turns a many-to-one into a de facto one-to-one)|`false`|
|`insertable` / `updatable`|Whether this mapping may write the column on INSERT/UPDATE|`true` / `true`|
|`foreignKey`|Names the FK constraint, or disables it|auto-generated ugly name|
|`columnDefinition`|Raw DDL type fragment (non-portable)|none|
|`table`|Put the column in a secondary table|primary table|

### Parameters worth a closer look

**`referencedColumnName`:** point to a non-PK column (it should be unique):

```java
@ManyToOne
@JoinColumn(name = "author_isni", referencedColumnName = "isni")   // FK to authors.isni
private Author author;
```

**`insertable = false, updatable = false`:** this makes the mapping **read-only**. The classic use is exposing the raw FK value next to the relation, without two fields fighting to write the same column:

```java
@Column(name = "author_id", insertable = false, updatable = false)
private Long authorId;          // read-only view of the FK

@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "author_id")
private Author author;          // the writer
```

Without the read-only flags, Hibernate fails at startup with `Repeated column in mapping`.

**`foreignKey`:** naming the constraint helps readable error messages and migrations:

```java
@JoinColumn(name = "author_id", foreignKey = @ForeignKey(name = "fk_book_author"))
// or, to skip creating the constraint entirely (legacy DBs, sharding):
@JoinColumn(name = "author_id", foreignKey = @ForeignKey(ConstraintMode.NO_CONSTRAINT))
```

**`unique = true`:** for a one-to-one by foreign key, this guarantees at the DB level that two accounts can't point to the same profile:

```java
@OneToOne
@JoinColumn(name = "profile_id", unique = true)
private Profile profile;
```

(`@OneToOne` doesn't add the unique constraint by itself in every Hibernate version, so stating it removes any doubt.)

### Composite keys: `@JoinColumns`

```java
@ManyToOne
@JoinColumns({
    @JoinColumn(name = "order_id",   referencedColumnName = "id"),
    @JoinColumn(name = "order_year", referencedColumnName = "year")
})
private Order order;
```

Use it only when the target has a composite primary key.

---
## 4. `@JoinTable`: the join table in ManyToMany

```java
@ManyToMany
@JoinTable(
    name = "student_course",
    joinColumns = @JoinColumn(name = "student_id"),
    inverseJoinColumns = @JoinColumn(name = "course_id"),
    uniqueConstraints = @UniqueConstraint(columnNames = {"student_id", "course_id"}),
    indexes = @Index(name = "idx_sc_course", columnList = "course_id"),
    foreignKey = @ForeignKey(name = "fk_sc_student"),
    inverseForeignKey = @ForeignKey(name = "fk_sc_course")
)
private Set<Course> courses = new HashSet<>();
```

|Parameter|Meaning|
|---|---|
|`name`|Join table name|
|`joinColumns`|FK column(s) pointing to the **owner** entity (the one holding this annotation)|
|`inverseJoinColumns`|FK column(s) pointing to the **other** entity|
|`uniqueConstraints`|Extra constraints (typically the pair, to prevent duplicates)|
|`indexes`|Indexes on the table (the second FK column usually needs one for fast reverse lookups)|
|`foreignKey` / `inverseForeignKey`|Constraint names for each side|
|`schema` / `catalog`|Where the table lives|

**Easy way to remember it:** `joinColumns` = "**me**", `inverseJoinColumns` = "**them**". Mixing them up makes data load backwards without any error when both ids exist, so double-check.

**Defaults if you write nothing:** table name is `students_courses` (owner table + `_` + other table), columns are `Student_id` and `courses_id`. Names that surprising are the reason to write `@JoinTable` explicitly.

---
## 5. Companion annotations with parameters

### `@OrderBy` (order by field when loading the collection)

```java
@OneToMany(mappedBy = "author")
@OrderBy("publishedYear DESC, title ASC")      // JPQL field names, not columns
private List<Book> books = new ArrayList<>();
```

### `@OrderColumn` (the list's position stored in a column)

```java
@OneToMany(mappedBy = "author")
@OrderColumn(name = "position")
private List<Book> books;
```

`@OrderBy` sorts by existing data. `@OrderColumn` **persists the index** itself. It is more expensive, because reordering rewrites many rows, so use it only when manual ordering matters (a playlist, say).

### `@MapsId`

```java
@OneToOne(fetch = FetchType.LAZY)
@MapsId                      // use the relation's id as THIS entity's id
@JoinColumn(name = "id")
private UserAccount user;
```

`@MapsId("fieldName")` is for composite embedded IDs, where it names which part of the ID the relation fills.

### Hibernate extras you will meet

```java
@OnDelete(action = OnDeleteAction.CASCADE)   // DB-level ON DELETE CASCADE, no row-by-row DELETEs
@OneToMany(mappedBy = "author")
private List<Book> books;

@BatchSize(size = 20)                        // load lazy collections for 20 owners per query (softens N+1)
@OneToMany(mappedBy = "author")
private List<Book> books;
```

`@OnDelete` pairs well with the cascade/orphanRemoval distinction from before: this one runs inside the database, so Hibernate doesn't load the children at all.

---
## 6. Gotchas

1. **`mappedBy` + `@JoinColumn` on the same field** is a mapping error. Only the owning side gets `@JoinColumn`.
2. **`optional = false` on a relation that is `LAZY`** is still fine, but if a legacy row has a null FK, you get an exception when the entity loads or flushes. Clean the data first.
3. **Both `@JoinColumn(name="author_id")` and a `@Column(name="author_id")` field without the read-only flags** gives `Repeated column in mapping`.
4. **`cascade` on the inverse side only** works for operations reaching the parent through Java, and saving a child directly never cascades "upward" to the parent. Cascade follows the direction you annotate.
5. **`columnDefinition`** locks your DDL to one database, so avoid it unless you use it deliberately.
6. **`ddl-auto` and `foreignKey` naming:** renaming a constraint later doesn't rename the old one in the DB under `update`. Name constraints from the start, and let a migration tool own changes afterwards.

---
## 7. Quick reference

|Goal|Parameter|
|---|---|
|Don't load until needed|`fetch = LAZY`|
|Save children with parent|`cascade = {PERSIST, MERGE}`|
|Delete children removed from the list|`orphanRemoval = true`|
|Forbid null relation|`optional = false` + `nullable = false`|
|Custom FK column name|`@JoinColumn(name = ...)`|
|FK to a non-PK column|`referencedColumnName`|
|Read-only FK mirror|`insertable = false, updatable = false`|
|Name or disable the constraint|`foreignKey = @ForeignKey(...)`|
|Custom join table|`@JoinTable(name, joinColumns, inverseJoinColumns)`|
|Sorted collection|`@OrderBy`|



[[Spring Framework]]