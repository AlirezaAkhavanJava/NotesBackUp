

## How to Monitor Fragmentation in PostgreSQL

Fragmentation in PostgreSQL is mostly **table bloat** and **index bloat**. You monitor it by tracking **dead tuples, table size, and index size**. Here’s the practical approach:

---

## 1️⃣ Monitor Table Fragmentation (Dead Tuples / Bloat)

### Check dead/live tuples:

```sql
SELECT
  schemaname,
  relname AS table_name,
  n_live_tup AS live_rows,
  n_dead_tup AS dead_rows,
  ROUND(100.0 * n_dead_tup / (n_live_tup + n_dead_tup), 2) AS dead_pct
FROM pg_stat_user_tables
ORDER BY dead_pct DESC;
```

- `n_dead_tup` high → table is fragmented.
    
- `dead_pct` > 10–20% usually needs VACUUM.
    

---

### Check table size vs estimated optimal size

```sql
SELECT
  relname,
  pg_size_pretty(pg_relation_size(relid)) AS table_size,
  pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size DESC;
```

- Compare size trends over time.
    
- Growing table without proportional row increase → fragmentation.
    

---

## 2️⃣ Monitor Index Fragmentation (Index Bloat)

### Check index size and usage:

```sql
SELECT
  indexrelname AS index_name,
  idx_scan AS times_used,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;
```

Red flags:

- Huge size
    
- Low `idx_scan` → index is bloated or redundant.
    

---

### Check index bloat percentage (advanced)

Using `pgstattuple` extension:

```sql
CREATE EXTENSION IF NOT EXISTS pgstattuple;

SELECT *
FROM pgstattuple('users');
```

- `approx_free_percent` → percentage of wasted space.
    
- `dead_tuple_count` → number of dead rows in the table.
    

For indexes:

```sql
SELECT *
FROM pgstattuple('idx_users_email');
```

---

## 3️⃣ Monitor via Autovacuum Stats

Autovacuum activity indicates whether tables are being maintained properly:

```sql
SELECT
  relname AS table_name,
  last_autovacuum,
  last_analyze,
  vacuum_count,
  autovacuum_count
FROM pg_stat_user_tables
ORDER BY last_autovacuum;
```

- Long gaps or zero autovacuum → potential bloat risk.
    

---

## 4️⃣ Optional: Tools for Monitoring

- **pg_stat_statements** → identify heavy queries that may produce dead tuples.
    
- **pg_repack** → online bloat monitoring and defrag.
    
- **pgBadger** → visualize table growth and vacuum activity.
    

---

## 5️⃣ Practical Workflow

1. Monitor dead tuples and table size weekly.
    
2. Check indexes for low usage and high size.
    
3. Run `VACUUM` / `ANALYZE` regularly.
    
4. Use `REINDEX` or `pg_repack` for badly bloated indexes.
    
5. Adjust autovacuum thresholds for high-update tables.
    

---

**Bottom line:**  
Monitoring fragmentation = **track dead tuples, table/index size, autovacuum activity, and usage stats**.  
If dead tuples or wasted index space grow, it’s time to vacuum, reindex, or repack.

---




###### Tags : [[1 - SQL 🥞]]