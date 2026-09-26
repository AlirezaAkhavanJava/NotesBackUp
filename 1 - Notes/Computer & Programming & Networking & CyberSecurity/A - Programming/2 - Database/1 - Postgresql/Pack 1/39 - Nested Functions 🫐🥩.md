


## **1. BASIC LEVEL**

###  Definition

A **nested function** is when you **use the output of one function as the input of another**.

- Functions can be **built-in** or **user-defined**.
    
- Nesting can be **row-level, aggregate, or string functions**.
    

**Example:**

```sql
SELECT UPPER(TRIM(name)) FROM employees;
```

- `TRIM(name)` removes spaces first, then `UPPER(...)` converts the result to uppercase.
    
- Nesting is evaluated **inside-out**: innermost function executes first.
    

---

##  **2. INTERMEDIATE LEVEL**

### 🔹 Rules for Nested Functions

1. **Output Type Must Match Input Type**
    
    - The outer function must accept the type returned by the inner function.
        

```sql
-- Correct
SELECT ROUND(LENGTH(name),0) FROM employees;  -- LENGTH returns INT, ROUND accepts numeric
```

```sql
-- Incorrect
SELECT UPPER(123); -- Error: UPPER expects text
```

2. **Order of Execution**
    
    - Functions execute **from innermost to outermost**.
        
    
    ```sql
    SELECT SUBSTRING(UPPER(name) FROM 1 FOR 3) FROM employees;
    ```
    
    - First: `UPPER(name)` → uppercase
        
    - Then: `SUBSTRING(... FROM 1 FOR 3)` → first 3 chars
        
3. **NULL Propagation**
    
    - If **inner function returns NULL**, outer function may also return NULL (unless handled).
        

```sql
SELECT UPPER(TRIM(NULL)); -- Returns NULL
```

- Use `COALESCE` to prevent NULL propagation:
    

```sql
SELECT UPPER(TRIM(COALESCE(name,'unknown'))) FROM employees;
```

4. **Data Type Compatibility**
    
    - Always ensure that the **inner function’s output type is compatible with the outer function’s input type**.
        
5. **Parentheses Are Mandatory**
    
    - To avoid ambiguity, always wrap functions with parentheses correctly.
        

```sql
SELECT ROUND(AVG(salary),2) FROM employees; -- Valid
```

---

### Examples of Nested Functions

1. **String + Case**
    

```sql
SELECT INITCAP(TRIM(LOWER(name))) FROM employees;
```

- Removes spaces → converts to lowercase → capitalizes first letters.
    

2. **Date + String**
    

```sql
SELECT TO_CHAR(NOW(),'YYYY-MM-DD') AS today;
```

- `NOW()` → current timestamp
    
- `TO_CHAR(...)` → formatted string
    

3. **Aggregation + Round**
    

```sql
SELECT ROUND(AVG(salary),2) FROM employees;
```

- `AVG(salary)` → average numeric value
    
- `ROUND(...,2)` → round to 2 decimal places
    

4. **Mathematics + String**
    

```sql
SELECT CONCAT('Salary: ', ROUND(salary*1.1,2)) FROM employees;
```

- Computes salary increase → rounds → converts to string → concatenates
    

---

##  **3. ADVANCED LEVEL**

###  Nested User-Defined Functions

- You can nest **UDFs**, just like built-in functions:
    

```sql
CREATE FUNCTION increase_salary(s NUMERIC) RETURNS NUMERIC AS $$
BEGIN
   RETURN s * 1.1;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION salary_label(s NUMERIC) RETURNS TEXT AS $$
BEGIN
   RETURN 'Salary: ' || ROUND(increase_salary(s),2);
END;
$$ LANGUAGE plpgsql;

SELECT salary_label(salary) FROM employees;
```

---

### 🔹 Rules for Nested UDFs

1. Inner function must **return compatible type** for outer function
    
2. Keep **function call depth reasonable** for performance
    
3. Be aware of **NULL propagation** — inner function NULL → outer function NULL
    
4. Nested **IMMUTABLE / VOLATILE** functions obey volatility rules:
    
    - Outer function volatility must be **at least as volatile** as inner function
        

---

### 🔹 Nesting with Aggregates

- Aggregates can be nested **with scalar functions**, but you **cannot nest aggregate inside aggregate directly** in PostgreSQL:
    

```sql
-- Correct
SELECT ROUND(AVG(salary),2) FROM employees;

-- Incorrect (cannot do SUM(AVG(...)) directly)
```

- Solution: Use **subqueries**:
    

```sql
SELECT SUM(avg_salary) 
FROM (SELECT AVG(salary) AS avg_salary FROM employees GROUP BY dept_id) t;
```

---

## ⚔️ **4. COMMON MISTAKES / RULES**

|Mistake|Rule to Fix|
|---|---|
|Wrong type for outer function|Ensure inner function output matches outer function input|
|NULL propagation|Use `COALESCE` if outer function should not return NULL|
|Deep nesting|Avoid very deep nesting for performance reasons|
|Aggregates inside aggregates|Use subqueries or CTEs to handle nested aggregates|
|Volatility mismatch|Outer function volatility ≥ inner function volatility|

---

## 🚀 **5. Practical Use Cases**

1. **Clean and Capitalize Names**
    

```sql
SELECT INITCAP(TRIM(LOWER(name))) FROM employees;
```

2. **Formatted Salary**
    

```sql
SELECT CONCAT('Salary: $', ROUND(salary*1.05,2)) FROM employees;
```

3. **Date + String Transformation**
    

```sql
SELECT CONCAT('Today is ', TO_CHAR(NOW(),'Day, DD Mon YYYY')) AS today;
```

4. **Nested User-Defined Functions**
    

- Compute tax + label: `SELECT salary_label(salary) FROM employees;`
    

---

## 📋 **6. Quick Rules / Cheat Sheet**

1. **Innermost function executes first**
    
2. **Outer function input type must match inner function output type**
    
3. **NULL from inner → NULL outer unless handled**
    
4. **Parentheses are mandatory**
    
5. **Nesting depth should be reasonable** for performance
    
6. **Aggregates cannot directly nest inside aggregates**; use subqueries
    
7. **Volatility of outer function ≥ inner function**
    
8. **User-defined functions can be nested like built-in functions**
    

---

🐐 **Mental Model:**

- Think of nested functions as **Russian dolls**: innermost executes → passes result to next → continues outward.
    
- Always **check type and NULL flow**, or the dolls break.
    

---



#### Tags : [[1 - SQL 🦬]]