

`TRUNCATE` empties one or more tables in one fast operation. Instead of visiting every row and marking it dead the way `DELETE` does, PostgreSQL swaps the table's underlying storage file for a fresh empty one. That makes it very fast on big tables, and it frees disk space immediately. The price is a heavy lock, some surprising interactions with foreign keys and triggers, and a few concurrency caveats. This tutorial covers all of that.

---

## 1. The problem it solves

Say you have a table `events` with 200 million rows and you want it empty:

```sql
DELETE FROM events;
```

This is slow and messy for several reasons:

- It touches every row and writes a WAL record for each one.
- It doesn't free any space. The rows become dead tuples until `VACUUM` cleans them up, so the table file stays huge.
- It leaves lots of bloat and extra work for autovacuum.
- Row-level triggers fire for every row.

`TRUNCATE` solves this:

```sql
TRUNCATE TABLE events;
```

It finishes in milliseconds whether the table has 10 rows or 10 billion, and the disk space comes back right away.

## 2. Basic syntax

```sql
TRUNCATE [ TABLE ] [ ONLY ] name [ * ] [, ... ]
    [ RESTART IDENTITY | CONTINUE IDENTITY ]
    [ CASCADE | RESTRICT ];
```

The pieces you'll use most:

```sql
-- One table
TRUNCATE TABLE orders;

-- Several tables in one statement
TRUNCATE TABLE orders, order_items, payments;

-- Reset auto-increment counters too
TRUNCATE TABLE orders RESTART IDENTITY;

-- Also truncate every table that references this one via a foreign key
TRUNCATE TABLE customers CASCADE;
```

The word `TABLE` is optional. `ONLY` matters with inheritance, and I'll cover it below.

## 3. How it works under the hood

A regular table in PostgreSQL is stored in files on disk. `TRUNCATE` creates a brand new empty file (a new "relfilenode") for the table and its indexes, then drops the old ones when the transaction commits. It never scans or modifies individual rows.

That explains most of its behavior:

- **It's constant-time**, because no rows are visited.
- **Space is reclaimed immediately**, because the old file is simply deleted.
- **No vacuum is needed afterward**, because there are no dead tuples.
- **Row-level `DELETE` triggers don't fire**, because no rows are deleted one by one.
- **It needs a very strong lock.**

## 4. Comparing `TRUNCATE`, `DELETE`, and `DROP`

||`DELETE` (no WHERE)|`TRUNCATE`|`DROP TABLE`|
|---|---|---|---|
|Removes rows|Yes|Yes|Yes|
|Removes the table itself|No|No|Yes|
|Speed on large tables|Slow|Very fast|Very fast|
|Can use a `WHERE` clause|Yes|No|No|
|Frees disk space immediately|No (needs `VACUUM`)|Yes|Yes|
|Fires row-level triggers|Yes|No|No|
|Lock taken|`ROW EXCLUSIVE`|`ACCESS EXCLUSIVE`|`ACCESS EXCLUSIVE`|
|Transaction-safe|Yes|Yes|Yes|

Use `TRUNCATE` when you want everything gone and the table structure kept. If you need to remove only some rows, you need `DELETE`.

## 5. It's transactional in PostgreSQL

In some databases (Oracle and MySQL, for example) `TRUNCATE` commits implicitly and can't be undone. PostgreSQL is different, and you can roll it back:

```sql
BEGIN;
TRUNCATE TABLE orders;
SELECT count(*) FROM orders;   -- 0
ROLLBACK;
SELECT count(*) FROM orders;   -- your rows are back
```

That makes `TRUNCATE` a safe building block in migration scripts and data reloads. If something later in the transaction fails, the whole thing, including the truncate, is undone.

## 6. Foreign keys: the most common stumbling block

Suppose `order_items.order_id` references `orders.id`. This fails:

```sql
TRUNCATE TABLE orders;
-- ERROR: cannot truncate a table referenced in a foreign key constraint
-- DETAIL: Table "order_items" references "orders".
-- HINT: Truncate table "order_items" at the same time, or use TRUNCATE ... CASCADE.
```

This error appears even when `order_items` is already empty. PostgreSQL doesn't scan the referencing table to check, because that would defeat the point of being fast. You have two options.

**Option A: truncate them together.**

```sql
TRUNCATE TABLE orders, order_items;
```

**Option B: use `CASCADE`.**

```sql
TRUNCATE TABLE orders CASCADE;
```

`CASCADE` automatically truncates every table that references `orders`, and every table that references those, and so on. Be careful here. It can wipe out far more than you expect, especially in a schema with many relationships. PostgreSQL prints a `NOTICE` listing the tables it cascaded to, so read it. When in doubt, list the tables explicitly (Option A) so nothing is a surprise.

The opposite is `RESTRICT`, which is the default. It refuses to proceed if any other table references the target.

## 7. Resetting sequences: `RESTART IDENTITY`

By default, `TRUNCATE` does not touch sequences, so your IDs keep counting from where they left off:

```sql
TRUNCATE TABLE orders;
INSERT INTO orders (note) VALUES ('first after truncate');
-- id might be 100001, not 1
```

If you want IDs to start over, say so:

```sql
TRUNCATE TABLE orders RESTART IDENTITY;
```

This resets sequences that are owned by columns of the truncated tables, which covers `SERIAL` and `GENERATED ... AS IDENTITY` columns. Sequences that were created separately and aren't owned by a column are left alone. The reset is also transactional, so a rollback restores the old sequence values.

`CONTINUE IDENTITY` is the default and just spells out the "don't touch sequences" behavior.

## 8. Locking: the part that bites in production

