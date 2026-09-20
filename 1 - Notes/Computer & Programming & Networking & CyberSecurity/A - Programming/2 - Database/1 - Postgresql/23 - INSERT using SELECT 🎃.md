

This copies data from one table into another.

**Syntax:**

```sql
INSERT INTO target_table (column1, column2, ...)
SELECT column1, column2, ...
FROM source_table
WHERE condition;
```

---

### **Example**

We have:

- `students` table: `id, name, age, country`
    
- `alumni` table: `id, name, age, country`
    

Copy students older than 25 into alumni:

```sql
INSERT INTO alumni (name, age, country)
SELECT name, age, country
FROM students
WHERE age > 25;
```

---

### **1. Insert all columns**

If both tables have exactly the same structure:

```sql
INSERT INTO alumni
SELECT *
FROM students
WHERE age > 25;
```

⚠️ Column order must match exactly unless you explicitly list them.

---

### **2. Insert with transformations**

You can modify values while inserting:

```sql
INSERT INTO alumni (name, age, country)
SELECT name, age + 1, 'Graduated'
FROM students
WHERE age > 25;
```

---

### **3. Insert distinct values**

Avoid duplicates when inserting:

```sql
INSERT INTO alumni (name, age, country)
SELECT DISTINCT name, age, country
FROM students;
```

---
### **1. Insert with JOIN**

Insert data from one table while joining another:

```sql
INSERT INTO alumni (name, age, country)
SELECT s.name, s.age, c.name
FROM students s
JOIN countries c ON s.country_id = c.id
WHERE s.age > 25;
```

---

### **2. Insert with RETURNING**

Get IDs of inserted rows:

```sql
INSERT INTO alumni (name, age, country)
SELECT name, age, country
FROM students
WHERE age > 25
RETURNING id, name;
```


>  `RETURNING` is a PostgreSQL clause that lets you **get back the data of the row(s) you just inserted, updated, or deleted** — without running another query.

---

### **3. Insert with CTE**

Use a Common Table Expression (CTE) for clarity:

```sql
WITH eligible_students AS (
    SELECT name, age, country
    FROM students
    WHERE age > 25
)
INSERT INTO alumni (name, age, country)
SELECT name, age, country
FROM eligible_students;
```

---

### **4. Insert into table with generated columns**

If the target table has generated columns:

```sql
CREATE TABLE alumni (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    age INT,
    country VARCHAR(50),
    graduation_date DATE DEFAULT CURRENT_DATE
);

INSERT INTO alumni (name, age, country)
SELECT name, age, country
FROM students
WHERE age > 25;
```

→ `graduation_date` uses the default value.

---

---

✅ **Quick Recap**

- **INSERT INTO target_table SELECT ... FROM source_table** is the standard form.
    
- You can transform data, filter with `WHERE`, join with other tables, use `DISTINCT`, or even use CTEs.
    
- Always match column count and types unless using explicit column names.
    

---

💡 Memory trick:  
Think of `INSERT FROM SELECT` as **copy-paste with filtering and transformation**.


#### Tags : [[1 - SQL 🥞]]