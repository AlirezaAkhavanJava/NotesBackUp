


PostgreSQL never overwrites a row when you update or delete it. It leaves the old version in place and writes a new one, so readers and writers don't block each other. That design is fast and concurrent, but old row versions pile up. `VACUUM` is the housekeeper that finds the ones nobody can see anymore, marks their space as reusable, and does a few other jobs that keep the database healthy.

Most of the time you never run it by hand, because autovacuum does it for you. Understanding it still matters, because the classic Postgres production problems (bloated tables, slow queries that got slower over months, a database that suddenly refuses writes) usually trace back to vacuum not keeping up.

---

## Why it exists: the "dead tuple" story

Let's follow one row through its life.

```sql
CREATE TABLE accounts (id int PRIMARY KEY, balance int);
INSERT INTO accounts VALUES (1, 100);
UPDATE accounts SET balance = 150 WHERE id = 1;
```

After the `UPDATE`, the table physically holds **two** versions of row 1: the old one (balance 100) and the new one (balance 150). Each version is called a **tuple**. The old one is now a **dead tuple** once no running transaction could possibly still need to see it.

Why keep it at all? Imagine another transaction started before your update and is still running. Under MVCC (multi-version concurrency control) it is entitled to see balance 100. So Postgres can't just erase it.

This leads to three problems:

1. **Bloat.** Dead tuples take up space in table and index files. A table with 1 GB of live data can occupy 5 GB on disk.
2. **Slower scans.** Postgres reads pages full of garbage to find the live rows.
3. **Transaction ID exhaustion.** Every row version is stamped with transaction IDs, and those IDs are a finite resource. This is the scariest one, and we'll get to it below.

`VACUUM` addresses all of these.

## What a plain VACUUM actually does

When you run `VACUUM`, for each table it:

1. **Scans the table** looking for dead tuples (skipping pages it knows are clean, see the visibility map below).
2. **Removes the index entries** pointing to those dead tuples.
3. **Marks the dead tuples' space as free** inside the table's pages, so future `INSERT`s and `UPDATE`s can reuse it.
4. **Updates the free space map (FSM)**, the structure Postgres consults to find pages with room for new rows.
5. **Updates the visibility map (VM)**, recording which pages contain only rows visible to everyone.
6. **Freezes old tuples** (more on this soon).
7. **Truncates empty pages at the very end of the file**, if there are any, and returns that space to the operating system.

Note step 3 carefully. Plain `VACUUM` makes space **reusable inside the table**, but it generally does **not shrink the file**. If a table grew to 5 GB and you vacuum it, it will probably stay about 5 GB, but it will stop growing, because new rows fill the freed space. That is the intended behavior.

And it doesn't block normal work. Plain `VACUUM` takes only a `SHARE UPDATE EXCLUSIVE` lock, so reads and writes (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) continue while it runs. It conflicts only with things like `ALTER TABLE`, `CREATE INDEX` (non-concurrent), and another vacuum on the same table.

## Two helper structures worth knowing

**The visibility map** keeps two bits per page: "all rows on this page are visible to every transaction" and "all rows on this page are frozen." This pays off in two ways:

- Vacuum can skip pages that haven't changed since last time, which makes repeat runs cheap.
- Index-only scans can answer queries without visiting the table for those pages. A table that isn't vacuumed regularly gets worse index-only scan performance.

**The free space map** tells Postgres where there's room for new tuples, so it doesn't extend the file when space already exists.

## The wraparound problem

Every transaction that modifies data gets a 32-bit transaction ID (XID). A row version records which XID created it. Since 32 bits only allows about 4 billion values, Postgres compares XIDs in a circular way: for any given XID, roughly 2 billion IDs count as "the past" and 2 billion as "the future."

The danger: if a row is left untouched long enough, the counter eventually advances so far that the row's creator XID seems to be in the _future_, and the row would suddenly become invisible. That would be catastrophic data loss.

The fix is **freezing**. When vacuum finds a sufficiently old tuple, it marks it frozen, which means "this row is older than any transaction, always visible," independent of the XID counter. Frozen rows are immune to wraparound.

So vacuum has a second job beyond cleaning up space: it makes sure no unfrozen tuple gets too old. If it fails for long enough, Postgres protects itself:

- At a certain age, it launches **aggressive autovacuums** that cannot be cancelled and that scan everything not yet frozen.
- Very close to the limit (`vacuum_failsafe_age`, 1.6 billion by default in PG 14+), vacuum goes into failsafe mode and skips non-essential work to finish quickly.
- At the limit, Postgres **stops accepting writes** until a vacuum completes. That is the outage nobody wants.

