
In SQL, **stored procedure variables** are temporary placeholders used **inside a stored procedure** to hold values, do calculations, or control flow. They exist only during the execution of the procedure. Think of them like **local variables in Java methods**. 🐐

Here’s the breakdown:

---

### 1. **Declaring a variable**

Syntax (for SQL Server):

```sql
DECLARE @variable_name DATA_TYPE;
```

Example:

```sql
DECLARE @totalStudents INT;
DECLARE @averageMark DECIMAL(5,2);
```

In MySQL:

```sql
DECLARE variable_name DATA_TYPE [DEFAULT value];
```

Example:

```sql
DECLARE totalStudents INT DEFAULT 0;
DECLARE averageMark DECIMAL(5,2);
```

---

### 2. **Setting a value**

- SQL Server:
    

```sql
SET @totalStudents = 100;
```

- MySQL:
    

```sql
SET totalStudents = 100;
```

Or during declaration in MySQL:

```sql
DECLARE totalStudents INT DEFAULT 100;
```

---

### 3. **Using variables**

You can use them in queries, calculations, or control flow:

```sql
DECLARE @bonus DECIMAL(10,2);

SET @bonus = (SELECT AVG(salary) * 0.10 FROM employees);

IF @bonus > 1000
    PRINT 'High bonus';
ELSE
    PRINT 'Normal bonus';
```

---

### 4. **Notes**

- Scope: Only exists **inside the procedure**. Outside calls cannot see it.
    
- Type: Must declare **data type** explicitly.
    
- Lifecycle: Created when the procedure runs, destroyed when it ends.
    




##### Tags : [[1 - SQL 🥞]]