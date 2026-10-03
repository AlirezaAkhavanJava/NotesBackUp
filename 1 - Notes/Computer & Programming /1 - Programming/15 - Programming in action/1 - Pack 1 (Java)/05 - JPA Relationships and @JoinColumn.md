


In JPA, relationships describe how entities are connected in the database.

The main relationship annotations are:

- `@OneToOne`
    
- `@OneToMany`
    
- `@ManyToOne`
    
- `@ManyToMany`
    

`@JoinColumn` defines the **foreign-key column** used to connect two entities.

---

## 1. `@OneToOne`

Represents a relationship where one entity is associated with one other entity.

```java
@OneToOne
@JoinColumn(name = "profile_id")
private Profile profile;
```

### Common arguments

```java
@OneToOne(
    cascade = CascadeType.ALL,
    fetch = FetchType.LAZY,
    optional = false,
    mappedBy = "user"
)
```

|Argument|Type|Meaning|
|---|---|---|
|`cascade`|`CascadeType[]`|Operations performed on the parent are propagated to the related entity|
|`fetch`|`FetchType`|Determines when the related entity is loaded|
|`optional`|`boolean`|Whether the relationship may be `null`|
|`mappedBy`|`String`|Specifies the field that owns the relationship on the other entity|
|`orphanRemoval`|`boolean`|Removes the related entity when it is disconnected from the parent|

---

# 2. `@ManyToOne`

Represents many entities referring to one entity.

For example:

```text
Many Receipts
       │
       ▼
    One User
```

```java
@ManyToOne
@JoinColumn(name = "user_id")
private User user;
```

This normally creates:

```sql
receipts
---------
id
user_id  → users.id
```

### Common arguments

```java
@ManyToOne(
    cascade = CascadeType.PERSIST,
    fetch = FetchType.LAZY,
    optional = false
)
```

|Argument|Type|Meaning|
|---|---|---|
|`cascade`|`CascadeType[]`|Propagates entity operations|
|`fetch`|`FetchType`|Loading strategy|
|`optional`|`boolean`|Whether the relationship can be `null`|
|`targetEntity`|`Class`|Explicitly specifies the target entity|

---

# 3. `@OneToMany`

Represents one entity having multiple related entities.

```text
One User
   │
   ├── Receipt
   ├── Receipt
   └── Receipt
```

```java
@OneToMany(mappedBy = "user")
private List<Receipt> receipts;
```

### Common arguments

```java
@OneToMany(
    mappedBy = "user",
    cascade = CascadeType.ALL,
    fetch = FetchType.LAZY,
    orphanRemoval = true
)
```

|Argument|Type|Meaning|
|---|---|---|
|`mappedBy`|`String`|Field that owns the relationship|
|`cascade`|`CascadeType[]`|Propagates operations|
|`fetch`|`FetchType`|Loading strategy|
|`orphanRemoval`|`boolean`|Deletes orphaned child entities|
|`targetEntity`|`Class`|Explicit target entity|

### `mappedBy`

Suppose:

```java
@Entity
class Receipt {

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;
}
```

Then:

```java
@Entity
class User {

    @OneToMany(mappedBy = "user")
    private List<Receipt> receipts;
}
```

`mappedBy = "user"` means:

> The `user` field in `Receipt` owns the relationship.

Therefore, `User.receipts` does **not** create another foreign-key column.

---

# 4. `@ManyToMany`

Represents many entities related to many other entities.

For example:

```text
Users             Roles

User ───────────── Admin
User ───────────── Customer
User ───────────── Manager
```

A many-to-many relationship normally requires a **join table**.

```java
@ManyToMany
@JoinTable(
    name = "user_roles",
    joinColumns = @JoinColumn(name = "user_id"),
    inverseJoinColumns = @JoinColumn(name = "role_id")
)
private Set<Role> roles;
```

This produces conceptually:

```text
users
-----
id

roles
-----
id

user_roles
----------
user_id
role_id
```

---

# 5. `@JoinColumn`

`@JoinColumn` specifies the database column used to join entities.

Basic example:

```java
@JoinColumn(name = "user_id")
```

### Arguments

```java
@JoinColumn(
    name = "user_id",
    referencedColumnName = "id",
    nullable = false,
    unique = false,
    insertable = true,
    updatable = true
)
```

|Argument|Type|Meaning|
|---|---|---|
|`name`|`String`|Name of the foreign-key column|
|`referencedColumnName`|`String`|Column in the referenced table|
|`nullable`|`boolean`|Whether the FK column can contain `NULL`|
|`unique`|`boolean`|Whether the FK column must be unique|
|`insertable`|`boolean`|Whether JPA includes the column in `INSERT`|
|`updatable`|`boolean`|Whether JPA includes the column in `UPDATE`|
|`columnDefinition`|`String`|Explicit SQL column definition|
|`table`|`String`|Table containing the column|
|`foreignKey`|`ForeignKey`|Controls foreign-key generation|

---

# 6. `name`

The most commonly used argument.

```java
@JoinColumn(name = "user_id")
```

This means the entity's table contains:

```sql
user_id
```

For example:

```java
@ManyToOne
@JoinColumn(name = "user_id")
private User user;
```

Database:

```text
receipts
----------------
id
user_id
store_name
price
```

---

# 7. `referencedColumnName`

Specifies which column in the target table is referenced.

