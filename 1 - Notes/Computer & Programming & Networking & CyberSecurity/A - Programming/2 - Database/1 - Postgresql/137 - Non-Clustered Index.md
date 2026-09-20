
## **Non-Clustered Index**

A **non-clustered index** is a separate data structure that stores a sorted copy of selected columns with pointers to the actual data rows. The table data remains in its original, unordered physical state.

### **Key Characteristics:**

1. **Separate Structure**: Creates a separate index structure from the table data
2. **Multiple Per Table**: You can create multiple non-clustered indexes on a table
3. **Pointers to Data**: Contains index keys + pointers (row locators) to actual data
4. **Logical Order Only**: Index entries are sorted, but table data is not

### **How It Works:**
```
Table (students) - Physical order:
| id | name     | age | (physical location)
|----|----------|-----|
| 3  | Charlie  | 22  | Page 3, Row 2
| 1  | Alice    | 20  | Page 1, Row 1  
| 4  | David    | 23  | Page 4, Row 1
| 2  | Bob      | 21  | Page 2, Row 1

Non-clustered index on id:
| id | pointer          |
|----|------------------|
| 1  | Page 1, Row 1    |
| 2  | Page 2, Row 1    |
| 3  | Page 3, Row 2    |
| 4  | Page 4, Row 1    |
```

## **Database Syntax:**

### **1. SQL Server (Explicit Non-Clustered)**
```sql
-- Default is non-clustered when not specified
CREATE INDEX idx_student_name 
ON students (name);

-- Explicit non-clustered
CREATE NONCLUSTERED INDEX idx_student_name_age
ON students (name, age);

-- On table with clustered index
CREATE TABLE students (
    id INT PRIMARY KEY CLUSTERED,      -- Clustered on id
    name VARCHAR(100),
    age INT
);

CREATE NONCLUSTERED INDEX idx_name 
ON students (name);                    -- Non-clustered on name
```

### **2. PostgreSQL (All indexes are "non-clustered" by default)**
```sql
-- All indexes in PostgreSQL are separate structures
CREATE INDEX idx_student_name ON students (name);

-- Unique non-clustered index
CREATE UNIQUE INDEX idx_student_email ON students (email);
```

### **3. MySQL/InnoDB**
```sql
-- Secondary indexes are non-clustered
CREATE INDEX idx_name ON students (name);

-- In InnoDB, non-clustered indexes store primary key values as pointers
CREATE INDEX idx_age ON students (age);
```

### **4. Oracle**
```sql
-- Default index type is non-clustered (B-tree)
CREATE INDEX idx_student_name ON students (name);
```

## **Internal Structure:**

### **In Tables with Clustered Index:**
```
Non-clustered index → Clustering Key (not physical address)
Example: Index on "name" contains:
- Sorted names: "Alice", "Bob", "Charlie"
- Pointers: Student_ID values (clustering key)
- Then uses clustered index to locate actual row
```

### **In Heap Tables (no clustered index):**
```
Non-clustered index → Physical Row Identifier (RID)
Example: Index on "name" contains:
- Sorted names: "Alice", "Bob", "Charlie"  
- Pointers: Page ID + Slot Number (physical location)
```

## **Two-Step Lookup Process:**
```sql
-- Query using non-clustered index:
SELECT * FROM students WHERE name = 'Alice';

-- 1. Search non-clustered index for 'Alice'
-- 2. Get pointer to data location
-- 3. Follow pointer to actual row (KEY LOOKUP/BOOKMARK LOOKUP)
-- 4. Return the complete row
```

## **Benefits of Non-Clustered Indexes:**

1. **Multiple Indexes**: Create many indexes for different query patterns
2. **Faster Lookups**: Quick access via indexed columns
3. **Covering Indexes**: Can include additional columns to avoid lookups
4. **Less Insert/Update Overhead**: No physical data reorganization

## **Drawbacks:**

1. **Extra Storage**: Each index consumes additional disk space
2. **Double Lookup Cost**: Need to access index THEN data
3. **Maintenance Overhead**: Updates to indexed columns require index updates
4. **Pointers Become Outdated**: In heap tables, data movement invalidates pointers

## **Advanced Non-Clustered Index Features:**

### **1. Covering/Included Index (SQL Server)**
```sql
-- Index covers the query - no need to access table
CREATE NONCLUSTERED INDEX idx_student_search
ON students (last_name, first_name)
INCLUDE (email, phone);  -- Additional columns stored in leaf

-- Query uses index only (covered):
SELECT email, phone FROM students 
WHERE last_name = 'Smith' AND first_name = 'John';
```

### **2. Filtered/Partial Index (PostgreSQL, SQL Server)**
```sql
-- Index only part of the data
CREATE INDEX idx_active_students ON students (department_id)
WHERE active = true;  -- Only index active students

-- PostgreSQL:
CREATE INDEX idx_recent_students ON students (enrollment_date)
WHERE enrollment_date > '2023-01-01';
```

### **3. Composite/Multi-column Index**
```sql
-- Index on multiple columns
CREATE INDEX idx_name_department ON students (last_name, first_name, department_id);

-- Useful for queries filtering/sorting on multiple columns
SELECT * FROM students 
WHERE last_name = 'Smith' 
  AND first_name = 'John'
  AND department_id = 5;
```

## **When to Use Non-Clustered Index:**

✅ **Good candidates:**
- Foreign key columns
- Columns in WHERE, JOIN, ORDER BY clauses
- Columns with high selectivity (many unique values)
- Columns used in search predicates but not ranges
- When you need multiple access paths

❌ **Poor candidates:**
- Columns with low selectivity (few unique values)
- Columns frequently updated
- Very wide columns (text, XML, JSON - unless using specialized indexes)
- On very small tables (scan might be faster)

## **Performance Example:**

```sql
-- Without index: Full table scan (reads all rows)
SELECT * FROM students WHERE email = 'john@example.com';

-- With non-clustered index: 
-- 1. Binary search in index (fast)
-- 2. Key lookup to get full row (additional I/O)

-- With covering index: Best performance
CREATE INDEX idx_email_covering ON students (email) 
INCLUDE (name, phone, enrollment_date);

SELECT name, phone FROM students 
WHERE email = 'john@example.com';  -- Index only scan!
```

## **Index Selection Guidelines:**

```sql
-- Priority for indexing:
1. WHERE clause columns
2. JOIN columns  
3. ORDER BY/GROUP BY columns
4. SELECT columns (for covering indexes)

-- Example:
SELECT s.name, s.email, g.grade
FROM students s
JOIN grades g ON s.id = g.student_id
WHERE s.department_id = 5
ORDER BY s.last_name, s.first_name;

-- Create indexes on:
-- students(department_id) -- WHERE clause
-- students(id) -- JOIN (likely already PK)
-- students(last_name, first_name) -- ORDER BY
-- grades(student_id) -- JOIN
```

## **Important Considerations:**

1. **Index Maintenance**: Each INSERT/UPDATE/DELETE must update all affected indexes
2. **Query Optimization**: The database decides which index to use (or none)
3. **Statistics**: Databases maintain statistics about index selectivity
4. **Fragmentation**: Indexes can become fragmented and need rebuilding

Non-clustered indexes are essential for optimizing read performance but should be created judiciously as they impact write performance and storage.

##### Tags : [[1 - SQL 🥞]]