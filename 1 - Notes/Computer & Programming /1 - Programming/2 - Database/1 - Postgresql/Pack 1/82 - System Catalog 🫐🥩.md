

## 🧠 1️⃣ What is a System Catalog?

A **System Catalog** is the **database’s internal dictionary** — a special set of tables that store **metadata** about everything inside the database.

Basically, it’s the **database about the database**.

---

## 📚 2️⃣ What It Stores

System catalogs hold info like:

|Type|Example Info|
|---|---|
|**Tables**|Table names, columns, data types|
|**Indexes**|Which tables have indexes and how|
|**Constraints**|Primary keys, foreign keys|
|**Users & Roles**|Who can connect, privileges|
|**Functions & Views**|Definitions and parameters|
|**Schemas**|Logical groupings of objects|

So whenever you run a query like:

```sql
SELECT * FROM users;
```

PostgreSQL first checks the **catalog tables** to know:

- where “users” is stored,
    
- what columns it has,
    
- what types those columns are.
    

---

## 🧩 3️⃣ Catalog Tables Live in the “pg_catalog” Schema

PostgreSQL keeps all internal system tables inside a built-in schema called `pg_catalog`.

You can see them with:

```sql
\dn   -- shows schemas
\dt pg_catalog.*   -- shows catalog tables
```

Or query directly:

```sql
SELECT * FROM pg_catalog.pg_tables;
```

---

## 🗂️ 4️⃣ Common System Catalog Tables

|Catalog Table|Description|
|---|---|
|**pg_database**|Lists all databases in the cluster|
|**pg_class**|One row per table, index, or sequence|
|**pg_attribute**|One row per column in every table|
|**pg_type**|Data types defined in the system|
|**pg_user / pg_roles**|Info about database users and permissions|
|**pg_index**|Metadata about all indexes|
|**pg_constraint**|All constraints (PK, FK, UNIQUE, etc.)|
|**pg_namespace**|Schemas (namespaces) info|
|**pg_proc**|All functions and procedures|

---

## ⚙️ 5️⃣ Example: How the Catalog Works Behind the Scenes

Let’s say you create a table:

```sql
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name TEXT,
    age INT
);
```

PostgreSQL will:

1. Add a record to **pg_class** → defines table “students”.
    
2. Add 3 rows to **pg_attribute** → for columns id, name, age.
    
3. Add a record to **pg_constraint** → defines the primary key.
    
4. Add a record to **pg_index** → for the PK index it auto-created.
    

All this happens automatically — the catalog keeps track of _everything_.

---

## 🔍 6️⃣ You Can Query Catalogs Yourself

Example — list all user tables:

```sql
SELECT relname FROM pg_class WHERE relkind = 'r' AND relnamespace IN (
  SELECT oid FROM pg_namespace WHERE nspname NOT LIKE 'pg_%' AND nspname <> 'information_schema'
);
```

Or show all columns of a specific table:

```sql
SELECT attname, atttypid::regtype
FROM pg_attribute
WHERE attrelid = 'students'::regclass AND attnum > 0;
```

---

## 🧮 7️⃣ Why System Catalogs Matter

|Use Case|Why It’s Important|
|---|---|
|**Query optimization**|The planner uses catalogs to find indexes, stats, etc.|
|**Tooling & introspection**|Tools like pgAdmin read from these tables|
|**Metadata analysis**|You can script reports on schema and usage|
|**Permissions**|Role and access data live here|

---

## 🧠 Summary

|Concept|Description|
|---|---|
|**System Catalog**|Internal metadata database|
|**pg_catalog schema**|Stores all system tables|
|**pg_class**|Objects (tables, indexes, etc.)|
|**pg_attribute**|Columns|
|**pg_constraint**|Keys & rules|
|**pg_roles**|Users and privileges|
|**pg_type**|Data types|

---

In short:

> The **system catalog** is PostgreSQL’s “internal memory” — it knows what exists, how it’s structured, and who can use it. Without it, the database wouldn’t even know what tables you created.



##### Tags : [[1 - SQL 🦬]]