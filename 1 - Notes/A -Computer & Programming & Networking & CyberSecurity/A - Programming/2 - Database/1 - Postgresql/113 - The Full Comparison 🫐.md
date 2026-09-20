
# **PostgreSQL: Subquery, CTE, Temp Table, CTE AS, View — The Full Comparison**

You're looking at **one of the most important diagrams** in SQL performance and architecture. Let's **decode it line by line** and turn you into a **master of temporary data structures** in PostgreSQL.

---

## **The Big Picture: 5 Ways to Reuse Query Logic**

| Structure | Full Name | When to Use |
|---------|----------|-------------|
| **Subquery** | Inline nested `SELECT` | One-off, simple reuse |
| **CTE** | Common Table Expression (`WITH`) | Readable, reusable in one query |
| **TMP** | Temporary Table | Multi-query, session-long data |
| **CTAS** | CREATE TABLE AS SELECT | Save query result permanently or reuse |
| **VIEW** | Virtual Table | Reusable, always up-to-date logic |

---

## **1. STORAGE: Where Does the Data Live?**

| | Subquery | CTE | TMP | CTAS | View |
|---|---------|-----|-----|------|------|
| **Storage** | Memory | Memory | Disk | Disk | No Storage |
| **Icon** | Paper | Paper | Hard Disk | Hard Disk | Cross |
| **Performance** | Fastest | Fast | Slower | Slower | Fastest (no data) |

> **Key Insight**:  
> - **Subquery & CTE** → **In-memory**, no disk I/O  
> - **TMP & CTAS** → **On disk**, slower but durable  
> - **View** → **No data stored**, just a saved query

---

## **2. LIFE TIME: How Long Does It Live?**

| | Subquery | CTE | TMP | CTAS | View |
|---|---------|-----|-----|------|------|
| **Lifetime** | **Temporary** | **Temporary** | **Permanent** | **Permanent** | **Permanent** |
| **Duration** | One query | One query | Session | Until DROP | Until DROP |

> **Key Insight**:  
> - **Subquery & CTE** die when the query ends  
> - **TMP** lives until you **log out**  
> - **CTAS & View** live **forever** (until dropped)

---

## **3. WHEN DELETED: When Is It Gone?**

| | Subquery | CTE | TMP | CTAS | View |
|---|---------|-----|-----|------|------|
| **Deleted** | End of Query | End of Query | End of Session | DDL: `DROP TABLE` | DDL: `DROP VIEW` |

```sql
-- TMP auto-deleted on disconnect
CREATE TEMP TABLE my_tmp AS SELECT ...;

-- CTAS & VIEW need explicit DROP
DROP TABLE my_ctas;
DROP VIEW my_view;
```

---

## **4. SCOPE: Who Can See It?**

| | Subquery | CTE | TMP | CTAS | View |
|---|---------|-----|-----|------|------|
| **Scope** | Single Query | Single Query | Multi-Queries | Multi-Queries | Multi-Queries |
| **Icon** | One arrow | One arrow | Long arrow | Long arrow | Long arrow |

> **Key Insight**:  
> - **Subquery & CTE**: Only usable **in the same `SELECT`**  
> - **TMP, CTAS, View**: Usable in **many queries in the same session**

---

## **5. REUSABILITY: Can I Use It Again?**

| | Subquery | CTE | TMP | CTAS | View |
|---|---------|-----|-----|------|------|
| **Reusability** | Limited | Limited | Medium | High | **High** |
| **Details** | 1 place, 1 query | Multiple places, 1 query | Multi-queries in session | Multi-queries forever | Multi-queries forever |

```sql
-- CTE: Reuse in same query
WITH sales AS (SELECT * FROM orders WHERE amount > 100)
SELECT * FROM sales WHERE region = 'EU'
UNION ALL
SELECT * FROM sales WHERE region = 'US';
```

```sql
-- TMP: Reuse across queries
CREATE TEMP TABLE top_customers AS ...
SELECT * FROM top_customers;
-- Later in same session:
INSERT INTO top_customers SELECT ...;
```

---

## **6. UP2DATE: Is Data Always Fresh?**

| | Subquery | CTE | TMP | CTAS | View |
|---|---------|-----|-----|------|------|
| **Up to Date?** | Yes | Yes | No | No | Yes |
| **Icon** | Green Check | Green Check | Red Cross | Red Cross | Green Check |

> **HUGE Insight**:  
> - **Subquery, CTE, View** → **Always reflect latest data**  
> - **TMP & CTAS** → **Snapshot in time** (data gets stale)

```sql
-- View: Always fresh
CREATE VIEW active_users AS
SELECT * FROM users WHERE status = 'active';

-- Later: someone updates users → view reflects it
```

```sql
-- CTAS: Frozen in time
CREATE TABLE user_snapshot AS
SELECT * FROM users WHERE created_at > '2025-01-01';

-- Later updates to users → NOT in snapshot
```

---

## **Summary Table (Memorize This!)**

