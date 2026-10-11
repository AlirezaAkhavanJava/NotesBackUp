
Inside the `mariadb` shell, you're typing two different kinds of things, and knowing which is which clears up a lot of confusion.

1. **SQL statements** such as `SELECT`, `LOAD DATA`, and `CREATE TABLE`. These are sent to the database server, which does the work. They end with `;`.
2. **Client commands** such as `SOURCE`, `USE`, `system`, and `\G`. These are handled by the shell program itself, and the server never sees them. Many have short backslash forms that don't need a semicolon.

It's a bit like a Linux terminal, where `cd` is handled by the shell itself but `grep` is a separate program. The analogy bends because MariaDB's client is forgiving: it accepts a trailing `;` on most client commands, so you don't have to memorize which is which. It does matter for one thing, though. Client commands run on **your machine**, while SQL statements run on the **server**. That difference explains most of the odd behavior around files.

---
## Running an SQL file

```sql
SOURCE /home/alireza/setup.sql;
```

The short form does the same thing:

```sql
\. /home/alireza/setup.sql
```

`SOURCE` reads the file and runs each statement in order, as if you had typed them. Because it's a client command, the path is on your machine, and relative paths work from the folder where you launched the shell. If a statement fails, execution stops at that point, and everything before it has already run.

You can also run a file from outside the shell:

```bash
sudo mariadb my_database < setup.sql
```

---
## Importing a CSV

Suppose you have `users.csv`:

```
name,email
Sara,sara@example.com
Omid,omid@example.com
```

First, the table has to exist, because MariaDB never creates one for you from a file:

```sql
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE
);
```

Then load the file:

```sql
LOAD DATA LOCAL INFILE '/home/alireza/users.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(name, email);
```

Here is what each line is telling MariaDB:

- **`LOCAL`** means the file is on your machine and the client should send it up. Without it, the _server_ process tries to read the file itself. That process runs as a different Linux user and usually can't see your home folder.
- **`INTO TABLE users`** is the destination.
- **`FIELDS TERMINATED BY ','`** is the character that separates columns.
- **`OPTIONALLY ENCLOSED BY '"'`** handles values like `"Tehran, Iran"`, where a comma sits inside quotes and shouldn't split the column.
- **`LINES TERMINATED BY '\n'`** marks where a row ends. A file made on Windows usually needs `'\r\n'`.
- **`IGNORE 1 LINES`** skips the header row.
- **`(name, email)`** maps the CSV's columns, in order, to table columns. Columns you leave out, like `id`, get their normal defaults, so `AUTO_INCREMENT` keeps working.

Because the types and constraints you defined are enforced, a row that breaks a rule (say, a duplicate email) stops the whole load with an error. If you'd rather skip bad rows and keep going, add `IGNORE` before `INTO TABLE`:

```sql
LOAD DATA LOCAL INFILE '/home/alireza/users.csv'
IGNORE INTO TABLE users
...
```

Then see what was skipped and why:

```sql
SHOW WARNINGS;
SELECT COUNT(*) FROM users;
```

Always run that count afterward. It's a quick check that the number of rows matches what you expected.

### Cleaning values while loading

You can load a column into a temporary variable (written with `@`) and transform it with `SET`:

```sql
LOAD DATA LOCAL INFILE '/home/alireza/users.csv'
INTO TABLE users
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
IGNORE 1 LINES
(name, @email)
SET email = LOWER(TRIM(@email));
```

This is useful when the CSV has messy spacing or capital letters. You can also use it to skip a CSV column you don't want: load it into a variable and simply never use it.

### If `LOCAL INFILE` is refused

Some setups disable it for security, since it lets a server ask a client to send files. If you get an error about it, start the shell with the option on:

```bash
sudo mariadb --local-infile=1 my_database
```

If it still complains, enable it on the server too from inside the shell:

```sql
SET GLOBAL local_infile = 1;
```

Only do this on databases you trust.

---
## Exporting to a CSV

The reverse operation is `SELECT ... INTO OUTFILE`:

```sql
SELECT name, email FROM users
INTO OUTFILE '/tmp/users_export.csv'
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n';
```

This is where the client/server split shows up again. The **server** writes this file, so:

- It must go in a folder the server's Linux user can write to, like `/tmp`. Your home folder usually won't work.
- It refuses to overwrite a file that already exists, so use a new name each time.
- There's no `LOCAL` version for exports.
- It doesn't write a header row.

If you want a header, you can glue one on with `UNION ALL`:

```sql
SELECT 'name', 'email'
UNION ALL
SELECT name, email FROM users
INTO OUTFILE '/tmp/users_with_header.csv'
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n';
```

---
## Saving what you see on screen

The `tee` command copies everything displayed in the shell into a file, until you turn it off:

```sql
tee /home/alireza/session.txt
SELECT * FROM users;
notee
```

This is a client command, so it writes on your machine, with no permission problems. It saves the formatted table exactly as shown, not CSV, so it's best for keeping a record of a session or pasting results into notes.

---
## Looking around

```sql
SHOW DATABASES;
USE my_database;
SELECT DATABASE();
SHOW TABLES;
DESCRIBE users;
SHOW CREATE TABLE users;
SHOW INDEX FROM users;
```

`SHOW CREATE TABLE` is especially valuable because it prints the exact statement that would rebuild the table, constraints and all.

---
## Running Linux commands without leaving

```sql
system ls /home/alireza
\! pwd
```

Use this to confirm your CSV is where you think it is, before you spend time debugging a load error that turns out to be a typo in the path.

## Other client commands worth knowing

```
\G      end a query with this instead of ; for vertical output
\c      cancel the statement you're in the middle of typing
\s      show connection and server status
\u db   switch database (same as USE)
\q      quit (exit and quit also work)
\h      help
```

`\G` deserves special mention. When a table has many columns, normal output wraps into an unreadable mess. This fixes it:

```sql
SELECT * FROM users WHERE id = 1\G
```

Each column prints on its own line, one row after another.

---
## A practice loop

The best way to make this stick is one full round trip:

1. Create a small table with `CREATE TABLE`.
2. Write a three-line CSV in a text editor.
3. Load it with `LOAD DATA LOCAL INFILE`.
4. Check it with `SELECT * FROM ...;` and `SELECT COUNT(*) ...;`.
5. Export it to `/tmp` with `INTO OUTFILE`.
6. Look at the result with `\! cat /tmp/your_file.csv`.

Once you've done that loop a couple of times, the long `LOAD DATA` syntax stops feeling long, because every clause is answering a question you already know to ask: where is the file, how are columns separated, how are rows separated, is there a header, and which columns does it fill.


[[MySQL]]