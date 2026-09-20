


# 🧠 **PostgreSQL Window Functions: The Complete Guide**

---

## **1. What is a Window Function?**

**Concept / Purpose:**

- A **window function** performs a calculation across a set of rows that are **related to the current row**, but **does not collapse rows** like aggregate functions with `GROUP BY`.
    
- It’s used for **ranking, running totals, moving averages, percentiles, comparisons**, etc.
    

Think of it like: you’re looking at a “window” of rows around the current row to calculate something, without losing the row itself.

---

## **2. Basic Syntax**

```sql
FUNCTION_NAME(arguments) OVER (
    [PARTITION BY column(s)]   -- optional
    [ORDER BY column(s) [ASC|DESC]]  -- optional
    [ROWS | RANGE frame specification]  -- optional
)
```

- **FUNCTION_NAME** → `SUM`, `AVG`, `COUNT`, `ROW_NUMBER`, `RANK`, etc.
    
- **OVER()** → defines the **window** for calculation. Without `OVER()`, it behaves like a regular aggregate.
    
- **PARTITION BY** → splits rows into groups (like `GROUP BY`) but keeps each row.
    
- **ORDER BY** → orders rows inside the window for ranking or cumulative calculations.
    
- **ROWS / RANGE** → defines exactly which rows are included in the window frame.
    

---

### **Step-by-Step Explanation**

- `PARTITION BY` → Think: “I want separate calculations for each group.”
    
- `ORDER BY` → Within the partition, how should the rows be sequenced?
    
- `ROWS` → Define physical row positions relative to current row (like “previous 2 rows”).
    
- `RANGE` → Define logical range based on ORDER BY value (all rows with same ORDER BY value).
    

---

## **3. ROW_NUMBER()**

- **Purpose:** Sequential numbering of rows **within a partition or entire table**.
    

```sql
SELECT
    name,
    department_id,
    ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS row_num
FROM employees;
```

**Explanation:**

- `PARTITION BY department_id` → separate numbering **per department**
    
- `ORDER BY salary DESC` → highest salary gets row 1
    
- Keeps all employee rows; just adds a column `row_num`
    

**Real-world use:** Identify top N employees per department.

---

## **4. RANK() and DENSE_RANK()**

- **Purpose:** Ranking rows with or without gaps for ties.
    

```sql
SELECT
    name,
    salary,
    RANK() OVER (ORDER BY salary DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rank
FROM employees;
```

**Explanation:**

- `RANK()` → If 2 employees tie at salary 100k, both are rank 1, next rank = 3 (gap)
    
- `DENSE_RANK()` → If 2 tie at 100k, both rank 1, next rank = 2 (no gap)
    
- Useful for **leaderboards or grading systems**.
    

---

## **5. NTILE(n)**

- **Purpose:** Divides rows into **n buckets**.
    

```sql
SELECT
    name,
    salary,
    NTILE(4) OVER (ORDER BY salary DESC) AS quartile
FROM employees;
```

**Explanation:**

- Divides employees into **4 salary quartiles**
    
- Rows are distributed as evenly as possible
    
- Useful for **percentiles or bucketing metrics**
    

---

## **6. LAG() and LEAD()**

- **Purpose:** Access **previous or next row value** for comparisons.
    

```sql
SELECT
    name,
    salary,
    LAG(salary, 1) OVER (ORDER BY hire_date) AS prev_salary,
    LEAD(salary, 1) OVER (ORDER BY hire_date) AS next_salary
FROM employees;
```

**Explanation:**

- `LAG(salary, 1)` → value from **1 row before current row**
    
- `LEAD(salary, 1)` → value from **1 row after current row**
    
- Great for **trend analysis**, salary changes, or gaps between rows
    

---

## **7. FIRST_VALUE() and LAST_VALUE()**

- **Purpose:** Get **first or last value** in a window.
    

```sql
SELECT
    name,
    salary,
    FIRST_VALUE(salary) OVER (PARTITION BY department_id ORDER BY salary DESC) AS highest_salary,
    LAST_VALUE(salary) OVER (
        PARTITION BY department_id 
        ORDER BY salary ASC 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS lowest_salary
FROM employees;
```

**Explanation:**

- `FIRST_VALUE()` → first row in ordered partition
    
- `LAST_VALUE()` → last row (need full window frame defined)
    
- Without `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`, LAST_VALUE might not return what you expect
    

---

## **8. SUM(), AVG(), COUNT() as Window Functions**

- **Purpose:** Aggregate per row, keeping row detail
    

