
# Anti-Joins: Finding What's _Missing_

An **anti-join** returns the rows from one table that have **no matching row** in another. Regular joins answer "what matches?", and an anti-join answers the opposite: "which customers have never ordered?", "which products were never sold?", "which users haven't logged in this month?"

Interestingly, SQL has no `ANTI JOIN` keyword. You write an anti-join using one of a few patterns, and PostgreSQL's planner recognizes them and runs them with a dedicated strategy. Knowing which pattern to pick (and which one has a nasty trap hiding in it) is the real skill, so let's walk through them.

## The question we'll answer

We'll reuse the little shop from the last lesson:

```sql
-- customers(id, name)
-- orders(id, customer_id, ordered_at)
```

**Goal: list every customer who has never placed an order.**

## Pattern 1: `NOT EXISTS` (the one to default to)

```sql
SELECT c.id, c.name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.id
);
```

Read it almost like English: "give me customers for whom there does not exist an order that points at them." The `SELECT 1` is a convention, because `EXISTS` only cares whether _any_ row comes back, not what's in it.

The subquery refers to `c.id` from the outer query, which makes it a _correlated_ subquery. That sounds expensive, but PostgreSQL doesn't run it once per customer. It rewrites the whole thing into a single **anti-join** internally.

## Pattern 2: `LEFT JOIN ... IS NULL`

You met the ingredients in the last lesson. A `LEFT JOIN` keeps every customer and fills the order columns with `NULL` when there's no match. Filter for those `NULL`s and only the unmatched customers remain:

```sql
SELECT c.id, c.name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.id IS NULL;
```

Test a column that can **never** be `NULL` in the real data, like the primary key `o.id`. If you test a nullable column, a genuine order with a `NULL` value there would be mistaken for "no match."

This form is popular because it reads naturally if you already think in joins, and it extends easily when you need to join several tables.

## Pattern 3: `NOT IN` (handle with care)

```sql
SELECT c.id, c.name
FROM customers c
WHERE c.id NOT IN (SELECT customer_id FROM orders);
```

It's the most readable of the three, and it's also the one that can **silently return wrong results.**

### The NULL trap

SQL uses three-valued logic: a comparison with `NULL` is neither true nor false, but _unknown_. Watch what happens if even one order has a `NULL` `customer_id`:

```sql
-- Imagine orders.customer_id contains: 1, 2, NULL
SELECT 5 NOT IN (1, 2, NULL);
```

PostgreSQL expands that to `5 <> 1 AND 5 <> 2 AND 5 <> NULL`. The last part is _unknown_, so the whole expression is never true. The result: **`NOT IN` returns zero rows**, even though plenty of customers have no orders.

In our schema `orders.customer_id` is `NOT NULL`, so we'd be safe, but schemas change and nullable foreign keys are common. If you must use `NOT IN`, guard the subquery:

```sql
WHERE c.id NOT IN (SELECT customer_id FROM orders WHERE customer_id IS NOT NULL)
```

`NOT EXISTS` and `LEFT JOIN ... IS NULL` don't have this problem, which is the main reason to prefer them.

## What PostgreSQL actually does

Run `EXPLAIN` on patterns 1 and 2 and you'll typically see a node like this:

```
Hash Anti Join
  Hash Cond: (c.id = o.customer_id)
  ->  Seq Scan on customers c
  ->  Hash
        ->  Seq Scan on orders o
```

The planner may also choose a **Nested Loop Anti Join** (good when an index on the inner table makes each lookup cheap) or a **Merge Anti Join** (when both sides arrive sorted). All three simply mean: "for each outer row, check whether a match exists, and keep the row only if none does."

`NOT IN` is different. Because of those `NULL` semantics, PostgreSQL can't convert it into a true anti-join. It usually falls back to a `SubPlan` that checks membership row by row, which is fast when the list is small enough to hash in memory but can degrade badly on large tables. Seeing `SubPlan` in your `EXPLAIN` output is a hint to rewrite with `NOT EXISTS`.

## Adding conditions: where `NOT EXISTS` shines

Say we want customers who **haven't ordered in the last 30 days**, which includes people who never ordered at all:

