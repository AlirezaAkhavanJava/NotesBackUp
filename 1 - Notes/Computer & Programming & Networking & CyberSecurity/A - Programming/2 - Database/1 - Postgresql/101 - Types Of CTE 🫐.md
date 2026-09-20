
In **PostgreSQL**, **Common Table Expressions (CTEs)** are classified into **two main types** based on their behavior and usage:

---

## 1. **Non-Recursive CTE**  
*(Most common type)*

A regular CTE that defines a **temporary named result set** using a standard subquery. It does **not** reference itself.

### Syntax
```sql
WITH cte_name AS (
    SELECT ...
)
SELECT ... FROM cte_name;
```

### Characteristics
- Executes **once** per query.
- Can be referenced **multiple times** in the main query.
- Improves **readability** and **modularity**.
- Cannot reference itself.

### Example
```sql
WITH active_users AS (
    SELECT id, name
    FROM users
    WHERE status = 'active'
)
SELECT * FROM active_users WHERE name LIKE 'A%';
```

> **Use Case**: Break complex queries into logical steps, avoid repeating subqueries.

---

## 2. **Recursive CTE**  
*(Special type for hierarchical or iterative data)*

A CTE that **references itself** to process hierarchical, tree-like, or sequential data.

### Syntax
```sql
WITH RECURSIVE cte_name AS (
    -- Anchor member (base case)
    SELECT ...

    UNION ALL

    -- Recursive member (references cte_name)
    SELECT ... FROM cte_name ...
)
SELECT ... FROM cte_name;
```

### Key Rules
- Must use **`WITH RECURSIVE`**
- Must use **`UNION ALL`** (not `UNION`)
- Must have **two parts**:
  1. **Anchor member** – non-recursive starting point
  2. **Recursive member** – joins back to the CTE
- PostgreSQL **prevents infinite loops** by limiting recursion depth (default: no hard limit, but monitor performance).

---

### Example: Employee Hierarchy
```sql
WITH RECURSIVE emp_tree AS (
    -- Anchor: CEOs (no manager)
    SELECT id, name, manager_id, 1 AS level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive: Employees reporting to previous level
    SELECT e.id, e.name, e.manager_id, et.level + 1
    FROM employees e
    JOIN emp_tree et ON e.manager_id = et.id
)
SELECT * FROM emp_tree ORDER BY level;
```

---

## Bonus: **Materialization Variants** (PostgreSQL 12+)

While not a "type" of CTE, you can control **how** a CTE is executed:

| Variant | Behavior |
|--------|---------|
| `AS MATERIALIZED` | CTE is computed **once** and stored temporarily (like a temp table). Best when reused. |
| `AS NOT MATERIALIZED` | CTE may be **inlined** into the query plan (optimizer choice). Best for one-time use. |

### Example
```sql
WITH sales_summary AS MATERIALIZED (
    SELECT region, SUM(amount) FROM sales GROUP BY region
)
SELECT * FROM sales_summary WHERE region = 'West';
```

> **Note**: This is **not a new type** of CTE — just an **optimization hint**.

---

## Summary: Types of CTEs in PostgreSQL

| Type | Keyword | Self-Referencing? | Use Case |
|------|--------|-------------------|---------|
| **Non-Recursive CTE** | `WITH` | No | Modular queries, reuse logic |
| **Recursive CTE** | `WITH RECURSIVE` | Yes | Trees, graphs, sequences |

---

## Common Recursive CTE Patterns

| Pattern | Example |
|-------|--------|
| **Hierarchy traversal** | Org charts, categories |
| **Series generation** | Numbers, dates, time ranges |
| **Graph path finding** | Shortest path, reachability |
| **Bill of Materials (BOM)** | Product assemblies |
| **Cumulative sums** | Running totals over time |

---

### Quick Cheat Sheet

```sql
-- 1. Non-Recursive
WITH cte AS (SELECT ...) 
SELECT ...;

-- 2. Recursive
WITH RECURSIVE cte AS (
    SELECT ...                -- Anchor
    UNION ALL
    SELECT ... FROM cte ...   -- Recursive step
)
SELECT ...;
```

---

**Bottom Line**:  
There are **only two fundamental types** of CTEs in PostgreSQL:

> **Non-Recursive** — for clarity and reuse  
> **Recursive** — for hierarchical and iterative logic

Everything else (materialization, multiple CTEs, etc.) is a **feature**, not a type.

##### Tags : [[1 - SQL 🥞]]