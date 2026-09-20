

## 🧠 1️⃣ What is `EXPLAIN`?

`EXPLAIN` is a **debugging and analysis tool** in SQL that shows _how PostgreSQL plans to execute your query._

It doesn’t run the query (unless you tell it to with `ANALYZE`).  
It just tells you **what the planner will do** — which indexes, joins, scans, etc.

So:

> `EXPLAIN` = “Show me the _execution plan_ of this SQL statement.”

---

## 🧩 2️⃣ Basic Syntax

```sql
EXPLAIN SELECT * FROM users WHERE age > 30;
```

Output example:

```
Seq Scan on users  (cost=0.00..35.50 rows=10 width=100)
  Filter: (age > 30)
```

---

## 💬 3️⃣ What It Means

|Term|Meaning|
|---|---|
|**Seq Scan**|PostgreSQL is doing a **sequential scan** — reading the whole table.|
|**cost**|An _estimated cost_ (time units, not seconds). Lower = faster.|
|**rows**|Estimated number of rows it expects to return.|
|**width**|Average size (in bytes) of one row.|

---

## ⚡ 4️⃣ `EXPLAIN ANALYZE`

Now this one **actually runs the query** and shows _real execution time_.

```sql
EXPLAIN ANALYZE SELECT * FROM users WHERE age > 30;
```

Output:

```
Seq Scan on users  (cost=0.00..35.50 rows=10 width=100)
                   (actual time=0.020..0.030 rows=12 loops=1)
  Filter: (age > 30)
Planning Time: 0.045 ms
Execution Time: 0.056 ms
```

Here:

- `actual time` = real measured time in milliseconds.
    
- `rows` = actual number returned.
    
- `loops` = how many times that operation was run (important for nested loops).
    

---

## 🔍 5️⃣ Common Plan Types

|Plan|Meaning|
|---|---|
|**Seq Scan**|Full table scan. Slow for big tables.|
|**Index Scan**|Uses an index to find rows faster.|
|**Index Only Scan**|Uses only the index (no table read). Super fast.|
|**Bitmap Heap Scan**|Uses index bitmap to fetch multiple rows efficiently.|
|**Nested Loop**|For small joins. One table loops over another.|
|**Hash Join**|Builds a hash table for one side of a join (fast for large sets).|
|**Merge Join**|Sorts both sides, then merges them (good for sorted inputs).|
|**CTE Scan / Subquery Scan**|Reading from subqueries or common table expressions.|

---

## 🧮 6️⃣ Cost Breakdown

Example:

```
(cost=0.00..35.50 rows=10 width=100)
```

- `0.00` → **startup cost** (before first row).
    
- `35.50` → **total cost** (to produce all rows).
    
- These are _estimated units_ used by the optimizer to compare plans.
    

They are not seconds — they’re **relative**.

---

## 🧰 7️⃣ Why It Matters

- Detect if your query is **using an index**.
    
- See if it’s doing **too many sequential scans**.
    
- Compare **real vs estimated rows** → shows if stats are outdated.
    
- Optimize JOINs and WHERE clauses.
    

---

## 🧩 8️⃣ Example Comparison

### ❌ Without Index

```sql
EXPLAIN SELECT * FROM users WHERE id = 5;
```

```
Seq Scan on users (cost=0.00..12.00 rows=1)
  Filter: (id = 5)
```

### ✅ With Index

```sql
CREATE INDEX idx_users_id ON users(id);
EXPLAIN SELECT * FROM users WHERE id = 5;
```

```
Index Scan using idx_users_id on users (cost=0.15..8.17 rows=1)
```

Now PostgreSQL uses the index — faster!

---

## 🧠 9️⃣ Quick Summary

|Command|Action|
|---|---|
|`EXPLAIN`|Shows _planned_ query execution.|
|`EXPLAIN ANALYZE`|Runs the query and shows _actual performance_.|
|`Seq Scan`|Full table read — usually bad for big tables.|
|`Index Scan`|Efficient read — uses an index.|
|`cost` / `rows` / `width`|Planner’s estimates.|
|`actual time`|Real performance (only with ANALYZE).|

---


##### Tags : [[1 - SQL 🥞]]