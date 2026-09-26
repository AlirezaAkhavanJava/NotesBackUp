

## **1 — What is an Anti Join?**

An **Anti Join** isn’t an official SQL keyword — it’s a **concept**.

🔹 It means: “Find all rows in one table that **do NOT have a match** in another table.”

Think of it as **the opposite of a normal join**.

---

### **Example in simple words**

Imagine:

- Table `students` (all students)
    
- Table `submitted_homework` (students who submitted homework)
    

We want **students who did NOT submit homework** → that’s an Anti Join.

---

### Tables:

**students**

|id|name|
|---|---|
|1|Alice|
|2|Bob|
|3|Charlie|

**submitted_homework**

|student_id|
|---|
|1|
|3|

We want → Bob (id=2) because he didn't submit homework.

---

## **2 — How to do Anti Join in SQL**

There are **three main ways** to do this in SQL/PostgreSQL.

---

### **2.1 — Using `NOT EXISTS` (Best choice)**

```sql
SELECT *
FROM students s
WHERE NOT EXISTS (
    SELECT 1
    FROM submitted_homework sh
    WHERE sh.student_id = s.id
);
```

**How it works**:

- For each student, check if there’s a matching row in `submitted_homework`.
    
- If there’s **no match**, keep it.
    

**Result**:

|id|name|
|---|---|
|2|Bob|

✅ `NOT EXISTS` is fast, especially for large datasets.

---

### **2.2 — Using `LEFT JOIN` + `IS NULL`**

```sql
SELECT s.*
FROM students s
LEFT JOIN submitted_homework sh
ON s.id = sh.student_id
WHERE sh.student_id IS NULL;
```

**How it works**:

- Do a `LEFT JOIN` → all students appear.
    
- If no match → joined columns from `submitted_homework` are NULL.
    
- Filter rows with NULL values.
    

**Result**:

|id|name|
|---|---|
|2|Bob|

---

### **2.3 — Using `NOT IN`**

```sql
SELECT *
FROM students
WHERE id NOT IN (
    SELECT student_id
    FROM submitted_homework
);
```

**Caution**:

- If `submitted_homework.student_id` contains **NULL**, this query may give wrong results.
    
- Safer: use `NOT EXISTS`.
    

---

---

## **3 — Anti Join in PostgreSQL — Advanced Concepts**

### **3.1 — Anti Join with Multiple Conditions**

You can check more than one condition:

```sql
SELECT *
FROM orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM returns r
    WHERE r.order_id = o.id
      AND r.returned_date > CURRENT_DATE - INTERVAL '30 days'
);
```

This returns orders that **haven’t been returned in the last 30 days**.

---

### **3.2 — Anti Join with Performance Tips**

- **NOT EXISTS** is usually faster than `LEFT JOIN` + `IS NULL` for large datasets.
    
- Use indexes on join columns to speed up queries.
    
- For complex Anti Joins, PostgreSQL query planner sometimes chooses the best method automatically — but you can hint with query rewriting.
    

---

### **3.3 — Anti Join with `EXCEPT`**

PostgreSQL has `EXCEPT`, which acts like an Anti Join:

```sql
SELECT id, name
FROM students
EXCEPT
SELECT s.id, s.name
FROM students s
JOIN submitted_homework sh
ON s.id = sh.student_id;
```

This returns students not in `submitted_homework`.

⚡ `EXCEPT` is readable but less flexible for big datasets compared to `NOT EXISTS`.

---

---

### **4 — Quick Summary Table**

|Method|Good for|Caveats|
|---|---|---|
|`NOT EXISTS`|Large datasets|Best practice|
|`LEFT JOIN` + `IS NULL`|Simpler queries|Can be slower for huge data|
|`NOT IN`|Simple cases|Issues if NULL exists|
|`EXCEPT`|Readability|Less flexible, performance varies|

---

---

### **5 — Super Simple Anti Join Example**

```sql
-- Students who did not submit homework
SELECT name
FROM students s
WHERE NOT EXISTS (
    SELECT 1
    FROM submitted_homework sh
    WHERE sh.student_id = s.id
);
```

**Result**:

```
Bob
```

---



### Tags : [[1 - SQL 🦬]]