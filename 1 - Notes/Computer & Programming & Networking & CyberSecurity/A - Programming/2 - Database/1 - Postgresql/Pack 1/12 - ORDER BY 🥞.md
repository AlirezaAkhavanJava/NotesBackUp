

## **📘 Beginner Level — Basic ORDER BY**

### **1. What is `ORDER BY`**

The `ORDER BY` clause sorts the rows returned by a query.

**Syntax:**

```sql
SELECT column1, column2
FROM table_name
ORDER BY column1 [ASC|DESC], column2 [ASC|DESC];
```

- **ASC** → ascending (default)
    
- **DESC** → descending
    

---

### **2. Basic Example**

```sql
SELECT name, age
FROM students
ORDER BY age ASC;
```

→ Students sorted by age, youngest first.

```sql
SELECT name, age
FROM students
ORDER BY age DESC;
```

→ Students sorted by age, oldest first.

---

### **3. Multiple Columns Sorting**

```sql
SELECT name, age, country
FROM students
ORDER BY country ASC, age DESC;
```

→ Sorts by country first, then by age within each country.

---
## **📗 Intermediate Level **

### **1. Sorting with expressions**

```sql
SELECT name, age
FROM students
ORDER BY age + 5 DESC;
```

→ Sorts based on `age + 5`.

---

### **2. Sorting with functions**

```sql
SELECT name, age
FROM students
ORDER BY LOWER(name) ASC;
```

→ Sorts names case-insensitively.

---

### **3. ORDER BY column position**

Instead of column name, you can use position:

```sql
SELECT name, age
FROM students
ORDER BY 2 DESC;
```

→ Sorts by the second selected column (`age`).

⚠️ This is allowed but not recommended for maintainability.

---

### **4. ORDER BY with NULLS**

By default, PostgreSQL puts NULLs last in ascending order and first in descending order.  
You can control it with `NULLS FIRST` or `NULLS LAST`:

```sql
SELECT name, age
FROM students
ORDER BY age ASC NULLS FIRST;
```

---

## **📙 Advanced Level — ORDER BY Tricks**

### **1. Ordering by CASE**

```sql
SELECT name, age, country
FROM students
ORDER BY CASE country
           WHEN 'USA' THEN 1
           WHEN 'UK' THEN 2
           ELSE 3
         END ASC, age DESC;
```

→ Custom ordering.

---

### **2. Ordering with RANDOM()**

```sql
SELECT name
FROM students
ORDER BY RANDOM()
LIMIT 5;
```

→ Random sample of rows (PostgreSQL-specific).

---

### **3. ORDER BY with Subquery**

```sql
SELECT *
FROM (
    SELECT name, age, ROW_NUMBER() OVER (PARTITION BY country ORDER BY age DESC) as rank
    FROM students
) ranked_students
WHERE rank <= 3
ORDER BY country, age DESC;
```

→ Combines ORDER BY with window functions.

---

### **4. COLLATION (PostgreSQL)**

Collations define language-specific sort rules.

```sql
SELECT name
FROM students
ORDER BY name COLLATE "de_DE" ASC;
```

→ Sorts names according to German language rules.

---

### **5. ORDER BY in UPDATE/DELETE**

You can use ORDER BY in UPDATE/DELETE queries in PostgreSQL for more control (especially with `LIMIT`):

```sql
DELETE FROM logs
WHERE created_at < '2025-01-01'
ORDER BY created_at ASC
LIMIT 1000;
```

→ Deletes oldest logs first.

---

## **🚀 Tips & Tricks**

- `ORDER BY` is **always last** in query execution order (after WHERE, GROUP BY, HAVING).
    
- Ordering large datasets can be slow → use indexes if sorting a lot.
    
- PostgreSQL allows advanced sorting with collations, NULLS FIRST/LAST, expressions, and functions.
    
- Use `EXPLAIN` to check sorting performance.
    


#### Tags : [[1 - SQL 🦬]]