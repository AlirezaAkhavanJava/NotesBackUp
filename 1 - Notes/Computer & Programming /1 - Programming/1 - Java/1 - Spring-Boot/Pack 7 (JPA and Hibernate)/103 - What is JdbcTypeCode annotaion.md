
`@JdbcTypeCode` is a Hibernate annotation that tells Hibernate which JDBC type to use when it sends a field's value to the database and reads it back. Normally Hibernate guesses from the Java type: `String` becomes `VARCHAR`, `Long` becomes `BIGINT`, and so on. The annotation lets you override that guess with a specific code from `org.hibernate.type.SqlTypes`, so the value is bound the way the column actually expects it.

It matters most for your enum setup. A PostgreSQL `CREATE TYPE ... AS ENUM` is its own type, and it is not a `VARCHAR`. If Hibernate sends your Java enum as a plain string, PostgreSQL rejects it. `@JdbcTypeCode(SqlTypes.NAMED_ENUM)` fixes that by telling Hibernate to send the value as a named enum. It builds on the column types you saw in the PostgreSQL data types lesson and the `CREATE TYPE` statements from the DDL lesson.

## What goes wrong without it

Assume Flyway created this (the same style as your DDL and Flyway lessons):

```sql
CREATE TYPE order_status AS ENUM ('PENDING', 'PAID', 'SHIPPED');

CREATE TABLE orders (
    id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status order_status NOT NULL
);
```

And this entity, with only `@Enumerated`:

```java
public enum OrderStatus { PENDING, PAID, SHIPPED }

@Entity
@Table(name = "orders")
public class Order {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OrderStatus status;
}
```

On insert, PostgreSQL answers with an error like:

```
ERROR: column "status" is of type order_status but expression is of type character varying
```

`@Enumerated(EnumType.STRING)` only decides how the Java enum is turned into a value: its name as text. The JDBC type is still `VARCHAR`, and PostgreSQL does not implicitly convert `varchar` to an enum type.

## The fix

```java
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Enumerated(EnumType.STRING)
@JdbcTypeCode(SqlTypes.NAMED_ENUM)
@Column(nullable = false)
private OrderStatus status;
```

The two annotations answer two different questions, so you keep both:

|Annotation|Question it answers|Decides|
|---|---|---|
|`@Enumerated(STRING)`|What value represents the constant?|The text `"PAID"` (vs. the number `1` with `ORDINAL`)|
|`@JdbcTypeCode(NAMED_ENUM)`|How is that value handed to the driver?|Bound as a PostgreSQL enum, not `VARCHAR`|

Your queries keep working as normal. Hibernate handles the binding for you in JPQL and in derived repository methods:

```java
List<Order> findByStatus(OrderStatus status);
```

## Rules the two sides must follow

The enum labels in PostgreSQL and the constant names in Java are compared as exact text, so they must match, including case. `PENDING` in SQL and `Pending` in Java will fail when the value is read back.

If you ever need a label that differs from the constant name, don't try to bend the mapping. Rename one side so they match. It is simpler and it can't drift.

The type name matters too. If you run Hibernate with `ddl-auto=validate`, it checks the column against the type it expects, and a mismatch in the enum's type name can be reported. With Flyway owning the schema, as in your Flyway lesson, the safe setup is `ddl-auto=none` or `validate`. If validation complains about the type name, make `@Column(columnDefinition = "order_status")` match the real SQL type name.

## Which `SqlTypes` code for which situation

|Code|Use it when|
|---|---|
|`SqlTypes.NAMED_ENUM`|PostgreSQL native enum, stored by name. This is your case.|
|`SqlTypes.NAMED_ORDINAL_ENUM`|PostgreSQL native enum, but Hibernate maps by ordinal position.|
|`SqlTypes.ENUM`|Inline enum column types, like MySQL's `ENUM('a','b')`. Not PostgreSQL.|
|`SqlTypes.VARCHAR`|Plain text column holding the enum name. No `CREATE TYPE` needed.|

Don't confuse `ENUM` with `NAMED_ENUM`. They sound alike, but `ENUM` is for databases where the enum is declared inline in the column, while `NAMED_ENUM` is for databases like PostgreSQL where the enum is a separate named type.

## Native queries and changing the enum later

JPQL and derived queries bind the enum for you. In a native query you may need an explicit cast when you pass the value as a parameter:

```java
@Query(value = "SELECT * FROM orders WHERE status = CAST(:status AS order_status)",
       nativeQuery = true)
List<Order> findNative(@Param("status") String status);
```

When you add a constant, change both sides in the same release. The Flyway migration adds the label:

```sql
ALTER TYPE order_status ADD VALUE 'CANCELLED';
```

Then you add `CANCELLED` to the Java enum. PostgreSQL lets you add labels but not remove them easily, so treat labels as permanent. Also, a newly added label can't be used in the same transaction that created it, so keep the `ADD VALUE` migration separate from any migration that inserts rows using it.

## Related concept: the other tools in this family

`@JdbcTypeCode` is the quick, one-line switch. Hibernate also has `@JdbcType`, which takes a class and lets you plug in your own JDBC handling for cases the built-in codes don't cover. The same annotation covers other PostgreSQL types too: `@JdbcTypeCode(SqlTypes.JSON)` for a `jsonb` column, for example. The idea is always the same: tell Hibernate how the database wants the value, instead of letting it guess from the Java type.



[[Spring Framework]]