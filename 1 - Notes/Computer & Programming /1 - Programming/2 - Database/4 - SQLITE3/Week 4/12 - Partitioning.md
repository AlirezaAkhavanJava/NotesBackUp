
 The important idea is that **a SQLite VIEW can partition how you _access_ data, but it does not physically partition the table**.

Think of it as creating named windows into one table.

## 1. Scenario

Suppose you have one large `orders` table:

```sql
CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    customer TEXT,
    amount REAL,
    status TEXT,
    created_at TEXT
);
```

Data:

```text
id | customer | amount | status    | created_at
---+----------+--------+-----------+------------
1  | Alice    | 120    | completed | 2026-01-10
2  | Bob      | 80     | pending   | 2026-01-11
3  | John     | 250    | completed | 2026-01-12
4  | Sarah    | 40     | cancelled | 2026-01-13
5  | Mike     | 90     | pending   | 2026-01-14
```

You could repeatedly write:

```sql
SELECT *
FROM orders
WHERE status = 'completed';
```

But you can turn that query into a **VIEW**.

---

# 2. Create a partition-like VIEW

```sql
CREATE VIEW completed_orders AS
SELECT *
FROM orders
WHERE status = 'completed';
```

Now:

```sql
SELECT *
FROM completed_orders;
```

returns:

```text
1 | Alice | 120 | completed | 2026-01-10
3 | John  | 250 | completed | 2026-01-12
```

You've created a logical partition:

```text
                 orders
                    │
       ┌────────────┼────────────┐
       ↓            ↓            ↓
 completed       pending      cancelled
   VIEW            VIEW          VIEW
```

But **all records still physically live inside `orders`**.

---

# 3. Create multiple views

You can create a view for each logical category:

```sql
CREATE VIEW completed_orders AS
SELECT *
FROM orders
WHERE status = 'completed';

CREATE VIEW pending_orders AS
SELECT *
FROM orders
WHERE status = 'pending';

CREATE VIEW cancelled_orders AS
SELECT *
FROM orders
WHERE status = 'cancelled';
```

Now your application can treat them almost like separate tables:

```sql
SELECT * FROM completed_orders;
```

```sql
SELECT * FROM pending_orders;
```

```sql
SELECT * FROM cancelled_orders;
```

This is useful because you don't repeatedly expose the filtering logic throughout your application.

---

# 4. Partition by time

This is another very useful pattern.

Suppose:

```sql
orders
```

contains millions of historical records.

You could create:

```sql
CREATE VIEW orders_2026 AS
SELECT *
FROM orders
WHERE created_at >= '2026-01-01'
  AND created_at <  '2027-01-01';
```

Then:

```sql
SELECT *
FROM orders_2026;
```

Or partition by month:

```sql
CREATE VIEW orders_2026_01 AS
SELECT *
FROM orders
WHERE created_at >= '2026-01-01'
  AND created_at <  '2026-02-01';
```

```sql
CREATE VIEW orders_2026_02 AS
SELECT *
FROM orders
WHERE created_at >= '2026-02-01'
  AND created_at <  '2026-03-01';
```

Conceptually:

```text
                    orders
                       │
          ┌────────────┼────────────┐
          ↓            ↓            ↓
       Jan 2026     Feb 2026     Mar 2026
         VIEW         VIEW         VIEW
```

Again, this is **logical partitioning**, not physical partitioning.

---

# 5. The important distinction

Don't confuse:

```text
VIEW
```

with:

```text
TABLE PARTITIONING
```

A VIEW is essentially a **saved SELECT statement**.

When you create:

```sql
CREATE VIEW pending_orders AS
SELECT *
FROM orders
WHERE status = 'pending';
```

SQLite isn't copying those rows somewhere.

Conceptually:

```text
pending_orders
      │
      │ SELECT ...
      ↓
   orders
      │
      ↓
 filtered rows
```

The data remains in:

```text
orders
```

