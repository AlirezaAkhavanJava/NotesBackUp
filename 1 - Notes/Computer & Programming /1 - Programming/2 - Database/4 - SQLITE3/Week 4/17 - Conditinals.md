
In SQLite, **conditionals are mostly expressed through SQL expressions**, rather than procedural `if/else` statements like Java.

The main tools are:

1. `CASE` → `if / else`
    
2. `IIF()` → compact `if / else`
    
3. `AND`, `OR`, `NOT` → combine conditions
    
4. `IS`, `IS NULL`, `IS NOT NULL` → NULL conditions
    
5. `EXISTS` → condition based on another query
    
6. `WHEN` → conditions inside triggers
    
7. `RAISE()` → reject an operation when a condition is violated
    

---

# 1. `CASE` — the main conditional

The general form:

```sql
CASE
    WHEN condition THEN result
    WHEN condition THEN result
    ELSE result
END
```

Example:

```sql
SELECT
    username,
    CASE
        WHEN active = 1 THEN 'ACTIVE'
        ELSE 'INACTIVE'
    END AS status
FROM users;
```

Think of it like Java:

```java
if (active == 1) {
    return "ACTIVE";
} else {
    return "INACTIVE";
}
```

---

# 2. Multiple conditions

```sql
SELECT
    username,
    age,
    CASE
        WHEN age < 18 THEN 'MINOR'
        WHEN age < 65 THEN 'ADULT'
        ELSE 'SENIOR'
    END AS category
FROM users;
```

SQLite evaluates the `WHEN`s **top to bottom**.

So if:

```text
age = 30
```

SQLite checks:

```text
age < 18  → false
age < 65  → true  → ADULT
```

It stops there.

---

# 3. `CASE` with `AND` / `OR`

```sql
SELECT
    username,
    CASE
        WHEN active = 1 AND age >= 18
            THEN 'AVAILABLE'
        WHEN active = 1 AND age < 18
            THEN 'RESTRICTED'
        ELSE 'DISABLED'
    END AS status
FROM users;
```

You can build fairly complex business rules this way.

---

# 4. `CASE` can compare values directly

There are actually two forms.

### Searched CASE

This is the one you'll use most:

```sql
CASE
    WHEN age >= 18 THEN 'adult'
    WHEN age < 18 THEN 'minor'
END
```

### Simple CASE

You give `CASE` an expression:

```sql
CASE status
    WHEN 1 THEN 'ACTIVE'
    WHEN 0 THEN 'INACTIVE'
    ELSE 'UNKNOWN'
END
```

Equivalent conceptually to:

```java
switch (status) {
    case 1 -> "ACTIVE";
    case 0 -> "INACTIVE";
    default -> "UNKNOWN";
}
```

---

# 5. `IIF()` — compact conditional

SQLite also provides:

```sql
IIF(condition, true_value, false_value)
```

Example:

```sql
SELECT
    username,
    IIF(active = 1, 'ACTIVE', 'INACTIVE') AS status
FROM users;
```

Equivalent to:

```sql
CASE
    WHEN active = 1 THEN 'ACTIVE'
    ELSE 'INACTIVE'
END
```

For simple conditions, `IIF()` is convenient.

For complex business logic, prefer `CASE`.

---

# 6. Conditions in `WHERE`

You don't always need `CASE`.

For filtering, use normal boolean expressions:

```sql
SELECT *
FROM users
WHERE active = 1;
```

Multiple conditions:

```sql
SELECT *
FROM users
WHERE active = 1
  AND age >= 18;
```

Or:

```sql
SELECT *
FROM users
WHERE active = 1
   OR admin = 1;
```

This is closer to Java:

```java
if (user.active() && user.age() >= 18)
```

---

# 7. NULL requires special handling

This is important in SQL.

Don't do:

```sql
WHERE username = NULL
```

That doesn't work the way you expect.

Use:

```sql
WHERE username IS NULL
```

or:

```sql
WHERE username IS NOT NULL
```

For example:

```sql
SELECT
    username,
    CASE
        WHEN email IS NULL THEN 'NO EMAIL'
        ELSE email
    END AS email_status
FROM users;
```

---

# 8. `EXISTS` as a conditional

You can condition based on whether another query returns a row.

Suppose:

```sql
users
orders
```

You want to determine whether each user has an order:

