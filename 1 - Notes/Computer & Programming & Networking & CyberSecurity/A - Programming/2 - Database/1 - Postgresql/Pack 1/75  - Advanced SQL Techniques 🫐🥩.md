

## 🧠 1️⃣ Window Functions

Perform calculations across related rows **without grouping**.

Example — running total:

```sql
SELECT
  employee_id,
  salary,
  SUM(salary) OVER (ORDER BY employee_id) AS running_total
FROM employees;
```

💡 Use cases: rankings, moving averages, percentiles, comparing to previous rows.

---

## 🧩 2️⃣ CTEs (Common Table Expressions)

CTEs make complex queries readable and reusable.

```sql
WITH total_sales AS (
  SELECT customer_id, SUM(amount) AS total
  FROM sales
  GROUP BY customer_id
)
SELECT * FROM total_sales WHERE total > 1000;
```

💡 Think of it as a “temporary named result set” used inside a bigger query.

---

## 🧮 3️⃣ Recursive CTEs

Used for **hierarchical or tree-like data** (like org charts, folders, etc.)

```sql
WITH RECURSIVE subordinates AS (
  SELECT id, manager_id, name
  FROM employees
  WHERE manager_id IS NULL
  UNION ALL
  SELECT e.id, e.manager_id, e.name
  FROM employees e
  JOIN subordinates s ON e.manager_id = s.id
)
SELECT * FROM subordinates;
```

💡 Follows relationships until the entire hierarchy is explored.

---

## 🧰 4️⃣ CASE Expressions

Conditional logic inside SQL.

```sql
SELECT
  name,
  CASE 
    WHEN salary > 10000 THEN 'High'
    WHEN salary > 5000 THEN 'Medium'
    ELSE 'Low'
  END AS salary_level
FROM employees;
```

---

## ⚡ 5️⃣ Subqueries (Correlated + Non-correlated)

Embed queries inside other queries.

Example (correlated):

```sql
SELECT name
FROM employees e
WHERE salary > (
  SELECT AVG(salary)
  FROM employees
  WHERE department = e.department
);
```

💡 Used for comparisons or filtering with dynamic conditions.

---

## 🔀 6️⃣ Joins Beyond Basics

Advanced join techniques include:

- **Self JOIN** → join a table with itself
    
- **FULL OUTER JOIN** → combine all rows from both sides
    
- **LATERAL JOIN** → use results of one query as input for another
    

Example:

```sql
SELECT u.name, p.*
FROM users u
LEFT JOIN LATERAL (
  SELECT * FROM posts WHERE posts.user_id = u.id ORDER BY date DESC LIMIT 1
) p ON true;
```

💡 LATERAL is great for “top-N per group” problems.

---

## 🧩 7️⃣ Pivoting (Aggregation + Crosstab)

Convert rows to columns.

Example:

```sql
SELECT *
FROM crosstab(
  'SELECT year, product, SUM(sales) FROM sales GROUP BY year, product'
) AS ct(year int, product_a numeric, product_b numeric);
```

💡 Great for reports.

---

## 📊 8️⃣ Analytical Aggregations

Advanced aggregates like:

- `GROUPING SETS`
    
- `ROLLUP`
    
- `CUBE`
    

Example:

```sql
SELECT region, product, SUM(amount)
FROM sales
GROUP BY ROLLUP(region, product);
```

💡 Automatically gives subtotals and grand totals.

---

## 🧩 9️⃣ JSON / ARRAY Functions

Modern SQL supports semi-structured data.

```sql
SELECT data->>'name' AS name
FROM users_json
WHERE data->>'country' = 'USA';
```

💡 PostgreSQL lets you query JSON fields like regular columns.

---

## ⚙️ 10️⃣ Performance Tricks

- Use **EXPLAIN ANALYZE** to see query execution plan.
    
- Create **indexes** on frequently filtered columns.
    
- Use **materialized views** for heavy aggregations.
    
- Replace correlated subqueries with **joins** for speed.
    



##### Tags : [[1 - SQL 🦬]]