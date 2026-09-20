

# **SQL / PostgreSQL: `CASE…WHEN` Statement**

## **1. Definition**

The `CASE` statement is SQL’s way of doing conditional logic. It allows you to evaluate conditions and return values based on them. Essentially, it’s like an **if-else statement** in programming.

---

## **2. Syntax**

### **Simple CASE**

Used when you compare a column or expression to fixed values:

```sql
CASE column_name
    WHEN value1 THEN result1
    WHEN value2 THEN result2
    ...
    ELSE default_result
END
```

**Example:**

```sql
SELECT name,
       grade,
       CASE grade
           WHEN 'A' THEN 'Excellent'
           WHEN 'B' THEN 'Good'
           WHEN 'C' THEN 'Average'
           ELSE 'Needs Improvement'
       END AS performance
FROM students;
```

- `grade` is checked against `'A'`, `'B'`, `'C'`.
    
- If no match, `ELSE` is returned.
    

---

### **Searched CASE**

Used when you have complex conditions or expressions:

```sql
CASE
    WHEN condition1 THEN result1
    WHEN condition2 THEN result2
    ...
    ELSE default_result
END
```

**Example:**

```sql
SELECT name,
       score,
       CASE
           WHEN score >= 90 THEN 'A'
           WHEN score >= 75 THEN 'B'
           WHEN score >= 50 THEN 'C'
           ELSE 'F'
       END AS grade
FROM exams;
```

- Here, conditions like `score >= 90` are evaluated.
    
- Useful for ranges or multiple criteria.
```SQL
SELECT * , COUNT(*) OVER(PARTITION BY country ORDER BY mark)
FROM (SELECT  name , 
			country , 
			mark ,
			CASE 
				WHEN mark BETWEEN 9 AND 10 THEN 'A'
				WHEN mark BETWEEN 8 AND 9 THEN 'B'
				WHEN mark BETWEEN 7 AND 8 THEN 'C'
				WHEN mark BETWEEN 6 AND 7 THEN 'D'
				ELSE 'F'
			END as status
	FROM student)
WHERE status = 'F'

```

---

## **3. Key Points**

1. `CASE` **returns a value**, it does not change the data in the table.
    
2. `ELSE` is optional; if omitted, `CASE` returns `NULL` when no conditions match.
    
3. Can be used in:
    
    - `SELECT` statements
        
    - `ORDER BY` clauses
        
    - `GROUP BY` with expressions
        
    - `WHERE` clause (though `CASE` must return a boolean)
        

---

## **4. Advanced Usage**

### **4.1 Using CASE in ORDER BY**

You can sort dynamically based on conditions:

```sql
SELECT name, grade
FROM students
ORDER BY CASE grade
             WHEN 'A' THEN 1
             WHEN 'B' THEN 2
             ELSE 3
         END;
```

- `'A'` comes first, then `'B'`, then others.
    

---

### **4.2 Nested CASE**

You can nest `CASE` statements for multiple layers of logic:

```sql
SELECT name, score,
       CASE
           WHEN score >= 80 THEN
               CASE
                   WHEN score >= 90 THEN 'Excellent'
                   ELSE 'Good'
               END
           ELSE 'Needs Improvement'
       END AS performance
FROM exams;
```

- Inner `CASE` handles fine-grained grading.
    

---

### **4.3 Using CASE in Aggregates**

You can use `CASE` in aggregation for conditional counts or sums:

```sql
SELECT
    COUNT(CASE WHEN grade = 'A' THEN 1 END) AS total_A,
    COUNT(CASE WHEN grade = 'B' THEN 1 END) AS total_B
FROM students;
```

- Counts how many students got `A` or `B`.
    

```sql
SELECT
    SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) AS active_users
FROM users;
```

- Sums only rows matching a condition.
    

---

### **4.4 CASE vs COALESCE / NULLIF**

- `COALESCE(expr1, expr2, ...)` → returns first non-NULL value.
    
- `NULLIF(expr1, expr2)` → returns NULL if expr1 = expr2, else expr1.
    
- `CASE` is more flexible because it handles complex logic, not just nulls.
    

---

## **5. PostgreSQL-Specific Notes**

1. PostgreSQL fully supports both **simple** and **searched CASE**.
    
2. Can be used anywhere an expression is allowed.
    
3. PostgreSQL evaluates conditions in order, stopping at the first true condition (short-circuiting).
    
4. Works perfectly with `FILTER` in aggregates:
    

```sql
SELECT COUNT(*) FILTER (WHERE status='active') AS active_users
FROM users;
```

- `FILTER` is sometimes cleaner than `CASE` for aggregates.
    

---

### **6. Best Practices**

- Always use `ELSE` to avoid unexpected `NULL`s.
    
- Keep conditions in order of likelihood for performance (first match is returned).
    
- Prefer **searched CASE** for ranges or multiple criteria.
    
- Use **simple CASE** for exact matches to improve readability.
    

---

✅ **TL;DR Goat Summary:**  
`CASE` = SQL’s **if-else**.

- **Simple CASE:** exact match → `WHEN value THEN result`
    
- **Searched CASE:** conditional logic → `WHEN condition THEN result`
    
- Use in `SELECT`, `ORDER BY`, `WHERE`, aggregates.
    
- Can nest, use in sums, counts, or filters.
    

---


### Tags : [[1 - SQL 🥞]]