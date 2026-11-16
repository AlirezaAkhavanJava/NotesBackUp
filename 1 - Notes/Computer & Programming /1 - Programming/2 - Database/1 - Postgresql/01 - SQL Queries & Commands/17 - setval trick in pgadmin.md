

A PostgreSQL sequence doesn't look at your table to decide what number comes next — it just keeps its own internal counter and hands out `nextval()` results from memory. That's exactly what makes sequences fast, but it also means the sequence and the table can **drift apart**. If something inserts rows into the table _without_ going through the sequence (a bulk import, a `pg_restore`, a manual `INSERT ... VALUES (5, ...)` with an explicit id), the table now has an id the sequence doesn't know about. The next time Hibernate or anyone else calls `nextval()`, it can hand out an id that already exists, and you get a primary key violation.

`setval` is the tool for forcibly telling the sequence "the counter is actually at this number now." It's the fix for that drift, and it's something you'll reach for almost every time you load data into Postgres from outside the normal insert-through-the-app path.

## The function itself

```sql
setval('sequence_name', value);
setval('sequence_name', value, is_called);
```

- **`sequence_name`** — the sequence's name, as text (quoted), e.g. `'orders_id_seq'`.
- **`value`** — the number you want the sequence's internal counter set to.
- **`is_called`** — optional boolean, defaults to `true`. This controls whether `value` itself has already been "used":
    - `true` (default): the _next_ `nextval()` call returns `value + 1`.
    - `false`: the _next_ `nextval()` call returns `value` itself.

So these two calls behave differently even though the numbers look similar:

```sql
SELECT setval('orders_id_seq', 100);        -- next nextval() → 101
SELECT setval('orders_id_seq', 100, false);  -- next nextval() → 100
```

## The actual trick: syncing to the table's real max id

The one-liner you'll use constantly is this:

```sql
SELECT setval('orders_id_seq', (SELECT MAX(id) FROM orders));
```

This reads the highest `id` currently in `orders`, and sets the sequence so the _next_ generated id continues right after it. Because `is_called` defaults to `true`, this is exactly what you want: if the max id is 500, the sequence will next hand out 501, not 500.

There's one edge case worth knowing: if the table is completely empty, `MAX(id)` returns `NULL`, and `setval` will error out on a `NULL` value. The safe version people actually put in migration scripts is:

```sql
SELECT setval('orders_id_seq', COALESCE((SELECT MAX(id) FROM orders), 1), false);
```

Here `is_called` is `false` and the fallback is `1`, so an empty table correctly resets the sequence to hand out `1` as the very first value, instead of skipping it.

## Why your `allocationSize` matters here

Since you've already learned `@SequenceGenerator`'s `allocationSize`: remember that Hibernate grabs ids in _batches_ when `allocationSize > 1` — it might call `nextval()` once and reserve 50 ids for itself in memory, handing them out to entities one at a time before it goes back to the database. That means the database-side sequence value can legitimately sit _ahead_ of the highest id actually saved, even with no drift at all. Don't panic if `currval` looks higher than `MAX(id)` in a Hibernate-managed table — that's normal batching, not corruption. `setval` is for fixing the opposite problem: when the sequence has fallen _behind_ the table.

## Doing this in pgAdmin

pgAdmin doesn't need any special UI for `setval` — it's just SQL, so the most direct route is:

1. Open the **Query Tool** on the database (right-click the database → Query Tool).
2. Run the `setval` statement directly, same as above.

But pgAdmin also gives you a GUI view of sequences if you want to check things without writing SQL first:

- In the browser tree: **Databases → your database → Schemas → public → Sequences** → your sequence name.
- Right-click it and choose **Properties**. The **Definition** tab shows **Current value** and **Increment**, so you can see where the sequence currently sits before you decide whether it needs fixing.
- There's no "set value" field in that dialog, though — editing it there changes the sequence's _definition_ (start value, increment, min/max), not its _live counter position_. For actually moving the live counter, you still run `setval` through the Query Tool.

A quick way to check for drift before reaching for `setval` at all:

```sql
SELECT last_value FROM orders_id_seq;           -- where the sequence thinks it is
SELECT MAX(id) FROM orders;                     -- where the table actually is
```

If the sequence's `last_value` is lower than the table's real max, that's your signal to run the `setval` fix.


[[PostgreSQL]]