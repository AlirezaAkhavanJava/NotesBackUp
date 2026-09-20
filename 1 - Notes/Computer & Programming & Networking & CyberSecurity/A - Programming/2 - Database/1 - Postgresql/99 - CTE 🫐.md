
**CTE (Common Table Expression) in PostgreSQL**

A **Common Table Expression (CTE)** is a temporary result set that you can reference within a `SELECT`, `INSERT`, `UPDATE`, or `DELETE` statement.

It is defined using the `WITH` clause and improves query readability and modularity, especially for complex queries.

---
###### Alireza : 
>A _temporary, named result set_ (like a **virtual table**) that doesn’t exist in the database but is built from one or more real tables during query execution.


>CTE is a representation of a table that does not exist in the database but made of one or more tables that exist in a database and can be treated as a normal temporarly table

---
### Basic Syntax

```sql
WITH cte_name (column1, column2, ...) AS (
    -- Subquery that returns a result set
    SELECT ...
)
-- Main query that can reference the CTE
SELECT ... FROM cte_name ...;
```

- The CTE is **not stored** — it exists only for the duration of the query.
- You can define **multiple CTEs** in a single `WITH` clause, separated by commas.

---

### Example 1: Simple CTE

```sql
WITH high_salary_employees AS (
    SELECT id, name, salary
    FROM employees
    WHERE salary > 70000
)
SELECT * FROM high_salary_employees
ORDER BY salary DESC;
```

This CTE filters employees with high salaries and is then used in the main query.

---

### Example 2: Multiple CTEs

```sql
WITH 
regional_sales AS (
    SELECT region, SUM(amount) AS total_sales
    FROM sales
    GROUP BY region
),
top_regions AS (
    SELECT region, total_sales
    FROM regional_sales
    WHERE total_sales > 100000
)
SELECT * FROM top_regions;
```

---

### Recursive CTE (for hierarchical or tree-like data)

Used to query recursive data (e.g., organizational charts, file systems, graph traversal).

```sql
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: top-level employees (no manager)
    SELECT id, name, manager_id, 1 AS level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case: join with employees who report to the previous level
    SELECT e.id, e.name, e.manager_id, eh.level + 1
    FROM employees e
    INNER JOIN employee_hierarchy eh ON e.manager_id = eh.id
)
SELECT * FROM employee_hierarchy
ORDER BY level, name;
```

> **Note**: Use `WITH RECURSIVE` for recursive queries. PostgreSQL detects infinite loops and limits recursion depth.

---

### Key Features

| Feature | Description |
|--------|-------------|
| **Readability** | Breaks complex queries into logical parts |
| **Reusability** | CTE can be referenced multiple times in the same query |
| **Recursion** | Supports `WITH RECURSIVE` for hierarchical data |
| **Materialization (Optional)** | Use `MATERIALIZED` or `NOT MATERIALIZED` (PostgreSQL 12+) to control optimization |

---

### Materialization Control (PostgreSQL 12+)

```sql
WITH cte_name AS MATERIALIZED (
    SELECT ...
)
SELECT ...;
```

- `MATERIALIZED`: Forces the CTE to be computed once and stored temporarily.
- `NOT MATERIALIZED`: Allows the optimizer to inline the CTE (default in many cases).

---

### Limitations

- CTEs are **not reusable across multiple queries** (unlike views or temp tables).
- Each CTE is executed **once per query**, even if referenced multiple times (unless optimized away with `NOT MATERIALIZED`).
- Recursive CTEs must have `UNION ALL` (not `UNION`).

---

### Summary

> A **CTE in PostgreSQL** is a named temporary result set defined with `WITH` that improves query clarity, supports recursion, and can be referenced in the following main statement. It's especially powerful for hierarchical data and complex analytical queries.
---


Here’s the clear difference between **CTE** and **Subquery** 

|Feature|**CTE (Common Table Expression)**|**Subquery**|
|---|---|---|
|**Readability**|Easier to read — you name the result (`WITH cte_name AS (...)`)|Harder to read — nested inside main query|
|**Reusability**|Can be used **multiple times** in the same query|Can be used **only once** where written|
|**Recursion**|Supports **recursive queries**|Cannot do recursion|
|**Optimization**|Often optimized like a view (depends on DB engine)|Usually inlined into main query|
|**Lifetime**|Exists only during that query|Exists only within its parent query|
|**Use case**|For complex queries, hierarchical data, or clarity|For small, one-off computations|

### Example of Both:

**CTE:**

```sql
WITH high_rated AS (
    SELECT title, rating FROM movies WHERE rating > 8
)
SELECT * FROM high_rated WHERE title LIKE 'T%';
```

**Subquery:**

```sql
SELECT * 
FROM (
    SELECT title, rating FROM movies WHERE rating > 8
) AS high_rated
WHERE title LIKE 'T%';
```

➡️ **Same result**, but CTE is cleaner and can be reused later in the same query.


##### Tags : [[1 - SQL 🥞]]