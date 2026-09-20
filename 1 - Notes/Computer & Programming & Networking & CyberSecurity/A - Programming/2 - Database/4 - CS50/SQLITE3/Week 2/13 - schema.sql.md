

`schema.sql` is **not a SQLite command**.

It is conventionally the name of an **SQL script file** containing SQL statements that define a database's schema.

Think:

```text
schema.sql
    │
    ├── CREATE TABLE ...
    ├── CREATE INDEX ...
    ├── CREATE VIEW ...
    └── CREATE TRIGGER ...
```

Its purpose is to keep your database's **structure definition in a reusable file**.

---

## 1. Example `schema.sql`

Suppose you create:

```text
schema.sql
```

with:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    age INTEGER
);

CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    user_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX idx_posts_user_id
ON posts(user_id);
```

That file describes the database structure.

---

# 2. Execute `schema.sql` with SQLite

Start SQLite:

```bash
sqlite3 app.db
```

Then inside the SQLite shell:

```text
.read schema.sql
```

SQLite reads the file and executes its SQL statements.

Afterward:

```text
.tables
```

might show:

```text
posts   users
```

And:

```text
.schema
```

shows the definitions.

---

# 3. Execute it directly from Bash

You can also do:

```bash
sqlite3 app.db < schema.sql
```

This means:

```text
schema.sql
     ↓
SQL statements
     ↓
sqlite3
     ↓
app.db
```

This is especially useful for scripts and automation.

---

# 4. Why use `schema.sql`?

Instead of manually typing:

```sql
CREATE TABLE users (...);
CREATE TABLE posts (...);
CREATE INDEX ...;
```

every time, you keep the database definition in one file.

Then a new database can be created with:

```bash
sqlite3 app.db < schema.sql
```

This gives you a **reproducible database structure**.

For example:

```text
project/
├── app.db
├── schema.sql
└── data.sql
```

You might have:

### `schema.sql`

```sql
CREATE TABLE users (...);
CREATE TABLE posts (...);
```

### `data.sql`

```sql
INSERT INTO users (...);
INSERT INTO posts (...);
```

Then:

```bash
sqlite3 app.db < schema.sql
sqlite3 app.db < data.sql
```

---

## 5. `schema.sql` vs `.schema`

This is an important distinction:

### `.schema`

SQLite **CLI command**:

```text
.schema
```

It **shows** the current database schema.

### `schema.sql`

A **file** containing SQL statements that can **create/modify** a schema.

```text
.schema
   ↓
"Show me the schema."

schema.sql
   ↓
"Here are SQL statements defining the schema."
```

And `.schema` itself can be redirected to create a schema file:

```bash
sqlite3 app.db .schema > schema.sql
```

So you can export the current schema into a reusable `schema.sql` file.


[[1 - WHAT IS SQLITE3]]
[[1 - SQL 🥞]]