You can see how close each database is:

```sql
SELECT datname, age(datfrozenxid) AS xid_age
FROM pg_database
ORDER BY xid_age DESC;
```

The default `autovacuum_freeze_max_age` is 200 million, so values far above that deserve attention.

## The different flavors of the command

```sql
VACUUM;                      -- every table in the current database you can vacuum
VACUUM accounts;             -- one table
VACUUM (VERBOSE) accounts;   -- print what it did
VACUUM (ANALYZE) accounts;   -- vacuum, then refresh planner statistics
VACUUM (FREEZE) accounts;    -- freeze all eligible tuples aggressively
VACUUM (FULL) accounts;      -- rewrite the table entirely (heavy!)
```

Options can be combined: `VACUUM (VERBOSE, ANALYZE) accounts;`. Two things to know: `VACUUM` cannot run inside a transaction block, and `VACUUM` without a table name processes every table in the database.

Other useful options:

|Option|What it does|
|---|---|
|`PARALLEL n`|Vacuum a table's indexes with up to `n` workers|
|`INDEX_CLEANUP off`|Skip index vacuuming (an emergency option when racing wraparound)|
|`TRUNCATE off`|Don't try to shrink the end of the file (avoids a brief heavier lock)|
|`SKIP_LOCKED`|Skip tables that can't be locked right away instead of waiting|
|`DISABLE_PAGE_SKIPPING`|Ignore the visibility map and scan every page|
|`PROCESS_TOAST`|Also vacuum the table's TOAST table (on by default)|

### VACUUM ANALYZE is two different jobs

`ANALYZE` has nothing to do with dead tuples. It samples the table and updates the statistics the query planner uses to choose plans (row counts, value distributions). `VACUUM ANALYZE` just does both in one go. Good statistics matter as much as clean pages: a stale-statistics table can suddenly get a terrible query plan.

## VACUUM FULL: the heavy hammer

`VACUUM FULL` works differently. It **rewrites the whole table into a new file** containing only live rows, rebuilds the indexes, and swaps the files, much like `TRUNCATE` swaps storage. The result is a compact table and disk space actually returned to the OS.

The cost is steep:

- It takes an **`ACCESS EXCLUSIVE` lock**, which blocks all reads and writes for the entire duration.
- It needs **extra disk space** (roughly the size of the live data) while it builds the new copy.
- It can take a long time on large tables and generates a lot of I/O and WAL.

So `VACUUM FULL` is for rare situations, such as after deleting most of a huge table's data with no plan to refill it. For routine bloat control, prefer a regular vacuum that keeps up. If you must compact a table online, the community extension **pg_repack** rebuilds tables with only brief locks.

## Autovacuum: the thing that usually does the work

Postgres ships with a background system that runs vacuum and analyze automatically. A launcher checks every `autovacuum_naptime` (default 1 minute) and starts workers (`autovacuum_max_workers`, default 3) for tables that have changed enough.

A table is vacuumed when the number of dead tuples exceeds:

```
autovacuum_vacuum_threshold + autovacuum_vacuum_scale_factor × number_of_rows
```

With the defaults (50 and 0.2), a table gets vacuumed after about **20% of its rows** are dead, plus 50. Since PG 13 there's an equivalent trigger for insert-heavy tables (`autovacuum_vacuum_insert_threshold` 1000, `autovacuum_vacuum_insert_scale_factor` 0.2), so append-only tables still get frozen and their visibility map kept up to date. Analyze has its own thresholds (50 plus 10% of the rows).

### Why the defaults fail on big tables

20% of a 1,000-row table is 200 rows, which is nothing. But 20% of a 500-million-row table is **100 million dead tuples** before autovacuum even wakes up. By then you have massive bloat. The standard fix is to override settings **per table**:

```sql
ALTER TABLE events SET (
    autovacuum_vacuum_scale_factor = 0.01,
    autovacuum_vacuum_threshold = 10000,
    autovacuum_analyze_scale_factor = 0.02
);
```

### Throttling and why vacuum can be slow

