## **6. PostgreSQL Equivalent**

PostgreSQL **does not have `DATALENGTH`**, but you can achieve the same thing using:

### **6.1 `octet_length()`**

➡ Returns the number of bytes in a string or bytea expression.

**Equivalent to:**

```sql
DATALENGTH(x)  ≈  octet_length(x)
```

**Example:**

```sql
SELECT
    name,
    octet_length(name) AS bytes_used
FROM employees;
```

---

### **6.2 Other Related Functions**

|Function|Description|Example|
|---|---|---|
|`length(str)`|Number of characters (not bytes)|`length('É') → 1`|
|`octet_length(str)`|Number of bytes|`octet_length('É') → 2`|
|`bit_length(str)`|Number of bits|`bit_length('abc') → 24`|

---

## **7. Example Comparison**

|Input|`length()`|`octet_length()`|`bit_length()`|
|---|---|---|---|
|`'abc'`|3|3|24|
|`'é'`|1|2|16|

---

## **8. Advanced Example**

### **Detecting Large Text Columns**

```sql
SELECT 
    id, 
    octet_length(description) AS bytes
FROM products
WHERE octet_length(description) > 5000;
```

### **Handling Binary Data**

```sql
SELECT 
    filename,
    octet_length(file_data) AS size_in_bytes
FROM files
ORDER BY size_in_bytes DESC;
```

---

## ✅ **Goat Mode TL;DR 🐐**

- `DATALENGTH(expr)` → bytes in SQL Server
    
- `octet_length(expr)` → PostgreSQL equivalent
    
- Counts **bytes**, not characters
    
- Includes **trailing spaces**
    
- Returns **NULL for NULLs**
    
- Use for **data size validation**, **encoding checks**, and **storage debugging**
    


### Tags : [[1 - SQL 🦬]]