
Below is a **concise, authoritative cheat-sheet of the exact rules** that PostgreSQL enforces when you place a **sub-query** in each of the four clauses (`SELECT`, `FROM`, `JOIN`, `WHERE`).  
Think of it as the **grammar + type-system contract** you must obey or the planner will raise an error.

---

## 1. Sub-query in **`SELECT`**

| Rule | What PostgreSQL checks | Error if violated |
|------|------------------------|-------------------|
| **Scalar only** | Must return **exactly 1 row, 1 column** (or `NULL`) | `ERROR:  more than one row returned by a subquery used as an expression` |
| **No ORDER BY** allowed unless `LIMIT 1` | `ORDER BY` inside scalar sub-query is ignored unless paired with `LIMIT`/`FETCH FIRST` | Warning (ignored) |
| **Correlation allowed** | Can reference outer tables → executed **per row** | — |
| **Data-type compatibility** | Result type must be assignable to the target column/expression | Type mismatch error |

```sql
-- OK: scalar
SELECT salary, (SELECT AVG(salary) FROM employees) FROM employees;

-- ERROR: returns 10 rows
SELECT (SELECT department_id FROM departments) FROM employees;
```

---

## 2. Sub-query in **`FROM`** (Derived Table)

| Rule | Requirement | Error |
|------|-------------|-------|
| **Must have an alias** | `AS alias` or `AS alias(col1, col2, …)` | `ERROR: subquery in FROM must have an alias` |
| **Any number of rows/columns** | Acts like a real table | — |
| **Column names** | If not aliased, taken from sub-query `SELECT` list | — |
| **Correlation allowed** | Can reference outer tables **only via `LATERAL`** | `ERROR: subquery references outer query without LATERAL` |

```sql
-- OK
FROM (SELECT dept_id, COUNT(*) FROM emp GROUP BY dept_id) AS e

-- ERROR: missing alias
FROM (SELECT dept_id FROM departments)

-- OK with LATERAL (correlated)
FROM employees e
LEFT JOIN LATERAL (SELECT * FROM bonuses b WHERE b.emp_id = e.id LIMIT 1) b ON true
```

---

## 3. Sub-query in **`JOIN`**

| Rule | Detail |
|------|--------|
| **Same rules as `FROM`** | Must be a **table sub-query** with alias |
| **Can be `INNER`, `LEFT`, `RIGHT`, `FULL`, `CROSS`** | Same join semantics |
| **`LATERAL` required for correlation** | Without `LATERAL`, outer references are illegal |

```sql
-- OK
INNER JOIN (SELECT salesperson_id, SUM(amount) AS total FROM sales GROUP BY 1) s
  ON e.id = s.salesperson_id

-- OK: correlated
LEFT JOIN LATERAL (
    SELECT review FROM reviews WHERE emp_id = e.id ORDER BY date DESC LIMIT 1
) r ON true
```

---

## 4. Sub-query in **`WHERE`**

| Operator | Sub-query must return | Rule |
|----------|-----------------------|------|
| **Comparison** (`=`, `>`, `<`, `>=`, `<=`, `<>`) | **0 or 1 row, 1 column** (scalar) | >1 row → error |
| **`IN` / `NOT IN`** | **Any number of rows, 1 column** | `NULL` in list makes `NOT IN` return **no rows** |
| **`EXISTS` / `NOT EXISTS`** | **Any number of rows/columns** (result ignored) | Use `SELECT 1` convention |
| **`ANY` / `SOME`** | **Any number of rows, 1 column** | Compares with each value |
| **`ALL`** | **Any number of rows, 1 column** | Compares with every value |
| **Logical (`AND`, `OR`, `NOT`)** | Can wrap any of the above | No special rule |

### Detailed Error Cases

```sql
-- ERROR: >1 row
WHERE salary > (SELECT salary FROM employees WHERE dept = 10)

-- OK: force scalar
WHERE salary > (SELECT MAX(salary) FROM employees WHERE dept = 10)

-- NOT IN pitfall
WHERE dept NOT IN (SELECT dept FROM depts WHERE region IS NULL)  -- returns 0 rows!

-- Use NOT EXISTS instead
WHERE NOT EXISTS (SELECT 1 FROM depts d WHERE d.dept = e.dept AND d.region IS NULL)
```

---

## Universal Rules (Apply to **All** Sub-queries)

| # | Rule |
|---|------|
| 1 | **No `ORDER BY` unless `LIMIT`/`OFFSET`** (except in `FROM`/`JOIN` where it’s allowed) |
| 2 | **Sub-query cannot reference variables from `WITH` unless in same `WITH` clause** |
| 3 | **Set-returning functions (SRFs) in `SELECT` require `LATERAL` or `FROM`** |
| 4 | **Aggregate + window functions allowed inside sub-queries** |
| 5 | **Recursive CTEs only allowed in `WITH`, not inline sub-queries** |

---

## Summary Table: “What Can Go Where?”

| Clause | Allowed Return | Correlation? | Must Alias? | Typical Operator |
|--------|----------------|--------------|-------------|------------------|
| `SELECT` | **1×1** (scalar) | Yes | No | `=`, `>`, `-`, etc. |
| `FROM`   | **N×M** (table)  | Only with `LATERAL` | **YES** | — |
| `JOIN`   | **N×M** (table)  | Only with `LATERAL` | **YES** | `ON`, `USING` |
| `WHERE`  | Varies by operator | Yes | No | `IN`, `EXISTS`, `ANY`, `ALL`, `=` |

---

### One-Liner Rule to Remember:
> **“One value → `SELECT`. One table → `FROM`/`JOIN` + alias. Filter → `WHERE` + right operator.”**

Stick to this table and PostgreSQL will **never** throw a sub-query syntax error.

##### Tags : [[1 - SQL 🦬]]