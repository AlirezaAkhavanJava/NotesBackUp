
Let's treat **CTE (Common Table Expression)** as a SQL feature from the ground up, including its terminology, creation, scope, composition, and practical use.

# 1. Definition

**CTE — Common Table Expression**

A CTE is a **temporary named result set defined at the beginning of a SQL statement using `WITH`**.

```sql
WITH name AS (
    SELECT ...
)
SELECT ...
FROM name;
```

A more precise definition:

> A CTE gives a subquery a name and makes that named query available to the remainder of the current SQL statement.

The important words are:

- **Common** → available to multiple parts of the statement.
    
- **Table Expression** → behaves like a table expression; you can query it.
    
- **Temporary** → its scope ends when the statement finishes.
    
- **Named** → unlike an ordinary anonymous subquery, it has an identifier.
    

---

# 2. Creating a CTE

The basic syntax is:

```sql
WITH cte_name AS (
    SELECT ...
)
SELECT ...
FROM cte_name;
```

Example:

```sql
WITH adult_users AS (
    SELECT *
    FROM users
    WHERE age >= 18
)
SELECT *
FROM adult_users;
```

The CTE is:

```sql
adult_users
```

and its definition is:

```sql
SELECT *
FROM users
WHERE age >= 18
```

Conceptually:

```text
WITH
 │
 └── adult_users
        │
        └── SELECT from users
                 │
                 ▼
            CTE result
                 │
                 ▼
             final SELECT
```

---

# 3. CTE does not create a database object

This is a major distinction.

When you execute:

```sql
CREATE VIEW adult_users AS ...
```

you create a **view in the database schema**.

But:

```sql
WITH adult_users AS (...)
SELECT ...
```

doesn't create anything permanent.

After the statement finishes:

```text
adult_users
     ↓
no longer exists
```

You cannot do:

```sql
SELECT * FROM adult_users;
```

in a separate statement.

---

# 4. CTE behaves like a table expression

Once defined:

```sql
WITH adult_users AS (
    SELECT *
    FROM users
    WHERE age >= 18
)
```

you can use it:

```sql
SELECT *
FROM adult_users;
```

You can filter:

```sql
SELECT *
FROM adult_users
WHERE age >= 30;
```

Sort:

```sql
SELECT *
FROM adult_users
ORDER BY age DESC;
```

Join:

```sql
SELECT *
FROM adult_users a
JOIN orders o
    ON a.id = o.user_id;
```

Aggregate:

```sql
SELECT COUNT(*)
FROM adult_users;
```

So mentally:

```text
CTE
 ↓
table-like query source
```

But remember:

> **Table-like does not mean it is a physical table.**

---

# 5. CTE column names

You can explicitly specify the CTE's columns:

```sql
WITH adult_users(id, username, user_age) AS (
    SELECT id, name, age
    FROM users
    WHERE age >= 18
)
SELECT username, user_age
FROM adult_users;
```

Here:

```text
id       → first SELECT column
username → second SELECT column
user_age → third SELECT column
```

Usually you don't need to explicitly specify them because SQLite can derive the names from the `SELECT`.

---

# 6. Multiple CTEs

This is where CTEs become really useful.

You can define multiple CTEs:

```sql
WITH adult_users AS (
    SELECT *
    FROM users
    WHERE age >= 18
),
active_users AS (
    SELECT *
    FROM adult_users
    WHERE active = 1
)
SELECT *
FROM active_users;
```

Notice:

```text
users
  │
  ▼
adult_users
  │
  ▼
active_users
  │
  ▼
final SELECT
```

The second CTE can use the first CTE.

---

# 7. CTE pipeline

This is one of the smartest ways to use CTEs.

Imagine:

> Find customers who spent more than $1,000 on paid orders.

Instead of one huge query:

```sql
WITH paid_orders AS (
    SELECT *
    FROM orders
    WHERE status = 'PAID'
),
customer_totals AS (
    SELECT
        customer_id,
        SUM(amount) AS total_spent
    FROM paid_orders
    GROUP BY customer_id
),
valuable_customers AS (
    SELECT *
    FROM customer_totals
    WHERE total_spent > 1000
)
SELECT *
FROM valuable_customers;
```

You have a logical pipeline:

```text
orders
  │
  │ filter
  ▼
paid_orders
  │
  │ aggregate
  ▼
customer_totals
  │
  │ filter
  ▼
valuable_customers
  │
  ▼
final result
```

This is much easier to reason about.

---

# 8. CTE scope

A CTE's scope is **the single SQL statement in which it is defined**.

This works:

```sql
WITH users_over_18 AS (
    SELECT *
    FROM users
    WHERE age > 18
)
SELECT * FROM users_over_18;
```

This does not:

```sql
SELECT * FROM users_over_18;
```

