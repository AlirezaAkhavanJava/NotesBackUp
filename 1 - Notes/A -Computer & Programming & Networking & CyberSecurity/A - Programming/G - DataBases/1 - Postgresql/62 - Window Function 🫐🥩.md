

# 🧠 **PostgreSQL Window Functions: Basic → Advanced**



## **1. What Are Window Functions?**

- **Window functions** perform calculations **across a set of rows related to the current row**, without collapsing rows like `GROUP BY`.
    
- Syntax:
    

```sql
FUNCTION_NAME(arguments) OVER (
    [PARTITION BY column(s)] 
    [ORDER BY column(s) [ASC|DESC]]
    [ROWS BETWEEN ...]
)
```

- **PARTITION BY** → defines groups (like `GROUP BY` but keeps rows)
    
- **ORDER BY** → order of calculation
    
- **ROWS / RANGE** → defines the “window frame”

> Window functions in theory
They **create a frame (or window) of related rows** — often grouped by some column (`PARTITION BY`) and ordered in some way (`ORDER BY`) —  
then they **perform a calculation or comparison** over that frame **for each row**.

> It’s like _temporarily grouping rows_ without collapsing them — you can still see each row, but you can also calculate things based on its group or neighbors.


> SO IT PUTS ROWS WITH SAME PARTITION CLOSE TO EACH OTHER AND COMPARES OR OPERATES THEM

#### This query perfectly demonstrates how window functions frame data : 

```SQL
SELECT 
  name,
  mark,
  age,
  country,
  COUNT(*) OVER (PARTITION BY country ORDER BY country ASC) AS countryman,
  ROW_NUMBER() OVER (PARTITION BY country)
FROM student;

```


### Step-by-step logic

1. **`PARTITION BY country`**  
    → divides the table into separate _frames_ (windows) — one per country.  
    Example: all “USA” rows together, all “IRAN” rows together, etc.
    
2. **`COUNT(*) OVER (...)`**  
    → counts how many rows are in each country’s frame — every row in that frame shows the same count.
    
3. **`ROW_NUMBER() OVER (PARTITION BY country)`**  
    → gives a unique row number **inside each country’s partition**, starting from 1.

---

## **2. Basic Window Functions**

### **2.1 ROW_NUMBER()**

Sequential numbering per partition or table.

```sql
SELECT name , mark , age , country ,
	COUNT(*) OVER(PARTITION BY country  ORDER BY country ASC) AS COUNTYMAN,
	ROW_NUMBER() OVER(PARTITION BY country), 
FROM student


```

- Numbers employees within **each department** by descending salary.
    

---

### **2.2 RANK() and DENSE_RANK()**

Ranking with and without gaps.

```sql
SELECT name , mark , age , country ,
	COUNT(*) OVER(PARTITION BY country  ORDER BY country ASC) AS COUNTYMAN,
	ROW_NUMBER() OVER(PARTITION BY country), 
	RANK() OVER(PARTITION BY country ORDER BY mark DESC) AS COUNTRY_RANKING
FROM student


```

- `RANK()` → gaps if ties exist
    
- `DENSE_RANK()` → no gaps


> `RANK()` gives each row a **ranking number** based on the **order you choose** — like a competition. 🏅 `RANK()` assigns a rank to each row **within its partition**, based on the `ORDER BY` inside the window.

---
#### TIP : 
|Clause|Meaning|
|---|---|
|`PARTITION BY`|define _which rows belong together_ (the frame groups)|
|`ORDER BY`|define _how to order rows_ inside each partition|
|window function|does the calculation _within that partition_|

---

### **2.3 NTILE(n)**

Divides rows into **n buckets**.

```sql
SELECT
    name,
    salary,
    NTILE(4) OVER (ORDER BY salary DESC) AS quartile
FROM employees;
```

- Splits employees into 4 **salary quartiles**.

> `NTILE(n)` takes a number **n** and splits the ordered rows into **n groups (tiles)** that are as equal in size as possible.

#### ANALOGY : 

##### ⚽ Imagine:

You’ve got **20 football teams** ranked by points.  
Now you want to split them into **4 divisions** (A, B, C, D).

That’s literally what:

```sql
NTILE(4) OVER (ORDER BY points DESC)
```

### 🧩 Result

|Team|Points|Division|
|---|---|---|
|Team1|90|1|
|Team2|88|1|
|Team3|85|1|
|Team4|82|2|
|Team5|80|2|
|Team6|78|2|
|Team7|75|3|
|Team8|72|3|
|Team9|70|3|
|Team10|65|4|
|Team11|62|4|
|Team12|60|4|

So:

- Top 25% → Division 1
    
