If you want the **complete SQLite command-line shell (`sqlite3`) command set**, here it is. These are **dot-commands**, not SQL statements.

> **Important:** The exact list can vary slightly with your installed SQLite version. You can always get the authoritative list for your installation with `.help`.

# SQLite3 Shell Commands — Complete Reference

## 1. Help & information

|Command|Purpose|
|---|---|
|`.help`|Show all available shell commands|
|`.help PATTERN`|Show help matching a pattern|
|`.show`|Show current shell settings|
|`.version`|Show SQLite version information|

Examples:

```text
.help
.help .schema
.show
.version
```

---

# 2. Database management

### `.open`

Open a database.

```text
.open database.db
```

You can also open/create a database from the Linux shell:

```bash
sqlite3 database.db
```

---

### `.databases`

Show databases attached to the current connection.

```text
.databases
```

Example:

```text
main: /home/alireza/database.db
```

---

### `.dbinfo`

Show information about the database file.

```text
.dbinfo
```

You can also specify a schema:

```text
.dbinfo main
```

---

### `.backup`

Backup a database.

```text
.backup backup.db
```

Or:

```text
.backup main backup.db
```

This performs a SQLite-aware backup rather than simply copying the file.

---

### `.restore`

Restore a database from a backup.

```text
.restore backup.db
```

Or:

```text
.restore main backup.db
```

---

### `.clone`

Clone the current database into another database.

```text
.clone new_database.db
```

---

### `.save`

Save the current database to a file.

```text
.save database.db
```

---

# 3. Inspecting database structure

### `.tables`

List tables.

```text
.tables
```

You can use a pattern:

```text
.tables user*
```

---

### `.schema`

Show the SQL schema.

```text
.schema
```

Specific table:

```text
.schema users
```

Pattern:

```text
.schema user*
```

---

### `.fullschema`

Show the complete schema, including statistics.

```text
.fullschema
```

This is more comprehensive than `.schema`.

---

### `.indexes`

Show indexes.

```text
.indexes
```

Specific table:

```text
.indexes users
```

---

### `.vfsinfo`

Show information about the active VFS.

```text
.vfsinfo
```

---

### `.filectrl`

Run SQLite file-control operations.

```text
.filectrl
```

This is mainly an advanced/debugging command.

---

### `.dbconfig`

View or change SQLite database configuration options.

```text
.dbconfig
```

For example, depending on SQLite version:

```text
.dbconfig defensive
```

---

# 4. Query output formatting

These commands don't change your database. They change **how SQLite displays results**.

## `.headers`

Turn column headers on/off.

```text
.headers on
```

```text
.headers off
```

---

## `.mode`

Change output format.

```text
.mode MODE
```

Common modes include:

```text
.mode ascii
.mode box
.mode csv
.mode column
.mode html
.mode insert
.mode json
.mode line
.mode list
.mode markdown
.mode quote
.mode table
.mode tabs
.mode tcl
```

For example:

```text
.mode table
.headers on
```

Then:

```sql
SELECT * FROM users;
```

gives a table-like output.

---

## `.width`

Set column widths.

```text
.width 10 20 15
```

Useful with:

```text
.mode column
```

---

## `.separator`

Change column/row separators.

```text
.separator |
```

For example:

```text
.separator ","
```

You can configure column and row separators separately on versions that support the extended syntax.

---

## `.nullvalue`

Choose how `NULL` is displayed.

```text
.nullvalue NULL
```

For example:

```text
.nullvalue [NULL]
```

---

## `.linemode`

Enable line-oriented output.

```text
.linemode
```

This is essentially a convenient way to configure line-style output.

---

## `.eqp`

Control automatic `EXPLAIN QUERY PLAN`.

```text
.eqp on
```

```text
.eqp off
```

```text
.eqp full
```

```text
.eqp trace
```

Very useful when you're learning query optimization.

---

## `.explain`

Control formatting of `EXPLAIN` output.

```text
.explain on
```

```text
.explain off
```

```text
.explain auto
```

---

# 5. Executing SQL/scripts

## `.read`

Read and execute SQL commands from a file.

```text
.read setup.sql
```

Example `setup.sql`:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT
);

