

## **📘 Beginner Level — Basic HAVING**

### **1. What is `HAVING`**

- `HAVING` filters groups created by **`GROUP BY`**.
    
- Similar to how `WHERE` filters individual rows, but `HAVING` works on aggregated results.
    

**Syntax:**

```sql
SELECT column1, AGGREGATE_FUNCTION(column2)
FROM table_name
GROUP BY column1
HAVING condition;
```



### **2. Basic Example**

```sql
SELECT country, COUNT(*)
FROM students
GROUP BY country
HAVING COUNT(*) > 10;
```

→ Only returns countries with more than 10 students.

---

### **3. Difference between WHERE and HAVING**

- **WHERE** filters rows before aggregation.
    
- **HAVING** filters after aggregation.
    

Example:

```sql
SELECT country, COUNT(*)
FROM students
WHERE age > 18         -- Filter rows first
GROUP BY country
HAVING COUNT(*) > 5;  -- Filter groups later
```



---

## **📗 Intermediate Level — HAVING with Expressions**

### **1. Using aggregate functions**

```sql
SELECT country, AVG(age) AS avg_age
FROM students
GROUP BY country
HAVING AVG(age) > 20;
```

→ Only returns countries where average student age is above 20.



### **2. Multiple conditions**

```sql
SELECT country, COUNT(*) AS total_students
FROM students
GROUP BY country
HAVING COUNT(*) > 10 AND SUM(age) > 500;
```



### **3. HAVING without GROUP BY**

Technically allowed in some SQL dialects, including PostgreSQL, but rare.

```sql
SELECT COUNT(*)
FROM students
HAVING COUNT(*) > 10;
```

→ Filters after aggregation without grouping.

---


## **📙 Advanced Level — HAVING Tricks**

### **1. HAVING with GROUPING SETS**

```sql
SELECT country, gender, COUNT(*)
FROM students
GROUP BY GROUPING SETS ((country, gender), (country))
HAVING COUNT(*) > 5;
```

→ Filters across grouped sets.



### **2. HAVING with Subqueries**

```sql
SELECT country, COUNT(*) AS student_count
FROM students
GROUP BY country
HAVING COUNT(*) > (
    SELECT AVG(student_count)
    FROM (
        SELECT COUNT(*) AS student_count
        FROM students
        GROUP BY country
    ) sub
);
```

→ Filters groups based on a calculated average.


### **3. HAVING with Aliases**

```sql
SELECT country, COUNT(*) AS total
FROM students
GROUP BY country
HAVING total > 10; -- PostgreSQL allows aliases here
```



### **4. HAVING with Window Functions**

Since `HAVING` works after aggregation, combining it with window functions can be powerful:

```sql
SELECT country, COUNT(*) AS total,
       RANK() OVER (ORDER BY COUNT(*) DESC) AS rank
FROM students
GROUP BY country
HAVING COUNT(*) > 5;
```



---

## **🚀 Tips & Tricks**

- `HAVING` always comes **after GROUP BY**.
    
- You can use aggregate functions only in HAVING, not in WHERE.
    
- If no GROUP BY exists, HAVING acts like a filter on the aggregated result of the whole table.
    
- For better performance, filter rows first with WHERE before grouping and using HAVING.
    
- Use parentheses for complex HAVING conditions.
    

---

💡 **Quick rule of thumb:**

- `WHERE` → filters **rows**
    
- `HAVING` → filters **groups**
    


#### Tags : [[1 - SQL 🥞]]