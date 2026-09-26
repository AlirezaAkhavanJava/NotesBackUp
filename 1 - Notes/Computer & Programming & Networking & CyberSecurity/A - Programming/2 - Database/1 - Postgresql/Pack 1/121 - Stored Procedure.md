

## **1. What is a Stored Procedure?**

A **stored procedure** is a set of SQL statements that you can save and execute repeatedly. Unlike regular SQL queries, stored procedures can:

- Accept parameters.
    
- Contain control-flow logic (`IF`, `LOOP`, `WHILE`, etc.).
    
- Return results (optional).
    
- Encapsulate complex operations in the database itself.
    

Think of it as a little program inside your database. 🐐

---

## **2. Syntax to Create a Stored Procedure**

PostgreSQL 11+ supports **stored procedures** (`CALL`) separately from functions (`SELECT function()`).

```sql
CREATE PROCEDURE procedure_name (parameters)
LANGUAGE plpgsql
AS $$
BEGIN
    -- SQL statements here
END;
$$;
```

### **Example 1: Simple procedure**

```sql
CREATE PROCEDURE greet_user(name text)
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Hello, %!', name;
END;
$$;
```

**Call it:**

```sql
CALL greet_user('Ethan');
```

Output:

```
NOTICE: Hello, Ethan!
```

---

### **Example 2: Procedure with logic and database operations**

```sql
CREATE PROCEDURE update_student_mark(student_id INT, new_mark NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE students
    SET mark = new_mark
    WHERE id = student_id;
    
    RAISE NOTICE 'Student % mark updated to %', student_id, new_mark;
END;
$$;
```

Call it:

```sql
CALL update_student_mark(1, 95);
```

---

## **3. Key Points**

1. **Procedures vs Functions**
    
    - **Procedures**: Use `CALL`, cannot be used in `SELECT`. Can do transactions (`COMMIT`, `ROLLBACK`).
        
    - **Functions**: Use `SELECT`, return a value, cannot manage transactions.
        
2. **Parameters**
    
    - IN (default): Input only
        
    - OUT: Output only
        
    - INOUT: Input and output
        
3. **Control Structures**
    
    - `IF ... THEN ... ELSE ... END IF;`
        
    - `FOR ... LOOP ... END LOOP;`
        
    - `WHILE ... LOOP ... END LOOP;`
        
4. **Transactions**
    
    - Inside procedures, you can manage transactions with `COMMIT` and `ROLLBACK`.
        
    - Functions **cannot** do transaction control.
        

---

## **4. Example: Procedure with IN and OUT Parameters**

```sql
CREATE PROCEDURE get_student_avg(
    IN student_id INT,
    OUT avg_mark NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT AVG(mark) INTO avg_mark
    FROM student_marks
    WHERE id = student_id;
END;
$$;
```

Call it:

```sql
CALL get_student_avg(1, avg_mark);
```

After execution, `avg_mark` will hold the value.

---

```sql
CREATE OR REPLACE PROCEDURE studentsSUMMARY(
    countryName TEXT,
    OUT total_students BIGINT,
    OUT avg_mark NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT 
        COUNT(*),
        ROUND(AVG(mark), 2)
    INTO 
        total_students,
        avg_mark
    FROM students
    WHERE country = countryName;

    -- If no rows match, the OUT parameters will be NULL
    -- Optionally handle no data case:
    IF total_students IS NULL THEN
        total_students := 0;
        avg_mark := NULL;  -- or 0 if preferred
    END IF;
END;
$$;
```

###### Tags : [[1 - SQL 🦬]]