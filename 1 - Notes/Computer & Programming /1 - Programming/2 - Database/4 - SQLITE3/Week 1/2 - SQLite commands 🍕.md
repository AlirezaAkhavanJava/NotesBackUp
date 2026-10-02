
 If you're learning SQLite properly, you should separate **SQLite shell commands** from **SQL commands**. That's one of the first things to understand.

When you run:

```bash
sqlite3 database.db
```

you enter the **SQLite command-line shell**.

Inside it, there are two different kinds of commands:

```text
SQLite shell commands → start with .
SQL commands          → normal SQL, usually end with ;
```

For example:

```sql
.tables
```

is a **SQLite shell command**, while:

```sql
SELECT * FROM users;
```

is **SQL**.

---

# 1. Starting SQLite

### Open an existing database

```bash
sqlite3 database.db
```

If `database.db` exists, SQLite opens it.

> If it doesn't exist, SQLite will generally **create a new database file**.

Example:

```bash
sqlite3 longlist.db
```

You should see something like:

```text
SQLite version 3.x.x
Enter ".help" for usage hints.
sqlite>
```

You're now inside SQLite.

---

# 2. `.help`

Shows available SQLite shell commands.

```sql
.help
```

You'll see commands such as:

```text
.open
.tables
.schema
.headers
.mode
.import
.dump
.read
.output
.quit
```

This is probably the most important command to remember when you're starting.

---

# 3. `.databases`

Shows the databases currently attached to your SQLite session.

```sql
.databases
```

Example:

```text
main: /home/alireza/database.db
```

`main` is the default database.

---

# 4. `.tables`

Shows all tables in the database.

```sql
.tables
```

Example:

```text
users    orders    products
```

Very useful when you've opened a database and don't know what's inside.

---

# 5. `.schema`

Shows the SQL used to create database objects.

```sql
.schema
```

Example:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT
);
```

You can also inspect one specific table:

```sql
.schema users
```

This is extremely useful.

---

# 6. `.schema` vs `.tables`

Think:

```text
.tables
    ↓
"What tables exist?"

.schema
    ↓
"How are those tables defined?"
```

For example:

```sql
.tables
```

might give:

```text
users
```

Then:

```sql
.schema users
```

might give:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    age INTEGER
);
```

---

# 7. `.headers`

Controls whether column names are displayed.

Turn them on:

```sql
.headers on
```

Turn them off:

```sql
.headers off
```

For example:

```sql
.headers on
SELECT * FROM users;
```

Output:

```text
id  username  age
--  --------  ---
1   alice     25
2   bob       30
```

Without headers:

```text
1|alice|25
2|bob|30
```

---

# 8. `.mode`

Controls how query results are displayed.

This is very useful.

### Default mode

```sql
.mode list
```

Output:

```text
1|alice|25
2|bob|30
```

### Table mode

```sql
.mode table
```

Output:

```text
┌────┬──────────┬─────┐
│ id │ username │ age │
├────┼──────────┼─────┤
│ 1  │ alice    │ 25  │
│ 2  │ bob      │ 30  │
└────┴──────────┴─────┘
```

### Column mode

```sql
.mode column
```

With:

```sql
.headers on
```

you get a nicely aligned result.

### JSON

```sql
.mode json
```

Useful when working with applications/scripts.

---

# 9. `.width`

Controls column widths in column/table output.

Example:

```sql
.width 10 20 10
```

This gives columns widths such as:

```text
id         username             age
---------- -------------------- ----------
1          alireza              25
```

Not something you'll use constantly, but useful when formatting output.

---

# 10. `.nullvalue`

Controls how `NULL` is displayed.

For example:

```sql
.nullvalue NULL
```

Then:

```sql
SELECT NULL;
```

might display:

```text
NULL
```

You could also do:

```sql
.nullvalue [NULL]
```

---

# 11. `.show`

Shows the current SQLite shell configuration.

