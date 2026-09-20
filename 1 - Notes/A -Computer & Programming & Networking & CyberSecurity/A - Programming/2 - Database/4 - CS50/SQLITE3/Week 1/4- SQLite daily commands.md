For **daily SQLite usage**, you do not need 90% of the shell commands. As a developer, you will mostly use around **15 commands** repeatedly.

Here is the practical workflow.

---

# 1. Start SQLite

From Linux terminal:

```bash
sqlite3 mydatabase.db
```

Example:

```bash
sqlite3 school.db
```

If `school.db` does not exist:

```
SQLite creates it automatically.
```

You are now inside:

```text
sqlite>
```

---

# 2. Check where you are working

## Show current database

```sql
.databases
```

Example:

```
main: /home/alireza/school.db
```

Use this when you forget which database you opened.

---

# 3. See available tables

```sql
.tables
```

Example:

```
students  courses  teachers
```

Think:

```
.tables
     |
     └── "What exists?"
```

---

# 4. Understand a table structure

```sql
.schema table_name
```

Example:

```sql
.schema students
```

Output:

```sql
CREATE TABLE students(
    id INTEGER PRIMARY KEY,
    name TEXT,
    age INTEGER
);
```

Think:

```
.schema
     |
     └── "How was this table created?"
```

---

# 5. Make output readable

By default SQLite output is ugly:

```
1|Alireza|25
2|Bob|30
```

Enable headers:

```sql
.headers on
```

Enable table mode:

```sql
.mode table
```

Now:

```sql
SELECT * FROM students;
```

Output:

```
┌────┬─────────┬─────┐
│ id │ name    │ age │
├────┼─────────┼─────┤
│ 1  │ Alireza │ 25  │
│ 2  │ Bob     │ 30  │
└────┴─────────┴─────┘
```

I recommend running these every time:

```sql
.headers on
.mode table
```

---

# 6. Create a table

This is SQL, not a shell command.

Example:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT
);
```

Check:

```sql
.tables
```

Then:

```sql
.schema users
```

---

# 7. Insert data

```sql
INSERT INTO users(username,email)
VALUES ('alireza','ali@test.com');
```

Check:

```sql
SELECT * FROM users;
```

---

# 8. Read data

Basic:

```sql
SELECT * FROM users;
```

Specific columns:

```sql
SELECT username FROM users;
```

With condition:

```sql
SELECT *
FROM users
WHERE id = 1;
```

---

# 9. Update data

Example:

```sql
UPDATE users
SET username='admin'
WHERE id=1;
```

Always remember:

```sql
WHERE
```

Otherwise:

```sql
UPDATE users
SET username='admin';
```

updates EVERY row.

---

# 10. Delete data

Delete one row:

```sql
DELETE FROM users
WHERE id=1;
```

Delete everything:

```sql
DELETE FROM users;
```

---

# 11. Import SQL files

Very common.

Example:

```
database.sql
```

contains:

```sql
CREATE TABLE users(...);
INSERT INTO users VALUES(...);
```

Run:

```sql
.read database.sql
```

---

# 12. Export database backup

Very important.

```sql
.dump
```

Example output:

```sql
CREATE TABLE users(...);

INSERT INTO users VALUES(...);
```

Save it:

From Linux:

```bash
sqlite3 school.db .dump > backup.sql
```

Restore later:

```bash
sqlite3 new.db < backup.sql
```

---

# 13. Check indexes

```sql
.indexes
```

Example:

```
idx_users_email
```

Specific table:

```sql
.indexes users
```

Useful when learning performance.

---

# 14. Enable foreign keys

SQLite has foreign keys but they are disabled by default in many setups.

Enable:

```sql
PRAGMA foreign_keys = ON;
```

Check:

```sql
PRAGMA foreign_keys;
```

Output:

```
1
```

---

# 15. Measure query speed

Enable timer:

```sql
.timer on
```

Now:

```sql
SELECT * FROM users;
```

Output:

```
Run Time: real 0.002 seconds
```

Disable:

```sql
.timer off
```

---

# 16. See query execution plan

Very useful for optimization.

Enable:

```sql
.eqp on
```

Run:

```sql
SELECT *
FROM users
WHERE email='test@test.com';
```

SQLite shows whether it uses an index.

Disable:

```sql
.eqp off
```

---

# 17. Run commands from a file

Example:

```
setup.sql
```

Run:

```sql
.read setup.sql
```

This is how you automate database creation.

---

# 18. Export query results

Save output:

```sql
.output users.txt

SELECT * FROM users;

.output stdout
```

Now the result is in:

```
users.txt
```

---

# 19. Change databases

Open another database:

```sql
.open another.db
```

Example:

```sql
.open company.db
```

---

# 20. Exit SQLite

```sql
.quit
```

or:

```text
Ctrl + D
```

---

# My daily SQLite workflow

Usually I do this:

```bash
sqlite3 app.db
```

Then:

```sql
.headers on
.mode table

.tables

.schema users

SELECT * FROM users;

.timer on
```

When finished:

```sql
.quit
```

---

# The "developer cheat sheet"

Memorize these:

|Command|Purpose|
|---|---|
|`.tables`|List tables|
|`.schema`|Show table structure|
|`.databases`|Show opened databases|
|`.open file.db`|Open database|
|`.read file.sql`|Run SQL file|
|`.dump`|Backup database|
|`.import`|Import CSV|
|`.headers on`|Show columns|
|`.mode table`|Pretty output|
|`.indexes`|Show indexes|
|`.timer on`|Measure speed|
|`.eqp on`|Query plan|
|`.output file`|Save output|
|`.quit`|Exit|

---

For a **Java developer using SQLite**, the most important ones are:

```
.open
.tables
.schema
.read
.dump
.mode table
.headers on
.timer on
.eqp on
.quit
```

Those are the commands you will actually use almost every day.

[[1 - WHAT IS SQLITE3]]