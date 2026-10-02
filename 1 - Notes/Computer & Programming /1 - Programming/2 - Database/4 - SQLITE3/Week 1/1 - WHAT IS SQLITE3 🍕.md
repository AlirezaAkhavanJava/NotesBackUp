

**SQLite3 is a small, self-contained relational database management system (RDBMS) that stores an entire database in a single file.**

Unlike PostgreSQL or MySQL, SQLite **does not run as a separate database server**.

>**SQLite has no database server process.**
   SQLite is an **embedded database**.

Think of it like this:

```text
PostgreSQL

Your Java App
     │
     ▼
PostgreSQL Server
     │
     ▼
Database
```

With SQLite:

```text
Your Java App
     │
     ▼
SQLite library
     │
     ▼
database.db
```

### The important characteristics

- **Embedded** — SQLite runs inside your application.
    
- **Serverless** — no PostgreSQL/MySQL-style database server needs to be running.
    
- **Zero configuration** — usually you just create/open a `.db` file.
    
- **Relational** — it supports tables, rows, columns, primary keys, foreign keys, `JOIN`, `GROUP BY`, transactions, SQL, etc.
    
- **Single-file database** — the database can literally be something like:
    

```text
longlist.db
```

- **Written in C** — the SQLite engine itself is implemented in C.
    
- **SQL-based** — you interact with it using SQL.
    

For example:

```sql
CREATE TABLE books (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT NOT NULL
);

INSERT INTO books (title, author)
VALUES ('Dune', 'Frank Herbert');

SELECT * FROM books;
```

The result is stored inside the `.db` file.

### SQLite vs PostgreSQL

||SQLite|PostgreSQL|
|---|---|---|
|Server required|❌ No|✅ Yes|
|Database storage|Usually one file|Managed by PostgreSQL|
|Setup|Extremely easy|More involved|
|SQL|✅|✅|
|Concurrent workloads|Limited compared with PostgreSQL|Excellent|
|Large production systems|Sometimes|✅ Excellent|
|Embedded applications|✅ Excellent|Usually unnecessary|
|Mobile/desktop apps|✅ Very common|Less common|

So when you ran:

```text
longlist/
├── 1.sql
├── 2.sql
├── ...
├── 9.sql
└── longlist.db
```

**`longlist.db` is the actual SQLite database file.**

And `sqlite3` usually refers to the **SQLite command-line program** you use to interact with that database:

```bash
sqlite3 longlist.db
```

Then you can execute SQL directly:

```sql
.tables
.schema
SELECT * FROM books;
```

One important distinction:

> **SQLite is the database engine. `sqlite3` is commonly the command-line shell used to interact with that engine.**

That distinction becomes useful when you later use SQLite from Java, because Java will typically communicate with SQLite through a **JDBC driver**, rather than through the `sqlite3` shell.

[[1 - SQL 🦬]]