
## **Formula for joining multiple tables**

```sql
SELECT <columns>
FROM table1 [alias1]
<JOIN TYPE> table2 [alias2]
  ON <join_condition1>
<JOIN TYPE> table3 [alias3]
  ON <join_condition2>
...
WHERE <conditions>
ORDER BY <columns>;
```

---

### **Example: Joining three tables**

Let’s say we have:

- **students**: id, name
    
- **enrollments**: student_id, course_id
    
- **courses**: course_id, course_name
    

**Goal:** Get student names with course names.

```sql
SELECT s.name, c.course_name
FROM students s
INNER JOIN enrollments e
  ON s.id = e.student_id
INNER JOIN courses c
  ON e.course_id = c.course_id;
```

---

### **How this works**

1. First join → `students` + `enrollments`
    
2. Second join → result of first join + `courses`
    

It builds step-by-step:

```
students ⨝ enrollments ⨝ courses
```

---

### **Example: Joining more tables**

If we add a fourth table **teachers** with columns `(teacher_id, course_id, teacher_name)`:

```sql
SELECT s.name, c.course_name, t.teacher_name
FROM students s
INNER JOIN enrollments e
  ON s.id = e.student_id
INNER JOIN courses c
  ON e.course_id = c.course_id
INNER JOIN teachers t
  ON c.course_id = t.course_id;
```

---

### **Rules for joining multiple tables**

- **Always specify join conditions** (`ON` or `USING`) to avoid unwanted Cartesian products.
    
- **Join order matters** for readability, but modern databases optimize internally.
    
- Use **aliases** to avoid column name conflicts.
    
- You can mix join types (INNER + LEFT + RIGHT).
    
- Filters (`WHERE`) usually go last after all joins, unless the condition is part of the join (`ON`).
    

---

### **Tip for readability**

When joining many tables, break them into a neat vertical layout:

```sql
SELECT s.name, c.course_name, t.teacher_name
FROM students s
INNER JOIN enrollments e ON s.id = e.student_id
INNER JOIN courses c ON e.course_id = c.course_id
INNER JOIN teachers t ON c.course_id = t.course_id
WHERE c.course_name = 'Math'
ORDER BY s.name;
```

---
### **Definition**

A **multiple table join** in SQL is a query that **combines data from more than two tables** into a single result set by linking them through **join conditions**.  
Each join merges rows from two tables based on a specified relationship (usually via a key), and these joins can be chained together to combine as many tables as needed.

---

### **Key points**

- **Purpose:** To retrieve related data spread across several tables.
    
- **Mechanism:** Uses join operations (`INNER JOIN`, `LEFT JOIN`, etc.) to match rows between tables.
    
- **Conditions:** Each join must have a condition (`ON` or `USING`) that defines how the tables relate.
    
- **Result:** A single result set that contains columns from all joined tables.
    

---

### **Formula**

```sql
SELECT <columns>
FROM table1
<JOIN TYPE> table2 ON <condition>
<JOIN TYPE> table3 ON <condition>
...
WHERE <conditions>;
```

---

### **Example definition in words**

> “Joining multiple tables means linking two or more tables together in a query so that related data from different tables can be combined into one comprehensive result. This is done by using JOIN clauses with specific conditions that define how the tables relate to each other.”


#### Tags : [[1 - SQL 🦬]]