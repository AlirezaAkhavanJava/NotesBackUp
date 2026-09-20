
## Fragmentation Handling Methods in PostgreSQL

Fragmentation in PostgreSQL (table bloat and index bloat) occurs naturally because of **MVCC**. Here’s how to handle it effectively:

---

## 1️⃣ VACUUM (lightweight cleanup)

- Frees space from **dead tuples** for reuse.
    
- Does **not shrink disk size**.
    
- Can be **manual or automatic** (autovacuum).
    

### Commands:

```sql
VACUUM users;           -- just cleanup
VACUUM ANALYZE users;   -- cleanup + update stats
```

**Pros:**

- Non-blocking (usually)
    
- Fast
    

**Cons:**

- Doesn’t reduce physical file size
    

---

## 2️⃣ VACUUM FULL (heavy cleanup)

- Physically rewrites table to remove all bloat.
    
- Returns space to OS.
    
- Locks the table → **blocking**.
    

### Command:

```sql
VACUUM FULL users;
```

**Pros:**

- Eliminates bloat completely
    
- Shrinks disk usage
    

**Cons:**

- Exclusive lock
    
- Slower
    

**Workaround:** Use **pg_repack** for online alternative.

---

## 3️⃣ REINDEX (index defragmentation)

- Rebuilds indexes from scratch.
    
- Reduces **index bloat**.
    
- Can be blocking or concurrent.
    

### Commands:

```sql
REINDEX INDEX idx_users_email;            -- simple
REINDEX TABLE users;                      -- all table indexes
REINDEX INDEX CONCURRENTLY idx_users_email; -- non-blocking
```

**Pros:**

- Reduces index size
    
- Improves query performance
    

**Cons:**

- Locks table (except concurrent)
    
- Disk space needed temporarily
    

---

## 4️⃣ pg_repack (online defrag)

- Rewrites table and indexes **without blocking reads/writes**.
    
- Handles **both table and index fragmentation**.
    
- Requires installation: `CREATE EXTENSION pg_repack;`
    

### Example:

```bash
pg_repack -t users mydb
```

**Pros:**

- Online
    
- Handles large tables
    
- Reduces both table & index bloat
    

**Cons:**

- Extra tool needed
    
- Uses temporary disk space
    

---

## 5️⃣ Preventive Methods

1. **Autovacuum tuning**
    
    ```conf
    autovacuum = on
    autovacuum_vacuum_scale_factor = 0.05
    autovacuum_analyze_scale_factor = 0.05
    ```
    
    → Keeps bloat under control automatically.
    
2. **HOT updates** (update non-indexed columns only)
    
3. **Partitioning** large, frequently updated tables
    
4. **Partial indexes** for selective queries (reduces index bloat)
    
5. Avoid frequent UPDATEs of wide rows when possible
    

---

## 6️⃣ Monitoring + Maintenance Workflow

1. Monitor dead tuples, index size, and table growth.
    
2. Run regular `VACUUM`/`ANALYZE` (autovacuum helps).
    
3. Use `REINDEX` or `pg_repack` for badly bloated indexes/tables.
    
4. Adjust autovacuum thresholds for high-update tables.
    
5. Track improvements with `pg_stat_user_tables` and `pg_stat_user_indexes`.
    

---

**Bottom line:**

- **VACUUM** → routine cleanup
    
- **VACUUM FULL / REINDEX / pg_repack** → fix severe fragmentation
    
- **Autovacuum + preventive design** → minimize future fragmentation
    

---


###### Tags : [[1 - SQL 🥞]]