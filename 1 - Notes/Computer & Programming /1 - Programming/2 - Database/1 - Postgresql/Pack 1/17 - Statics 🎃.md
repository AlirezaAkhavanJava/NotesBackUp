

## **📘 Beginner Level — What Are Static Fixed Values**

**Static fixed values** are literal values you hardcode in a SQL query instead of fetching them from a table or calculation.  
These values never change unless you edit the query.

They are useful for:

- Creating constant columns
    
- Filtering
    
- Comparison
    
- Testing queries
    

---

### **1. Static values in SELECT**

```sql
SELECT 'Hello World' AS greeting;
```

→ Returns:

|greeting|
|---|
|Hello World|

```sql
SELECT 100 AS fixed_number;
```

→ Returns:

|fixed_number|
|---|
|100|

---

### **2. Static values in WHERE**

```sql
SELECT *
FROM students
WHERE country = 'USA';
```

→ `'USA'` is a static fixed value.

---

### **3. Static values in INSERT**

```sql
INSERT INTO students (name, age, country)
VALUES ('Ethan', 25, 'USA');
```

→ `'Ethan'`, `25`, `'USA'` are static fixed values.



---

## **📗 Intermediate Level — Advanced Uses of Static Values**

### **1. Static expressions**

```sql
SELECT name, age, age + 5 AS age_in_5_years
FROM students;
```

→ `5` is a fixed value added to age.



### **2. Static filtering**

```sql
SELECT name, age
FROM students
WHERE age = 21;
```

→ Only students aged exactly 21 are selected.



### **3. Static in CASE**

```sql
SELECT name,
       CASE WHEN age > 18 THEN 'Adult'
            ELSE 'Minor'
       END AS status
FROM students;
```

→ `'Adult'` and `'Minor'` are static fixed values.



### **4. Static date values**

```sql
SELECT *
FROM orders
WHERE order_date = '2025-09-01';
```

→ `'2025-09-01'` is a fixed date value.



---

## **📙 Advanced Level — Tricks with Static Fixed Values**

### **1. Static values in UNION**

```sql
SELECT name FROM students
UNION
SELECT 'No Name';
```

→ Adds a fixed value row.

---

### **2. Static values with functions**

```sql
SELECT name, COALESCE(NULL, 'No Name') AS display_name
FROM students;
```

→ `'No Name'` is a static fallback value.

---

### **3. Static values in CTEs**

```sql
WITH fixed_values AS (
    SELECT 'Fixed1' AS value
    UNION ALL
    SELECT 'Fixed2'
)
SELECT * FROM fixed_values;
```

→ Creates a table of static values.

---

### **4. Static values in PostgreSQL arrays**

```sql
SELECT unnest(ARRAY['A', 'B', 'C']) AS letters;
```

→ `'A'`, `'B'`, `'C'` are static fixed values.

---

---

✅ **Quick recap:**  
Static fixed values are hardcoded values in SQL that don’t change unless you edit the query. They can be:

- Strings (`'Hello'`)
    
- Numbers (`100`)
    
- Dates (`'2025-09-01'`)
    
- Expressions  
    They are used for filtering, constants, testing, and creating fixed columns.
    



#### Tags : [[1 - SQL 🦬]]

---