```sql
.show
```

It can show things such as:

```text
echo: off
headers: on
mode: table
nullvalue: ""
...
```

Very useful if you forgot what settings you've changed.

---

# 12. `.open`

Opens another database.

```sql
.open another.db
```

For example:

```sql
.open school.db
```

Now your SQLite session is working with `school.db`.

You can also create/open a database somewhere else:

```sql
.open /home/alireza/databases/school.db
```

---

# 13. `.cd`

Changes SQLite's current working directory.

```sql
.cd /home/alireza/databases
```

Then:

```sql
.open school.db
```

will refer to:

```text
/home/alireza/databases/school.db
```

---

# 14. `.pwd`

Shows the current working directory.

```sql
.pwd
```

Useful when you're dealing with relative paths.

---

# 15. `.quit`

Exit SQLite.

```sql
.quit
```

You can also use:

```sql
.exit
```

or usually:

```text
Ctrl+D
```

on Linux.

---

# 16. `.read`

Execute SQL commands from a file.

Suppose you have:

```text
setup.sql
```

containing:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT
);

INSERT INTO users (username)
VALUES ('alireza');
```

Inside SQLite:

```sql
.read setup.sql
```

SQLite executes the file.

This is very useful for SQL scripts.

---

# 17. `.dump`

Exports the database as SQL statements.

```sql
.dump
```

You'll get something like:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT
);

INSERT INTO users VALUES(1,'alireza');
INSERT INTO users VALUES(2,'bob');
```

You can dump a specific table:

```sql
.dump users
```

---

# 18. `.dump` from Linux

You can also do this directly from the shell:

```bash
sqlite3 database.db .dump
```

Save it:

```bash
sqlite3 database.db .dump > backup.sql
```

Now:

```text
database.db
     ↓
   .dump
     ↓
 backup.sql
```

And you can reconstruct the database later.

---

# 19. `.import`

Imports data from a file.

For example, suppose:

```text
users.csv
```

contains:

```text
1,alireza
2,bob
3,charlie
```

You can import it.

First configure CSV mode:

```sql
.mode csv
```

Then:

```sql
.import users.csv users
```

This inserts the CSV data into the `users` table.

Be careful: the table structure should already be appropriate for the imported data.

---

# 20. `.output`

Redirects SQLite output to a file.

For example:

```sql
.output result.txt
SELECT * FROM users;
.output stdout
```

Now the query result went into:

```text
result.txt
```

`.output stdout` switches output back to your terminal.

You can also use:

```sql
.output result.sql
.dump
.output stdout
```

---

# 21. `.once`

Similar to `.output`, but only affects the **next command**.

```sql
.once result.txt
SELECT * FROM users;
```

The result is written to `result.txt`, and then SQLite automatically returns to normal terminal output.

Very convenient.

---

# 22. `.print`

Prints text.

```sql
.print Hello SQLite
```

Output:

```text
Hello SQLite
```

Useful inside scripts.

---

# 23. `.timer`

Shows how long SQL commands take.

```sql
.timer on
```

Then:

```sql
SELECT * FROM users;
```

You may see:

```text
Run Time: real 0.001 user 0.000000 sys 0.000000
```

Turn it off:

```sql
.timer off
```

This is useful when you start learning about **query performance and indexes**.

---

# 24. `.eqp`

Controls SQLite's **EXPLAIN QUERY PLAN** output.

For example:

```sql
.eqp on
```

Then:

```sql
SELECT * FROM users WHERE username = 'alireza';
```

SQLite will show information about how it plans to execute the query.

This becomes important when you learn **indexes and query optimization**.

---

# 25. `.indexes`

Shows indexes.

```sql
.indexes
```

For a specific table:

```sql
.indexes users
```

Example:

```text
idx_users_username
```

---

# 26. `.foreignkeys`

Controls SQLite foreign-key enforcement.

```sql
.foreign_keys on
```

