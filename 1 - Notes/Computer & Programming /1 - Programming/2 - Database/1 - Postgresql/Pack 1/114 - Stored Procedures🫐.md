

### 🧱 **1. What is a Stored Procedure**

A **stored procedure** is a **block of SQL code saved in the database** that you can call and run later.  
Think of it like a **function**, but it can:

- Run multiple SQL commands
    
- Commit or rollback transactions
    
- Return no value (unlike functions)
    

>A **Stored Procedure** is like a little program or recipe that lives inside a database. You write it once, and the database can run it anytime you need.


A **stored procedure can take arguments** (parameters) and use them to **insert, update, or delete data** in a table.

Super simple example:

```sql
-- Create a stored procedure that adds a student
CREATE PROCEDURE AddStudent(IN student_name VARCHAR(50), IN student_age INT)
BEGIN
    INSERT INTO students (name, age)
    VALUES (student_name, student_age);
END;
```

Now, to use it:

```sql
CALL AddStudent('Alice', 20);
CALL AddStudent('Bob', 22);
```

This will save the data into the `students` table.

So yes, it’s just like a **Java method with parameters** that modifies your database instead of objects.


---

### 🧩 **2. Example**

```sql
CREATE PROCEDURE add_employee(name TEXT, salary NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO employees (emp_name, emp_salary)
    VALUES (name, salary);
END;
$$;
```

Now call it:

```sql
CALL add_employee('Ethan', 5000);
```

---

### ⚙️ **3. Key Difference: Procedure vs Function**

|Feature|Function|Procedure|
|---|---|---|
|Call syntax|`SELECT my_function()`|`CALL my_procedure()`|
|Returns value|Yes|No (usually)|
|Transaction control|❌ No|✅ Yes (can COMMIT/ROLLBACK)|
|Purpose|Computation|Operations / workflow|

---

### 💡 **4. Transaction Example**

```sql
CREATE PROCEDURE transfer_money(sender INT, receiver INT, amount NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    BEGIN
        UPDATE accounts SET balance = balance - amount WHERE id = sender;
        UPDATE accounts SET balance = balance + amount WHERE id = receiver;
        COMMIT; -- allowed in procedures
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE NOTICE 'Transfer failed';
    END;
END;
$$;
```

Call it:

```sql
CALL transfer_money(1, 2, 100);
```

---

### 🧠 **5. Why Use Them**

- Move business logic **into the database**
    
- Improve **performance** by reducing app–DB communication
    
- Ensure **consistency and security**
    
- Great for **batch jobs**, **ETL**, or **data cleanup**
    

---

### ⚡ **6. Summary**

|Concept|Description|
|---|---|
|Definition|Saved SQL logic block|
|Language|`plpgsql` (default)|
|Run with|`CALL procedure_name(args)`|
|Can control transactions|✅ Yes|
|Returns|Nothing (or OUT params)|


----

#### how to **call a PostgreSQL stored procedure** from **Spring Boot** ?

## 🧱 1. Example PostgreSQL Procedure

Let’s create a simple one in PostgreSQL:

```sql
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name TEXT,
    salary NUMERIC
);

CREATE PROCEDURE add_employee(name TEXT, salary NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO employees (name, salary)
    VALUES (name, salary);
END;
$$;
```

Now you can test it directly:

```sql
CALL add_employee('Ethan', 5000);
```

---

## 💻 2. Call from Spring Boot (Using `JdbcTemplate`)

```java
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class EmployeeService {

    private final JdbcTemplate jdbc;

    public EmployeeService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional
    public void addEmployee(String name, double salary) {
        jdbc.execute("CALL add_employee('" + name + "', " + salary + ")");
        System.out.println("✅ Employee added via stored procedure.");
    }
}
```

Usage:

```java
employeeService.addEmployee("Sara", 6500);
```

---

## ⚙️ 3. Better (Safe) Version — Use `?` Placeholders

Avoid SQL injection:

```java
jdbc.update("CALL add_employee(?, ?)", name, salary);
```

Spring handles parameter binding safely.

---

## 🧩 4. Using `@Scheduled` or `@RestController`

Example REST endpoint:

```java
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/employees")
public class EmployeeController {

    private final EmployeeService service;

    public EmployeeController(EmployeeService service) {
        this.service = service;
    }

    @PostMapping
    public String add(@RequestParam String name, @RequestParam double salary) {
        service.addEmployee(name, salary);
        return "Employee added successfully!";
    }
}
```

Now `POST /employees?name=Ethan&salary=7000` → runs the stored procedure.

---

## ⚡ 5. Summary

|Step|Description|
|---|---|
|Create procedure|`CREATE PROCEDURE add_employee(...)`|
|Call syntax|`CALL add_employee(?, ?)`|
|Spring integration|Use `JdbcTemplate` or `EntityManager`|
|Safe calls|Use `?` placeholders|
|Benefits|Reuse DB logic + faster operations|

---



##### Tags : [[1 - SQL 🦬]]