```sql
SELECT
    username,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM orders
            WHERE orders.user_id = users.id
        )
        THEN 'HAS ORDERS'
        ELSE 'NO ORDERS'
    END AS order_status
FROM users;
```

This is extremely useful for database logic.

Conceptually:

```text
Does a matching row exist?
        │
    ┌───┴───┐
   YES      NO
    │        │
 HAS ORDERS  NO ORDERS
```

---

# 9. Conditions in `UPDATE`

`CASE` becomes particularly powerful here.

Suppose you want to automatically classify users:

```sql
UPDATE users
SET status =
    CASE
        WHEN age < 18 THEN 'MINOR'
        WHEN age < 65 THEN 'ADULT'
        ELSE 'SENIOR'
    END;
```

You can also conditionally change a value:

```sql
UPDATE users
SET discount =
    CASE
        WHEN active = 1 THEN 20
        ELSE 0
    END;
```

---

# 10. Conditions in `INSERT`

You can calculate values conditionally:

```sql
INSERT INTO users (
    username,
    status
)
VALUES (
    'alice',
    CASE
        WHEN 25 >= 18 THEN 'ADULT'
        ELSE 'MINOR'
    END
);
```

More realistically, the condition would use values coming from the inserted data.

---

# 11. Conditions inside triggers

This connects directly to what you asked before.

You can use `WHEN`:

```sql
CREATE TRIGGER log_active_user
AFTER INSERT ON users
WHEN NEW.active = 1
BEGIN
    INSERT INTO audit_log(message)
    VALUES ('Active user created');
END;
```

Here:

```sql
WHEN NEW.active = 1
```

means:

> Run this trigger only if the condition is true.

---

# 12. `CASE` inside a trigger

You can also use `CASE`:

```sql
CREATE TRIGGER validate_user
BEFORE INSERT ON users
BEGIN

    SELECT CASE
        WHEN NEW.username IS NULL
        THEN RAISE(ABORT, 'username is required')

        WHEN length(NEW.username) < 3
        THEN RAISE(ABORT, 'username is too short')
    END;

END;
```

Now you have conditional validation:

```text
INSERT
  │
  ▼
trigger
  │
  ├── username NULL? ──→ ABORT
  │
  ├── length < 3? ────→ ABORT
  │
  └── otherwise ──────→ continue
```

---

# 13. `RAISE()` gives you database-level `if`

This pattern is worth remembering:

```sql
SELECT CASE
    WHEN <invalid condition>
    THEN RAISE(ABORT, 'reason')
END;
```

For example:

```sql
SELECT CASE
    WHEN NEW.price < 0
    THEN RAISE(ABORT, 'price cannot be negative')
END;
```

Conceptually:

```java
if (price < 0) {
    throw new Exception("price cannot be negative");
}
```

Except the validation is happening **inside SQLite**.

---

# 14. Conditional logic with views

You can also put conditionals directly into a view:

```sql
CREATE VIEW user_status AS
SELECT
    id,
    username,
    CASE
        WHEN deleted = 1 THEN 'DELETED'
        WHEN active = 1 THEN 'ACTIVE'
        ELSE 'INACTIVE'
    END AS status
FROM users;
```

Then:

```sql
SELECT * FROM user_status;
```

might produce:

```text
id   username   status
---  ---------  --------
1    alice      ACTIVE
2    bob        INACTIVE
3    john       DELETED
```

---

## The important distinction

Think of SQLite conditionals in four categories:

|Tool|Purpose|
|---|---|
|`CASE`|Produce different values|
|`IIF()`|Simple `if/else` value|
|`WHERE` / `AND` / `OR`|Decide which rows participate|
|`WHEN`|Decide whether a trigger executes|
|`RAISE()`|Reject an operation|
|`EXISTS`|Make a decision based on another query|

The most important one to master is **`CASE`**.

If you're coming from Java, a good mental mapping is:

```text
Java                         SQLite

if / else              →     CASE
switch                 →     CASE expression
&&                     →     AND
||                     →     OR
!                      →     NOT
x == null              →     x IS NULL
collection exists      →     EXISTS(...)
exception              →     RAISE(...)
if trigger condition   →     WHEN
```

One SQLite-specific rule to burn into your memory: **SQL doesn't have Java-style procedural `if` statements in ordinary queries. You express conditional logic as expressions.**


[[SQlite]]