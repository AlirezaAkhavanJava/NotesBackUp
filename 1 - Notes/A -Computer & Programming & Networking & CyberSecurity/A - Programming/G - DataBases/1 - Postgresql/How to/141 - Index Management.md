
## 1. Create indexes

```sql
CREATE INDEX idx_user_email ON users(email);
CREATE UNIQUE INDEX idx_unique_email ON users(email);
CREATE INDEX idx_active_users ON users(email) WHERE active = true; -- partial
CREATE INDEX idx_name_gin ON users USING gin(to_tsvector('english', name));
```

---

## 2. List indexes

```sql
-- All indexes on a table
\d users

-- Detailed
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'users';
```

---

## 3. Check index usage (VERY important)

```sql
SELECT
  relname AS table,
  indexrelname AS index,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

👉 `idx_scan = 0` = **unused index → candidate for removal**

---

## 4. Drop unused or bad indexes

```sql
DROP INDEX idx_user_email;
DROP INDEX CONCURRENTLY idx_user_email; -- production-safe
```

⚠️ `CONCURRENTLY` avoids table locks (slower but safe).

---

## 5. Rebuild indexes (bloat / corruption)

```sql
REINDEX INDEX idx_user_email;
REINDEX TABLE users;
REINDEX DATABASE mydb;
```

Production-safe:

```sql
REINDEX INDEX CONCURRENTLY idx_user_email;
```

---

## 6. Analyze planner decisions

```sql
EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'a@b.com';
```

Look for:

- `Index Scan` ✅
    
- `Seq Scan` ❌ (maybe missing or useless index)
    

---

## 7. Index size & bloat

```sql
SELECT
  relname,
  pg_size_pretty(pg_relation_size(relid)) AS size
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(relid) DESC;
```

Large + low usage = bad index.

---

## 8. Index maintenance rules (hard truth)

- ❌ More indexes ≠ faster
    
- ✅ Each index slows **INSERT / UPDATE / DELETE**
    
- ❌ Index columns with low selectivity (e.g. `boolean`) unless partial
    
- ✅ Index columns used in `WHERE`, `JOIN`, `ORDER BY`
    

---

## 9. Production best practices

- Use **partial indexes** for hot subsets
    
- Use **CONCURRENTLY** in production
    
- Review indexes after schema changes
    
- Monitor `pg_stat_user_indexes`
    
- Keep index count minimal and intentional
    

---

## 10. Quick checklist

- Is the index used? → `pg_stat_user_indexes`
    
- Does the query match the index condition?
    
- Is index size worth the benefit?
    
- Can a partial index replace a full one?
    

---

### Bottom line

Index management is **continuous pruning**, not hoarding.  
Unused or wrong indexes **hurt performance more than missing ones**.


##### Tags : [[1 - SQL 🥞]]