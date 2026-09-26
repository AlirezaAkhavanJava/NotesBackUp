
## **📘 Beginner Level — Basic DISTINCT**

### **1. What is `DISTINCT`**

- `DISTINCT` removes duplicate rows from the query result.
    
- Works with `SELECT`.
    

**Syntax:**

```sql
SELECT DISTINCT column1
FROM table_name;
```

---

### **2. Basic Example**

```sql
SELECT DISTINCT country
FROM students;
```

→ Returns a list of unique countries without repeats.

---

### **3. DISTINCT on multiple columns**

```sql
SELECT DISTINCT country, gender
FROM students;
```

→ Returns unique combinations of country and gender.

---

---

## **📗 Intermediate Level — DISTINCT in Complex Queries**

### **1. DISTINCT with ORDER BY**

```sql
SELECT DISTINCT country
FROM students
ORDER BY country ASC;
```

→ Returns unique countries sorted alphabetically.

---

### **2. DISTINCT with Expressions**

```sql
SELECT DISTINCT UPPER(country)
FROM students;
```

→ Returns unique uppercase country names.

---

### **3. DISTINCT with COUNT**

Counting distinct values:

```sql
SELECT COUNT(DISTINCT country)
FROM students;
```

→ Returns the number of unique countries.

---

### **4. DISTINCT in Joins**

```sql
SELECT DISTINCT s.country
FROM students s
JOIN courses c ON s.id = c.student_id;
```

→ Returns unique countries of students enrolled in courses.

---

## **📙 Advanced Level — DISTINCT Tricks**

### **1. DISTINCT ON (PostgreSQL-specific)**

PostgreSQL has `DISTINCT ON`, which lets you pick one row per group with control over which row to pick.

```sql
SELECT DISTINCT ON (country) country, name, age
FROM students
ORDER BY country, age DESC;
```

→ Picks the oldest student for each country.

---

### **2. DISTINCT in Window Functions**

```sql
SELECT DISTINCT name, FIRST_VALUE(age) OVER (PARTITION BY country ORDER BY age DESC) AS oldest_age
FROM students;
```

→ Uses DISTINCT with window functions for advanced grouping.

---

### **3. DISTINCT with Subqueries**

```sql
SELECT name
FROM students
WHERE country IN (
    SELECT DISTINCT country
    FROM students
    WHERE age > 18
);
```

→ Filters students in countries with adult students only.

---

### **4. DISTINCT with UNION**

- `UNION` already removes duplicates automatically.
    

```sql
SELECT country FROM students
UNION
SELECT country FROM teachers;
```

Equivalent to:

```sql
SELECT DISTINCT country FROM (
    SELECT country FROM students
    UNION ALL
    SELECT country FROM teachers
) sub;
```

---

### **5. Performance Notes**

- `DISTINCT` can be expensive for large datasets.
    
- Use indexes where possible.
    
- In PostgreSQL, `DISTINCT ON` is often faster for certain grouping needs.
    

---

---

✅ **Quick Recap:**

- `DISTINCT` → remove duplicates
    
- `DISTINCT ON` (PostgreSQL) → control which row to keep per group
    
- Works with expressions, joins, subqueries, and aggregates.


---

|Clause|Purpose|Works On|When Applied|Example|
|---|---|---|---|---|
|**WHERE**|Filters rows before grouping or aggregation.|Individual rows before aggregation.|Before `GROUP BY`.|`sql SELECT * FROM students WHERE age > 18;` Filters rows where `age > 18`.|
|**HAVING**|Filters groups after aggregation.|Aggregated results (groups).|After `GROUP BY`.|`sql SELECT country, COUNT(*) FROM students GROUP BY country HAVING COUNT(*) > 10;` Keeps only countries with more than 10 students.|
|**DISTINCT**|Removes duplicate rows from query result.|Whole result set (columns specified).|After `WHERE` and before ORDER BY.|`sql SELECT DISTINCT country FROM students;` Returns unique countries.|

---

### **Key Differences**

#### 1. **WHEN they run**

- **WHERE** → Before grouping (filters raw rows).
    
- **HAVING** → After grouping (filters aggregated results).
    
- **DISTINCT** → After filtering and grouping (removes duplicate rows in final result).
    

---

#### 2. **WHAT they filter**

- **WHERE** → individual row data.
    
- **HAVING** → group-level aggregated data.
    
- **DISTINCT** → unique row combinations.
    

---

#### 3. **Usage**

- **WHERE** → Filtering raw data.
    
- **HAVING** → Filtering grouped/aggregated data.
    
- **DISTINCT** → Removing duplicate results.
    

---

### **Example Combining All Three**

```sql
SELECT DISTINCT country, COUNT(*) AS student_count
FROM students
WHERE age > 18                -- Filters rows before grouping
GROUP BY country
HAVING COUNT(*) > 10          -- Filters grouped results
ORDER BY student_count DESC;
```

**Flow:**

1. WHERE → remove rows where age ≤ 18
    
2. GROUP BY → group by country
    
3. HAVING → keep groups with more than 10 students
    
4. DISTINCT → remove duplicate country rows (if any)
    
5. ORDER BY → sort results
    

---

💡 **Memory trick:**  
Think of it as a **pipeline**:  
`WHERE → GROUP BY → HAVING → DISTINCT → ORDER BY`

#### Tags : [[1 - SQL 🦬]]