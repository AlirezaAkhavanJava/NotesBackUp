



## 1. **LATERAL Joins (PostgreSQL-only, advanced)**


A **LATERAL join** lets a subquery in the `FROM` clause **refer to columns of tables already listed**.  
It’s like a correlated subquery, but placed in `FROM` so you can treat the results as a table.

> **LATERAL = "یه ساب‌کوئری رو مثل یه جدول موقت بساز و برای هر ردیف جوین کن"**

### Why use?

- Get **top-N per group** (e.g. latest order for each customer).
    
- Expand arrays / JSON per row.
    
- Use set-returning functions.
    

### Example – latest order per customer:

```sql
SELECT c.id, c.name, o.*
FROM customers c
LEFT JOIN LATERAL (
  SELECT *
  FROM orders o
  WHERE o.customer_id = c.id
  ORDER BY o.created_at DESC
  LIMIT 1
) o ON true;
```

👉 Without `LATERAL`, this would need a messy correlated subquery.

---

## 2. **Recursive Joins (via Recursive CTEs)**

👉 Standard joins can’t easily walk hierarchical relationships.  
👉 Solution = **Recursive CTEs**, which internally do a **repeated self-join** until no more rows are found.

### Why use?

- Tree structures (employees → managers, categories → subcategories).
    
- Graph traversal.
    

### Example – employee hierarchy:

```sql
WITH RECURSIVE hierarchy AS (
  SELECT id, name, manager_id, 1 AS level
  FROM employees
  WHERE manager_id IS NULL  -- start from top manager

  UNION ALL

  SELECT e.id, e.name, e.manager_id, h.level + 1
  FROM employees e
  JOIN hierarchy h ON e.manager_id = h.id
)
SELECT * FROM hierarchy;
```

👉 This is essentially a **repeated self-join until exhaustion**.

---

## 3. **Windowed Joins (Join + Window Functions)**

👉 Not a new join type, but an advanced **pattern** where you combine joins with window functions.

### Why use?

- To **rank, filter, and compute aggregates per joined row** without collapsing data.
    

### Example – student with course rank:

```sql
SELECT s.name, e.course_id,
       RANK() OVER (PARTITION BY e.course_id ORDER BY s.name) AS course_rank
FROM students s
JOIN enrollments e ON s.id = e.student_id;
```

👉 Inner join gives all pairs, window assigns rank **within each course group**.

---

## 4. **Join Filtering & Predicate Pushdown**

👉 Advanced optimization: WHERE conditions can **change the meaning of outer joins**.

- If you write:
    

```sql
SELECT s.name, e.course
FROM students s
LEFT JOIN enrollments e ON s.id = e.student_id
WHERE e.course = 'Math';
```

👉 This accidentally **removes students without enrollments**, turning it into an INNER JOIN!

✅ Correct way:

```sql
SELECT s.name, e.course
FROM students s
LEFT JOIN enrollments e 
  ON s.id = e.student_id AND e.course = 'Math';
```

👉 Keeps all students, matches Math enrollments where present.

---

## 5. **Join Algorithms (Execution Detail)**

Not syntax, but knowing _how the database executes joins_ is **advanced SQL mastery**.

- **Nested Loop Join** → compares each left row with right rows (good for small sets with index).
    
- **Hash Join** → builds hash table on smaller side, then probes it (good for big unsorted sets).
    
- **Merge Join** → requires both inputs sorted on join key (efficient for large sorted data).
    

👉 You can check with:

```sql
EXPLAIN ANALYZE
SELECT s.name, e.course
FROM students s
JOIN enrollments e ON s.id = e.student_id;
```

---

## 6. **Partitioned Joins (Postgres ≥ 11)**

👉 When joining **partitioned tables**, Postgres can prune partitions and join only relevant slices.  
This is an advanced optimization for **large-scale data warehouses**.

---

## 7. **Foreign Data Joins (FDW Joins)**

👉 PostgreSQL supports **Foreign Data Wrappers**, meaning you can `JOIN` a local table with one in another database (even another PostgreSQL or MySQL instance).

### Example:

```sql
SELECT l.id, r.some_column
FROM local_table l
JOIN foreign_table r ON l.id = r.id;
```

👉 Under the hood, Postgres may push parts of the join to the remote server.

---

## 8. **Materialized Joins (Denormalization)**

👉 Sometimes joins are too expensive to compute every time.  
👉 Solution: precompute them into **materialized views**.

```sql
CREATE MATERIALIZED VIEW student_courses AS
SELECT s.id, s.name, e.course
FROM students s
JOIN enrollments e ON s.id = e.student_id;
```

👉 Refresh periodically instead of recalculating every query.

---

## 9. **Advanced Join Tricks**

- **Join with DISTINCT ON** (Postgres):
    

```sql
SELECT DISTINCT ON (s.id) s.id, s.name, e.course
FROM students s
JOIN enrollments e ON s.id = e.student_id
ORDER BY s.id, e.created_at DESC;
```

👉 Pick latest course per student without window functions.

- **Join with JSON**:
    

```sql
SELECT s.id, json_agg(e.course) AS courses
FROM students s
LEFT JOIN enrollments e ON s.id = e.student_id
GROUP BY s.id;
```

👉 Combine relational joins + JSON aggregation.

- **Join with Arrays**:
    

```sql
SELECT s.id, array_agg(e.course) AS courses
FROM students s
LEFT JOIN enrollments e ON s.id = e.student_id
GROUP BY s.id;
```

---

# ✅ Recap

We now have:

**Basic joins** → INNER, LEFT, RIGHT, FULL, CROSS, SELF, NATURAL, USING  
**Advanced joins** →

- LATERAL (per-row subqueries in FROM)
    
- Recursive (hierarchies, graphs)
    
- Semi / Anti joins (EXISTS / NOT EXISTS)
    
- Windowed joins (join + window functions)
    
- Join filtering (ON vs WHERE subtlety)
    
- Join algorithms (nested loop, hash, merge)
    
- Partitioned joins
    
- Foreign data joins (across DBs)
    
- Materialized joins (denormalization)
    
- JSON/Array joins (Postgres-specific tricks)
    



#### Tags : [[1 - SQL 🦬]]