In SQLite, **`WHERE`** is the clause used to **filter rows**. It tells SQLite: _“Only work with rows where this condition is true.”_

## Basic structure

```sql
SELECT column1, column2
FROM table
WHERE condition;
```

Example:

```sql
SELECT title, author
FROM longlist
WHERE year >= 2020;
```

Only books whose `year` is `2020` or later are returned.

---

# Components of `WHERE`

A `WHERE` condition is generally built from these pieces:

```text
WHERE
  expression
  operator
  value
```

For example:

```sql
WHERE year >= 2020
```

|Component|Example|Meaning|
|---|---|---|
|`WHERE`|`WHERE`|Starts the filtering condition|
|Column/expression|`year`|What you're checking|
|Operator|`>=`|How you're comparing|
|Value|`2020`|What you're comparing against|

---

## 1. Comparison operators

### `=`

Equal to:

```sql
WHERE author = 'George Orwell'
```

### `!=` or `<>`

Not equal to:

```sql
WHERE year != 2020
```

SQLite supports both `!=` and `<>`.

### `>`

Greater than:

```sql
WHERE year > 2020
```

### `<`

Less than:

```sql
WHERE year < 2020
```

### `>=`

Greater than or equal:

```sql
WHERE year >= 2020
```

### `<=`

Less than or equal:

```sql
WHERE year <= 2020
```

---

# 2. Logical operators

You can combine conditions.

## `AND`

**Both conditions must be true.**

```sql
WHERE year >= 2020
  AND format = 'hardcover';
```

Meaning:

```text
year >= 2020
        AND
format = 'hardcover'
```

---

## `OR`

**At least one condition must be true.**

```sql
WHERE year = 2020
   OR year = 2021;
```

---

## `NOT`

Reverses a condition.

```sql
WHERE NOT format = 'hardcover';
```

Equivalent to:

```sql
WHERE format != 'hardcover';
```

---

# 3. `NULL`

`NULL` is special. You **cannot** normally do this:

```sql
WHERE translator = NULL;
```

Instead:

```sql
WHERE translator IS NULL;
```

Or:

```sql
WHERE translator IS NOT NULL;
```

This is extremely important in SQL.

---

# 4. `IN`

Checks whether a value is inside a list.

Instead of:

```sql
WHERE year = 2020
   OR year = 2021
   OR year = 2022;
```

You can write:

```sql
WHERE year IN (2020, 2021, 2022);
```

---

# 5. `NOT IN`

The opposite:

```sql
WHERE year NOT IN (2020, 2021, 2022);
```

---

# 6. `BETWEEN`

Checks whether a value is within a range.

```sql
WHERE year BETWEEN 2020 AND 2025;
```

This is equivalent to:

```sql
WHERE year >= 2020
  AND year <= 2025;
```

**`BETWEEN` is inclusive** on both ends.

---

# 7. `LIKE`

Used for pattern matching.

```sql
WHERE title LIKE 'Harry%';
```

`%` means **zero or more characters**.

So this can match:

```text
Harry Potter
Harry Potter and the Philosopher's Stone
Harry's World
```

Another example:

```sql
WHERE title LIKE '%war%';
```

Matches titles containing `war` anywhere.

---

## `_` wildcard

`_` means **exactly one character**.

```sql
WHERE author LIKE 'Jo_n';
```

Could match:

```text
John
Joan
```

---

# 8. `GLOB`

SQLite also has `GLOB`, which uses Unix-style wildcard patterns:

```sql
WHERE title GLOB 'Harry*';
```

Unlike `LIKE`, `GLOB` is case-sensitive by default and uses `*` instead of `%`.

---

# 9. `EXISTS`

Checks whether a subquery returns at least one row.

```sql
WHERE EXISTS (
    SELECT 1
    FROM authors
    WHERE authors.name = longlist.author
);
```

This is more advanced and is commonly used with correlated subqueries.

---

# 10. Expressions and functions

`WHERE` doesn't have to contain only a column.

You can use expressions:

```sql
WHERE year + 1 > 2025;
```

Or functions:

```sql
WHERE LENGTH(title) > 20;
```

Or:

```sql
WHERE LOWER(author) = 'george orwell';
```

---

# 11. Parentheses

Parentheses control the order in which conditions are evaluated.

For example:

```sql
WHERE year = 2020
   OR year = 2021
  AND format = 'hardcover';
```

`AND` has higher precedence than `OR`, so SQLite interprets this roughly as:

```sql
WHERE year = 2020
   OR (year = 2021 AND format = 'hardcover');
```

If you mean something different, use parentheses:

```sql
WHERE (year = 2020 OR year = 2021)
  AND format = 'hardcover';
```

**Good SQL habit:** use parentheses whenever mixing `AND` and `OR`. It makes your intention obvious.

---

# The big picture

You can think of `WHERE` as a **boolean filter**:

```sql
SELECT *
FROM longlist
WHERE condition;
```

SQLite evaluates the condition for **each row**:

```text
Row 1 → condition TRUE  → keep
Row 2 → condition FALSE → discard
Row 3 → condition TRUE  → keep
Row 4 → condition FALSE → discard
```

And the condition can become quite powerful:

```sql
SELECT title, author, year
FROM longlist
WHERE year BETWEEN 2020 AND 2026
  AND format IN ('hardcover', 'paperback')
  AND title LIKE '%Java%'
  AND translator IS NOT NULL;
```

So the core things to learn are:

```text
WHERE
├── Comparisons
│   ├── =
│   ├── != / <>
│   ├── >
│   ├── <
│   ├── >=
│   └── <=
│
├── Logical
│   ├── AND
│   ├── OR
│   └── NOT
│
├── NULL
│   ├── IS NULL
│   └── IS NOT NULL
│
├── Membership
│   ├── IN
│   └── NOT IN
│
├── Ranges
│   └── BETWEEN
│
├── Patterns
│   ├── LIKE
│   └── GLOB
│
├── Subqueries
│   └── EXISTS
│
└── Expressions / Functions
    ├── LENGTH()
    ├── LOWER()
    ├── UPPER()
    └── arithmetic expressions
```

The most important mental model is: **`WHERE` doesn't modify the rows—it decides which rows are allowed to continue through the query.**

[[1 - WHAT IS SQLITE3]]