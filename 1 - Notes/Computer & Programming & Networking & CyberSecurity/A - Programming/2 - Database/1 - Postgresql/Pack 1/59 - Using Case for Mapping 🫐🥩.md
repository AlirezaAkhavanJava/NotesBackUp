


# 🧩 **Using CASE Statements for Mapping in PostgreSQL**

---

## **1. Basic Concept**

- **Mapping with CASE** means: **transforming a column’s value** into another value based on rules.
    
- Useful when you don’t want to create a separate lookup table.
    

**Syntax:**

```sql
CASE
    WHEN condition1 THEN mapped_value1
    WHEN condition2 THEN mapped_value2
    ELSE default_value
END
```

---

## **2. Example: Mapping Department IDs to Names**

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

- Maps numeric IDs to human-readable names.
    
- Works well for small, fixed sets of codes.
    

---

## **3. Mapping Ranges**

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

- Maps numeric ranges into categories.
    
- Common in **reporting and dashboards**.
    

---

## **4. Mapping NULL Values**

```sql
SELECT
    name,
    department_id,
    CASE
        WHEN department_id IS NULL THEN 'No Department'
        ELSE 'Assigned Department'
    END AS dept_status
FROM employees;
```

- Explicitly handles **NULLs**.
    
- Prevents mapping errors when a value is missing.
    

---

## **5. Mapping Multiple Columns (Complex Mapping)**

```sql
SELECT
    name,
    department_id,
    salary,
    CASE
        WHEN department_id = 1 AND salary > 50000 THEN 'HR High Earner'
        WHEN department_id = 1 THEN 'HR Normal'
        WHEN department_id = 2 AND salary > 60000 THEN 'Finance High Earner'
        ELSE 'Other'
    END AS employee_category
FROM employees;
```

- Combines multiple columns for **dynamic mapping**.
    
- Great for **segmentation or business rules**.
    

---

## **6. Mapping with Aggregates**

```sql
SELECT
    department_id,
    COUNT(CASE WHEN salary < 30000 THEN 1 END) AS low_salary_count,
    COUNT(CASE WHEN salary BETWEEN 30000 AND 70000 THEN 1 END) AS medium_salary_count,
    COUNT(CASE WHEN salary > 70000 THEN 1 END) AS high_salary_count
FROM employees
GROUP BY department_id;
```

- Maps rows into **aggregated categories**.
    
- Very common in **analytics** and **reporting**.
    

---

## **7. Mapping for Presentation (Views / Reports)**

```sql
CREATE VIEW employee_summary AS
SELECT
    name,
    department_id,
    CASE department_id
        WHEN 1 THEN 'HR'
        WHEN 2 THEN 'Finance'
        WHEN 3 THEN 'Engineering'
        ELSE 'Other'
    END AS department_name,
    CASE
        WHEN salary < 30000 THEN 'Low'
        WHEN salary BETWEEN 30000 AND 70000 THEN 'Medium'
        ELSE 'High'
    END AS salary_level
FROM employees;
```

- Combines **mapping for IDs** and **mapping for ranges** in a reusable view.
    
- Makes **reports and queries simpler** for downstream use.
    

---

## **8. Nested CASE Mapping**

```sql
SELECT
    name,
    salary,
    CASE
        WHEN salary > 70000 THEN
            CASE WHEN performance_rating = 'A' THEN 'Star' ELSE 'Solid' END
        WHEN salary BETWEEN 30000 AND 70000 THEN 'Average'
        ELSE 'Low'
    END AS employee_status
FROM employees;
```

- Nest CASE statements for **multi-level mapping**.
    
- Useful for **complex business rules**.
    

---

## ✅ **Goat Mode TL;DR 🐐**

- `CASE` is perfect for **mapping codes, IDs, ranges, or multi-column rules**.
    
- Can handle **NULLs explicitly**.
    
- Works in `SELECT`, `UPDATE`, `ORDER BY`, and `GROUP BY`.
    
- Combine with **aggregates** for **category counts**.
    
- Nest CASE statements for **multi-level or hierarchical mapping**.
    

---



### Tags : [[1 - SQL 🦬]]