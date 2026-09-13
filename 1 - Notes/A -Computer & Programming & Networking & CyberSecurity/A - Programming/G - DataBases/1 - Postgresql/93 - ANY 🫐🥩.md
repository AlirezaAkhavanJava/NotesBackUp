
Below is a **complete, authoritative guide to the `ANY` operator** in **PostgreSQL** — how it works, exact **rules**, **syntax**, **comparison vs. `IN`**, **gotchas**, **performance**, and **senior-level patterns**.

---

## What is `ANY`?

```sql
expression operator ANY (subquery)
```

- `expression`: a single value (column, literal, etc.)
- `operator`: any comparison (`=`, `>`, `<`, `>=`, `<=`, `<>`, `!=`)
- `subquery`: returns **0 or more rows, 1 column**
- Returns `TRUE` if **at least one** row in the subquery satisfies the comparison.

> `SOME` is a **synonym** for `ANY` — same behavior.

---

## Syntax & Rules

| Rule | Detail |
|------|--------|
| **Subquery must return 1 column** | `ANY (SELECT col1, col2 ...)` → **ERROR** |
| **Subquery can return 0+ rows** | Empty result → `FALSE` |
| **Expression and subquery column must be compatible types** | Type mismatch → error |
| **Can be used in `WHERE`, `HAVING`, `SELECT` (boolean), `CASE`** | Anywhere a boolean expression is allowed |
| **`NULL` handling**: if any subquery row is `NULL`, result can be `NULL` unless operator handles it | See below |

---

## Comparison with `IN`

| Feature | `col = ANY (subquery)` | `col IN (subquery)` |
|--------|------------------------|---------------------|
| **Meaning** | `TRUE` if **any** value matches | **Identical** |
| **Performance** | Same (planner rewrites `IN` → `= ANY`) | — |
| **Flexibility** | Can use **any operator**: `> ANY`, `< ANY` | Only equality |
| **Use case** | Non-equality comparisons | Simple membership |

```sql
-- These are equivalent
WHERE dept_id IN (10, 20, 30)
WHERE dept_id = ANY (SELECT dept_id FROM nyc_depts)
```

---

## Core Examples

### 1. **Greater than ANY** → “more than the lowest”
```sql
SELECT *
FROM employees
WHERE salary > ANY (SELECT salary FROM interns);
```
> Returns employees earning **more than at least one intern** (i.e., more than the **lowest** intern salary).

### 2. **Less than ANY** → “less than the highest”
```sql
SELECT *
FROM products
WHERE price < ANY (SELECT price FROM premium_products);
```
> Cheaper than **at least one** premium product → cheaper than the **cheapest** premium.

### 3. **Equal to ANY** → same as `IN`
```sql
SELECT *
FROM orders
WHERE customer_id = ANY (SELECT id FROM vip_customers);
```

### 4. **With `ARRAY` (alternative syntax)
```sql
WHERE customer_id = ANY('{1001,1002,1003}'::int[])
```
> `ANY` works with **array expressions** too — no subquery needed.

---

## `ANY` vs `ALL` — Quick Contrast

| Operator | Meaning |
|--------|--------|
| `> ANY` | Greater than **at least one** (i.e., > **minimum**) |
| `> ALL` | Greater than **all** (i.e., > **maximum**) |
| `< ANY` | Less than **at least one** (i.e., < **maximum**) |
| `< ALL` | Less than **all** (i.e., < **minimum**) |

```sql
-- Highest paid employee in dept 10
WHERE salary > ALL (SELECT salary FROM employees WHERE dept = 10)

-- Paid more than the lowest manager
WHERE salary > ANY (SELECT salary FROM employees WHERE title = 'Manager')
```

---

## NULL Handling (Critical!)

| Case | Result |
|------|--------|
| Subquery returns `[NULL]` | `expr = ANY(...)` → `NULL` |
| Subquery returns `[5, NULL]` | `expr = 5` → `TRUE`<br>`expr = 6` → `NULL` (because of `NULL`) |
| Subquery returns `[]` (empty) | `FALSE` |

### Safe pattern: Filter `NULL`s
```sql
WHERE salary > ANY (
    SELECT salary FROM bonuses WHERE salary IS NOT NULL
)
```

---

## Advanced Patterns

### 1. **Top-N per group with `ANY` + `ARRAY_AGG`**
```sql
SELECT *
FROM employees e
WHERE e.employee_id = ANY (
    SELECT unnest(top_3_ids)
    FROM (
        SELECT department_id, array_agg(employee_id ORDER BY salary DESC LIMIT 3) AS top_3_ids
        FROM employees
        GROUP BY department_id
    ) t
    WHERE t.department_id = e.department_id
);
```

### 2. **`ANY` in `SELECT` (boolean column)**
```sql
SELECT 
    employee_id,
    salary,
    salary > ANY (SELECT avg_salary FROM dept_avgs WHERE dept = e.dept) AS above_any_dept_avg
FROM employees e;
```

### 3. **Dynamic `IN` list from JSON**
```sql
WHERE product_id = ANY (
    SELECT (json_array_elements('[101,102,103]'::json))::int
)
```

---

## Performance & Indexing

| Tip | Why |
|-----|-----|
| **Index the subquery column** | `CREATE INDEX ON table(col)` → fast semi-join |
| **Prefer `EXISTS` for existence checks** | Often faster than `= ANY` |
| **`ANY` with arrays is fastest** | No subquery → in-memory |
| **Avoid `OR` chains** → use `IN` / `= ANY` | Planner optimizes better |

```sql
-- Fast
WHERE dept_id = ANY (SELECT dept_id FROM active_depts)  -- uses index

-- Slow equivalent
WHERE dept_id = 10 OR dept_id = 20 OR dept_id = 30
```

---

## Common Mistakes & Fixes

| Mistake | Fix |
|-------|-----|
| `WHERE col > ANY (SELECT col FROM ...)` → includes `NULL` → `NULL` result | Add `WHERE col IS NOT NULL` in subquery |
| Using `IN` when you need `> ANY` | Use `> ANY` for “greater than minimum” |
| Forgetting `LATERAL` when correlating in `FROM` | Use `JOIN LATERAL` or move to `WHERE` |

---

## One-Liner Summary

> **`expr > ANY(subquery)`** = “greater than the **smallest** value”  
> **`expr < ANY(subquery)`** = “less than the **largest** value”  
> **`expr = ANY(subquery)`** = `IN` (but more powerful)

---

## Cheat Sheet

```sql
-- Greater than minimum
WHERE x > ANY (SELECT y FROM t)

-- Less than maximum
WHERE x < ANY (SELECT y FROM t)

-- Equal to any
WHERE x = ANY (SELECT y FROM t)      -- same as IN
WHERE x = ANY (VALUES (1),(2),(3))   -- or array: ANY('{1,2,3}')

-- With arrays (no subquery)
WHERE id = ANY('{1001,1002}'::int[])
```

---

**Master `ANY` → you’ve unlocked non-equality set logic.**  
Use it when `IN` isn’t enough.


##### Tags : [[1 - SQL 🥞]]