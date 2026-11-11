
`@Table` tells JPA which database table an entity maps to. It also lets you describe that table a little: which schema it lives in, which columns must be unique together, and which indexes should exist. You place it on the entity class, right next to `@Entity`.

You don't always need it. If you leave it out, JPA picks a table name from the class name. So the real question is not "how do I use it" but "when does the default stop being good enough". The short answer: reserved words, schemas, and anything you want to name on purpose. Everything below builds on your `@GeneratedValue` and auditing lessons (same `Orders` entity) and on your DDL, schema and Flyway lessons.

## First: what happens without @Table

```java
@Entity
public class OrderItem { ... }
```

Two names get decided here, and people mix them up:

|Name|Decided by|Used where|
|---|---|---|
|Entity name|`@Entity(name = "...")`, default is the class name `OrderItem`|JPQL queries: `select o from OrderItem o`|
|Table name|`@Table(name = "...")`, otherwise derived from the entity name|The real SQL: `select ... from order_item`|

`@Table(name = ...)` never changes the JPQL name, and `@Entity(name = ...)` never changes the table.

How does `OrderItem` become `order_item`? Spring Boot sets a naming strategy (`CamelCaseToUnderscoresNamingStrategy`) that turns camelCase into snake_case and lowercases it. So `OrderItem` → `order_item`, and a field `createdAt` → `created_at`. That's why your Flyway column names matched without any `@Column`.

## The parameters

```java
@Entity
@Table(
    name = "orders",
    schema = "sales",
    uniqueConstraints = @UniqueConstraint(name = "uk_orders_number", columnNames = "order_number"),
    indexes = {
        @Index(name = "idx_orders_customer", columnList = "customer_id"),
        @Index(name = "idx_orders_status_created", columnList = "status, created_at")
    }
)
public class Orders extends Auditable { ... }
```

**`name`** is the table name. Use it when the default is wrong. The classic case is a reserved word: an entity called `User`, `Order`, or `Group` maps to a table that PostgreSQL treats as a keyword, and the query fails with a syntax error. Rename the table instead of fighting with quotes:

```java
@Entity
@Table(name = "users")
public class User { ... }
```

(You could force quoting with `@Table(name = "\"User\"")`, but then every raw SQL query must quote it too. Avoid it.)

**`schema`** puts the table in a PostgreSQL schema, so the SQL becomes `sales.orders`. This is the schema from your schema lesson. If every entity belongs to the same schema, set it once instead of on every class:

```properties
spring.jpa.properties.hibernate.default_schema=sales
```

**`catalog`** exists for databases where "catalog" means a database (MySQL). PostgreSQL ignores it, because the database comes from the JDBC URL. You'll almost never set it.

**`uniqueConstraints`** declares a uniqueness rule across **one or more** columns. For a single column, `@Column(unique = true)` is shorter. For a combination, you need this:

```java
@UniqueConstraint(name = "uk_member_course", columnNames = {"member_id", "course_id"})
```

That says the same member can't enroll in the same course twice. Note that `columnNames` takes **column names** (`member_id`), not Java field names (`memberId`).

**`indexes`** lists `@Index` entries. Each has a `name`, a `columnList` (comma-separated, with optional `ASC`/`DESC`), and `unique = true` if you want a unique index. In `"status, created_at"` the order matters: that index helps queries filtering on `status`, or on `status` and `created_at` together, but not on `created_at` alone.

Newer JPA versions (3.2) add `comment`, `options` and `check` to `@Table`. Check which Hibernate and JPA version your Spring Boot brings before relying on them.

## Who actually creates the constraints?

This is the part that matters most in production. `uniqueConstraints` and `indexes` are only turned into SQL when **Hibernate generates the schema**, that is, with `ddl-auto=create`, `create-drop` or `update`. With your setup (Flyway + `ddl-auto=validate`), Hibernate creates nothing. And `validate` checks tables, columns and types, not your indexes or unique constraints.

So the real rule lives in the migration:

```sql
-- V5__orders_constraints.sql
ALTER TABLE sales.orders
    ADD CONSTRAINT uk_orders_number UNIQUE (order_number);

CREATE INDEX idx_orders_customer       ON sales.orders (customer_id);
CREATE INDEX idx_orders_status_created ON sales.orders (status, created_at);
```

Then why write them in `@Table` at all? Three reasons: the entity documents the schema it expects, tests that use generated schemas (H2, `create-drop`) get the same rules, and it's easy to compare the two. Keep them in sync, and treat Flyway as the truth.

## Gotchas

**Unnamed constraints get ugly names.** Without `name`, Hibernate invents something like `UK_6dotkott2kjsp8vw4d0m25fb7`. Such names are unreadable in error messages and hard to drop later. Always name them.

**Index names are unique per schema in PostgreSQL**, not per table. Two tables can't both have an index called `idx_status`. Prefix with the table: `idx_orders_status`.

**Violating a unique constraint throws an exception.** In Spring this surfaces as `DataIntegrityViolationException`. Map it to a `409 Conflict` in your `@RestControllerAdvice` with a `ProblemDetail`, as in your exception handler lesson, so the client doesn't see a 500.

**SQLite has no schemas.** `schema = "sales"` makes Hibernate write `sales.orders`, which SQLite reads as an attached database and fails. Leave `schema` out when the entity runs on SQLite.

**Inheritance.** With `SINGLE_TABLE`, put `@Table` on the root entity only; subclasses share it. With `JOINED`, every class in the hierarchy can have its own `@Table`. A `@MappedSuperclass` like your `Auditable` is not a table, so it takes no `@Table`.

## Designing it for production

- Write `@Table(name = ...)` on every entity, even when the default would match. Then renaming a Java class during a refactor can't silently point it at a different table.
- Use plural, lowercase snake_case names (`orders`, `order_items`, `users`), and avoid reserved words from the start.
- Name every unique constraint and index with a consistent prefix: `uk_<table>_<columns>`, `idx_<table>_<columns>`.
- Put one schema per bounded area (like `sales`) with `default_schema`, and let Flyway create it.
- Create constraints and indexes in Flyway. Mirror them in `@Table` for documentation, but never depend on Hibernate to create them.
- Index the columns you filter and join on (foreign keys are the usual forgotten ones, since PostgreSQL does not index them for you).

## Related concepts, briefly

- **`@Column`**: the same idea one level down. It names a single column and sets `nullable`, `length`, `unique`, `updatable` (you used `updatable = false` in the auditing lesson).
- **`@SecondaryTable`**: maps one entity across two tables, joined by primary key. Useful when part of a wide row is rarely read.
- **`@JoinTable` and `@CollectionTable`**: they control the extra table behind a many-to-many relation or an element collection. They accept `name`, `schema`, `uniqueConstraints` and `indexes` just like `@Table`.
- **Naming strategy**: the Spring Boot setting `spring.jpa.hibernate.naming.physical-strategy` decides how Java names become table and column names. It's the reason `@Table` is optional in the first place.


[[Spring Framework]]