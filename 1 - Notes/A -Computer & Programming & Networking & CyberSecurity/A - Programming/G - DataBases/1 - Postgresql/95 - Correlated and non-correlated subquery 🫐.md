

## 1. Definitions

| Type | Definition | Execution |
|------|------------|-----------|
| **Non-correlated** (Independent) | Sub-query **does NOT reference any column from outer query** | Executed **once**, result cached |
| **Correlated** (Dependent) | Sub-query **references outer table columns** | Executed **once per outer row** |

---

## 2. Execution Model (How PostgreSQL Runs Them)

| Type | Plan Node | Example |
|------|----------|--------|
| **Non-correlated** | `InitPlan` or `SubPlan` (once) | `(SELECT AVG(salary) FROM employees)` |
| **Correlated** | `SubPlan` **per outer row** | `(SELECT COUNT(*) FROM bonuses b WHERE b.emp_id = e.id)` |

```sql
EXPLAIN (COSTS OFF)
SELECT first_name,
       (SELECT AVG(salary) FROM employees)          -- Non-correlated: InitPlan
       (SELECT COUNT(*) FROM reviews r WHERE r.emp_id = e.id) -- Correlated: SubPlan
FROM employees e;
```

---

## 3. Rules by Clause

| Clause | Non-correlated | Correlated |
|--------|----------------|------------|
| `SELECT` | Always allowed | Allowed |
| `FROM` / `JOIN` | Allowed | **Only with `LATERAL`** |
| `WHERE` | Allowed | Allowed |
| `HAVING` | Allowed | Allowed |

> **Key Rule**: **Correlated sub-queries in `FROM`/`JOIN` → `LATERAL` required**

---

## 4. Full Examples (All Clauses)

### Setup
```sql
CREATE TABLE employees (
    id INT, name TEXT, dept_id INT, salary NUMERIC
);
CREATE TABLE departments (id INT, name TEXT);
CREATE TABLE bonuses (emp_id INT, amount NUMERIC);
```

---

### `SELECT` Clause

```sql
SELECT 
    name,
    salary,
    -- Non-correlated: runs once
    (SELECT AVG(salary) FROM employees) AS company_avg,

    -- Correlated: runs per employee
    (SELECT COUNT(*) FROM bonuses b WHERE b.emp_id = e.id) AS bonus_count
FROM employees e;
```

---

### `FROM` Clause

```sql
-- Non-correlated: OK
SELECT d.name, stats.emp_count
FROM departments d
JOIN (
    SELECT dept_id, COUNT(*) AS emp_count
    FROM employees
    GROUP BY dept_id
) stats ON d.id = stats.dept_id;

-- Correlated: MUST use LATERAL
SELECT e.name, latest_bonus.amount
FROM employees e
LEFT JOIN LATERAL (
    SELECT amount
    FROM bonuses b
    WHERE b.emp_id = e.id
    ORDER BY amount DESC
    LIMIT 1
) latest_bonus ON true;
```

---

### `WHERE` Clause

```sql
SELECT *
FROM employees e
WHERE 
    -- Non-correlated
    salary > (SELECT AVG(salary) FROM employees)

    -- Correlated
    AND EXISTS (
        SELECT 1 FROM bonuses b
        WHERE b.emp_id = e.id AND b.amount > 1000
    );
```

---

### `JOIN` Clause (Same as `FROM`)

```sql
-- Non-correlated
SELECT e.name, dept_stats.total_salary
FROM employees e
JOIN (
    SELECT dept_id, SUM(salary) AS total_salary
    FROM employees
    GROUP BY dept_id
) dept_stats ON e.dept_id = dept_stats.dept_id;

-- Correlated → LATERAL
SELECT e.name, r.review_text
FROM employees e
LEFT JOIN LATERAL (
    SELECT review_text
    FROM reviews r
    WHERE r.emp_id = e.id
    ORDER BY review_date DESC
    LIMIT 1
) r ON true;
```

---

## 5. Performance Comparison

| Type | Execution | Best For |
|------|-----------|----------|
| **Non-correlated** | **Once** | Constants, aggregates, lookups |
| **Correlated** | **N times** (N = outer rows) | Row-specific logic, top-N per group |

### Optimization Tips

| Tip | Why |
|-----|-----|
| **Non-correlated → `InitPlan`** | Cached, fast |
| **Correlated → Index outer reference** | `WHERE b.emp_id = e.id` → use `INDEX ON bonuses(emp_id)` |
| **Use `EXISTS` over `IN` for correlated** | Semi-join, early exit |
| **Avoid correlated in `SELECT` if possible** | Use `WINDOW` or `JOIN` instead |

---

## 6. Senior-Level Patterns

### 1. **Top-N per Group (Correlated + LATERAL)**
```sql
SELECT e.*
FROM employees e
JOIN LATERAL (
    SELECT rank
    FROM (
        SELECT 
            id,
            ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rank
        FROM employees
    ) ranked
    WHERE ranked.id = e.id
) r ON r.rank <= 3;
```

### 2. **Convert Correlated → Non-correlated with CTE**
```sql
-- SLOW: correlated
SELECT e.*,
       (SELECT COUNT(*) FROM orders o WHERE o.emp_id = e.id) AS order_count
FROM employees e;

-- FAST: non-correlated via CTE
WITH order_counts AS (
    SELECT emp_id, COUNT(*) AS order_count
    FROM orders
    GROUP BY emp_id
)
SELECT e.*, COALESCE(oc.order_count, 0)
FROM employees e
LEFT JOIN order_counts oc ON oc.emp_id = e.id;
```

### 3. **Avoid `SELECT *` in Correlated Sub-queries**
```sql
-- BAD
(SELECT * FROM bonuses b WHERE b.emp_id = e.id LIMIT 1)

-- GOOD
(SELECT amount FROM bonuses b WHERE b.emp_id = e.id LIMIT 1)
```

---

## 7. Quick Decision Table

| You Need… | Use |
|----------|-----|
| Same value for all rows | **Non-correlated** |
| Different value per row | **Correlated + LATERAL** |
| Filter based on outer row | `WHERE EXISTS (...)` |
| Aggregate per group | `JOIN` + `GROUP BY` |
| Top-1 per employee | `LATERAL` sub-query |

---

## 8. Cheat Sheet

```sql
-- Non-correlated (runs once)
(SELECT AVG(salary) FROM employees)
(SELECT dept_name FROM departments WHERE id = 10)

-- Correlated (runs per row)
(SELECT COUNT(*) FROM bonuses b WHERE b.emp_id = e.id)
EXISTS (SELECT 1 FROM reviews r WHERE r.emp_id = e.id)

-- In FROM/JOIN
FROM (SELECT ...) AS t                 -- non-correlated
LEFT JOIN LATERAL (SELECT ... WHERE x = e.x) AS l ON true  -- correlated
```

---

## Final Summary

| Feature | Non-correlated | Correlated |
|-------|----------------|------------|
| References outer? | No | Yes |
| Runs how many times? | **Once** | **Per outer row** |
| `FROM`/`JOIN`? | Yes | Only with `LATERAL` |
| Performance | Fast | Slower (unless indexed) |
| Use case | Constants, pre-aggregates | Per-row logic, top-N |

---

**Master this → you control query performance at the deepest level.**  
**Non-correlated = speed. Correlated = power (with `LATERAL` and indexes).**


##### Tags : [[1 - SQL 🥞]]