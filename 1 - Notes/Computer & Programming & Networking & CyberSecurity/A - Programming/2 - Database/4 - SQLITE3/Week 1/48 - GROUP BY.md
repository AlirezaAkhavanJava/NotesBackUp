
# `GROUP BY` in SQLite3

`GROUP BY` is a SQL clause used to **combine rows that have the same value(s) into groups**, usually so you can perform an **aggregate calculation for each group**.

The core idea:

> **`GROUP BY` changes a collection of individual rows into groups of rows.**

---

## 1. Basic syntax

```sql
SELECT column, aggregate_function(column)
FROM table
GROUP BY column;
```

Example:

```sql
SELECT "department", COUNT(*)
FROM "employees"
GROUP BY "department";
```

Suppose the table is:

```text
employees
+----+--------+------------+
| id | name   | department |
+----+--------+------------+
| 1  | Alice  | IT         |
| 2  | Bob    | IT         |
| 3  | Carol  | HR         |
| 4  | Dave   | HR         |
| 5  | Eve    | IT         |
+----+--------+------------+
```

`GROUP BY department` creates:

```text
IT → Alice, Bob, Eve
HR → Carol, Dave
```

Then:

```sql
COUNT(*)
```

operates **inside each group**.

Result:

```text
department | COUNT(*)
-----------+--------
HR         | 2
IT         | 3
```

---

# 2. Why `GROUP BY` exists

Without `GROUP BY`:

```sql
SELECT COUNT(*)
FROM "employees";
```

You get **one result for the entire table**:

```text
5
```

With:

```sql
SELECT "department", COUNT(*)
FROM "employees"
GROUP BY "department";
```

you get **one result per department**:

```text
HR | 2
IT | 3
```

So:

```text
Aggregate without GROUP BY
        ↓
one aggregate for everything

Aggregate + GROUP BY
        ↓
one aggregate for each group
```

---

# 3. `GROUP BY` works with aggregate functions

The most common aggregate functions are:

|Function|Meaning|
|---|---|
|`COUNT()`|Number of rows/values|
|`SUM()`|Sum|
|`AVG()`|Average|
|`MIN()`|Minimum|
|`MAX()`|Maximum|

Example:

```sql
SELECT
    "department",
    COUNT(*) AS "employees",
    AVG("salary") AS "average_salary",
    MIN("salary") AS "minimum_salary",
    MAX("salary") AS "maximum_salary"
FROM "employees"
GROUP BY "department";
```

Conceptually:

```text
             employees
                 │
                 ▼
          GROUP BY department
             /          \
            /            \
          IT              HR
          │                │
    ┌─────┼─────┐      ┌───┴───┐
  Alice  Bob   Eve    Carol   Dave
    │      │     │       │       │
    └──────┴─────┘       └───────┘
            │                 │
            ▼                 ▼
        aggregates        aggregates
```

---

# 4. Grouping by multiple columns

You aren't limited to one column.

```sql
SELECT
    "department",
    "job",
    COUNT(*)
FROM "employees"
GROUP BY "department", "job";
```

SQLite groups by the **combination**:

```text
department + job
```

For example:

```text
IT + Developer
IT + Manager
HR + Recruiter
HR + Manager
```

These are four different groups.

---

# 5. `WHERE` vs `GROUP BY`

This distinction is extremely important.

### `WHERE`

Filters **individual rows before grouping**.

```sql
SELECT "department", COUNT(*)
FROM "employees"
WHERE "salary" > 50000
GROUP BY "department";
```

Process:

```text
table
 ↓
WHERE
 ↓
remaining rows
 ↓
GROUP BY
 ↓
groups
 ↓
COUNT()
```

---

# 6. `HAVING` vs `WHERE`

`HAVING` filters **groups after grouping**.

Example:

```sql
SELECT
    "department",
    COUNT(*) AS "employee_count"
FROM "employees"
GROUP BY "department"
HAVING COUNT(*) >= 3;
```

Process:

```text
FROM
 ↓
WHERE
 ↓
GROUP BY
 ↓
aggregate functions
 ↓
HAVING
 ↓
final result
```

For example:

```text
IT → 3
HR → 2
```

With:

```sql
HAVING COUNT(*) >= 3
```

result:

```text
IT → 3
```

### Mental distinction

```text
WHERE
→ "Which ROWS should participate?"

GROUP BY
→ "How should those rows be GROUPED?"

HAVING
→ "Which GROUPS should remain?"
```

---

# 7. `GROUP BY` with `ORDER BY`

You can sort the grouped result:

```sql
SELECT
    "department",
    COUNT(*) AS "employee_count"
FROM "employees"
GROUP BY "department"
ORDER BY "employee_count" DESC;
```

Result:

```text
IT | 3
HR | 2
```

---

# 8. `GROUP BY` and `DISTINCT` are related but different

This:

```sql
SELECT DISTINCT "department"
FROM "employees";
```

gives:

```text
HR
IT
```

You could think of it as:

> "Give me each department once."

But:

```sql
SELECT "department", COUNT(*)
FROM "employees"
GROUP BY "department";
```

means:

> "Create a group for each department and perform an operation on each group."

So:

```text
DISTINCT
→ eliminate duplicate result rows

GROUP BY
→ construct groups for aggregation
```

---

# 9. `GROUP BY` without an aggregate

SQLite allows:

```sql
SELECT "department"
FROM "employees"
GROUP BY "department";
```

This can produce unique departments, similar to:

```sql
SELECT DISTINCT "department"
FROM "employees";
```

But if your goal is simply uniqueness, `DISTINCT` communicates the intention more clearly.

---

# 10. The most important mental model

Imagine:

```sql
SELECT "department", COUNT(*)
FROM "employees"
GROUP BY "department";
```

SQLite conceptually does:

```text
employees
    │
    ▼
┌─────────────────────────┐
│ GROUP BY department     │
└─────────────────────────┘
    │
    ├── HR
    │    ├── Carol
    │    └── Dave
    │
    └── IT
         ├── Alice
         ├── Bob
         └── Eve
              │
              ▼
       COUNT each group
              │
              ▼
       HR → 2
       IT → 3
```

The key idea is:

> **`GROUP BY` partitions the rows into groups based on equal values, allowing aggregate functions to operate independently on each group.**


[[1 - WHAT IS SQLITE3 🍕]]