You should understand this one carefully.

SQLite supports foreign keys, but foreign-key enforcement is something you should explicitly verify/configure for your connection.

Example:

```sql
.foreign_keys on
```

Check:

```sql
PRAGMA foreign_keys;
```

---

# 27. `.print` + `.read` = useful scripts

You can make a script such as:

```sql
.print Creating database...

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL
);

.print Inserting users...

INSERT INTO users(username)
VALUES ('alireza');

.print Done!
```

Then:

```sql
.read setup.sql
```

This is a nice way to automate database setup.

---

# The SQL commands are separate

Now comes the **important part**.

The commands above are SQLite **shell commands**.

They are not SQL.

You still need to learn SQL itself:

### Create table

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    age INTEGER
);
```

### Insert

```sql
INSERT INTO users (username, age)
VALUES ('alireza', 25);
```

### Select

```sql
SELECT *
FROM users;
```

### Update

```sql
UPDATE users
SET age = 26
WHERE username = 'alireza';
```

### Delete

```sql
DELETE FROM users
WHERE username = 'alireza';
```

### Drop table

```sql
DROP TABLE users;
```

These are **SQL**, not SQLite shell commands.

---

# A normal SQLite workflow

If you're learning SQLite, I'd recommend practicing this exact workflow:

### 1. Create/open database

From Linux:

```bash
sqlite3 school.db
```

### 2. Check the database

```sql
.databases
```

### 3. Check tables

```sql
.tables
```

### 4. Create a table

```sql
CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    age INTEGER
);
```

### 5. Verify it

```sql
.tables
```

Then:

```sql
.schema students
```

### 6. Insert data

```sql
INSERT INTO students (name, age)
VALUES ('Alireza', 25);

INSERT INTO students (name, age)
VALUES ('Bob', 24);
```

### 7. Query it

```sql
.headers on
.mode table

SELECT *
FROM students;
```

You'll get something like:

```text
┌────┬─────────┬─────┐
│ id │  name   │ age │
├────┼─────────┼─────┤
│ 1  │ Alireza │ 25  │
│ 2  │ Bob     │ 24  │
└────┴─────────┴─────┘
```

### 8. Modify data

```sql
UPDATE students
SET age = 26
WHERE name = 'Alireza';
```

### 9. Query again

```sql
SELECT *
FROM students;
```

### 10. Exit

```sql
.quit
```

---

# The commands I recommend memorizing first

Don't try to memorize every `.command`. Start with these:

```text
.help          → SQLite shell help
.databases     → show databases
.tables        → show tables
.schema        → show table definitions
.open FILE     → open database
.headers on    → show column names
.mode table    → pretty table output
.read FILE     → execute SQL file
.dump          → export database as SQL
.import        → import data
.timer on      → show query execution time
.quit          → exit
```

And keep this distinction firmly in your head:

```text
┌──────────────────────────────────────────────┐
│              SQLite CLI                     │
├──────────────────────────────────────────────┤
│ .tables       → SQLite shell command       │
│ .schema       → SQLite shell command       │
│ .mode table   → SQLite shell command       │
│ .dump         → SQLite shell command       │
│ .quit         → SQLite shell command       │
├──────────────────────────────────────────────┤
│              SQL                            │
├──────────────────────────────────────────────┤
│ CREATE TABLE   → SQL                        │
│ INSERT         → SQL                        │
│ SELECT         → SQL                        │
│ UPDATE         → SQL                        │
│ DELETE         → SQL                        │
│ JOIN           → SQL                        │
│ CREATE INDEX   → SQL                        │
│ ALTER TABLE    → SQL                        │
└──────────────────────────────────────────────┘
```

**That distinction is fundamental.** SQLite is the database engine, `sqlite3` is the CLI you can use to operate it, and SQL is the language you use to manipulate the database.


[[1 - WHAT IS SQLITE3 🍕]]