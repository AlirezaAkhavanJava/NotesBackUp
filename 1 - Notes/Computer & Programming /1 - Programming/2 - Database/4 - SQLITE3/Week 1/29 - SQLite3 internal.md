
Here's your full toolkit of SQLite3 CLI "dot-commands" for poking around inside a database.

## Getting started

```bash
sqlite3 database.db
```

Opens the database in the SQLite3 shell.

## 1. See what databases are attached

```sql
.databases
```

Shows the main database file and any attached ones, with their file paths.

## 2. List all tables

```sql
.tables
```

Lists every table (and view) in the database.

## 3. See a table's schema (structure)

```sql
.schema table_name
```

Shows the exact `CREATE TABLE` statement — columns, types, constraints, primary/foreign keys.

```sql
.schema
```

(no table name) → shows the schema for **everything** in the database — every table, index, trigger, view.

## 4. List columns of a table (compact view)

```sql
.headers on
.mode column
PRAGMA table_info(table_name);
```

`PRAGMA table_info()` returns each column's name, type, whether it's `NOT NULL`, default value, and whether it's part of the primary key (`pk` column: 0 = no, 1+ = position in primary key).

## 5. See foreign keys of a table

```sql
PRAGMA foreign_key_list(table_name);
```

Shows which columns are foreign keys and what they reference.

## 6. See indexes on a table

```sql
PRAGMA index_list(table_name);
```

And to see the columns inside a specific index:

```sql
PRAGMA index_info(index_name);
```

## 7. List all rows in a table

```sql
SELECT * FROM table_name;
```

(Not a dot-command, just plain SQL — but this is how you dump all rows.)

## 8. Row count in a table

```sql
SELECT COUNT(*) FROM table_name;
```

## 9. Formatting output for readability

```sql
.mode column     -- aligned columns
.mode table      -- ASCII table borders (nice for CS50-style output)
.mode csv        -- CSV output
.mode box        -- Unicode box-drawing table
.headers on      -- show column names at top
```

## 10. Check current settings

```sql
.show
```

Displays current CLI settings (mode, headers, separator, etc.)

## 11. See all indexes in the whole database

```sql
.indexes
```

Or for a specific table:

```sql
.indexes table_name
```

## 12. Dump the entire database as SQL

```sql
.dump
```

Outputs the full set of `CREATE TABLE` + `INSERT` statements needed to recreate the database — great for seeing "everything" at once, including data.

## 13. Check if foreign keys are enforced

```sql
PRAGMA foreign_keys;
```

Returns `0` or `1`. Remember, in SQLite3 this defaults to **off** unless you `PRAGMA foreign_keys = ON;`.

## 14. Quit the shell

```sql
.quit
```

or `.exit`

## Cheat sheet: your "explore everything" workflow

```sql
.tables                          -- what tables exist?
.schema table_name                -- what does this table look like?
PRAGMA table_info(table_name);    -- columns in detail
PRAGMA foreign_key_list(table_name); -- relationships out
SELECT * FROM table_name LIMIT 20; -- peek at actual rows
SELECT COUNT(*) FROM table_name;  -- how many rows total?
```




[[1 - WHAT IS SQLITE3 🍕]]