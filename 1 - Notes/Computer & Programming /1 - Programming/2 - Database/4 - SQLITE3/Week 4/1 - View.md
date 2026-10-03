
In SQLite3, **VIEW** is a virtual table based on the result set of a SELECT statement. It's a stored query that acts like a table but doesn't store data itself.

## Creating a VIEW

```sql
CREATE VIEW view_name AS
SELECT column1, column2, ...
FROM table_name
WHERE condition;
```

### Example:
```sql
-- Create a view for active customers
CREATE VIEW active_customers AS
SELECT customer_id, name, email
FROM customers
WHERE status = 'active';
```

## Using a VIEW

Once created, you can query it like a regular table:

```sql
SELECT * FROM active_customers;
SELECT * FROM active_customers WHERE name LIKE 'J%';
```

## Types of VIEWs

### 1. Simple VIEW
Based on a single table:
```sql
CREATE VIEW high_salary_employees AS
SELECT * FROM employees WHERE salary > 100000;
```

### 2. Complex VIEW
Based on joins, aggregations, etc.:
```sql
CREATE VIEW customer_orders_summary AS
SELECT 
    c.customer_id,
    c.name,
    COUNT(o.order_id) AS total_orders,
    SUM(o.amount) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name;
```

## Replacing/Dropping a VIEW

```sql
-- Replace an existing view
CREATE VIEW view_name AS SELECT ...;  -- Use DROP first, then CREATE

-- SQLite doesn't support CREATE OR REPLACE VIEW, so:
DROP VIEW IF EXISTS view_name;
CREATE VIEW view_name AS SELECT ...;

-- Drop a view
DROP VIEW view_name;
DROP VIEW IF EXISTS view_name;
```

## Listing VIEWs

```sql
-- List all views in the database
SELECT name FROM sqlite_master 
WHERE type = 'view';

-- Or in SQLite CLI
.tables
```

## Key Points About SQLite VIEWs

| Feature | Support |
|---------|---------|
| Read-only views | ✅ Yes |
| Updatable views | ⚠️ Limited (simple views only) |
| Materialized views | ❌ Not supported |
| Indexes on views | ❌ Not supported |
| Parameters in views | ❌ Not supported |
| Triggers on views | ❌ Not supported (INSTEAD OF triggers work in some cases) |

## Updatable Views

SQLite allows INSERT/UPDATE/DELETE on views if:
- The view is based on a single table
- No DISTINCT, GROUP BY, HAVING, LIMIT, or aggregate functions
- All columns are direct references (no expressions)

```sql
-- This view is updatable
CREATE VIEW active_users AS
SELECT id, name, email FROM users WHERE active = 1;

-- You can do:
UPDATE active_users SET name = 'John' WHERE id = 1;
```

## Practical Use Cases

1. **Simplify complex queries** — hide joins/aggregations
2. **Security** — expose only certain columns/rows
3. **Compatibility** — provide a stable interface when schema changes
4. **Reusability** — avoid repeating complex SQL

## Limitation Example

```sql
-- This view is NOT updatable (has aggregation)
CREATE VIEW order_totals AS
SELECT customer_id, SUM(amount) AS total
FROM orders GROUP BY customer_id;

-- This will fail:
INSERT INTO order_totals VALUES (1, 500);  -- Error
```

## Checking if a View is Updatable

SQLite doesn't have a direct function, but you can test by attempting an operation, or check the view definition — if it's simple (single table, no aggregates/DISTINCT/GROUP BY), it's likely updatable.




[[SQlite]]