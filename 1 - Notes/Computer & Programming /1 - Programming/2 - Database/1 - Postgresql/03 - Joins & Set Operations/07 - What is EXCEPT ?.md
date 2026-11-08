# EXCEPT: "Everything in This Set, Minus That Set"

`EXCEPT` takes the results of two queries and returns the rows that appear in the **first** but **not the second**. It's subtraction for query results: result A minus result B. You met it briefly in the anti-join and `UNION` lessons, so now let's give it the full treatment.

Think of two guest lists. List A is everyone you invited, and list B is everyone who has already RSVP'd. `A EXCEPT B` gives you the people you're still waiting to hear from. Order matters, because `B EXCEPT A` would give you RSVPs from people you never invited, which is a very different question.

## The basics

```sql
CREATE TABLE invited (name TEXT, email TEXT);
CREATE TABLE rsvped  (name TEXT, email TEXT);

INSERT INTO invited VALUES ('Alice','alice@mail.com'), ('Bob','bob@mail.com'), ('Carol','carol@mail.com');
INSERT INTO rsvped  VALUES ('Bob','bob@mail.com'), ('Dave','dave@mail.com');
```

```sql
SELECT name, email FROM invited
EXCEPT
SELECT name, email FROM rsvped;
```

Result: Alice and Carol. Bob is removed because his row exists in both. Dave doesn't appear at all, because `EXCEPT` only ever returns rows from the first query.

Swap the order and you get Dave alone:

```sql
SELECT name, email FROM rsvped
EXCEPT
SELECT name, email FROM invited;
```

## The rules

`EXCEPT` follows the same rules as `UNION`:

1. Both queries must return the **same number of columns**.
2. Matching columns (by **position**, not name) must have **compatible types**.
3. Column names come from the first query.

Matching is on the **entire row**. Two rows count as "the same" only if every selected column is equal. So if you select `name, email` and Bob's email differs between the lists, he stays in the result.

## EXCEPT removes duplicates

Plain `EXCEPT` returns **distinct** rows, even when the first query has repeats:

```sql
SELECT x FROM (VALUES (1), (1), (2), (3)) t(x)
EXCEPT
SELECT x FROM (VALUES (3)) t(x);
-- returns 1 and 2, each once
```

The two copies of `1` collapsed into one. If you want to keep duplicates, use `EXCEPT ALL`.

## EXCEPT ALL: subtraction with counting

`EXCEPT ALL` treats rows like a multiset, subtracting occurrence by occurrence:

```sql
SELECT x FROM (VALUES (1), (1), (1), (2)) t(x)
EXCEPT ALL
SELECT x FROM (VALUES (1), (2), (2)) t(x);
```

The first query has three `1`s and the second has one, so two `1`s remain. The first has one `2` and the second has two, so zero `2`s remain (it never goes negative). Result: `1, 1`.

It's handy for reconciliation when quantities matter, such as comparing two inventory lists where the same item can legitimately appear several times.

## NULLs: where EXCEPT beats NOT IN

For set operations, two `NULL`s count as **equal**. That makes `EXCEPT` immune to the trap that makes `NOT IN` dangerous:

```sql
SELECT x FROM (VALUES (1), (NULL)) t(x)
EXCEPT
SELECT x FROM (VALUES (NULL::int)) t(x);
-- returns 1; the NULL row is correctly subtracted
```

With `NOT IN`, that `NULL` in the second list would have wiped out the entire result.

## EXCEPT versus the other anti-join patterns

||`EXCEPT`|`NOT EXISTS` / `LEFT JOIN ... IS NULL`|
|---|---|---|
|Compares|Whole rows, all selected columns|A key you choose|
|Duplicates|Removed (unless `ALL`)|Kept as they are|
|Columns returned|Only those in both queries|Any column from the left table|
|`NULL` handling|`NULL`s match each other|Depends on how you write it|
|Best for|Comparing two result sets, reconciliation|Filtering a table by a missing relationship|

The biggest practical limitation: you only get the columns you listed. To fetch the customer's name for IDs that never ordered, you'd have to wrap `EXCEPT` in a subquery:

```sql
SELECT c.id, c.name
FROM customers c
WHERE c.id IN (
    SELECT id FROM customers
    EXCEPT
    SELECT customer_id FROM orders
);
```

At that point, `NOT EXISTS` is usually simpler and often faster.

## Combining with other set operations

`EXCEPT` shares precedence with `UNION` (both evaluated left to right), while `INTERSECT` binds tighter. When mixing them, use parentheses so your intent is unmistakable:

```sql
(SELECT email FROM customers
 UNION
 SELECT email FROM suppliers)
EXCEPT
SELECT email FROM unsubscribed;
```

This reads: "all customer and supplier emails, minus anyone who unsubscribed", a classic mailing-list query. Without the parentheses, it would still go left to right here, but being explicit protects you from surprises.

## Sorting and limiting

Like `UNION`, a final `ORDER BY` applies to the whole result, and parentheses let you shape individual branches:

```sql
SELECT email FROM invited
EXCEPT
SELECT email FROM rsvped
ORDER BY email;
```

## Real-world uses

**Data reconciliation:** compare two tables in both directions to find every discrepancy.

```sql
(SELECT * FROM old_table EXCEPT SELECT * FROM new_table)
UNION ALL
(SELECT * FROM new_table EXCEPT SELECT * FROM old_table);
```

If this returns zero rows, the two tables contain identical data. It's a favorite for verifying a migration or refactor.

**Verifying a rewritten query:** run the old and new versions through `EXCEPT` in both directions. Empty results mean they agree.

**Finding missing references:**

```sql
SELECT DISTINCT customer_id FROM orders
EXCEPT
SELECT id FROM customers;   -- orders pointing at customers that don't exist
```

**Gap analysis:** which expected values never showed up?

```sql
SELECT generate_series(1, 100) AS id
EXCEPT
SELECT id FROM tickets;     -- ticket numbers that were skipped
```

## Performance notes

- PostgreSQL executes `EXCEPT` with a **SetOp** node, using either a sorted approach (`SetOp Except`) or a hashed one (`HashSetOp Except`), fed by an `Append` of both inputs. Run `EXPLAIN` to see which.
- Because it must compare entire rows, wide rows with many columns cost more. Select only the columns you actually need to compare.
- Filtering inside each branch lets each side use its own indexes.
- For very large tables, `NOT EXISTS` with an index on the lookup column often wins, because it can stop at the first match rather than processing both full sets. Measure with `EXPLAIN ANALYZE`.

## Common mistakes

- **Wrong order.** `A EXCEPT B` and `B EXCEPT A` answer different questions.
- **Column mismatch.** Matching is positional, so mismatched column order can silently compare the wrong things.
- **Unexpected row collapse.** Remember plain `EXCEPT` de-duplicates, so counts may drop. Use `EXCEPT ALL` when counts matter.
- **Selecting too many columns.** An extra column like a timestamp that always differs means no row ever matches, so nothing gets subtracted.

## Quick recap

`EXCEPT` returns the distinct rows from the first query that don't appear in the second, comparing whole rows by position and treating `NULL`s as equal. `EXCEPT ALL` subtracts with counts. It's ideal for comparing two result sets and reconciling data, while `NOT EXISTS` is usually better when you need extra columns or maximum speed on big tables.




[[PostgreSQL]]