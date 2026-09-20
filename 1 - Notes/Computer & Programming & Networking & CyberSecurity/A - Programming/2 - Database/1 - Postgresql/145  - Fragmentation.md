
## 1. What fragmentation is

**Fragmentation = wasted space + inefficiency caused by row changes over time.**

In PostgreSQL this mainly means **bloat**, not classic page fragmentation like some other DBs.

---

## 2. Types of fragmentation (bloat)

### 1️⃣ Table fragmentation (table bloat)

- Happens when rows are **UPDATED or DELETED**
    
- Old row versions remain (MVCC)
    
- Space is not immediately reused
    

Effect:

- Table grows
    
- Seq scans read more pages
    

---

### 2️⃣ Index fragmentation (index bloat)

- Index entries for dead rows remain
    
- Random page splits
    
- Bigger index → slower scans
    

---

### 3️⃣ Heap vs Index mismatch

- Table cleaned, index still bloated
    
- Planner thinks index is cheap → but it isn’t
    

---

## 3. Why PostgreSQL fragments

PostgreSQL uses **MVCC**:

- UPDATE = new row version
    
- DELETE = row marked dead
    
- Cleanup happens later
    

This is **by design**, not a bug.

---

## 4. How to detect fragmentation

### Table bloat indicators

```sql
SELECT
  relname,
  n_dead_tup,
  n_live_tup
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
```

High `n_dead_tup` = fragmentation.

---

### Index bloat indicators

```sql
SELECT
  indexrelname,
  idx_scan,
  pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;
```

Large index + low usage = bloated.

---

## 5. Tools (advanced)

- `pgstattuple`
    
- `pg_freespacemap`
    
- `pg_repack` (online defrag)
    

---

## 6. How to fix fragmentation

### Light cleanup (safe)

```sql
VACUUM;
VACUUM ANALYZE;
```

Reclaims space **internally**, not disk.

---

### Heavy cleanup (offline)

```sql
VACUUM FULL;
```

- Rewrites table
    
- Locks table
    
- Returns disk space
    

---

### Index-only cleanup

```sql
REINDEX INDEX idx_users_email;
REINDEX CONCURRENTLY idx_users_email;
```

---

## 7. Prevent fragmentation

- Keep **autovacuum healthy**
    
- Avoid frequent UPDATE of wide rows
    
- Use **HOT updates**
    
- Partition large, volatile tables
    

---

## 8. Hard truths

- Fragmentation is normal in PostgreSQL
    
- VACUUM ≠ disk shrink
    
- VACUUM FULL is expensive
    
- Index bloat hurts more than table bloat
    

---

### Bottom line

Fragmentation in PostgreSQL = **bloat caused by MVCC**.  
Monitor dead tuples, vacuum regularly, and reindex only when it actually hurts performance.

###### Tags : [[1 - SQL 🥞]]