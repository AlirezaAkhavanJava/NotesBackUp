


# **SQL / PostgreSQL: Conditions**


## **1. Basic WHERE Conditions**

- Filter rows based on a condition.
    
- Syntax:
    

```sql
SELECT column1, column2
FROM table_name
WHERE condition;
```

### **1.1 Examples**

```sql
-- Simple equality
SELECT * FROM employees WHERE department_id = 1;

-- Inequality
SELECT * FROM employees WHERE salary > 50000;

-- Range
SELECT * FROM employees WHERE age BETWEEN 25 AND 35;

-- Set membership
SELECT * FROM employees WHERE department_id IN (1, 2, 3);
```

---

## **2. Logical Operators**

|Operator|Description|
|---|---|
|AND|All conditions must be true|
|OR|At least one condition must be true|
|NOT|Negates a condition|

**Examples:**

```sql
-- Multiple conditions
SELECT * FROM employees
WHERE department_id = 1 AND salary > 50000;

-- OR condition
SELECT * FROM employees
WHERE department_id = 1 OR department_id = 2;

-- Negation
SELECT * FROM employees
WHERE NOT department_id = 3;
```

---

## **3. Pattern Matching**

### **3.1 LIKE**

- `%` → any sequence of characters
    
- `_` → single character
    

```sql
SELECT * FROM employees
WHERE name LIKE 'A%';   -- names starting with 'A'

SELECT * FROM employees
WHERE name LIKE '_lice'; -- matches 'Alice'
```

### **3.2 ILIKE** (case-insensitive in PostgreSQL)

```sql
SELECT * FROM employees
WHERE name ILIKE 'a%';  -- matches 'Alice', 'adam'
```

### **3.3 SIMILAR TO** (regex-like)

```sql
SELECT * FROM employees
WHERE name SIMILAR TO '(Alice|Bob)';
```

---

## **4. NULL Conditions**

- Use `IS NULL` / `IS NOT NULL`:
    

```sql
SELECT * FROM employees
WHERE department_id IS NULL;     -- employees without department

SELECT * FROM employees
WHERE department_id IS NOT NULL; -- employees with department
```

- Avoid `= NULL` or `<> NULL` → **doesn’t work**
    

---

## **5. Conditional Expressions**

### **5.1 CASE Expression**

- Return values based on conditions.
    

```sql
SELECT
    name,
    salary,
    CASE
        WHEN salary < 30000 THEN 'Low'
        WHEN salary BETWEEN 30000 AND 70000 THEN 'Medium'
        ELSE 'High'
    END AS salary_level
FROM employees;
```

---

### **5.2 COALESCE**

- Handles NULLs in conditions:
    

```sql
SELECT name,
       COALESCE(department_id, 0) AS dept_id
FROM employees
WHERE COALESCE(department_id, 0) = 0;  -- finds employees without department
```

---

### **5.3 NULLIF**

- Returns NULL if two values are equal; useful in conditions:
    

```sql
SELECT name, salary / NULLIF(bonus,0) AS ratio
FROM employees
WHERE NULLIF(bonus,0) IS NOT NULL;
```

- Prevents division by zero.
    

---

## **6. Advanced Conditions**

### **6.1 EXISTS / NOT EXISTS**

```sql
-- Employees in departments that exist
SELECT * FROM employees e
WHERE EXISTS (
    SELECT 1 FROM departments d
    WHERE d.id = e.department_id
);

-- Employees not in any department
SELECT * FROM employees e
WHERE NOT EXISTS (
    SELECT 1 FROM departments d
    WHERE d.id = e.department_id
);
```

### **6.2 ANY / ALL**

- Compare against a set of values.
    

```sql
SELECT * FROM employees
WHERE salary > ANY (SELECT salary FROM employees WHERE department_id = 1);

SELECT * FROM employees
WHERE salary > ALL (SELECT salary FROM employees WHERE department_id = 1);
```

---

### **6.3 Combining with Joins**

```sql
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id
WHERE d.dept_name IS NOT NULL AND e.salary > 50000;
```

- Filters after the join, can handle NULLs.
    

---

## **7. Key Notes**

1. **Use IS NULL / IS NOT NULL** for NULLs.
    
2. **CASE** → for conditional logic inside SELECT.
    
3. **COALESCE** → replace NULLs in conditions.
    
4. **EXISTS / NOT EXISTS** → check existence of related rows.
    
5. **ANY / ALL** → compare with sets.
    
6. Combine **logical operators** (`AND`, `OR`, `NOT`) for complex conditions.
    

---

## ✅ **Goat Mode TL;DR**

- `WHERE` → basic filtering
    
- `AND / OR / NOT` → combine conditions
    
- `IS NULL / IS NOT NULL` → check NULLs
    
- `LIKE / ILIKE / SIMILAR TO` → pattern matching
    
- `CASE` → conditional values in SELECT
    
- `COALESCE / NULLIF` → handle NULLs safely
    
- `EXISTS / NOT EXISTS` → check related rows
    
- `ANY / ALL` → compare against a list or subquery
    



### Tags : [[1 - SQL 🦬]]