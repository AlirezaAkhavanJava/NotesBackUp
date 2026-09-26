

## **1. Overview**

Both **aggregate** and **analytical** functions perform calculations across **multiple rows**, but they work differently:

|Type|Purpose|Result Scope|Keyword|
|---|---|---|---|
|**Aggregate Functions**|Combine multiple rows into **one result**|One output per group|`GROUP BY`|
|**Analytical (Window) Functions**|Perform calculations across related rows but **keep each row**|One output per row|`OVER()`|

---

## **2. Aggregate Functions (GROUP BY)**

Aggregate functions summarize data by **groups**.  
Used mostly in reporting and summaries.

### **Common Aggregate Functions**

|Function|Description|
|---|---|
|`COUNT()`|Counts rows|
|`SUM()`|Adds values|
|`AVG()`|Averages values|
|`MAX()` / `MIN()`|Finds highest/lowest|
|`STRING_AGG()`|Concatenates text values|
|`ARRAY_AGG()`|Combines values into an array|

---

### **Example 1: Basic Aggregation**

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count,
    AVG(salary) AS avg_salary,
    MAX(salary) AS max_salary,
    MIN(salary) AS min_salary
FROM employees
GROUP BY department_id;
```

- Groups data by `department_id`.
    
- One result per department.
    

---

### **Example 2: Conditional Aggregation**

```sql
SELECT
    department_id,
    COUNT(*) FILTER (WHERE gender = 'M') AS male_count,
    COUNT(*) FILTER (WHERE gender = 'F') AS female_count
FROM employees
GROUP BY department_id;
```

- Uses **FILTER** for condition-based aggregation.
    
- PostgreSQL-specific and cleaner than `CASE`.
    

---

### **Example 3: Aggregate + HAVING**

```sql
SELECT
    department_id,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 50000;
```

- Filters **after aggregation**.
    
- `HAVING` acts like `WHERE` for grouped results.
    

---

## **3. Analytical (Window) Functions**

Analytical or **window functions** allow you to:

- Compute aggregates **without collapsing rows**
    
- Use **OVER()** to define a “window” of rows to compute over
    

### **Common Analytical Functions**

|Function|Purpose|
|---|---|
|`ROW_NUMBER()`|Sequential numbering|
|`RANK()` / `DENSE_RANK()`|Ranking with or without gaps|
|`SUM()` / `AVG()` / `COUNT()`|Running or partitioned totals|
|`LAG()` / `LEAD()`|Access previous/next row values|
|`FIRST_VALUE()` / `LAST_VALUE()`|Capture boundary values|
|`NTILE(n)`|Divide into n equal buckets|

---

### **Example 4: Basic Window Function**

```sql
SELECT
    name,
    department_id,
    salary,
    AVG(salary) OVER (PARTITION BY department_id) AS dept_avg_salary
FROM employees;
```

- Computes **average salary per department**,  
    but keeps **each employee’s row**.
    

---

### **Example 5: Ranking**

```sql
SELECT
    name,
    department_id,
    salary,
    RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rank_in_dept
FROM employees;
```

- Ranks employees by salary **within their department**.
    

---

### **Example 6: Running Total**

```sql
SELECT
    department_id,
    name,
    salary,
    SUM(salary) OVER (PARTITION BY department_id ORDER BY salary) AS running_total
FROM employees;
```

- Adds a **progressive sum** of salaries within each department.
    

---

### **Example 7: LAG / LEAD (Compare Rows)**

```sql
SELECT
    name,
    salary,
    LAG(salary, 1) OVER (ORDER BY hire_date) AS prev_salary,
    LEAD(salary, 1) OVER (ORDER BY hire_date) AS next_salary
FROM employees;
```

- Accesses previous/next row’s salary — great for **trend analysis**.
    

---

### **Example 8: Combining Aggregate and Analytical**

```sql
SELECT
    department_id,
    name,
    salary,
    SUM(salary) OVER (PARTITION BY department_id) AS total_salary,
    salary * 100.0 / SUM(salary) OVER (PARTITION BY department_id) AS percent_share
FROM employees;
```

- Combines **window SUM()** with calculations per row.
    
- Gives each employee’s percentage of department total.
    

---

## **4. Key Differences: Aggregate vs Analytical**

|Feature|Aggregate|Analytical|
|---|---|---|
|Collapses rows|✅ Yes|❌ No|
|Uses GROUP BY|✅ Yes|❌ Optional|
|Keeps detail rows|❌ No|✅ Yes|
|Keyword|—|`OVER()`|
|Use case|Summaries|Rankings, trends, per-row stats|

---

## **5. Pro Tips 🧠**

- Use **Aggregate** when you need one result per group.
    
- Use **Analytical** when you need row-level insights with group context.
    
- Combine both for **advanced dashboards or reports**.
    
- You can’t use **window functions** directly in `WHERE` — wrap them in a subquery if needed.
    

---

## ✅ **Goat Mode TL;DR 🐐**

- **Aggregate = collapse rows into summaries** (`GROUP BY`)
    
- **Analytical = calculate over windows, keep all rows** (`OVER()`)
    
- Use both together for **powerful analysis**
    
- PostgreSQL adds magic with `FILTER`, `PARTITION BY`, `ORDER BY`, `LAG/LEAD`
    
- Example use cases:
    
    - Totals per department
        
    - Running averages
        
    - Rank & percentile
        
    - Previous vs next value comparisons
        

---

Do you want me to make a **PostgreSQL “Aggregate vs Analytical Functions Cheat Sheet”** next — with all common functions, short descriptions, and mini examples side by side for instant recall?
### Tags : [[1 - SQL 🦬]]