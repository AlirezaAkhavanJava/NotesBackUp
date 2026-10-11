
# `@Column` vs Bean Validation: Schema Hints vs Runtime Checks

**Definition:** `@Column(nullable = false, length = 50)` is **JPA mapping metadata**. It describes how a field maps to a database column. Bean Validation annotations like `@NotBlank` and `@Size(max = 50)` are **runtime validation rules** that a validator executes against an object. They live on the same field and look similar, but they are two separate systems run by two separate libraries.

Your suspicion is right: `@Column` constraints are mostly DDL definitions, not validation.

**Mental model:** Think of two different gatekeepers.

- `@Column` tells **the database** what to enforce. JPA/Hibernate only passes the description along.
- Bean Validation tells **the JVM** what to enforce, before anything is sent to the database.

## What `@Column` actually does

```java
@Entity
class User {
    @Column(name = "user_name", nullable = false, length = 50, unique = true)
    private String name;
}
```

Attribute by attribute:

- `name = "user_name"`: Maps the field to a column name. This is a real runtime effect, used in every generated SQL statement.
- `nullable = false`: Two effects. When Hibernate **generates the schema** (`spring.jpa.hibernate.ddl-auto=create` / `update`), it emits `NOT NULL`. Also, Hibernate checks nullability itself at flush time, but only for **null**, and it throws a Hibernate `PropertyValueException`, not a validation error.
- `length = 50`: Only used for DDL: `VARCHAR(50)`. Hibernate does **not** check string length before sending the INSERT. If you pass 80 characters, the database rejects it (or truncates it, depending on the database), and you get a `DataIntegrityViolationException`.
- `unique = true`: Only used for DDL (`UNIQUE` constraint). Hibernate does not check it. The database enforces it at insert time.

So `length` and `unique` are **never** checked by Hibernate. They only matter if Hibernate creates the schema, or as documentation. If you manage your schema with Flyway or Liquibase (which is what you should do in real projects), these attributes don't create anything. The migration SQL is the source of truth, and `@Column` just needs to agree with it.

## What Bean Validation does

```java
@NotBlank @Size(max = 50)
private String name;
```

When a validator runs, it inspects the object in memory and produces a `ConstraintViolation` for each broken rule. This happens in the JVM, with **no database involved**. It also has far more expressive power: `@Email`, `@Pattern`, `@Min`, `@Past`, `@NotBlank` (which `@Column` has no equivalent for), and custom constraints.

On entities specifically, Hibernate integrates with Bean Validation: if a validator is on the classpath, it runs the check on `@PrePersist` and `@PreUpdate`, before the SQL statement. Failure throws `ConstraintViolationException`.

## Side-by-side

||`@Column(...)`|Bean Validation (`@NotBlank`, `@Size`...)|
|---|---|---|
|Spec|JPA|Jakarta Bean Validation|
|Purpose|Describe the DB column|Check object state|
|When it acts|Schema generation; DB at insert time|Before persist/update (entities), or at controller/service boundary|
|Checked by|The database|A validator in the JVM|
|Blank strings (`" "`)|Not caught (`nullable=false` allows it)|`@NotBlank` catches it|
|String length|DDL only, DB rejects overflow|`@Size` checks in memory|
|Exception on failure|`DataIntegrityViolationException` (from DB)|`ConstraintViolationException` or `MethodArgumentNotValidException`|
|Error message|DB-specific, ugly|Customizable per constraint|

## A subtle bridge: Hibernate's schema generation reads Bean Validation

Hibernate has a feature where, when it generates DDL, it **reads some Bean Validation annotations** and applies them to the schema. `@NotNull` becomes `NOT NULL`, and `@Size(max = 50)` / `@Length` can set the column length. This is controlled by `jakarta.persistence.validation.mode` / `hibernate.validator.apply_to_ddl` (on by default). So with `ddl-auto=create`, `@NotNull @Size(max=50)` can produce the same schema as `@Column(nullable=false, length=50)`.

This is a convenience for generated schemas only. It does not change runtime behavior, and it does nothing with Flyway.

## Example: the same bad input, three outcomes

```java
User u = new User();
u.setName("x".repeat(80));   // too long for VARCHAR(50)
userRepository.save(u);
```

1. **With only `@Column(length = 50)`**: Hibernate sends the INSERT, the database rejects it, and you get `DataIntegrityViolationException` wrapping a SQL error. This usually becomes an HTTP 500 unless you handle it. (Some databases, like MySQL in non-strict mode, may silently truncate instead.)
2. **With `@Size(max = 50)` on the entity**: Validation fails at `@PrePersist` with `ConstraintViolationException`, before any SQL is sent. Cleaner, but still after your service logic ran.
3. **With `@Size(max = 50)` on the request DTO + `@Valid` in the controller**: The request is rejected with a 400 before it reaches your service at all. This is the best place for the user-facing feedback.

## Why you want both

They guard different things:

- DTO validation gives users **fast, clear errors** at the boundary.
- Entity-level validation is a **safety net** against bugs in your own code that build an invalid entity (e.g. a scheduler job, an import script).
- `@Column` / DB constraints are the **final authority**, the only thing that holds under concurrent requests, direct SQL edits, or other applications writing to the same database.

The DB constraint is the only one that can be trusted absolutely, because everything else in the JVM can be bypassed. `unique` is the best example: no annotation can reliably prevent duplicates by checking first, because two concurrent requests can both pass the check. The `UNIQUE` constraint in the database is what actually guarantees it.

## Practical rule

- Request DTOs: Bean Validation for user-facing rules and error messages.
- Entity: keep `@Column` accurate to your real schema (name, nullability, length). Add Bean Validation sparingly, mirroring the same limits, if you want the safety net.
- Schema: define it with Flyway/Liquibase migrations, and treat `ddl-auto=update` as a development shortcut only.
- Keep the numbers in sync. If DTO says `max = 50`, entity says `length = 50`, and DB says `VARCHAR(50)`, you get consistent behavior. If they drift (DTO allows 100, DB allows 50), you get 500 errors in production for input your validation accepted.




[[Spring Framework]]