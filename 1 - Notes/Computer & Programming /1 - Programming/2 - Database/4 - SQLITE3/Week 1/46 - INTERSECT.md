

## INTERSECT in SQLite3

**INTERSECT** is a set operation that returns only the rows that appear in **both** SELECT statements. It gives you the common records between two result sets.

---

### **Syntax**

```sql
SELECT column_list FROM table1
INTERSECT
SELECT column_list FROM table2;
```

**Key Points:**
- Both SELECT statements must return the same number of columns with compatible data types
- Duplicate rows are automatically removed (result is always distinct)
- Only records present in **both** queries are returned
- SQLite does NOT support `INTERSECT ALL`

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

### **Example 1: Students in BOTH A and B**

```sql
SELECT id, name FROM students_a
INTERSECT
SELECT id, name FROM students_b;
```

**Result:**
```
2 | Bob
3 | Carol
```

*(Bob and Carol appear in both tables)*

---

### **Example 2: Find Common Employees by Department**

**Setup:**
```sql
CREATE TABLE dept_a_employees(emp_id INTEGER, name TEXT);
CREATE TABLE dept_b_employees(emp_id INTEGER, name TEXT);

INSERT INTO dept_a_employees VALUES (101, 'John'), (102, 'Sarah'), (103, 'Mike');
INSERT INTO dept_b_employees VALUES (102, 'Sarah'), (103, 'Mike'), (104, 'Lisa');
```

```sql
SELECT emp_id, name FROM dept_a_employees
INTERSECT
SELECT emp_id, name FROM dept_b_employees;
```

**Result:**
```
102 | Sarah
103 | Mike
```

---

### **Example 3: With WHERE Clause**

```sql
SELECT name FROM students_a WHERE id >= 2
INTERSECT
SELECT name FROM students_b WHERE id <= 3;
```

**Result:**
```
Bob
Carol
```

---

### **Example 4: Find Common Product IDs Across Orders**

```sql
SELECT product_id FROM orders_2024
INTERSECT
SELECT product_id FROM orders_2025;
```

*(Returns products ordered in both 2024 and 2025)*

---

### **Comparison Table**

| Operator | Purpose | Example Result |
|----------|---------|-----------------|
| **UNION** | All unique rows from both queries | Alice, Bob, Carol, Dave |
| **INTERSECT** | Only rows in BOTH queries | Bob, Carol |
| **EXCEPT** | Rows in first query NOT in second | Alice |

---

### **Common Use Cases**

- Find common customers between two sales periods
- Identify products available in multiple stores
- Find employees working in multiple departments
- Detect duplicate records across data sources
- Find shared interests or data overlaps


[[1 - WHAT IS SQLITE3 🍕]]