because the CTE no longer exists.

Think of its scope like a local variable in programming:

```java
void method() {
    var usersOver18 = ...;

    // available here
}

// usersOver18 doesn't exist here
```

The analogy isn't perfect internally, but it is useful for understanding **scope**.

---

# 9. CTE vs subquery

Without CTE:

```sql
SELECT *
FROM (
    SELECT *
    FROM users
    WHERE age >= 18
) AS adult_users;
```

The subquery is anonymous.

With CTE:

```sql
WITH adult_users AS (
    SELECT *
    FROM users
    WHERE age >= 18
)
SELECT *
FROM adult_users;
```

The CTE gives the query a meaningful name.

Compare:

```text
Subquery:

SELECT
  FROM (
      SELECT ...
  )


CTE:

WITH adult_users AS (
    SELECT ...
)
SELECT
  FROM adult_users
```

For complex queries, the second form is generally easier to understand.

---

# 10. CTEs can be used multiple times

A CTE isn't restricted to one reference.

```sql
WITH expensive_products AS (
    SELECT *
    FROM products
    WHERE price > 100
)
SELECT
    (SELECT COUNT(*) FROM expensive_products) AS count,
    (SELECT AVG(price) FROM expensive_products) AS average_price;
```

The CTE is available throughout that statement.

---

# 11. CTE + JOIN

Example:

```sql
WITH expensive_products AS (
    SELECT *
    FROM products
    WHERE price > 100
)
SELECT
    p.name,
    o.quantity
FROM expensive_products p
JOIN order_items o
    ON p.id = o.product_id;
```

Here the CTE becomes one side of the join.

---

# 12. CTE + aggregation

Very common pattern:

```sql
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(amount) AS total
    FROM orders
    GROUP BY customer_id
)
SELECT
    AVG(total) AS average_customer_spending
FROM customer_totals;
```

Notice the two levels:

```text
orders
   ↓
SUM per customer
   ↓
customer_totals
   ↓
AVG across customers
```

This is much cleaner than trying to express everything in one flat query.

---

# 13. CTE + `INSERT`

A CTE doesn't have to end in `SELECT`.

For example:

```sql
WITH inactive_users AS (
    SELECT id
    FROM users
    WHERE last_login < '2025-01-01'
)
DELETE FROM users
WHERE id IN (
    SELECT id
    FROM inactive_users
);
```

The CTE provides the data used by the `DELETE`.

Similarly, CTEs can be used with `INSERT` and `UPDATE` where supported by the database.

---

# 14. Recursive CTE

SQLite also supports:

```sql
WITH RECURSIVE
```

A recursive CTE can reference itself.

Simple example:

```sql
WITH RECURSIVE numbers(n) AS (
    SELECT 1

    UNION ALL

    SELECT n + 1
    FROM numbers
    WHERE n < 10
)
SELECT *
FROM numbers;
```

Result:

```text
1
2
3
4
5
6
7
8
9
10
```

The important difference is:

```text
Normal CTE:

CTE → query


Recursive CTE:

CTE
 ↑  │
 │  ▼
 └── query
```

It is useful for hierarchical and graph-like data.

Examples:

- organizational structures
    
- categories/subcategories
    
- directory trees
    
- dependency graphs
    
- parent/child relationships
    

---

# 15. CTE terminology

When working with CTEs, you'll encounter these terms:

### CTE

The complete named query expression:

```sql
adult_users AS (
    SELECT ...
)
```

### CTE name

```sql
adult_users
```

### CTE query / CTE definition

```sql
SELECT *
FROM users
WHERE age >= 18
```

### `WITH` clause

The part that introduces the CTE:

```sql
WITH adult_users AS (...)
```

### Main query

The query that consumes the CTE:

```sql
SELECT *
FROM adult_users;
```

### Recursive CTE

A CTE that references itself:

```sql
WITH RECURSIVE ...
```

---

# 16. The professional mental model

Don't think:

> "A CTE is a temporary table."

That's slightly misleading.

Think:

> **A CTE is a named query expression with statement-level scope.**

For example:

```sql
WITH
    filtered_orders AS (...),
    customer_totals AS (...),
    ranked_customers AS (...)
SELECT ...
FROM ranked_customers;
```

Read it as:

```text
Define filtered_orders
        ↓
Define customer_totals using it
        ↓
Define ranked_customers using it
        ↓
Execute the final query
```

That makes CTEs excellent for **structuring complex SQL as a sequence of logical transformations**.

One important final point: **a CTE is not inherently a performance optimization or guaranteed temporary materialization**. Whether SQLite materializes or inlines a CTE is an execution/optimization concern; use CTEs primarily for query structure and clarity unless you've examined the query plan and have a specific performance reason.



[[SQlite]]