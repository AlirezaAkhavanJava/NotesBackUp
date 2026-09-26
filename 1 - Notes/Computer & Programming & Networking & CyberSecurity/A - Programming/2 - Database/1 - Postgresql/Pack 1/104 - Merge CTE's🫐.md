**Merging CTEs in PostgreSQL**  
You can't literally merge CTEs with a keyword, but you **can (and should)** combine them to eliminate redundancy and improve performance.

### Why Merge?
- Avoid repeating the same logic/filters
- Prevent multiple table scans
- Make queries cleaner and faster

### Best Techniques

**1. Combine with `UNION ALL` in one CTE** (most common)
```sql
WITH user_segments AS (
    SELECT id, 'high_spender' AS segment
    FROM users u JOIN orders o ON u.id = o.user_id
    GROUP BY id HAVING SUM(amount) > 10000
    UNION ALL
    SELECT id, 'frequent'
    FROM users u JOIN visits v ON u.id = v.user_id
    GROUP BY id HAVING COUNT(*) > 50
)
SELECT * FROM user_segments;
```

**2. Extract shared filters**
```sql
-- Instead of two identical date filters:
WITH monthly AS (
    SELECT * FROM sales
    WHERE sale_date >= '2025-01-01' AND sale_date < '2025-02-01'
),
summary AS (SELECT SUM(amount), COUNT(DISTINCT customer_id) FROM monthly)
SELECT * FROM summary;
```

**3. Push filters into recursive CTEs**
```sql
WITH RECURSIVE hierarchy AS (
    SELECT id, manager_id, 1 AS lvl
    FROM employees
    WHERE manager_id IS NULL AND active
    UNION ALL
    SELECT e.id, e.manager_id, h.lvl + 1
    FROM employees e JOIN hierarchy h ON e.manager_id = h.id
    WHERE e.active
)
SELECT * FROM hierarchy;
```

**4. Replace sequential CTEs with `LATERAL` (often faster)**
```sql
SELECT p.*, tp.sales
FROM products p
CROSS JOIN LATERAL (
    SELECT SUM(amount) AS sales
    FROM orders o WHERE o.product_id = p.id
    GROUP BY o.product_id
    ORDER BY 1 DESC LIMIT 5
) tp;
```

### When NOT to Merge
- CTE is reused in multiple places → keep it + consider `MATERIALIZED`
```sql
WITH expensive AS MATERIALIZED (SELECT … heavy work …)
SELECT … FROM expensive WHERE …
UNION ALL
SELECT … FROM expensive WHERE …;
```
- Logic is conceptually very different → readability > merging

### Quick Rules
| Do Merge                  | Keep Separate                  |
|---------------------------|--------------------------------|
| Same table + similar filters | Reused in multiple queries     |
| Overlapping conditions      | Marked as MATERIALIZED         |
| Building segments/unions     | Very different business meaning |

**Bottom line**:  
**Merge aggressively when logic overlaps. One well-designed CTE almost always beats many small ones.**


###### Tags : [[1 - SQL 🦬]]