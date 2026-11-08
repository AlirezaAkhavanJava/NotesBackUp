
# The `::` operator in PostgreSQL: type casting

The `::` operator converts a value from one data type to another. You write the value, then `::`, then the type you want: `'42'::integer` turns the text `'42'` into the number 42. It is PostgreSQL's own short form of the standard SQL `CAST(value AS type)`, and you will see it in almost every real PostgreSQL query, migration, and Spring Boot native query.

Casting matters because PostgreSQL is strict about types. It will not guess that a `varchar` should be an `inet`, or that text should be a date. When types don't match, you get an error. `::` is how you tell the database exactly what you mean.

---

## 1. The problem it solves

Here are three situations where it saves you.

**A. Text that should be something else.** Data often arrives as strings (from a CSV, a JSON payload, or Java).

```sql
SELECT '2026-11-01'::date;        -- 2026-11-01 (a real date)
SELECT '192.168.1.5'::inet;       -- 192.168.1.5 (a real IP)
```

**B. Integer division surprises.**

```sql
SELECT 7 / 2;                 -- 3  (both are integers, so the result is an integer)
SELECT 7::numeric / 2;        -- 3.5000000000000000
```

**C. Matching types in comparisons and functions.**

```sql
SELECT * FROM orders WHERE id = '15'::int;
```

---

## 2. The syntax, line by line

```sql
SELECT '123'::integer;
```

- `'123'` is a string literal.
- `::` means "convert to."
- `integer` is the target type.

The result is the number 123.

All three forms below do the same thing:

|Form|Example|Notes|
|---|---|---|
|`::`|`'123'::integer`|PostgreSQL-specific, short, easy to chain|
|`CAST(... AS ...)`|`CAST('123' AS integer)`|Standard SQL, works in other databases|
|`type 'literal'`|`integer '123'`|Only works with a plain literal, not an expression or column|

**Chaining.** You can cast more than once:

```sql
SELECT '3.7'::numeric::integer;   -- 4 (numeric rounds when cast to integer)
```

Read it left to right: text, then numeric, then integer.

**Precedence tip.** `::` binds very tightly, tighter than math operators:

```sql
SELECT -'5'::integer;     -- -5
SELECT 2 + '3'::integer;  -- 5
SELECT ('2' || '3')::integer;   -- 23  (parentheses needed to cast the whole expression)
SELECT '2' || '3'::integer;     -- '23' (only the 3 is cast, then concatenated)
```

When you want to cast a whole expression, wrap it in parentheses.

---

## 3. Everyday examples

```sql
-- Text to number
SELECT '42'::int + 8;                     -- 50

-- Number to text
SELECT 123::text || ' items';             -- '123 items'

-- Text to date and timestamp
SELECT '2026-11-01'::date;
SELECT '2026-11-01 14:30'::timestamp;

-- Timestamp to date (drops the time part)
SELECT now()::date;                       -- today's date

-- Boolean from text
SELECT 'true'::boolean, 'yes'::boolean, '0'::boolean;   -- t, t, f

-- Numeric rounding
SELECT 10.456::numeric(5,2);              -- 10.46

-- Casting a column
SELECT price::numeric(10,2) FROM products;
SELECT created_at::date FROM orders;      -- group by day

-- Arrays
SELECT '{1,2,3}'::int[];                  -- {1,2,3}

-- JSON
SELECT '{"name":"Ali"}'::jsonb;
```

Here is a small before and after:

|Expression|Result|Result type|
|---|---|---|
|`'42'`|42|text|
|`'42'::int`|42|integer|
|`'42'::int / 5`|8|integer|
|`'42'::numeric / 5`|8.4000000000000000|numeric|
|`now()`|2026-10-25 14:03:11+00|timestamptz|
|`now()::date`|2026-10-25|date|

---

## 4. Real uses you will meet often

**Grouping by day:**

```sql
SELECT created_at::date AS day, count(*)
FROM orders
GROUP BY day
ORDER BY day;
```

Line by line: `created_at::date` throws away the time, so all orders from the same day land in one group.

**Safe division for percentages:**

```sql
SELECT (done::numeric / total) * 100 AS percent FROM tasks;
```

Casting one side to `numeric` makes the whole division non-integer.

**Working with the special types from the last lesson:**

```sql
SELECT ip FROM login_attempts WHERE ip << '203.0.113.0/24'::cidr;
SELECT * FROM bookings WHERE stay @> '2026-11-02'::date;
SELECT to_tsvector('english', body) @@ 'spring'::tsquery FROM articles;
```

**Casting parameters in native queries from Spring Boot:**

```java
@Query(value = "INSERT INTO devices (name, mac) VALUES (:name, CAST(:mac AS macaddr))",
       nativeQuery = true)
```

In a Spring Data native query, use `CAST(:param AS type)`. Writing `:mac::macaddr` can confuse the parser, because the colon is also the named parameter marker. If you do want the short form, write `:mac\:\:macaddr`, or just use `CAST`.

**Casting an enum or a custom type:**

```sql
INSERT INTO tickets (status) VALUES ('open'::ticket_status);
```

---

## 5. What can and cannot be cast

PostgreSQL has three levels of casts:

