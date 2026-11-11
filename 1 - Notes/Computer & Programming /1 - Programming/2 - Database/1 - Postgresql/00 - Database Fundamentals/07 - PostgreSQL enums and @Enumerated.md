

A **PostgreSQL enum** is a column type that only accepts a fixed list of values, such as `'NEW'`, `'PAID'`, `'SHIPPED'`. You create it once with `CREATE TYPE` and use it like any other type. The database itself rejects any other value, no matter which application sends it.

`@Enumerated` is a JPA annotation that tells Hibernate how to save a Java `enum` into a column. It lives on the Java side and answers one question: "which value do I send to the database?" The two are not alternatives. One describes the column, and the other describes the conversion. So the short answer to your question is **yes, you still need it**, and you usually need one more annotation next to it when the column is a native enum.

## What you already have from the DDL lesson

You already saw `CREATE TYPE ... AS ENUM` and `ALTER TYPE ... ADD VALUE`. Here is what is new about how enums behave:

```sql
CREATE TYPE order_status AS ENUM ('NEW', 'PAID', 'SHIPPED');

CREATE TABLE orders (
    id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status order_status NOT NULL DEFAULT 'NEW'
);

ALTER TYPE order_status ADD VALUE 'CANCELLED' BEFORE 'SHIPPED';
ALTER TYPE order_status RENAME VALUE 'SHIPPED' TO 'DISPATCHED';

SELECT enum_range(NULL::order_status);   -- lists all values in order
SELECT * FROM orders WHERE status > 'NEW' ORDER BY status;
```

New things used above:

- **Enums are ordered.** The order is the order you declared the values, not alphabetical. That is why `status > 'NEW'` and `ORDER BY status` work, and why `BEFORE` and `AFTER` exist on `ADD VALUE`.
- `enum_range(NULL::order_status)` returns every value of the type. In `psql`, `\dT+ order_status` shows it too.
- `RENAME VALUE` renames a value in place, and all existing rows follow automatically.
- `NULL::order_status` is a cast. It means "a null of this type", which is how you point a function at a type.

Three rules you must know before choosing enums:

1. **You cannot remove a value.** There is no `DROP VALUE`. The workaround is to create a new type and convert the column with `ALTER COLUMN status TYPE new_type USING status::text::new_type`. That rewrites the table.
2. **A new value cannot be used in the same transaction that added it.** Flyway runs each migration in a transaction, so add the value in one migration and use it in the next.
3. **A value is stored in 4 bytes**, no matter how long its text is, so enums are compact.

## What `@Enumerated` does

Take this Java enum:

```java
public enum OrderStatus { NEW, PAID, SHIPPED }
```

JPA has two ways to store it:

|Mode|Stored value|Column type|
|---|---|---|
|`EnumType.ORDINAL`|`0`, `1`, `2`|integer|
|`EnumType.STRING`|`"NEW"`, `"PAID"`, `"SHIPPED"`|text|

**`ORDINAL` is the default when you write nothing.** That is a trap. The number is the constant's position in the Java file. If someone inserts `CANCELLED` in the middle of the enum or reorders the constants, every stored number now means something different, and nothing fails to warn you. Always write `@Enumerated(EnumType.STRING)`.

`STRING` stores the constant's name. It is safe against reordering, but renaming a Java constant now breaks old rows. The name in Java and the value in the database must stay in sync.

## Connecting the two

Here is the natural first attempt. It looks right but fails:

```java
@Enumerated(EnumType.STRING)
private OrderStatus status;
```

With a native enum column, you get this error:

```
ERROR: column "status" is of type order_status but expression is of type character varying
```

Hibernate sends the value as `varchar`, and PostgreSQL does not convert `varchar` to your enum type automatically. Hibernate has to be told that the column is a _named enum type_. Hibernate 6.2 and later (which current Spring Boot uses) has a type code for this:

```java
@Entity
@Table(name = "orders")
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(nullable = false, columnDefinition = "order_status")
    private OrderStatus status;
}
```

New things used above:

- `@JdbcTypeCode(SqlTypes.NAMED_ENUM)` tells Hibernate to bind the value as PostgreSQL's native enum type instead of plain text. This is the annotation that fixes the error.
- `@Enumerated(EnumType.STRING)` still decides what gets sent: the constant's name. The two annotations work together.
- `columnDefinition = "order_status"` names your database type explicitly. Hibernate uses it when it generates or checks DDL, so the Java side points at the exact type your Flyway migration created.

There are two other ways you will see this solved:

- **`?stringtype=unspecified` on the JDBC URL.** The driver sends every string parameter untyped, and PostgreSQL works out the type itself. It is a one-line fix, but it changes the behaviour of _all_ string parameters, so treat it as a shortcut and not a design.
- **An implicit cast in the database**, created with `CREATE CAST (varchar AS order_status) WITH INOUT AS IMPLICIT`. This works, but it hides type errors you would rather catch.

## Which design should you choose?

You have three real options for a status-like column:

|Design|Database side|Java side|
|---|---|---|
|Native enum|`order_status` type|`@Enumerated(STRING)` + `@JdbcTypeCode(NAMED_ENUM)`|
|Text + check|`VARCHAR(20)` with `CHECK (status IN ('NEW','PAID','SHIPPED'))`|`@Enumerated(STRING)`|
|Integer|`SMALLINT`|`@Enumerated(ORDINAL)` (avoid)|

**Native enum** gives you real type safety in the database, compact storage, and ordered comparisons. The cost is awkward changes: no removing values, the transaction rule above, and more mapping annotations. It makes the most sense when several applications or SQL scripts share the same database and you want the database to be the one that enforces the rules.

**Text plus CHECK** is plain `@Enumerated(STRING)` with no extra Hibernate annotation. Changing the allowed values is an ordinary `ALTER TABLE` that drops and re-adds the constraint, and it works the same in SQLite, which has no enum type at all.

For a typical Spring Boot service where only your app writes to the database, I would pick text plus CHECK. The native enum's extra safety rarely repays its migration pain. Choose the native enum when you have a stable list of values and several writers. Never choose `ORDINAL`.

## Related concept: `AttributeConverter`

Sometimes the database must store a code that is not the constant's name, for example `'N'`, `'P'`, `'S'`. Then `@Enumerated` is the wrong tool. You write a small class that implements `AttributeConverter<OrderStatus, String>`, with one method converting the enum to the code and one converting back, and you attach it with `@Convert`. You then control the stored value completely, and the database column stays a plain `CHAR(1)` or `VARCHAR`.


[[PostgreSQL]]