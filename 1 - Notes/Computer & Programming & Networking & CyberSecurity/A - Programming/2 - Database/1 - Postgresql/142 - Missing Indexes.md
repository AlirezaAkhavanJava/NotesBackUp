
## Missing Indexes in PostgreSQL (truth, no myths)

**Important upfront:**  
PostgreSQL has **no built-in “missing index” feature** like SQL Server.  
Missing indexes are **inferred**, not reported.

---

## 1. What “missing index” really means

A **missing index** is an index that **should exist** because:

- Queries do **Seq Scan**
    
- Filters / joins are selective
    
- Execution time is high
    
- Planner had no usable index
    

Postgres will **never tell you** “create this index” automatically.

---

## 2. Primary signal: Sequential scans

```sql
SELECT
  relname,
  seq_scan,
  seq_tup_read,
  idx_scan
FROM pg_stat_user_tables
ORDER BY seq_tup_read DESC;
```

🚨 Red flags:

- High `seq_scan`
    
- Huge `seq_tup_read`
    
- Low or zero `idx_scan`
    

---

## 3. Find slow queries (root cause)

Enable slow query logging:

```conf
log_min_duration_statement = 200ms
```

Then analyze queries doing full table scans.

---

## 4. Use EXPLAIN ANALYZE (non-negotiable)

```sql
EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_id = 42;
```

Look for:

- `Seq Scan on orders`
    
- `Filter: (customer_id = 42)`
    
- Large “rows removed by filter”
    

👉 That column likely needs an index.

---

## 5. pg_stat_statements (MOST IMPORTANT)

Enable it:

```conf
shared_preload_libraries = 'pg_stat_statements'
```

Query it:

```sql
SELECT
  query,
  calls,
  mean_exec_time,
  total_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

Then run `EXPLAIN ANALYZE` on those queries.

---

## 6. Pattern-based detection (manual but effective)

### WHERE clause

```sql
WHERE user_id = ?
WHERE created_at > ?
WHERE status = 'ACTIVE'
```

→ Index candidate

### JOIN condition

```sql
ON orders.customer_id = customers.id
```

→ Index foreign key columns

### ORDER BY / LIMIT

```sql
ORDER BY created_at DESC LIMIT 10
```

→ Composite index needed

---

## 7. Composite index mistakes (common)

❌ Wrong:

```sql
CREATE INDEX ON orders (status, created_at);
```

Query:

```sql
WHERE created_at > now() - interval '1 day';
```

✅ Correct:

```sql
CREATE INDEX ON orders (created_at, status);
```

Index **column order matters**.

---

## 8. Tools that help (optional)

- `auto_explain` (logs slow plans)
    
- `pgBadger` (log analyzer)
    
- `hypopg` (test hypothetical indexes)
    
- `pg_stat_statements` (must-have)
    

---

## 9. How NOT to create missing indexes

- ❌ Index every column
    
- ❌ Index boolean columns (unless partial)
    
- ❌ Trust “slow = missing index” blindly
    

Sometimes Seq Scan is **correct**.

---

## 10. Monitoring workflow (real-world)

1. Enable `pg_stat_statements`
    
2. Find top slow queries
    
3. Run `EXPLAIN ANALYZE`
    
4. Identify Seq Scans + filters
    
5. Design **minimal** index
    
6. Test
    
7. Monitor index usage
    

---

## Key truth (remember this)

> PostgreSQL doesn’t miss indexes — **DBAs do**.

Missing indexes are discovered through **observation, not automation**.

###### Tags : [[1 - SQL 🥞]]