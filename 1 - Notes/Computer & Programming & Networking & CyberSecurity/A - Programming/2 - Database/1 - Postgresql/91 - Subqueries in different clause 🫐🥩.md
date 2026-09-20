
Below is a **complete, practical guide** to using **sub-queries (a.k.a. nested queries or inner queries)** in **PostgreSQL** inside the four major clauses:

| Clause | What it does | Sub-query role |
|--------|--------------|----------------|
| `SELECT` | Returns columns | **Scalar sub-query** → returns **one row, one column** |
| `FROM`   | Supplies row source | **Table sub-query** → acts like a derived table / CTE |
| `JOIN`   | Combines tables | Same as `FROM`, but used in join logic |
| `WHERE`  | Filters rows | **Scalar**, **row**, or **set** sub-query with comparison/logical operators |

We’ll walk through **syntax, examples, explanations**, the **comparison (`=`, `>`, `IN`, `EXISTS`, etc.)** and **logical (`AND`, `OR`, `NOT`)** operators, and finish with **senior-level tips**.

---

## 1. Sub-query in `SELECT` (Scalar Sub-query)

```sql
SELECT 
    employee_id,
    first_name,
    salary,
    (SELECT AVG(salary) FROM employees) AS company_avg_salary,
    salary - (SELECT AVG(salary) FROM employees) AS diff_from_avg
FROM employees
WHERE department_id = 10;
```

### Explanation
- The sub-query **must return exactly one value** (`AVG` → scalar).
- It is executed **once** for the whole query (PostgreSQL optimizes it into a constant).
- Use **comparison operators** inside the outer expression: `-`, `>`, `<`, `=`, etc.

### With logical operators
```sql
SELECT employee_id, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees)
  AND department_id IN (10, 20);
```

---

## 2. Sub-query in `FROM` (Derived Table)

```sql
SELECT d.dept_name, e.cnt
FROM (
    SELECT department_id, COUNT(*) AS cnt
    FROM employees
    GROUP BY department_id
) AS e
JOIN departments d USING (department_id)
ORDER BY e.cnt DESC;
```

### Explanation
- Sub-query becomes a **temporary table** aliased as `e`.
- Must have an **alias** (`AS e`).
- Useful for **pre-aggregations**, complex calculations, or when you need to filter on aggregates.

### Senior tip – Use `LATERAL` for row-by-row sub-queries
```sql
SELECT e.employee_id, e.first_name, r.latest_review
FROM employees e
LEFT JOIN LATERAL (
    SELECT review_text AS latest_review
    FROM reviews r
    WHERE r.employee_id = e.employee_id
    ORDER BY review_date DESC
    LIMIT 1
) r ON true;
```
`LATERAL` lets the inner query reference outer columns **per row**.

---

## 3. Sub-query in `JOIN` (Same as `FROM`, but in join syntax)

```sql
SELECT e.first_name, s.sales_total
FROM employees e
INNER JOIN (
    SELECT salesperson_id, SUM(amount) AS sales_total
    FROM sales
    WHERE sale_date >= '2025-01-01'
    GROUP BY salesperson_id
    HAVING SUM(amount) > 10000
) s ON e.employee_id = s.salesperson_id;
```

### Explanation
- Same semantics as `FROM`, just written in `JOIN` for readability.
- Often used with **correlation** (outer reference) via `LATERAL JOIN`.

---

## 4. Sub-query in `WHERE`

### 4.1 Scalar comparison
```sql
SELECT *
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);
```

### 4.2 `IN` / `NOT IN` (set membership)
```sql
SELECT *
FROM employees
WHERE department_id IN (
    SELECT department_id
    FROM departments
    WHERE location = 'New York'
);
```

> **Caution**: `NOT IN` with `NULL`s returns **no rows** if any `NULL` appears in the sub-query result.

### 4.3 `EXISTS` / `NOT EXISTS` (correlation, very efficient)
```sql
SELECT e.*
FROM employees e
WHERE EXISTS (
    SELECT 1
    FROM bonuses b
    WHERE b.employee_id = e.employee_id
      AND b.amount > 5000
);
```

