
A **SQL view** is best understood as a **named, reusable query that behaves like a virtual table**.

The important part is not merely knowing `CREATE VIEW`; it is knowing **when a view improves your database design** and when it just adds unnecessary abstraction.

---

# 1. What is a View?

Suppose you have:

```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY,
    username TEXT,
    email TEXT,
    password_hash TEXT
);

CREATE TABLE tasks (
    id BIGINT PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    title TEXT,
    completed BOOLEAN
);
```

You frequently need:

> "Give me each user's tasks, but don't expose their password hash."

You could repeatedly write:

```sql
SELECT
    u.id,
    u.username,
    u.email,
    t.id AS task_id,
    t.title,
    t.completed
FROM users u
JOIN tasks t ON t.user_id = u.id;
```

Instead, create a view:

```sql
CREATE VIEW user_tasks AS
SELECT
    u.id AS user_id,
    u.username,
    u.email,
    t.id AS task_id,
    t.title,
    t.completed
FROM users u
JOIN tasks t ON t.user_id = u.id;
```

Now:

```sql
SELECT *
FROM user_tasks;
```

The view gives the query a **name**.

Conceptually:

```text
              ┌─────────────┐
users ───────►│             │
              │   VIEW      │──────► SELECT
tasks ───────►│ user_tasks  │
              │             │
              └─────────────┘
```

The underlying tables still contain the actual data.

---

# 2. A View Is Not Normally a Copy of the Data

This distinction is critical.

```sql
CREATE VIEW active_tasks AS
SELECT *
FROM tasks
WHERE completed = false;
```

The view normally **doesn't store another copy of the rows**.

Think:

```text
Table
  ↓
stored data

View
  ↓
stored SQL query
```

When you execute:

```sql
SELECT *
FROM active_tasks;
```

the database uses the view's definition as part of the query.

Therefore, if the underlying data changes:

```sql
UPDATE tasks
SET completed = true
WHERE id = 5;
```

then:

```sql
SELECT *
FROM active_tasks;
```

will reflect that change.

---

# 3. Why Are Views Useful?

There are several major use cases.

## 3.1 Hide query complexity

This is probably the most common reason.

Imagine:

```sql
SELECT
    u.username,
    COUNT(t.id) AS total_tasks,
    COUNT(*) FILTER (WHERE t.completed) AS completed_tasks
FROM users u
LEFT JOIN tasks t
    ON t.user_id = u.id
GROUP BY u.id, u.username;
```

You could turn that into:

```sql
CREATE VIEW user_task_statistics AS
SELECT
    u.username,
    COUNT(t.id) AS total_tasks,
    COUNT(*) FILTER (WHERE t.completed) AS completed_tasks
FROM users u
LEFT JOIN tasks t
    ON t.user_id = u.id
GROUP BY u.id, u.username;
```

Then application code can simply:

```sql
SELECT *
FROM user_task_statistics;
```

This is particularly useful when the query is used in many places.

---

# 4. Views Create a Database-Level Abstraction

This is where views become interesting from a software-engineering perspective.

Your physical schema might be:

```text
users
tasks
task_labels
labels
task_history
...
```

But your application might conceptually need:

```text
TaskSummary
```

A view can provide that abstraction:

```sql
CREATE VIEW task_summary AS
SELECT
    t.id,
    t.title,
    u.username,
    t.completed
FROM tasks t
JOIN users u
    ON u.id = t.user_id;
```

Now:

```sql
SELECT *
FROM task_summary;
```

The application doesn't need to know that `username` comes from another table.

This is similar to creating an **API over your relational schema**.

---

# 5. Views Are Excellent for Security

Suppose:

```sql
users
--------------------------------
id
username
email
password_hash
phone
address
```

You want some database user/application to access user information but **not passwords**.

Create:

```sql
CREATE VIEW public_users AS
SELECT
    id,
    username,
    email
FROM users;
```

Then expose:

```sql
SELECT *
FROM public_users;
```

instead of:

```sql
SELECT *
FROM users;
```

In PostgreSQL, you can combine this with privileges:

```sql
REVOKE SELECT ON users FROM app_user;

GRANT SELECT ON public_users TO app_user;
```

Now the database itself participates in enforcing the boundary.

That's much stronger than merely telling your Java developer:

> "Please don't select `password_hash`."

---

# 6. Views Are Great for Reporting

