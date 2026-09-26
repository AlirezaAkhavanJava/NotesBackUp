



### **1. What is `WHERE`**

The `WHERE` clause filters rows in SQL queries so that only rows meeting a condition are returned.

**Syntax:**

```sql
SELECT column1, column2
FROM table_name
WHERE condition;
```

**Example:**

```sql
SELECT * FROM students
WHERE age > 18;
```

---

### **2. Comparison Operators**

|Operator|Meaning|
|---|---|
|`=`|Equal to|
|`<>`|Not equal to|
|`>`|Greater than|
|`<`|Less than|
|`>=`|Greater or equal|
|`<=`|Less or equal|

Example:

```sql
SELECT name, age FROM students
WHERE age >= 21;
```

---

### **3. Logical Operators**

Combine conditions:

- **`AND`** — both conditions must be true
    
- **`OR`** — at least one condition must be true
    
- **`NOT`** — negates condition
    

Example:

```sql
SELECT * FROM students
WHERE age > 18 AND country = 'USA';
```

---

### **4. NULL Values**

Check for missing values:

```sql
SELECT * FROM students
WHERE country IS NULL;
```

or

```sql
SELECT * FROM students
WHERE country IS NOT NULL;
```

---

### **5. Pattern Matching**

Use `LIKE` to search text:

```sql
SELECT * FROM students
WHERE name LIKE 'A%'; -- names starting with A
```

PostgreSQL extra: `ILIKE` (case-insensitive)

```sql
SELECT * FROM students
WHERE name ILIKE 'a%';
```

---

### **6. Range and Sets**

- **BETWEEN**:
    

```sql
SELECT * FROM students
WHERE age BETWEEN 18 AND 25;
```

- **IN**:
    

```sql
SELECT * FROM students
WHERE country IN ('USA', 'UK', 'Canada');
```

---



PostgreSQL supports advanced filtering inside `WHERE`.

### **1. Using functions**

```sql
SELECT * FROM students
WHERE LENGTH(name) > 5; -- names longer than 5 characters
```

### **2. Date filtering**

```sql
SELECT * FROM orders
WHERE order_date >= '2025-01-01';
```

### **3. Subqueries in WHERE**

```sql

--Get the the countries from the eroup

SELECT * FROM students
WHERE country IN (SELECT country FROM countries WHERE region = 'Europe');
```

---

### **4. Regular Expressions (PostgreSQL-specific)**

```sql
SELECT * FROM students
WHERE name ~ '^A'; -- names starting with A
```

- `~*` → case-insensitive regex match
    
- `!~` → regex NOT match
    

---

### **5. Type casting**

```sql
SELECT * FROM students
WHERE CAST(age AS TEXT) LIKE '2%';
```



---

## *📙 Advanced Level — Complex WHERE*

### *1. Complex logic*

```sql
SELECT * 
FROM students
WHERE (age > 18 AND country = 'USA') OR (age > 25 AND country = 'UK');
```

### *2. EXISTS*

```sql
SELECT * 
FROM students s
WHERE EXISTS (
    SELECT 1 FROM courses c WHERE c.student_id = s.id
);
```

### *3. JSON filtering (PostgreSQL)*

```sql
SELECT * FROM users
WHERE data->>'status' = 'active';
```

### *4. Full-text search*

```sql
SELECT * FROM articles
WHERE to_tsvector(title || ' ' || content) @@ to_tsquery('database & tutorial');
```

---

### **5. Window Functions + WHERE**

Filtering with `WHERE` happens **before** window functions.  
If you want to filter after a window function → use `HAVING` or subquery.

Example:

```sql
SELECT *
FROM (
    SELECT name, RANK() OVER (ORDER BY score DESC) as rank
    FROM students
) ranked_students
WHERE rank <= 10;
```

---

---

## **🚀 Tips & Tricks**

- `WHERE` runs **before** `GROUP BY` and `ORDER BY` in query execution order.
    
- Use parentheses `()` to make complex logic clear.
    
- In PostgreSQL, use `EXPLAIN` to see how `WHERE` filters affect query performance.
    
- Avoid filtering with functions on indexed columns unless necessary — it can prevent index usage.
    


#### Tags : [[1 - SQL 🦬]]