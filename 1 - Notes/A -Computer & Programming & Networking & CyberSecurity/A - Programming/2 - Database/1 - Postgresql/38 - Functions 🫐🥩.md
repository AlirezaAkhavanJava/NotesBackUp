


## 🧱 **1. BASIC LEVEL**

### 🔹 Definition

A **function** is a piece of SQL code that **performs a task and returns a value**.

- Built-in functions: provided by SQL/PostgreSQL
    
- User-defined functions: created by users
    

Functions can:

- Compute values
    
- Transform data
    
- Aggregate results
    

---

### 🔹 Types of Built-in Functions

|Type|Example|
|---|---|
|**String**|`UPPER(name)`, `LOWER(name)`, `CONCAT(first, last)`|
|**Numeric**|`ROUND(salary,2)`, `CEIL(value)`, `FLOOR(value)`|
|**Date/Time**|`NOW()`, `CURRENT_DATE`, `AGE(birthdate)`|
|**Aggregate**|`SUM(salary)`, `AVG(salary)`, `COUNT(*)`|
|**Conditional**|`COALESCE(col, 'default')`, `NULLIF(a,b)`|

**Example:**

```sql
SELECT UPPER(name) FROM employees;
SELECT ROUND(salary,2) FROM employees;
```

---

## ⚙️ **2. INTERMEDIATE LEVEL — User-Defined Functions (UDFs)**

### 🔹 Syntax (PostgreSQL)

```sql
CREATE [OR REPLACE] FUNCTION function_name(parameters)
RETURNS return_type AS $$
BEGIN
   -- function body
   RETURN value;
END;
$$ LANGUAGE plpgsql;
```

### 🔹 Example: Add Two Numbers

```sql
CREATE FUNCTION add_numbers(a INT, b INT)
RETURNS INT AS $$
BEGIN
   RETURN a + b;
END;
$$ LANGUAGE plpgsql;
```

Call it:

```sql
SELECT add_numbers(5, 7);  -- Output: 12
```

### 🔹 Example: String Function

```sql
CREATE FUNCTION full_name(first VARCHAR, last VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
   RETURN first || ' ' || last;
END;
$$ LANGUAGE plpgsql;
```

---

## 🧠 **3. ADVANCED LEVEL**

### 🔹 Function Types in PostgreSQL

|Type|Description|
|---|---|
|**IMMUTABLE**|Always returns same output for same input; can be used in indexes|
|**STABLE**|Returns same output within a single query but may vary across queries|
|**VOLATILE**|Output may change at any time (default for most functions)|

```sql
CREATE FUNCTION square(x INT) RETURNS INT
AS $$ SELECT x*x; $$ 
LANGUAGE SQL IMMUTABLE;
```

### 🔹 Set-returning Functions

Functions can return **tables or sets**:

```sql
CREATE FUNCTION get_employees()
RETURNS TABLE(id INT, name VARCHAR) AS $$
BEGIN
   RETURN QUERY SELECT id, name FROM employees;
END;
$$ LANGUAGE plpgsql;
```

Call it:

```sql
SELECT * FROM get_employees();
```

### 🔹 Function Overloading

You can create **multiple functions with same name but different parameters**.

```sql
CREATE FUNCTION multiply(a INT, b INT) RETURNS INT AS $$ SELECT a*b; $$ LANGUAGE SQL;
CREATE FUNCTION multiply(a NUMERIC, b NUMERIC) RETURNS NUMERIC AS $$ SELECT a*b; $$ LANGUAGE SQL;
```

---

## ⚔️ **4. COMMON MISTAKES / RULES**

1. ❌ Forgetting `RETURN` statement in PL/pgSQL functions → error
    
2. ❌ Mismatched `RETURNS` type and returned value
    
3. ❌ Using `VOLATILE` functions in indexes → performance issues
    
4. ❌ Calling functions without parentheses (for some SQL functions)
    
5. ❌ Not handling NULLs properly in function logic
    

---

## 🚀 **5. REAL-WORLD USE CASES**

- Compute salary after tax:
    

```sql
CREATE FUNCTION salary_after_tax(salary NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
   RETURN salary * 0.8;
END;
$$ LANGUAGE plpgsql;
```

- Format names for reports:
    

```sql
CREATE FUNCTION report_name(first VARCHAR, last VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
   RETURN INITCAP(first) || ' ' || INITCAP(last);
END;
$$ LANGUAGE plpgsql;
```

- Return multiple rows dynamically:
    

```sql
CREATE FUNCTION high_salary(threshold NUMERIC)
RETURNS TABLE(id INT, name VARCHAR, salary NUMERIC) AS $$
BEGIN
   RETURN QUERY SELECT id, name, salary FROM employees WHERE salary > threshold;
END;
$$ LANGUAGE plpgsql;
```

---

## 📋 **6. Quick Rules / Cheatsheet**

|Rule|Description|
|---|---|
|1|Use `RETURNS type` to define return type|
|2|Use `RETURN` to output a value|
|3|Use `IMMUTABLE`, `STABLE`, or `VOLATILE` to declare stability|
|4|Parameters must have types|
|5|Functions can return `SCALAR`, `TABLE`, or `SETOF`|
|6|Use `LANGUAGE SQL` for simple queries, `plpgsql` for procedural logic|
|7|Always handle NULLs explicitly if needed|

---


##### Tags : [[1 - SQL 🥞]]