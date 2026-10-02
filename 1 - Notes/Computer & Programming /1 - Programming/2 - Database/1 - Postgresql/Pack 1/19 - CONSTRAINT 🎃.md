
## **📘 Beginner Level — What is CONSTRAINT**

- A **constraint** is a rule enforced on a table to ensure the integrity of the data. صحت داده
     
- Constraints can prevent invalid data, maintain relationships, and enforce uniqueness.
    

**Syntax when creating a table:**

```sql
CREATE TABLE table_name (
    column_name data_type CONSTRAINT constraint_name constraint_type
);
```

---

### **1. Common Constraint Types**

|Constraint|Purpose|
|---|---|
|`PRIMARY KEY`|Unique identifier for a row; cannot be NULL.|
|`FOREIGN KEY`|Ensures a column matches a value in another table.|
|`UNIQUE`|Ensures all values in a column (or group of columns) are unique.|
|`NOT NULL`|Ensures a column cannot have NULL values.|
|`CHECK`|Ensures a condition is true for all values in the column.|
|`DEFAULT`|Provides a default value if none is supplied.|

---

### **2. Example — Table with Constraints**

```sql
CREATE TABLE students (
    id SERIAL CONSTRAINT pk_students PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    age INT CHECK (age > 0),
    country VARCHAR(50) DEFAULT 'USA'
);
```



---

## **📗 Intermediate Level — Using Constraints**

### **1. UNIQUE Constraint**

```sql
CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE
);
```

→ No two courses can have the same name.

---

### **2. FOREIGN KEY Constraint**

```sql
CREATE TABLE enrollments (
    id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(id),
    course_id INT REFERENCES courses(id)
);
```

→ Ensures enrolled students and courses exist.

---

### **3. Composite Primary Key**

```sql
CREATE TABLE attendance (
    student_id INT,
    course_id INT,
    date DATE,
    PRIMARY KEY (student_id, course_id, date)
);
```

→ Uses multiple columns to identify a row uniquely.

---

### **4. Named Constraints**

```sql
CREATE TABLE products (
    id SERIAL,
    name VARCHAR(100),
    price DECIMAL CHECK (price > 0),
    CONSTRAINT pk_products PRIMARY KEY (id),
    CONSTRAINT chk_price CHECK (price > 0)
);
```

→ Named constraints help with error identification and easier modification.

---

---

## **📙 Advanced Level — PostgreSQL Constraints**

### **1. Exclusion Constraints (PostgreSQL-specific)**

```sql
CREATE TABLE bookings (
    room INT,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    EXCLUDE USING gist (
        room WITH =,
        tstzrange(start_time, end_time) WITH &&
    )
);
```

→ Prevents overlapping bookings.

---

### **2. CHECK with Functions**

```sql
CREATE FUNCTION valid_age(age INT) RETURNS BOOLEAN AS $$
BEGIN
    RETURN age BETWEEN 0 AND 150;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE people (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    age INT,
    CONSTRAINT chk_age CHECK (valid_age(age))
);
```

→ Uses a function for validation.

---

### **3. Deferrable Constraints**

```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(id) DEFERRABLE INITIALLY DEFERRED
);
```

→ Allows postponing constraint checks until commit time.

---

### **4. Dropping Constraints**

```sql
ALTER TABLE students DROP CONSTRAINT pk_students;
```

---

---

✅ **Quick Recap:**  
Constraints ensure data quality and enforce rules:

- **Row-level constraints**: `NOT NULL`, `CHECK`
    
- **Table-level constraints**: `PRIMARY KEY`, `UNIQUE`, `FOREIGN KEY`
    
- PostgreSQL adds **Exclusion Constraints**, **Deferrable Constraints**, **Function-based CHECKs**.
    

---
#### Tags : [[1 - SQL 🦬]]