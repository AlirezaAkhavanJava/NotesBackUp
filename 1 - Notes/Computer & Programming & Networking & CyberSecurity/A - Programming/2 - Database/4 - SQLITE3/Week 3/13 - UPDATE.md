


`UPDATE` changes **existing rows** in a table.

Think of it as:

> **Find existing rows → change one or more columns → save the changes.**

---

## 1. Basic syntax

```sql
UPDATE table_name
SET column_name = value
WHERE condition;
```

Example:

```sql
UPDATE users
SET age = 26
WHERE id = 5;
```

This means:

> Find the user whose `id` is `5`, then change their `age` to `26`.

---

# 2. `UPDATE` without `WHERE` — dangerous

```sql
UPDATE users
SET age = 26;
```

This changes **every row**:

```text
id | name  | age
---+-------+----
1  | Ali   | 26
2  | Sara  | 26
3  | John  | 26
4  | Mike  | 26
```

So the general rule is:

```sql
UPDATE ...
SET ...
WHERE ...;
```

**Always think about the `WHERE` clause.**

---

# 3. Updating multiple columns

You can modify several columns at once:

```sql
UPDATE users
SET
    name = 'Alireza',
    age = 25,
    country = 'Iran'
WHERE id = 5;
```

Each assignment is separated by a comma:

```sql
SET
    column1 = value1,
    column2 = value2,
    column3 = value3
```

---

# 4. Updating based on a condition

Suppose:

```sql
SELECT * FROM products;
```

```text
id | name       | price
---+------------+------
1  | Keyboard   | 50
2  | Mouse      | 30
3  | Monitor    | 200
```

Increase the price of the mouse:

```sql
UPDATE products
SET price = 35
WHERE name = 'Mouse';
```

Or update everything below a certain price:

```sql
UPDATE products
SET price = price + 10
WHERE price < 100;
```

Notice this:

```sql
price = price + 10
```

The right side uses the **old value**.

So:

```text
50 → 60
30 → 40
```

---

# 5. `UPDATE` with comparison operators

You can use normal SQL conditions:

```sql
UPDATE products
SET price = price * 1.10
WHERE price >= 100;
```

Operators include:

```sql
=       equal
!=      not equal
<>      not equal
>       greater than
<       less than
>=      greater than or equal
<=      less than or equal
```

And:

```sql
AND
OR
NOT
IN
LIKE
BETWEEN
IS NULL
IS NOT NULL
```

Example:

```sql
UPDATE users
SET status = 'inactive'
WHERE age < 18 AND status = 'active';
```

---

# 6. `UPDATE` and `NULL`

Don't do this:

```sql
WHERE email = NULL;
```

Use:

```sql
WHERE email IS NULL;
```

Example:

```sql
UPDATE users
SET email = 'unknown@example.com'
WHERE email IS NULL;
```

---

# 7. Updating using an expression

You aren't restricted to literal values.

```sql
UPDATE accounts
SET balance = balance - 100
WHERE id = 42;
```

Or:

```sql
UPDATE products
SET price = ROUND(price * 1.20, 2)
WHERE category = 'electronics';
```

The database calculates the new value for each matching row.

---

# 8. Check before you update

This is an excellent habit.

Before:

```sql
UPDATE users
SET status = 'inactive'
WHERE age < 18;
```

first run:

```sql
SELECT *
FROM users
WHERE age < 18;
```

If the returned rows are correct, execute the `UPDATE`.

Think:

```text
SELECT → verify → UPDATE
```

This becomes especially important when working with real databases.

---

# 9. Know how many rows you changed

In SQLite CLI, after:

```sql
UPDATE users
SET status = 'inactive'
WHERE age < 18;
```

you can check:

```sql
SELECT changes();
```

For example:

```text
3
```

means the previous operation affected 3 rows.

---

# 10. `UPDATE` inside a transaction

For risky updates, use a transaction:

```sql
BEGIN TRANSACTION;

UPDATE users
SET status = 'inactive'
WHERE age < 18;

SELECT changes();

COMMIT;
```

If you realize something is wrong:

```sql
ROLLBACK;
```

So:

```text
BEGIN
  ↓
UPDATE
  ↓
check
  ↓
COMMIT
```

or:

```text
BEGIN
  ↓
UPDATE
  ↓
something is wrong
  ↓
ROLLBACK
```

This is a very important database concept.

---

# 11. `UPDATE ... RETURNING`

Modern SQLite supports `RETURNING`, which lets you see the rows affected by the update:

```sql
UPDATE users
SET age = age + 1
WHERE id = 5
RETURNING *;
```

You might get:

```text
id | name | age
---+------+----
5  | Ali  | 26
```

You can also return specific columns:

```sql
UPDATE users
SET age = age + 1
WHERE id = 5
RETURNING id, age;
```

This is particularly useful from application code.

---

# 12. The mental model

When you see:

```sql
UPDATE users
SET age = age + 1
WHERE id = 5;
```

break it into:

```text
TABLE
  ↓
users

WHICH ROWS?
  ↓
WHERE id = 5

WHAT CHANGES?
  ↓
age = age + 1

RESULT
  ↓
the matching row's age increases by 1
```

The most important distinction is:

```sql
WHERE
```

determines **which rows**

while:

```sql
SET
```

determines **what changes**.

### Core pattern to memorize

```sql
UPDATE table
SET column = new_value
WHERE condition;
```

And for multiple columns:

```sql
UPDATE table
SET
    column1 = value1,
    column2 = value2
WHERE condition;
```





[[1 - WHAT IS SQLITE3 🍕]]