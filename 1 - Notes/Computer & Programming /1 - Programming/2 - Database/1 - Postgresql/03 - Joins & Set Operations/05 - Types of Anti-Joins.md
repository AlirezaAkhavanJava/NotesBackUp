
#  Direction, Syntax, and Execution

"Anti-join" isn't one single thing. It's a family. You can classify anti-joins in three different ways: **which side you keep** (left, right, or both), **how you write them** in SQL, and **how PostgreSQL physically executes them** (hash, merge, or nested loop). Once you see all three angles, `EXPLAIN` output stops looking like alphabet soup.

This lesson builds on the last one, so I'll skip re-explaining `NOT EXISTS` versus `NOT IN` in depth and focus on how the types differ.

## Our two tiny tables

```sql
CREATE TABLE a (id INT, label TEXT);
CREATE TABLE b (id INT, label TEXT);

INSERT INTO a VALUES (1,'one'), (2,'two'), (3,'three');
INSERT INTO b VALUES (2,'two'), (3,'three'), (4,'four');
```

Keys 2 and 3 appear in both. Key 1 is only in `a`, and key 4 is only in `b`.

## Angle 1: Which side are you keeping?

### Left anti-join: rows of A with no match in B

```sql
SELECT a.*
FROM a
WHERE NOT EXISTS (SELECT 1 FROM b WHERE b.id = a.id);
-- returns: (1, 'one')
```

This is the one most people mean when they say "anti-join."

### Right anti-join: rows of B with no match in A

It's the exact mirror, with the tables swapped:

```sql
SELECT b.*
FROM b
WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.id = b.id);
-- returns: (4, 'four')
```

There's no special syntax. A "right" anti-join is just a left anti-join written from the other table's point of view. The distinction becomes real only inside the planner, which we'll reach shortly.

### Full anti-join: unmatched rows from both sides

Sometimes you want everything that _doesn't_ line up, in either direction. This is also known as the symmetric difference. A `FULL JOIN` makes it easy:

```sql
SELECT a.id AS a_id, b.id AS b_id
FROM a
FULL JOIN b ON a.id = b.id
WHERE a.id IS NULL OR b.id IS NULL;
-- returns: (1, NULL) and (NULL, 4)
```

Rows where `a.id` is `NULL` exist only in `b`, and rows where `b.id` is `NULL` exist only in `a`. This is the go-to query for **reconciling two tables** and seeing every discrepancy at once. (Test never-null columns like keys, as we discussed before.)

## Angle 2: How do you write it?

The same left anti-join can be spelled four ways. Here's a quick side-by-side for "rows of `a` missing from `b`":

```sql
-- 1. NOT EXISTS
SELECT a.* FROM a
WHERE NOT EXISTS (SELECT 1 FROM b WHERE b.id = a.id);

-- 2. LEFT JOIN ... IS NULL
SELECT a.* FROM a
LEFT JOIN b ON b.id = a.id
WHERE b.id IS NULL;

-- 3. NOT IN
SELECT a.* FROM a
WHERE a.id NOT IN (SELECT id FROM b WHERE id IS NOT NULL);

-- 4. EXCEPT (compares whole rows, so the column lists must match)
SELECT id FROM a
EXCEPT
SELECT id FROM b;
```

The first two are planned as true anti-joins. `NOT IN` usually becomes a `SubPlan` (or a hashed one), and `EXCEPT` uses its own `SetOp` machinery. All four are logically the same, but the planner treats them differently, which leads to the third angle.

## Angle 3: How does PostgreSQL execute it?

When PostgreSQL recognizes a true anti-join, it picks one of several physical algorithms. In `EXPLAIN`, these appear as distinct node types.

### Hash Anti Join

PostgreSQL builds an in-memory hash table from one table, then probes it with rows from the other. A row survives only if the probe finds **no** match.

```
Hash Anti Join
  Hash Cond: (a.id = b.id)
  ->  Seq Scan on a
  ->  Hash
        ->  Seq Scan on b
```

