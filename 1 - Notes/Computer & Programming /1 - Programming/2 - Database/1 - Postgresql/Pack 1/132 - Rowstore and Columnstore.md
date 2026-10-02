
PostgreSQL **natively is a row-store database**, but it can also do columnar storage with extensions. Let’s break it down clearly.


![[Pasted image 20251206145205.png]]

---
## **1. Rowstore (Row-oriented) Indexes**

- **Definition:** Data is stored **row by row**. Each row contains all columns for that record together.
    
- **PostgreSQL default:** Every table is row-oriented unless you use an extension.
    
- **Indexes:** Standard PostgreSQL indexes (B-tree, GiST, GIN, BRIN) are designed for **row-oriented storage**.
    
- **Advantages:**
    
    - Fast **OLTP queries** (point queries, `INSERT`, `UPDATE`, `DELETE`).
        
    - Good for accessing **full rows**.
        
- **Disadvantages:**
    
    - Slow for **analytical queries** that scan few columns but millions of rows.
        

**Example:**

|id|name|age|country|
|---|---|---|---|
|1|Alice|25|UK|
|2|Bob|30|US|

- Each row is stored together; an index on `name` points to the row location.
    

---

## **2. Columnstore (Column-oriented) Indexes / Storage**

- **Definition:** Data is stored **column by column**. All values of one column are stored together.
    
- PostgreSQL **does NOT natively support columnstore**, but you can use **extensions** like:
    
    - **cstore_fdw** (Foreign Data Wrapper for columnar storage)
        
    - **TimescaleDB** or **ClickHouse** (on PostgreSQL forks)
        
- **Advantages:**
    
    - Excellent for **OLAP / analytical queries** (aggregations, scans over few columns).
        
    - Better **compression** because same-column data is stored together.
        
- **Disadvantages:**
    
    - Slower for **point updates** (`UPDATE`, `INSERT`, `DELETE`), because rows are split across columns.
        

**Example (column-oriented storage):**

| Column `id` | 1, 2, 3, … |  
| Column `name` | Alice, Bob, … |  
| Column `age` | 25, 30, … |

- Querying `SELECT age FROM table` → very fast, because only the `age` column is read.
    

---

## **3. Rowstore vs Columnstore Summary**

|Feature|Rowstore|Columnstore|
|---|---|---|
|Storage layout|Row by row|Column by column|
|Default in PostgreSQL|✅|❌ (needs extension)|
|Good for|OLTP, point queries|OLAP, analytics|
|Updates/Inserts|Fast|Slow|
|Aggregations|Slow for large tables|Fast|
|Compression|Moderate|High|

---

### **4. PostgreSQL options for Columnstore**

- **cstore_fdw**: Columnar foreign table, read-only, compresses columns.
    
- **TimescaleDB**: Time-series DB with columnar chunks.
    
- **PostgreSQL 16+**: Has some improvements for columnar-friendly scans via **BRIN** and **vectorized execution**, but still not fully columnstore.
    

---






###### Tags : [[1 - SQL 🦬]]