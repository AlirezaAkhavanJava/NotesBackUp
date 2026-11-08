

`RETURNING` is a clause you add to `INSERT`, `UPDATE`, `DELETE` (and `MERGE` in PostgreSQL 17+) that makes the statement hand back the rows it just touched, as if it were a `SELECT`. You get the generated IDs, the final values after defaults and triggers were applied, or the rows that were just deleted, all in the same round trip and the same atomic step as the change itself.

It looks like a small convenience, but it removes a whole class of race conditions and extra queries, and it is the glue that makes some of Postgres's best patterns work, like job queues and multi-table inserts in one statement. Let's build up to those.

---

## Start with the annoying thing it fixes

You insert a row, and now you need its auto-generated `id`. The clumsy way:

```sql
INSERT INTO users (email) VALUES ('ana@example.com');
SELECT max(id) FROM users;   -- WRONG: another session may have inserted in between
```

Even the "safer" `currval('users_id_seq')` only works for sequences, only for one column, and needs a second statement. With `RETURNING` you ask for it directly:

```sql
INSERT INTO users (email) VALUES ('ana@example.com')
RETURNING id;
```

The result comes back as a normal result set with one row and one column. No second query, no race.

## What you can put after RETURNING

Anything you could put in a `SELECT` list works:

```sql
INSERT INTO users (email, name)
VALUES ('ana@example.com', 'Ana')
RETURNING *;                                   -- every column

INSERT INTO users (email, name)
VALUES ('bob@example.com', 'Bob')
RETURNING id, upper(name) AS shouting_name, now() AS created_at;
```

`RETURNING *` is great for seeing exactly what landed in the table, including columns you never mentioned, like defaults, generated columns, and timestamps. Expressions, function calls, and aliases all work.

It also works for multi-row inserts, where you get one row back per inserted row:

```sql
INSERT INTO tags (name)
VALUES ('postgres'), ('sql'), ('performance')
RETURNING id, name;
```

The rows come back in the order they were inserted, which matches the `VALUES` order for a plain insert.

## UPDATE ... RETURNING: seeing the new values

For `UPDATE`, `RETURNING` shows the row **as it is after the update**:

```sql
UPDATE accounts
SET balance = balance - 50
WHERE id = 1
RETURNING id, balance;
```

This is the classic way to do "decrement and read the result" atomically. Without `RETURNING` you'd need a separate `SELECT`, and someone could change the balance between your two statements.

If the `WHERE` matches nothing, you simply get zero rows back. That's useful on its own: "no rows returned" tells you the update didn't match anything, which is how you detect things like a failed optimistic-lock check:

```sql
UPDATE documents
SET body = 'new text', version = version + 1
WHERE id = 5 AND version = 3        -- version I originally read
RETURNING version;                  -- empty result = someone else changed it first
```

### Joining other tables inside RETURNING

With `UPDATE ... FROM`, the `RETURNING` list can use columns from the joined tables too:

```sql
UPDATE orders o
SET status = 'shipped'
FROM customers c
WHERE o.customer_id = c.id AND o.id = 99
RETURNING o.id, o.status, c.email;
```

### Getting the OLD values

Plain `RETURNING` only gives new values. What if you want to know what the row looked like before?

**PostgreSQL 18 and later** added `OLD` and `NEW` aliases:

```sql
UPDATE accounts
SET balance = balance - 50
WHERE id = 1
RETURNING old.balance AS before, new.balance AS after;
```

`OLD` is empty for an `INSERT` and `NEW` is empty for a `DELETE`, so those columns come back as `NULL` in those cases.

**On older versions**, you can join against a locked copy of the row:

```sql
UPDATE accounts a
SET balance = a.balance - 50
FROM (SELECT id, balance FROM accounts WHERE id = 1 FOR UPDATE) AS old
WHERE a.id = old.id
RETURNING old.balance AS before, a.balance AS after;
```

The `FOR UPDATE` lock keeps another session from changing the row between the subquery and the update, so the "before" value is trustworthy.

## DELETE ... RETURNING: the row's last words

`DELETE ... RETURNING` gives back the rows that were just removed:

```sql
DELETE FROM sessions
WHERE expires_at < now()
RETURNING user_id, expires_at;
```

Why is that valuable? Because you get a guaranteed-accurate list of what was deleted, atomically. No window where a row is deleted but you didn't see it, or seen but not deleted.

### Example: a job queue in one statement

This is a famous Postgres pattern. Many workers each want to grab one pending job, and no two workers may get the same one:

```sql
DELETE FROM jobs
WHERE id = (
    SELECT id FROM jobs
    ORDER BY created_at
    FOR UPDATE SKIP LOCKED
    LIMIT 1
)
RETURNING id, payload;
```

