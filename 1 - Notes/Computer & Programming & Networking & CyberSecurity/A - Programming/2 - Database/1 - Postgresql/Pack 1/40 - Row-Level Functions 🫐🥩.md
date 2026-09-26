


## 🧱 **1. BASIC LEVEL**

### 🔹 Definition

**Row-level functions** operate **on individual rows** of a table, returning a **single value per row**.  
They are sometimes called **scalar functions** because their output is scalar (one value per row).

---

### 🔹 Examples of Built-in Row-Level Functions

|Category|Function|Example|Output|
|---|---|---|---|
|String|`UPPER(text)`|`UPPER('alice')`|`ALICE`|
|String|`LOWER(text)`|`LOWER('BOB')`|`bob`|
|Numeric|`ROUND(num,2)`|`ROUND(3.1415,2)`|`3.14`|
|Numeric|`CEIL(num)`|`CEIL(3.2)`|`4`|
|Date/Time|`EXTRACT(YEAR FROM date)`|`EXTRACT(YEAR FROM '2025-01-01')`|`2025`|
|Conditional|`COALESCE(col, 'default')`|`COALESCE(NULL, 'x')`|`'x'`|

**Example in a table:**

```sql
SELECT name, UPPER(name) AS upper_name FROM employees;
```

- Operates on **each row** of the `name` column.
    

---

## ⚙️ **2. INTERMEDIATE LEVEL — User-Defined Row-Level Functions**

### 🔹 Syntax (PL/pgSQL)

```sql
CREATE FUNCTION function_name(param datatype)
RETURNS datatype AS $$
BEGIN
   RETURN param + 10;  -- example
END;
$$ LANGUAGE plpgsql;
```

### 🔹 Example: Increment Salary

```sql
CREATE FUNCTION increment_salary(s NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
   RETURN s * 1.1;
END;
$$ LANGUAGE plpgsql;
```

Call it:

```sql
SELECT id, name, increment_salary(salary) FROM employees;
```

- Each row’s `salary` is processed individually.
    

---

### 🔹 Example: Format Full Name

```sql
CREATE FUNCTION full_name(first VARCHAR, last VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
   RETURN INITCAP(first) || ' ' || INITCAP(last);
END;
$$ LANGUAGE plpgsql;
```

Call:

```sql
SELECT full_name(first_name, last_name) FROM employees;
```

---

## 🧠 **3. ADVANCED LEVEL**

### 🔹 Characteristics of Row-Level Functions

1. Operate **per row** (not aggregating across multiple rows)
    
2. Can return **scalar** or **complex types** (ROW, composite type)
    
3. Can be **IMMUTABLE**, **STABLE**, or **VOLATILE**
    

### 🔹 Set-returning Row Functions

- Some row-level functions can return a **row or set of rows** (table functions):
    

```sql
CREATE FUNCTION get_employee_info(eid INT)
RETURNS TABLE(id INT, name VARCHAR, salary NUMERIC) AS $$
BEGIN
   RETURN QUERY SELECT id, name, salary FROM employees WHERE id = eid;
END;
$$ LANGUAGE plpgsql;
```

Call:

```sql
SELECT * FROM get_employee_info(2);
```

---

### 🔹 ROW Types and Composite Returns

- You can return an entire **row type**:
    

```sql
CREATE FUNCTION get_employee_row(eid INT)
RETURNS employees AS $$
DECLARE emp_row employees%ROWTYPE;
BEGIN
   SELECT * INTO emp_row FROM employees WHERE id = eid;
   RETURN emp_row;
END;
$$ LANGUAGE plpgsql;
```

- Useful for **procedures that operate per row**.
    

---

## ⚔️ **4. COMMON MISTAKES / RULES**

1. ❌ Forgetting `RETURNS` type → function fails
    
2. ❌ Returning a **different type than declared**
    
3. ❌ Using aggregate logic inside a pure row-level function (should be set-level)
    
4. ❌ Not handling NULLs per row → unexpected results
    

---

## 🚀 **5. REAL-WORLD USE CASES**

- Apply a discount per order row:
    

```sql
CREATE FUNCTION apply_discount(price NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
   RETURN price * 0.9;
END;
$$ LANGUAGE plpgsql;
```

- Normalize names per row for reporting:
    

```sql
SELECT full_name(first_name, last_name) FROM employees;
```

- Extract components of a date per row:
    

```sql
SELECT id, EXTRACT(YEAR FROM hire_date) AS hire_year FROM employees;
```

---

## 📋 **6. Quick Cheatsheet**

|Feature|Row-Level Function|
|---|---|
|Operates|On each row individually|
|Returns|Scalar or ROW|
|Built-in Examples|`UPPER`, `LOWER`, `ROUND`, `COALESCE`, `EXTRACT`|
|User-Defined|PL/pgSQL functions with `RETURNS type`|
|Stability|IMMUTABLE, STABLE, VOLATILE|
|Common Mistakes|Type mismatch, missing RETURN, aggregates inside row-level function|

---

🐐 **Mental Model:**

- Think of **row-level functions as “one-at-a-time processors”**. Each row goes in, function runs, row comes out transformed.
    
