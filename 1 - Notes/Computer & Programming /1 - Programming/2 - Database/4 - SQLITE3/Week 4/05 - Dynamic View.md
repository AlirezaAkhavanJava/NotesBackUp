
**A normal SQL view is dynamic and stays connected to the original tables.**

A view does **not store the result data**. It stores the **query definition**.

Example:

```sql
CREATE TABLE users (
    id INTEGER,
    name TEXT,
    age INTEGER
);

CREATE VIEW adult_users AS
SELECT *
FROM users
WHERE age >= 18;
```

The view internally stores:

```sql
SELECT *
FROM users
WHERE age >= 18;
```

Now:

```sql
SELECT * FROM adult_users;
```

SQLite executes the view query **at that moment**.

---

## Example: Dynamic behavior

Initial table:

```text
users

id | name | age
---+------+----
1  | Ali  | 25
2  | Bob  | 15
```

Query the view:

```sql
SELECT * FROM adult_users;
```

Result:

```text
1 | Ali | 25
```

Now insert a new row:

```sql
INSERT INTO users VALUES (3, 'Sara', 30);
```

Query the view again:

```sql
SELECT * FROM adult_users;
```

Result:

```text
1 | Ali  | 25
3 | Sara | 30
```

The view automatically sees the new data.

---

## Important distinction

### View

```text
CREATE VIEW
      |
      ▼
Stores SQL query
      |
      ▼
Runs query every time you SELECT
      |
      ▼
Gets current data
```

### Materialized View (not in SQLite)

```text
CREATE MATERIALIZED VIEW
      |
      ▼
Runs query once
      |
      ▼
Stores result data
      |
      ▼
Needs refresh
```

Materialized views are useful for expensive calculations.

Example:

```text
Millions of sales records
        |
        ▼
Complex aggregation
        |
        ▼
Stored summary
```

---

## Can you update the original table through a view?

Sometimes.

Example:

```sql
CREATE VIEW simple_users AS
SELECT id, name
FROM users;
```

This may allow:

```sql
UPDATE simple_users
SET name = 'Ali Reza'
WHERE id = 1;
```

But views with:

- `JOIN`
    
- `GROUP BY`
    
- `SUM()`
    
- `AVG()`
    
- `DISTINCT`
    
- aggregate functions
    

are usually **not directly updatable**.

Example:

```sql
CREATE VIEW sales_summary AS
SELECT customer, SUM(amount)
FROM orders
GROUP BY customer;
```

You cannot update:

```sql
UPDATE sales_summary
SET SUM(amount)=500;
```

because that value does not physically exist.

---

Professional definition:

> A SQL view is a **virtual table whose rows are generated dynamically from its underlying query whenever it is accessed**. It provides a logical abstraction layer over physical tables.


[[SQlite]]