
Below is a **complete, authoritative guide** to the **`EXISTS`** and **`NOT EXISTS`** operators in **PostgreSQL** — the **most efficient way** to test for **set membership with correlation**.

---

## What is `EXISTS`?

```sql
WHERE EXISTS (subquery)
```

- Returns `TRUE` if the **subquery returns at least one row**.
- Returns `FALSE` if **zero rows**.
- **Ignores column values** — only cares about **row existence**.
- **Always correlated** in practice (references outer table).

> `NOT EXISTS` = opposite: `TRUE` if **no rows**.

---

## Core Rules

| Rule | Detail |
|------|--------|
| Subquery can return **any number of columns** | Use `SELECT 1` convention |
| Subquery can return **0 or more rows** | 0 → `FALSE` |
| **Must reference outer table** for correlation | Otherwise, use `IN` or scalar |
| Can be used in `WHERE`, `HAVING`, `CASE`, `SELECT` (boolean) | Anywhere boolean allowed |
| **`NULL` does not affect result** | `EXISTS` ignores `NULL` rows |

---

## Syntax & Examples

### 1. **Basic `EXISTS`**
```sql
SELECT *
FROM employees e
WHERE EXISTS (
    SELECT 1
    FROM bonuses b
    WHERE b.employee_id = e.employee_id
);
```
> Returns employees **who have at least one bonus**

### 2. **`NOT EXISTS`**
```sql
SELECT *
FROM employees e
WHERE NOT EXISTS (
    SELECT 1
    FROM terminations t
    WHERE t.employee_id = e.employee_id
);
```
> Active employees (never terminated)

---

## `EXISTS` vs `IN` vs `JOIN`

| Operator | Use Case | Performance | Correlation |
|--------|--------|-----------|-------------|
| `col IN (subquery)` | Equality match | Good | No (unless correlated) |
| `EXISTS` | **Any condition**, correlated | **Best** | Yes |
| `LEFT JOIN ... IS NOT NULL` | Same as `EXISTS` | Same (planner rewrites) | Yes |

### **PostgreSQL rewrites `EXISTS` → Anti/Semi Join**
```sql
-- These are equivalent and equally fast
WHERE EXISTS (SELECT 1 FROM b WHERE b.id = e.id)
WHERE e.id IN (SELECT id FROM b)
LEFT JOIN b ON b.id = e.id WHERE b.id IS NOT NULL
```

---

## Performance: Why `EXISTS` Wins

| Feature | Benefit |
|-------|--------|
| **Short-circuit** | Stops after **first matching row** |
| **Index usage** | Uses index on correlated column |
| **No data transfer** | Doesn’t fetch column values |
| **Semi-join optimization** | Planner uses `Hash Semi Join` or `Nested Loop` |

```sql
EXPLAIN (COSTS OFF)
SELECT * FROM employees e
WHERE EXISTS (
    SELECT 1 FROM bonuses b
    WHERE b.employee_id = e.employee_id
      AND b.amount > 5000
);
```
**Look for**: `Nested Loop Semi Join` + `Index Scan using idx_bonuses_emp`

---

## Advanced Patterns

### 1. **Multiple Conditions**
```sql
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.id
      AND o.order_date >= '2025-01-01'
      AND o.status = 'shipped'
)
```

### 2. **Top-1 per Group with `EXISTS` + `LATERAL`**
```sql
SELECT e.*
FROM employees e
WHERE EXISTS (
    SELECT 1
    FROM LATERAL (
        SELECT 1
        FROM salaries s
        WHERE s.emp_id = e.id
        ORDER BY s.effective_date DESC
        LIMIT 1
    ) latest
);
```

### 3. **`EXISTS` in `SELECT` (boolean flag)**
```sql
SELECT 
    e.name,
    e.salary,
    EXISTS (
        SELECT 1 FROM managers m WHERE m.emp_id = e.id
    ) AS is_manager
FROM employees e;
```

### 4. **`NOT EXISTS` for Uniqueness**
```sql
-- Find departments with no employees
SELECT d.*
FROM departments d
WHERE NOT EXISTS (
    SELECT 1 FROM employees e WHERE e.dept_id = d.id
);
```

---

## `EXISTS` with `NULL` Handling

| Case | Result |
|------|--------|
| Subquery returns `[NULL]` | `FALSE` (still a row → `EXISTS` = `TRUE`) |
| Subquery returns `[]` | `FALSE` |
| Correlated column is `NULL` | No match → `FALSE` |

```sql
-- This STILL returns TRUE if row exists (even if amount IS NULL)
WHERE EXISTS (SELECT 1 FROM bonuses b WHERE b.emp_id = e.id)
```

---

## Common Pitfalls & Fixes

| Mistake | Problem | Fix |
|-------|--------|-----|
| `WHERE col IN (SELECT ...)` with `NULL`s | Returns `NULL` → no rows | Use `EXISTS` |
| `WHERE NOT EXISTS` but forget index | Table scan | `CREATE INDEX ON table(correlated_col)` |
| Using `COUNT(*) > 0` | Fetches all rows | Use `EXISTS` |
| `SELECT * FROM subquery` | Unnecessary data | Use `SELECT 1` |

---

## Senior-Level Optimization Tips

| # | Tip |
|---|-----|
| **1** | **Always use `SELECT 1`** in `EXISTS` — never `SELECT *` |
| **2** | **Index every correlated column** — e.g., `CREATE INDEX ON bonuses(employee_id)` |
| **3** | **`NOT EXISTS` > `NOT IN`** — `NOT IN` fails with `NULL`s |
| **4** | **Use `EXISTS` in `WHERE`**, not `JOIN` for filtering |
| **5** | **Combine with `LATERAL` for complex per-row logic** |
| **6** | **Check `EXPLAIN` for `Semi Join`** — confirms optimization |

---

## `EXISTS` vs `IN` vs `JOIN` — Final Decision Table

| You Want… | Use |
|----------|-----|
| **"Has at least one X"** | `EXISTS` |
| **"Value in list"** | `IN` (static) or `= ANY` |
| **"No X at all"** | `NOT EXISTS` |
| **Fetch related data** | `JOIN` |
| **Avoid `NULL` issues** | `EXISTS` / `NOT EXISTS` |

---

## Cheat Sheet

```sql
-- Has bonus?
WHERE EXISTS (SELECT 1 FROM bonuses b WHERE b.emp_id = e.id)

-- Never terminated?
WHERE NOT EXISTS (SELECT 1 FROM terminations t WHERE t.emp_id = e.id)

-- Has order in 2025?
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.cust_id = c.id
      AND o.year = 2025
)

-- Boolean column
SELECT e.name, 
       EXISTS (SELECT 1 FROM vip v WHERE v.id = e.id) AS is_vip
FROM employees e;
```

---

## One-Liner Summary

> **`EXISTS` = “Does a row exist?” → Stops at first match → Fastest correlated filter.**

---

**Master `EXISTS` → you’ve unlocked PostgreSQL’s #1 performance weapon for correlation.**  
Use it **every time** you need to check **existence**, not value.

##### Tags : [[1 - SQL 🥞]]