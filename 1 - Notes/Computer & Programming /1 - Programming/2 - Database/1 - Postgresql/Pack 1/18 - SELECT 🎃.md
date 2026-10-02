

# 🧠 PostgreSQL `SELECT` 

---

## 1️⃣ Basic Definition

`SELECT` retrieves data from one or more tables, views, or subqueries.  
It’s the **core of all SQL querying** — think of it as a data pipeline builder:  
**you build a flow from raw data → filters → calculations → final result.**

---

## 2️⃣ General Syntax

```sql
SELECT [DISTINCT | ALL]
       expression [, expression ...]
FROM   table_name [AS alias]
[WHERE condition]
[GROUP BY expression]
[HAVING condition]
[WINDOW window_name AS (...)]
[ORDER BY expression [ASC|DESC]]
[LIMIT n]
[OFFSET n]
```

Each clause adds a new layer of power. Let’s break them down with depth and examples.

---

## 3️⃣ SELECT Expressions

### 🔹 Column Selection

```sql
SELECT id, name, age FROM employees;
```

### 🔹 Computed Columns

You can compute or rename:

```sql
SELECT name, salary * 1.2 AS raised_salary FROM employees;
```

### 🔹 Functions

Postgres supports tons of built-in functions:

```sql
SELECT UPPER(name), LENGTH(email), NOW();
```

### 🔹 Expressions (even subqueries)

```sql
SELECT name, (SELECT COUNT(*) FROM orders WHERE orders.emp_id = e.id) AS order_count
FROM employees e;
```

---

## 4️⃣ DISTINCT / DISTINCT ON

### 🔹 `DISTINCT`

Removes duplicates across all selected columns:

```sql
SELECT DISTINCT country FROM customers;
```

### 🔹 `DISTINCT ON`

PostgreSQL-only feature. Keeps **first row per group** based on `ORDER BY`:

```sql
SELECT DISTINCT ON (country) country, name, salary
FROM employees
ORDER BY country, salary DESC;
```

🧠 Keeps the _highest-salary employee per country._

---

## 5️⃣ FROM Clause — Sources of Data

You can select from:

- **tables**
    
- **views**
    
- **subqueries**
    
- **joins**
    
- **set operations**
    
- **functions returning sets** (e.g. `generate_series()`)
    

### Example: multiple sources

```sql
SELECT *
FROM employees e
JOIN departments d ON e.dept_id = d.id;
```

### Subquery as source

```sql
SELECT *
FROM (SELECT * FROM employees WHERE salary > 5000) AS high_paid;
```

---

## 6️⃣ WHERE — Filtering Rows

```sql
SELECT * FROM employees WHERE salary > 5000 AND active = true;
```

- Supports logical ops: `AND`, `OR`, `NOT`
    
- Supports comparison ops: `=`, `>`, `<`, `<>`, `BETWEEN`, `IN`, `LIKE`, `ILIKE`, etc.
    
- You can even call functions or subqueries here.
    

Example:

```sql
SELECT name FROM employees
WHERE id IN (SELECT emp_id FROM orders WHERE total > 10000);
```

---

## 7️⃣ GROUP BY — Aggregation

Groups rows to compute aggregated results.

```sql
SELECT department, AVG(salary) AS avg_salary
FROM employees
GROUP BY department;
```

---

## 8️⃣ HAVING — Filter After Grouping

Filters grouped results (unlike `WHERE`, which filters rows before grouping).

```sql
SELECT department, COUNT(*) AS count
FROM employees
GROUP BY department
HAVING COUNT(*) > 10;
```

---

## 9️⃣ WINDOW FUNCTIONS (🔥 Advanced)

Run calculations across “windows” of rows — without collapsing them into groups.

```sql
SELECT name,
       department,
       salary,
       AVG(salary) OVER (PARTITION BY department) AS dept_avg,
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank_in_dept
FROM employees;
```

### Key parts:

- `OVER()` defines the “window”
    
- `PARTITION BY` = like `GROUP BY`, splits data into groups
    
- `ORDER BY` = defines order inside each partition
    

---

