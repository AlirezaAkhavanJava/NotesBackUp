

### 🧱 **BASIC LEVEL**

#### 🔹 Definition

`UNION` combines the **results of two or more SELECT queries** into a **single result set**.  
Each `SELECT` must return the **same number of columns**, with **compatible data types**.

#### 🔹 Syntax

```sql
SELECT column1, column2 FROM table1
UNION
SELECT column1, column2 FROM table2;
```

#### 🔹 Example

```sql
SELECT name FROM employees
UNION
SELECT name FROM managers;
```

→ This returns all unique names that appear in either `employees` or `managers`.

---

### ⚙️ **INTERMEDIATE LEVEL**

#### 🔸 `UNION` vs `UNION ALL`

|Keyword|Removes Duplicates|Faster|When to Use|
|---|---|---|---|
|`UNION`|✅ Yes|❌ Slower|When duplicates don’t make sense|
|`UNION ALL`|❌ No|✅ Faster|When you want to keep duplicates|

Example:

```sql
SELECT city FROM customers
UNION ALL
SELECT city FROM suppliers;
```

→ Keeps all cities, even if some repeat.

---

### 🧠 **ADVANCED LEVEL (PostgreSQL details)**

#### 🔹 ORDER BY in UNION

If you need sorting, apply `ORDER BY` **after the full UNION**, not inside individual queries:

```sql
SELECT name FROM employees
UNION
SELECT name FROM managers
ORDER BY name;
```

#### 🔹 Column Names

PostgreSQL uses the **column names from the first SELECT** query:

```sql
SELECT id AS employee_id, name FROM employees
UNION
SELECT id, name FROM contractors;
```

→ Final output column will be named `employee_id`.

#### 🔹 Type Resolution

PostgreSQL automatically chooses a **common type** when types differ but are compatible:

```sql
SELECT 1 AS value
UNION
SELECT 1.5;
-- Result type is numeric (since both int and float are compatible)
```

#### 🔹 Use with Subqueries

You can use `UNION` inside subqueries or CTEs:

```sql
WITH combined AS (
  SELECT id, name FROM employees
  UNION ALL
  SELECT id, name FROM contractors
)
SELECT * FROM combined WHERE name LIKE 'E%';
```

---

### 🚀 **REAL-WORLD USE CASE**

Merging data from multiple sources:

```sql
SELECT email FROM users
UNION
SELECT email FROM newsletter_subscribers;
```

→ Quickly creates a unified list without duplicates.

---
## 🧱 1. Structural Rules

These are **mandatory** — your query fails if you break them.

### ✅ Rule 1: Same Number of Columns

Every `SELECT` in a `UNION` must return the **same number of columns**.

```sql
-- ❌ Error: different column counts
SELECT id, name FROM users
UNION
SELECT id FROM admins;
```

---

### ✅ Rule 2: Same (or Compatible) Data Types

Each column position must have **compatible data types** across all SELECTs.  
PostgreSQL will auto-convert when possible.

```sql
SELECT id, name FROM employees
UNION
SELECT id, CAST(NULL AS TEXT) FROM contractors; -- compatible
```

---

### ✅ Rule 3: Column Names Come from the First SELECT

```sql
SELECT id AS employee_id, name FROM employees
UNION
SELECT id, name FROM contractors;
-- → Output column name = employee_id
```

---

### ✅ Rule 4: ORDER BY Applies to the Final Result Only

You cannot order each SELECT individually (unless wrapped in subqueries):

```sql
-- ✅ Correct
SELECT name FROM employees
UNION
SELECT name FROM managers
ORDER BY name;

-- ❌ Wrong
SELECT name FROM employees ORDER BY name
UNION
SELECT name FROM managers;
```

---

## ⚙️ **2. Behavior Rules**

### ✅ Rule 5: `UNION` Removes Duplicates

By default, it performs a **distinct** operation on the combined results.

### ✅ Rule 6: Use `UNION ALL` to Keep Duplicates

`UNION ALL` is faster because it **skips deduplication** (no sorting or hashing needed).

---

### ✅ Rule 7: Performance Matters

`UNION` (without ALL) may require a **sort or hash step** to eliminate duplicates.  
For large datasets, prefer `UNION ALL` when possible and deduplicate later if needed:

```sql
SELECT * FROM (
  SELECT name FROM employees
  UNION ALL
  SELECT name FROM managers
) t
GROUP BY name;
```

---

## 🧠 **3. PostgreSQL-Specific Rules**

### ✅ Rule 8: Type Resolution Rules

PostgreSQL picks the **most general type** that can represent all branches:

- `int` + `numeric` → `numeric`
    
- `text` + `varchar` → `text`
    
- `date` + `timestamp` → `timestamp`
    

You can force a type using `CAST()`.

---

### ✅ Rule 9: Parentheses for Complex Combinations

When chaining multiple `UNION`s and `INTERSECT`s, **use parentheses** to control order:

```sql
(SELECT id FROM users
 UNION
 SELECT id FROM admins)
INTERSECT
SELECT id FROM active_accounts;
```

---

### ✅ Rule 10: Null Handling

`NULL` values are treated as **equal** when deduplicating in `UNION` (unlike normal comparisons).

