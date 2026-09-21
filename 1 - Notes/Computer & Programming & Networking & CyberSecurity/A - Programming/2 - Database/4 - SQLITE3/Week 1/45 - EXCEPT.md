## EXCEPT in SQLite3

**EXCEPT** is a set operation that returns all rows from the first SELECT statement that are **not** present in the second SELECT statement. It essentially gives you the difference between two result sets.

---

### **Syntax**

```sql
SELECT column_list FROM table1
EXCEPT
SELECT column_list FROM table2;
```

**Key Points:**
- Both SELECT statements must return the same number of columns with compatible data types
- Duplicate rows are automatically removed (result is always distinct)
- SQLite does NOT support `EXCEPT ALL`

---

### **Practical Examples**

**Setup:**
```sql
CREATE TABLE students_a(id INTEGER, name TEXT);
CREATE TABLE students_b(id INTEGER, name TEXT);

INSERT INTO students_a VALUES (1, 'Alice'), (2, 'Bob'), (3, 'Carol');
INSERT INTO students_b VALUES (2, 'Bob'), (3, 'Carol'), (4, 'Dave');
```

---

### **Example 1: Students in A but NOT in B**

```sql
SELECT id, name FROM students_a
EXCEPT
SELECT id, name FROM students_b;
```

**Result:**
```
1 | Alice
```

*(Only Alice is in students_a but not in students_b)*

---

### **Example 2: Students in B but NOT in A**

```sql
SELECT id, name FROM students_b
EXCEPT
SELECT id, name FROM students_a;
```

**Result:**
```
4 | Dave
```

*(Only Dave is in students_b but not in students_a)*

---

### **Example 3: With WHERE Clause**

```sql
SELECT name FROM students_a WHERE id > 1
EXCEPT
SELECT name FROM students_b WHERE id > 2;
```

**Result:**
```
Bob
```

---

### **Comparison Table**

| Operator | Purpose | Result |
|----------|---------|--------|
| **UNION** | Combine all unique rows from both queries | Alice, Bob, Carol, Dave |
| **INTERSECT** | Only rows present in BOTH queries | Bob, Carol |
| **EXCEPT** | Rows in first query NOT in second | Alice |

**EXCEPT** is useful for finding differences between datasets, such as:
- Records deleted from one table
- Items in one list but not another
- Data discrepancies between two sources
[[1 - WHAT IS SQLITE3 🍕]]