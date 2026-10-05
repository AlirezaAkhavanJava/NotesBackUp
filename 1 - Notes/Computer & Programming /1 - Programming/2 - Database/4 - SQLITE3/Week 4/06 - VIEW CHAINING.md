
**A view can be created from another view.** This is called **view chaining** or **nested views**.

A view does not have to use only physical tables. Its `SELECT` statement can read from:

- tables
    
- other views
    
- joins between tables and views
    

---

## Example

Create a base table:

```sql
CREATE TABLE employees (
    id INTEGER,
    name TEXT,
    department TEXT,
    salary INTEGER
);
```

Create the first view:

```sql
CREATE VIEW engineering_employees AS
SELECT *
FROM employees
WHERE department = 'Engineering';
```

Now create another view from that view:

```sql
CREATE VIEW high_paid_engineers AS
SELECT name, salary
FROM engineering_employees
WHERE salary > 100000;
```

Now:

```sql
SELECT * FROM high_paid_engineers;
```

Internally SQLite does something like:

```text
high_paid_engineers
        |
        ▼
engineering_employees
        |
        ▼
employees table
```

The database expands the views until it reaches the real tables.

---

## Why create views from views?

### 1. Reuse logic

Instead of repeating:

```sql
SELECT *
FROM employees
WHERE department = 'Engineering'
```

everywhere, create it once.

Then:

```sql
SELECT *
FROM engineering_employees
WHERE salary > 100000;
```

---

### 2. Layer complexity

Large systems often build layers:

```
Raw tables
     |
     ▼
Base views
(clean columns, joins)
     |
     ▼
Business views
(calculations, rules)
     |
     ▼
Reports
(dashboards, analytics)
```

Example:

```
orders
customers
products
   |
   ▼
customer_orders_view
   |
   ▼
customer_sales_summary_view
   |
   ▼
monthly_report_view
```

---

## But be careful: too many layers

You can create a problem called **view explosion**:

```
View A
  |
  ▼
View B
  |
  ▼
View C
  |
  ▼
View D
  |
  ▼
Table
```

Problems:

- harder debugging
    
- harder performance analysis
    
- unclear data origin
    
- complex SQL execution plans
    

Professional practice:

- Use views to simplify repeated logic.
    
- Keep important business rules documented.
    
- Avoid creating dozens of unnecessary view layers.
    

---

## SQLite example: checking dependencies

SQLite stores view definitions in:

```sql
SELECT name, sql
FROM sqlite_schema
WHERE type = 'view';
```

You can see which views depend on other views by reading the stored SQL.

So the short answer:

> Yes, views can be built on top of other views. A view hierarchy behaves like a chain of queries that eventually resolves to the underlying tables.


[[SQlite]]