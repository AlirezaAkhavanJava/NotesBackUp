
In PostgreSQL, there are a few ways to **make a table that’s a copy of another**. It depends on whether you want **just the structure** or **structure + data**.

---

### 1️⃣ Copy **structure only**

```sql
CREATE TABLE new_table AS
TABLE existing_table
WITH NO DATA;
```

- Copies **columns and types**, but **no rows**.
    
- Useful if you just want the same schema.
    

---

### 2️⃣ Copy **structure + data**

```sql
CREATE TABLE new_table AS
TABLE existing_table;
```

or

```sql
CREATE TABLE new_table AS
SELECT * FROM existing_table;
```

- Copies **columns and all rows**.
    
- Indexes, constraints, sequences are **not copied**.
    

---

### 3️⃣ Copy including **indexes and constraints**

- PostgreSQL doesn’t have a single command for this; you need to use **`pg_dump`** or manually recreate indexes/constraints:
    

```bash
pg_dump -t existing_table --schema-only mydb > table.sql
```

Then edit the SQL to create a new table.

---

💡 Quick note: `CREATE TABLE new_table AS SELECT *` is the most common for **quick copies with data**.

[[1 - SQL 🦬]]