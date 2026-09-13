
In PostgreSQL, the **`information_schema`** is a **built-in system schema** that stores **metadata** — data **about your database’s structure** (tables, columns, constraints, views, etc.).

Think of it like a **catalog of catalogs** — it tells you _what exists_ inside your database.

---

### 🧠 What It Is

- It’s a **set of read-only views**.
    
- It follows the **SQL standard**, so it’s portable across databases (MySQL, SQL Server, etc.).
    
- It’s part of every database by default.
    

---

### 🏗️ Example: Main Areas Inside `information_schema`

|View|Description|
|---|---|
|`tables`|Lists all tables and their schema names|
|`columns`|Lists all columns, their data types, nullability, defaults|
|`views`|Lists all database views|
|`schemata`|Lists all schemas in the database|
|`constraints`|Lists table constraints (PRIMARY KEY, FOREIGN KEY, etc.)|
|`key_column_usage`|Shows which columns are part of constraints|
|`table_constraints`|Describes constraints per table|
|`routines`|Lists functions and stored procedures|
|`triggers`|Lists triggers defined in the database|

---

### ⚙️ Examples

**1️⃣ List all tables in your database**

```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_type = 'BASE TABLE'
  AND table_schema NOT IN ('pg_catalog', 'information_schema');
```

**2️⃣ Get all columns of a table**

```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'employees';
```

**3️⃣ Find all foreign keys**

```sql
SELECT constraint_name, table_name
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY';
```

---

### 🧩 Difference from `pg_catalog`

- `pg_catalog` = PostgreSQL-specific internal system tables (deeper, more detailed)
    
- `information_schema` = SQL-standardized, portable interface  
    → Use `information_schema` for **portable, readable SQL**  
    → Use `pg_catalog` for **PostgreSQL-specific details**
    

---

## how `information_schema` actually works in PostgreSQL : 


## 🧱 1. Two Layers of Metadata

|Layer|Description|Example|
|---|---|---|
|**System Catalog (`pg_catalog` schema)**|Low-level system tables that PostgreSQL uses internally.|`pg_class`, `pg_attribute`, `pg_type`, `pg_namespace`|
|**Information Schema (`information_schema`)**|SQL-standard _views_ built _on top_ of `pg_catalog` tables.|`information_schema.tables`, `information_schema.columns`|

🧠 The `information_schema` doesn’t store data — it just _queries_ the system catalog under the hood.

---

## 🧩 2. How They Connect

Example:  
When you run this:

```sql
SELECT * FROM information_schema.tables;
```

PostgreSQL internally does something _like_:

```sql
SELECT 
  n.nspname AS table_schema,
  c.relname AS table_name,
  CASE c.relkind
    WHEN 'r' THEN 'BASE TABLE'
    WHEN 'v' THEN 'VIEW'
    ELSE 'OTHER'
  END AS table_type
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace;
```

So:

- `pg_class` → holds info about every table, view, index, etc.
    
- `pg_namespace` → holds schema names.
    
- `relkind` in `pg_class` → defines type (`r` = table, `v` = view, `i` = index, etc.)
    

---

## 🧩 3. Column Metadata Example

`information_schema.columns` is built using `pg_attribute`, `pg_type`, and `pg_class`:

```sql
SELECT
  att.attname AS column_name,
  typ.typname AS data_type,
  att.attnotnull AS not_null
FROM pg_attribute att
JOIN pg_class cls ON att.attrelid = cls.oid
JOIN pg_type typ ON att.atttypid = typ.oid
WHERE cls.relname = 'employees'
  AND att.attnum > 0;
```

- `pg_attribute` → column-level info (name, nullability, position)
    
- `pg_type` → data type info
    
- `pg_class` → table-level info
    

---

## 🔍 4. Why Two Layers?

|Use Case|Recommended Schema|
|---|---|
|Standard, cross-database SQL|`information_schema`|
|PostgreSQL-specific features, indexes, stats, OIDs|`pg_catalog`|

Example:

- `information_schema.tables` can’t show **index** info → use `pg_indexes` or `pg_class`.
    
- `information_schema` hides PostgreSQL-only features like **toast tables** or **partition info**.
    

---

## ⚙️ 5. Summary Table

|Concept|`information_schema`|`pg_catalog`|
|---|---|---|
|SQL standard|✅|❌|
|Portable to other RDBMS|✅|❌|
|Readable for users|✅|❌ (internal names, OIDs)|
|Full internal detail|❌|✅|
|Editable|❌ (read-only views)|❌ (system-owned tables)|



##### Tags : [[1 - SQL 🥞]]