

---

# 🧩 **SQL / PostgreSQL: Mapping**

---

## **1. What is Mapping?**

**Mapping** is the process of **linking or transforming data from one form to another**. In SQL/PostgreSQL, this can mean:

1. **Column mapping** — mapping columns from one table to another.
    
2. **Value mapping** — translating codes or IDs into human-readable values.
    
3. **ETL mapping** — transforming data during extraction, transformation, and load.
    
4. **Table-to-object mapping** — in ORMs like Hibernate or JPA.
    

---

## **2. Column Mapping**

- When combining tables, you map columns to **align data correctly**.
    

**Example:**

```sql
SELECT
    e.id AS employee_id,
    e.name AS employee_name,
    d.dept_name AS department_name
FROM employees e
JOIN departments d ON e.department_id = d.id;
```

- `AS` keyword maps **column names** to friendly names.
    
- Essential for **reporting** and **views**.
    

---

## **3. Value Mapping (Using CASE or Lookup Tables)**

### **3.1 Using CASE**

```sql
SELECT
    name,
    department_id,
    CASE department_id
        WHEN 1 THEN 'HR'
        WHEN 2 THEN 'Finance'
        WHEN 3 THEN 'Engineering'
        ELSE 'Unknown'
    END AS department_name
FROM employees;
```

- Maps **numeric IDs** to **meaningful strings**.
    

### **3.2 Using Lookup Table**

```sql
CREATE TABLE department_codes (
    id INT PRIMARY KEY,
    name TEXT
);

INSERT INTO department_codes VALUES
(1, 'HR'), (2, 'Finance'), (3, 'Engineering');

SELECT e.name, d.name AS department_name
FROM employees e
LEFT JOIN department_codes d ON e.department_id = d.id;
```

- Cleaner and **dynamic** mapping — easy to maintain.
    

---

## **4. ETL Mapping / Transformation**

Mapping is heavily used in **data pipelines**:

```sql
-- Map raw sales data to standardized categories
SELECT
    sale_id,
    CASE
        WHEN raw_category = 'E' THEN 'Electronics'
        WHEN raw_category = 'F' THEN 'Fashion'
        ELSE 'Other'
    END AS category
FROM raw_sales;
```

- Mapping ensures data is **clean, standardized, and analyzable**.
    

---

## **5. Mapping in Joins and Views**

- Views are often **mappings** of multiple tables:
    

```sql
CREATE VIEW employee_info AS
SELECT
    e.id AS emp_id,
    e.name AS emp_name,
    d.name AS dept_name,
    COALESCE(m.name, 'No Manager') AS manager_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id
LEFT JOIN employees m ON e.manager_id = m.id;
```

- Maps multiple foreign keys into **readable output**.
    

---

## **6. Mapping in ORMs (Object-Relational Mapping)**

- In PostgreSQL, mapping is also used in **Java/Python apps**:
    
    - `employees` table → `Employee` class
        
    - `department_id` → `department` object reference
        

**Example (Java JPA)**

```java
@Entity
public class Employee {
    @Id
    private Long id;
    private String name;

    @ManyToOne
    @JoinColumn(name="department_id")
    private Department department;
}
```

- Database rows are **mapped to objects** for easier programming.
    

---

## **7. Advanced Mapping Techniques**

### **7.1 Mapping NULLs**

```sql
SELECT
    name,
    COALESCE(department_id, 0) AS dept_id
FROM employees;
```

- Maps NULLs to **default value**.
    

### **7.2 Mapping with Aggregates**

```sql
SELECT
    department_id,
    SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS female_count
FROM employees
GROUP BY department_id;
```

- Maps rows into **aggregated values**.
    

### **7.3 Mapping with Arrays / JSON**

```sql
-- Aggregate employee names per department into array
SELECT department_id, array_agg(name) AS employees
FROM employees
GROUP BY department_id;
```

- Maps multiple rows into **a single structured column**.
    

---

## **8. Key Principles of Mapping**

1. **Maintainability:** Prefer lookup tables over CASE for large sets.
    
2. **Consistency:** Map codes, IDs, and NULLs consistently.
    
3. **Performance:** Avoid very large CASE statements in queries; use joins when possible.
    
4. **Presentation vs Storage:** Keep mapping logic in **views or ETL**, not raw tables.
    
5. **ORM Mapping:** Use for seamless integration with applications.
    

---

## ✅ **Goat Mode TL;DR 🐐**

- **Mapping** = converting IDs, codes, or raw data into readable or structured forms
    
- **Column mapping** → friendly names via `AS`
    
- **Value mapping** → CASE, lookup tables, ETL transforms
    
- **NULL mapping** → `COALESCE` / default values
    
- **Aggregates mapping** → combine multiple rows into one
    
- **ORM mapping** → table rows → objects in app code
    
- Use **views, joins, and ETL** for maintainable mapping
    

---


### [[1 - SQL 🦬]]