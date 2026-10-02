
**Multiple CTEs in PostgreSQL**  
You can define **multiple Common Table Expressions (CTEs)** in a single `WITH` clause, separated by **commas**. They are evaluated in the order they appear and can **reference previously defined CTEs**.

---

## Syntax

```sql
WITH
    cte1 AS (
        SELECT ...
    ),
    cte2 AS (
        SELECT ... FROM cte1 ...
    ),
    cte3 AS (
        SELECT ... FROM cte1, cte2 ...
    )
-- Main query
SELECT ... FROM cte3 ...;
```

> **Order matters**: A CTE can only reference CTEs defined **before** it in the list.

---

## Key Rules

| Rule | Details |
|------|--------|
| **Comma-separated** | Use `,` between CTEs |
| **Sequential evaluation** | `cte1` → `cte2` → `cte3` |
| **Later CTEs can use earlier ones** | `cte3` can join `cte1` and `cte2` |
| **All CTEs share same scope** | Available in the **main query** |
| **Can be mixed**: recursive + non-recursive | But only one `RECURSIVE` keyword needed if any is recursive |

---

## Example 1: Sales Analysis (Non-Recursive)

```sql
WITH
    monthly_sales AS (
        SELECT
            DATE_TRUNC('month', sale_date) AS month,
            SUM(amount) AS total
        FROM sales
        GROUP BY 1
    ),
    top_months AS (
        SELECT month, total
        FROM monthly_sales
        WHERE total > 100000
        ORDER BY total DESC
        LIMIT 3
    ),
    avg_top AS (
        SELECT AVG(total) AS avg_top_sales
        FROM top_months
    )
SELECT
    tm.month,
    tm.total,
    at.avg_top_sales
FROM top_months tm, avg_top at;
```

**Output**:
| month       | total   | avg_top_sales |
|-------------|---------|---------------|
| 2025-03-01  | 150000  | 130000        |
| ...         | ...     | ...           |

---

## Example 2: Mixed Recursive + Non-Recursive

```sql
WITH
    -- Non-recursive: Get active employees
    active_emps AS (
        SELECT id, name, manager_id, salary
        FROM employees
        WHERE status = 'active'
    ),

    -- Recursive: Build org hierarchy from active employees only
    RECURSIVE org_hierarchy AS (
        SELECT id, name, manager_id, salary, 1 AS level
        FROM active_emps
        WHERE manager_id IS NULL

        UNION ALL

        SELECT e.id, e.name, e.manager_id, e.salary, oh.level + 1
        FROM active_emps e
        JOIN org_hierarchy oh ON e.manager_id = oh.id
    ),

    -- Non-recursive: Summary by level
    level_summary AS (
        SELECT
            level,
            COUNT(*) AS emp_count,
            AVG(salary) AS avg_salary
        FROM org_hierarchy
        GROUP BY level
    )
-- Final result
SELECT * FROM level_summary
ORDER BY level;
```

> Only **one** `RECURSIVE` keyword is needed even with multiple CTEs.

---

## Example 3: Data Cleanup with Multiple CTEs

```sql
WITH
    duplicates AS (
        SELECT
            id,
            email,
            ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_at) AS rn
        FROM users
    ),
    to_delete AS (
        SELECT id
        FROM duplicates
        WHERE rn > 1
    ),
    deleted_count AS (
        DELETE FROM users
        WHERE id IN (SELECT id FROM to_delete)
        RETURNING id
    )
SELECT COUNT(*) AS deleted_rows FROM deleted_count;
```

> Uses CTEs for **filtering → identifying → deleting → counting**

---

## Example 4: Reusing CTEs in Multiple Branches

```sql
WITH
    high_value_customers AS (
        SELECT customer_id, SUM(amount) AS total_spent
        FROM orders
        GROUP BY customer_id
        HAVING SUM(amount) > 5000
    )
-- Use the same CTE twice
SELECT 'VIP' AS type, COUNT(*) FROM high_value_customers
UNION ALL
SELECT 'Details', COUNT(DISTINCT o.product_id)
FROM orders o
JOIN high_value_customers hvc ON o.customer_id = hvc.customer_id;
```

---

## Best Practices

| Practice | Why |
|--------|-----|
| **Name CTEs meaningfully** | `monthly_sales`, not `cte1` |
| **Keep CTEs focused** | One logical step per CTE |
| **Use indentation** | Improves readability |
| **Reference earlier CTEs only** | Avoid forward references |
| **Use `MATERIALIZED` if expensive & reused** | Prevent recomputation |

```sql
WITH
    sales_agg AS MATERIALIZED (
        SELECT customer_id, SUM(amount) FROM orders GROUP BY 1
    ),
    top_10 AS (
        SELECT * FROM sales_agg ORDER BY 2 DESC LIMIT 10
    )
SELECT * FROM top_10;
```

---

## What You **Cannot** Do

| Invalid | Reason |
|--------|--------|
| `cte2` references `cte3` | Forward reference not allowed |
| Reuse CTEs across statements | Scope is **one query only** |
| `WITH cte1 AS (...); WITH cte2 AS (...)` | Only **one** `WITH` per query |

---

## Visual Flow of Multiple CTEs

```
WITH
  ┌─────────────┐
  │   cte1      │ ← Base data
  └──────┬──────┘
         ↓
  ┌──────┴──────┐
  │   cte2      │ ← Uses cte1
  └──────┬──────┘
         ↓
  ┌──────┴──────┐
  │   cte3      │ ← Uses cte1 + cte2
  └──────┬──────┘
         ↓
   Main Query
```

---

## Summary

| Feature | Supported? |
|-------|-----------|
| Multiple CTEs | Yes |
| Reference previous CTEs | Yes |
| Mix recursive & non-recursive | Yes (one `RECURSIVE` keyword) |
| Reuse CTEs in main query | Yes |
| Forward references | No |

---

**Pro Tip**:  
Think of multiple CTEs as **building blocks** — each transforms or filters data for the next step, making complex logic **readable, reusable, and maintainable**.

```sql
-- Clean, modular, powerful
WITH a AS (...), b AS (...), c AS (...) SELECT ... FROM c;
```

##### Tags : [[1 - SQL 🦬]]