```sql
SELECT
    name,
    department_id,
    salary,
    SUM(salary) OVER (PARTITION BY department_id) AS dept_total_salary,
    AVG(salary) OVER (PARTITION BY department_id) AS dept_avg_salary,
    COUNT(*) OVER (PARTITION BY department_id) AS dept_emp_count
FROM employees;
```

**Explanation:**

- Each employee sees **department total, avg, count**
    
- Rows are **not collapsed**, unlike `GROUP BY`
    

---

## **9. Running Totals & Moving Averages**

```sql
SELECT
    name,
    hire_date,
    SUM(salary) OVER (ORDER BY hire_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
    AVG(salary) OVER (ORDER BY hire_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3
FROM employees;
```

**Explanation:**

- `running_total` → cumulative sum up to current row
    
- `moving_avg_3` → average over current row + previous 2 rows
    
- Great for **financial trends, KPI tracking, or rolling metrics**
    

---

## **10. Advanced Window Framing**

- **ROWS vs RANGE**:
    

```sql
SUM(salary) OVER (
    PARTITION BY department_id
    ORDER BY salary
    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
) AS sum_window
```

**Explanation:**

- `ROWS` → literal row positions relative to current row
    
- `RANGE` → logical frame based on ORDER BY values
    
- Lets you calculate **local sums, moving totals, or context-sensitive metrics**
    

---

## **11. Combining Multiple Window Functions**

```sql
SELECT
    name,
    department_id,
    salary,
    RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rank_in_dept,
    SUM(salary) OVER (PARTITION BY department_id ORDER BY salary DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_salary,
    LAG(salary) OVER (PARTITION BY department_id ORDER BY salary) AS prev_salary
FROM employees;
```

**Explanation:**

- Combines **ranking, cumulative totals, and previous row comparison**
    
- Very powerful for **dashboards and reports**
    

---

## **12. Real-World Use Cases**

1. **Employee rankings** → `RANK()`, `DENSE_RANK()`
    
2. **Salary percentiles / quartiles** → `NTILE()`
    
3. **Running totals** → `SUM() OVER()`
    
4. **Moving averages** → `AVG() OVER()`
    
5. **Trend analysis** → `LAG()`, `LEAD()`
    
6. **Top N per group** → `ROW_NUMBER()` + `PARTITION BY`
    
7. **Boundary values** → `FIRST_VALUE()`, `LAST_VALUE()`
    
8. **Pivoting or KPI dashboards** → multiple window functions together
    

---

## ✅ **Key Takeaways**

- **Window functions** = calculations across rows **without collapsing**
    
- **PARTITION BY** → group rows (like GROUP BY but keeps row)
    
- **ORDER BY** → define sequence for ranking or running totals
    
- **ROWS / RANGE** → define exact window frame
    
