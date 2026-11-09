

In PostgreSQL, a **database** is a named, isolated container that holds your schemas, tables, views, functions, indexes and the data inside them. When you open `psql`, you are always connected to exactly **one** database, and everything you run (`SELECT`, `CREATE TABLE`, `GRANT`) happens inside that one. Other databases on the same server are invisible to your queries.

The thing that surprises most people is that a database is not the top level. Above it sits the **cluster**, which is one running PostgreSQL server that manages many databases. Once you see the full hierarchy, commands like `\l`, `\c` and `\dt` stop feeling random, because each one works at a different level.

![[730617d7-7a22-4f45-881e-efa9343aa5e6.png]]

---

## 1. The hierarchy

```
Cluster (one PostgreSQL server, one port, e.g. 5432)
 ├── Role: postgres, app_user, ...        ← shared by ALL databases
 ├── Database: postgres
 ├── Database: template1
 ├── Database: mydb
 │    ├── Schema: public
 │    │    ├── Table: users
 │    │    └── Table: orders
 │    └── Schema: audit
 │         └── Table: login_log
 └── Database: otherdb
```

|Level|What it is|psql command to list it|
|---|---|---|
|Cluster|The running server and its data directory|`\conninfo` shows where you're connected|
|Database|Isolated container of schemas|`\l`|
|Schema|A namespace inside a database|`\dn`|
|Table|Rows and columns|`\dt`|

Two rules follow from this:

1. **A table name is only unique inside its schema.** `public.users` and `audit.users` can both exist.
2. **A database can't see another database.** `SELECT * FROM otherdb.public.users;` fails with "cross-database references are not implemented".

---

## 2. Seeing databases in psql

Connect to the server and list what exists:

```
psql -U postgres
```

```
postgres=# \l
```

You will see something like:

|Name|Owner|Encoding|Collate|
|---|---|---|---|
|postgres|postgres|UTF8|en_US.UTF-8|
|template0|postgres|UTF8|en_US.UTF-8|
|template1|postgres|UTF8|en_US.UTF-8|
|mydb|app_owner|UTF8|en_US.UTF-8|

Look at the prompt: `postgres=#`. The text before `=` is the **database you're currently connected to**. The `#` means you're a superuser (a normal user shows `>`).

The three databases that exist from the start:

- **postgres** is a default database to connect to when you have nowhere else to go. It's convenient but not special.
- **template1** is the blueprint copied whenever you run `CREATE DATABASE`. Anything you add to it (an extension, say) appears in every new database.
- **template0** is a pristine, untouchable copy. Use it when you need a database with a different encoding.

---

## 3. Creating, entering and dropping a database

```sql
CREATE DATABASE shopdb
  OWNER app_owner
  ENCODING 'UTF8'
  TEMPLATE template0;
```

Line by line:

- `CREATE DATABASE shopdb` makes a new, empty database. PostgreSQL copies `template1` (or the template you name).
- `OWNER app_owner` sets which role owns it. The owner can drop it and manage its contents.
- `ENCODING 'UTF8'` fixes how text is stored. You can't change this later.
- `TEMPLATE template0` copies the clean blueprint instead of `template1`.

Now move into it:

```
postgres=# \c shopdb
You are now connected to database "shopdb" as user "postgres".
shopdb=#
```

`\c` (connect) closes your connection to the old database and opens a new one. The prompt changes to `shopdb=#`. This is a new session, so anything you set earlier, like `SET search_path`, is gone.

To delete one:

```sql
DROP DATABASE shopdb;
```

This permanently deletes everything inside, with no recycle bin.

---

## 4. Proving that databases are isolated

```
shopdb=# CREATE TABLE users (id serial PRIMARY KEY, email text);
CREATE TABLE
shopdb=# \dt
         List of relations
 Schema | Name  | Type  |  Owner
--------+-------+-------+----------
 public | users | table | postgres

shopdb=# \c postgres
postgres=# \dt
Did not find any relations.
```

The `users` table exists in `shopdb` only. The same thing happens in reverse. This is why one server can safely host many unrelated projects.

---

## 5. What is shared and what is not

|Per database|Shared across the whole cluster|
|---|---|
|Schemas, tables, views|**Roles** (users and groups)|
|Data and indexes|The port and `postgresql.conf`|
|Extensions you installed|`pg_hba.conf` login rules|
|Table-level `GRANT`s|Which databases exist|

This ties directly to your DCL lesson. `CREATE ROLE app_user` creates the role for the **whole cluster**, but `GRANT CONNECT ON DATABASE shopdb TO app_user` and `GRANT SELECT ON users TO app_user` are specific to what lives in each database. A role can exist everywhere yet only be allowed into some databases.

---

## 6. Connecting from outside psql

You choose the database at connection time:

```
psql -h localhost -p 5432 -U app_user -d shopdb
```

- `-h` is the host, `-p` the port, `-U` the role, `-d` the database.

Your Spring Boot app does the same thing through the JDBC URL, which is where the database name lives:

```
jdbc:postgresql://localhost:5432/shopdb
```

The part after the last slash is `shopdb`. That is the database the app's connection pool will connect to, as covered in your DataSource and Spring PostgreSQL config lessons. If the name is wrong, you get `FATAL: database "..." does not exist`.

---

## 7. Useful inspection commands

```
\conninfo                       -- current database, user, host, port
\l+                             -- list databases with sizes
SELECT current_database();      -- same info, but in SQL
SELECT pg_size_pretty(pg_database_size('shopdb'));   -- e.g. 8453 kB
```

Under the hood, `\l` reads the system catalog `pg_database`, which you can query directly:

```sql
SELECT datname, datdba::regrole AS owner FROM pg_database;
```

Each database also lives on disk as a numbered folder inside the cluster's data directory (under `base/`), but you should never touch those files by hand.

---

## 8. Common mistakes

1. **Running `DROP DATABASE` while connected to it.** It fails. Connect to `postgres` first, then drop. Other active connections also block it.
2. **Running `CREATE DATABASE` inside a transaction block.** It isn't allowed.
3. **Creating tables in the wrong database.** Always glance at the prompt (`shopdb=#`) before running DDL.
4. **Expecting joins across databases.** Not possible directly. If you truly need it, you'd use the `postgres_fdw` or `dblink` extensions, or just use schemas in one database instead.
5. **Mixing up "database" and "schema".** Use separate databases for separate projects. Use separate schemas to organize parts of one project.

---

## Related concept: SQLite's meaning of "database"

You also know SQLite, where the answer is much simpler: **one file is one database**. `sqlite3 shop.db` opens that file, and there is no server, no cluster and no roles. PostgreSQL's database is a logical container managed by a server process, so you connect over a network to a named database instead of opening a file.



[[PostgreSQL]]