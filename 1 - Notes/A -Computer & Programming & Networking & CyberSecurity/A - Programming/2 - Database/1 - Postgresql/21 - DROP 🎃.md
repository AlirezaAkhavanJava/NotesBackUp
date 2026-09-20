

## **📘 What is DROP**

- `DROP` is a **Data Definition Language (DDL)** command.
    
- It removes database objects permanently (tables, databases, columns, constraints, indexes, views, etc.).
    

⚠️ **DROP deletes permanently — there’s no undo unless you have backups.**

---

### **1. Basic Syntax**

```sql
DROP object_type object_name;
```

---

### **2. Examples**

#### Drop a table:

```sql
DROP TABLE students;
```

#### Drop a database:

```sql
DROP DATABASE school;
```

#### Drop a view:

```sql
DROP VIEW student_summary;
```

---

### What is a view ? 


> In PostgreSQL, a **view** is basically a **virtual table** — it doesn’t store data itself, but **shows data from one or more tables** based on a query you define.



```sql
-- Base tables
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name TEXT,
    department TEXT,
    salary INT
);

-- View
CREATE VIEW it_employees AS
SELECT id, name, salary
FROM employees
WHERE department = 'IT';
--- NOW you can see 

SELECT * FROM it_employees;


```

### 🔹 Notes

- You **cannot insert/update/delete** directly in a view unless it’s **updatable**.
    
- Views are useful for **reporting, security, and simplifying queries**.

A **view in PostgreSQL is saved permanently in the database** once you create it with `CREATE VIEW`.

- It **does not disappear after fetching data**.
    
- Think of it as a **stored SELECT query**: you can query it anytime like a table.
    
- **Data itself is not stored** in the view; the view just **fetches fresh data from underlying tables** each time you query it.

it’s **not a part of the table**, but more like a **window into the table**.

- A **view** doesn’t store data itself.
    
- You **define it** by writing a query on one or more tables.
    
- When you query the view, PostgreSQL **runs the query behind the scenes** and shows the result.
    

> So a view is like a **custom lens** on your tables — it **looks at the data** in the way you define, without actually being part of the table.

Example analogy:

- **Table** → the full bookshelf with all books.
    
- **View** → a curated list of books on a specific topic from that shelf. The books are still on the shelf; the view just shows the subset.
---

## **📗 DROP with Options**

### **1. IF EXISTS**

Avoids errors if the object doesn’t exist:

```sql
DROP TABLE IF EXISTS students;
```

### **2. CASCADE**

Drops the object and all dependent objects:

```sql
DROP TABLE students CASCADE;
```

Example: Drops the table and dependent foreign keys, views, triggers, etc.

### **3. RESTRICT**

Default behavior: prevents drop if dependencies exist:

```sql
DROP TABLE students RESTRICT;
```

---

---

## **📙 DROP Tricks**

### **1. Drop multiple objects**

```sql
DROP TABLE students, courses;
```

### **2. Drop a column**

```sql
ALTER TABLE students DROP COLUMN email;
```

### **3. Drop a constraint**

```sql
ALTER TABLE students DROP CONSTRAINT chk_age;
```

### **4. Drop an index**

```sql
DROP INDEX idx_students_country;
```

### **5. Drop a schema**

```sql
DROP SCHEMA school_data CASCADE;
```

→ Removes schema and all objects inside.

---

### **6. Drop with Transaction Safety**

In PostgreSQL, you can use transactions to ensure safety:

```sql
BEGIN;
DROP TABLE students;
-- If something is wrong
ROLLBACK; -- Cancels drop
COMMIT; -- Confirms drop
```

---

---

## **🚀 Quick Recap**

- `DROP` permanently deletes database objects.
    
- Common uses: drop tables, databases, columns, constraints, indexes, views, schemas.
    
- Options:
    
    - **IF EXISTS** → avoid errors
        
    - **CASCADE** → drop dependencies
        
    - **RESTRICT** → stop if dependencies exist
        

---

💡 **Memory tip:**  
Think of `DROP` as **"destroy mode"** — use it carefully.



#### Tags : [[1 - SQL 🥞]]