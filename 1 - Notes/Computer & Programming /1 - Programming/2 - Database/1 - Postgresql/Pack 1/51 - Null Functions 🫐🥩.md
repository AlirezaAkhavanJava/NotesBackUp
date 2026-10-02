

## 🧱 **1️⃣ Concept**

`NULL` = “unknown / missing value,” not 0 or empty string.  
So you **can’t compare** it with `=` or `!=`.  
You must use `IS NULL` / `IS NOT NULL`.

---

## ⚙️ **2️⃣ Common NULL Functions**

|Function|Description|Example|Result|
|---|---|---|---|
|**COALESCE(expr1, expr2, ...)**|Returns the first **non-NULL** value|`COALESCE(NULL, 'A', 'B')`|`'A'`|
|**NULLIF(expr1, expr2)**|Returns `NULL` if both are equal, else `expr1`|`NULLIF(5,5)` → NULL `NULLIF(5,3)` → 5|`NULL` / `5`|
|**ISNULL(expr, replacement)** _(T-SQL)_|Same as COALESCE, not in PostgreSQL|—|—|
|**NVL(expr1, expr2)** _(Oracle)_|Same as COALESCE|—|—|
|**GREATEST() / LEAST()**|Ignore NULLs unless all are NULL|`GREATEST(NULL, 10, 5)`|`10`|
|**CASE WHEN ... THEN ... END**|Handle NULL manually|`CASE WHEN value IS NULL THEN 0 ELSE value END`|custom|
|**SUM() / COUNT() / AVG()**|**Ignore NULLs automatically** in aggregates|`AVG(NULL, 5, 10)`|`7.5`|

---

## 🧮 **3️⃣ Advanced PostgreSQL-Specific**

|Function|Description|Example|Result|
|---|---|---|---|
|**COALESCE() + NULLIF() combo**|Prevent divide-by-zero|`value / NULLIF(divisor, 0)`|NULL instead of error|
|**LAG() / LEAD() + IGNORE NULLS**|(from PostgreSQL 15+) skip NULLs|`LAG(col) IGNORE NULLS OVER (...)`|returns previous non-null|
|**FILTER (WHERE ...)**|In aggregates, exclude NULLs|`COUNT(value) FILTER (WHERE value IS NOT NULL)`|counts non-null only|
|**SET default NULL behavior**|with `DEFAULT NULL`, `NOT NULL` in table schema|—|—|

---

## 📏 **4️⃣ Rules**

1. `NULL` ≠ `NULL` → comparison fails (use `IS NULL`)
    
2. `NULL + number` = `NULL`, same for most operations
    
3. `COALESCE` is your best friend to **replace NULLs safely**
    
4. Aggregate functions (like `SUM`, `AVG`, etc.) **ignore NULLs**
    
5. `COUNT(*)` counts all rows, `COUNT(column)` skips NULLs
    
6. `NULLIF(a, b)` prevents division or logic errors
    
7. PostgreSQL treats empty string `''` and `NULL` **as different**
    
8. `CASE` can override NULL logic manually
    

---

## 🧠 **5️⃣ Practice Tip**

Example combining them all:

```sql
SELECT 
    name,
    COALESCE(salary, 0) AS safe_salary,
    salary / NULLIF(work_hours, 0) AS rate,
    CASE WHEN bonus IS NULL THEN 'No bonus' ELSE bonus END AS bonus_status
FROM employees;
```

✅ Handles:

- Missing salary
    
- Division by zero
    
- Bonus NULLs gracefully
    

---


#### Tags : [[1 - SQL 🦬]]