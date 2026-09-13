
## **1. NULLs in Joins**

When working with **joins**, NULLs can behave unexpectedly because **`NULL = NULL` is false** in SQL. This affects which rows appear in your results.

---

### **1.1 INNER JOIN**

- Excludes rows where join columns are NULL.
    

```sql
SELECT e.name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.id;
```

- Employees with `department_id = NULL` are **excluded**.
    
- **Tip:** Use `IS NOT DISTINCT FROM` for NULL-safe joins if needed.
    

```sql
SELECT e.name, d.dept_name
FROM employees e
JOIN departments d ON e.department_id IS NOT DISTINCT FROM d.id;
```

---

### **1.2 LEFT JOIN / RIGHT JOIN / FULL OUTER JOIN**

- Outer joins **preserve rows from one or both tables**, filling unmatched columns with NULL.
    

```sql
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id;
```

- Employees without a department → `dept_name = NULL`
    
- You can replace NULLs with `COALESCE`:
    

```sql
SELECT e.name, COALESCE(d.dept_name, 'No Department') AS dept_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id;
```

---

### **1.3 NULL-safe joins**

- Use `IS NOT DISTINCT FROM` to treat NULL = NULL as TRUE:
    

```sql
SELECT e.name, d.dept_name
FROM employees e
JOIN departments d ON e.department_id IS NOT DISTINCT FROM d.id;
```

- Useful if both tables may have NULLs in the join column and you want them to match.
    

---

## **2. NULLs in UNION / UNION ALL**

### **2.1 UNION vs UNION ALL**

- `UNION` → removes duplicates
    
- `UNION ALL` → keeps all rows
    

### **2.2 How NULLs behave**

- **NULLs are treated as equal** when checking duplicates for `UNION`.
    
- Example:
    

```sql
SELECT department_id FROM employees
UNION
SELECT department_id FROM departments;
```

- If `department_id` is NULL in both tables → **only one NULL** appears in the result.
    
- `UNION ALL` → all NULLs appear, duplicates not removed.
    

```sql
SELECT department_id FROM employees
UNION ALL
SELECT department_id FROM departments;
```

---

### **2.3 Replacing NULLs before UNION**

- Often useful to replace NULLs with a sentinel value:
    

```sql
SELECT COALESCE(department_id, -1) AS dept_id FROM employees
UNION
SELECT COALESCE(department_id, -1) AS dept_id FROM departments;
```

- Ensures all NULLs are treated consistently.
    

---

### **2.4 Ordering with NULLs**

- Use `NULLS FIRST` or `NULLS LAST`:
    

```sql
SELECT department_id
FROM (
    SELECT department_id FROM employees
    UNION
    SELECT department_id FROM departments
) AS combined
ORDER BY department_id NULLS LAST;
```

---

## **3. Practical Tips for Handling NULLs in Joins and Unions**

1. **Outer joins** → always expect NULLs in unmatched columns.
    
2. **Replace NULLs** with `COALESCE` for clarity.
    
3. **NULL-safe comparisons** → `IS NOT DISTINCT FROM` if NULLs need to match.
    
4. **UNION** → removes duplicate NULLs automatically.
    
5. **UNION ALL** → preserves all NULLs.
    
6. **Aggregates** → functions like `SUM`, `COUNT`, `AVG` ignore NULLs by default, but `COUNT(*)` counts all rows.
    

---

## **4. Combined Example**

```sql
-- Employees and Departments combined
SELECT e.name, COALESCE(d.dept_name, 'No Dept') AS dept_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id

UNION

SELECT 'Unknown Employee', COALESCE(d.dept_name, 'No Dept') AS dept_name
FROM departments d
WHERE NOT EXISTS (
    SELECT 1 FROM employees e WHERE e.department_id IS NOT DISTINCT FROM d.id
)
ORDER BY dept_name;
```

- Combines employees and departments
    
- Handles NULLs in department_id and unmatched rows
    
- Replaces NULLs for clarity
    

---

## ✅ **Goat Mode TL;DR**

- **Joins:** NULLs do **not match** by default; outer joins preserve unmatched rows as NULL.
    
- **Use `COALESCE`** to replace NULLs.
    
- **NULL-safe comparisons:** `IS NOT DISTINCT FROM`.
    
- **UNION:** removes duplicate NULLs
    
- **UNION ALL:** keeps all NULLs
    
- Always plan for NULLs in **filters, joins, and aggregations** to avoid surprises.
    



### Tags : [[1 - SQL 🥞]]