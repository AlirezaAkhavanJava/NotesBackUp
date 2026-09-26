


# **SQL / PostgreSQL: CAST, CONVERT, FORMAT**

These functions are about **type conversion** and **formatting values**. PostgreSQL handles some differently than SQL Server, so we’ll cover both.

---

## **1. CAST**

### **1.1 Definition**

`CAST` converts a value from one data type to another.  
It’s standard SQL and fully supported in PostgreSQL.

### **1.2 Syntax**

```sql
CAST(expression AS target_data_type)
```

**Example 1: String to Integer**

```sql
SELECT CAST('123' AS INTEGER) AS number;
-- Result: 123
```

**Example 2: Integer to Text**

```sql
SELECT CAST(123 AS TEXT) AS text_value;
-- Result: '123'
```

**Example 3: Date conversion**

```sql
SELECT CAST('2025-10-19' AS DATE) AS my_date;
```

### **1.3 PostgreSQL Shortcut**

You can also use `::` operator:

```sql
SELECT '123'::INTEGER AS number;
SELECT '2025-10-19'::DATE AS my_date;
```

---

## **2. CONVERT**

### **2.1 Definition**

- In **SQL Server**, `CONVERT` changes data type **and optionally formats dates**.
    
- PostgreSQL doesn’t have `CONVERT` like SQL Server, but you can use `CAST` or `TO_CHAR` for formatting.
    

### **2.2 SQL Server Syntax**

```sql
-- Convert value to another type
CONVERT(target_data_type, expression [, style])
```

**Example: Convert string to integer**

```sql
SELECT CONVERT(INT, '123') AS number;
```

**Example: Convert date to string with style**

```sql
SELECT CONVERT(VARCHAR, GETDATE(), 23) AS formatted_date;
-- 23 = yyyy-mm-dd
```

### **2.3 PostgreSQL Equivalent**

- Use `CAST` or `::` for type conversion.
    
- Use `TO_CHAR` for formatting dates or numbers.
    

**Date formatting example:**

```sql
SELECT TO_CHAR(NOW(), 'YYYY-MM-DD') AS formatted_date;
SELECT TO_CHAR(NOW(), 'DD/MM/YYYY HH24:MI:SS') AS formatted_timestamp;
```

**Number formatting:**

```sql
SELECT TO_CHAR(12345.678, '99999.99') AS formatted_number;
```

---

## **3. FORMAT (PostgreSQL specific)**

### **3.1 Definition**

`FORMAT` creates formatted strings using placeholders (like `printf` in C).

### **3.2 Syntax**

```sql
FORMAT(format_string, arguments...)
```

**Placeholders:**

- `%s` → string
    
- `%I` → identifier (table/column name)
    
- `%L` → literal (escapes quotes automatically)
    
- `%d` → integer
    
- `%f` → floating-point number
    

### **3.3 Examples**

```sql
-- Simple string formatting
SELECT FORMAT('Hello %s, today is %s', 'Ethan', CURRENT_DATE);

-- Numbers
SELECT FORMAT('Price: $%0.2f', 123.456);
-- Result: 'Price: $123.46'

-- Dynamic identifiers
SELECT FORMAT('SELECT * FROM %I WHERE id = %L', 'students', 123);
-- Result: 'SELECT * FROM students WHERE id = 123'
```

- `FORMAT` is extremely useful for dynamic SQL generation in PostgreSQL.
    

---

## **4. Key Differences Between CAST, CONVERT, FORMAT**

|Function|PostgreSQL|SQL Server|Use Case|
|---|---|---|---|
|CAST|✅ Supported (`CAST(expr AS type)` or `::`)|✅ Supported|Convert between types (string ↔ int, date ↔ text)|
|CONVERT|❌ Not supported, use CAST or TO_CHAR|✅ Supported (`CONVERT(type, expr, style)`)|Convert types, optionally format dates|
|FORMAT|✅ Supported|✅ Supported|Create formatted strings, dynamic SQL, print numbers/dates nicely|

---

## **5. Advanced Examples**

### **5.1 Convert and Format in one query**

```sql
SELECT TO_CHAR(CAST('2025-10-19' AS DATE), 'Day, DD Month YYYY') AS formatted_date;
```

- Converts string to date, then formats nicely.
    

### **5.2 Combine numbers and strings**

```sql
SELECT FORMAT('User %s has score %.2f', 'Ethan', 95.678);
-- Result: 'User Ethan has score 95.68'
```

### **5.3 Dynamic SQL using FORMAT**

```sql
DO $$
DECLARE table_name text := 'students';
BEGIN
    EXECUTE FORMAT('SELECT COUNT(*) FROM %I', table_name);
END $$;
```

---

## ✅ **Goat Mode Summary**

- **CAST** → convert types (int ↔ text, string ↔ date) → `CAST(expr AS type)` or `'expr'::type`
    
- **CONVERT** → SQL Server only, use `CAST`/`TO_CHAR` in PostgreSQL
    
- **FORMAT** → fancy string formatting (`%s, %d, %L`) → dynamic SQL or readable output
    
- **Tip:** PostgreSQL separates **type conversion** (`CAST`) and **formatting** (`TO_CHAR`, `FORMAT`), unlike SQL Server which mixes both in `CONVERT`.
    

---

I can also make a **super cheat sheet for all PostgreSQL conversion & formatting functions** including **string ↔ number ↔ date**, with **50+ code examples for real-world queries**, if you want.

Do you want me to do that next?

### Tags : [[1 - SQL 🦬]]