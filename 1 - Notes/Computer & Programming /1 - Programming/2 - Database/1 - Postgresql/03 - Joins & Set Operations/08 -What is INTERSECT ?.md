
# INTERSECT: "What Do These Two Results Have in Common?"

`INTERSECT` takes the results of two queries and returns only the rows that appear in **both**. If `UNION` is "everything from either," and `EXCEPT` is "this minus that," then `INTERSECT` is the overlap in the middle of a Venn diagram. It completes the set-operation trio you've been building up over the last two lessons.

Picture two guest lists again: people invited to the dinner and people invited to the afterparty. `INTERSECT` hands you the people on both lists, the ones you'll be seeing all night. Let's look at how it works and where it earns its keep.

## The basics

```sql
CREATE TABLE customers (name TEXT, email TEXT);
CREATE TABLE suppliers (name TEXT, email TEXT);

INSERT INTO customers VALUES ('Alice','alice@mail.com'), ('Bob','bob@mail.com'), ('Carol','carol@mail.com');
INSERT INTO suppliers VALUES ('Bob','bob@mail.com'), ('Carol','carol@mail.com'), ('Dave','dave@mail.com');
```

```sql
SELECT name, email FROM customers
INTERSECT
SELECT name, email FROM suppliers;
```

Result: Bob and Carol. Alice is only a customer and Dave is only a supplier, so both are left out. Unlike `EXCEPT`, order doesn't change the _set_ of rows returned: `A INTERSECT B` and `B INTERSECT A` give the same rows (though row order in the output isn't guaranteed either way).

## The rules

They're the same as for `UNION` and `EXCEPT`:

1. Both queries must return the **same number of columns**.
2. Matching columns (by **position**, not name) need **compatible types**.
3. Column names come from the first query.
4. Rows match only if **every selected column** is equal.

That last rule is the one that bites. If you select `name, email` and Bob's name is spelled differently in the two tables, he won't appear. To intersect on just one attribute, select just that column:

```sql
SELECT email FROM customers
INTERSECT
SELECT email FROM suppliers;
```

## INTERSECT removes duplicates

Plain `INTERSECT` returns **distinct** rows:

```sql
SELECT x FROM (VALUES (1), (1), (2), (3)) t(x)
INTERSECT
SELECT x FROM (VALUES (1), (1), (3)) t(x);
-- returns 1 and 3, each once
```

## INTERSECT ALL: counting the overlap

`INTERSECT ALL` keeps duplicates, but only as many copies as appear in **both** inputs, so it takes the smaller count:

```sql
SELECT x FROM (VALUES (1), (1), (1), (2)) t(x)
INTERSECT ALL
SELECT x FROM (VALUES (1), (1), (3)) t(x);
```

The first query has three `1`s and the second has two, so two `1`s are returned. The `2` and `3` appear on only one side, so they vanish. Result: `1, 1`.

This is useful when quantities matter, such as finding how many units two warehouses could swap with each other.

## NULLs: they match each other

As with the other set operations, two `NULL`s are treated as **equal**:

```sql
SELECT NULL::int
INTERSECT
SELECT NULL::int;
-- returns one row (NULL)
```

This differs from `=`, where `NULL = NULL` is never true. It means `INTERSECT` is safe for columns that may contain `NULL`s, while a join written as `ON a.x = b.x` would silently miss them.

## INTERSECT versus a join

You can get the same answer with an inner join or `EXISTS`:

```sql
-- INTERSECT
SELECT email FROM customers
INTERSECT
SELECT email FROM suppliers;

-- Semi-join with EXISTS
SELECT DISTINCT c.email
FROM customers c
WHERE EXISTS (SELECT 1 FROM suppliers s WHERE s.email = c.email);

-- Inner join
SELECT DISTINCT c.email
FROM customers c
JOIN suppliers s ON s.email = c.email;
```