## 🔟 ORDER BY — Sorting Results

```sql
SELECT name, salary
FROM employees
ORDER BY salary DESC, name ASC;
```

Works with columns, expressions, or even aliases.

---

## 11️⃣ LIMIT / OFFSET — Pagination

```sql
SELECT * FROM employees ORDER BY id LIMIT 10 OFFSET 20;
```

→ skip first 20, return next 10.

Use for pagination (like “page 3, 10 per page”).

---

## 12️⃣ JOINS (💪 Deep Power)

### Types:

|Join Type|Description|
|---|---|
|INNER JOIN|Only matching rows|
|LEFT JOIN|All left + matching right|
|RIGHT JOIN|All right + matching left|
|FULL JOIN|All rows from both sides|
|CROSS JOIN|Cartesian product|
|LATERAL JOIN|Join with a subquery depending on left table|

Example:

```sql
SELECT e.name, d.name AS dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.id;
```

Lateral:

```sql
SELECT e.id, s.total
FROM employees e,
LATERAL (SELECT SUM(amount) AS total FROM sales WHERE emp_id = e.id) s;
```

---

## 13️⃣ SET OPERATIONS

Combine results of multiple queries.

|Operation|Description|
|---|---|
|`UNION`|Merge unique rows|
|`UNION ALL`|Merge all rows (keep duplicates)|
|`INTERSECT`|Rows common to both|
|`EXCEPT`|Rows from first not in second|

Example:

```sql
SELECT id FROM active_users
UNION
SELECT id FROM premium_users;
```

---

## 14️⃣ CTE (Common Table Expressions) — `WITH`

Re-usable named subqueries.

```sql
WITH high_paid AS (
  SELECT * FROM employees WHERE salary > 10000
),
avg_salary AS (
  SELECT AVG(salary) AS avg_sal FROM high_paid
)
SELECT h.name, h.salary, a.avg_sal
FROM high_paid h, avg_salary a;
```

Also supports **recursive queries** (for hierarchies):

```sql
WITH RECURSIVE subordinates AS (
  SELECT id, manager_id, name FROM employees WHERE id = 1
  UNION ALL
  SELECT e.id, e.manager_id, e.name
  FROM employees e
  JOIN subordinates s ON e.manager_id = s.id
)
SELECT * FROM subordinates;
```

---

## 15️⃣ JSON / ARRAY in SELECT

PostgreSQL supports advanced types.

### JSON:

```sql
SELECT json_build_object('name', name, 'salary', salary) AS info FROM employees;
```

### Array:

```sql
SELECT ARRAY_AGG(name ORDER BY name) FROM employees;
```

---

## 16️⃣ CASE Expressions (Inline IF/ELSE)

```sql
SELECT name,
       CASE
         WHEN salary > 10000 THEN 'High'
         WHEN salary BETWEEN 5000 AND 10000 THEN 'Medium'
         ELSE 'Low'
       END AS salary_level
FROM employees;
```

---

## 17️⃣ Performance Tips (Advanced)

- ✅ Always `SELECT` only needed columns (avoid `SELECT *`)
    
- ✅ Use `WHERE` and indexes properly
    
- ✅ Use `EXPLAIN ANALYZE` to profile queries
    
- ✅ Combine aggregations smartly with CTE or window functions
    
- ✅ Avoid OFFSET for large pagination (use keyset pagination instead)
    

---

## 18️⃣ Example: Real Complex Query

```sql
WITH ranked_sales AS (
  SELECT emp_id,
         SUM(total) AS total_sales,
         RANK() OVER (ORDER BY SUM(total) DESC) AS rank
  FROM sales
  WHERE date >= CURRENT_DATE - INTERVAL '30 days'
  GROUP BY emp_id
)
SELECT e.name,
       r.total_sales,
       r.rank,
       CASE WHEN r.rank <= 3 THEN '🏆 Top Performer' ELSE 'Regular' END AS status
FROM ranked_sales r
JOIN employees e ON e.id = r.emp_id
ORDER BY r.rank;
```




#### Tags : [[1 - SQL 🦬]]