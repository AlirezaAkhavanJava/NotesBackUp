

# **SQL / PostgreSQL: `OVER` Clause (Window Functions)**

---

## **1. Definition**

The `OVER` clause is used to apply a **window function** over a set of rows defined by **partitions, order, or frame**.

- Unlike `GROUP BY`, it **does not collapse rows**.
    
- Useful for cumulative sums, ranking, moving averages, percentiles, etc.
    

**Basic syntax:**

```sql
window_function() OVER (
    [PARTITION BY column1, column2, ...]
    [ORDER BY column1, column2, ...]
    [ROWS frame_specification]
)
```

---

## **2. Common Window Functions with OVER**

### **2.1 ROW_NUMBER()**

Assigns a unique sequential number to rows within a partition.

```sql
SELECT
    department,
    employee,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS rank_in_dept
FROM employees;
```

- `PARTITION BY department` → resets row numbers for each department
    
- `ORDER BY salary DESC` → highest salary = 1
    

---

### **2.2 RANK()**

Ranks rows with **ties** getting the same rank; gaps exist after ties.

```sql
SELECT
    department,
    employee,
    salary,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank_in_dept
FROM employees;
```

- Multiple employees with same salary get same rank; next rank skips numbers.
    

---

### **2.3 DENSE_RANK()**

Ranks rows with ties **without gaps**.

```sql
SELECT
    department,
    employee,
    salary,
    DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank_in_dept
FROM employees;
```

---

### **2.4 SUM(), AVG(), MIN(), MAX() with OVER**

Calculates **aggregates without grouping**.

```sql
SELECT
    department,
    employee,
    salary,
    SUM(salary) OVER (PARTITION BY department) AS total_salary_dept,
    AVG(salary) OVER (PARTITION BY department) AS avg_salary_dept
FROM employees;
```

- `SUM()` and `AVG()` give **department totals/averages** while keeping row-level detail.
    

---

### **2.5 LEAD() and LAG()**

Access **next or previous row** within partition.

```sql
SELECT
    employee,
    salary,
    LAG(salary, 1) OVER (ORDER BY salary) AS previous_salary,
    LEAD(salary, 1) OVER (ORDER BY salary) AS next_salary
FROM employees;
```

- Useful for calculating **changes or trends**.
    

---

### **2.6 FIRST_VALUE() and LAST_VALUE()**

Get the first or last value in a partition.

```sql
SELECT
    department,
    employee,
    salary,
    FIRST_VALUE(salary) OVER (PARTITION BY department ORDER BY salary DESC) AS highest_salary,
    LAST_VALUE(salary) OVER (PARTITION BY department ORDER BY salary DESC
                             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS lowest_salary
FROM employees;
```

> Important: For `LAST_VALUE()` you often need a **frame definition** to cover all rows, otherwise it uses **current row as end**.

---

## **3. Frame Specification**

- Default: `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`
    
- Common options:
    

```sql
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW -- cumulative
ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING       -- moving window
ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
```

**Example: cumulative sum:**

```sql
SELECT
    employee,
    salary,
    SUM(salary) OVER (ORDER BY salary ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_salary
FROM employees;
```

---

## **4. ORDER BY vs PARTITION BY**

|Clause|Purpose|
|---|---|
|PARTITION BY|Splits rows into groups; resets the window function for each partition|
|ORDER BY (inside OVER)|Orders rows inside each partition (required for ranking, cumulative functions)|

- You can use `PARTITION BY` without `ORDER BY` (e.g., `COUNT(*) OVER (PARTITION BY department)`).
    

---

## **5. Examples Together**

```sql
SELECT
    department,
    employee,
    salary,
    COUNT(*) OVER (PARTITION BY department) AS dept_count,
    SUM(salary) OVER (PARTITION BY department ORDER BY salary ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_salary,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS row_num,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank,
    LEAD(salary) OVER (PARTITION BY department ORDER BY salary DESC) AS next_salary
FROM employees;
```

- Single query calculates: counts, cumulative sum, row number, rank, and next row salary.
    

---

## **6. Key Notes**

1. `OVER` allows **analytic computations without collapsing rows**.
    
2. Use `PARTITION BY` to group logically (like `GROUP BY` but **keeps rows**).
    
3. Use `ORDER BY` for ranking, cumulative, or moving window calculations.
    
4. Combine with `ROWS` or `RANGE` for precise frame control.
    
5. Works with numeric, date, or string ordering.
    

---

## ✅ **Goat Mode TL;DR**

- **`OVER` = Window function magic** → keeps rows, calculates over “windows”
    
- **Functions used with OVER:** `ROW_NUMBER, RANK, DENSE_RANK, SUM, AVG, MIN, MAX, LEAD, LAG, FIRST_VALUE, LAST_VALUE`
    
- **Partition = group**, **Order = sequence**, **Frame = subset**
    
- Use for analytics like: cumulative sums, running totals, moving averages, leaderboards
    


### Tags : [[1 - SQL 🦬]]