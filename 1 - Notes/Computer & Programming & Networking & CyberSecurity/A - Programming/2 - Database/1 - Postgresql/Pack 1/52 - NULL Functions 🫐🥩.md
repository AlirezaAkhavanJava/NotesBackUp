

# **SQL / PostgreSQL: NULL Handling Functions**

Null handling is **critical** because SQL treats `NULL` as an **unknown value**, which behaves differently from 0, empty string, or false.

---

## **1. ISNULL**

### **1.1 SQL Server**

```sql
ISNULL(expression, replacement)
```

- Replaces `NULL` with a **specified replacement value**.
    

**Example (SQL Server):**

```sql
SELECT ISNULL(NULL, 10);  -- Result: 10
SELECT ISNULL(5, 10);     -- Result: 5
```

### **1.2 PostgreSQL Equivalent**

- PostgreSQL **does not have ISNULL**.
    
- Use `COALESCE()` instead.
    

```sql
SELECT COALESCE(NULL, 10); -- 10
SELECT COALESCE(5, 10);    -- 5
```

---

## **2. NULLIF**

### **2.1 Definition**

- Returns `NULL` if two expressions are equal; otherwise returns the first expression.
    

```sql
NULLIF(expression1, expression2)
```

**Examples:**

```sql
SELECT NULLIF(5, 5);   -- NULL
SELECT NULLIF(5, 10);  -- 5
SELECT NULLIF('abc', 'abc'); -- NULL
```

- Useful to avoid division by zero:
    

```sql
SELECT 10 / NULLIF(0, 0); -- NULL instead of error
```

---

## **3. COALESCE**

### **3.1 Definition**

- Returns the **first non-NULL value** from a list of expressions.
    

```sql
COALESCE(expr1, expr2, expr3, ...)
```

**Examples:**

```sql
SELECT COALESCE(NULL, NULL, 10, 20);  -- 10
SELECT COALESCE(NULL, 'hello', 'world'); -- 'hello'
```

- Can be used in `SELECT`, `INSERT`, `UPDATE` to provide defaults:
    

```sql
SELECT name, COALESCE(nickname, 'No nickname') AS display_name
FROM users;
```

---

## **4. IS NULL / IS NOT NULL**

### **4.1 IS NULL**

- Checks if a value is NULL.
    

```sql
SELECT *
FROM users
WHERE nickname IS NULL;
```

- Returns all rows where `nickname` is NULL.
    

### **4.2 IS NOT NULL**

- Checks if a value is **not NULL**.
    

```sql
SELECT *
FROM users
WHERE nickname IS NOT NULL;
```

---

## **5. Combined Examples**

### **5.1 Filtering and Default Values**

```sql
SELECT 
    name,
    COALESCE(nickname, 'No nickname') AS display_name
FROM users
WHERE age IS NOT NULL;
```

- Filters only rows where `age` is known and provides a default nickname if missing.
    

### **5.2 Preventing Division by Zero**

```sql
SELECT
    total,
    NULLIF(total, 0) AS safe_total,
    amount / NULLIF(total, 0) AS ratio
FROM sales;
```

- `NULLIF(total,0)` avoids division by zero by returning `NULL`.
    

### **5.3 Combining COALESCE and NULLIF**

```sql
SELECT 
    COALESCE(NULLIF(user_input, ''), 'default_value') AS final_value;
```

- If `user_input` is empty string → treat as NULL → then replace with `'default_value'`.
    

---

## **6. Key Notes**

|Function|PostgreSQL Equivalent|Description|
|---|---|---|
|ISNULL(expr, val)|COALESCE(expr, val)|Replace NULL with default|
|NULLIF(a, b)|NULLIF(a, b)|Return NULL if equal, else a|
|COALESCE(a,b,...)|COALESCE(a,b,...)|First non-NULL value|
|IS NULL|IS NULL|Check if value is NULL|
|IS NOT NULL|IS NOT NULL|Check if value is NOT NULL|

**Tips:**

- Use **COALESCE** for defaults and filling missing values.
    
- Use **NULLIF** for conditional NULL (like avoiding errors).
    
- `IS NULL` / `IS NOT NULL` is essential in `WHERE` clauses because `= NULL` **does not work**.
    

---

## ✅ **Goat Mode TL;DR**

- **ISNULL** → SQL Server only → `COALESCE` in PostgreSQL
    
- **NULLIF** → returns NULL if two values match
    
- **COALESCE** → first non-NULL value
    
- **IS NULL / IS NOT NULL** → check for NULL values in queries
    
- Always remember: **NULL ≠ 0 ≠ empty string**
    


### Tags : [[1 - SQL 🦬]]