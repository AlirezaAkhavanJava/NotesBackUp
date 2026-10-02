# 📘 1. **Row-based Combination (Set Operations)**

👉 Works on **whole result sets** stacked **vertically (rows)**.  
👉 Tables must have the **same number of columns** and compatible data types.

- **UNION** → merges results, removes duplicates.
    
- **UNION ALL** → merges results, keeps duplicates.
    
- **INTERSECT** → only common rows between results.
    
- **EXCEPT / MINUS** → rows in the first set but not in the second.
    

```sql
SELECT id, name FROM students
UNION
SELECT id, name FROM teachers;
```

---
# 📗 2. **Column-based Combination (Joins)**

👉 Works by **matching rows** across tables and placing their **columns side by side (horizontally)**.  
👉 Tables don’t need same structure — they’re linked by keys.

- **INNER JOIN** → only matching rows.
    
- **LEFT JOIN** → all rows from left + matches from right.
    
- **RIGHT JOIN** → all rows from right + matches from left.
    
- **FULL JOIN** → everything, fill with NULL if no match.
    
- **CROSS JOIN** → every row with every row.
    
- **SELF JOIN** → table joined with itself.
    

```sql
SELECT s.name, e.course_id
FROM students s
JOIN enrollments e ON s.id = e.student_id;
```

---
# ✅ Simple Analogy

- **Set operations (rows)** → like stacking **pages of a notebook** one after another.
    
- **Joins (columns)** → like combining **two spreadsheets side by side**, matching rows by some rule.
    
---
##### Tags : [[1 - SQL 🦬]]