The VIEW stores the **query definition**.

---

# 6. Why this is useful

Imagine your application has these operations:

```text
Admin
 ├── All orders
 ├── Pending orders
 ├── Completed orders
 └── Cancelled orders
```

Instead of putting this everywhere:

```sql
SELECT *
FROM orders
WHERE status = 'pending';
```

you can have:

```sql
SELECT *
FROM pending_orders;
```

The application code becomes more expressive.

For example:

```sql
SELECT customer, amount
FROM completed_orders
WHERE amount > 100;
```

You're combining the VIEW's filter with another filter.

Conceptually SQLite evaluates something similar to:

```sql
SELECT customer, amount
FROM (
    SELECT *
    FROM orders
    WHERE status = 'completed'
)
WHERE amount > 100;
```

---

# 7. Views can also hide complexity

This is where Views become particularly powerful.

Suppose your actual database is:

```text
orders
customers
payments
```

And getting "successful customer orders" requires a JOIN:

```sql
SELECT
    o.id,
    c.name,
    o.amount
FROM orders o
JOIN customers c
    ON c.id = o.customer_id
JOIN payments p
    ON p.order_id = o.id
WHERE p.status = 'successful';
```

You could create:

```sql
CREATE VIEW successful_orders AS
SELECT
    o.id,
    c.name,
    o.amount
FROM orders o
JOIN customers c
    ON c.id = o.customer_id
JOIN payments p
    ON p.order_id = o.id
WHERE p.status = 'successful';
```

Now:

```sql
SELECT *
FROM successful_orders;
```

Your application doesn't need to know that three tables are involved.

That's one of the strongest uses of Views:

> **A VIEW creates a stable logical interface over underlying data.**

---

# 8. Views can be queried like tables

You can do:

```sql
SELECT *
FROM pending_orders
ORDER BY amount DESC;
```

```sql
SELECT COUNT(*)
FROM completed_orders;
```

```sql
SELECT AVG(amount)
FROM completed_orders;
```

```sql
SELECT *
FROM completed_orders
WHERE amount > 200;
```

You can even create another VIEW from a VIEW:

```sql
CREATE VIEW expensive_completed_orders AS
SELECT *
FROM completed_orders
WHERE amount > 200;
```

So:

```text
orders
   ↓
completed_orders
   ↓
expensive_completed_orders
```

This is **logical composition**.

---

# 9. A very important limitation

Don't think:

> "I created `completed_orders`, therefore SQLite only searches completed rows."

Not necessarily.

A VIEW doesn't automatically create an index or physically separate the data.

If performance matters, index the underlying table.

For example:

```sql
CREATE INDEX idx_orders_status
ON orders(status);
```

Now this:

```sql
SELECT *
FROM completed_orders;
```

can potentially benefit from the index on:

```text
orders.status
```

For time-based views:

```sql
CREATE INDEX idx_orders_created_at
ON orders(created_at);
```

---

# 10. The mental model

Think of the database like this:

```text
                 PHYSICAL DATA
                      │
                      ▼
                   orders
                      │
          ┌───────────┼───────────┐
          │           │           │
          ▼           ▼           ▼
       VIEW A      VIEW B      VIEW C
          │           │           │
          ▼           ▼           ▼
     completed     pending    cancelled
```

The **table owns the data**.

The **VIEW owns a way of looking at that data**.

So when you say:

> "Use Views to partition data"

the technically precise statement is:

> **Use Views to create logical partitions/subsets of a table, not physical partitions of its storage.**

### When I'd actually use this

Use Views when you want:

- a reusable filtered dataset
    
- a clean database API for your application
    
- to hide complicated JOINs
    
- different logical "sections" of a table
    
- reporting/analytics datasets
    
- stable query interfaces for your backend
    

Don't use Views as a substitute for actual physical partitioning or indexing. SQLite's storage engine doesn't turn each VIEW into a separate data partition.


[[SQlite]]