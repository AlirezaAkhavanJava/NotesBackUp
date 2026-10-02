
Here’s a comprehensive guide to **CTE (Common Table Expression) syntax rules and common usages in PostgreSQL**:

---

## 1. **Basic Syntax Rules**

```sql
[WITH [RECURSIVE]]
    cte_name [(column_name [, ...])] AS [MATERIALIZED | NOT MATERIALIZED] (
        query
    ) [, ...]
main_query;
```

### Components Explained

| Part | Required? | Description |
|------|----------|-----------|
| `WITH` | Yes | Starts the CTE definition |
| `RECURSIVE` | Optional | Enables recursive queries |
| `cte_name` | Yes | Name of the CTE (must be unique in the query) |
| `(column_list)` | Optional | Explicit column names (must match query result) |
| `AS (...)` | Yes | Subquery that defines the CTE |
| `MATERIALIZED` / `NOT MATERIALIZED` | Optional (PostgreSQL 12+) | Controls optimization |
| Comma-separated CTEs | Optional | Multiple CTEs allowed |
| `main_query` | Yes | Must reference at least one CTE (or be valid standalone) |

---

## 2. **Core Syntax Rules**

| Rule | Example / Explanation |
|------|-----------------------|
| **CTE must be followed by a main query** | `WITH cte AS (SELECT 1) SELECT * FROM cte;` |
| **Column names**: If not specified, inherited from subquery | `WITH cte AS (SELECT id, name FROM users) ...` |
| **Explicit column list** (optional but useful) | `WITH cte(id, full_name) AS (SELECT user_id, first_name || ' ' || last_name FROM users)` |
| **Multiple CTEs** separated by commas | `WITH cte1 AS (...), cte2 AS (...) SELECT ...` |
| **CTEs can reference previous CTEs** | `WITH a AS (...), b AS (SELECT * FROM a WHERE ...) ...` |
| **Recursive CTEs require `UNION ALL`** | `UNION` removes duplicates → breaks recursion |
| **No `ORDER BY` in CTE** unless with `LIMIT` | Invalid: `WITH cte AS (SELECT * FROM t ORDER BY x)`<br>Valid: `WITH cte AS (SELECT * FROM t ORDER BY x LIMIT 10)` |

---

## 3. **Common Usages & Examples**

---

### 1. **Improve Readability (Modular Queries)**

```sql
WITH sales_summary AS (
    SELECT 
        region,
        SUM(amount) AS total,
        AVG(amount) AS avg_sale
    FROM sales
    GROUP BY region
),
top_regions AS (
    SELECT region, total
    FROM sales_summary
    WHERE total > 50000
)
SELECT * FROM top_regions
ORDER BY total DESC;
```

> **Use case**: Break complex logic into logical steps.

---

### 2. **Avoid Repeating Subqueries**

```sql
WITH expensive_items AS (
    SELECT * FROM products WHERE price > 1000
)
SELECT * FROM expensive_items WHERE category = 'Electronics'
UNION ALL
SELECT * FROM expensive_items WHERE in_stock = false;
```

> **Use case**: Reuse the same filtered dataset multiple times.

---

### 3. **Recursive CTE: Hierarchical Data (Org Chart)**

```sql
WITH RECURSIVE org_chart AS (
    -- Anchor: Top-level employees
    SELECT id, name, manager_id, 0 AS depth
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive: Reportees
    SELECT e.id, e.name, e.manager_id, oc.depth + 1
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.id
)
SELECT * FROM org_chart
ORDER BY depth, name;
```

> **Use case**: Trees, graphs, bill of materials, file systems.

---

### 4. **Recursive CTE: Generate Series (Numbers, Dates)**

```sql
WITH RECURSIVE numbers(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 10
)
SELECT * FROM numbers;
```

```sql
-- Generate dates from Jan 1 to Jan 10, 2025
WITH RECURSIVE date_series AS (
    SELECT DATE '2025-01-01' AS day
    UNION ALL
    SELECT day + 1 FROM date_series WHERE day < '2025-01-10'
)
SELECT * FROM date_series;
```

> **Use case**: Fill missing dates, generate sequences.

---

### 5. **Data Cleanup / Deduplication**

```sql
WITH duplicates AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_at) AS rn
    FROM users
),
to_delete AS (
    SELECT id FROM duplicates WHERE rn > 1
)
DELETE FROM users
WHERE id IN (SELECT id FROM to_delete);
```

> **Use case**: Remove duplicates safely.

---

### 6. **Recursive Path Traversal (Graph)**

```sql
WITH RECURSIVE paths AS (
    SELECT start_node, end_node, ARRAY[start_node] AS path, 0 AS hops
    FROM graph
    WHERE start_node = 'A'

    UNION ALL

    SELECT g.start_node, g.end_node, path || g.end_node, hops + 1
    FROM graph g
    JOIN paths p ON g.start_node = p.end_node
    WHERE g.end_node <> ALL(path)  -- Avoid cycles
)
SELECT * FROM paths WHERE end_node = 'Z';
```

> **Use case**: Find all paths in a directed graph.

---

### 7. **Materialization Control (PostgreSQL 12+)**

```sql
-- Force CTE to be computed once (useful if expensive)
WITH regional_sales AS MATERIALIZED (
    SELECT region, SUM(amount) FROM sales GROUP BY region
)
SELECT * FROM regional_sales WHERE region = 'North';

-- Allow optimizer to inline (default in many cases)
WITH regional_sales AS NOT MATERIALIZED (
    SELECT region, SUM(amount) FROM sales GROUP BY region
)
SELECT * FROM regional_sales;
```

> **Use case**: Performance tuning.

---

## 4. **Best Practices**

| Practice | Why |
|--------|-----|
| Use **meaningful CTE names** | Improves readability |
| **Limit CTE scope** | Only include needed columns |
| Use `MATERIALIZED` for **expensive CTEs reused multiple times** | Avoid recomputation |
| Use `NOT MATERIALIZED` for **simple CTEs used once** | Let optimizer inline |
| Always **test recursive CTEs** with small data | Prevent infinite loops |
| Use `WHERE ... <> ALL(path)` in graphs | Avoid cycles |

---

## 5. **What You *Cannot* Do**

| Invalid | Reason |
|-------|--------|
| `WITH cte AS (...) INSERT INTO ...` without main query | CTE requires a statement |
| Reuse CTE across multiple statements | Scope is one query only |
| `ORDER BY` in CTE without `LIMIT` | Not allowed by parser |
| `UNION` in recursive CTE | Breaks recursion (use `UNION ALL`) |

---

## Summary: When to Use CTEs

| Use Case | Recommended |
|--------|-------------|
| Complex reporting queries | Yes |
| Hierarchical/tree data | Yes (Recursive) |
| Reusing subquery logic | Yes |
| Generating sequences/dates | Yes |
| Data cleanup (DELETE/UPDATE) | Yes |
| Replacing messy nested subqueries | Yes |
| Performance-critical reusable views | No → Use **materialized views** |

---

**Pro Tip**: CTEs are **not** a performance magic bullet — they’re for **clarity**. Use `EXPLAIN` to check execution plans.

Let PostgreSQL decide materialization unless you have a specific reason to control it.

##### Tags : [[1 - SQL 🦬]]