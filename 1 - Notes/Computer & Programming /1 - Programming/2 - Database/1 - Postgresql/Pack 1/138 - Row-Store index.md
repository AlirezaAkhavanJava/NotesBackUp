

## 1️⃣ What is a **Row-Store index** in PostgreSQL?

**Truth first:**  
PostgreSQL **does NOT have a feature officially called “Row-Store index.”**

PostgreSQL is a **row-oriented database by default**.  
So when people say **“row-store index”**, they usually mean:

> **Standard PostgreSQL indexes that reference rows in a row-oriented table**

Examples:

- **B-Tree index** (most common)
    
- Hash index
    
- GiST, GIN, SP-GiST, BRIN
    

All of these **point to table rows (TIDs)**, not column fragments.

👉 In contrast:

- **Column stores** (ClickHouse, BigQuery) index columns separately
    
- PostgreSQL stores **entire rows together on disk**
    

---

## 2️⃣ How PostgreSQL Row Storage Works (important)

- Table = sequence of **heap pages**
    
- Each page = multiple **full rows**
    
- Index stores:
    
    ```
    indexed_value → (block_id, row_offset)
    ```
    

So an index **does NOT store the row**, only a **pointer to the row**.

---

## 3️⃣ How to Create a “Row-Store” Index (aka normal index)

### ✅ B-Tree (default, 90% of cases)

```sql
CREATE INDEX idx_student_email
ON student(email);
```

Used for:

- `=`
    
- `< > <= >=`
    
- `ORDER BY`
    
- `BETWEEN`
    

---

### ✅ Unique index

```sql
CREATE UNIQUE INDEX idx_student_email_unique
ON student(email);
```

---

### ✅ Composite (multi-column)

```sql
CREATE INDEX idx_student_name_dob
ON student(last_name, date_of_birth);
```

⚠ Order matters:

- Works for `(last_name)`
    
- Works for `(last_name, date_of_birth)`
    
- ❌ Not for `(date_of_birth)` alone
    

---

### ✅ Partial index (very powerful)

```sql
CREATE INDEX idx_active_students
ON student(id)
WHERE active = true;
```

---

## 4️⃣ How to Use It (You don’t “call” indexes)

PostgreSQL **automatically uses indexes** via the query planner.

Example:

```sql
SELECT *
FROM student
WHERE email = 'a@b.com';
```

If indexed → **Index Scan**  
If not → **Seq Scan (slow)**

### Check if index is used

```sql
EXPLAIN ANALYZE
SELECT *
FROM student
WHERE email = 'a@b.com';
```

Look for:

- `Index Scan`
    
- ❌ `Seq Scan`
    

---

## 5️⃣ Where to Use Row-Store Indexes (Best Use Cases)

### ✅ OLTP systems (CRUD apps)

Perfect for:

- Spring Boot + JPA
    
- REST APIs
    
- Banking systems
    
- E-commerce
    
- User tables
    

### ✅ Queries that:

- Filter by row attributes
    
- Fetch **full rows**
    
- Use `WHERE`, `JOIN`, `ORDER BY`
    

Example:

```sql
SELECT *
FROM orders
WHERE user_id = 10
ORDER BY created_at DESC;
```

---

## 6️⃣ Where Row-Store Indexes Are BAD

❌ Analytics:

```sql
SELECT SUM(amount)
FROM orders
WHERE created_at >= '2024-01-01';
```

Why?

- PostgreSQL still fetches **entire rows**
    
- Column stores only read required columns
    

👉 For analytics:

- Use **BRIN**
    
- Use **covering indexes**
    
- Or move to **column DB**
    

---

## 7️⃣ Row-Store vs Column-Store (Quick Table)

|Feature|Row Store (Postgres)|Column Store|
|---|---|---|
|Storage|Full rows together|Columns separate|
|Best for|OLTP|Analytics|
|Index points to|Row (TID)|Column blocks|
|PostgreSQL default|✅ Yes|❌ No|

---

## 8️⃣ Advanced Tip (Covering Index)

Still row-store, but faster:

```sql
CREATE INDEX idx_order_user
ON orders(user_id)
INCLUDE (amount, status);
```

Query:

```sql
SELECT amount, status
FROM orders
WHERE user_id = 5;
```

👉 **Index-only scan** (no table hit)

---

## Bottom Line (Brutally Honest)

- ❌ “Row-store index” is **not a real Postgres term**
    
- ✅ PostgreSQL **is row-store**
    
- ✅ Normal indexes = what people mean
    
- ✅ Best for **transactional systems**
    
- ❌ Bad for heavy analytics
    

---

###### Tags : [[1 - SQL 🦬]]