This is the typical choice for large tables with an equality condition. It makes one pass over each table and needs no indexes or sorting.

### Hash Right Anti Join

Normally the hash table is built on the _inner_ table, which here is the one you're checking against. But if the planner decides the table you're keeping is the smaller one, it can hash _that_ side instead and flip the logic: scan the big table, mark hash entries that find a match, and at the end emit the entries that were never matched.

```
Hash Right Anti Join
  Hash Cond: (b.id = a.id)
  ->  Seq Scan on b
  ->  Hash
        ->  Seq Scan on a
```

This node type is available in PostgreSQL 16 and later. It's purely an optimization that lets the planner pick the cheaper side to hash. Your SQL doesn't change.

### Merge Anti Join

Both inputs are sorted on the join key (or read from an index that already gives sorted order), then PostgreSQL walks them side by side like a zipper, emitting rows from the first input that never find a partner.

```
Merge Anti Join
  Merge Cond: (a.id = b.id)
  ->  Index Only Scan using a_pkey on a
  ->  Index Only Scan using b_pkey on b
```

This shines when both sides are already sorted by indexes, or when the data is too big for a hash table to fit in memory.

### Nested Loop Anti Join

For each row of the outer table, PostgreSQL probes the inner table to see if a match exists, and stops at the first hit.

```
Nested Loop Anti Join
  ->  Seq Scan on a
  ->  Index Only Scan using b_pkey on b
        Index Cond: (id = a.id)
```

It's excellent when the outer side is small and the inner side has an index, because each probe is a fast lookup. It's also the **only** option when the match condition isn't a simple equality. For example, finding time slots with no overlapping booking:

```sql
SELECT s.*
FROM slots s
WHERE NOT EXISTS (
    SELECT 1 FROM bookings k
    WHERE k.starts_at < s.ends_at
      AND k.ends_at   > s.starts_at
);
```

Hash and merge strategies need an equality to work with, so range conditions like these force a nested loop (or a smarter index, such as a GiST index on a range type).

## The odd one out: NOT IN

`NOT IN` often shows up in plans as a `SubPlan` rather than any anti-join node:

```
Seq Scan on a
  Filter: (NOT (hashed SubPlan 1))
  SubPlan 1
    ->  Seq Scan on b
```

"Hashed SubPlan" is the fast variant: PostgreSQL loads the list into a hash table once and checks each row against it. It only does this when the list fits in `work_mem`. If it doesn't, you get a plain `SubPlan` that rescans the list for every row, which can be painfully slow. That's another good reason to prefer `NOT EXISTS`.

## Putting the three angles together

|Angle|The types|Question it answers|
|---|---|---|
|**Direction**|Left, right, full|Which side's unmatched rows do I want?|
|**Syntax**|`NOT EXISTS`, `LEFT JOIN … IS NULL`, `NOT IN`, `EXCEPT`, `FULL JOIN … IS NULL`|How do I write it so it's correct and plannable?|
|**Execution**|Hash, hash right, merge, nested loop|How does PostgreSQL actually run it?|

You control the first two. The planner chooses the third, based on table sizes, indexes, statistics, and `work_mem`.

## Seeing it for yourself

Want to watch the planner switch strategies? Try this experiment on a pair of tables:

```sql
EXPLAIN ANALYZE
SELECT a.* FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE b.id = a.id);
```

Run it with tiny tables, then with a million rows each, then with and without an index on `b.id`. You'll likely see the node type change between nested loop, hash, and merge. If something looks slower than expected, run `ANALYZE a; ANALYZE b;` first, because stale statistics are a common reason for a poor choice.

## Quick recap

Anti-joins come in left, right, and full flavors depending on which unmatched rows you want. You can write them with `NOT EXISTS`, `LEFT JOIN ... IS NULL`, `NOT IN`, `EXCEPT`, or a `FULL JOIN` filtered on `NULL`s. Under the hood, PostgreSQL runs them as a Hash, Hash Right, Merge, or Nested Loop Anti Join, with `NOT IN` as the odd one that often becomes a `SubPlan`.




[[PostgreSQL]]