


In PostgreSQL, the word **comment** means two different things, and it helps to know both. The main one is the `COMMENT ON` command, which attaches a piece of documentation to a database object (a table, a column, an index, and so on) and stores it _inside the database itself_. The second is the humble **code comment** (`--` and `/* */`), which is just a note in your SQL text that PostgreSQL ignores.

Think of it as the difference between a sticky note stuck to a file in the cabinet (`COMMENT ON`, it stays with the thing) and a note scribbled in the margin of a script (a code comment, it only exists where you wrote it). Let's start with the more interesting one.

## Why bother documenting inside the database?

Six months from now, you open a table and find a column called `status` with values like `3`. Or `amount` with no hint whether it's dollars or cents. Or `ref_code`, which nobody remembers. The _meaning_ of data usually lives in people's heads or an old wiki page, and those drift away.

`COMMENT ON` fixes this by putting the explanation right next to the object. Anyone who connects to the database, with any tool, can read it.

## Writing comments with `COMMENT ON`

The pattern is always `COMMENT ON <object type> <name> IS '<text>'`:

```sql
COMMENT ON TABLE customers IS 'One row per registered customer, including deactivated ones.';

COMMENT ON COLUMN customers.phone IS 'Phone number in E.164 format, e.g. +14155550123.';

COMMENT ON COLUMN orders.total_cents IS 'Order total in cents (integer) to avoid rounding errors.';

COMMENT ON INDEX idx_customers_email_lower IS 'Supports case-insensitive email lookups at login.';
```

Many object types can carry comments: tables, columns, views, indexes, constraints, schemas, functions, sequences, types, and even the database itself.

```sql
COMMENT ON CONSTRAINT customers_email_key ON customers IS 'Emails must be unique across all customers.';
COMMENT ON SCHEMA billing IS 'Everything related to invoices and payments.';
```

A few small rules to remember:

- **Apostrophes need doubling**, like any SQL string: `'The customer''s primary phone'`.
- **To remove a comment**, set it to `NULL`: `COMMENT ON TABLE customers IS NULL;`
- **Only the owner** of an object (or a superuser) can comment on it.
- Setting a comment again simply **replaces** the old one.

## Reading comments back

In `psql`, the `+` versions of the describe commands show comments:

```
\d+ customers     -- columns, with a "Description" column
\dt+              -- all tables, with their comments
```

You can also read them with plain SQL, which is handy for generating documentation:

```sql
SELECT obj_description('customers'::regclass, 'pg_class') AS table_comment;

SELECT a.attname AS column_name,
       col_description(a.attrelid, a.attnum) AS comment
FROM pg_attribute a
WHERE a.attrelid = 'customers'::regclass
  AND a.attnum > 0
  AND NOT a.attisdropped;
```

Under the hood, comments live in a system catalog called `pg_description` (or `pg_shdescription` for objects shared across the whole cluster, like databases and roles). You rarely query it directly, since the helper functions above are friendlier.

## How comments behave over time

- They **travel with backups**: `pg_dump` includes them, so a restored database keeps its documentation.
- They **survive renames**: rename a column and its comment follows.
- They **die with the object**: drop and recreate a table, and the comment is gone unless you re-add it.
- They're **transactional**, like other PostgreSQL schema changes. A `COMMENT ON` inside a transaction is undone if you roll back.

That third point connects to our last lesson: the best place for `COMMENT ON` statements is **inside your migration files**, right beside the `CREATE TABLE` they describe:

```sql
-- V5__create_invoices.sql
CREATE TABLE invoices (
    id          BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id),
    amount_cents BIGINT NOT NULL
);

COMMENT ON TABLE invoices IS 'Bills issued to customers; one row per invoice.';
COMMENT ON COLUMN invoices.amount_cents IS 'Invoice total in cents.';
```

## The other kind: code comments

These are notes in your SQL text. PostgreSQL discards them when it runs the statement, and they are **not** stored anywhere in the database.

```sql
-- This is a single-line comment; it runs to the end of the line.

/* This is a block comment.
   It can span several lines. */

SELECT id, name   -- inline note after code
FROM customers
WHERE active = true;  /* only active customers */
```

PostgreSQL also allows block comments to be **nested**, which is handy when you want to temporarily disable a chunk of code that already contains comments:

```sql
/* disabled for now
   SELECT * FROM old_table; /* legacy query */
*/
```

## Which one should you use?

||Code comment (`--`, `/* */`)|`COMMENT ON`|
|---|---|---|
|Stored in the database|No|Yes|
|Visible to anyone connecting|No|Yes (`\d+`, catalog queries)|
|Best for|Explaining _why_ a query or script is written a certain way|Explaining _what_ an object means|
|Survives a restore|Only if the script file does|Yes|

A good rule of thumb: use **`COMMENT ON` for meaning** (what is this table, what unit is this column) and **code comments for reasoning** (why does this migration do the update before adding the constraint).

## Habits worth keeping

- Comment the things that _aren't obvious from the name_: units, formats, allowed values, and business rules.
- Keep comments short and factual. One or two sentences is plenty.
- Don't restate the obvious: `COMMENT ON COLUMN customers.name IS 'The name'` adds nothing.
- Update comments when the meaning changes, because an outdated comment is worse than none.

## Quick recap

`COMMENT ON` stores documentation inside PostgreSQL, attached to tables, columns, indexes, and more, readable with `\d+` or catalog functions, and it travels with your backups. Code comments (`--` and `/* */`) are just notes in your scripts that PostgreSQL ignores. Use both, each for its own job.




[[PostgreSQL]]