

The core difference is **lifetime and purpose**:

> **CTE = temporary query structure for one SQL statement.**  
> **View = persistent named query stored in the database.**

## Side-by-side

||CTE|View|
|---|---|---|
|Syntax|`WITH ... AS (...)`|`CREATE VIEW ... AS ...`|
|Lifetime|One SQL statement|Persistent|
|Stored in DB schema|❌|✅|
|Reusable across queries|❌|✅|
|Name|Yes|Yes|
|Usually used for|Complex query construction|Reusable data abstraction|
|Can query tables|✅|✅|
|Can query other views|✅|✅|
|Recursive queries|✅|❌ directly; use recursive CTE|
|Temporary|✅|❌ normally|
|Data copied|❌|❌|

---

# Same problem, two approaches

Suppose:

```sql
orders
```

contains:

```text
id | customer_id | amount
```

You want customers whose total purchases exceed `1000`.

### CTE

```sql
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(amount) AS total
    FROM orders
    GROUP BY customer_id
)
SELECT *
FROM customer_totals
WHERE total > 1000;
```

The lifecycle is:

```text
WITH
 ↓
customer_totals
 ↓
SELECT
 ↓
DONE
 ↓
customer_totals disappears
```

If you execute:

```sql
SELECT * FROM customer_totals;
```

afterward, it doesn't exist.

---

# View

You could instead create:

```sql
CREATE VIEW customer_totals AS
SELECT
    customer_id,
    SUM(amount) AS total
FROM orders
GROUP BY customer_id;
```

Then use it repeatedly:

```sql
SELECT *
FROM customer_totals
WHERE total > 1000;
```

Later:

```sql
SELECT AVG(total)
FROM customer_totals;
```

And:

```sql
SELECT *
FROM customer_totals
ORDER BY total DESC;
```

The view remains available.

```text
Database
   │
   ├── orders
   │
   └── customer_totals (VIEW)
             │
             ▼
       SELECT query
```

---

# The most useful mental model

Think about **scope**:

```text
CTE
┌──────────────────────────────┐
│ ONE SQL STATEMENT             │
│                              │
│ WITH customer_totals AS (...)│
│                              │
│ SELECT ...                   │
└──────────────────────────────┘
               ↓
            gone
```

Versus:

```text
VIEW
┌──────────────────────────────┐
│ DATABASE                      │
│                              │
│ customer_totals VIEW         │
│          ↓                   │
│     underlying query         │
└──────────────────────────────┘
       ↓       ↓       ↓
    Query 1  Query 2  Query 3
```

---

# When should you choose which?

### Use a CTE when:

You're **building one complex query**.

```sql
WITH filtered AS (...),
     aggregated AS (...),
     ranked AS (...)
SELECT ...
FROM ranked;
```

It lets you express your query as a sequence of logical operations.

---

### Use a View when:

You've identified a **reusable database-level concept**.

For example:

```sql
CREATE VIEW active_users AS ...
```

Now every query can use:

```sql
SELECT * FROM active_users;
```

You are essentially creating a reusable **database abstraction**.

---

## A practical rule

Ask yourself:

> **"Will I need this query structure again in another SQL statement?"**

**No → CTE**

**Yes → View**

There is one important nuance: a CTE can also be referenced **multiple times within the same statement**, so don't think of it strictly as "used once." Its scope is **one statement**, not one reference.

And neither CTEs nor ordinary views are automatically stored copies of the data. They represent query logic; the underlying data remains in the base tables.


[[SQlite]]