Vacuum is deliberately rate-limited so it doesn't swamp your disks. It does a bit of work, then sleeps. The key knobs are `autovacuum_vacuum_cost_delay` (default 2 ms) and `autovacuum_vacuum_cost_limit` (default effectively 200, shared among all running workers). If vacuum can't keep up with a write-heavy workload, raising the cost limit or lowering the delay is the usual tuning step. Memory matters too: `autovacuum_work_mem` (or `maintenance_work_mem`) sets how many dead-tuple pointers vacuum can hold before it must make an extra pass over the indexes, so too little makes vacuum slower on big tables.

Also remember that **autovacuum running is not the same as autovacuum finishing**. A worker can spend hours on a huge table, and if you cancel or conflict with it, the work is lost.

## What blocks vacuum from cleaning up

This is the most common reason bloat grows even when autovacuum is running. Vacuum can only remove a dead tuple if **no transaction anywhere could still need it**. Anything that holds back the "oldest transaction still running" horizon (the `xmin` horizon) stops cleanup across the whole cluster:

- **Long-running transactions**, including sessions stuck "idle in transaction."
- **Abandoned replication slots**, which hold back cleanup for a consumer that isn't consuming.
- **Orphaned prepared transactions** (from two-phase commit).
- **Replicas with `hot_standby_feedback = on`** running long queries.

You'll see vacuum run, report dead tuples that "cannot be removed yet," and bloat keep growing. Find the culprits:

```sql
-- Oldest open transactions
SELECT pid, state, xact_start, now() - xact_start AS age, left(query, 60)
FROM pg_stat_activity
WHERE xact_start IS NOT NULL
ORDER BY xact_start
LIMIT 10;

-- Replication slots holding things back
SELECT slot_name, active, xmin, catalog_xmin FROM pg_replication_slots;

-- Forgotten prepared transactions
SELECT * FROM pg_prepared_xacts;
```

Setting `idle_in_transaction_session_timeout` is a good safety net against forgotten sessions.

## Watching vacuum

**Per-table health:**

```sql
SELECT relname,
       n_live_tup,
       n_dead_tup,
       round(100.0 * n_dead_tup / nullif(n_live_tup + n_dead_tup, 0), 1) AS dead_pct,
       last_vacuum,
       last_autovacuum,
       last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 20;
```

**Live progress of a running vacuum:**

```sql
SELECT * FROM pg_stat_progress_vacuum;
```

**Logging slow autovacuums**, which is very useful for understanding what's happening:

```
log_autovacuum_min_duration = 0     # log every autovacuum run (or e.g. 1000 for >1s)
```

**Accurate bloat measurement** can be done with the `pgstattuple` extension (`pgstattuple('tablename')`), though it reads the whole table, so be mindful on huge ones.

## A related trick: HOT updates and pruning

You may hear of **HOT (heap-only tuple) updates**. If an update doesn't change any indexed column and the new row version fits on the same page, Postgres can skip creating new index entries. Related to this, even regular queries can do **page pruning**, cleaning dead tuples within a single page opportunistically. Setting a lower `fillfactor` on frequently updated tables (e.g. 80-90) leaves room on each page for such updates, reducing both bloat and vacuum work. It's a way to make vacuum's job easier rather than a replacement for it.

## Common mistakes

- **Turning autovacuum off** to "improve performance." This makes wraparound and bloat inevitable. Tune it instead.
- **Running `VACUUM FULL` routinely.** It locks the table completely; regular vacuum keeping pace is the right answer.
- **Leaving defaults on huge tables** (the 20% scale factor problem).
- **Ignoring long-running transactions and stale replication slots**, which quietly sabotage vacuum everywhere.
- **Expecting `VACUUM` to shrink files.** It makes space reusable, and it only returns space to the OS if the empty pages are at the end of the file.
- **Forgetting statistics.** After big data loads, run `ANALYZE` so the planner isn't working from outdated numbers.
- **Not monitoring XID age**, so wraparound warnings come as a surprise.

## Quick cheat sheet

```sql
VACUUM (VERBOSE, ANALYZE) mytable;         -- everyday manual run with details
VACUUM (FREEZE) mytable;                   -- force freezing
VACUUM (FULL) mytable;                     -- rewrite table (exclusive lock!)
VACUUM (INDEX_CLEANUP off) mytable;        -- emergency wraparound avoidance

ALTER TABLE mytable SET (autovacuum_vacuum_scale_factor = 0.01);   -- per-table tuning
ALTER TABLE mytable SET (fillfactor = 85);                          -- room for HOT updates

SELECT * FROM pg_stat_progress_vacuum;                              -- what's running now
SELECT datname, age(datfrozenxid) FROM pg_database;                 -- wraparound distance
```



[[PostgreSQL]]