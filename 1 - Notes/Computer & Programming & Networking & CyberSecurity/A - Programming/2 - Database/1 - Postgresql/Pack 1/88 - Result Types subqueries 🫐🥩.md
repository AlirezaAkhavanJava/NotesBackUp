
In PostgreSQL, **subqueries** can return different types of results depending on how you use them. Understanding these **result types** is key to writing correct queries. Let’s break them down clearly:

---

### 1. **Scalar Subquery** (Single Value)

- Returns **exactly one value** (one row, one column).
    
- Often used in the `SELECT` or `WHERE` clause.
    

**Example:**

```sql
SELECT name,
       (SELECT MAX(salary) FROM employees) AS max_salary
FROM employees;
```

- `MAX(salary)` returns a **single value**, so the subquery is scalar.
    

> ⚠️ Error occurs if the subquery returns more than one row.

---

### 2. **Column Subquery** (Single Column, Multiple Rows)

- Returns a **single column** but can have **multiple rows**.
    
- Typically used with `IN`, `ANY`, `ALL`.
    

**Example:**

```sql
SELECT name
FROM employees
WHERE department_id IN (SELECT id FROM departments WHERE location = 'New York');
```

- Subquery returns multiple department IDs.
    
- PostgreSQL matches the employee's `department_id` against all those IDs.
    

---

### 3. **Row Subquery** (Single Row, Multiple Columns)

- Returns **one row with multiple columns**.
    
- Often used in comparison operators like `=`, `<`, `>`, or `IN` with tuples.
    

**Example:**

```sql
SELECT *
FROM employees
WHERE (department_id, salary) = (SELECT department_id, MAX(salary) 
                                 FROM employees 
                                 GROUP BY department_id
                                 HAVING department_id = 10);
```

- Subquery returns **one row** with multiple columns for comparison.
    

---

### 4. **Table Subquery** (Multiple Rows, Multiple Columns)

- Returns a **table-like result** (more than one row and column).
    
- Can be used as a **derived table** (inline view) in `FROM` or with `EXISTS`.
    

**Example:**

```sql
SELECT d.name, e.name
FROM departments d
JOIN (SELECT * FROM employees WHERE salary > 5000) e
ON d.id = e.department_id;
```

- The subquery behaves like a temporary table.
    

---

### 5. **Existence Subquery** (`EXISTS` / `NOT EXISTS`)

- Returns **true or false** depending on whether the subquery returns rows.
    
- Used in conditional checks.
    

**Example:**

```sql
SELECT name
FROM employees e
WHERE EXISTS (SELECT 1 
              FROM departments d 
              WHERE d.id = e.department_id 
                AND d.location = 'London');
```

- If the subquery returns at least one row, `EXISTS` is `TRUE`.
    

---

✅ **Summary Table**

|Subquery Type|Returns|Use Case|
|---|---|---|
|Scalar|Single value|`SELECT`, `WHERE` comparisons|
|Column|Single column, many rows|`IN`, `ANY`, `ALL`|
|Row|Single row, many cols|Tuple comparisons `(a, b) = (x, y)`|
|Table / Derived|Many rows, many cols|`FROM` clause, JOIN, filtering|
|Existence|TRUE / FALSE|`EXISTS`, `NOT EXISTS`|

---



##### Tags : [[1 - SQL 🦬]]