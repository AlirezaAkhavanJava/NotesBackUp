


## 🧱 1. Types of Parameters

PostgreSQL supports **three kinds** of parameters in stored procedures:

|Type|Meaning|Used for|
|---|---|---|
|`IN`|Input only|Pass data **into** the procedure|
|`OUT`|Output only|Return data **from** the procedure|
|`INOUT`|Both input and output|Modify and return data|

---

### 🧩 **Example 1: IN parameters**

```sql
CREATE PROCEDURE add_employee(IN name TEXT, IN salary NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO employees (name, salary) VALUES (name, salary);
END;
$$;
```

➡️ Called with:

```sql
CALL add_employee('Ethan', 5000);
```

---

### 🧩 **Example 2: OUT parameters**

```sql
CREATE PROCEDURE get_salary(IN emp_name TEXT, OUT emp_salary NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT salary INTO emp_salary
    FROM employees
    WHERE name = emp_name;
END;
$$;
```

➡️ Call and view output:

```sql
CALL get_salary('Ethan', NULL);
```

It returns the salary in the output column.

---

### 🧩 **Example 3: INOUT parameters**

```sql
CREATE PROCEDURE adjust_salary(INOUT emp_salary NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    emp_salary := emp_salary * 1.1;  -- increase by 10%
END;
$$;
```

Call:

```sql
CALL adjust_salary(5000);
-- returns 5500
```

---

## 💻 2. In **Spring Boot**

### **IN parameters (most common)**

```java
jdbc.update("CALL add_employee(?, ?)", "Ethan", 5000);
```

### **OUT parameters**

To capture outputs, use `SimpleJdbcCall`:

```java
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import java.util.Map;

@Service
public class EmployeeService {

    private final JdbcTemplate jdbc;
    private SimpleJdbcCall getSalaryCall;

    public EmployeeService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @PostConstruct
    void init() {
        getSalaryCall = new SimpleJdbcCall(jdbc)
            .withProcedureName("get_salary");
    }

    public double getSalary(String name) {
        Map<String, Object> result = getSalaryCall
            .execute(Map.of("emp_name", name));
        return (Double) result.get("emp_salary");
    }
}
```

---

## ⚙️ 3. Summary

|Parameter Type|Direction|Spring Boot usage|
|---|---|---|
|`IN`|Input only|`jdbc.update("CALL proc(?, ?)", ...)`|
|`OUT`|Output only|Use `SimpleJdbcCall`|
|`INOUT`|Input + output|`SimpleJdbcCall` (same)|

---

### ✅ **Using a FUNCTION** (recommended — because it can _return_ data)

PostgreSQL **procedures (`CREATE PROCEDURE`)** don’t return result sets directly,  
so we use a **function** with `RETURNS TABLE`.

```sql
CREATE OR REPLACE FUNCTION GetCustomerSummary(country TEXT)
RETURNS TABLE(
    total_customers BIGINT,
    avg_score NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) AS total_customers,
        AVG(score) AS avg_score
    FROM sales.customers
    WHERE sales.customers.country = country;
END;
$$;
```

---

### ⚙️ **Run it**

```sql
SELECT * FROM GetCustomerSummary('USA');
```

Output:

|total_customers|avg_score|
|---|---|
|152|87.3|

---

### 💡 If You _Must_ Use a PROCEDURE

You can print the result using `RAISE NOTICE`, but it won’t return a table:

```sql
CREATE OR REPLACE PROCEDURE GetCustomerSummaryProc(country TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    total INTEGER;
    avgscore NUMERIC;
BEGIN
    SELECT COUNT(*), AVG(score)
    INTO total, avgscore
    FROM sales.customers
    WHERE sales.customers.country = country;

    RAISE NOTICE 'Total: %, AvgScore: %', total, avgscore;
END;
$$;
```

Call it:

```sql
CALL GetCustomerSummaryProc('USA');
```

Output in console:

```
NOTICE:  Total: 152, AvgScore: 87.3
```

---

✅ **Summary:**

|Type|Returns Result Set?|Syntax|
|---|---|---|
|`FUNCTION`|✅ Yes (`SELECT * FROM ...`)|`CREATE FUNCTION ... RETURNS TABLE ...`|
|`PROCEDURE`|❌ No (only prints)|`CREATE PROCEDURE ... CALL ...`|

---




##### Tags : [[1 - SQL 🥞]]