```java
@JoinColumn(
    name = "user_id",
    referencedColumnName = "id"
)
```

Conceptually:

```text
receipts.user_id
       │
       ▼
users.id
```

Usually you don't need to specify it because JPA defaults to the referenced entity's primary key.

Therefore this:

```java
@JoinColumn(name = "user_id")
```

normally means:

```text
user_id → User.id
```

---

# 8. `nullable`

Controls whether the FK column can contain `NULL`.

```java
@JoinColumn(
    name = "user_id",
    nullable = false
)
```

Conceptually:

```sql
user_id INTEGER NOT NULL
```

This means every receipt **must have a user**.

With:

```java
nullable = true
```

the relationship can be absent:

```text
Receipt
   │
   └── user = null
```

---

# 9. `unique`

Controls whether the column must contain unique values.

```java
@JoinColumn(
    name = "profile_id",
    unique = true
)
```

This is useful for a `@OneToOne` relationship.

For example:

```text
user_id → profile_id

1 → 10
2 → 20
3 → 30
```

No two users can reference the same profile.

---

# 10. `insertable`

Controls whether JPA includes the column when inserting the entity.

```java
@JoinColumn(
    name = "user_id",
    insertable = false
)
```

JPA will not include `user_id` in its generated `INSERT`.

This is useful in special cases where **two entity fields map to the same database column**.

Normally:

```java
insertable = true
```

is what you want.

---

# 11. `updatable`

Controls whether JPA includes the column when updating the entity.

```java
@JoinColumn(
    name = "user_id",
    updatable = false
)
```

The relationship can be inserted but cannot subsequently be changed through that mapping.

Again, normally:

```java
updatable = true
```

---

# 12. `cascade`

Cascade controls whether an operation on one entity propagates to related entities.

```java
@OneToMany(
    cascade = CascadeType.ALL
)
```

Available cascade types:

```java
CascadeType.PERSIST
CascadeType.MERGE
CascadeType.REMOVE
CascadeType.REFRESH
CascadeType.DETACH
CascadeType.ALL
```

### `PERSIST`

```text
save User
   ↓
persist related entity
```

### `MERGE`

Propagates `merge()`.

### `REMOVE`

```text
delete User
   ↓
delete related entities
```

Be careful with `REMOVE`, especially in `@ManyToMany`.

### `ALL`

Equivalent to:

```java
cascade = {
    CascadeType.PERSIST,
    CascadeType.MERGE,
    CascadeType.REMOVE,
    CascadeType.REFRESH,
    CascadeType.DETACH
}
```

---

# 13. `fetch`

Controls when related entities are loaded.

```java
fetch = FetchType.LAZY
```

or:

```java
fetch = FetchType.EAGER
```

### LAZY

Load the relationship only when needed.

```text
load User
   ↓
User loaded

access user.receipts
   ↓
Receipts loaded
```

### EAGER

Load the relationship immediately.

```text
load User
   ↓
User + related data
```

For collections, `LAZY` is generally the safer default because eager loading can cause unnecessary queries and large object graphs.

---

# 14. `orphanRemoval`

Used mainly with parent-child relationships.

```java
@OneToMany(
    mappedBy = "user",
    orphanRemoval = true
)
private List<Receipt> receipts;
```

If a receipt is removed from the user's collection:

```java
user.getReceipts().remove(receipt);
```

JPA can delete that receipt from the database.

Conceptually:

```text
User
 │
 ├── Receipt A
 ├── Receipt B
 └── Receipt C

remove Receipt B
       ↓
Receipt B becomes orphan
       ↓
DELETE Receipt B
```

---

# 15. `mappedBy`

`mappedBy` identifies the **owning field** on the other entity.

Example:

```java
// Receipt
@ManyToOne
@JoinColumn(name = "user_id")
private User user;
```

Then:

```java
// User
@OneToMany(mappedBy = "user")
private List<Receipt> receipts;
```

Notice:

```java
mappedBy = "user"
```

references the **Java field name**, not the database column.

Wrong:

```java
mappedBy = "user_id"
```

Correct:

```java
mappedBy = "user"
```

---

# 16. Owning Side vs Inverse Side

This is one of the most important concepts in JPA relationships.

Consider:

```java
class Receipt {

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;
}
```

`Receipt` is the **owning side**.

Why?

Because it contains the foreign key:

```text
receipts.user_id
        │
        ▼
     users.id
```

The `User` side is the inverse side:

```java
@OneToMany(mappedBy = "user")
private List<Receipt> receipts;
```

So:

```text
User
 │
 │  inverse side
 ▼
receipts

Receipt
 │
 │  owning side
 ▼
user_id
```

---

# 17. Typical User → Receipt Model

For your `Receipta` application, a natural relationship would be:

```text
User
 │
 └── 1:N ──> Receipt
```

### `User`

```java
@OneToMany(
    mappedBy = "user",
    cascade = CascadeType.ALL,
    orphanRemoval = true
)
private List<Receipt> receipts;
```

### `Receipt`

```java
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(
    name = "user_id",
    nullable = false
)
private User user;
```

Database:

```text
users
----------------
id PK
email
password
created_at


receipts
----------------
id PK
user_id FK → users.id
store_name
purchase_date
price
```

The key idea is:

> **Relationship annotations describe the object relationship; `@JoinColumn` describes the database foreign-key column that implements that relationship.**



[[Java]]