### 4.4 Comparison with `ALL` / `ANY`
```sql
-- Employees paid more than ALL managers in dept 90
SELECT *
FROM employees
WHERE salary > ALL (
    SELECT salary
    FROM employees
    WHERE department_id = 90 AND job_title = 'Manager'
);

-- Employees paid more than ANY junior in dept 10
SELECT *
FROM employees
WHERE salary > ANY (
    SELECT salary
    FROM employees
    WHERE department_id = 10 AND years_experience < 2
);
```

### 4.5 Logical operators inside sub-query
```sql
SELECT *
FROM orders o
WHERE o.order_date > '2025-01-01'
  AND (
    o.customer_id IN (SELECT customer_id FROM vip_customers)
    OR o.total_amount > 1000
  );
```

---

## Full Working Example (All Clauses Together)

```sql
WITH yearly_sales AS (
    SELECT 
        salesperson_id,
        EXTRACT(YEAR FROM sale_date)::int AS yr,
        SUM(amount) AS total
    FROM sales
    GROUP BY salesperson_id, yr
)
SELECT 
    e.first_name,
    e.salary,
    (SELECT AVG(salary) FROM employees) AS avg_salary,
    ys.total AS y2025_sales
FROM employees e
JOIN LATERAL (
    SELECT total
    FROM yearly_sales
    WHERE salesperson_id = e.employee_id
      AND yr = 2025
) ys ON true
WHERE e.department_id = 30
  AND e.hire_date < '2024-01-01'
  AND EXISTS (
      SELECT 1 FROM promotions p
      WHERE p.employee_id = e.employee_id
        AND p.promotion_date >= '2025-01-01'
  )
  AND e.salary > ANY (SELECT salary FROM employees WHERE department_id = 10);
```

---

## Senior-Level Tips & Best Practices

| # | Tip |
|---|-----|
| **1** | **Prefer `EXISTS` over `IN`** for correlated filters – planner can use anti/semi joins (faster, especially with indexes). |
| **2** | **Avoid `NOT IN` with nullable columns** – use `NOT EXISTS` instead. |
| **3** | **Use `LATERAL` for per-row sub-queries** (top-N per group, latest record, JSON aggregation, etc.). |
| **4** | **CTE (`WITH`) > sub-query in `FROM`** for readability and reuse. |
| **5** | **Materialize heavy sub-queries** with `CREATE TEMP TABLE` or `WITH ... AS MATERIALIZED` (PostgreSQL 12+). |
| **6** | **Index correlation columns** – e.g., `CREATE INDEX ON bonuses(employee_id)` for `EXISTS (… WHERE b.employee_id = e.employee_id)`. |
| **7** | **`ANY` vs `SOME`** – they are synonyms; pick one for consistency. |
| **8** | **Scalar sub-queries in `SELECT` are executed once** if not correlated – great for constants. |
| **9** | **Use `LIMIT 1` in correlated scalar sub-queries** to hint early exit. |
| **10** | **Explain plan (`EXPLAIN (ANALYZE, BUFFERS)`) is your friend** – check for “SubPlan” vs “InitPlan”. |

---

## Quick Reference Cheat-Sheet

```sql
-- SELECT (scalar)
SELECT col, (SELECT avg(x) FROM t) AS avg_x FROM ...

-- FROM / JOIN (table sub-query)
FROM (SELECT ... ) AS alias ...

-- WHERE
WHERE col =    (SELECT ...)               -- scalar
WHERE col IN   (SELECT ...)               -- set
WHERE EXISTS   (SELECT 1 ... )            -- correlated
WHERE col > ALL (SELECT ...)              -- max
WHERE col > ANY (SELECT ...)              -- min
WHERE NOT EXISTS (SELECT 1 ...)           -- anti-join
```


##### Tags ; [[1 - SQL 🥞]]