INSERT INTO users(username)
VALUES ('alireza');
```

Then:

```text
.read setup.sql
```

---

## `.once`

Send the output of the **next command only** to a file.

```text
.once result.txt
SELECT * FROM users;
```

After that command, output returns to the terminal.

---

## `.output`

Redirect output to a file.

```text
.output result.txt
```

Then:

```sql
SELECT * FROM users;
```

Return output to terminal:

```text
.output stdout
```

---

## `.print`

Print text.

```text
.print Hello SQLite
```

---

## `.echo`

Show commands before executing them.

```text
.echo on
```

Disable:

```text
.echo off
```

Useful for SQL scripts.

---

## `.cmd`

Run a dot-command from another command context.

This is an advanced shell feature and isn't something you'll normally need.

---

# 6. Import/export

## `.dump`

Export database contents as SQL.

```text
.dump
```

Specific table:

```text
.dump users
```

Save it:

```bash
sqlite3 database.db .dump > backup.sql
```

---

## `.import`

Import data from a file.

```text
.import file.csv users
```

For CSV:

```text
.mode csv
.import users.csv users
```

Modern SQLite versions also have options for controlling import behavior.

---

## `.excel`

Write the next query's output to a temporary CSV file and open it with the system's spreadsheet application when supported by the environment.

```text
.excel
```

---

## `.www`

Write the next query's output to a temporary HTML file and open it in the default web browser.

```text
.www
```

Availability/behavior can depend on the platform.

---

# 7. Query execution & debugging

## `.timer`

Show execution time.

```text
.timer on
```

Then:

```sql
SELECT * FROM users;
```

Disable:

```text
.timer off
```

---

## `.progress`

Configure progress callbacks for long-running queries.

```text
.progress N
```

For example:

```text
.progress 1000
```

Disable:

```text
.progress 0
```

This is mostly useful for monitoring expensive operations.

---

## `.limit`

View or change SQLite limits for the current connection.

```text
.limit
```

You can inspect a particular limit:

```text
.limit length
```

And set one:

```text
.limit length 1000000
```

---

## `.trace`

Trace SQL statements being executed.

```text
.trace stdout
```

Turn it off:

```text
.trace off
```

This is useful for debugging applications/scripts.

---

## `.expert`

Ask SQLite's query planner advisor for index recommendations.

```text
.expert
```

Then:

```sql
SELECT *
FROM users
WHERE username = 'alireza';
```

This is an **advanced but extremely useful** command when learning indexes.

---

# 8. History & command-line editing

## `.history`

Show command history.

```text
.history
```

Depending on the build/platform, history can also be saved to a file:

```text
.history history.txt
```

---

## `.shell`

Execute an operating-system shell command.

On Linux:

```text
.shell ls
```

or:

```text
.shell pwd
```

You can use:

```text
.shell ls -lah
```

This executes the command through the OS shell.

You can also commonly use:

```text
.system ls
```

`.shell` is generally the more useful/standard form to remember.

---

# 9. File-system navigation

## `.cd`

Change the SQLite shell's working directory.

```text
.cd /home/alireza/databases
```

---

## `.pwd`

Print the current working directory.

```text
.pwd
```

---

# 10. Foreign keys & database configuration

## `.connection`

Manage additional database connections in the CLI.

```text
.connection
```

This is mainly useful for advanced shell usage and testing.

---

## `.load`

Load a SQLite extension.

```text
.load extension
```

For example:

```text
.load ./my_extension
```

This allows additional functionality to be loaded into SQLite.

---

# 11. Parameter / variable commands

## `.parameter`

Manage SQL parameters in the SQLite shell.

```text
.parameter
```

Initialize the parameter table:

```text
.parameter init
```

Set a parameter:

```text
.parameter set :name 'Alireza'
```

Then:

```sql
SELECT :name;
```

List parameters:

```text
.parameter list
```

Clear them:

```text
.parameter clear
```

This is particularly useful when experimenting with parameterized SQL directly in the CLI.

---

# 12. Environment / shell configuration

## `.bail`

Stop after an error.

```text
.bail on
```

Without it, the shell may continue executing subsequent commands after an error.

Disable:

```text
.bail off
```

---

## `.changes`

Show the number of rows changed by SQL statements.

```text
.changes on
```

Example:

```sql
UPDATE users
SET age = 26
WHERE id = 1;
```

SQLite can report:

```text
changes: 1
```

---

## `.count`

Show row counts for query results.

```text
.count on
```

Disable:

```text
.count off
```

---

## `.stats`

Show SQLite memory/performance statistics.

```text
.stats on
```

or:

```text
.stats off
```

You can also request specific statistics depending on your SQLite version.

---

## `.scanstats`

Show scan statistics.

```text
.scanstats on
```

Disable:

```text
.scanstats off
```

This can be useful when studying query performance.

---

## `.limits`

There is **not** a separate `.limits` command in modern SQLite shells; the relevant shell command is:

```text
.limit
```

This is worth noting because you'll find old/third-party command lists online.

---

# 13. Output modes for programmers

Some particularly useful formats:

### CSV

```text
.mode csv
```

```text
SELECT * FROM users;
```

Output:

```text
1,Alireza,25
2,Bob,30
```

### JSON

```text
.mode json
```

Output:

```json
[
  {"id":1,"username":"Alireza","age":25},
  {"id":2,"username":"Bob","age":30}
]
```

### Markdown

```text
.mode markdown
```

Useful for documentation/README files.

### HTML

```text
.mode html
```

Useful if you need query results embedded into HTML.

### Insert

```text
.mode insert
```

This produces SQL `INSERT` statements from query results.

---

# 14. Advanced/diagnostic commands

These aren't commands you need every day, but they're part of the shell.

|Command|Purpose|
|---|---|
|`.archive`|Manage SQLite Archive files|
|`.auth`|Authorization callbacks/debugging|
|`.crnl`|Control CR/LF behavior|
|`.filectrl`|Execute file-control operations|
|`.imposter`|Create an imposter table for an index|
|`.lint`|Analyze database for potential issues|
|`.log`|Configure logging|
|`.memtrace`|Memory allocation tracing|
|`.mmap`|Configure memory-mapped I/O|
|`.nonce`|Set nonce used by defensive features|
|`.oom`|Configure out-of-memory simulation/testing|
|`.optimize`|Run SQLite optimization|
|`.selftest`|Run database self-tests|
|`.sha3sum`|Calculate SHA3 hashes of database contents|
|`.testcase`|Start a test case|
|`.testctrl`|Execute SQLite test-control operations|
|`.vfsinfo`|Display VFS information|
|`.vfslist`|List available VFS implementations|
|`.vfsname`|Show current VFS name|
|`.zipfile`|Work with ZIP/SQLite archive functionality where supported|

Some of these are primarily intended for **SQLite developers, testing, debugging, or specialized workflows**, rather than normal database usage.

---

# 15. Exiting SQLite

### `.quit`

```text
.quit
```

### `.exit`

```text
.exit
```

On Linux you can also normally use:

```text
Ctrl+D
```

---

# The commands I'd actually memorize

You **do not need to memorize the entire list**. As a developer, I'd memorize these first:

```text
.help
.version

.open
.databases
.tables
.schema
.fullschema
.indexes

.headers
.mode
.width
.nullvalue
.separator

.read
.dump
.import
.output
.once

.timer
.eqp
.explain
.expert
.stats

.parameter

.cd
.pwd
.shell

.bail
.changes
.count

.quit
```

And whenever you forget something:

```text
.help
```

That's the **real master command**.

---

## One important correction from the previous answer

The SQLite shell command list is **version-dependent**. So if your goal is a _literally complete list for the SQLite3 binary installed on your Debian machine_, run:

```bash
sqlite3 --version
```

then:

```bash
sqlite3
```

and inside it:

```text
.help
```

That output is the authoritative command list for **your exact SQLite build**.

Also remember:

```text
sqlite3
   │
   ├── .tables       ← SQLite CLI command
   ├── .schema       ← SQLite CLI command
   ├── .dump         ← SQLite CLI command
   └── .mode table   ← SQLite CLI command
       
   └── SELECT ...    ← SQL
       INSERT ...    ← SQL
       UPDATE ...    ← SQL
       DELETE ...    ← SQL
       CREATE ...    ← SQL
```

That's the mental model I would keep while working through CS50's database material.


[[1 - WHAT IS SQLITE3]]