

# 🧩 **SQL / PostgreSQL: Conditional Aggregation**

---

## **1. Definition**

**Conditional Aggregation** = aggregating **only certain rows** based on a condition, without filtering out the rest of the dataset.

- Typically done with **CASE inside an aggregate function**.
    
- Works for `SUM`, `COUNT`, `AVG`, `MAX`, `MIN`, etc.
    

**Pattern:**

```sql
AGG_FUNC(CASE WHEN condition THEN value ELSE 0 END)
```

---

## **2. Example 1: Count by Category**

Count male and female employees per department:

```sql
SELECT
    department_id,
    COUNT(CASE WHEN gender = 'M' THEN 1 END) AS male_count,
    COUNT(CASE WHEN gender = 'F' THEN 1 END) AS female_count
FROM employees
GROUP BY department_id;
```

- `CASE` determines which rows to include in each count.
    
- Rows not matching the condition are ignored by `COUNT` if `NULL` is returned.
    

---

## **3. Example 2: Conditional SUM**

Total salary of high earners per department:

```sql
SELECT
    department_id,
    SUM(CASE WHEN salary > 70000 THEN salary ELSE 0 END) AS high_earners_total,
    SUM(salary) AS total_salary
FROM employees
GROUP BY department_id;
```

- Only sums **salary > 70000** for `high_earners_total`.
    

---

## **4. Example 3: Conditional AVG**

Average salary of employees with rating A:

```sql
SELECT
    department_id,
    AVG(CASE WHEN performance_rating = 'A' THEN salary END) AS avg_rating_a
FROM employees
GROUP BY department_id;
```

- `AVG` ignores NULLs, so rows where the condition is false are excluded automatically.
    

---

## **5. Example 4: Multiple Conditions**

```sql
SELECT
    department_id,
    COUNT(CASE WHEN gender = 'M' AND salary > 50000 THEN 1 END) AS male_high_salary,
    COUNT(CASE WHEN gender = 'F' AND salary > 50000 THEN 1 END) AS female_high_salary
FROM employees
GROUP BY department_id;
```

- Combines **multiple conditions** in one aggregation.
    

---

## **6. Example 5: Using FILTER (PostgreSQL 9.4+)**

PostgreSQL has a **cleaner syntax** using `FILTER`:

```sql
SELECT
    department_id,
    COUNT(*) FILTER (WHERE gender = 'M') AS male_count,
    COUNT(*) FILTER (WHERE gender = 'F') AS female_count,
    SUM(salary) FILTER (WHERE salary > 70000) AS high_salary_total
FROM employees
GROUP BY department_id;
```

- `FILTER` = **conditional aggregation without CASE**.
    
- Easier to read and maintain.
    

---

## **7. Example 6: Conditional Aggregation in Pivoting**

```sql
SELECT
    department_id,
    SUM(CASE WHEN month = 'Jan' THEN sales ELSE 0 END) AS jan_sales,
    SUM(CASE WHEN month = 'Feb' THEN sales ELSE 0 END) AS feb_sales,
    SUM(CASE WHEN month = 'Mar' THEN sales ELSE 0 END) AS mar_sales
FROM sales_data
GROUP BY department_id;
```

- Converts **rows into columns** by condition — basic pivoting.
    

---

## **8. Practical Use Cases**

1. **Gender-wise count in departments**
    
2. **High/low salary totals**
    
3. **Performance-based averages**
    
4. **Monthly/quarterly sales pivot**
    
5. **Conditional KPI calculations**
    
6. **Data cleaning reports**
    

---

## ✅ **Goat Mode TL;DR 🐐**

- **Conditional Aggregation** = aggregate **specific rows based on a condition**
    
- Use **CASE** inside `SUM`, `COUNT`, `AVG`, etc.
    
- Use **FILTER (PostgreSQL)** for cleaner syntax
    
- Ideal for **reporting, pivoting, KPI calculation**
    
- Combines perfectly with **GROUP BY**
    

---


### Tags : [[1 - SQL 🦬]]