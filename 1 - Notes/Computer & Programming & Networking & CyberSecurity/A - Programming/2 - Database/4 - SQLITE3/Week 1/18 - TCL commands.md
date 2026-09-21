In **SQLite3**, **TCL commands** (often called **dot commands**) are commands provided by the **SQLite command-line shell**, not SQL statements.

They control the SQLite shell itself rather than querying or modifying database data.

### Definition

> **TCL commands in SQLite3 are special shell commands used to control the SQLite3 command-line interface, inspect databases, format output, manage files, and perform shell-level operations.**

They normally begin with a **`.` (dot)**:

```sql
.tables
.schema
.databases
.mode
.headers
.output
.import
.read
.quit
```

### Common SQLite3 TCL / dot commands

|Command|Purpose|
|---|---|
|`.help`|Shows available SQLite shell commands|
|`.databases`|Lists attached databases|
|`.tables`|Lists tables|
|`.schema`|Displays the schema of tables/views|
|`.mode`|Changes the output format|
|`.headers`|Enables/disables column headers|
|`.output`|Redirects output to a file|
|`.read`|Executes SQL/script commands from a file|
|`.import`|Imports data from a file|
|`.dump`|Exports the database as SQL statements|
|`.backup`|Creates a backup of a database|
|`.restore`|Restores a database|
|`.cd`|Changes the working directory|
|`.show`|Displays current shell settings|
|`.indexes`|Lists indexes|
|`.foreign_keys`|Shows or changes foreign-key enforcement|
|`.log`|Enables/disables logging|
|`.quit` / `.exit`|Exits the SQLite shell|

### Example

```bash
sqlite3 database.db
```

Then:

```sql
.tables
.schema users
.mode column
.headers on
.databases
```

These are **not SQL commands**:

```sql
.tables       -- SQLite shell command
.schema       -- SQLite shell command
.mode column  -- SQLite shell command
```

Whereas these are SQL:

```sql
SELECT * FROM users;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT
);

INSERT INTO users (name) VALUES ('Alireza');
```

### Important terminology

Strictly speaking, SQLite's shell commands are **not TCL commands**. They are generally called **SQLite CLI dot commands** or **dot-commands**. The SQLite shell itself historically has Tcl integration, which is probably where the term "TCL commands" can cause confusion.

For your SQLite notes, I would categorize them as:

```text
SQLite3 Commands
│
├── SQL Commands
│   ├── DDL
│   ├── DML
│   ├── DQL
│   └── TCL / Transaction Control
│
└── SQLite CLI Dot Commands
    ├── .tables
    ├── .schema
    ├── .mode
    ├── .headers
    ├── .dump
    └── ...
```

One important correction: **TCL in SQL terminology usually means Transaction Control Language**, such as `BEGIN`, `COMMIT`, and `ROLLBACK`—not SQLite's `.tables`-style commands.

[[1 - WHAT IS SQLITE3 🍕]]