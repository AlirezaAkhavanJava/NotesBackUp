

### **Definition**

A **row subquery** returns **exactly one row** but can have **multiple columns**.

- Think of it as a little “tuple” `(col1, col2, ...)`.
    
- Often used in comparisons like `=` or `IN` with tuples.
    
- If it returns more than one row, PostgreSQL will throw an error.
    
- If no row is returned, the result is `NULL`.
    

---

### **Syntax**

```sql
(SELECT col1, col2, ...
 FROM table
 WHERE condition)
```

Used in comparisons like:

```sql
(colA, colB) = (SELECT col1, col2 ... )
```

---

### **Examples**

#### 1. Basic row comparison

```sql
SELECT *
FROM employees
WHERE (department_id, salary) = 
      (SELECT department_id, MAX(salary)
       FROM employees
       WHERE department_id = 10
       GROUP BY department_id);
```

- Subquery returns **one row with two columns** `(department_id, max_salary)`.
    
- Employee rows are compared against this tuple.
    

---

#### 2. Using in `IN` with tuples

```sql
SELECT *
FROM employees
WHERE (department_id, job_id) IN 
      (SELECT department_id, job_id
       FROM job_assignments
       WHERE end_date IS NULL);
```

- Returns employees whose `(department_id, job_id)` matches any tuple returned by the subquery.
    

---

#### 3. Using in `UPDATE`

```sql
UPDATE employees
SET (salary, bonus) = 
    (SELECT MAX(salary), MAX(bonus)
     FROM employees
     WHERE department_id = 10)
WHERE department_id = 10;
```

- Subquery returns **one row with two columns**.
    
- Updates salary and bonus together for all employees in department 10.
    

---

### **Key Rules**

1. Must return **exactly one row** (multiple columns allowed).
    
2. If multiple rows are returned → **error**.
    
3. Can be used with `=`, `<`, `>`, `IN` (for tuples), and `SET` (for multiple columns).
    

---



##### Tags : [[1 - SQL 🥞]]