|Level|Meaning|Example|
|---|---|---|
|**Implicit**|Happens automatically|`int` to `bigint`, `int` to `numeric`|
|**Assignment**|Happens automatically when storing into a column|`numeric` to `int` on `INSERT`|
|**Explicit**|Only when you write `::` or `CAST`|`text` to `int`, `timestamp` to `date`|

Most "text to something" conversions are explicit only. That is exactly why PostgreSQL stops you with an error until you add `::`.

You can see the cast rules yourself:

```sql
SELECT castsource::regtype, casttarget::regtype, castcontext
FROM pg_cast
WHERE castsource = 'text'::regtype;
```

(Here `::regtype` is itself a nice use of casting: it turns an internal type ID into a readable type name.)

---

## 6. Errors you may hit

**1. Invalid text for the target type**

```sql
SELECT 'abc'::integer;
```

```
ERROR: invalid input syntax for type integer: "abc"
```

The text doesn't look like a number. Clean the data first, or filter it:

```sql
SELECT value::int FROM t WHERE value ~ '^\d+$';
```

(`~` is a regular-expression match, and `\d+` means one or more digits.) Be aware that PostgreSQL may still evaluate the cast before the filter in some plans. A `CASE` is safer:

```sql
SELECT CASE WHEN value ~ '^\d+$' THEN value::int END FROM t;
```

PostgreSQL 16 added `pg_input_is_valid('abc', 'integer')` to test this without raising an error.

**2. Value out of range**

```sql
SELECT 3000000000::integer;
```

```
ERROR: integer out of range
```

Use `bigint` instead.

**3. Numeric overflow**

```sql
SELECT 12345.6::numeric(4,2);
```

```
ERROR: numeric field overflow
DETAIL: A field with precision 4, scale 2 must round to an absolute value less than 10^2.
```

`numeric(4,2)` allows only 2 digits before the decimal point.

**4. No cast exists**

```sql
SELECT 'hello'::point;      -- invalid input syntax
SELECT true::date;          -- cannot cast type boolean to date
```

```
ERROR: cannot cast type boolean to date
```

There is no conversion path. You would need a function or a different approach.

**5. Operator does not exist (a cast problem in disguise)**

```sql
SELECT * FROM users WHERE id = 'abc' || 5;
```

```
ERROR: operator does not exist: integer = text
HINT: No operator matches the given name and argument types. You might need to add explicit type casts.
```

The hint is literally telling you to use `::`.

**6. Cast in a `WHERE` kills index use**

```sql
-- Slow: casts every row, so a normal index on created_at can't be used
SELECT * FROM orders WHERE created_at::date = '2026-10-25';

-- Fast: compare the raw column against a range
SELECT * FROM orders
WHERE created_at >= '2026-10-25' AND created_at < '2026-10-26';
```

Casting the column forces PostgreSQL to compute the cast for each row. Prefer casting the _value_ side, not the column side.

**7. Precedence mistakes** (shown in section 2): `'2' || '3'::integer` is not `23` as an integer.

**8. Timezone surprises when casting `timestamptz` to `date`**

```sql
SELECT '2026-10-25 23:30:00+00'::timestamptz::date;
```

The result depends on the session's `TimeZone` setting, so a late-evening UTC moment can land on a different day. Use `AT TIME ZONE` first if the day matters:

```sql
SELECT ('2026-10-25 23:30:00+00'::timestamptz AT TIME ZONE 'UTC')::date;
```

---

## 7. Casting in Spring Boot, in short

|Situation|What to do|
|---|---|
|Native query with a special type (`inet`, `macaddr`, `jsonb`, enums)|`CAST(:param AS type)`|
|JPQL query|Use JPQL's own `CAST(x AS type)` or `function(...)`; `::` is not valid JPQL|
|Plain `String` going into a typed column|Add `CAST`, a proper Hibernate type, or `?stringtype=unspecified` on the JDBC URL|
|Computing a percentage|Cast one side to `numeric` in SQL, or use `BigDecimal` in Java|

`::` only works in real SQL, meaning native queries, SQL scripts, psql, and migrations. It will not work inside JPQL or HQL.

---

## Related concepts, in short

- **`CAST` vs `::`:** same engine behavior. `CAST` is portable to other databases, `::` is shorter.
- **`to_char`, `to_date`, `to_number`, `to_timestamp`:** functions for converting with an explicit _format_ (`to_date('25/10/2026','DD/MM/YYYY')`). Use them when the text isn't in the standard format that `::date` expects.
- **`regclass` / `regtype`:** special types that turn names into internal IDs and back. `'orders'::regclass` finds a table by name, and `pg_total_relation_size('orders'::regclass)` gets its size.
- **`COALESCE`:** often used next to casts to handle `NULL`s: `COALESCE(value::int, 0)`.

---

## Quick cheat sheet

```sql
'42'::int                  -- text to integer
42::text                   -- integer to text
now()::date                -- timestamp to date
7::numeric / 2             -- avoid integer division
'{1,2}'::int[]             -- array
'{"a":1}'::jsonb           -- JSON
'10.0.0.1'::inet           -- IP address
CAST(:p AS inet)           -- inside Spring native queries
```




[[PostgreSQL]]