```sql
SELECT NULL AS city
UNION
SELECT NULL;
-- → Only one NULL appears
```

---

### ✅ Rule 11: Limit + Offset Placement

If you want to limit the **final** combined result:

```sql
SELECT id FROM users
UNION
SELECT id FROM admins
LIMIT 10;
```

If you want to limit **each branch**, wrap them:

```sql
SELECT * FROM (
  SELECT id FROM users LIMIT 10
  UNION
  SELECT id FROM admins LIMIT 10
) t;
```

---

### ✅ Rule 12: UNION in Views and CTEs

You can safely use `UNION` inside **views** or **CTEs** to create unified virtual tables:

```sql
CREATE VIEW all_users AS
SELECT id, name FROM customers
UNION
SELECT id, name FROM employees;
```

---


## ❌ **1. Different Number of Columns**

You must return **the same number of columns** in all `SELECT`s — otherwise you’ll get:

```
ERROR: each UNION query must have the same number of columns
```

**Bad:**

```sql
SELECT id, name FROM employees
UNION
SELECT id FROM contractors; -- ❌
```

**Fix:**

```sql
SELECT id, name FROM employees
UNION
SELECT id, NULL AS name FROM contractors; -- ✅
```

---

## ❌ **2. Mismatched or Incompatible Data Types**

Even if the column count matches, the **data types must align** or be implicitly convertible.

**Bad:**

```sql
SELECT id, name FROM employees
UNION
SELECT id, hire_date FROM contractors; -- ❌ name(text) vs hire_date(date)
```

**Fix:**

```sql
SELECT id, name FROM employees
UNION
SELECT id, CAST(hire_date AS TEXT) FROM contractors; -- ✅
```

---

## ❌ **3. Wrong `ORDER BY` Placement**

You can only have **one ORDER BY** — at the **end** of the whole union.  
**Bad:**

```sql
SELECT name FROM employees ORDER BY name
UNION
SELECT name FROM managers;
-- ❌ Syntax error
```

**Fix:**

```sql
SELECT name FROM employees
UNION
SELECT name FROM managers
ORDER BY name; -- ✅ Works
```

If you want each part ordered separately, use **subqueries**:

```sql
SELECT * FROM (
  SELECT name FROM employees ORDER BY name
) e
UNION
SELECT * FROM (
  SELECT name FROM managers ORDER BY name
) m;
```

---

## ❌ **4. Forgetting `ALL` When You Need Duplicates**

Developers often use plain `UNION` without realizing it removes duplicates.

**Example:**

```sql
SELECT city FROM orders_2024
UNION
SELECT city FROM orders_2025;
```

→ Some cities disappear if they appear in both tables.

**Fix (keep all):**

```sql
SELECT city FROM orders_2024
UNION ALL
SELECT city FROM orders_2025;
```

---

## ❌ **5. Unexpected Column Names**

Only the **first SELECT’s** column names appear in the final result.

**Example:**

```sql
SELECT id AS user_id, name FROM users
UNION
SELECT id, fullname FROM customers;
```

→ Output columns: `user_id`, `name`  
(`fullname` label is ignored)

---

## ❌ **6. Wrong Parentheses with Mixed Operators**

When mixing `UNION`, `INTERSECT`, and `EXCEPT`, SQL follows **left-to-right precedence**,  
but you should **always use parentheses** to make it explicit.

**Bad:**

```sql
SELECT id FROM users
UNION
SELECT id FROM admins
INTERSECT
SELECT id FROM active_accounts; -- ❓ Unclear order
```

**Fix:**

```sql
(SELECT id FROM users
 UNION
 SELECT id FROM admins)
INTERSECT
SELECT id FROM active_accounts; -- ✅
```

---

## ❌ **7. Forgetting NULL Behavior**

`UNION` treats `NULL = NULL` during deduplication (unlike in normal SQL where `NULL != NULL`).

**Example:**

```sql
SELECT NULL AS city
UNION
SELECT NULL;
-- → Only one NULL appears
```

---

## ❌ **8. LIMIT/OFFSET Applied in the Wrong Place**

`LIMIT` or `OFFSET` after `UNION` applies to the **final combined set**, not each query.

**Bad:**

```sql
SELECT id FROM users LIMIT 10
UNION
SELECT id FROM admins LIMIT 10; -- ❌ LIMIT only applies to first SELECT
```

**Fix:**

```sql
SELECT * FROM (
  SELECT id FROM users LIMIT 10
  UNION
  SELECT id FROM admins LIMIT 10
) t;
```

---

## ❌ **9. Performance Killer: Using `UNION` Instead of `UNION ALL`**

If your tables are large and duplicates are rare, `UNION` wastes time sorting or hashing results.  
Use `UNION ALL` unless deduplication is absolutely necessary.

---

## ❌ **10. Wrong Expectations in Joins**

`UNION` doesn’t join — it **stacks rows vertically** (like appending).  
Many beginners confuse it with `JOIN`, which combines columns horizontally.

**Bad mental model:**

> “UNION joins my two tables.”

**Reality:**

> `UNION` → add more rows  
> `JOIN` → add more columns

---

#### Tags : [[1 - SQL 🥞]]