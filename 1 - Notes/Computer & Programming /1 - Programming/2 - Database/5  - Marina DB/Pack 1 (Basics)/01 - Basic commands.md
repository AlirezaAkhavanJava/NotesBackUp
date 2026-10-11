

Most of what you'll do in MariaDB falls into three groups: **looking around**, **shaping your data** (tables), and **working with the data itself**. Let's go through them in that order.

A handy mental picture is that a database is like a folder, and each table inside is like a spreadsheet. That's a good starting point, but it breaks down quickly: tables can be linked to each other, and MariaDB enforces rules on what each column may contain, which a spreadsheet never does.

## Looking around

These commands answer "where am I and what's here?"

```sql
SHOW DATABASES;              -- list all databases
USE my_database;             -- switch to one
SELECT DATABASE();           -- which one am I in right now?
SHOW TABLES;                 -- list tables in the current database
DESCRIBE users;              -- show a table's columns and types (DESC works too)
SHOW CREATE TABLE users;     -- show the exact statement that would recreate it
```

`DESCRIBE` is the one you'll use constantly. It shows each column's name, type, whether it can be empty, and whether it's a key.

To leave the shell, type `exit` (or `quit`, or press Ctrl+D).

## Shaping your data: tables

```sql
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

Let's unpack the pieces, because each one is a rule MariaDB will enforce for you:

- `AUTO_INCREMENT` makes MariaDB hand out 1, 2, 3... for you.
- `PRIMARY KEY` means each row is uniquely identifiable by that column.
- `NOT NULL` means the column can't be left empty.
- `UNIQUE` means no two rows can share that value.
- `DEFAULT` fills in a value when you don't provide one.

Changing a table later uses `ALTER`:

```sql
ALTER TABLE users ADD COLUMN age INT;          -- add a column
ALTER TABLE users DROP COLUMN age;             -- remove a column
ALTER TABLE users MODIFY name VARCHAR(200);    -- change a column's type
```

And removing things entirely:

```sql
DROP TABLE users;                  -- deletes the table AND all its data
DROP DATABASE my_database;         -- deletes the whole database
```

Be careful with `DROP`. There's no recycle bin and no "are you sure?" prompt. It's gone the moment you press Enter.

## Working with the data: the four everyday operations

Developers call these **CRUD**: Create, Read, Update, Delete.

**Create (INSERT)**

```sql
INSERT INTO users (name, email)
VALUES ('Alireza', 'ali@example.com');

-- several rows at once
INSERT INTO users (name, email) VALUES
  ('Sara', 'sara@example.com'),
  ('Omid', 'omid@example.com');
```

Notice we didn't mention `id` or `created_at`. MariaDB filled those in using the rules we set up earlier.

**Read (SELECT)**

```sql
SELECT * FROM users;                          -- everything
SELECT name, email FROM users;                -- only some columns
SELECT * FROM users WHERE name = 'Sara';      -- filter rows
SELECT * FROM users ORDER BY created_at DESC; -- sort, newest first
SELECT * FROM users LIMIT 5;                  -- only the first 5
SELECT COUNT(*) FROM users;                   -- how many rows?
```

`SELECT` is the most flexible command in SQL, and you'll keep discovering new things you can do with it for years. The `WHERE` clause is the part to get comfortable with first.

**Update**

```sql
UPDATE users SET email = 'new@example.com' WHERE id = 1;
```

**Delete**

```sql
DELETE FROM users WHERE id = 1;
```

Here's the single most important habit in this whole lesson: **always include a `WHERE` on `UPDATE` and `DELETE`.** Without one, the command applies to _every row in the table_. `DELETE FROM users;` empties the whole table instantly. A good routine is to write the same condition in a `SELECT` first, check that it returns exactly the rows you expect, and only then change `SELECT *` into `DELETE`.

## Running SQL from a file

When your commands start getting long, save them in a `.sql` file and run them from inside the shell:

```sql
SOURCE /home/alireza/setup.sql;
```

Or straight from your terminal, without opening the shell first:

```bash
sudo mariadb my_database < setup.sql
```

## Users and permissions (a preview)

```sql
SELECT USER();                                             -- who am I logged in as?
CREATE USER 'app'@'localhost' IDENTIFIED BY 'secret123';
GRANT ALL PRIVILEGES ON my_database.* TO 'app'@'localhost';
FLUSH PRIVILEGES;
```

This is the dedicated-user setup that your Spring Boot app will eventually connect with, instead of using root.

## Small things that save you frustration

- Statements end with `;`. If you see a `->` prompt, MariaDB is waiting for you to finish. Type `;` and press Enter, or type `\c` to cancel what you've typed.
- Text values go in single quotes (`'Sara'`), but column and table names don't.
- Press the up arrow to bring back previous commands. The shell remembers your history.
- `HELP;` shows built-in help, and `HELP SELECT;` explains a specific command.

If you practice just the CRUD four plus `SHOW`, `USE`, and `DESCRIBE`, you'll cover probably 90% of what you do day to day. 



[[MySQL]]
