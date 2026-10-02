


### 🧱 **1. CTAS (Create Table As Select)**

**CTAS** = `CREATE TABLE ... AS SELECT ...`

It creates a **new table** and fills it with the **result of a query**.

#### Example:

```sql
CREATE TABLE sales_copy AS
SELECT * FROM sales WHERE amount > 1000;
```

✅ **Key points**

- It **creates a permanent table**.
    
- The new table is **physically stored** in the database.
    
- It **copies data and structure**, but **not constraints** (like primary keys, foreign keys, indexes).
    
- Used for **backups**, **staging**, or **data transformation** steps.
    

---

### 🧪 **2. Temporary Tables**

A **temporary table** exists **only for the current session** or **transaction**.

#### Example:

```sql
CREATE TEMP TABLE temp_sales AS
SELECT * FROM sales WHERE amount > 1000;
```

✅ **Key points**

- Data disappears when you disconnect (session ends).
    
- Ideal for **intermediate calculations** or **complex ETL steps**.
    
- Each user gets **their own isolated copy** (not shared).
    
- Can be faster because PostgreSQL may skip some disk writes.
    

---

### ⚖️ **CTAS vs Temporary Table**

|Feature|CTAS Table|Temporary Table|
|---|---|---|
|Lifetime|Permanent|Session-based|
|Storage|On disk|Temporary (session memory/disk)|
|Use Case|Data backup, staging, marts|Intermediate query steps|
|Visible To|Everyone (with access)|Only current session|
|Needs Cleanup|Yes (manual `DROP TABLE`)|No (auto-deleted)|

---

### 🧩 Tip:

You can **combine** both:

```sql
CREATE TEMP TABLE temp_sales_summary AS
SELECT region, SUM(amount) AS total
FROM sales
GROUP BY region;
```

---



##### Tags : [[1 - SQL 🦬]]