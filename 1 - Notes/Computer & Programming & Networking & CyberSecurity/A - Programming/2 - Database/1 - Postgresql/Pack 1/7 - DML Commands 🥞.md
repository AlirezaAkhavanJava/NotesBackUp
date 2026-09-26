Date : 2025-08-30


DML (Data Manipulation Language) commands in SQL are used to manipulate data within database objects, such as tables, as opposed to defining their structure (which is handled by DDL). These commands focus on inserting, updating, deleting, and retrieving data. 

### Key DML Commands in SQL (and PostgreSQL)
1. **SELECT**
   - **Purpose**: Retrieves data from one or more tables.
   - **Standard SQL Example**:
     ```sql
     SELECT id, name FROM employees WHERE hire_date > '2023-01-01';
     ```
   - **PostgreSQL Notes**:
     - Supports standard `SELECT` with advanced features like `DISTINCT ON`, window functions, and JSON/JSONB queries.
     - Example with PostgreSQL-specific features:
       ```sql
       SELECT DISTINCT ON (department_id) id, name, salary
       FROM employees
       ORDER BY department_id, salary DESC;
       ```
       This keeps the highest-paid employee per department.
     - PostgreSQL also supports querying JSON data:
       ```sql
       SELECT data->'name' AS name FROM employees WHERE data->>'role' = 'manager';
       ```

2. **INSERT**
   - **Purpose**: Adds new rows to a table.
   - **Standard SQL Example**:
     ```sql
     INSERT INTO employees (id, name, hire_date) VALUES (1, 'Alice Smith', '2023-06-15');
     ```
   - **PostgreSQL Notes**:
     - Supports standard `INSERT` with extensions like `ON CONFLICT` for handling duplicate key conflicts.
     - Example:
       ```sql
       INSERT INTO employees (id, name, hire_date)
       VALUES (1, 'Alice Smith', '2023-06-15')
       ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, hire_date = EXCLUDED.hire_date;
       ```
     - Also supports bulk inserts and returning inserted rows:
       ```sql
       INSERT INTO employees (name, hire_date)
       VALUES ('Bob Jones', '2023-07-01'), ('Cathy Lee', '2023-08-01')
       RETURNING id, name;
       ```

3. **UPDATE**
   - **Purpose**: Modifies existing rows in a table.
   - **Standard SQL Example**:
     ```sql
     UPDATE employees SET salary = salary + 5000 WHERE department_id = 3;
     ```
   - **PostgreSQL Notes**:
     - Supports standard `UPDATE` with additional features like updating from another table or using `RETURNING` to see affected rows.
     - Example:
       ```sql
       UPDATE employees
       SET salary = salary * 1.1
       FROM departments
       WHERE employees.department_id = departments.id AND departments.name = 'Sales'
       RETURNING employees.id, employees.name, employees.salary;
       ```

4. **DELETE**
   - **Purpose**: Removes rows from a table.
   - **Standard SQL Example**:
     ```sql
     DELETE FROM employees WHERE hire_date < '2020-01-01';
     ```
   - **PostgreSQL Notes**:
     - Supports standard `DELETE` with options like `USING` for joins and `RETURNING` for deleted rows.
     - Example:
       ```sql
       DELETE FROM employees
       USING departments
       WHERE employees.department_id = departments.id AND departments.name = 'HR'
       RETURNING employees.id, employees.name;
       ```

### PostgreSQL-Specific Considerations
- **RETURNING Clause**: PostgreSQL allows `INSERT`, `UPDATE`, and `DELETE` to return affected rows, which is not standard SQL.
  - Example:
    ```sql
    INSERT INTO employees (name) VALUES ('David Brown') RETURNING id, name;
    ```
- **ON CONFLICT**: Unique to PostgreSQL, this handles conflicts during `INSERT` (e.g., upsert operations).
  - Example:
    ```sql
    INSERT INTO employees (id, name) VALUES (1, 'Eve Green')
    ON CONFLICT (id) DO NOTHING;
    ```
- **JSON/JSONB Support**: PostgreSQL’s DML commands can manipulate JSON data efficiently.
  - Example:
    ```sql
    UPDATE employees
    SET data = jsonb_set(data, '{role}', '"senior"', true)
    WHERE data->>'name' = 'Alice';
    ```
- **Advanced Joins and CTEs**: PostgreSQL supports Common Table Expressions (CTEs) and complex joins in `SELECT`, `UPDATE`, and `DELETE`.
  - Example with CTE:
    ```sql
    WITH moved_employees AS (
        DELETE FROM employees WHERE department_id = 5 RETURNING *
    )
    INSERT INTO archive_employees SELECT * FROM moved_employees;
    ```

### Summary
- **Standard SQL DML Commands**: `SELECT`, `INSERT`, `UPDATE`, `DELETE`.
- **PostgreSQL DML**: Fully supports standard SQL DML with extensions like `RETURNING`, `ON CONFLICT`, `DISTINCT ON`, JSON/JSONB manipulation, and CTEs.
- **Key Difference**: PostgreSQL enhances DML with powerful features for conflict handling, returning modified data, and advanced querying, making it more flexible than standard SQL.



##### *Tags : [[1 - SQL 🦬]]