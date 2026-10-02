


SQLite is different from PostgreSQL/MySQL here:

> **You don't normally use `CREATE DATABASE`.**

A SQLite database is simply a **file**. SQLite creates the database file when you open a file that doesn't exist.

## 1. Create a database

From your terminal:

```bash
sqlite3 mbta.db
```

If `mbta.db` doesn't exist, SQLite creates it.

You'll enter the SQLite shell:

```text
SQLite version ...
Enter ".help" for usage hints.
sqlite>
```

You now have a database.

Exit:

```sql
.quit
```

Check:

```bash
ls
```

You'll see:

```text
mbta.db
```

---

## 2. Create a database in a specific location

For example:

```bash
sqlite3 /mnt/hdd/Home/Programming\ Files/HarvardDatabase/mbta.db
```

SQLite creates the file there if it doesn't already exist.

---

## 3. Then create your schema

Open it:

```bash
sqlite3 mbta.db
```

Create a table:

```sql
CREATE TABLE stations (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);
```

Check:

```sql
.tables
```

Output:

```text
stations
```

Check the schema:

```sql
.schema
```

---

## The important mental model

With SQLite:

```text
sqlite3 mbta.db
        │
        ▼
   ┌───────────┐
   │  mbta.db  │  ← Database file
   ├───────────┤
   │  Schema   │
   │    ├── stations
   │    ├── routes
   │    └── stops
   │
   │  Data
   │    ├── rows
   │    └── values
   └───────────┘
```

So unlike PostgreSQL:

```sql
CREATE DATABASE mydb;
```

you generally just do:

```bash
sqlite3 mydb.db
```

**The `.db` file is the SQLite database.**


[[1 - WHAT IS SQLITE3 🍕]]