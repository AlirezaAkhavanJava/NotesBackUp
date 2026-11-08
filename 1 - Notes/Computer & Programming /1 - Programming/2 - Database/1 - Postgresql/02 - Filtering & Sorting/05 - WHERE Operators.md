


A `WHERE` clause is built from operators: small symbols and keywords that compare values, combine conditions, match patterns, and test for membership. Each operator takes values and produces `TRUE`, `FALSE`, or `NULL`, and only rows where the whole condition comes out `TRUE` are kept. Knowing which operator to reach for (and how each one handles `NULL`s and indexes) is most of what it takes to write correct filters.

We covered `WHERE` as a clause earlier, so this one is a tour of the operators themselves, grouped by what they do. We'll use this table:

```sql
CREATE TABLE products (
    id        serial PRIMARY KEY,
    name      text NOT NULL,
    category  text,
    price     numeric(10,2),
    tags      text[],
    specs     jsonb,
    in_stock  boolean NOT NULL DEFAULT true,
    added_on  date NOT NULL
);
```

---

## 1. Comparison operators

|Operator|Meaning|
|---|---|
|`=`|equal|
|`<>` or `!=`|not equal|
|`<`, `>`, `<=`, `>=`|ordering comparisons|

```sql
WHERE price >= 20
WHERE category <> 'toys'
```

Remember that SQL uses a single `=`, and that any comparison with `NULL` yields `NULL`, so `category <> 'toys'` also drops rows whose category is `NULL`. Strings compare according to the column's collation, and `=` on text is case-sensitive.

## 2. Logical operators: AND, OR, NOT

```sql
WHERE in_stock AND price < 50
WHERE category = 'books' OR category = 'music'
WHERE NOT in_stock
```

Precedence is `NOT`, then `AND`, then `OR`. Mixing `AND` and `OR` without parentheses is the classic source of wrong results, so always bracket:

```sql
WHERE in_stock AND (category = 'books' OR category = 'music')
```

With `NULL`s, the logic is three-valued: `TRUE OR NULL` is `TRUE`, but `FALSE OR NULL` is `NULL`, and `FALSE AND NULL` is `FALSE`, while `TRUE AND NULL` is `NULL`.

## 3. Range and list operators

**`BETWEEN`** is inclusive on both ends:

```sql
WHERE price BETWEEN 10 AND 20        -- same as price >= 10 AND price <= 20
WHERE price NOT BETWEEN 10 AND 20
```

It's fine for numbers and dates, but risky for timestamps, because the upper bound matches only that exact instant. For timestamps use `>= start AND < next_start` instead.

**`IN`** checks membership in a list:

```sql
WHERE category IN ('books', 'music', 'film')
WHERE category NOT IN ('toys', 'games')
```

`NOT IN` has a famous trap: if the list (or subquery) contains even one `NULL`, it never returns `TRUE` and you get zero rows. Prefer `NOT EXISTS` for subqueries.

## 4. NULL operators

Because `= NULL` never works, Postgres gives you dedicated operators:

```sql
WHERE category IS NULL
WHERE category IS NOT NULL
WHERE category IS DISTINCT FROM 'toys'       -- null-safe "not equal"
WHERE category IS NOT DISTINCT FROM $1       -- null-safe "equal"
```

`IS DISTINCT FROM` treats `NULL` as an ordinary value, which makes it great for comparing two nullable columns or an optional parameter. Boolean columns also have `IS TRUE`, `IS NOT TRUE`, `IS FALSE`, and `IS UNKNOWN`. Note that `WHERE flag IS NOT TRUE` returns both `FALSE` and `NULL` rows.

## 5. Pattern matching

**`LIKE` / `ILIKE`** use two wildcards: `%` for any number of characters and `_` for exactly one.

```sql
WHERE name LIKE 'Pro%'        -- starts with Pro (case-sensitive)
WHERE name ILIKE '%phone%'    -- contains phone (case-insensitive, Postgres-only)
WHERE name LIKE '__-%'        -- two characters, then a dash
```

**Regular expressions** are more powerful:

|Operator|Meaning|
|---|---|
|`~`|matches regex, case-sensitive|
|`~*`|matches regex, case-insensitive|
|`!~`, `!~*`|does not match|

```sql
WHERE name ~ '^[A-Z]{3}-\d+$'
```

