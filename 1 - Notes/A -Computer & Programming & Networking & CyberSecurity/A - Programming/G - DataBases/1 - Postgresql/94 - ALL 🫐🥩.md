
Below is a **complete, authoritative guide to the `ALL` operator** in **PostgreSQL** — the **mirror image of `ANY`**, but **much stricter**.

---

## What is `ALL`?

```sql
expression operator ALL (subquery)
```

- Returns `TRUE` **only if the comparison holds for EVERY row** in the subquery.
- If the subquery is **empty**, returns `TRUE` (vacuous truth).
- Works with **any comparison operator**: `=`, `>`, `<`, `>=`, `<=`, `<>`

---

## Core Rules

| Rule | Detail |
|------|--------|
| Subquery must return **1 column** | Multiple columns → **ERROR** |
| Subquery can return **0 or more rows** | Empty → `TRUE` |
| Types must be compatible | Mismatch → error |
| `NULL` in subquery → result can be `NULL` | See NULL handling |
| Can be used in `WHERE`, `HAVING`, `SELECT`, `CASE` | Any boolean context |

---

## Comparison with `ANY`

| Operator | Meaning |
|--------|--------|
| `> ANY` | Greater than **at least one** → **> minimum** |
| `> ALL` | Greater than **every one** → **> maximum** |
| `< ANY` | Less than **at least one** → **< maximum** |
| `< ALL` | Less than **every one** → **< minimum** |
| `= ALL` | Equal to **all values** → all must be identical |

---

## Real-World Examples

### 1. **Greater than ALL** → “strictly the highest”
```sql
SELECT *
FROM employees
WHERE salary > ALL (SELECT salary FROM employees WHERE department_id = 10);
```
> Returns employees earning **more than every employee in dept 10** → **higher than the highest in dept 10**

### 2. **Less than ALL** → “strictly the lowest”
```sql
SELECT *
FROM products
WHERE price < ALL (SELECT price FROM catalog WHERE category = 'Electronics');
```
> Cheaper than **every** electronic item → **lowest price in category**

### 3. **Equal to ALL** → “all values are the same”
```sql
SELECT *
FROM orders
WHERE status = ALL (SELECT status FROM active_orders);
```
> Only returns rows if **every** `active_orders` has the same `status`

---

## `ALL` vs Aggregate Functions

| Goal | `ALL` | Aggregate |
|------|-------|-----------|
| > maximum | `> ALL (SELECT ...)` | `> (SELECT MAX(...) FROM ...)` |
| < minimum | `< ALL (SELECT ...)` | `< (SELECT MIN(...) FROM ...)` |
| = all values | `= ALL (SELECT ...)` | `= (SELECT col FROM ... LIMIT 1) AND COUNT(DISTINCT col) = 1` |

**`ALL` is more concise and often faster** — planner can use index directly.

---

## NULL Handling (Critical!)

| Subquery Result | `x > ALL (...)` | `x = ALL (...)` |
|-----------------|-----------------|-----------------|
| `[10, 20]` | `x > 20` → `TRUE` | `x = 10 AND x = 20` → `FALSE` |
| `[10, NULL]` | `NULL` (unknown) | `NULL` |
| `[]` (empty) | `TRUE` (vacuous) | `TRUE` |
| `[NULL]` | `NULL` | `NULL` |

### Safe Pattern: Exclude `NULL`s
```sql
WHERE salary > ALL (
    SELECT salary FROM managers WHERE salary IS NOT NULL
)
```

---

## Advanced Patterns

### 1. **Find strict maximum per group**
```sql
SELECT e.*
FROM employees e
WHERE e.salary > ALL (
    SELECT m.salary
    FROM employees m
    WHERE m.department_id = e.department_id
      AND m.employee_id <> e.employee_id
      AND m.salary IS NOT NULL
);
```
> Returns **only the highest-paid employee in each department**

### 2. **Use with `ARRAY` (no subquery)**
```sql
WHERE salary > ALL('{50000, 60000, 70000}'::int[])
-- Equivalent to: salary > 70000
```

### 3. **`ALL` in `HAVING`**
```sql
SELECT department_id
FROM employees
GROUP BY department_id
HAVING AVG(salary) > ALL (
    SELECT AVG(salary) FROM employees GROUP BY department_id
);
```
> Department with **highest average salary**

---

## Performance & Indexing

| Tip | Why |
|-----|-----|
| **Index the subquery column** | `CREATE INDEX ON employees(salary)` → fast `ALL` evaluation |
| **`ALL` often uses index scan** | More efficient than `MAX()` in some cases |
| **Prefer `> ALL` over `NOT EXISTS` + `>=`** | Cleaner and optimized |
| **Empty subquery = `TRUE`** | Use `COALESCE` or filter if needed |

---

## Common Pitfalls & Fixes

| Mistake | Result | Fix |
|-------|--------|-----|
| `WHERE x > ALL (SELECT y FROM t)` with `NULL` | `NULL` | Add `WHERE y IS NOT NULL` |
| Forgetting empty set → `TRUE` | Unexpected rows | Add `AND EXISTS (...)` if needed |
| `= ALL` on varied data | `FALSE` | Use only when expecting uniform values |

---

## `ALL` vs `ANY` Cheat Sheet

| Expression | Meaning | Equivalent |
|----------|--------|------------|
| `x > ANY(s)` | x > **minimum** | `x > MIN(s)` |
| `x < ANY(s)` | x < **maximum** | `x < MAX(s)` |
| `x > ALL(s)` | x > **maximum** | `x > MAX(s)` |
| `x < ALL(s)` | x < **minimum** | `x < MIN(s)` |
| `x = ANY(s)` | x in set | `x IN (s)` |
| `x = ALL(s)` | all values = x | `COUNT(DISTINCT) = 1` |

---

## One-Liner Summary

> **`expr > ALL(subquery)`** = “greater than **every** value” → **greater than the maximum**  
> **`expr < ALL(subquery)`** = “less than **every** value” → **less than the minimum**

---

## Final Cheat Sheet

```sql
-- Strictly highest salary in dept 10
WHERE salary > ALL (SELECT salary FROM employees WHERE dept = 10 AND salary IS NOT NULL)

-- Strictly lowest price in category
WHERE price < ALL (SELECT price FROM products WHERE cat = 'Toys' AND price IS NOT NULL)

-- All statuses are 'shipped'
WHERE status = ALL (SELECT status FROM open_orders)

-- Array version (no subquery)
WHERE salary > ALL('{80000, 90000}'::int[])  -- salary > 90000
```

---

**Master `ALL` → you now control “strict supremacy” in SQL.**  
Use it when you need **“better than everyone”**, not just “better than someone”.


##### Tags : [[1 - SQL 🥞]]