||`INTERSECT`|`JOIN` / `EXISTS`|
|---|---|---|
|Compares|Whole rows, all selected columns|A condition you write|
|Duplicates|Removed (unless `ALL`)|Kept (join) or avoided (`EXISTS`)|
|Extra columns|Only those in both queries|Any column from either table|
|`NULL`s|Match each other|Don't match with `=`|
|Match logic|Equality only|Any condition (ranges, etc.)|

Reach for `INTERSECT` when you want to compare two result sets as wholes, especially with many columns or possible `NULL`s. Use a join or `EXISTS` when you need extra columns or a non-equality condition.

## Chaining and precedence

`INTERSECT` has **higher precedence** than `UNION` and `EXCEPT`, meaning it's evaluated first:

```sql
SELECT email FROM customers
UNION
SELECT email FROM suppliers
INTERSECT
SELECT email FROM newsletter;
```

This is parsed as `customers UNION (suppliers INTERSECT newsletter)`, which may not be what you meant. Use parentheses to say what you want:

```sql
(SELECT email FROM customers
 UNION
 SELECT email FROM suppliers)
INTERSECT
SELECT email FROM newsletter;   -- contacts of either kind who are subscribed
```

You can also intersect more than two queries by chaining: `A INTERSECT B INTERSECT C` returns rows present in all three.

## Real-world uses

**Finding shared members:** which customers also bought from a second category?

```sql
SELECT customer_id FROM orders o JOIN order_items oi ON oi.order_id = o.id WHERE oi.product_id = 10
INTERSECT
SELECT customer_id FROM orders o JOIN order_items oi ON oi.order_id = o.id WHERE oi.product_id = 20;
```

This returns customers who bought **both** product 10 and product 20, a question that's awkward to express with a single `WHERE` clause (since `product_id = 10 AND product_id = 20` can never be true for one row). It's a classic use of `INTERSECT`.

**Segment overlap:** users who are both "active this month" and "on the premium plan."

**Reconciliation checks:** confirm which records exist in both a source and a target after a migration.

**Verifying equality:** combined with `EXCEPT`, you can prove two tables hold the same data:

```sql
SELECT COUNT(*) FROM (
    SELECT * FROM old_table
    INTERSECT
    SELECT * FROM new_table
) t;
-- compare to the row count of each table
```

## Sorting and limiting

A trailing `ORDER BY` applies to the whole result. Parentheses let you shape individual branches:

```sql
(SELECT email FROM customers ORDER BY email LIMIT 100)
INTERSECT
SELECT email FROM suppliers
ORDER BY email;
```

## Performance notes

- PostgreSQL runs `INTERSECT` with a **SetOp** node, either sorted (`SetOp Intersect`) or hashed (`HashSetOp Intersect`), fed by an `Append` of both inputs. `EXPLAIN` shows which.
- Both inputs are fully processed, so a join or `EXISTS` with a good index can be faster when one side is small and the other is huge.
- Select only the columns you need to compare. Wider rows cost more to sort or hash.
- Filter inside each branch so each side can use its own indexes.

## Common mistakes

- **Extra columns that never match.** Adding something like a timestamp or auto-generated ID to the select list means no rows overlap.
- **Positional mix-ups.** Columns are matched by position, so the same column order is essential in both queries.
- **Precedence surprises** when mixing with `UNION` or `EXCEPT`. Add parentheses.
- **Forgetting that it de-duplicates.** Use `INTERSECT ALL` when counts matter.

## The trio at a glance

|Operator|Returns|Venn picture|
|---|---|---|
|`UNION`|Rows in either|Both circles|
|`INTERSECT`|Rows in both|The overlap|
|`EXCEPT`|Rows in the first only|Left circle minus overlap|

## Quick recap

`INTERSECT` returns the distinct rows present in **both** queries, comparing whole rows by position and treating `NULL`s as equal. `INTERSECT ALL` keeps the smaller duplicate count. It binds tighter than `UNION` and `EXCEPT`, so use parentheses when mixing them, and it shines for "has both" questions and for comparing whole result sets.




[[PostgreSQL]]