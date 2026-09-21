

A **schema** is the **formal structure and organization of a database**.

It defines things such as:

- What **tables** exist
    
- What **columns** each table has
    
- Each column's **data type**
    
- **Primary keys**
    
- **Foreign keys**
    
- Constraints such as `NOT NULL`, `UNIQUE`, and `CHECK`
    
- Relationships between tables
    
- Sometimes views, indexes, triggers, etc.
    

Think of a schema as the **blueprint of a database**.

---

# 1. What problem does a schema solve?

Without a schema, a database would have no defined structure.

Imagine storing MBTA data without rules:

```text
station_id     station_name     route
1              Harvard          Red
2              MIT              Red
3              100               ????
```

Questions immediately appear:

- Is `station_id` an integer?
    
- Can two stations have the same ID?
    
- Can `station_name` be empty?
    
- What exactly does `route` reference?
    
- Can a stop reference a station that doesn't exist?
    

A schema establishes these rules.

For example:

```sql
CREATE TABLE stations (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);
```

Now SQLite knows:

```text
stations
├── id
│   └── INTEGER
│   └── PRIMARY KEY
│
└── name
    └── TEXT
    └── NOT NULL
    └── UNIQUE
```

The schema therefore solves the problem of **unstructured, inconsistent, and invalid data**.

---

# 2. Schema as a contract

A useful way to think about a schema is:

> **A schema is a contract describing what data the database accepts and how that data is organized.**

For example:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    age INTEGER CHECK (age >= 0)
);
```

This establishes rules:

```text
id
 └── must identify a row

username
 ├── must contain a value
 └── cannot be duplicated

age
 └── must be >= 0
```

The database can enforce these rules for you.

---

# 3. Schema vs database

These terms are related but aren't the same.

### Database

The actual collection of data.

```text
mbta.db
```

### Schema

The structure describing that database.

```text
stations
routes
stops
trains
...
```

### Data

The actual records:

```text
1 | Harvard
2 | Park Street
3 | Kendall/MIT
```

So:

```text
Database
│
├── Schema
│   ├── tables
│   ├── columns
│   ├── constraints
│   └── relationships
│
└── Data
    ├── rows
    ├── rows
    └── rows
```

---

# 4. How do you create a schema?

In SQLite, you generally create the schema using SQL statements such as:

```sql
CREATE TABLE
CREATE INDEX
CREATE VIEW
CREATE TRIGGER
```

The most important one initially is:

```sql
CREATE TABLE
```

For example:

```sql
CREATE TABLE stations (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);
```

Then:

```sql
CREATE TABLE routes (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);
```

Then a relationship:

```sql
CREATE TABLE stops (
    id INTEGER PRIMARY KEY,
    station_id INTEGER NOT NULL,
    route_id INTEGER NOT NULL,

    FOREIGN KEY (station_id) REFERENCES stations(id),
    FOREIGN KEY (route_id) REFERENCES routes(id)
);
```

Now you have a small relational schema:

```text
stations
   │
   │ station_id
   ▼
 stops
   ▲
   │ route_id
   │
routes
```

---

# 5. Creating the database + schema in SQLite

Start SQLite:

```bash
sqlite3 mbta.db
```

Then create your tables:

```sql
CREATE TABLE stations (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE routes (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE stops (
    id INTEGER PRIMARY KEY,
    station_id INTEGER NOT NULL,
    route_id INTEGER NOT NULL,
    FOREIGN KEY (station_id) REFERENCES stations(id),
    FOREIGN KEY (route_id) REFERENCES routes(id)
);
```

You've now created the database's schema.

---

# 6. How do you see the schema?

SQLite provides commands for inspecting it.

### See tables

```sql
.tables
```

Example:

```text
routes    stations    stops
```

### See a table's structure

```sql
.schema stations
```

You might get:

```sql
CREATE TABLE stations (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);
```

### See the entire schema

```sql
.schema
```

This is particularly useful in CS50.

---

# 7. Schema + data

After creating the schema, you insert data:

```sql
INSERT INTO stations (id, name)
VALUES (1, 'Harvard');

INSERT INTO stations (id, name)
VALUES (2, 'Park Street');
```

Now:

```text
SCHEMA
─────────────────
stations
id      INTEGER
name    TEXT
─────────────────

DATA
─────────────────
1       Harvard
2       Park Street
─────────────────
```

The schema defines **what the data is allowed to look like**.

The rows are the **actual data**.

---

# 8. Schema and relationships

This is one of the most important parts of relational databases.

Suppose:

```text
stations
+----+----------+
| id | name     |
+----+----------+
| 1  | Harvard  |
| 2  | Park St  |
+----+----------+

routes
+----+------+
| id | name |
+----+------+
| 1  | Red  |
| 2  | Green|
+----+------+
```

A stop can connect them:

```text
stops
+----+------------+----------+
| id | station_id | route_id |
+----+------------+----------+
| 1  | 1          | 1        |
| 2  | 2          | 1        |
+----+------------+----------+
```

The schema says:

```sql
FOREIGN KEY (station_id)
    REFERENCES stations(id)
```

and:

```sql
FOREIGN KEY (route_id)
    REFERENCES routes(id)
```

This tells SQLite:

> `station_id` must refer to a station.

> `route_id` must refer to a route.

That's how the schema represents **relationships between entities**.

---

# 9. The major pieces of a schema

When designing a relational database, you'll commonly define:

|Component|Purpose|
|---|---|
|`TABLE`|Defines an entity/data structure|
|Column|Defines an attribute|
|Data type|Defines the kind of value|
|`PRIMARY KEY`|Uniquely identifies a row|
|`FOREIGN KEY`|Connects tables|
|`NOT NULL`|Requires a value|
|`UNIQUE`|Prevents duplicates|
|`CHECK`|Enforces a condition|
|`DEFAULT`|Provides a default value|
|`INDEX`|Improves lookup performance|
|`VIEW`|Defines a reusable query|

For example:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    age INTEGER CHECK (age >= 18),
    country TEXT DEFAULT 'Iran'
);
```

That's not just creating a table.

You're **designing part of the database schema**.

---

# 10. One important SQLite detail

If you're learning this through CS50, you'll eventually encounter an important distinction:

**SQLite does not use schemas in exactly the same way PostgreSQL does.**

In SQLite, when people say:

> "the database schema"

they usually mean the collection of tables, indexes, views, and triggers that define the database's structure.

PostgreSQL also has a separate concept called a **schema**, such as:

```text
database
│
├── public schema
│   ├── users
│   └── orders
│
└── accounting schema
    ├── invoices
    └── payments
```

SQLite doesn't have that same PostgreSQL-style namespace system.

---

## The core mental model

Remember this:

```text
                    DATABASE
                       │
             ┌─────────┴─────────┐
             │                   │
           SCHEMA              DATA
             │                   │
       ┌─────┼─────┐        ┌────┴────┐
       │     │     │        │         │
     tables keys relations  rows      values
       │
       ├── columns
       ├── data types
       ├── constraints
       └── relationships
```

**Schema = blueprint.**  
**Database = the actual container/system.**  
**Tables = structures defined by the blueprint.**  
**Rows = actual records stored in those structures.**

And in CS50's MBTA problem, you're essentially learning to go from:

**real-world transportation system → entities → relationships → relational schema → SQL queries.**


[[1 - WHAT IS SQLITE3 🍕]]
[[1 - SQL 🥞]]