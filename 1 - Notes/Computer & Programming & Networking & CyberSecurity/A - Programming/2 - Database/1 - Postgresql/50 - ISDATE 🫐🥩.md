


# **SQL / PostgreSQL: ISDATE**

---

## **1. Definition**

- **SQL Server** has a built-in function:
    

```sql
ISDATE(expression)
```

- **Purpose:** Checks if a string can be converted to a valid date.
    
- **Returns:**
    
    - `1` → valid date
        
    - `0` → invalid date
        

**Example (SQL Server):**

```sql
SELECT ISDATE('2025-10-19') AS valid_date;   -- 1
SELECT ISDATE('2025-13-01') AS valid_date;   -- 0 (invalid month)
SELECT ISDATE('hello') AS valid_date;        -- 0
```

---

## **2. PostgreSQL Equivalent**

PostgreSQL **does not have `ISDATE`**, but you can achieve the same functionality using:

### **2.1 Using `TO_DATE` with `EXCEPTION` (PL/pgSQL)**

```sql
DO $$
DECLARE
    date_str TEXT := '2025-10-19';
    valid BOOLEAN;
BEGIN
    BEGIN
        PERFORM TO_DATE(date_str, 'YYYY-MM-DD');
        valid := TRUE;
    EXCEPTION WHEN OTHERS THEN
        valid := FALSE;
    END;
    RAISE NOTICE 'Is valid date? %', valid;
END $$;
```

- If `TO_DATE` fails, exception sets `valid = FALSE`.
    

---

### **2.2 Using a Function (Reusable)**

```sql
CREATE OR REPLACE FUNCTION is_date(text_input TEXT) RETURNS BOOLEAN AS $$
BEGIN
    PERFORM TO_DATE(text_input, 'YYYY-MM-DD');
    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Usage
SELECT is_date('2025-10-19');  -- TRUE
SELECT is_date('2025-13-01');  -- FALSE
SELECT is_date('hello');       -- FALSE
```

---

### **2.3 Using Regex Validation (Quick Check)**

For simple format validation (does not check real dates):

```sql
SELECT '2025-10-19' ~ '^\d{4}-\d{2}-\d{2}$' AS valid_format;
-- TRUE

SELECT '2025-13-01' ~ '^\d{4}-\d{2}-\d{2}$' AS valid_format;
-- TRUE (format is correct, month invalid)
```

- **Note:** Regex validates format only, not actual date validity.
    

---

### **2.4 Using `DATE` Casting in a Query**

```sql
SELECT
    CASE 
        WHEN '2025-10-19'::DATE IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS is_valid_date;
```

- Works if you can guarantee the string is mostly correct.
    
- Use with `TRY/CATCH` in PL/pgSQL to handle exceptions.
    

---

## **3. Key Notes**

1. PostgreSQL does **not have built-in ISDATE**, unlike SQL Server.
    
2. To fully validate, you need **PL/pgSQL function** with `TO_DATE` + exception handling.
    
3. Regex or simple casting only validates **format**, not real calendar validity.
    
4. Common use: cleaning imported CSV data or validating user input before inserting into a table.
    

---

## **4. Goat Mode TL;DR**

- **SQL Server:** `ISDATE('string')` → 1 or 0 ✅
    
- **PostgreSQL:** Use a function:
    

```sql
CREATE FUNCTION is_date(text_input TEXT) RETURNS BOOLEAN AS $$
BEGIN
    PERFORM TO_DATE(text_input, 'YYYY-MM-DD');
    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
```

- Use it to filter valid dates before inserting or processing.
    



### Tags : [[1 - SQL 🥞]]