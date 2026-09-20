
**Subqueries in SQL** are queries **nested inside another query** — basically, a query inside parentheses that returns data used by the outer query.

---

### 🧠 Definition

A **subquery** is an inner query whose result is used by an **outer query** (SELECT, INSERT, UPDATE, or DELETE).

```sql
SELECT name
FROM employees
WHERE department_id = (
    SELECT id FROM departments WHERE name = 'IT'
);
```

Here:

- Inner query → `(SELECT id FROM departments WHERE name = 'IT')`
    
- Outer query → `SELECT name FROM employees ...`
    

---

### 🧩 Types of Subqueries

1. **Scalar Subquery**
    
    - Returns **one value**.
        
    
    ```sql
    SELECT name, salary
    FROM employees
    WHERE salary > (
        SELECT AVG(salary) FROM employees
    );
    ```
    
2. **Row Subquery**
    
    - Returns **one row** with multiple columns.
        
    
    ```sql
    SELECT *
    FROM employees
    WHERE (department_id, job_id) = (
        SELECT department_id, job_id
        FROM employees
        WHERE name = 'John'
    );
    ```
    
3. **Table Subquery (Multi-row / Multi-column)**
    
    - Returns **multiple rows**.
        
    
    ```sql
    SELECT name
    FROM employees
    WHERE department_id IN (
        SELECT id FROM departments WHERE location = 'New York'
    );
    ```
    

---

### ⚙️ Where Subqueries Are Used

|Clause|Example|
|---|---|
|**WHERE**|Filter based on another query|
|**FROM**|Use as a virtual table (`derived table`)|
|**SELECT**|Return calculated values|
|**HAVING**|Filter aggregated groups|

Example (in FROM):

```sql
SELECT dept, avg_salary
FROM (
    SELECT department_id AS dept, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
) AS dept_avg
WHERE avg_salary > 50000;
```

---

### 🚀 Correlated vs Non-Correlated

|Type|Description|Example|
|---|---|---|
|**Non-Correlated**|Executes once, independent of outer query|(the previous examples)|
|**Correlated**|Depends on each row of outer query — runs repeatedly||

```sql
SELECT e.name
FROM employees e
WHERE salary > (
    SELECT AVG(salary)
    FROM employees
    WHERE department_id = e.department_id
);
```

---

### ⚡ Tips

- Use **JOINs** instead of subqueries if performance is poor.
    
- Subqueries in **SELECT** or **WHERE** are great for logical separation.
    
- Subqueries in **FROM** create temporary, inline views.
    



##### Tags : [[1 - SQL 🥞]]