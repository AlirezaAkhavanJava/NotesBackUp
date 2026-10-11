
`DESCRIBE` is the command you'll reach for most when you meet a table you didn't build, or one you built a week ago and half forgot. It answers one question: "what does this table look like?"

## The basics

```sql
DESCRIBE users;
```

Short forms work too, and they're all identical:

```sql
DESC users;
EXPLAIN users;
SHOW COLUMNS FROM users;
```

(`EXPLAIN` is also used for something very different, analyzing how a query runs, but when you give it a plain table name it behaves like `DESCRIBE`.)

## Reading the output

![[Pasted image 20261011134627.png]]

Each column of that output is answering something you already know from earlier lessons:

- **Field** is the column name.
- **Type** is the data type, including the length or precision, like `varchar(100)` or `decimal(10,2)`.
- **Null** says whether the column may be empty. `NO` means it's `NOT NULL`.
- **Key** shows the column's role in an index:
    - `PRI` means primary key.
    - `UNI` means it has a unique constraint.
    - `MUL` means it's indexed but can hold duplicates. This is what you'll usually see on a foreign key column.
- **Default** is the value used when you don't supply one. A literal `NULL` here means "the default is NULL", not "there's no default", which trips people up.
- **Extra** holds special behavior, such as `auto_increment`.

## Looking at just one column

You can add a column name, or even a pattern:

```sql
DESCRIBE users email;
DESCRIBE users 'e%';     -- columns whose names start with e
```

## What DESCRIBE doesn't show

It's a quick summary, so some things are left out. It won't show `CHECK` constraints, foreign key details (which table they point to, or the `ON DELETE` rule), or the storage engine and character set. For the complete picture, use:

```sql
SHOW CREATE TABLE orders\G
```

That prints the exact statement that would rebuild the table, with every constraint included. A good habit is `DESCRIBE` for a quick look, and `SHOW CREATE TABLE` when you need the full truth. Adding `\G` at the end makes the long output easier to read.

A related command, `SHOW INDEX FROM users;`, lists every index in detail.

## Describing something that isn't in the current database

You don't have to `USE` a database first. Prefix the table name with the database name:

```sql
DESCRIBE my_database.users;
```

## Describing a query's result

You can also ask `DESCRIBE` about a `SELECT`, but then it means something else. It shows how MariaDB plans to run the query:

```sql
EXPLAIN SELECT * FROM users WHERE email = 'sara@example.com';
```

That's the start of query tuning, and you can leave it for much later. For now, just remember that `DESCRIBE tablename` is the structure lookup, and `EXPLAIN SELECT ...` is the query analyzer, even though they share a keyword.

## Where it fits in your routine

When you open an unfamiliar database, this sequence tells you almost everything:

```sql
SHOW DATABASES;
USE my_database;
SHOW TABLES;
DESCRIBE users;
```

And before you write an `INSERT`, a quick `DESCRIBE` tells you which columns are required (`Null = NO` with no default), which are filled in automatically (`auto_increment`), and what types your values must match.


[[MySQL]]