`FOR UPDATE SKIP LOCKED` makes each worker skip rows already claimed by someone else, and `RETURNING` hands the claimed job to the worker. Claiming and fetching happen in one atomic step. (If you'd rather keep finished jobs, use an `UPDATE ... SET status = 'running' ... RETURNING *` version of the same idea.)

## INSERT ... ON CONFLICT: what comes back?

This is where people get surprised, so look at the rules:

```sql
INSERT INTO users (email, name)
VALUES ('ana@example.com', 'Ana')
ON CONFLICT (email) DO NOTHING
RETURNING id;
```

With `DO NOTHING`, a conflicting row is **skipped, and skipped rows are not returned**. If the email already existed, you get an empty result, not the existing row's `id`.

With `DO UPDATE`, both inserted **and** updated rows are returned:

```sql
INSERT INTO users (email, name)
VALUES ('ana@example.com', 'Ana B.')
ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name
RETURNING id, name;
```

So "insert it or give me the existing id" is usually written with a deliberate no-op update, so the row always comes back:

```sql
INSERT INTO users (email)
VALUES ('ana@example.com')
ON CONFLICT (email) DO UPDATE SET email = EXCLUDED.email
RETURNING id;
```

The cost is that this writes a new row version every time, even though nothing changed, which adds bloat on hot tables.

### Was it an insert or an update?

A widely used trick is checking `xmax`:

```sql
RETURNING id, (xmax = 0) AS was_inserted
```

For a freshly inserted row `xmax` is 0, and for a row that went down the update path it isn't. Be aware that this relies on internal system-column behavior rather than a documented guarantee, so treat it as a pragmatic trick, not a contract.

## MERGE ... RETURNING (PostgreSQL 17+)

`MERGE` gained `RETURNING` in version 17, along with a helper function, `merge_action()`, that tells you what happened to each row:

```sql
MERGE INTO inventory AS t
USING incoming AS s ON t.sku = s.sku
WHEN MATCHED THEN UPDATE SET qty = t.qty + s.qty
WHEN NOT MATCHED THEN INSERT (sku, qty) VALUES (s.sku, s.qty)
RETURNING merge_action() AS action, t.sku, t.qty;
```

`action` will be `'INSERT'`, `'UPDATE'`, or `'DELETE'` for each affected row. That solves the "insert or update?" question cleanly, without the `xmax` trick.

## The real superpower: chaining with CTEs

Because `RETURNING` produces a result set, you can use it as the input to another statement through a data-modifying CTE. Here's creating an order and its line items in one statement:

```sql
WITH new_order AS (
    INSERT INTO orders (customer_id)
    VALUES (42)
    RETURNING id
)
INSERT INTO order_items (order_id, product_id, qty)
SELECT new_order.id, v.product_id, v.qty
FROM new_order,
     (VALUES (10, 2), (11, 1)) AS v(product_id, qty);
```

The generated order `id` flows straight into the child rows, with no round trip, and the whole thing is atomic.

You can also capture the output of one statement and use it in several others, for example to log changes:

```sql
WITH changed AS (
    UPDATE products
    SET price = price * 1.10
    WHERE category = 'books'
    RETURNING id, price
)
INSERT INTO price_history (product_id, new_price, changed_at)
SELECT id, price, now() FROM changed;
```

And since a CTE's `RETURNING` is just rows, you can count them:

```sql
WITH d AS (
    DELETE FROM sessions WHERE expires_at < now() RETURNING 1
)
SELECT count(*) AS deleted FROM d;
```

## Using it inside PL/pgSQL

In functions and procedures, `INTO` captures the returned row into variables:

```sql
CREATE FUNCTION create_user(p_email text) RETURNS int
LANGUAGE plpgsql AS $$
DECLARE
    v_id int;
BEGIN
    INSERT INTO users (email) VALUES (p_email)
    RETURNING id INTO v_id;
    RETURN v_id;
END;
$$;
```

Note that `INTO` expects a single row. If the statement could return several, you'd loop instead with `FOR rec IN INSERT ... RETURNING ... LOOP`, or use `RETURN QUERY` in a set-returning function. With `INTO STRICT`, Postgres raises an error unless exactly one row came back, which is a nice safety net.

## How it interacts with triggers, views, and partitions

- **BEFORE triggers**: if a trigger modifies the row before it's stored, `RETURNING` shows the modified values, which is what's actually in the table.
- **AFTER triggers**: changes an `AFTER` trigger makes to the table afterward are _not_ reflected in what `RETURNING` shows for that statement.
- **Views**: auto-updatable views support `RETURNING`. For views with `INSTEAD OF` triggers, the trigger function must return the row you want `RETURNING` to see.
- **Partitioned tables**: if an `UPDATE` moves a row to a different partition, `RETURNING` shows the row as it is in its new location.
- **Generated columns and defaults**: they're all computed by the time `RETURNING` runs, so you see final values.

## Limits and gotchas

- `COPY` has no `RETURNING`. For bulk loads where you need the generated IDs, use a multi-row `INSERT ... RETURNING`, or load into a staging table and then `INSERT ... SELECT ... RETURNING`.
- Multi-row inserts return rows in input order in practice, but with `INSERT ... SELECT` that has no `ORDER BY`, don't assume the output order lines up with the source order. If you need to map returned IDs back to your inputs, return a natural key too (like `email`) and join on it.
- `ON CONFLICT DO NOTHING` returns nothing for skipped rows, as covered above. If you need the existing rows, follow up with a `SELECT` (or use the no-op `DO UPDATE` trick, mindful of the bloat).
- In a plain `UPDATE`, `RETURNING` gives the new row only, and before PG 18 you need the `FROM` subquery trick for old values.
- A statement that affects millions of rows with `RETURNING *` sends millions of rows to the client. It's convenient, but it's real network and memory cost, so return only the columns you need, or aggregate inside a CTE.
- Because it's a data-modifying statement, a `RETURNING` query isn't something you can casually run "just to look." Wrap experiments in `BEGIN; ... ROLLBACK;`.

## Quick cheat sheet

```sql
INSERT ... RETURNING id;                           -- get generated id
INSERT ... RETURNING *;                            -- see the full stored row
UPDATE ... RETURNING balance;                      -- new value, atomically
UPDATE ... RETURNING old.x, new.x;                 -- before/after (PG 18+)
DELETE ... RETURNING *;                            -- what got removed
INSERT ... ON CONFLICT DO NOTHING RETURNING id;    -- skipped rows return nothing
INSERT ... ON CONFLICT DO UPDATE ... RETURNING id; -- inserted + updated rows return
MERGE ... RETURNING merge_action(), t.*;           -- PG 17+

WITH x AS (INSERT ... RETURNING id)                -- chain into the next statement
INSERT INTO child SELECT id, ... FROM x;
```




[[PostgreSQL]]