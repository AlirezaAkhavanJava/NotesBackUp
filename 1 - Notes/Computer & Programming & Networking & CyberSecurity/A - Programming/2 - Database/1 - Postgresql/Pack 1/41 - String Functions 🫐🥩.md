

## 🧱 **1. BASIC LEVEL**

### 🔹 Definition

**String functions** operate on **text/string values** to transform, manipulate, or extract information.

- Input: `VARCHAR`, `TEXT`, or `CHAR`
    
- Output: typically `TEXT` or `VARCHAR`
    

---

### 🔹 Common Built-in String Functions

|Function|Description|Example|Output|
|---|---|---|---|
|`UPPER(str)`|Converts text to uppercase|`UPPER('alice')`|`'ALICE'`|
|`LOWER(str)`|Converts text to lowercase|`LOWER('BOB')`|`'bob'`|
|`INITCAP(str)`|Capitalizes first letter of each word|`INITCAP('john doe')`|`'John Doe'`|
|`LENGTH(str)`|Returns string length|`LENGTH('abc')`|`3`|
|`TRIM(str)`|Removes leading/trailing spaces|`TRIM(' abc ')`|`'abc'`|
|`CONCAT(str1,str2,...)`|Concatenates multiple strings|`CONCAT('a','b')`|`'ab'`|
|`||` operator|Alternative to CONCAT|

---

### 🔹 Example

```sql
SELECT UPPER(name), LENGTH(name) FROM employees;
```

- Works **row-by-row**, typical **row-level function**.
    

---

## ⚙️ **2. INTERMEDIATE LEVEL**

### 🔹 Substring / Position Functions

|Function|Description|Example|Output|
|---|---|---|---|
|`SUBSTRING(str FROM start FOR length)`|Extract part of string|`SUBSTRING('abcdef' FROM 2 FOR 3)`|`'bcd'`|
|`LEFT(str, n)`|First n characters|`LEFT('abcdef',3)`|`'abc'`|
|`RIGHT(str, n)`|Last n characters|`RIGHT('abcdef',2)`|`'ef'`|
|`POSITION(substr IN str)`|Find position of substring|`POSITION('c' IN 'abcdef')`|`3`|

### 🔹 Pattern Matching

- `LIKE` / `ILIKE` (case-insensitive)
    

```sql
SELECT name FROM employees WHERE name LIKE 'A%';
```

- Regular expressions:
    

```sql
SELECT REGEXP_REPLACE('abc123', '\d', '') AS letters_only;
-- Output: 'abc'
```

---

### 🔹 Advanced Concatenation

- `CONCAT_WS(separator, str1, str2, ...)` → concatenate with separator:
    

```sql
SELECT CONCAT_WS(', ', first_name, last_name);
-- Output: 'John, Doe'
```

---

## 🧠 **3. ADVANCED LEVEL — PostgreSQL Specific**

### 🔹 Unicode & Multi-byte Characters

- Functions like `LENGTH` vs `CHAR_LENGTH` vs `OCTET_LENGTH`:
    

```sql
SELECT LENGTH('é');        -- 1 character
SELECT OCTET_LENGTH('é');  -- 2 bytes (UTF-8)
```

### 🔹 Trim Variants

- `LTRIM(str, chars)` → remove leading specific chars
    
- `RTRIM(str, chars)` → remove trailing specific chars
    

```sql
SELECT LTRIM('---abc','-'); -- 'abc'
```

### 🔹 Regex Functions

|Function|Description|
|---|---|
|`REGEXP_MATCHES(str, pattern)`|Returns all matching substrings|
|`REGEXP_REPLACE(str, pattern, replacement)`|Replace substrings via regex|
|`REGEXP_SPLIT_TO_TABLE(str, pattern)`|Split string into multiple rows|
|`REGEXP_SPLIT_TO_ARRAY(str, pattern)`|Split string into array|

**Example:**

```sql
SELECT REGEXP_REPLACE('Phone: 123-456-7890', '\D','','g');
-- Output: '1234567890'
```

---

### 🔹 Conversion Functions

- Convert to numeric/date if string is valid:
    

```sql
SELECT CAST('123' AS INTEGER);
SELECT '2025-01-01'::DATE;
```

---

## ⚔️ **4. COMMON MISTAKES / RULES**

|Mistake|Rule to Fix|
|---|---|
|Forgetting NULLs|Many string functions return NULL if input is NULL → use `COALESCE`|
|Using wrong substring syntax|PostgreSQL: `SUBSTRING(str FROM start FOR len)` or `LEFT/RIGHT`|
|Ignoring multi-byte characters|Use `CHAR_LENGTH` for characters, not bytes|
|Concatenation with NULL|`'a'|
|Regex not anchored|`^` and `$` matter in patterns|

---

## 🚀 **5. REAL-WORLD USE CASES**

1. **Normalize Names**
    

```sql
SELECT INITCAP(TRIM(name)) FROM employees;
```

2. **Extract Phone Numbers**
    

```sql
SELECT REGEXP_REPLACE(phone, '\D', '', 'g') FROM contacts;
```

3. **Split CSV Column into Rows**
    

```sql
SELECT REGEXP_SPLIT_TO_TABLE('a,b,c', ',');
```

4. **Generate Full Name**
    

```sql
SELECT CONCAT_WS(' ', first_name, last_name) FROM employees;
```

5. **Substring & Validate**
    

```sql
SELECT SUBSTRING(email FROM 1 FOR POSITION('@' IN email)-1) AS username FROM users;
```

---

## 📋 **6. Quick Cheat Sheet**

|Category|Function|Example|
|---|---|---|
|Case|`UPPER`, `LOWER`, `INITCAP`|`UPPER('abc')` → `'ABC'`|
|Length|`LENGTH`, `CHAR_LENGTH`, `OCTET_LENGTH`|`LENGTH('é')` → 1|
|Trim|`TRIM`, `LTRIM`, `RTRIM`|`TRIM(' abc ')` → `'abc'`|
|Substring|`SUBSTRING`, `LEFT`, `RIGHT`|`SUBSTRING('abcdef',2,3)` → `'bcd'`|
|Position|`POSITION`|`POSITION('c' IN 'abc')` → 3|
|Concatenate|`CONCAT`, `||
|Regex|`REGEXP_MATCHES`, `REGEXP_REPLACE`, `REGEXP_SPLIT_TO_TABLE/ARRAY`|`REGEXP_REPLACE('abc123','\d','')` → `'abc'`|
|Conversion|`CAST`, `::`|`'123'::INT` → 123|

---

💡 **Mental Model**

- Row-level string functions = **per-row text transformers**
    
- Built-in PostgreSQL functions are optimized; avoid heavy procedural logic per row if possible.
    

---


### Tags : [[1 - SQL 🦬]]