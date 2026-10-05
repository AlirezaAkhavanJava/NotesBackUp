

A **temporary view** is a view that exists **only during the current database connection/session**.

When you close the SQLite connection, the view disappears automatically.

---

## Normal view

```sql
CREATE VIEW adult_users AS
SELECT *
FROM users
WHERE age >= 18;
```

Lifetime:

```text
Create view
     |
     ▼
Stored in database file
     |
     ▼
Available after closing and reopening SQLite
```

---

## Temporary view

Syntax:

```sql
CREATE TEMP VIEW adult_users AS
SELECT *
FROM users
WHERE age >= 18;
```

or:

```sql
CREATE TEMPORARY VIEW adult_users AS
SELECT *
FROM users
WHERE age >= 18;
```

Lifetime:

```text
Create temp view
        |
        ▼
Current SQLite session
        |
        ▼
Exit sqlite3
        |
        ▼
View deleted
```

---

## Example

Open SQLite:

```bash
sqlite3 test.db
```

Create temporary view:

```sql
CREATE TEMP VIEW expensive_products AS
SELECT *
FROM products
WHERE price > 100;
```

Use it:

```sql
SELECT * FROM expensive_products;
```

Exit:

```sql
.quit
```

Open again:

```bash
sqlite3 test.db
```

Try:

```sql
SELECT * FROM expensive_products;
```

Result:

```
Error: no such table: expensive_products
```

Because the temporary view is gone.

---

## Where are temporary views stored?

SQLite has a special temporary database:

```text
main database
    |
    ├── tables
    ├── views
    └── indexes


temp database
    |
    ├── temporary tables
    └── temporary views
```

You can see them:

```sql
SELECT name
FROM sqlite_temp_schema
WHERE type = 'view';
```

---

## When are temporary views useful?

### 1. Complex analysis

Instead of writing:

```sql
SELECT *
FROM (
    SELECT ...
    JOIN ...
    WHERE ...
)
WHERE ...
```

you create a temporary view:

```sql
CREATE TEMP VIEW analysis AS
SELECT ...
```

Then:

```sql
SELECT *
FROM analysis;
```

---

### 2. Scripts and data processing

Example:

```bash
sqlite3 database.db < report.sql
```

Your script:

```sql
CREATE TEMP VIEW monthly_sales AS
SELECT ...
;

SELECT *
FROM monthly_sales;
```

The view exists only while the script runs.

---

### 3. Testing

You can experiment without changing the database structure permanently.

---

## Difference summary

|Feature|View|Temporary View|
|---|---|---|
|Stored permanently|Yes|No|
|Saved in `.db` file|Yes|No|
|Exists after restart|Yes|No|
|Uses `SELECT` query|Yes|Yes|
|Data copied|No|No|

Mental model:

> A normal view is a **saved query in the database**.  
> A temporary view is a **saved query in your current session only**.


[[SQlite]]