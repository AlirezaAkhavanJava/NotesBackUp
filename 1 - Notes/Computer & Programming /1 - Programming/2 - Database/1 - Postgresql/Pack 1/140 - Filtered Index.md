

**Filtered Index in PostgreSQL = Partial Index**

PostgreSQL doesn’t call it “filtered index”; the correct term is **partial index**.

---

## 1. What it is

A **partial index** indexes **only rows that satisfy a WHERE condition**.

So instead of indexing the whole table, you index a **subset**.

---

## 2. Why it exists (the problem it solves)

Normal indexes:

- Bigger
    
- Slower to maintain
    
- Often wasted on rows you never query
    

Partial indexes:

- Smaller
    
- Faster
    
- Optimized for specific queries
    

---

## 3. Syntax (how to create)

```sql
CREATE INDEX idx_active_users
ON users (email)
WHERE active = true;
```

Only rows where `active = true` are indexed.

---

## 4. How PostgreSQL uses it

PostgreSQL will use the index **only if your query’s WHERE clause matches the index condition**.

✅ Uses the index:

```sql
SELECT * FROM users
WHERE active = true AND email = 'a@b.com';
```

❌ Does NOT use the index:

```sql
SELECT * FROM users
WHERE email = 'a@b.com';
```

or

```sql
SELECT * FROM users
WHERE active = false;
```

---

## 5. Common real-world use cases

### Soft deletes

```sql
CREATE INDEX idx_not_deleted
ON orders (created_at)
WHERE deleted_at IS NULL;
```

### Status-based filtering

```sql
CREATE INDEX idx_pending_orders
ON orders (customer_id)
WHERE status = 'PENDING';
```

### Boolean flags

```sql
CREATE INDEX idx_verified_users
ON users (id)
WHERE verified = true;
```

---

## 6. Partial UNIQUE index

Very powerful.

```sql
CREATE UNIQUE INDEX uniq_active_email
ON users (email)
WHERE active = true;
```

Meaning:

- Active users must have unique emails
    
- Inactive users can duplicate emails
    

---

## 7. When to use (and when NOT)

### Use when:

- You frequently query a **specific subset**
    
- The subset is **much smaller** than the table
    
- Conditions are **stable**
    

### Do NOT use when:

- Queries don’t include the filter condition
    
- Filter condition changes often
    
- You need general-purpose indexing
    

---

## 8. Compare with normal index

|Feature|Normal Index|Partial Index|
|---|---|---|
|Size|Larger|Smaller|
|Speed|Medium|Faster|
|Flexibility|General|Specific|
|Maintenance|Higher|Lower|

---

## 9. Key rule (important)

> **Query WHERE clause must logically imply the index condition**

Otherwise PostgreSQL ignores it.

---

### Bottom line

A **filtered index in PostgreSQL = partial index**.  
Use it when you know **exactly which rows matter** and want **maximum performance with minimal index cost**.


##### Tags : [[1 - SQL 🦬]]