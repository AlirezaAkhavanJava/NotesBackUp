

A Java enum is a fixed set of named values, like `USER` and `ADMIN`, but a database column has no idea what a Java enum is. **`@Enumerated`** tells JPA how to turn an enum value into something the database can store, either its **name** as text or its **position** as a number. The choice looks tiny, but picking the wrong one can silently corrupt your data months later. This lesson shows both options, the one trap in the default behavior, and the pattern to use in real projects.

## 1. The setup

An enum, and an entity that uses it:

```java
public enum Role {
    USER,
    ADMIN
}
```

```java
@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;
}
```

The key line is `@Enumerated(EnumType.STRING)`. It says: store the enum's name.

```
Java            Database
Role.USER   ->  'USER'
Role.ADMIN  ->  'ADMIN'
```

## 2. The two options

**`EnumType.STRING`** stores the constant's name as text:

```
USER
ADMIN
```

**`EnumType.ORDINAL`** stores the constant's position in the enum, counting from zero:

```
USER   -> 0
ADMIN  -> 1
```

Here is the part many tutorials skip: **if you write no `@Enumerated` at all, JPA uses `ORDINAL`.** So forgetting the annotation does not give you readable text. It gives you the risky option without any warning.

## 3. Why `ORDINAL` is dangerous

Suppose you launch with this enum and the default (`ORDINAL`):

```java
public enum Role {
    USER,   // 0
    ADMIN   // 1
}
```

Your database now holds `0` and `1`. Later someone adds a new role at the top:

```java
public enum Role {
    GUEST,  // 0
    USER,   // 1
    ADMIN   // 2
}
```

Every existing row keeps its old number, but the numbers now mean something else:

```
Stored value 1  used to mean ADMIN, now means USER
Stored value 0  used to mean USER,  now means GUEST
```

Your admins become ordinary users, and nothing throws an error. It is data corruption with no warning. Reordering the constants, or inserting one anywhere except the end, causes the same problem.

With `STRING`, the database holds the names themselves. Adding `GUEST`, or reordering the enum, changes nothing about the existing rows.

## 4. The recommended pattern

For normal business enums (roles, statuses, types), use this combination every time:

```java
@Enumerated(EnumType.STRING)
@Column(nullable = false)
private Role role;
```

```
users
-----------------------------------------
id      email                role
550e... alice@example.com    USER
```

`@Enumerated` and `@Column` do different jobs and work together:

|Annotation|Decides|
|---|---|
|`@Enumerated`|**How** the enum is represented (text or number)|
|`@Column`|The column's rules (`nullable`, `name`, `length`, ...)|

Because `STRING` creates a text column, `@Column`'s `length` applies to it. The default is 255, which is more than enough for most enum names.

## 5. What `STRING` doesn't protect you from

`STRING` fixes the reordering problem, but it has its own weak spots:

- **Renaming a constant breaks old rows.** If you rename `ADMIN` to `ADMINISTRATOR`, existing rows still contain `'ADMIN'`, and loading them fails because Hibernate can't map that text to any constant. Treat enum names that are stored in the database as part of your schema: renaming one needs a data migration, for example an SQL `UPDATE` in Flyway or Liquibase.
- **Removing a constant has the same effect** while old rows still use it.
- **Constraint changes.** When Hibernate generates your schema, newer versions can add a database check constraint listing the allowed values. If you add a new constant later, make sure that constraint is updated too (in a migration, if you use one), or inserts of the new value may be rejected.

## 6. Using enums in queries

Pass the enum itself as a parameter. Don't write the text by hand:

```java
public interface UserRepository extends JpaRepository<User, UUID> {
    List<User> findByRole(Role role);

    @Query("select u from User u where u.role = :role")
    List<User> findAllWithRole(@Param("role") Role role);
}
```

Hibernate converts the enum to the right stored form for you, so this keeps working no matter which `EnumType` you use.

## 7. Remember: the enum in your API is a separate decision

How an enum is stored in the database and how it appears in your JSON are two different things. Jackson, by default, writes the constant's name (`"USER"`), but that is controlled by your DTO and Jackson settings, not by `@Enumerated`.

## Quick mental model

```
Enum field
   |
   |  @Enumerated
   v
How is it stored?
   |
   +-- STRING  -> 'ACTIVE'   (readable, safe to reorder and extend)
   +-- ORDINAL -> 0          (compact, but breaks when the enum changes)
```

## Key takeaways

1. `@Enumerated` tells JPA how to store an enum: by name (`STRING`) or by position (`ORDINAL`).
2. **The default is `ORDINAL`**, so always write the annotation explicitly.
3. Use `EnumType.STRING` by default. Choose `ORDINAL` only with a deliberate reason and tight control over the schema.
4. Pair it with `@Column(nullable = false)` when the value is required.
5. Stored enum names are part of your schema: renaming or removing one needs a data migration.
6. Pass enums as query parameters instead of typing their text.




[[Spring Framework]]