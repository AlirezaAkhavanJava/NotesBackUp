
## **Clustered Index - Definition and Concepts**

A **clustered index** physically reorders the rows in a table to match the index order. This means the table data itself is stored in the leaf nodes of the index structure.

### **Key Characteristics:**

1. **Physical Reordering**: The table data is physically stored on disk in the same order as the index keys
2. **One Per Table**: You can only have one clustered index per table (since data can only be physically ordered one way)
3. **Data is the Index**: The index leaf nodes contain the actual row data, not just pointers

### **How It Works (Conceptual):**
```
Clustered Index on students(id):
- Row with id=1 is physically first on disk
- Row with id=2 is physically second
- Row with id=3 is physically third
- etc.
```

## **Database-Specific Implementations:**

### **1. SQL Server (Explicit Clustered Index)**
```sql
-- Primary key is clustered by default
CREATE TABLE students (
    id INT PRIMARY KEY CLUSTERED,  -- Explicit clustered
    name VARCHAR(100)
);

-- Or create clustered index separately
CREATE CLUSTERED INDEX idx_student_id 
ON students (id);
```

### **2. MySQL/InnoDB (Always Clustered)**
- Uses clustered index on PRIMARY KEY automatically
- If no PK, uses first UNIQUE NOT NULL index
- If neither, creates hidden clustered index

### **3. PostgreSQL (Different Approach)**
PostgreSQL doesn't have true clustered indexes like SQL Server. Instead:
- Uses `CLUSTER` command to physically reorder data
- This is a **one-time operation**, not maintained automatically
- New inserts don't maintain the order

```sql
-- In PostgreSQL, you "cluster" a table by an index
CREATE INDEX idx_student_id ON students (id);
CLUSTER students USING idx_student_id;  -- One-time physical reorder
```

### **4. Oracle (Index-Organized Tables)**
Oracle's equivalent is Index-Organized Tables (IOT):
```sql
CREATE TABLE students (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100)
) ORGANIZATION INDEX;  -- Similar to clustered index
```

## **Benefits of Clustered Indexes:**

1. **Faster Range Queries**:
```sql
-- Since data is physically ordered, these are very fast
SELECT * FROM students WHERE id BETWEEN 100 AND 200;
```

2. **Eliminates Extra Lookup**:
- Non-clustered index: Index → Pointer → Data Row
- Clustered index: Index → Data Row (directly)

3. **Better for Sequential Access**:
- Data is stored contiguously on disk
- Reduces disk I/O for ordered scans

## **Drawbacks:**

1. **Slow Inserts/Updates**:
- Inserting in the middle requires shifting data
- Can cause page splits

2. **One Per Table**:
- Must choose the most beneficial column carefully

3. **Fragmentation**:
- Over time, inserts/deletes can fragment the physical order

## **When to Use Clustered Index:**

✅ **Good candidates:**
- Primary keys (especially sequential IDs)
- Columns frequently used in range queries
- Columns often used in ORDER BY
- Columns with low update frequency

❌ **Poor candidates:**
- Frequently updated columns
- Wide keys (takes more space in non-leaf nodes)
- Columns with random values (GUIDs) - causes fragmentation

## **Example - SQL Server (True Clustered Index):**
```sql
-- Table with clustered primary key
CREATE TABLE students (
    student_id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    ssn CHAR(9) UNIQUE NONCLUSTERED,
    name VARCHAR(100),
    enrollment_date DATE
);

-- Non-clustered index on another column
CREATE NONCLUSTERED INDEX idx_enrollment_date 
ON students (enrollment_date);
```

## **Performance Impact:**
```
Query: SELECT * FROM students WHERE id = 500

With Clustered Index:
1. Navigate B-tree to find id=500
2. Return the row directly (data is there)

With Non-Clustered Index:
1. Navigate B-tree to find id=500
2. Get pointer to data location
3. Navigate to data location (extra I/O)
4. Return the row
```

## **Important Distinction:**

**Clustered Index** (SQL Server/MySQL):
- Data is always stored in index order
- Automatically maintained

**CLUSTER Command** (PostgreSQL):
- One-time physical reordering
- Not maintained after the operation
- Similar concept but different implementation

Choose clustered indexes carefully as they affect physical storage and have significant performance implications for both reads and writes.

###### Tags : [[1 - SQL 🥞]]