- Next 25% → Division 2
    
- and so on
    

### 🧠 In SQL terms:

`NTILE(4)` split your table (ordered by points) into **4 groups** — like football **divisions, brackets, or fixtures**.


🐐 **In short:**

> `NTILE()` works like organizing teams into equal leagues based on performance.


---

## **3. Aggregate Window Functions**

These are standard aggregates but keep **row context**.

```sql
SELECT
    name,
    department_id,
    salary,
    SUM(salary) OVER (PARTITION BY department_id) AS dept_total_salary,
    AVG(salary) OVER (PARTITION BY department_id) AS dept_avg_salary,
    MAX(salary) OVER (PARTITION BY department_id) AS dept_max_salary
FROM employees;
```

- Each row gets **department totals, averages, and max**.
    

---

## **4. LAG() and LEAD()**

Access **previous/next row** values.

```sql
SELECT
    name,
    salary,
    LAG(salary, 1) OVER (ORDER BY hire_date) AS prev_salary,
    LEAD(salary, 1) OVER (ORDER BY hire_date) AS next_salary
FROM employees;
```

- Perfect for **trend analysis** or **comparisons**.
    

---

## **5. FIRST_VALUE() and LAST_VALUE()**

```sql
SELECT
    name,
    salary,
    FIRST_VALUE(salary) OVER (PARTITION BY department_id ORDER BY salary DESC) AS highest_salary,
    LAST_VALUE(salary) OVER (PARTITION BY department_id ORDER BY salary ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS lowest_salary
FROM employees;
```

- Grab **first/last value** in a partition.
    
- `ROWS BETWEEN ...` sometimes needed to define full window correctly.

This is a **sliding window / moving sum**, and it’s very different from a total sum. Let me break it down clearly:

```sql
SUM(mark) OVER(ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
```

### What it means:

1. `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` → defines a **frame of 3 rows** for the calculation:
    
    - **Current row**
        
    - **1 row before**
        
    - **2 rows before**
        
2. `SUM(mark) OVER(...)` → adds up the `mark` values **only for the rows in that frame**.
    


### Example:

|row|mark|sum(mark) over(2 preceding to current)|
|---|---|---|
|1|10|10|
|2|20|10 + 20 = 30|
|3|30|10 + 20 + 30 = 60|
|4|40|20 + 30 + 40 = 90|
|5|50|30 + 40 + 50 = 120|

✅ Notice how the sum **“slides” down the rows**, always including the current row and the 2 rows before it.



---

## **6. Running Totals & Moving Averages**

```sql
SELECT
    name,
    hire_date,
    SUM(salary) OVER (ORDER BY hire_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
    AVG(salary) OVER (ORDER BY hire_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3
FROM employees;
```

- `running_total` → cumulative sum
    
- `moving_avg_3` → average over **3-row window**
    

---

## **7. Advanced Window Framing**

- **ROWS vs RANGE**:
    

```sql
-- RANGE: includes all rows with same value in ORDER BY
-- ROWS: strictly row positions
SUM(salary) OVER (
    PARTITION BY department_id
    ORDER BY salary
    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
) AS sum_window
```

- Lets you calculate **local sums, moving sums, or context-sensitive aggregates**.
    

---

## **8. Combining Multiple Window Functions**

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

- Combines **ranking, cumulative totals, and previous value** in one query.
    

---

## **9. Real-World Use Cases**

1. **Employee Salary Rankings** → `RANK() / DENSE_RANK()`
    
2. **Cumulative Sales** → `SUM() OVER()`
    
3. **Moving Averages** → `AVG() OVER()`
    
4. **Quarterly/Monthly KPIs** → `PARTITION BY month/quarter`
    
5. **Percentiles** → `NTILE(n)`
    
6. **Comparing Trends** → `LAG()` / `LEAD()`
    
7. **Pivoting / Dashboard Metrics** → multiple window functions in one query
    

---

## **10. Goat Mode TL;DR 🐐**

- **Window functions = aggregate & analytic superpowers without losing rows**
    
- Core functions:
    
    - **ROW_NUMBER(), RANK(), DENSE_RANK(), NTILE()** → rankings
        
    - **SUM(), AVG(), COUNT(), MAX(), MIN()** → aggregates per window
        
    - **LAG(), LEAD()** → previous/next row comparison
        
    - **FIRST_VALUE(), LAST_VALUE()** → boundary values
        
- **PARTITION BY** → defines groups
    
- **ORDER BY** → defines sequence in window
    
- **ROWS / RANGE** → window frame (cumulative, moving, custom)
    
- Combine multiple window functions → **production-level reporting**
    

---




### Tags : [[1 - SQL 🥞]]