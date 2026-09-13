
The `WHERE` clause filters rows. Operators are used to build conditions.

### **Comparison operators**

```sql
=      -- equal
<> or !=  -- not equal
>      -- greater than
<      -- less than
>=     -- greater or equal
<=     -- less or equal
```

**Example:**

```sql
SELECT * FROM students
WHERE age >= 18;
```

---

### **Logical operators**

```sql
AND     -- both conditions must be true
OR      -- at least one condition must be true
NOT     -- negates condition
```

**Example:**

```sql
SELECT * FROM students
WHERE age > 18 AND country = 'USA';
```

---

### **Range check**

```sql
BETWEEN value1 AND value2
```

```sql
SELECT * FROM students
WHERE age BETWEEN 18 AND 25;
```

---

### **List check**

```sql
IN (value1, value2, ...)
```

```sql
SELECT * FROM students
WHERE country IN ('USA', 'UK', 'Canada');
```

---

### **Pattern matching**

```sql
LIKE 'pattern'
ILIKE 'pattern'   -- PostgreSQL only, case-insensitive
LIKE '%a%'  -- If contains a 
LIKE 'a%' -- start with a
LIKE '%a' -- ends with a 
LIKE '__a%' -- exact third character be a 
```

- `%` → any sequence of characters
    
- `_` → single character
    

```sql
SELECT * FROM students
WHERE name LIKE 'A%';   -- names starting with A
```

### **NULL check**

```sql
IS NULL
IS NOT NULL
```

```sql
SELECT * FROM students
WHERE email IS NULL;
```

### **Conditional expressions**

```sql
CASE WHEN ... THEN ... ELSE ...
```

Used with `WHERE` sometimes:

```sql
SELECT * FROM students
WHERE (CASE WHEN country = 'USA' THEN age END) > 18;
```


### **Subquery comparisons**

```sql
= ANY (subquery)
> ALL (subquery)
```

Example: students older than **all** students from Canada:

```sql
SELECT * FROM students
WHERE age > ALL (SELECT age FROM students WHERE country = 'Canada');
```


### **1. Regular expressions**

```sql
~     -- regex match
~*    -- regex match, case-insensitive
!~    -- does not match regex
!~*   -- does not match regex, case-insensitive
```

```sql
SELECT * FROM students
WHERE name ~ '^[A-Z]';   -- names starting with uppercase letter
```

### **2. Array operators**

```sql
= ANY(array)     -- element exists in array
= ALL(array)     -- all elements match
```

```sql
SELECT * FROM courses
WHERE 'math' = ANY(tags);
```

```sql
->   -- get JSON field
->>  -- get JSON field as text
```

```sql
SELECT * FROM users
WHERE data->>'role' = 'admin';
```


```sql
SELECT * FROM students
WHERE country IN (SELECT DISTINCT country FROM exchange_students);
```


## ✅ Quick Recap

- **Beginner**: `=, !=, >, <, >=, <=, AND, OR, NOT, BETWEEN, IN, LIKE`
    
- **Intermediate**: `IS NULL`, `CASE`, `ANY`, `ALL`, subqueries
    
- **Advanced (PostgreSQL)**: regex (`~`), array operators (`= ANY`), JSON operators (`->`, `->>`)
    

💡 **Memory tip**:  
Think of `WHERE` operators in **levels of filtering power**:

- Simple comparisons → Beginner
    
- Conditional & subqueries → Intermediate
    
- PostgreSQL extras (regex, arrays, JSON) → Advanced
#### Tags : [[1 - SQL 🥞]]