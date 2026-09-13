

## **📘 Beginner Level — What is ALTER**

- `ALTER` is a **Data Definition Language (DDL)** command.
    
- It modifies the structure of an existing database object (table, column, index, etc.) without deleting it.
    

---

### **1. Basic Syntax**

```sql
ALTER TABLE table_name action;
```

---

### **2. Examples**

#### Add a column:

```sql
ALTER TABLE students
ADD COLUMN email VARCHAR(100);
```

#### Drop a column:

```sql
ALTER TABLE students
DROP COLUMN email;
```

#### Rename a column:

```sql
ALTER TABLE students
RENAME COLUMN name TO full_name;
```

#### Rename a table:

```sql
ALTER TABLE students
RENAME TO student_info;
```

---

---

## **📗 Intermediate Level — ALTER with Constraints & Types**

### **1. Add constraints**

```sql
ALTER TABLE students
ADD CONSTRAINT chk_age CHECK (age > 0);
```

### **2. Drop constraints**

```sql
ALTER TABLE students
DROP CONSTRAINT chk_age;
```

### **3. Change column type**

```sql
ALTER TABLE students
ALTER COLUMN age TYPE BIGINT;
```

### **4. Set default value**

```sql
ALTER TABLE students
ALTER COLUMN country SET DEFAULT 'USA';
```

### **5. Drop default value**

```sql
ALTER TABLE students
ALTER COLUMN country DROP DEFAULT;
```

---

---

## **📙 Advanced Level — PostgreSQL ALTER Tricks**

### **1. Alter column to NOT NULL**

```sql
ALTER TABLE students
ALTER COLUMN age SET NOT NULL;
```

### **2. Alter column to allow NULL**

```sql
ALTER TABLE students
ALTER COLUMN age DROP NOT NULL;
```

### **3. Add multiple columns**

```sql
ALTER TABLE students
ADD COLUMN phone VARCHAR(20),
ADD COLUMN enrollment_date DATE;
```

### **4. Rename constraint**

```sql
ALTER TABLE students
RENAME CONSTRAINT chk_age TO chk_student_age;
```

### **5. Alter column type with USING**

When converting data type that isn’t automatically compatible:

```sql
ALTER TABLE students
ALTER COLUMN age TYPE VARCHAR(10) USING age::VARCHAR;
```

### **6. Alter table owner**

```sql
ALTER TABLE students OWNER TO ethan;
```

---

---

## **🚀 Quick Recap**

- **ALTER TABLE** is for modifying existing tables without losing data.
    
- Common actions:
    
    - Add/drop/rename columns
        
    - Change column type
        
    - Add/drop constraints
        
    - Set/drop defaults
        
    - Rename table/constraints
        
    - Change table owner
        
- In PostgreSQL, **ALTER** supports advanced features like `USING`, multiple actions, and altering ownership.
    

---

💡 **Memory tip:**  
Think of `ALTER` as “**edit mode**” for your database structure without rebuilding it.


#### Tags : [[1 - SQL 🥞]]