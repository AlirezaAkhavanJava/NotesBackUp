
**Nested CTEs in PostgreSQL**  
While **PostgreSQL does not support CTEs *inside* other CTEs** (i.e., you **cannot** write a `WITH` clause inside another `WITH`), you can **simulate nesting** using **multiple CTEs in sequence** — each building on the previous one.

---

## What **Does NOT Work** (Invalid Syntax)

```sql
-- NOT ALLOWED in PostgreSQL
WITH outer_cte AS (
    WITH inner_cte AS (
        SELECT * FROM users WHERE active = true
    )
    SELECT * FROM inner_cte WHERE age > 30
)
SELECT * FROM outer_cte;
```

> **Error**: `ERROR: syntax error at or near "WITH"`

PostgreSQL **only allows one `WITH` clause per statement**, and it must be at the **top level**.

---

## Correct Way: **Sequential (Layered) CTEs**

Use **multiple CTEs in a single `WITH` clause**, where each CTE references the one(s) before it.

```sql
WITH
    active_users AS (
        SELECT id, name, age, email
        FROM users
        WHERE active = true
    ),
    adult_users AS (
        SELECT id, name, email
        FROM active_users
        WHERE age > 30
    ),
    premium_adults AS (
        SELECT au.*, 'Premium' AS tier
        FROM adult_users au
        JOIN subscriptions s ON au.id = s.user_id
        WHERE s.plan = 'premium'
    )
-- Main query
SELECT * FROM premium_adults
ORDER BY name;
```

This is **functionally equivalent** to "nested" CTEs.

---

## Visual: "Nested" Logic via Sequential CTEs

```
WITH
  ┌────────────────────┐
  │ active_users       │ ← Base filter
  └─────────▲──────────┘
            │
  ┌─────────▼──────────┐
  │ adult_users        │ ← Filters active_users
  └─────────▲──────────┘
            │
  ┌─────────▼──────────┐
  │ premium_adults     │ ← Filters adult_users + join
  └─────────▲──────────┘
            │
      Main Query
```

---

## Real-World Example: Sales Funnel Analysis

```sql
WITH
    -- Step 1: All website visits
    visits AS (
        SELECT user_id, visit_date
        FROM web_visits
        WHERE visit_date >= '2025-01-01'
    ),

    -- Step 2: Users who signed up (nested filter)
    signups AS (
        SELECT v.user_id, v.visit_date AS signup_date
        FROM visits v
        JOIN users u ON v.user_id = u.id
        WHERE u.created_at >= v.visit_date
    ),

    -- Step 3: Users who made a purchase (nested filter + join)
    purchasers AS (
        SELECT s.user_id, s.signup_date, MIN(o.order_date) AS first_order
        FROM signups s
        JOIN orders o ON s.user_id = o.user_id
        GROUP BY s.user_id, s.signup_date
    ),

    -- Step 4: High-value purchasers
    high_value AS (
        SELECT p.*, o.total_amount
        FROM purchasers p
        JOIN orders o ON p.user_id = o.user_id AND p.first_order = o.order_date
        WHERE o.total_amount > 100
    )

-- Final result
SELECT
    COUNT(*) AS total_high_value,
    AVG(total_amount) AS avg_order_value
FROM high_value;
```

Each CTE is a **layer** on top of the previous — this is **"nesting" in practice**.

---

## Advanced: Recursive + Non-Recursive "Nesting"

```sql
WITH
    -- Base: Active employees
    active_emps AS (
        SELECT * FROM employees WHERE status = 'active'
    ),

    -- Recursive: Build hierarchy from active only
    RECURSIVE hierarchy AS (
        SELECT id, name, manager_id, 1 AS level
        FROM active_emps
        WHERE manager_id IS NULL

        UNION ALL

        SELECT e.id, e.name, e.manager_id, h.level + 1
        FROM active_emps e
        JOIN hierarchy h ON e.manager_id = h.id
    ),

    -- Final aggregation on hierarchy
    level_stats AS (
        SELECT
            level,
            COUNT(*) AS employees,
            AVG(salary) AS avg_salary
        FROM hierarchy
        JOIN active_emps ae ON hierarchy.id = ae.id
        GROUP BY level
    )

SELECT * FROM level_stats ORDER BY level;
```

---

## Alternative: Subquery in CTE (True Nesting Inside Query)

You **can** nest subqueries **inside** a CTE:

```sql
WITH user_stats AS (
    SELECT
        u.id,
        u.name,
        (
            SELECT COUNT(*) 
            FROM orders o 
            WHERE o.user_id = u.id
        ) AS order_count
    FROM users u
    WHERE u.active = true
)
SELECT * FROM user_stats WHERE order_count > 5;
```

This is **allowed** — because the nesting is in the `SELECT` clause, not in a `WITH`.

---

## Best Practices for "Nested" CTEs

| Practice | Why |
|--------|-----|
| **One transformation per CTE** | Keeps logic clear |
| **Name CTEs by purpose** | `active_users`, not `cte1` |
| **Use indentation** | Improves readability |
| **Avoid deep chains unless necessary** | Too many layers → hard to debug |
| **Materialize expensive intermediate CTEs** | Use `AS MATERIALIZED` |

```sql
WITH
    sales_2025 AS MATERIALIZED (
        SELECT * FROM sales WHERE YEAR(sale_date) = 2025
    ),
    monthly_totals AS (
        SELECT DATE_TRUNC('month', sale_date) AS month, SUM(amount)
        FROM sales_2025
        GROUP BY 1
    )
SELECT * FROM monthly_totals;
```

---

## Summary: "Nested" CTEs in PostgreSQL

| Concept | Supported? | How |
|-------|-----------|-----|
| `WITH` inside `WITH` | No | Not allowed |
| Sequential CTEs (layered) | Yes | **Recommended** |
| Subquery inside CTE | Yes | Use scalar or correlated subqueries |
| Recursive + non-recursive | Yes | One `RECURSIVE` keyword |

---

## Final Pattern: Clean "Nested" Logic

```sql
WITH
    step1_filtered_data AS (...),
    step2_transformed AS (SELECT ... FROM step1_filtered_data ...),
    step3_joined AS (SELECT ... FROM step2_transformed JOIN ...),
    step4_aggregated AS (SELECT ... FROM step3_joined GROUP BY ...)
SELECT * FROM step4_aggregated;
```

> This is **as close as you get to nested CTEs** — and it’s **cleaner, faster, and standard**.

---

**Bottom Line**:  
> **No true nested `WITH` clauses**  
> **Yes Use sequential CTEs to simulate nesting**  
> **Yes This is the idiomatic and recommended way**

Think of it as **pipeline processing**, not nesting.

##### Tags : [[1 - SQL 🥞]]