- Compare: **row-level** = 1 pancake at a time, **aggregate function** = stack all pancakes and then compute something.
    

---

## 1️⃣ **Row-Level vs Set-Level Functions (Important Detail)**

- **Row-level functions**: operate **one row at a time**, return a **single value** (scalar) per row.
    
    - Example: `UPPER(name)` → returns transformed value per row.
        
- **Set-level / Aggregate functions**: operate on **multiple rows at once**, return **one value per group**.
    
    - Example: `SUM(salary)` → total for all rows or group.
        

⚠️ **Mistake people make:** Using aggregate logic in row-level function thinking it will give row-wise output — it doesn’t.

---

## 2️⃣ **Row-Type Functions / Composite Returns**

- PostgreSQL allows returning **entire rows or custom composite types**:
    

```sql
CREATE FUNCTION get_employee_row(eid INT)
RETURNS employees AS $$
DECLARE emp_row employees%ROWTYPE;
BEGIN
   SELECT * INTO emp_row FROM employees WHERE id = eid;
   RETURN emp_row;
END;
$$ LANGUAGE plpgsql;
```

- Returns a **whole row**, not just a single column.
    

**Tip:** You can use `%ROWTYPE` to match any table or variable type dynamically.

---

## 3️⃣ **Volatility / Stability Matters**

- Row-level functions can be:
    
    - **IMMUTABLE** – always returns same result for same inputs (great for indexing)
        
    - **STABLE** – same output within a query but may change across queries (e.g., `CURRENT_DATE`)
        
    - **VOLATILE** – output may change anytime (default, e.g., random number generator)
        

⚠️ **Mistake:** Using `VOLATILE` function in an index — PostgreSQL disallows it because the output can change unpredictably per row.

---

## 4️⃣ **NULL Handling**

- Every row can contain `NULL` → row-level function must **explicitly handle nulls** if you want consistent results.
    

```sql
CREATE FUNCTION safe_upper(text) RETURNS text AS $$
BEGIN
  RETURN CASE WHEN $1 IS NULL THEN 'UNKNOWN' ELSE UPPER($1) END;
END;
$$ LANGUAGE plpgsql;
```

- If you ignore NULLs, you might get `NULL` instead of expected default values.
    

---

## 5️⃣ **Set-Returning Row-Level Functions**

- Functions can **return multiple rows per call**, technically row-level but producing a small table:
    

```sql
CREATE FUNCTION get_employees_in_dept(did INT)
RETURNS TABLE(id INT, name VARCHAR) AS $$
BEGIN
  RETURN QUERY SELECT id, name FROM employees WHERE dept_id = did;
END;
$$ LANGUAGE plpgsql;
```

- Each input row can generate **0, 1, or many output rows**.
    
- These are sometimes called **table functions**, but internally behave like row-level for each input.
    

---

## 6️⃣ **Function Overloading**

- PostgreSQL allows **same function name with different parameters**, even for row-level functions:
    

```sql
CREATE FUNCTION add_numbers(a INT, b INT) RETURNS INT AS $$ SELECT a+b; $$ LANGUAGE SQL;
CREATE FUNCTION add_numbers(a NUMERIC, b NUMERIC) RETURNS NUMERIC AS $$ SELECT a+b; $$ LANGUAGE SQL;
```

- Row-level function resolution is **based on input types**.
    
- **Tip:** Always carefully type your parameters to avoid ambiguity.
    

---

## 7️⃣ **Row-Level Triggers vs Row-Level Functions**

- **Row-level functions** can be used **inside triggers** to operate **per row**:
    

```sql
CREATE FUNCTION log_employee_update() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO employee_audit(emp_id, old_salary, new_salary, changed_at)
  VALUES(OLD.id, OLD.salary, NEW.salary, NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_employee_update
AFTER UPDATE ON employees
FOR EACH ROW
EXECUTE FUNCTION log_employee_update();
```

- Each updated row triggers the function individually.
    

---

## 8️⃣ **Performance Notes**

- Row-level functions are called **once per row**, so for large tables they can be **slow**.
    
- Always consider:
    
    - Minimizing procedural code inside loops
        
    - Using **SQL-language functions** instead of PL/pgSQL for simple expressions
        
    - Avoiding unnecessary queries inside the function per row
        

---

## 9️⃣ **Other PostgreSQL Specifics**

- **%ROWTYPE** and **%TYPE** allow dynamic typing matching table columns → avoids breaking function when table schema changes.
    
- Row-level functions can return **arrays, JSON, or composite types**, not just scalar values.
    
- You can use **LATERAL JOIN** to call row-level functions per row dynamically:
    

```sql
SELECT e.id, f.*
FROM employees e
JOIN LATERAL get_employee_info(e.id) f ON TRUE;
```

---

### 🐐 **Mental Model**

- **Row-Level Functions = “1 row in → 1 row/value out”**
    
- **Set-Level / Aggregate = “many rows in → 1 value out”**
    
- **Table Functions / Set-returning = “1 row in → 0..n rows out”**
    

Row-level functions are your **per-row transformers**, auditors, and triggers — fundamental for PostgreSQL logic.

---



### Tags : [[1 - SQL 🦬]]