- **Functions to know:**
    
    - **Ranking:** `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `NTILE()`
        
    - **Aggregates:** `SUM()`, `AVG()`, `COUNT()`, `MAX()`, `MIN()`
        
    - **Row access:** `LAG()`, `LEAD()`
        
    - **Boundaries:** `FIRST_VALUE()`, `LAST_VALUE()`
        


---

# 🧠 **PostgreSQL Window Functions Cheat Sheet**

|Function|Purpose / Concept|Syntax|Example|Explanation / Use Case|
|---|---|---|---|---|
|**ROW_NUMBER()**|Sequential numbering of rows|`ROW_NUMBER() OVER ([PARTITION BY col] ORDER BY col)`|`ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC)`|Numbers rows per department. Use for **top N queries**.|
|**RANK()**|Ranking with gaps for ties|`RANK() OVER ([PARTITION BY col] ORDER BY col)`|`RANK() OVER (ORDER BY salary DESC)`|If two employees tie at rank 1, next rank = 3. Use in **leaderboards**.|
|**DENSE_RANK()**|Ranking without gaps|`DENSE_RANK() OVER ([PARTITION BY col] ORDER BY col)`|`DENSE_RANK() OVER (ORDER BY salary DESC)`|Ties don’t create gaps. Use for **grading or tiers**.|
|**NTILE(n)**|Split rows into n buckets|`NTILE(n) OVER ([PARTITION BY col] ORDER BY col)`|`NTILE(4) OVER (ORDER BY salary DESC)`|Divides employees into **quartiles**. Great for **percentile calculations**.|
|**SUM()**|Aggregate over a window|`SUM(col) OVER ([PARTITION BY col] ORDER BY col ROWS BETWEEN frame)`|`SUM(salary) OVER (PARTITION BY department_id ORDER BY hire_date ROWS UNBOUNDED PRECEDING)`|Cumulative sum or totals **per department or group**.|
|**AVG()**|Average over a window|`AVG(col) OVER ([PARTITION BY col] ORDER BY col ROWS BETWEEN frame)`|`AVG(salary) OVER (PARTITION BY department_id)`|Average salary **per department**, row-level.|
|**COUNT()**|Count rows over window|`COUNT(col) OVER ([PARTITION BY col] ORDER BY col ROWS frame)`|`COUNT(*) OVER (PARTITION BY department_id)`|Counts employees per department **without collapsing rows**.|
|**MAX() / MIN()**|Max or min value over window|`MAX(col) OVER ([PARTITION BY col] ORDER BY col)`|`MAX(salary) OVER (PARTITION BY department_id)`|Get highest/lowest salary **per group**.|
|**LAG(col, offset, default)**|Previous row value|`LAG(col, 1) OVER ([PARTITION BY col] ORDER BY col)`|`LAG(salary,1) OVER (ORDER BY hire_date)`|Compare previous row salary; useful for **trend analysis**.|
|**LEAD(col, offset, default)**|Next row value|`LEAD(col, 1) OVER ([PARTITION BY col] ORDER BY col)`|`LEAD(salary,1) OVER (ORDER BY hire_date)`|Compare next row; used for **forecasting or gaps**.|
|**FIRST_VALUE(col)**|First value in window|`FIRST_VALUE(col) OVER (PARTITION BY col ORDER BY col)`|`FIRST_VALUE(salary) OVER (PARTITION BY department_id ORDER BY salary DESC)`|Get **highest salary per department**.|
|**LAST_VALUE(col)**|Last value in window|`LAST_VALUE(col) OVER (PARTITION BY col ORDER BY col ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)`|`LAST_VALUE(salary) OVER (PARTITION BY department_id ORDER BY salary ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)`|Get **lowest salary per department**.|
|**CUME_DIST()**|Relative rank / percentile|`CUME_DIST() OVER ([PARTITION BY col] ORDER BY col)`|`CUME_DIST() OVER (ORDER BY salary DESC)`|Returns fraction of rows ≤ current row. Good for **percentile rank**.|
|**PERCENT_RANK()**|Percentile ranking|`PERCENT_RANK() OVER ([PARTITION BY col] ORDER BY col)`|`PERCENT_RANK() OVER (ORDER BY salary)`|Returns 0-1 rank relative to group. Use in **distribution analysis**.|
|**NTH_VALUE(col, n)**|Get nth value in window|`NTH_VALUE(col, n) OVER ([PARTITION BY col] ORDER BY col ROWS BETWEEN frame)`|`NTH_VALUE(salary,2) OVER (PARTITION BY department_id ORDER BY salary)`|Grab **second highest salary** per department.|
|**ROWS / RANGE frame**|Defines which rows in window|`ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING`|`SUM(salary) OVER (ORDER BY hire_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)`|Controls **moving averages, cumulative totals, local sums**.|

---

## **Window Function Clauses Explained**

1. **PARTITION BY**
    
    - Splits data into **groups** for separate calculation.
        
    - Example: `PARTITION BY department_id` → compute ranking or sum **per department**.
        
2. **ORDER BY**
    
    - Defines **row sequence** inside a partition.
        
    - Needed for **ranking, running totals, moving averages**.
        
3. **ROWS vs RANGE**
    
    - **ROWS** → physical row positions relative to current row.  
        Example: `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` → include 2 rows before current row.
        
    - **RANGE** → logical frame based on **ORDER BY values**.  
        Example: `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` → all rows with values ≤ current row.
        
4. **OFFSET in LAG/LEAD**
    
    - `LAG(salary, 1)` → 1 row before
        
    - Default value can be set if no previous/next row exists
        
5. **Combining Multiple Window Functions**
    
    - Can use **ROW_NUMBER + SUM + LAG** in the same query
        
    - Each can have **different partition/order/window frame**
        

---

## **Real-World Use Cases**

1. **Top N per group:** `ROW_NUMBER()` + `PARTITION BY`
    
2. **Employee ranking:** `RANK() / DENSE_RANK()`
    
3. **Salary quartiles:** `NTILE(4)`
    
4. **Running totals:** `SUM() OVER(...)`
    
5. **Moving averages:** `AVG() OVER(...)`
    
6. **Trend comparison:** `LAG() / LEAD()`
    
7. **Boundary values:** `FIRST_VALUE()` / `LAST_VALUE()`
    
8. **Percentiles / distribution:** `CUME_DIST()` / `PERCENT_RANK()`
    

---

## ✅ **Key Takeaways for Memorization**

- **Window functions = aggregate & analytic power without collapsing rows**
    
- **Use PARTITION BY to group**, ORDER BY to sort, and ROWS/RANGE to define frame
    
- **Ranking:** ROW_NUMBER, RANK, DENSE_RANK, NTILE
    
- **Aggregates per row:** SUM, AVG, COUNT, MAX, MIN
    
- **Row access:** LAG, LEAD
    
- **Boundary values:** FIRST_VALUE, LAST_VALUE, NTH_VALUE
    
- **Percentiles:** CUME_DIST, PERCENT_RANK
    
- Combine functions + partitions + frames for **production-level dashboards and analytics**
    

---

# **Window Functions in SQL – The Ultimate Simple Theory Note**

---

## **1️⃣ What a Window Function Is**

A **window function** lets you calculate values **over a group of rows** (the “window”) **without collapsing the rows**.

- **Normal aggregate (`GROUP BY`)** → merges rows, losing detail.
    
- **Window function** → keeps every row, adds calculated info **next to each row**.
    

**Analogy:** Each student in a classroom wants to know **their class’s total marks**, but still wants to see **their own mark**.

---

## **2️⃣ Core Components**

```sql
AGG_FUNC(column) OVER(PARTITION BY group_column ORDER BY order_column)
```

- **AGG_FUNC(column)** → what calculation you want (`SUM`, `COUNT`, `AVG`, `RANK`, `ROW_NUMBER`)
    
- **PARTITION BY group_column** → defines **the window**, like a “group of rows”
    
- **ORDER BY order_column** (optional) → orders rows inside that window (needed for ranking or running totals)
    
- **OVER(...)** → tells SQL “do this calculation per row, keeping all rows intact”
    

---

## **3️⃣ How It Works – Step by Step Logic**

For each row:

1. Look at the current row (example: Alice, US, 90).
    
2. Find all rows that belong to the same **partition/group** (all US students).
    
3. Apply the aggregate or function over **this group only**.
    
4. Put the result **next to the original row**.
    
5. Repeat for **every row** in the table.
    

**Key point:** Each row stays; calculation is relative to its “window”.

---

## **4️⃣ Simple Examples**

### Example 1 – Count students per country

```sql
SELECT 
    name,
    country,
    COUNT(*) OVER(PARTITION BY country) AS students_per_country
