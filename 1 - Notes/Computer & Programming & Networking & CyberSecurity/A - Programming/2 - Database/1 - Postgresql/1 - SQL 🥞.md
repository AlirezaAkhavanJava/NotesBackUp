> The language 


![[Pasted image 20251210135501.png]]

# SQL Definition

## What is SQL?

SQL (Structured Query Language) is a standardized programming language used for managing and manipulating relational databases.

It enables users to perform CRUD operations (Create, Read, Update, Delete) on data, define database structures, set permissions, and execute administrative tasks.

SQL is widely supported by DMS (database management systems) such as MySQL, PostgreSQL, SQLite, Oracle, and Microsoft SQL Server.

## Key Functions of SQL

- **Querying Data**: Retrieve specific data using `SELECT` statements.
- **Inserting Data**: Add new records to a database with `INSERT` statements.
- **Updating Data**: Modify existing records using `UPDATE` statements.
- **Deleting Data**: Remove records with `DELETE` statements.
- **Database Management**: Create and modify database structures (e.g., tables, schemas) using commands like `CREATE`, `ALTER`, and `DROP`.
- **Access Control**: Manage user permissions with commands like `GRANT` and `REVOKE`.

## Example SQL Query

```sql
SELECT first_name, last_name
FROM employees
WHERE department = 'Engineering';
```

This query retrieves the first and last names of employees in the Engineering department.

## Common SQL Database Systems

- MySQL
- PostgreSQL
- SQLite
- Oracle Database
- Microsoft SQL Server

[[Java]] [[0 - Back-End]]