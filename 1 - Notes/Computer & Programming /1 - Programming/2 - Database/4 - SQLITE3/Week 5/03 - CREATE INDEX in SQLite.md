

## Full syntax

```sql
CREATE [UNIQUE] INDEX [IF NOT EXISTS] index_name
ON table_name (column1 [ASC|DESC], column2, ...)
[WHERE condition];
```

## Each component

|Part|Meaning|Required?|
|---|---|---|
|`CREATE INDEX`|The command that builds the index|Yes|
|`UNIQUE`|Rejects duplicate values in the indexed columns|No|
|`IF NOT EXISTS`|Skips creation instead of erroring if the name exists|No|
|`index_name`|Your name for it. Convention: `idx_table_column`|Yes|
|`ON table_name`|Which table the index belongs to|Yes|
|`(column, ...)`|The column(s) to sort by. Order matters in multi-column indexes|Yes|
|`ASC` / `DESC`|Sort direction (default is ASC)|No|
|`WHERE condition`|Makes it a partial index (only matching rows)|No|

## Examples, simplest to most advanced

**1. Basic**

```sql
CREATE INDEX idx_users_city ON users (city);
```

**2. Safe re-run**

```sql
CREATE INDEX IF NOT EXISTS idx_users_city ON users (city);
```

**3. Unique** (also enforces no duplicates)

```sql
CREATE UNIQUE INDEX idx_users_email ON users (email);
```

**4. Composite** (leftmost column first)

```sql
CREATE INDEX idx_users_city_age ON users (city, age);
```

**5. Sort direction**

```sql
CREATE INDEX idx_users_age_desc ON users (age DESC);
```

**6. Partial** (only active users)

```sql
CREATE INDEX idx_users_active_email ON users (email) WHERE active = 1;
```

**7. Expression** (index a calculation)

```sql
CREATE INDEX idx_users_lower_email ON users (LOWER(email));
```

## What happens when you run it

1. SQLite reads every row in the table.
2. It sorts the key values and builds the B-tree.
3. It saves the index in the database file.
4. From then on, every `INSERT`, `UPDATE`, and `DELETE` also updates the index.

On a large table, step 1 and 2 can take noticeable time, because the index is built once, up front.

## Manage indexes

```sql
DROP INDEX idx_users_city;                  -- delete it
DROP INDEX IF EXISTS idx_users_city;        -- delete safely
REINDEX idx_users_city;                     -- rebuild it
PRAGMA index_list('users');                 -- list a table's indexes
PRAGMA index_info('idx_users_city_age');    -- show an index's columns
```

> SQLite has no `ALTER INDEX`. To change an index, **drop it and create it again**.

## Common errors

|Error|Cause|Fix|
|---|---|---|
|`index idx_users_city already exists`|Name is taken|Use `IF NOT EXISTS` or choose a new name|
|`no such table: users`|Wrong or misspelled table|Check the table name|
|`no such column: cty`|Misspelled column|Check the column name|
|`UNIQUE constraint failed`|Duplicates already exist while creating a `UNIQUE` index|Clean the duplicates first|
|`near "CRAETE": syntax error`|Typo in the keyword|Spell it `CREATE`|

## Always verify

```sql
CREATE INDEX idx_users_city ON users (city);

EXPLAIN QUERY PLAN
SELECT * FROM users WHERE city = 'London';
-- Expect: SEARCH users USING INDEX idx_users_city (city=?)
```

If you still see `SCAN users`, the index isn't being used, so revisit the common mistakes from the previous lesson.

## Try it

Create an index on `users(age)`, then run `EXPLAIN QUERY PLAN` on `SELECT * FROM users WHERE age = 30;`. Paste the output here and I'll tell you what it means.


[[SQlite]]