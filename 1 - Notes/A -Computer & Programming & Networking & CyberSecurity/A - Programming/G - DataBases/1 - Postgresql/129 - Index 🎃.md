
## 1. **What is an index?**

An **index** in PostgreSQL is a special data structure that **speeds up data retrieval**. Think of it like a book’s index: instead of reading the whole book, you go straight to the page you need.

- Without an index → `SELECT` scans the entire table (full table scan).
    
- With an index → PostgreSQL can jump to the rows faster.
    

Indexes **don’t store data themselves**; they store pointers to table rows.

![[Pasted image 20251210130936.png]]

---

## 2. **Why use indexes?**

- Faster `SELECT` queries (`WHERE`, `JOIN`, `ORDER BY`).
    
- Faster search on specific columns.
    
- Can enforce constraints (`UNIQUE` indexes).
    

**Trade-off:** Indexes **slow down `INSERT`, `UPDATE`, and `DELETE`** because the index itself needs updating.

---

## 3. **Types of indexes in PostgreSQL**

|Type|Use case|Notes|
|---|---|---|
|**B-tree**|Default, most queries (`=`, `<`, `<=`, `>`, `>=`)|Great for equality & range queries|
|**Hash**|Only `=` queries|Rarely used; limited functionality|
|**GIN** (Generalized Inverted Index)|Full-text search, JSONB, array contains|Great for searching inside a column with many elements|
|**GiST** (Generalized Search Tree)|Geospatial data, ranges|Supports `<>`, geometric queries|
|**BRIN** (Block Range Index)|Very large, sequential tables|Small, lightweight, only for certain sequential data|
|**SP-GiST**|Specialized tree structures|Rare, advanced use cases|

---
![[Pasted image 20251206144504.png]]
## 4. **Creating indexes**

**Basic B-tree index:**

```sql
CREATE INDEX idx_students_name
ON students(name);
```

**Unique index:**

```sql
CREATE UNIQUE INDEX idx_email_unique
ON students(email);
```

**Index on multiple columns:**

```sql
CREATE INDEX idx_students_name_country
ON students(name, country);
```

**GIN index for JSONB or array:**

```sql
CREATE INDEX idx_json_data
ON my_table USING GIN (data);
```

**BRIN index for large sequential tables:**

```sql
CREATE INDEX idx_created_at_brin
ON events USING BRIN (created_at);
```

---

## 5. **Using indexes effectively**

- **Use indexes on columns used in `WHERE`, `JOIN`, `ORDER BY`, `GROUP BY`.**
    
- Avoid indexing columns with **low selectivity** (e.g., `gender` with only `M`/`F`) — index might be useless.
    
- **Partial indexes** are powerful:
    

```sql
CREATE INDEX idx_active_students
ON students(name)
WHERE active = true;
```

This index only stores rows where `active = true` → smaller and faster.

---

## 6. **Check if an index is used**

```sql
EXPLAIN SELECT * FROM students WHERE name = 'John';
```

- `Index Scan` → index is being used.
    
- `Seq Scan` → index is not used.
    

---

## 7. **Drop an index**

```sql
DROP INDEX idx_students_name;
```

---

## 8. **Maintenance tips**

- `VACUUM` and `ANALYZE` keep indexes efficient.
    
- Avoid creating too many indexes on a table → slows writes.
    
- Monitor index usage with `pg_stat_user_indexes`.
    




###### Tags : [[1 - SQL 🥞]]