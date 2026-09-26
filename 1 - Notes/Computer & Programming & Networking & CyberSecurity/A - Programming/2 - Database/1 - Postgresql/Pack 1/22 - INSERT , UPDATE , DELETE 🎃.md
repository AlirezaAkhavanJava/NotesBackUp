
### **1. INSERT — Adding Data**

Adds new rows to a table.

**Basic syntax:**

```sql
INSERT INTO table_name (column1, column2, ...)
VALUES (value1, value2, ...);
```

**Example:**

```sql
INSERT INTO students (name, age, country)
VALUES ('Ethan', 25, 'USA');
```

- **Insert multiple rows:**
    
```sql
INSERT INTO students (name, age, country)
VALUES 
  ('Alice', 20, 'UK'),
  ('Bob', 22, 'Canada');
```

- **Insert from SELECT:**
    
```sql
INSERT INTO alumni (name, age, country)
SELECT name, age, country FROM students WHERE age > 25;
```

- **Insert with DEFAULT values:**
    

```sql
INSERT INTO students DEFAULT VALUES;
```

→ Uses default values for all columns.

- **Insert with RETURNING (PostgreSQL):**
    

```sql
INSERT INTO students (name, age, country)
VALUES ('John', 30, 'USA')
RETURNING id;
```

→ Returns the inserted row’s id.

---

### **2. UPDATE — Modifying Data**

Changes existing rows in a table.

**Basic syntax:**

```sql
UPDATE table_name
SET column1 = value1, column2 = value2
WHERE condition;
```

**Example:**

```sql
UPDATE students
SET age = 26
WHERE name = 'Ethan';
```

⚠️ Without `WHERE`, all rows are updated.

> in PostgreSQL you don’t write `UPDATE TABLE`, just `UPDATE`

- **Update multiple columns:**
    

```sql
UPDATE students
SET age = age + 1, country = 'USA'
WHERE country = 'Canada';
```

- **Update using subquery:**
    

```sql
UPDATE students
SET country = (
    SELECT country FROM countries WHERE countries.id = students.country_id
)
WHERE students.age > 20;
```


- **Update with RETURNING:**
    

```sql
UPDATE students
SET age = age + 1
WHERE country = 'USA'
RETURNING id, name, age;
```

→ Returns updated rows.

- **Update using JOIN (PostgreSQL):**
    

```sql
UPDATE students s
SET country = c.name
FROM countries c
WHERE s.country_id = c.id;
```


---

### **3. DELETE — Removing Data**

Removes rows from a table.

**Basic syntax:**

```sql
DELETE FROM table_name
WHERE condition;
```

**Example:**

```sql
DELETE FROM students
WHERE name = 'Ethan';
```

⚠️ Without `WHERE`, all rows are deleted.

- **Delete with subquery:**
    

```sql
DELETE FROM students
WHERE country IN (
    SELECT country FROM countries WHERE region = 'Europe'
);

--OR

DELETE FROM student
WHERE country IN ('LBN', 'PSE');


```

- **Delete with LIMIT (PostgreSQL):**
    

```sql
DELETE FROM students
WHERE country = 'USA'
LIMIT 5;
```


- **Delete with USING (PostgreSQL):**
    

```sql
DELETE FROM students s
USING enrollments e
WHERE s.id = e.student_id AND e.course_id = 5;
```

- **Truncate table (fast delete all):**
    

```sql
TRUNCATE TABLE students;
```

→ Deletes all rows quickly, resets sequences.

---

✅ **Quick Recap Table**

|Command|Purpose|Key Tip|
|---|---|---|
|INSERT|Add rows|Can insert single/multiple rows or from SELECT|
|UPDATE|Modify rows|Always use WHERE unless you want all rows changed|
|DELETE|Remove rows|Use WHERE to avoid deleting all rows|

---

💡 **Memory trick:**  
Think of them as **CRUD basics**:

- `INSERT` → Create
    
- `UPDATE` → Update
    
- `DELETE` → Delete
    

#### Tags : [[1 - SQL 🦬]]