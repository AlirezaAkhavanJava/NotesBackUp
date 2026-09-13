


# 🧩 **SQL / PostgreSQL: CASE Statement**

---

## **1. Definition**

The `CASE` statement lets you apply **conditional logic inside SQL queries**, similar to `if / else if / else` in programming languages.

It’s used inside:

- `SELECT`
    
- `UPDATE`
    
- `ORDER BY`
    
- `WHERE`
    

---

## **2. Syntax**

### **2.1 Simple CASE**

Compare one expression to several possible values.

```sql
CASE expression
    WHEN value1 THEN result1
    WHEN value2 THEN result2
    ELSE resultN
END
```

---

### **2.2 Searched CASE**

Evaluate **conditions** instead of comparing to one expression.

```sql
CASE
    WHEN condition1 THEN result1
    WHEN condition2 THEN result2
    ELSE resultN
END
```

✅ **PostgreSQL supports both.**

---

## **3. Basic Example**

```sql
SELECT 
    name,
    department_id,
    CASE department_id
        WHEN 1 THEN 'HR'
        WHEN 2 THEN 'Finance'
        WHEN 3 THEN 'Engineering'
        ELSE 'Unknown'
    END AS department_name
FROM employees;
```

➡ Translates department IDs into human-readable names.

---

## **4. Conditional (Searched CASE)**

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

## **5. CASE in ORDER BY**

```sql
SELECT name, department_id
FROM employees
ORDER BY 
    CASE 
        WHEN department_id = 3 THEN 1
        WHEN department_id = 2 THEN 2
        ELSE 3
    END;
```

➡ Custom sorting (Engineering first, then Finance, etc.).

---

## **6. CASE in WHERE**

You can’t directly use `CASE` to replace `WHERE`,  
but you can use it inside **conditions**:

```sql
SELECT *
FROM employees
WHERE 
    CASE 
        WHEN department_id = 1 THEN salary > 50000
        ELSE salary > 20000
    END;
```

⚠️ However, this form isn’t portable; better to use **logical ORs**.

---

## **7. CASE in UPDATE**

```sql
UPDATE employees
SET bonus = 
    CASE 
        WHEN performance_rating = 'A' THEN 1000
        WHEN performance_rating = 'B' THEN 500
        ELSE 0
    END;
```

➡ Adjusts bonus based on rating.

---

## **8. CASE with NULLs**

Remember: `CASE` uses **“equals” logic**, so if an expression is `NULL`,  
it **won’t match** any `WHEN` unless you explicitly check it.

```sql
SELECT 
    name,
    CASE 
        WHEN department_id IS NULL THEN 'No Department'
        ELSE 'Assigned'
    END AS dept_status
FROM employees;
```

---

## **9. Nested CASE Statements**

You can nest them — though readability matters.

```sql
SELECT 
    name,
    CASE 
        WHEN salary > 70000 THEN 
            CASE WHEN performance_rating = 'A' THEN 'Star' ELSE 'Solid' END
        ELSE 'Average'
    END AS employee_status
FROM employees;
```

---

## **10. CASE in Aggregations**

```sql
SELECT 
    department_id,
    SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS female_count
FROM employees
GROUP BY department_id;
```

➡ Count conditionally by gender or category.

---

## **11. Practical Use Cases**

|Use Case|Example|
|---|---|
|Categorizing values|Salary tiers, grade levels|
|Conditional aggregation|Count or sum specific types|
|Custom sorting|Prioritize special values|
|Conditional updates|Set columns differently per rule|
|Data cleaning|Replace invalid or NULL data|

---

## ✅ **Goat Mode TL;DR 🐐**

- `CASE` = SQL’s **if / else**
    
- Two types:
    
    - 🟢 **Simple:** compare a single expression
        
    - 🧠 **Searched:** check full conditions
        
- Works in `SELECT`, `UPDATE`, `ORDER BY`, `GROUP BY`
    
- Always use `ELSE` for safety
    
- Be explicit with `IS NULL`
    
- Great for categorizing, mapping IDs, or custom sorting
    


### Tags : [[1 - SQL 🥞]]