FROM student;
```

- **Window:** All students with the same country
    
- **Function:** COUNT(*)
    
- **Result:** Each student row shows **how many students are in their country**
    

---

### Example 2 – Sum of marks per country

```sql
SELECT 
    name,
    country,
    mark,
    SUM(mark) OVER(PARTITION BY country) AS total_marks_per_country
FROM student;
```

- Each student sees **their mark** and **the total marks of their country**
    

---

### Example 3 – Ranking per country

```sql
SELECT
    name,
    country,
    mark,
    RANK() OVER(PARTITION BY country ORDER BY mark DESC) AS rank_in_country
FROM student;
```

- Partitions students by country
    
- Orders by mark descending
    
- Assigns ranks **within each country**
    

---

## **5️⃣ Why Use Window Functions?**

- Keep individual rows while calculating group-level data
    
- Easily calculate:
    
    - Totals, sums, averages, counts
        
    - Percentages or ratios per group
        
    - Ranks, row numbers, running totals
        
- Much more flexible than `GROUP BY`
    

---

## **6️⃣ Mental Model (🐐 Style)**

Think of each row as a **friend with their own candy**:

1. Friend looks at their **group of friends** (partition)
    
2. Counts or sums candy across the group (function)
    
3. Writes the result on their **own candy sheet**
    
4. Every friend still keeps their **individual candy info**
    

---

## **7️⃣ Key Tips**

- Use **numeric columns** for `SUM`, `AVG`, etc.
    
- `COUNT(*)` works on anything.
    
- `ORDER BY` inside `OVER()` is only needed for ranking or running totals.
    
- Window functions **do not remove rows**.
    

---

```sql
SELECT 
    name,
    age,
    country,
    mark,
    ROUND(AVG(mark) OVER(), 2) AS average_mark,
	CASE 
        WHEN mark > ROUND(AVG(mark) OVER(), 2) THEN '✅⬆️'
        WHEN mark = ROUND(AVG(mark) OVER(), 2) THEN '✅🟰'
        ELSE '❌⬇️'
	END as status
FROM student;

```

### Tags : [[1 - SQL 🥞]]