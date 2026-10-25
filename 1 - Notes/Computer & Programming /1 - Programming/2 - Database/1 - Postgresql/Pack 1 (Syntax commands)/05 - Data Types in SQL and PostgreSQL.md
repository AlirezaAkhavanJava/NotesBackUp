

A **data type** tells PostgreSQL what kind of value a column can hold: a whole number, a piece of text, a date, a true/false flag, and so on. Every column, every function argument, and every expression has one. When you pick the right type, PostgreSQL stores your data compactly, checks it for you, and lets you run the right operations on it.

PostgreSQL has one of the richest type systems of any database. Beyond the usual numbers and text, it has built-in types for JSON, arrays, UUIDs, IP addresses, ranges, and more. You will also see that it is strict. It won't quietly turn `'abc'` into a number, and that strictness saves you from bugs later. Let's walk through the types you will actually use, group by group.

---

## 1. Numeric types

You use these for counting, measuring, and money-like values.

### Whole numbers (integers)

|Type|Size|Range (approx.)|
|---|---|---|
|`smallint`|2 bytes|−32,768 to 32,767|
|`integer` (or `int`)|4 bytes|−2.1 billion to 2.1 billion|
|`bigint`|8 bytes|−9.2 quintillion to 9.2 quintillion|

**Rule of thumb:** use `integer` by default. Use `bigint` when the number could pass 2 billion (like an event log's id). Use `smallint` only when you are sure the value stays small.

### Auto-increment ids

```sql
CREATE TABLE users (
    id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text
);
```

Line by line:

- `integer`: the column holds whole numbers.
- `GENERATED ALWAYS AS IDENTITY`: PostgreSQL fills in 1, 2, 3… for you. You never insert the id yourself.
- `PRIMARY KEY`: the value must be unique and not null.

You may also see `serial` and `bigserial` in older tutorials. They do the same job, but `IDENTITY` is the modern, standard way.

### Exact decimals vs. approximate decimals

This is the most important split in numeric types.

|Type|Behavior|Use it for|
|---|---|---|
|`numeric(p, s)` / `decimal`|**Exact.** No rounding surprises.|Money, prices, anything accounting-related|
|`real`|Approximate, 4 bytes|Scientific data where tiny errors are fine|
|`double precision`|Approximate, 8 bytes|Same, with more precision|

```sql
price numeric(10, 2)
```

- `10` is the **precision**: total digits allowed.
- `2` is the **scale**: digits after the decimal point.
- So this column holds values like `12345678.99`.

Why does this matter? Floating-point types store numbers in binary, and some decimals can't be represented exactly. You may get `0.1 + 0.2 = 0.30000000000000004`. With `numeric`, you get exactly `0.3`. **Never store money in `real` or `double precision`.**

---

## 2. Character (text) types

|Type|What it does|
|---|---|
|`text`|Any length of text. No limit.|
|`varchar(n)`|Text up to `n` characters. Rejects longer values.|
|`char(n)`|Fixed length. Pads short values with spaces.|

In PostgreSQL, `text` and `varchar` perform the same. There's no speed benefit to `varchar(255)`, which is a habit carried over from other databases. Use `text` by default. Use `varchar(n)` only when you truly want the database to enforce a maximum length (like a 2-letter country code). Avoid `char(n)`. The space padding usually causes confusion.

```sql
name         text,
country_code varchar(2)
```

---

## 3. Boolean

```sql
is_active boolean DEFAULT true
```

A `boolean` holds `true`, `false`, or `NULL` (unknown). PostgreSQL accepts `true/false`, `'t'/'f'`, `'yes'/'no'`, and `1/0` as input.

---

## 4. Date and time types

|Type|Stores|Example|
|---|---|---|
|`date`|Just the date|`2026-10-25`|
|`time`|Just the time of day|`14:30:00`|
|`timestamp`|Date + time, **no** time zone|`2026-10-25 14:30:00`|
|`timestamptz`|Date + time, **with** time zone|`2026-10-25 14:30:00+00`|
|`interval`|A span of time|`3 days 4 hours`|

**Use `timestamptz` for almost everything.** Here's why: it stores the moment in UTC and converts it to each user's time zone when displayed. A plain `timestamp` doesn't know where it came from, so two servers in different zones can disagree about what it means.

```sql
created_at timestamptz DEFAULT now()
```

- `DEFAULT now()`: if you don't give a value, PostgreSQL fills in the current time.

Intervals let you do date math:

```sql
SELECT now() + interval '7 days';
```

This returns the moment one week from now.

---

## 5. UUID

A **UUID** is a 128-bit identifier that is practically guaranteed to be unique, even across different databases.

```sql
id uuid DEFAULT gen_random_uuid() PRIMARY KEY
```

- `gen_random_uuid()` is built in (PostgreSQL 13+). Each new row gets a value like `3f2b8c1e-9d4a-4c7e-8b21-5a6f7d9e0c12`.

It's useful when ids are created in several places, or when you don't want users to guess ids by counting (`/orders/1`, `/orders/2`).

---

## 6. JSON types

PostgreSQL can store JSON documents inside a normal column.

|Type|Storage|Notes|
|---|---|---|
|`json`|Stores the exact text|Keeps spacing and key order. Slower to query.|
|`jsonb`|Stores a parsed binary form|**Faster to query, supports indexes.**|

Use `jsonb` almost always.

```sql
CREATE TABLE events (
    id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payload jsonb
);

INSERT INTO events (payload)
VALUES ('{"user": "ana", "tags": ["a", "b"]}');

SELECT payload->>'user' FROM events;
```

- `->>` pulls out a field **as text**. This query returns `ana`.
- `->` pulls out a field **as JSON**.

This is great for flexible, changing data. For data with a stable shape, normal columns are still the better choice.

---

## 7. Arrays

Any type can become an array by adding `[]`.

```sql
tags text[]
```

```sql
INSERT INTO posts (tags) VALUES (ARRAY['java', 'spring']);
SELECT * FROM posts WHERE 'java' = ANY(tags);
```

- `ARRAY[...]` builds an array.
- `ANY(tags)` checks whether the value matches any element.

Arrays are handy for small lists. If the list grows large or you need to query items individually, use a separate table instead.

---

## 8. Enumerated types (`enum`)

An `enum` is a type with a fixed list of allowed values.

```sql
CREATE TYPE order_status AS ENUM ('pending', 'paid', 'shipped');

CREATE TABLE orders (
    id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status order_status DEFAULT 'pending'
);
```

PostgreSQL rejects any value outside the list. The tradeoff: adding values is easy, but removing or renaming them is awkward. If your list changes often, a lookup table is more flexible.

---

## 9. Other useful types

|Type|Purpose|Example|
|---|---|---|
|`bytea`|Raw binary data|A small file or hash|
|`inet` / `cidr`|IP addresses and networks|`192.168.1.10`|
|`macaddr`|MAC addresses|`08:00:2b:01:02:03`|
|`int4range`, `daterange`, …|A range of values|`[2026-01-01, 2026-12-31)`|
|`point`, `polygon`, …|Basic geometry|`(1, 2)`|
|`tsvector`|Full-text search|Searchable document|
|`money`|Currency|Avoid it. Use `numeric` instead.|

---

## 10. Casting: converting between types

Sometimes you need to turn one type into another. There are two ways:

```sql
SELECT '42'::integer;          -- PostgreSQL shorthand
SELECT CAST('42' AS integer);  -- standard SQL
```

Both give you the number `42`. The `::` form is shorter and very common in PostgreSQL code.

---

## 11. NULL: not a type, but it affects every type

`NULL` means "no value / unknown". Any column can hold it unless you add `NOT NULL`. It's different from `0` or an empty string. Comparing with it is also special: `x = NULL` never works, so use `x IS NULL`.

---

## Related concept: constraints (short summary)

A **constraint** is a rule attached to a column, like `NOT NULL`, `UNIQUE`, `CHECK (price > 0)`, or `PRIMARY KEY`. Data types say _what kind_ of value is allowed. Constraints say _which values_ are allowed. You normally use them together.

---

## Quick cheat sheet: which type should you pick?

|You want to store…|Use|
|---|---|
|A normal id or count|`integer` / `bigint`|
|Money or prices|`numeric(10, 2)`|
|Names, descriptions|`text`|
|True/false flags|`boolean`|
|A moment in time|`timestamptz`|
|A unique id across systems|`uuid`|
|Flexible document data|`jsonb`|
|A short list of values|`text[]`|
|A fixed set of options|`enum`|

---

## Putting it all together

```sql
CREATE TABLE products (
    id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       text NOT NULL,
    price      numeric(10, 2) CHECK (price >= 0),
    in_stock   boolean DEFAULT true,
    tags       text[],
    details    jsonb,
    created_at timestamptz DEFAULT now()
);
```

Reading it line by line:

- `id`: an auto-generated whole number that identifies each row.
- `name`: text that can't be empty (`NOT NULL`).
- `price`: an exact decimal that can't be negative.
- `in_stock`: a flag that starts as `true`.
- `tags`: a list of text labels.
- `details`: flexible JSON data.
- `created_at`: the time the row was made, filled in automatically.

---



[[PostgreSQL]]