

It tells JPA/Hibernate **how a Java `enum` should be stored in the database**.

```java
@Enumerated(EnumType.STRING)
private Role role;
```

---

## 1. Start with the Java enum

```java
public enum Role {
    USER,
    ADMIN
}
```

Then your entity:

```java
@Entity
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Enumerated(EnumType.STRING)
    private Role role;
}
```

The important part is:

```java
@Enumerated(EnumType.STRING)
```

It tells Hibernate:

> Store the enum as its **name/string value**.

So:

```text
Java                         Database

Role.USER       ──────────►  "USER"
Role.ADMIN      ──────────►  "ADMIN"
```

---

# 2. `EnumType` has two important choices

### `EnumType.STRING`

```java
@Enumerated(EnumType.STRING)
private Role role;
```

Database:

```text
USER
ADMIN
```

### `EnumType.ORDINAL`

```java
@Enumerated(EnumType.ORDINAL)
private Role role;
```

Database:

```text
USER  → 0
ADMIN → 1
```

because Java enums have ordinal positions:

```java
public enum Role {
    USER,   // 0
    ADMIN   // 1
}
```

---

# 3. Why `STRING` is usually the pattern you want

Consider:

```java
public enum Role {
    USER,
    ADMIN
}
```

with:

```java
@Enumerated(EnumType.ORDINAL)
```

Your database contains:

```text
0
1
```

Later you change the enum:

```java
public enum Role {
    GUEST,
    USER,
    ADMIN
}
```

Now:

```text
GUEST → 0
USER  → 1
ADMIN → 2
```

Your existing database row:

```text
1
```

used to mean:

```text
ADMIN
```

but now means:

```text
USER
```

That's a **data corruption/migration problem**.

With:

```java
@Enumerated(EnumType.STRING)
```

the database contains:

```text
USER
ADMIN
```

Adding another enum value doesn't change the meaning of existing values.

---

# 4. Recommended pattern

For normal business enums:

```java
@Enumerated(EnumType.STRING)
@Column(nullable = false)
private Role role;
```

Example:

```java
public enum Role {
    USER,
    ADMIN
}
```

Entity:

```java
@Entity
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;
}
```

Database conceptually:

```text
users
────────────────────────────
id          UUID
email       VARCHAR
role        VARCHAR
```

with:

```text
550e... | alice@example.com | USER
```

---

## 5. One important professional detail

Don't confuse:

```java
@Enumerated(EnumType.STRING)
```

with:

```java
@Column(length = ...)
```

`@Enumerated` controls **enum representation**.

`@Column` controls **column mapping/constraints**.

So they can work together:

```java
@Enumerated(EnumType.STRING)
@Column(nullable = false)
private Status status;
```

Mental model:

```text
Enum
 │
 │ @Enumerated
 ▼
How is the enum represented?
 │
 ├── STRING  → "ACTIVE"
 └── ORDINAL → 0
```

For your Spring/JPA projects, **use `EnumType.STRING` by default**. `ORDINAL` is generally something you'd choose only with a deliberate reason and careful schema control.



[[Java]]
[[0 - Spring Framework]]