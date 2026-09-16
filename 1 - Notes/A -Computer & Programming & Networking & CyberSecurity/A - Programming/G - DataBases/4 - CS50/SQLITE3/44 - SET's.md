
### **Definition**

**UNION** is a set operation that combines the result sets of two or more SELECT statements into a single result set. It removes duplicate rows by default.

---

### **Types of Set Operations**

#### **1. UNION** (Removes Duplicates)
Combines results from multiple queries and eliminates duplicate rows.

```sql
SELECT value FROM table1
UNION
SELECT value FROM table2;
```

#### **2. UNION ALL** (Keeps Duplicates)
Combines results but retains all rows, including duplicates.

```sql
SELECT value FROM table1
UNION ALL
SELECT value FROM table2;
```

---

### **Practical Examples**

**Setup:**
```sql
CREATE TABLE employees_dept_a(id INTEGER, name TEXT, salary INTEGER);
CREATE TABLE employees_dept_b(id INTEGER, name TEXT, salary INTEGER);

INSERT INTO employees_dept_a VALUES (1, 'Alice', 50000), (2, 'Bob', 60000);
INSERT INTO employees_dept_b VALUES (3, 'Charlie', 55000), (2, 'Bob', 60000);
```

**UNION (removes duplicate Bob):**
```sql
SELECT name, salary FROM employees_dept_a
UNION
SELECT name, salary FROM employees_dept_b;
```

Result:
```
Alice | 50000
Bob | 60000
Charlie | 55000
```

**UNION ALL (keeps duplicate Bob):**
```sql
SELECT name, salary FROM employees_dept_a
UNION ALL
SELECT name, salary FROM employees_dept_b;
```

Result:
```
Alice | 50000
Bob | 60000
Charlie | 55000
Bob | 60000
```

---

### **Requirements for UNION**
- Same number of columns in both SELECT statements
- Columns must have compatible data types
- Column names from the first SELECT are used in the result set

---

### **Performance Note**
- **UNION** is slower (requires sorting to remove duplicates)
- **UNION ALL** is faster (no duplicate removal)

[[1 - WHAT IS SQLITE3]]]