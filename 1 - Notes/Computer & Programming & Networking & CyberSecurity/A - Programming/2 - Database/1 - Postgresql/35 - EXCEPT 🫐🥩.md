
## 🧱 **1. BASIC LEVEL**

### 🔹 Definition

`EXCEPT` returns **rows from the first SELECT that are not present in the second SELECT**.  
It’s like **“A minus B”** in sets.

### 🔹 Syntax

```sql
SELECT column1, column2 FROM table1
EXCEPT
SELECT column1, column2 FROM table2;
```

### 🔹 Example

**Employees minus Managers**

```sql
SELECT name FROM employees
EXCEPT
SELECT name FROM managers;
```

|name|
|---|
|Alice|

✅ Alice is in employees but **not** in managers.

---

## ⚙️ **2. INTERMEDIATE LEVEL**

### 🔹 `EXCEPT` vs `EXCEPT ALL`

|Keyword|Removes Duplicates|Keeps Duplicates|Notes|
|---|---|---|---|
|`EXCEPT`|✅ Yes|❌ No|Default behavior|
|`EXCEPT ALL`|❌ No|✅ Keeps duplicates|Counts repeated rows|

**Example:**

```sql
SELECT name FROM employees
EXCEPT ALL
SELECT name FROM managers;
```

- If “Bob” appears twice in employees and once in managers → result has **one “Bob”**.
    

---

### 🔹 Column Rules

Same as `UNION`:

- Same number of columns
    
- Compatible data types
    
- Column names from the **first SELECT**
    

---

### 🔹 ORDER BY

`ORDER BY` applies to the **final result**:

```sql
SELECT name FROM employees
EXCEPT
SELECT name FROM managers
ORDER BY name;
```

---

## 🧠 **3. ADVANCED LEVEL — PostgreSQL**

### 🔹 NULL Handling

- `NULL` is treated as **equal** in `EXCEPT`
    

```sql
SELECT NULL AS city
EXCEPT
SELECT NULL;
-- → Result = empty (NULL removed)
```

### 🔹 Performance

- PostgreSQL uses **sort or hash-based deduplication** to find differences.
    
- `EXCEPT ALL` is faster when duplicates must be preserved, as fewer sort/hash operations are needed.
    

### 🔹 Parentheses

When combining `EXCEPT` with `UNION` or `INTERSECT`, use parentheses to control order:

```sql
(SELECT id FROM employees
 EXCEPT
 SELECT id FROM managers)
UNION
SELECT id FROM contractors;
```

---

## ⚔️ **4. COMMON MISTAKES**

1. ❌ **Different number of columns**
    

```sql
SELECT id, name FROM employees
EXCEPT
SELECT id FROM managers; -- ❌
```

2. ❌ **Incompatible data types**
    

```sql
SELECT id FROM employees
EXCEPT
SELECT name FROM managers; -- ❌ int vs text
```

3. ❌ **Expecting duplicates to be preserved**
    

- Use `EXCEPT ALL` if needed.
    

4. ❌ **Wrong NULL assumptions**
    

- `EXCEPT` treats NULLs as equal — so they get removed if matched.
    

5. ❌ **Order confusion**
    

- `A EXCEPT B` ≠ `B EXCEPT A` — order matters!
    

---

## 🚀 **5. REAL-WORLD USE CASES**

### 🧾 Find unmatched records

```sql
-- Customers who haven’t made orders
SELECT customer_id FROM customers
EXCEPT
SELECT customer_id FROM orders;
```

### 📊 Combine with UNION/INTERSECT

```sql
(SELECT id FROM employees
 EXCEPT
 SELECT id FROM managers)
UNION
SELECT id FROM contractors;
```

### 📝 Deduplicate manually with EXCEPT ALL

```sql
SELECT name FROM old_table
EXCEPT ALL
SELECT name FROM new_table;
```

---

## 📋 **6. Quick Rules / Cheatsheet**

|Rule|Description|
|---|---|
|1|Number of columns must match|
|2|Data types must be compatible|
|3|Column names come from first SELECT|
|4|`EXCEPT` removes duplicates; use `EXCEPT ALL` to keep them|
|5|NULLs are treated as equal|
|6|Order matters (`A EXCEPT B` ≠ `B EXCEPT A`)|
|7|Use parentheses when mixing with `UNION` / `INTERSECT`|
|8|ORDER BY applies to final result only|

---


#### Tags : [[1 - SQL 🥞]]