```sql
SELECT c.id, c.name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.id
      AND o.ordered_at > now() - interval '30 days'
);
```

The extra filter just goes inside the subquery. With the `LEFT JOIN` form, the same filter must go in the **`ON` clause**, not `WHERE`:

```sql
SELECT c.id, c.name
FROM customers c
LEFT JOIN orders o
       ON o.customer_id = c.id
      AND o.ordered_at > now() - interval '30 days'
WHERE o.id IS NULL;
```

Put the date filter in `WHERE` instead and you'd be filtering on a column that's `NULL` for exactly the rows you want, and the query would return nothing sensible. For conditions like this, many people find `NOT EXISTS` less error-prone.

## Anti-joins on several columns

Suppose you track which product each customer has bought, and you want pairs that _haven't_ happened yet. `NOT EXISTS` handles multi-column matching naturally:

```sql
SELECT c.id AS customer_id, p.id AS product_id
FROM customers c
CROSS JOIN products p
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE o.customer_id = c.id
      AND oi.product_id = p.id
);
```

This lists every customer/product combination where the customer never bought that product, which is the raw material for a "you might like..." feature.

## A cousin: `EXCEPT`

`EXCEPT` is a set operation that returns rows from the first query that don't appear in the second. It compares **entire rows** and removes duplicates:

```sql
SELECT id FROM customers
EXCEPT
SELECT customer_id FROM orders;
```

It's compact, and it treats two `NULL`s as equal, so it dodges the `NOT IN` trap. The catch is that you only get the columns you list in both queries, so to fetch the customer's name you'd need to wrap it in another query. It shines for quick comparisons, like checking which IDs exist in one table but not another.

## Real-world uses

Anti-joins show up constantly in everyday work:

- **Orphan detection:** find child rows whose parent is missing, say after a bad import:

```sql
SELECT o.id
FROM orders o
WHERE NOT EXISTS (SELECT 1 FROM customers c WHERE c.id = o.customer_id);
```

- **"Insert only the new ones":** useful in loading data and migrations:

```sql
INSERT INTO customers (id, name)
SELECT s.id, s.name
FROM staging_customers s
WHERE NOT EXISTS (SELECT 1 FROM customers c WHERE c.id = s.id);
```

(For this specific case, `INSERT ... ON CONFLICT DO NOTHING` is often simpler when a unique constraint exists.)

- **Gap analysis:** products never sold, users who never verified their email, days with no data.
- **Data reconciliation:** comparing two tables and listing what's missing from each side.

## Speed: one index does most of the work

An anti-join must check the "other" table for each candidate row, so the column used in that check should be indexed:

```sql
CREATE INDEX idx_orders_customer_id ON orders (customer_id);
```

With that index, PostgreSQL can use an efficient nested loop anti-join when the outer table is small, or it can hash the whole thing when both tables are large. As always, `EXPLAIN ANALYZE` shows what really happened.

## Its mirror image: the semi-join

If an anti-join asks "who has **no** match?", the **semi-join** asks "who has **at least one** match?", and you write it with `EXISTS`:

```sql
SELECT c.id, c.name
FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);
```

Unlike a regular `JOIN`, a semi-join never duplicates a customer who has ten orders. Each customer appears once, which makes it handy when you just need a yes/no check.

## Which pattern should you reach for?

|Pattern|Strengths|Watch out for|
|---|---|---|
|`NOT EXISTS`|Safe with `NULL`s, clear intent, planned as a true anti-join|Slightly wordier|
|`LEFT JOIN ... IS NULL`|Familiar, easy to chain across many tables|Conditions belong in `ON`; test a never-null column|
|`NOT IN`|Short and readable|Returns nothing if the list has a `NULL`; may plan as a slow `SubPlan`|
|`EXCEPT`|Great for comparing whole sets of rows|Only returns the listed columns; removes duplicates|

A good default: **start with `NOT EXISTS`.** Switch to `LEFT JOIN ... IS NULL` when you're already deep in a multi-table join, use `EXCEPT` for quick set comparisons, and only use `NOT IN` with a hard-coded list of values or a column you know can't be `NULL`.




[[PostgreSQL]]