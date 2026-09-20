
# 📗 Types of Subqueries

## 1. **Scalar Subquery** (returns 1 value)

Used where a single value is expected.

```sql
SELECT name, age
FROM students
WHERE age > (SELECT AVG(age) FROM students);
```

👉 The inner query returns one number (average age).

---

## 2. **Row Subquery** (returns one row)

```sql
SELECT name, age
FROM students
WHERE (age, grade) = (
  SELECT age, grade FROM students WHERE id = 10
);
```

👉 Outer query compares multiple columns to one row.

---

## 3. **Table Subquery** (returns many rows/columns)

```sql
SELECT * 
FROM (SELECT id, name FROM students WHERE age > 18) AS adult_students;
```

👉 Subquery acts like a temporary table (must give it an alias).

---

## 4. **Correlated Subquery**

Uses a column from the **outer query** inside the **inner query**.  
It’s executed once per row of the outer query.

```sql
SELECT name
FROM students s
WHERE age > (
  SELECT AVG(age) 
  FROM students 
  WHERE country = s.country
);
```

👉 For each student, it checks the avg age of _their country_.

---

## 5. **EXISTS / NOT EXISTS**

Tests whether a subquery returns **any rows**.

```sql
SELECT name
FROM students s
WHERE EXISTS (
  SELECT 1 FROM enrollments e WHERE e.student_id = s.id
);
```

👉 Only students who are enrolled in something.

---

## 6. **IN / NOT IN**

Checks membership in a subquery result.

```sql
SELECT name
FROM students
WHERE id IN (SELECT student_id FROM enrollments);
```

---

## 7. **ANY / ALL**

Compare against **all** or **any** results of a subquery.

```sql
-- Students older than ANY teacher
SELECT name
FROM students
WHERE age > ANY (SELECT age FROM teachers);

-- Students older than ALL teachers
SELECT name
FROM students
WHERE age > ALL (SELECT age FROM teachers);
```

---

# 📙 PostgreSQL-Only Subquery Power

✅ You can use **`WITH` (Common Table Expressions, CTEs)** instead of subqueries for readability:

```sql
WITH adult_students AS (
  SELECT id, name FROM students WHERE age > 18
)
SELECT * FROM adult_students WHERE name LIKE 'A%';
```

✅ You can even use subqueries in the `SELECT` list:

```sql
SELECT name,
       (SELECT COUNT(*) FROM enrollments e WHERE e.student_id = s.id) AS course_count
FROM students s;
```

---

# ✅ Quick Recap

- **Scalar** → returns one value (`=`, `<`, `>`)
    
- **Row** → returns one row for comparison
    
- **Table** → acts like a derived table
    
- **Correlated** → references outer query (runs per row)
    
- **EXISTS / NOT EXISTS** → checks presence of rows
    
- **IN / ANY / ALL** → compare values against subquery results
    
- **CTE (`WITH`)** → modern replacement for complex subqueries
    

#### [[1 - SQL 🥞]]