

There's no `.import`-style dot-command for table→table. You use plain SQL: `INSERT INTO ... SELECT ... WHERE ...`.

## Basic pattern

```sql
INSERT INTO target_table (col1, col2, col3)
SELECT col1, col2, col3
FROM source_table
WHERE some_condition;
```

The column list on the target is optional if the SELECT returns columns in the target's order, but **always list them** — it's safer and survives schema changes.

---

## Examples

### 1. Simple filter
```sql
INSERT INTO active_users (id, name, email)
SELECT id, name, email
FROM users
WHERE active = 1;
```

### 2. Filter + transform
```sql
INSERT INTO orders_2026 (order_id, customer, total)
SELECT id, customer_name, amount * 1.2
FROM orders
WHERE order_date >= '2026-01-01'
  AND order_date <  '2027-01-01';
```

### 3. Copy everything, then filter later
```sql
INSERT INTO backup_users SELECT * FROM users;   -- no filter
```

### 4. Copy with deduplication
```sql
INSERT INTO archive (id, name)
SELECT id, name
FROM live
WHERE id NOT IN (SELECT id FROM archive);
```
Or the more robust anti-join:
```sql
INSERT INTO archive (id, name)
SELECT l.id, l.name
FROM live l
LEFT JOIN archive a ON a.id = l.id
WHERE a.id IS NULL;
```

### 5. Copy and rename columns
```sql
INSERT INTO people (full_name, age)
SELECT first || ' ' || last, years
FROM raw_import
WHERE years IS NOT NULL;
```

### 6. Create the target on the fly from a filtered SELECT
```sql
CREATE TABLE big_orders AS
SELECT * FROM orders WHERE amount > 1000;
```
Note: `CREATE TABLE AS SELECT` does **not** copy constraints, indexes, or primary keys — only column names and data.

---

## Filtering during a `.import`

If your source is still a file and you want the filter applied on load, you can import into a **staging table** first, then filter-copy:

```sql
CREATE TABLE stage (date TEXT, region TEXT, amount REAL);
.import --csv --skip 1 raw.csv stage

CREATE TABLE sales_uk (date TEXT, region TEXT, amount REAL);
INSERT INTO sales_uk SELECT * FROM stage WHERE region = 'UK';

DROP TABLE stage;
```

This is the standard ETL shape in SQLite: **load raw → transform/filter → drop raw**.

---

## Gotchas

- **Column count/order must match** the SELECT output, not the source table's order.
- **`INSERT OR IGNORE` / `INSERT OR REPLACE`** are useful when the target has a PK/UNIQUE and you may collide:
  ```sql
  INSERT OR IGNORE INTO archive (id, name) SELECT id, name FROM live WHERE ...;
  ```
- **No implicit commit** — wrap in `BEGIN; ... COMMIT;` for big loads.
- **Rowid preserved?** Only if you explicitly select and insert the rowid. `SELECT *` doesn't include it.
- **NULL handling** — a `WHERE col = 'x'` filter silently drops NULLs; use `WHERE col IS 'x'` (SQLite's `IS` works like `=` but NULL-safe) if you need NULLs to match.




[[1 - WHAT IS SQLITE3 🍕]]