`TRUNCATE` takes an `ACCESS EXCLUSIVE` lock on the table. That is the strongest lock PostgreSQL has: it blocks everything, including plain `SELECT`s.

Two practical consequences:

1. **It waits for existing transactions.** If a long-running query or an idle-in-transaction session has touched the table, `TRUNCATE` queues behind it.
2. **While it waits, it blocks everyone behind it.** Lock requests queue up in order, so every new query on that table now waits behind your pending `TRUNCATE`. One innocent truncate can stall an entire application.

A safe pattern for production:

```sql
BEGIN;
SET LOCAL lock_timeout = '3s';
TRUNCATE TABLE events;
COMMIT;
```

If the lock can't be acquired within 3 seconds, the statement fails quickly instead of piling up a traffic jam, and you can retry later.

## 9. Concurrency caveat: not MVCC-safe

Normally, PostgreSQL's MVCC lets a transaction keep seeing the data as it was when its snapshot began, even if others change it. `TRUNCATE` is the exception. If a transaction with an older snapshot (for example a `REPEATABLE READ` transaction) is running and then someone commits a `TRUNCATE`, the older transaction will see the table as empty after the commit. In practice the lock makes this rare, since `TRUNCATE` has to wait for transactions using the table, but it matters when snapshots were taken before the table was first accessed. If you rely on strict snapshot consistency, remember this.

## 10. Triggers

- `ON DELETE` row-level triggers do **not** fire on `TRUNCATE`.
- `BEFORE TRUNCATE` and `AFTER TRUNCATE` triggers do exist, but they must be statement-level:

```sql
CREATE TRIGGER log_truncate
AFTER TRUNCATE ON orders
FOR EACH STATEMENT
EXECUTE FUNCTION audit_truncate();
```

If you have auditing built on delete triggers, truncating will silently bypass it, so add a truncate trigger or restrict who can truncate.

## 11. Permissions

You need the `TRUNCATE` privilege on the table, or you must own it. It's a separate privilege from `DELETE`, so you can grant one without the other:

```sql
GRANT TRUNCATE ON orders TO app_cleanup_role;
REVOKE TRUNCATE ON orders FROM app_user;
```

It's a good habit to keep this privilege away from your regular application user in production.

## 12. Related concepts

**Partitioned tables.** Truncating a partitioned parent truncates all its partitions. You can also truncate a single partition directly, which is a very cheap way to purge old data (for example, last year's monthly partition).

**Inheritance and `ONLY`.** For old-style table inheritance, `TRUNCATE parent` also truncates its children. Use `TRUNCATE ONLY parent` to leave the children alone.

**Replication.** With logical replication, `TRUNCATE` is replicated to subscribers by default (publications include `truncate` among their published operations unless you exclude it). Keep that in mind before running it on a publisher.

**Temporary tables.** Truncating a temp table is a common way to reuse it between steps in a script or function.

**Statistics.** After a truncate, the table's planner statistics are stale until `ANALYZE` or autovacuum updates them. It's a good idea to run `ANALYZE` after you reload data into a truncated table.

## 13. Using it in Spring Boot tests

Since you work with Spring Boot, the most common place you'll meet `TRUNCATE` is resetting the database between integration tests (for example with Testcontainers). `@Transactional` tests roll back automatically, but tests that commit data (or that run in another thread) need explicit cleanup.

```java
@Component
public class DatabaseCleaner {

    private final JdbcTemplate jdbc;

    public DatabaseCleaner(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public void clean() {
        List<String> tables = jdbc.queryForList("""
            SELECT tablename FROM pg_tables
            WHERE schemaname = 'public'
              AND tablename <> 'flyway_schema_history'
            """, String.class);

        if (!tables.isEmpty()) {
            jdbc.execute("TRUNCATE TABLE "
                + String.join(", ", tables)
                + " RESTART IDENTITY CASCADE");
        }
    }
}
```

```java
@SpringBootTest
class OrderServiceIT {

    @Autowired DatabaseCleaner cleaner;

    @AfterEach
    void tearDown() {
        cleaner.clean();
    }
}
```

Notes on this approach:

- Listing every table in a single `TRUNCATE` statement avoids foreign-key ordering problems.
- Exclude your migration history table (`flyway_schema_history`, or `databasechangelog` for Liquibase), or your migrations will think they've never run.
- `RESTART IDENTITY` keeps IDs predictable across tests.
- You can also do the same with a SQL script via `@Sql(scripts = "/clean.sql", executionPhase = AFTER_TEST_METHOD)`.

## 14. Common pitfalls

- **Running it on the wrong database.** There's no `WHERE` clause and no confirmation prompt. Check your connection before running it, and wrap manual runs in `BEGIN; ...` so you can inspect the result and `ROLLBACK` if needed.
- **Using `CASCADE` carelessly.** It can reach tables you didn't think of.
- **Forgetting the lock.** On a busy table, use `lock_timeout`.
- **Expecting delete triggers or per-row auditing to run.**
- **Expecting sequences to reset** without `RESTART IDENTITY`.
- **Using it when you need a `WHERE` clause.** For partial deletes, use `DELETE` (or partition drops for time-based data).

## Quick cheat sheet

```sql
TRUNCATE TABLE t;                          -- empty one table
TRUNCATE TABLE a, b, c;                    -- empty several at once
TRUNCATE TABLE t RESTART IDENTITY;         -- also reset sequences
TRUNCATE TABLE t CASCADE;                  -- also empty referencing tables
TRUNCATE TABLE ONLY parent;                -- skip inherited children

BEGIN;                                     -- the safe production pattern
SET LOCAL lock_timeout = '3s';
TRUNCATE TABLE t;
COMMIT;
```




[[PostgreSQL]]
[[Spring Framework]]