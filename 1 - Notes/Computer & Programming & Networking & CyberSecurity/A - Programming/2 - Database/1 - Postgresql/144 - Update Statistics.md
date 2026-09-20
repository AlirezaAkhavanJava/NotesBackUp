

## Update Statistics in PostgreSQL 

PostgreSQL query plans depend on **table statistics**.  
If stats are stale → **bad plans** → slow queries.

---

## 1. What “update statistics” means

It means running **ANALYZE** so PostgreSQL:

- Recalculates row counts
    
- Updates value distribution
    
- Improves index vs seq-scan decisions
    

---

## 2. Core commands

### Update stats for one table

```sql
ANALYZE users;
```

### Update stats for whole database

```sql
ANALYZE;
```

### Vacuum + analyze (most common)

```sql
VACUUM ANALYZE users;
```

---

## 3. When you MUST update stats

- After **large INSERT / UPDATE / DELETE**
    
- After **bulk load**
    
- After **schema changes**
    
- When planner chooses **Seq Scan incorrectly**
    
- When index exists but isn’t used
    

---

## 4. Check last stats update

```sql
SELECT
  relname,
  last_analyze,
  last_autoanalyze
FROM pg_stat_user_tables;
```

If `NULL` or old → stats are stale.

---

## 5. Autovacuum (default behavior)

PostgreSQL **automatically updates stats**, but:

- Thresholds may be too high
    
- Busy systems can lag
    

Key settings:

```conf
autovacuum = on
autovacuum_analyze_threshold
autovacuum_analyze_scale_factor
```

---

## 6. Increase stats accuracy (advanced)

For skewed data:

```sql
ALTER TABLE users
ALTER COLUMN status SET STATISTICS 1000;
ANALYZE users;
```

Higher = better plans, more ANALYZE cost.

---

## 7. Verify effect

```sql
EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'a@b.com';
```

Before vs after ANALYZE → check plan change.

---

## 8. Hard truths

- ❌ Index won’t help with stale stats
    
- ❌ Planner is not “wrong”, it’s **uninformed**
    
- ✅ ANALYZE is cheap → run it
    

---

### Bottom line

If PostgreSQL makes bad decisions, **update statistics first**.  
Most “missing index” problems disappear after `ANALYZE`.


###### Tags : [[1 - SQL 🥞]]