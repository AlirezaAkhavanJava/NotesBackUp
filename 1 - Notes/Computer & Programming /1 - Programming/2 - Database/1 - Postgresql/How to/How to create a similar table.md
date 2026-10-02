

Below is the **standard, portable way** to create a new table that has **exactly the same column names and data types** as an existing table (but **no data**, **no indexes**, **no constraints**, **no triggers** unless you ask for them).

---

## 1. Create an **empty** copy of the structure  

```sql
-- PostgreSQL / MySQL / MariaDB / SQLite
CREATE TABLE new_table_name (LIKE source_table_name);

-- SQL Server
SELECT TOP 0 *
INTO new_table_name
FROM source_table_name;
```

| DBMS          | Syntax |
|---------------|--------|
| **PostgreSQL** | `CREATE TABLE new_table (LIKE source_table INCLUDING ALL);` |
| **MySQL / MariaDB** | `CREATE TABLE new_table LIKE source_table;` |
| **SQLite** | `CREATE TABLE new_table AS SELECT * FROM source_table WHERE 0;` |
| **SQL Server** | `SELECT * INTO new_table FROM source_table WHERE 1=0;` |
| **Oracle** | `CREATE TABLE new_table AS SELECT * FROM source_table WHERE 1=0;` |

> **What you get**  
> * Same column names  
> * Same data types (including length, precision, scale)  
> * **No rows**  

---

## 2. Include **constraints / defaults / indexes** (optional)

### PostgreSQL (most complete)

```sql
-- Everything: defaults, NOT NULL, indexes, PK/FK, comments
CREATE TABLE new_table (LIKE source_table INCLUDING ALL);
```

| `INCLUDING` clause | What it copies |
|--------------------|----------------|
| `DEFAULTS`         | Column defaults |
| `CONSTRAINTS`      | CHECK, NOT NULL, PK, UNIQUE |
| `INDEXES`          | All indexes (including PK) |
| `STORAGE`          | Table-space, fill-factor, etc. |
| `COMMENTS`         | Column / table comments |
| `ALL`              | All of the above |

### MySQL / MariaDB

```sql
CREATE TABLE new_table LIKE source_table;   -- copies PK, FK, indexes, defaults, auto-inc
```

### SQL Server (manual)

```sql
-- 1. copy structure
SELECT * INTO new_table FROM source_table WHERE 1=0;

-- 2. copy indexes / constraints manually (or script them with SSMS)
```

---

## 3. Quick one-liner for **any** ANSI-SQL DB (works everywhere)

```sql
CREATE TABLE new_table AS
SELECT *
FROM source_table
WHERE 1 = 0;          -- forces zero rows, keeps column definitions
```

*Works in PostgreSQL, Oracle, MySQL (with `CREATE TABLE ... AS` support), SQLite, etc.*

---

## 4. Example (PostgreSQL)

```sql
-- Original table
CREATE TABLE employees (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    email      VARCHAR(255) UNIQUE,
    salary     NUMERIC(10,2) DEFAULT 0,
    hired_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Exact copy of the structure (empty)
CREATE TABLE employees_copy (LIKE employees INCLUDING ALL);
```

`employees_copy` now has **identical columns, constraints, defaults, indexes**.

---

### TL;DR (pick the line for your DB)

```sql
-- PostgreSQL
CREATE TABLE new_tbl (LIKE old_tbl INCLUDING ALL);

-- MySQL / MariaDB
CREATE TABLE new_tbl LIKE old_tbl;

-- SQL Server
SELECT * INTO new_tbl FROM old_tbl WHERE 1=0;

-- Any DB (ANSI)
CREATE TABLE new_tbl AS SELECT * FROM old_tbl WHERE 1=0;
```

That’s it – you now have a table with **exactly the same column names and types**, ready for data or further modifications.


##### [[1 - SQL 🦬]]