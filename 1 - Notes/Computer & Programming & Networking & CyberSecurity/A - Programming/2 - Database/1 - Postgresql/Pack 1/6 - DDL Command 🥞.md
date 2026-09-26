Date : 2025-08-30


> DDL (Data Definition Language) commands in SQL are ***used to define or modify the structure of database objects*** like tables, schemas, and databases. 

> They focus on creating, altering, or deleting the framework of a database, as opposed to manipulating the data itself. 


---
### Key DDL Commands in SQL (and PostgreSQL)
1. **CREATE**
   - **Purpose**: Defines a new database object (e.g., database, table, schema, index).
   - **Standard SQL Example**:
     ```sql
     CREATE TABLE employees (
         id INT PRIMARY KEY,
         name VARCHAR(100),
         hire_date DATE
     );
     ```
   - **PostgreSQL Notes**:
     - Supports standard SQL `CREATE` syntax.
     - Offers additional features like `SERIAL` for auto-incrementing IDs and `CREATE TYPE` for custom data types.
     - Example with PostgreSQL-specific features:
       ```sql
       CREATE TABLE employees (
           id SERIAL PRIMARY KEY,
           name VARCHAR(100),
           hire_date DATE DEFAULT CURRENT_DATE
       );
       CREATE TYPE employment_status AS ENUM ('active', 'inactive', 'retired');
       ```
   - PostgreSQL also supports `CREATE SCHEMA` for organizing database objects and `CREATE EXTENSION` for adding functionality (e.g., `CREATE EXTENSION postgis;`).

2. **ALTER**
   - **Purpose**: Modifies an existing database object (e.g., adding columns, changing data types, renaming objects).
   - **Standard SQL Example**:
     ```sql
     ALTER TABLE employees
     ADD COLUMN salary DECIMAL(10, 2);
     ```
   - **PostgreSQL Notes**:
     - Supports standard `ALTER` operations like `ADD COLUMN`, `DROP COLUMN`, `RENAME COLUMN`, and `ALTER COLUMN` to modify data types or constraints.
     - Allows advanced alterations, such as modifying schema ownership or adding constraints.
     - Example:
       ```sql
       ALTER TABLE employees
       ADD COLUMN department_id INT,
       ADD CONSTRAINT fk_department FOREIGN KEY (department_id) REFERENCES departments(id);
       ALTER TABLE employees
       ALTER COLUMN name SET NOT NULL;
       ```

3. **DROP**
   - **Purpose**: Deletes a database object (e.g., table, database, index).
   - **Standard SQL Example**:
     ```sql
     DROP TABLE employees;
     ```
   - **PostgreSQL Notes**:
     - Supports standard `DROP` syntax with options like `IF EXISTS` to avoid errors if the object doesn’t exist.
     - Includes `CASCADE` to drop dependent objects or `RESTRICT` to prevent dropping if dependencies exist.
     - Example:
       ```sql
       DROP TABLE employees CASCADE;
       DROP SCHEMA  IF EXISTS hr CASCADE;
       ```

4. **TRUNCATE**
   - **Purpose**: Removes all rows from a table without deleting the table structure.
   - **Standard SQL Example**:
     ```sql
     TRUNCATE TABLE employees;
     ```
   - **PostgreSQL Notes**:
     - Supports standard `TRUNCATE` with options like `CASCADE` to truncate dependent tables or `RESTART IDENTITY` to reset auto-incrementing sequences.
     - Example:
       ```sql
       TRUNCATE TABLE employees RESTART IDENTITY CASCADE;
       ```

### PostgreSQL-Specific Considerations
- **Extensions**: PostgreSQL extends DDL with commands like `CREATE EXTENSION`, `CREATE DOMAIN`, and `CREATE SEQUENCE` for advanced use cases.
  - Example:
    ```sql
    CREATE SEQUENCE employee_id_seq START 100;
    CREATE TABLE employees (
        id INT DEFAULT nextval('employee_id_seq') PRIMARY KEY,
        name TEXT
    );
    ```
- **Inheritance**: PostgreSQL supports table inheritance, a non-standard feature.
  - Example:
    ```sql
    CREATE TABLE persons (id INT, name TEXT);
    CREATE TABLE employees (salary DECIMAL) INHERITS (persons);
    ```
- **Schemas**: PostgreSQL emphasizes schemas for organizing database objects, with commands like `CREATE SCHEMA` and `ALTER SCHEMA`.
  - Example:
    ```sql
    CREATE SCHEMA hr;
    CREATE TABLE hr.employees (id SERIAL PRIMARY KEY, name VARCHAR(100));
    ```
- **Constraints**: PostgreSQL supports advanced constraints like `CHECK`, `EXCLUDE`, and `DEFERRABLE` constraints.
  - Example:
    ```sql
    CREATE TABLE bookings (
        id SERIAL PRIMARY KEY,
        room_id INT,
        start_date DATE,
        end_date DATE,
        EXCLUDE USING gist (room_id WITH =, daterange(start_date, end_date) WITH &&)
    );
    ```

### Summary
- **Standard SQL DDL Commands**: `CREATE`, `ALTER`, `DROP`, `TRUNCATE`.
- **PostgreSQL DDL**: Fully supports standard SQL DDL with extensions like `SERIAL`, `CREATE TYPE`, `CREATE SEQUENCE`, table inheritance, and advanced constraints.
- **Key Difference**: PostgreSQL offers richer functionality (e.g., schemas, extensions, inheritance) while maintaining SQL standards.

---



##### *Tags : [[1 - SQL 🦬]]