| Feature | Subquery | CTE | Temp Table | CTAS | View |
|--------|----------|-----|------------|------|------|
| **Storage** | Memory | Memory | Disk | Disk | None |
| **Lifetime** | Query | Query | Session | Permanent | Permanent |
| **Deleted** | End Query | End Query | End Session | `DROP TABLE` | `DROP VIEW` |
| **Scope** | 1 Query | 1 Query | Multi-Query | Multi-Query | Multi-Query |
| **Reusability** | Low | Medium | Medium | High | High |
| **Always Fresh?** | Yes | Yes | No | No | Yes |
| **Indexable?** | No | No | Yes | Yes | No (but can use mat. view) |

---

## **Real-World Decision Guide**

| You Need... | Use This |
|-------------|----------|
| Clean, readable query with reuse in **one query** | **CTE** |
| Step-by-step data pipeline in **one query** | **Multiple CTEs** |
| Reuse data across **multiple queries in same session** | **TEMP TABLE** |
| Save a **snapshot** of data for reporting | **CTAS** |
| Reuse **same logic** in many places, always fresh | **VIEW** |
| Performance on large reused logic | **Materialized View** (not in diagram) |

---

## **Code Examples: All 5 in Action**

### 1. **Subquery**
```sql
SELECT name, 
       (SELECT COUNT(*) FROM orders o WHERE o.user_id = u.id) AS order_count
FROM users u;
```

### 2. **CTE**
```sql
WITH high_value AS (
  SELECT * FROM orders WHERE amount > 1000
)
SELECT region, COUNT(*) FROM high_value GROUP BY region;
```

### 3. **Temp Table**
```sql
CREATE TEMP TABLE session_report AS
SELECT user_id, SUM(amount) FROM orders GROUP BY user_id;

-- Use in next query
SELECT u.name, r.total FROM session_report r
JOIN users u ON u.id = r.user_id;
```

### 4. **CTAS**
```sql
CREATE TABLE monthly_sales_2025 AS
SELECT DATE_TRUNC('month', order_date) AS month, SUM(amount)
FROM orders WHERE order_date >= '2025-01-01'
GROUP BY 1;

-- Use forever
SELECT * FROM monthly_sales_2025;
```

### 5. **View**
```sql
CREATE VIEW vip_customers AS
SELECT * FROM customers WHERE lifetime_value > 5000;

-- Always up to date
SELECT * FROM vip_customers;
```

---

## **Pro Tips**

### Use **CTE** for:
- Complex reporting
- Recursive queries (tree, graph)
- Code readability

```sql
WITH RECURSIVE org_chart AS (
  SELECT id, name, manager_id FROM employees WHERE id = 1
  UNION ALL
  SELECT e.id, e.name, e.manager_id 
  FROM employees e 
  JOIN org_chart o ON e.manager_id = o.id
)
SELECT * FROM org_chart;
```

### Use **TEMP TABLE** when:
- You need **indexes** on intermediate data
- You're doing **multiple passes**
- Data is **large** and reused

```sql
CREATE TEMP TABLE staged AS SELECT ...;
CREATE INDEX ON staged (user_id);
ANALYZE staged;
```

### Use **Materialized View** (Bonus!)
```sql
CREATE MATERIALIZED VIEW daily_sales AS
SELECT DATE(order_date), SUM(amount) FROM orders GROUP BY 1;

REFRESH MATERIALIZED VIEW daily_sales; -- Manual refresh
```

> Combines **CTAS speed** + **View freshness** (with refresh)

---

## **Common Mistakes to Avoid**

| Mistake | Why It's Bad |
|-------|-------------|
| Using `CTAS` when data changes often | Becomes stale |
| Using `TEMP TABLE` in a short query | Unnecessary disk I/O |
| Using `VIEW` on huge data without indexing | Slow every time |
| Forgetting `TEMP` → creates permanent table | Clutters database |
| Using subquery in `WHERE` on large table | No indexing |

---

## **Quiz: Choose the Right One**

| Scenario | Best Choice |
|--------|-----------|
| Debug step-by-step in one query | CTE |
| Reuse same filter in `SELECT`, `WHERE`, `JOIN` | CTE |
| Save report for Excel export | CTAS |
| Show live dashboard data | View |
| ETL pipeline with 5 steps in one session | Temp Tables |
| Hierarchy traversal | Recursive CTE |

---

## **Final Cheat Sheet (Copy-Paste!)**

```sql
-- 1. Subquery
SELECT ..., (SELECT ...) FROM ...

-- 2. CTE
WITH cte_name AS (SELECT ...) 
SELECT ... FROM cte_name

-- 3. Temp Table
CREATE TEMP TABLE name AS SELECT ...;
-- Auto-dropped at session end

-- 4. CTAS
CREATE TABLE name AS SELECT ...;
DROP TABLE name; -- when done

-- 5. View
CREATE VIEW name AS SELECT ...;
DROP VIEW name;
```

---

## **You Are Now a Master of SQL Structures!**

**Remember the diagram**:
```
Memory → Disk → No Storage
Temporary → Permanent
Single Query → Multi-Query
Stale → Fresh
```


##### Tags : [[1 - SQL 🥞]]