**`SIMILAR TO`** exists (it's a SQL-standard hybrid of `LIKE` and regex), but it's rarely worth using. Pick `LIKE` for simple cases and `~` for anything complex.

For speed: `LIKE 'abc%'` (anchored at the start) can use a B-tree index in the right setup, but `LIKE '%abc%'` cannot. For those, use the `pg_trgm` extension with a GIN index.

## 6. Subquery operators

```sql
WHERE price > (SELECT avg(price) FROM products)            -- scalar comparison
WHERE category IN (SELECT name FROM featured_categories)
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.product_id = products.id)
WHERE price > ANY (SELECT price FROM products WHERE category = 'books')   -- beats at least one
WHERE price > ALL (SELECT price FROM products WHERE category = 'books')   -- beats every one
```

`EXISTS` only asks whether at least one row comes back, so the select list inside doesn't matter. `= ANY(array)` is equivalent to `IN` and is handy for passing a whole array as one parameter:

```sql
WHERE category = ANY ($1)        -- $1 is a text[] parameter
```

## 7. Array operators

```sql
WHERE tags @> ARRAY['sale']              -- tags contains all of these
WHERE tags <@ ARRAY['sale','new','hot']  -- tags is contained in this set
WHERE tags && ARRAY['sale','clearance']  -- tags overlaps (shares at least one)
WHERE 'sale' = ANY (tags)                -- one value is in the array
```

A GIN index on the array column makes `@>`, `<@`, and `&&` fast.

## 8. JSON operators

```sql
WHERE specs ->> 'color' = 'red'          -- ->> extracts text
WHERE (specs -> 'dims' ->> 'width')::int > 30    -- -> extracts JSON, drill down, then cast
WHERE specs @> '{"wifi": true}'          -- jsonb containment
WHERE specs ? 'battery'                  -- top-level key exists
WHERE specs ?| ARRAY['battery','solar']  -- any of these keys exists
```

`->` returns JSON and `->>` returns text, which is the usual source of type errors. A GIN index on a `jsonb` column speeds up `@>` and `?`. For `->>` comparisons on one key, an expression index like `CREATE INDEX ON products ((specs ->> 'color'))` is the right tool.

## 9. Range and date operators

Postgres has native range types (`int4range`, `daterange`, `tstzrange`, and others) with their own operators:

```sql
WHERE validity @> now()                         -- range contains a value
WHERE validity && tstzrange('2026-01-01', '2026-02-01')   -- overlaps another range
```

For plain dates and timestamps, the ordinary comparison operators plus `interval` arithmetic cover most needs:

```sql
WHERE added_on >= current_date - interval '30 days'
```

`OVERLAPS` also exists for comparing two date or time periods, such as `(start1, end1) OVERLAPS (start2, end2)`.

## 10. Row-wise comparison

Comparing several columns as one tuple is perfect for keyset pagination:

```sql
WHERE (added_on, id) > ('2026-06-01', 120)
ORDER BY added_on, id
LIMIT 50;
```

It compares the first element, and moves to the next only on a tie.

## 11. Precedence in one glance

From tightest to loosest, roughly: arithmetic (`*`, `/`, then `+`, `-`), then comparison operators (`=`, `<`, `>`...), then `IS`, then `BETWEEN`/`IN`/`LIKE`, then `NOT`, then `AND`, then `OR`. You don't need to memorize this: use parentheses whenever you mix categories, and the question never comes up.

## 12. Operators and indexes

An operator can use an index only when the index was built for that operator and the column is used "bare."

- **B-tree** (the default) supports `=`, `<`, `>`, `<=`, `>=`, `BETWEEN`, `IN`, `IS NULL`, and anchored `LIKE 'abc%'` (with the right operator class if your collation isn't `C`).
- **GIN** supports array operators (`@>`, `&&`), `jsonb` operators, and trigram or full-text matching.
- **GiST** supports range overlap/containment and geometric operators.
- **Wrapping the column in a function** (`lower(name) = ...`, `date_trunc(...)`) defeats a plain index, so use a matching expression index or rewrite the condition.
- **Type mismatches** can force a cast on the column and block the index. Compare a column to a value of its own type.

## Common mistakes

- Writing `= NULL` instead of `IS NULL`.
- Using `NOT IN` with a list or subquery that can contain `NULL`s.
- Mixing `AND`/`OR` without parentheses.
- Using `BETWEEN` for timestamp ranges.
- Expecting `LIKE` to be case-insensitive (use `ILIKE`).
- Using `->` when you need text (`->>`), then getting type errors.
- Using a leading-wildcard `LIKE '%x'` on a big table and expecting an index to help.

## Quick cheat sheet

```sql
=  <>  <  >  <=  >=                    -- compare
AND  OR  NOT                           -- combine (use parentheses!)
BETWEEN a AND b     IN (...)           -- range and list
IS NULL   IS NOT NULL   IS DISTINCT FROM   -- NULL-safe tests
LIKE  ILIKE  ~  ~*                     -- patterns
EXISTS (...)   = ANY (...)   > ALL (...)   -- subquery tests
@>  <@  &&                             -- contains / contained / overlaps
->  ->>  ?                             -- JSON access and key checks
(a, b) > (x, y)                        -- row-wise comparison
```

## Try it yourself

1. Find in-stock products priced between 10 and 50 in either `books` or `music`.
2. Find products with no category, then products whose category is not `toys` (including the ones with no category).
3. Find products whose name contains "pro", ignoring case, then do it again with a regex.
4. Find products tagged `sale` that also have a `battery` key in `specs`.
5. Write a `NOT IN` query that breaks because of a `NULL`, then fix it with `NOT EXISTS`.




[[PostgreSQL]]