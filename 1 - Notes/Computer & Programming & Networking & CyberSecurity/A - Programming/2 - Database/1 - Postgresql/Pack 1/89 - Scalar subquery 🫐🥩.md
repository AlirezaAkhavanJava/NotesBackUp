Alright, let’s go full 🐐 on **Scalar Subqueries** in PostgreSQL.

---

### **Definition**

A **scalar subquery** is a subquery that returns **exactly one value** (one row, one column).

- If it returns **more than one row**, PostgreSQL will throw an error.
    
- If it returns **no rows**, the result is `NULL`.
    

Basically, think of it as “I need **one number or one string** from this other query.”

---

### **Syntax**

```sql
(SELECT single_column
 FROM table
 WHERE condition)
```

---

### **Examples**

#### 1. Using in `SELECT`

```sql
SELECT name,
       (SELECT MAX(salary) FROM employees) AS max_salary
FROM employees;
```

- Subquery `(SELECT MAX(salary)...)` returns **one value**: the maximum salary.
    
- Each employee row gets that same max salary attached.
    

---

#### 2. Using in `WHERE`

```sql
SELECT name
FROM employees
WHERE salary = (SELECT MAX(salary) FROM employees);
```

- Only returns the employee(s) with the highest salary.
    

> ⚠️ If `(SELECT ...)` returned multiple rows, PostgreSQL would complain.

---

#### 3. Using in `UPDATE`

```sql
UPDATE employees
SET salary = (SELECT AVG(salary) FROM employees)
WHERE department_id = 10;
```

- Scalar subquery returns the average salary of all employees.
    
- All employees in department 10 get their salary updated to that average.
    

---

### **Key Rules**

1. **One row, one column only**.
    
2. Returns `NULL` if no rows match.
    
3. Can be used in `SELECT`, `WHERE`, `HAVING`, or `SET` clauses.
    

---
##### Tags :[[1 - SQL 🦬]]