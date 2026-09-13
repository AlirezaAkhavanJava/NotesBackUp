


## 🧱 **1. BASIC LEVEL**

### 🔹 Definition

`INTERSECT` returns **only the rows that appear in both SELECT statements**.  
Think of it as a **set intersection**.

### 🔹 Syntax

```sql
SELECT column1, column2 FROM table1
INTERSECT
SELECT column1, column2 FROM table2;
```

### 🔹 Example

**Employees who are also Managers**

```sql
SELECT name FROM employees
INTERSECT
SELECT name FROM managers;
```

|name|
|---|
|Bob|
|Carol|

✅ Only names present in **both tables** are returned.

---

## ⚙️ **2. INTERMEDIATE LEVEL**

### 🔹 `INTERSECT` vs `INTERSECT ALL`

|Keyword|Removes Duplicates|Keeps Duplicates|
|---|---|---|
|`INTERSECT`|✅ Yes|❌ No|
|`INTERSECT ALL`|❌ No|✅ Keeps duplicates|

**Example:**

```sql
SELECT name FROM employees
INTERSECT ALL
SELECT name FROM managers;
```

- If “Bob” appears twice in employees and once in managers → result has **one “Bob”**.
    

---

### 🔹 Column Rules

Same as `UNION` and `EXCEPT`:

- Same number of columns
    
- Compatible data types
    
- Column names come from **first SELECT**
    

---

### 🔹 ORDER BY

```sql
SELECT name FROM employees
INTERSECT
SELECT name FROM managers
ORDER BY name;
```

✅ Applies to **final result only**.

---

## 🧠 **3. ADVANCED LEVEL — PostgreSQL**

### 🔹 NULL Handling

- `NULL` is treated as **equal**.
    

```sql
SELECT NULL AS city
INTERSECT
SELECT NULL;
-- → One NULL row appears
```

### 🔹 Parentheses

When combining with `UNION`, `EXCEPT`, or multiple `INTERSECT`s:

```sql
(SELECT id FROM employees
 INTERSECT
 SELECT id FROM managers)
UNION
SELECT id FROM contractors;
```

### 🔹 Performance

- PostgreSQL uses **sort or hash-based deduplication** to find intersections.
    
- `INTERSECT ALL` is faster if duplicates must be preserved.
    

---

## ⚔️ **4. COMMON MISTAKES**

1. ❌ **Different number of columns**
    

```sql
SELECT id, name FROM employees
INTERSECT
SELECT id FROM managers; -- ❌
```

2. ❌ **Incompatible data types**
    

```sql
SELECT id FROM employees
INTERSECT
SELECT name FROM managers; -- ❌ int vs text
```

3. ❌ **Expecting duplicates to be preserved**
    

- Use `INTERSECT ALL` for duplicates.
    

4. ❌ **NULL confusion**
    

- `INTERSECT` treats NULLs as equal → shows one NULL if both tables have it.
    

5. ❌ **Order doesn’t affect intersection**
    

- `A INTERSECT B` = `B INTERSECT A` (commutative)
    

---

## 🚀 **5. REAL-WORLD USE CASES**

### 🧾 Find common users

```sql
SELECT email FROM newsletter
INTERSECT
SELECT email FROM registered_users;
```

- Only emails that exist in both lists.
    

### 📊 Combine with other set operators

```sql
(SELECT id FROM employees
 INTERSECT
 SELECT id FROM managers)
EXCEPT
SELECT id FROM retired_staff;
```

### 📝 Preserve duplicates with ALL

```sql
SELECT name FROM old_table
INTERSECT ALL
SELECT name FROM new_table;
```

---

## 📋 **6. Quick Rules / Cheatsheet**

|Rule|Description|
|---|---|
|1|Number of columns must match|
|2|Data types must be compatible|
|3|Column names come from first SELECT|
|4|`INTERSECT` removes duplicates; use `INTERSECT ALL` to keep them|
|5|NULLs are treated as equal|
|6|Commutative: `A INTERSECT B` = `B INTERSECT A`|
|7|Use parentheses when mixing with `UNION` / `EXCEPT`|
|8|ORDER BY applies to final result only|

---

✅ **Key mental model for all set operators:**

|Operator|Meaning|Duplicates|
|---|---|---|
|`UNION`|Combine rows, remove duplicates|❌ removed|
|`UNION ALL`|Combine rows, keep duplicates|✅ kept|
|`INTERSECT`|Only rows in both|❌ removed|
|`INTERSECT ALL`|Only rows in both, keep duplicates|✅ kept|
|`EXCEPT`|Rows in first not in second|❌ removed|
|`EXCEPT ALL`|Rows in first not in second, keep duplicates|✅ kept|

---

#### Tags : [[1 - SQL 🥞]]