Imagine an e-commerce database:

```text
customers
orders
order_items
products
```

You might need:

```text
customer_id
customer_name
number_of_orders
total_spent
```

Create:

```sql
CREATE VIEW customer_sales AS
SELECT
    c.id AS customer_id,
    c.name AS customer_name,
    COUNT(DISTINCT o.id) AS number_of_orders,
    COALESCE(SUM(oi.quantity * oi.price), 0) AS total_spent
FROM customers c
LEFT JOIN orders o
    ON o.customer_id = c.id
LEFT JOIN order_items oi
    ON oi.order_id = o.id
GROUP BY c.id, c.name;
```

Then:

```sql
SELECT *
FROM customer_sales
ORDER BY total_spent DESC;
```

You have essentially created a reusable **reporting interface**.

---

# 7. Filtering Through Views

A particularly useful pattern:

```sql
CREATE VIEW active_tasks AS
SELECT
    id,
    user_id,
    title
FROM tasks
WHERE completed = false;
```

Then:

```sql
SELECT *
FROM active_tasks
WHERE user_id = 10;
```

Notice the difference:

```text
View definition:
    "What is an active task?"

Query:
    "Which active tasks belong to user 10?"
```

This separation can make SQL considerably easier to reason about.

---

# 8. Don't Put Every Query Into a View

This is where people misuse views.

Bad thinking:

> "I have a SELECT query, therefore I should make a view."

No.

A view is useful when the query represents a **stable, meaningful relational concept**.

Good:

```sql
active_tasks
user_task_statistics
customer_sales
public_users
available_products
```

Less useful:

```sql
CREATE VIEW tasks_for_user_17 AS
SELECT *
FROM tasks
WHERE user_id = 17;
```

That's application-specific data, not a useful abstraction.

Instead:

```sql
CREATE VIEW user_tasks AS
SELECT *
FROM tasks;
```

and:

```sql
SELECT *
FROM user_tasks
WHERE user_id = 17;
```

---

# 9. PostgreSQL

In PostgreSQL:

```sql
CREATE VIEW active_tasks AS
SELECT *
FROM tasks
WHERE completed = false;
```

Inspect it:

```sql
\d active_tasks
```

or:

```sql
\dv
```

Inside `psql`.

You can also query PostgreSQL's catalog:

```sql
SELECT *
FROM information_schema.views;
```

Delete:

```sql
DROP VIEW active_tasks;
```

Replace its definition:

```sql
CREATE OR REPLACE VIEW active_tasks AS
SELECT
    id,
    user_id,
    title,
    completed
FROM tasks
WHERE completed = false;
```

---

# 10. SQLite

SQLite supports views too.

```sql
CREATE VIEW active_tasks AS
SELECT
    id,
    user_id,
    title
FROM tasks
WHERE completed = 0;
```

Then:

```sql
SELECT *
FROM active_tasks;
```

List views:

```sql
SELECT name
FROM sqlite_schema
WHERE type = 'view';
```

Inspect:

```sql
.schema active_tasks
```

Remove:

```sql
DROP VIEW active_tasks;
```

SQLite's boolean handling is slightly different from PostgreSQL:

```text
PostgreSQL:
BOOLEAN
TRUE / FALSE

SQLite:
no native BOOLEAN storage class
0 / 1 commonly used
```

So you'll commonly see:

```sql
WHERE completed = 0
```

in SQLite.

---

# 11. PostgreSQL vs SQLite

The basic concept is almost identical:

|Feature|PostgreSQL|SQLite|
|---|---|---|
|`CREATE VIEW`|Yes|Yes|
|`DROP VIEW`|Yes|Yes|
|`CREATE OR REPLACE VIEW`|Yes|No|
|View stores normal rows|No|No|
|Can query view with `SELECT`|Yes|Yes|
|Can join views|Yes|Yes|
|Can use aggregation|Yes|Yes|
|Materialized views|**Yes**|**No native equivalent**|

That last distinction is important.

---

# 12. View vs Materialized View

PostgreSQL also has:

```sql
CREATE MATERIALIZED VIEW ...
```

Unlike an ordinary view, a materialized view **stores the result**.

Ordinary view:

```text
tables
  ↓
query
  ↓
result
```

Materialized view:

```text
tables
  ↓
query
  ↓
stored result
```

Example:

```sql
CREATE MATERIALIZED VIEW monthly_sales AS
SELECT
    DATE_TRUNC('month', created_at) AS month,
    SUM(amount) AS total
FROM orders
GROUP BY DATE_TRUNC('month', created_at);
```

Then:

```sql
SELECT *
FROM monthly_sales;
```

But if the underlying orders change, the materialized view doesn't automatically change.

Refresh:

```sql
REFRESH MATERIALIZED VIEW monthly_sales;
```

This is useful when:

- query is expensive
    
- data doesn't need real-time freshness
    
- result is queried frequently
    

---

# 13. Views and Spring Boot

This is where views become particularly useful for you as a backend developer.

Suppose your database has:

```text
users
tasks
categories
task_history
```

Your Java application might need:

```text
TaskSummary
```

Instead of putting a giant SQL query into your repository:

```java
@Query("""
    SELECT ...
    FROM tasks t
    JOIN users u ...
    JOIN categories c ...
    ...
""")
```

you can have:

```sql
CREATE VIEW task_summary AS
SELECT
    t.id,
    t.title,
    t.completed,
    u.username,
    c.name AS category
FROM tasks t
JOIN users u
    ON u.id = t.user_id
JOIN categories c
    ON c.id = t.category_id;
```

Then your repository can query:

```sql
SELECT *
FROM task_summary
WHERE user_id = ?;
```

This gives you a clean separation:

```text
Database
    │
    ├── tables
    │      └── normalized storage
    │
    └── views
           └── application-oriented representations
                    │
                    ▼
                Spring Boot
                    │
                    ▼
                   DTO
```

This is a powerful pattern when used deliberately.

---

# 14. Views and Database Normalization

Views become especially valuable with normalized databases.

You might deliberately normalize:

```text
users
tasks
categories
task_categories
labels
task_labels
```

That's good for data integrity.

But querying the normalized structure can become complicated.

A view can provide a convenient **denormalized read model**:

```text
Normalized tables
       │
       ▼
      VIEW
       │
       ▼
Convenient read representation
```

This gives you:

> **Normalized storage + convenient querying**

without physically duplicating the data.

---

# 15. A Smart Pattern: Write Model vs Read Model

For more advanced systems, think of views as **read models**.

For example:

```text
                    DATABASE
                       │
          ┌────────────┴────────────┐
          │                         │
     Base tables                  Views
          │                         │
          ▼                         ▼
   Write-oriented data       Read-oriented data
          │                         │
          ▼                         ▼
      INSERT/UPDATE              SELECT
```

Your tables are optimized around:

- integrity
    
- normalization
    
- relationships
    

Your views can be optimized around:

- querying
    
- reporting
    
- application consumption
    
- security
    
- abstraction
    

This is one of the smartest ways to use views.

---

# 16. One Important Performance Myth

Don't assume:

> "A view makes my query faster."

Usually, **a normal view doesn't inherently make a query faster**.

It primarily gives you:

- abstraction
    
- reuse
    
- security
    
- cleaner SQL
    
- consistent definitions
    

The database optimizer may expand the view into the surrounding query and optimize the whole thing.

For example:

```sql
SELECT *
FROM active_tasks
WHERE user_id = 10;
```

can often be optimized similarly to:

```sql
SELECT *
FROM tasks
WHERE completed = false
AND user_id = 10;
```

For actual stored/cached results, PostgreSQL's **materialized views** are the relevant tool.

---

# 17. The Mental Model I Want You to Keep

Think about SQL objects like this:

```text
TABLE
│
├── stores data
│
└── source of truth


VIEW
│
├── stores a query
│
├── doesn't normally store result rows
│
└── reusable logical representation


MATERIALIZED VIEW
│
├── stores query result
│
├── faster for some expensive reads
│
└── must be refreshed
```

And ask yourself:

> **"Is this query representing a meaningful concept that I want the database to expose repeatedly?"**

If yes → **consider a view.**

If it's simply a one-off query → **just write the query.**

If the query is expensive and repeatedly read → **consider a materialized view in PostgreSQL.**

If the purpose is hiding sensitive columns → **view + privileges is particularly powerful.**

For your Spring Boot/PostgreSQL work, I'd especially focus on **views + indexes + query plans (`EXPLAIN ANALYZE`) + materialized views**, because that's where views stop being just a SQL feature and become part of database architecture.


[[SQlite]]
[[PostgreSQL]]