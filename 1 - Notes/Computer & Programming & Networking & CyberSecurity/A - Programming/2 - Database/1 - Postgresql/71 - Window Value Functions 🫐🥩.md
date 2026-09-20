In PostgreSQL, **window value functions** (also called **window aggregate functions**) are functions that perform calculations **across a set of rows related to the current row**, **without collapsing them** into a single result (unlike `GROUP BY`).

They use the `OVER()` clause to define the _window_ (the range of rows considered).

---

### 🧠 Common Window Value Functions

|Function|Description|Example|
|---|---|---|
|`AVG()`|Average over a window|`AVG(salary) OVER (PARTITION BY dept)`|
|`SUM()`|Sum over a window|`SUM(sales) OVER (ORDER BY date)`|
|`COUNT()`|Count of rows in the window|`COUNT(*) OVER (PARTITION BY region)`|
|`MIN()` / `MAX()`|Minimum or maximum in window|`MAX(score) OVER (ORDER BY score)`|
|`FIRST_VALUE()`|First value in window|`FIRST_VALUE(price) OVER (ORDER BY date)`|
|`LAST_VALUE()`|Last value in window|`LAST_VALUE(price) OVER (ORDER BY date)`|
|`NTH_VALUE(expr, n)`|The _n-th_ value in the window|`NTH_VALUE(salary, 3) OVER (ORDER BY salary DESC)`|
|`LAG(expr [, offset])`|Value from a previous row|`LAG(salary, 1) OVER (ORDER BY id)`|
|`LEAD(expr [, offset])`|Value from a next row|`LEAD(salary, 1) OVER (ORDER BY id)`|

---

### 🪟 Syntax

```sql
function_name(expression) 
OVER (
    [PARTITION BY column]
    [ORDER BY column]
    [ROWS or RANGE frame_clause]
)
```

---

### 💡 Example

```sql
SELECT
    emp_id,
    dept,
    salary,
    AVG(salary) OVER (PARTITION BY dept) AS avg_dept_salary,
    RANK() OVER (PARTITION BY dept ORDER BY salary DESC) AS rank_in_dept,
    LAG(salary) OVER (PARTITION BY dept ORDER BY salary) AS prev_salary
FROM employees;
```

🧩 **What happens here:**

- Each employee sees their department’s average salary (`AVG OVER`).
    
- `RANK()` gives their position within the department.
    
- `LAG()` shows the previous employee’s salary in order.
    

---


### 🧱 FRAME CLAUSE STRUCTURE

A window frame can be defined like this:

```sql
ROWS | RANGE BETWEEN frame_start AND frame_end
```

---

### 🔹 FRAME TYPES

|Keyword|Meaning|
|---|---|
|`ROWS`|Counts physical rows before/after the current row.|
|`RANGE`|Groups rows with the same `ORDER BY` value together.|
|`GROUPS`|(less common) Works with ranking ties like `RANGE`, but counts tied groups instead of rows.|

---

### 🔹 FRAME BOUNDARIES

|Boundary|Meaning|
|---|---|
|`UNBOUNDED PRECEDING`|Start from the first row in the partition.|
|`n PRECEDING`|n rows before current row.|
|`CURRENT ROW`|Only the current row.|
|`n FOLLOWING`|n rows after current row.|
|`UNBOUNDED FOLLOWING`|Go until the last row in the partition.|

---

### 💡 Examples

#### 1️⃣ Moving Average of 3 Salaries

```sql
SELECT
    emp_id,
    salary,
    AVG(salary) OVER (
        ORDER BY emp_id
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg
FROM employees;
```

✅ Each employee’s moving average includes **their own row and the 2 before it**.

---

#### 2️⃣ Running Total

```sql
SELECT
    emp_id,
    SUM(salary) OVER (
        ORDER BY emp_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM employees;
```

✅ Adds up all salaries **from the first row to the current** (like cumulative sum).

---

#### 3️⃣ Compare with RANGE

If you use:

```sql
RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
```

…it means _all rows with equal ORDER BY values_ are included.  
This is useful for timestamps or scores that may have duplicates.

---

### 🧠 TL;DR

- `OVER()` defines **window scope**.
    
- `PARTITION BY` divides data into groups.
    
- `ORDER BY` defines order inside the group.
    
- `ROWS BETWEEN ... AND ...` defines **which subset** of that group the function works on.
    


---

### 🧩 1️⃣ Window functions require `OVER()`

Every window function **must** have an `OVER()` clause — otherwise PostgreSQL treats it as a normal aggregate (which collapses rows).

```sql
-- ✅ Valid
AVG(salary) OVER()

-- ❌ Invalid
AVG(salary)
```

---

### 🧩 2️⃣ `PARTITION BY` divides rows into groups

Each partition acts like a mini-table.  
Functions reset for each partition.  
If omitted, the function runs over **the entire result set**.

```sql
AVG(salary) OVER (PARTITION BY dept)
```

---

### 🧩 3️⃣ `ORDER BY` defines row sequence inside the window

Used for ranking, cumulative sums, lag/lead, etc.  
Without it, PostgreSQL treats all rows as “tied”.

```sql
SUM(salary) OVER (ORDER BY emp_id)
```

---

### 🧩 4️⃣ Frame clause (optional but powerful)

Defines exactly **which subset of rows** to include relative to the current row.  
Default frame:

- For **`ORDER BY` present** → `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`
    
- For **no ORDER BY** → entire partition
    

```sql
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
```

---

### 🧩 5️⃣ Frame boundaries can’t go backward

Start must be **≤ end**. Example:

```sql
ROWS BETWEEN 3 PRECEDING AND 1 FOLLOWING  -- ✅ valid
ROWS BETWEEN 1 FOLLOWING AND 3 PRECEDING  -- ❌ invalid
```

---

### 🧩 6️⃣ Can’t use in WHERE, GROUP BY, or HAVING

Window functions can only appear in:

- `SELECT`
    
- `ORDER BY`
    
- `WINDOW` clause
    

You **cannot** filter by them in `WHERE`.  
If needed, use a subquery or CTE:

```sql
SELECT * FROM (
  SELECT emp_id, RANK() OVER (ORDER BY salary DESC) AS rnk FROM employees
) t WHERE rnk <= 3;
```

---

### 🧩 7️⃣ Executed after `GROUP BY`

Order of SQL operations:

```
FROM → WHERE → GROUP BY → HAVING → SELECT → WINDOW → ORDER BY → LIMIT
```

So window functions happen **after aggregation** but **before final sorting**.

---

### 🧩 8️⃣ You can reuse definitions with `WINDOW` clause

```sql
SELECT
  SUM(salary) OVER w,
  AVG(salary) OVER w
FROM employees
WINDOW w AS (PARTITION BY dept ORDER BY emp_id);
```

---



##### Tags : [[1 - SQL 🥞]]