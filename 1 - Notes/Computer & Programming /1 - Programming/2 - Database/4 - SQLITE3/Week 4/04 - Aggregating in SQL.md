

**Aggregation** means **combining multiple rows into a single summarized result**.

Instead of looking at individual records:

```text
orders

id | customer | amount
---+----------+-------
1  | Ali      | 100
2  | Sara     | 200
3  | Ali      | 150
4  | Sara     | 50
```

Aggregation answers questions like:

- How many orders exist?
    
- What is the total revenue?
    
- What is the average order value?
    
- What is the highest/lowest value?
    

---

## Aggregate Functions

SQL provides built-in aggregate functions:

### `COUNT()` — count rows

```sql
SELECT COUNT(*)
FROM orders;
```

Result:

```text
4
```

---

### `SUM()` — add values

```sql
SELECT SUM(amount)
FROM orders;
```

Result:

```text
500
```

---

### `AVG()` — average

```sql
SELECT AVG(amount)
FROM orders;
```

Result:

```text
125
```

---

### `MAX()` — largest value

```sql
SELECT MAX(amount)
FROM orders;
```

Result:

```text
200
```

---

### `MIN()` — smallest value

```sql
SELECT MIN(amount)
FROM orders;
```

Result:

```text
50
```

---

# GROUP BY

Aggregation becomes powerful with `GROUP BY`.

Without grouping:

```sql
SELECT SUM(amount)
FROM orders;
```

You get one result:

```text
500
```

With grouping:

```sql
SELECT customer, SUM(amount)
FROM orders
GROUP BY customer;
```

Result:

```text
customer | SUM(amount)
---------+------------
Ali      | 250
Sara     | 250
```

The database does:

```text
Rows
 |
 ├── Ali group
 │     100
 │     150
 │
 └── Sara group
       200
       50

        ↓

Aggregate each group
```

---

# HAVING

`WHERE` filters rows **before aggregation**.

`HAVING` filters groups **after aggregation**.

Example:

Find customers who spent more than 200:

```sql
SELECT customer, SUM(amount)
FROM orders
GROUP BY customer
HAVING SUM(amount) > 200;
```

Execution order:

```text
FROM
 ↓
WHERE
 ↓
GROUP BY
 ↓
Aggregate functions
 ↓
HAVING
 ↓
SELECT
 ↓
ORDER BY
```

---

# Aggregation with Views

A common professional pattern:

Create a view:

```sql
CREATE VIEW customer_sales AS
SELECT
    customer,
    SUM(amount) AS total_spent,
    COUNT(*) AS order_count
FROM orders
GROUP BY customer;
```

Now query it:

```sql
SELECT *
FROM customer_sales;
```

Result:

```text
customer | total_spent | order_count
---------+-------------+------------
Ali      | 250         | 2
Sara     | 250         | 2
```

The view hides the aggregation logic.

---

## Real-world examples

### E-commerce

```sql
SELECT 
    product_id,
    SUM(quantity)
FROM order_items
GROUP BY product_id;
```

"How many units of each product were sold?"

---

### Analytics

```sql
SELECT 
    DATE(created_at),
    COUNT(*)
FROM users
GROUP BY DATE(created_at);
```

"How many users registered each day?"

---

### Spring Boot example

A repository query:

```java
@Query("""
    SELECT c.name, SUM(o.total)
    FROM Customer c
    JOIN c.orders o
    GROUP BY c.name
""")
List<Object[]> getCustomerRevenue();
```

The database does the heavy calculation instead of Java loading thousands of rows.

---

Mental model:

```
Normal query:
Rows → Rows

Aggregation:
Rows → Groups → Summary values
```

Aggregation is one of the core tools behind **reports, dashboards, analytics, and database views**.


[[SQlite]]