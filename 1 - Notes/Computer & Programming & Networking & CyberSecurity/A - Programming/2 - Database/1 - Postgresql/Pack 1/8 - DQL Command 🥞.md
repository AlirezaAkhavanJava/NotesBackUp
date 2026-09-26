Date : 2025-08-30


DQL (Data Query Language) is a subset of SQL focused on retrieving and querying data from a database. 

While not always distinguished as a separate category in standard SQL (as it’s often grouped under DML), DQL specifically refers to the `SELECT` command used to fetch data.



### DQL Command in SQL (and PostgreSQL)
1. **SELECT**
   - **Purpose**: Retrieves data from one or more tables, views, or other database objects.
   - **Standard SQL Example**:
     ```sql
     SELECT id, name, hire_date
     FROM employees
     WHERE salary > 50000
     ORDER BY hire_date DESC;
     ```
   - **Key Components**:
     - **Columns**: Specify columns to retrieve (e.g., `id, name`) or use `*` for all columns.
     - **FROM**: Indicates the table(s) or source(s).
     - **WHERE**: Filters rows based on conditions.
     - **ORDER BY**: Sorts results.
     - **Optional Clauses**: Includes `GROUP BY` for aggregation, `HAVING` for filtering groups, `JOIN` for combining tables, etc.
     - Example with aggregation:
       ```sql
       SELECT department_id, COUNT(*) as employee_count
       FROM employees
       GROUP BY department_id
       HAVING COUNT(*) > 10;
       ```

   - **PostgreSQL Notes**:
     - PostgreSQL fully supports standard `SELECT` with additional powerful features:
       - **DISTINCT ON**: Retrieves the first row for each unique value in specified columns.
         ```sql
         SELECT DISTINCT ON (department_id) id, name, salary
         FROM employees
         ORDER BY department_id, salary DESC;
         ```
         This returns the highest-paid employee per department.
       - **Window Functions**: Perform calculations across rows related to the current row.
         ```sql
         SELECT name, salary,
                RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) as rank
         FROM employees;
         ```
       - **JSON/JSONB Queries**: Query JSON data stored in tables.
         ```sql
         SELECT data->>'name' as name, data->>'role' as role
         FROM employees
         WHERE data->>'role' = 'manager';
         ```
       - **Common Table Expressions (CTEs)**: Simplify complex queries.
         ```sql
         WITH dept_totals AS (
             SELECT department_id, SUM(salary) as total_salary
             FROM employees
             GROUP BY department_id
         )
         SELECT d.department_id, d.total_salary, e.name
         FROM dept_totals d
         JOIN employees e ON d.department_id = e.department_id
         WHERE e.salary > d.total_salary * 0.5;
         ```
       - **Full-Text Search**: PostgreSQL supports `tsvector` and `tsquery` for text search.
         ```sql
         SELECT name
         FROM employees
         WHERE to_tsvector('english', name) @@ to_tsquery('Alice & Smith');
         ```
       - **LIMIT and OFFSET**: Control the number of rows returned, useful for pagination.
         ```sql
         SELECT id, name
         FROM employees
         ORDER BY id
         LIMIT 10 OFFSET 20;
         ```

### PostgreSQL-Specific Considerations
- **Advanced Features**: PostgreSQL extends `SELECT` with `DISTINCT ON`, window functions, JSON/JSONB querying, full-text search, and CTEs, which are not all available in standard SQL.
- **Performance Optimizations**: PostgreSQL supports `EXPLAIN` to analyze query performance, which can be used with `SELECT` to optimize queries.
  ```sql
  EXPLAIN SELECT * FROM employees WHERE salary > 50000;
  ```
- **Recursive Queries**: PostgreSQL supports recursive CTEs for hierarchical data.
  ```sql
  WITH RECURSIVE org_chart AS (
      SELECT id, name, manager_id
      FROM employees
      WHERE manager_id IS NULL
      UNION ALL
      SELECT e.id, e.name, e.manager_id
      FROM employees e
      INNER JOIN org_chart oc ON e.manager_id = oc.id
  )
  SELECT * FROM org_chart;
  ```

### Summary
- **DQL in Standard SQL**: Primarily the `SELECT` command for retrieving data, with clauses like `WHERE`, `GROUP BY`, `HAVING`, `ORDER BY`, and `JOIN`.
- **DQL in PostgreSQL**: Enhances `SELECT` with features like `DISTINCT ON`, window functions, JSON/JSONB support, full-text search, CTEs, and recursive queries.
- **Key Difference**: PostgreSQL’s DQL capabilities are more advanced, offering tools for complex data retrieval not found in standard SQL.




##### *Tags : [[1 - SQL 🦬]]