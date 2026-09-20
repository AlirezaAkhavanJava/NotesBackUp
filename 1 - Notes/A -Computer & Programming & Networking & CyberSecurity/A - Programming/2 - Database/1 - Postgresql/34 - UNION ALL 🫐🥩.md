


## 🧱 **1. BASIC LEVEL**

### 🔹 Definition

`UNION ALL` combines results of **two or more SELECT statements** into a **single result set** —  
**without removing duplicates**.

### 🔹 Syntax

```sql
SELECT column1, column2 FROM table1
UNION ALL
SELECT column1, column2 FROM table2;
```

### 🔹 Example

```sql
SELECT name FROM employees
UNION ALL
SELECT name FROM managers;
```

✅ Returns _all_ names, even if they appear in both tables.

---

## ⚙️ **2. HOW IT WORKS**

|Feature|`UNION`|`UNION ALL`|
|---|---|---|
|Removes duplicates|✅ Yes|❌ No|
|Performance|⏳ Slower (needs sorting or hashing)|⚡ Faster (just appends)|
|Use when|You need unique results|You want all rows, even duplicates|

---

### 🔹 Internal Logic (PostgreSQL)

`UNION ALL` doesn’t sort or deduplicate — it literally appends query outputs in sequence.  
This means:

1. The first SELECT runs → sends results.
    
2. The second SELECT runs → appends results.
    
3. Done. No deduplication pass.
    

---

## 💡 **3. INTERMEDIATE LEVEL**

### ✅ Column Rules

Same as `UNION`:

- Same number of columns.
    
- Same or compatible data types.
    
- Column names come from the **first SELECT**.
    

```sql
SELECT id AS person_id, name FROM employees
UNION ALL
SELECT id, name FROM contractors;
-- Output column name: person_id
```

---

### ✅ ORDER BY

Just like `UNION`, `ORDER BY` applies **only to the final combined result**, not to each branch:

```sql
SELECT name FROM employees
UNION ALL
SELECT name FROM managers
ORDER BY name;
```

If you need to order each branch individually, use subqueries:

```sql
SELECT * FROM (
  SELECT name FROM employees ORDER BY name
) e
UNION ALL
SELECT * FROM (
  SELECT name FROM managers ORDER BY name
) m;
```

---

### ✅ Use in CTEs and Views

```sql
CREATE VIEW all_users AS
SELECT id, name FROM customers
UNION ALL
SELECT id, name FROM employees;
```

or with CTE:

```sql
WITH combined AS (
  SELECT id, name FROM customers
  UNION ALL
  SELECT id, name FROM employees
)
SELECT * FROM combined WHERE name LIKE 'E%';
```

---

## 🧠 **4. ADVANCED LEVEL — PostgreSQL DETAILS**

### 🔹 Type Resolution

PostgreSQL finds a **common supertype** for each column position:

```sql
SELECT 1 AS val
UNION ALL
SELECT 1.5;
-- → Result type is numeric
```

---

### 🔹 NULL Handling

`UNION ALL` does **not** merge duplicates, even if both are `NULL`:

```sql
SELECT NULL AS city
UNION ALL
SELECT NULL;
-- → Two NULL rows appear
```

---

### 🔹 Performance Note

`UNION ALL` is **much faster** for large data sets because:

- No sorting
    
- No hashing
    
- Just sequential append
    

It’s ideal for **data aggregation**, **logs**, **ETL pipelines**, or **report merges**.

Example:

```sql
SELECT * FROM sales_2024
UNION ALL
SELECT * FROM sales_2025
UNION ALL
SELECT * FROM sales_2026;
```

This pattern is common in **time-based partitioning**.

---

## ⚔️ **5. COMMON MISTAKES**

1. ❌ Using `UNION` instead of `UNION ALL` when duplicates are needed  
    → Causes missing rows.
    
2. ❌ Forgetting to match column types  
    → Causes “types do not match” error.
    
3. ❌ Wrong ORDER BY placement  
    → Must be at the end, after all unions.
    
4. ❌ Expecting automatic deduplication  
    → You must explicitly use `DISTINCT` or `GROUP BY` if needed.
    

---

## 🚀 **6. REAL-WORLD USE CASES**

### 🧾 Combine Yearly Tables

```sql
SELECT * FROM invoices_2023
UNION ALL
SELECT * FROM invoices_2024;
```

### 📈 Merge Log Sources

```sql
SELECT * FROM app_logs
UNION ALL
SELECT * FROM system_logs
ORDER BY timestamp;
```

### 📊 Summarize Combined Data

```sql
SELECT country, SUM(amount) AS total
FROM (
  SELECT country, amount FROM sales_domestic
  UNION ALL
  SELECT country, amount FROM sales_international
) t
GROUP BY country;
```

---

## 📋 **7. Quick Summary Rules**

|Rule|Description|
|---|---|
|1|Each SELECT must have the same number of columns|
|2|Data types in each column position must be compatible|
|3|Column names come from the first SELECT|
|4|`UNION ALL` keeps duplicates|
|5|`ORDER BY` only allowed at the end|
|6|Use subqueries if you need per-SELECT ordering|
|7|Use it for better performance when deduplication isn’t required|

---



## 1️⃣ Sample Tables

**Table A: Employees**

|id|name|
|---|---|
|1|Alice|
|2|Bob|
|3|Carol|

**Table B: Managers**

|id|name|
|---|---|
|2|Bob|
|3|Carol|
|4|Dave|

---

## 2️⃣ `UNION`

**Query:**

```sql
SELECT name FROM employees
UNION
SELECT name FROM managers;
```

**Result:**

|name|
|---|
|Alice|
|Bob|
|Carol|
|Dave|

✅ **Notes:**

- Stacks results vertically
    
- **Removes duplicates** (Bob and Carol appear only once)
    

---

## 3️⃣ `UNION ALL`

**Query:**

```sql
SELECT name FROM employees
UNION ALL
SELECT name FROM managers;
```

**Result:**

|name|
|---|
|Alice|
|Bob|
|Carol|
|Bob|
|Carol|
|Dave|

✅ **Notes:**

- Stacks results vertically
    
- **Keeps duplicates** (Bob and Carol appear twice)
    

---

## 4️⃣ `JOIN` (INNER JOIN Example)

**Query:**

```sql
SELECT e.name AS employee, m.name AS manager
FROM employees e
JOIN managers m ON e.id = m.id;
```

**Result:**

|employee|manager|
|---|---|
|Bob|Bob|
|Carol|Carol|

✅ **Notes:**

- Combines rows **horizontally** based on a condition
    
- Only matches rows with the same `id`
    
- Does **not remove duplicates unless explicitly asked**
    

---

## 5️⃣ Visual Comparison

|Concept|Direction of Combination|Duplicates Removed?|Example Rows from Above|
|---|---|---|---|
|`UNION`|Vertical|✅ Yes|Alice, Bob, Carol, Dave|
|`UNION ALL`|Vertical|❌ No|Alice, Bob, Carol, Bob, Carol, Dave|
|`JOIN`|Horizontal|❌ No (depends)|Bob-Bob, Carol-Carol|

---

💡 **Key takeaway:**

- **`UNION / UNION ALL` → stack rows**
    
- **`JOIN` → combine columns**
    

Think: `UNION` = “stack pancakes,” `JOIN` = “pair socks.”

---


#### Tags: [[1 - SQL 🥞]]