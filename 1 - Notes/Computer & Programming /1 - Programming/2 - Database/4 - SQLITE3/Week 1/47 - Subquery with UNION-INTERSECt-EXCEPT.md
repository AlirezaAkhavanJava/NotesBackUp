
In SQLite, you can combine **subqueries** with `UNION`, `INTERSECT`, and `EXCEPT`. The key idea is that a compound query combines the **result sets** of multiple `SELECT` statements.

## 1. Basic structure

```sql
SELECT ...
UNION
SELECT ...
INTERSECT
SELECT ...
EXCEPT
SELECT ...;
```

Each side must return the **same number of columns**, with compatible types.

For example:

```sql
SELECT "name" FROM "students"
UNION
SELECT "name" FROM "teachers";
```

---

# 2. Using subqueries

A subquery is simply another `SELECT` whose result can participate in the set operation.

```sql
SELECT "name"
FROM "users"
WHERE "id" IN (
    SELECT "user_id"
    FROM "orders"
);
```

Now you can make the subquery itself a compound query:

```sql
SELECT "name"
FROM "users"
WHERE "id" IN (
    SELECT "user_id" FROM "orders"
    UNION
    SELECT "user_id" FROM "subscriptions"
);
```

Meaning:

```text
             ┌── orders
             │
user_id ─────┤ UNION
             │
             └── subscriptions
                    ↓
                 IDs
                    ↓
                  users
```

---

# 3. `UNION` inside a subquery

Suppose:

```text
users
+----+-------+
| id | name  |
+----+-------+
| 1  | Alice |
| 2  | Bob   |
| 3  | Carol |
| 4  | Dave  |
+----+-------+

orders
+---------+
| user_id |
+---------+
| 1       |
| 2       |
+---------+

premium_users
+---------+
| user_id |
+---------+
| 3       |
| 4       |
+---------+
```

You can do:

```sql
SELECT *
FROM "users"
WHERE "id" IN (
    SELECT "user_id"
    FROM "orders"

    UNION

    SELECT "user_id"
    FROM "premium_users"
);
```

Result:

```text
Alice
Bob
Carol
Dave
```

The subquery produces:

```text
1
2
3
4
```

and the outer query finds those users.

---

# 4. `INTERSECT` inside a subquery

`INTERSECT` means:

> Give me values that exist in **both** result sets.

```sql
SELECT *
FROM "users"
WHERE "id" IN (
    SELECT "user_id"
    FROM "orders"

    INTERSECT

    SELECT "user_id"
    FROM "premium_users"
);
```

If:

```text
orders        premium_users

1             3
2             4
3
```

then:

```text
INTERSECT
   ↓

3
```

So only Carol is returned.

---

# 5. `EXCEPT` inside a subquery

`EXCEPT` means:

> Give me values from the first result that don't exist in the second.

```sql
SELECT *
FROM "users"
WHERE "id" IN (
    SELECT "user_id"
    FROM "orders"

    EXCEPT

    SELECT "user_id"
    FROM "premium_users"
);
```

If:

```text
orders        premium_users

1             3
2             2
3
```

then:

```text
orders
  1
  2
  3

EXCEPT

  2
  3

=

  1
```

Only Alice remains.

---

# 6. Mixing all three

You can build something like:

```sql
SELECT *
FROM "users"
WHERE "id" IN (

    SELECT "user_id"
    FROM "orders"

    UNION

    SELECT "user_id"
    FROM "subscriptions"

    INTERSECT

    SELECT "user_id"
    FROM "premium_users"

    EXCEPT

    SELECT "user_id"
    FROM "banned_users"

);
```

However, **be careful** here.

Don't think of it as ordinary mathematical parentheses automatically surrounding each operation. Compound-query evaluation and precedence matter, and if the exact grouping matters, explicitly structure the query rather than relying on intuition.

---

# 7. The powerful pattern: nested compound queries

You can make each logical operation its own subquery:

```sql
SELECT *
FROM "users"
WHERE "id" IN (

    SELECT "id"
    FROM (
        SELECT "id"
        FROM "orders"

        UNION

        SELECT "id"
        FROM "subscriptions"
    )

    INTERSECT

    SELECT "id"
    FROM "premium_users"

);
```

Conceptually:

```text
                orders
                  │
                  ├── UNION ──→ A
                  │
            subscriptions
                              │
                              ↓
                         INTERSECT
                              │
                              ↓
                       premium_users
                              │
                              ↓
                           result
                              │
                              ↓
                            users
```

This is usually much easier to reason about.

---

# 8. You can also put a compound query in `FROM`

This is extremely useful:

```sql
SELECT *
FROM (
    SELECT "id", "name"
    FROM "users"

    UNION

    SELECT "id", "name"
    FROM "admins"
) AS "people";
```

The compound query becomes a **derived table**.

Then you can query it normally:

```sql
SELECT *
FROM (
    SELECT "id", "name"
    FROM "users"

    UNION

    SELECT "id", "name"
    FROM "admins"
) AS "people"
WHERE "name" LIKE 'A%';
```

Think:

```text
SELECT
    ↓
FROM (
    compound query
)
    ↓
temporary result set
    ↓
WHERE / JOIN / GROUP BY / etc.
```

---

## 9. Important rules

For:

```sql
SELECT ...
UNION
SELECT ...
```

the two `SELECT`s should have:

|Requirement|Example|
|---|---|
|Same number of columns|`SELECT id, name` + `SELECT id, name`|
|Corresponding columns compatible|`INTEGER` + `INTEGER`|
|Column names|Taken from the first `SELECT`|
|Duplicate handling|`UNION` removes duplicates|
|Duplicate preservation|`UNION ALL` preserves duplicates|

And:

```sql
UNION
INTERSECT
EXCEPT
```

are **set operators**. They don't combine rows like `JOIN` does.

### Mental model

```text
JOIN
→ combine columns from related rows

UNION
→ append two result sets

INTERSECT
→ keep common rows

EXCEPT
→ remove rows found in the second result
```

The most important technique for complex SQLite queries is:

```sql
SELECT ...
FROM (
    SELECT ...
    UNION
    SELECT ...
) AS x
WHERE ...;
```

You can nest these derived tables to create explicit logical grouping instead of writing one giant compound expression.


[[1 - WHAT IS SQLITE3 🍕]]