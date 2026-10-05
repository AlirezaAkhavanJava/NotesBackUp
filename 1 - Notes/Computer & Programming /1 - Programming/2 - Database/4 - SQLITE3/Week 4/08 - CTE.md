
## CTE — Common Table Expression

A **CTE (Common Table Expression)** is a **temporary named result set created inside a single SQL statement**.

The key difference from a view:

```text
View:
CREATE VIEW → exists as a database object

Temporary View:
CREATE TEMP VIEW → exists for the connection

CTE:
WITH ... → exists only for ONE SQL statement
```

### Basic example

Instead of:

```sql
SELECT *
FROM (
    SELECT *
    FROM employees
    WHERE salary > 50000
) AS high_paid
WHERE department = 'Engineering';
```

You can write:

```sql
WITH high_paid AS (
    SELECT *
    FROM employees
    WHERE salary > 50000
)
SELECT *
FROM high_paid
WHERE department = 'Engineering';
```

`high_paid` is the **CTE**.

### Structure

```sql
WITH cte_name AS (
    SELECT ...
)
SELECT ...
FROM cte_name;
```

Think:

```text
WITH
  │
  └── create temporary named query
             │
             ▼
       use it in this statement
             │
             ▼
       statement finishes
             │
             ▼
       CTE disappears
```

### CTE vs temporary view

This is the important distinction:

```sql
CREATE TEMP VIEW expensive_products AS
SELECT *
FROM products
WHERE price > 100;
```

You can then execute **multiple statements**:

```sql
SELECT * FROM expensive_products;

SELECT COUNT(*) FROM expensive_products;

SELECT AVG(price) FROM expensive_products;
```

But with a CTE:

```sql
WITH expensive_products AS (
    SELECT *
    FROM products
    WHERE price > 100
)
SELECT * FROM expensive_products;
```

The CTE exists only for **that one `SELECT` statement**.

If you then run:

```sql
SELECT * FROM expensive_products;
```

you get:

```text
no such table: expensive_products
```

---

## CTEs become powerful with multiple stages

For example:

```sql
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(amount) AS total
    FROM orders
    GROUP BY customer_id
),
big_customers AS (
    SELECT *
    FROM customer_totals
    WHERE total > 1000
)
SELECT *
FROM big_customers;
```

You created:

```text
orders
  │
  ▼
customer_totals
  │
  ▼
big_customers
  │
  ▼
final SELECT
```

This is extremely useful for making complex SQL readable.

### CTE vs View vs Subquery

||Subquery|CTE|View|
|---|---|---|---|
|Named|Usually no|Yes|Yes|
|Lifetime|One statement|One statement|Persistent|
|Database object|No|No|Yes|
|Reusable across statements|No|No|Yes|
|Can reference another CTE|—|Yes|Can reference views|
|Good for complex queries|Sometimes|**Excellent**|Excellent|

### One more important capability: recursive CTEs

CTEs can be **recursive**, which lets SQL work with hierarchical/graph-like data:

```sql
WITH RECURSIVE numbers(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1
    FROM numbers
    WHERE n < 10
)
SELECT * FROM numbers;
```

Result:

```text
1
2
3
...
10
```

Recursive CTEs are particularly useful for **trees, organizational hierarchies, dependency graphs, filesystem-like structures, and graph traversal**.

**Mental model:**

> **Subquery = anonymous temporary query**  
> **CTE = named temporary query for one statement**  
> **Temporary view = named query for one connection**  
> **View = named query persisted in the database**



[[SQlite]]