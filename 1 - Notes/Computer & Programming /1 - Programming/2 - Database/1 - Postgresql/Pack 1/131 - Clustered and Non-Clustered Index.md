
## **1. Clustered Index**

- A **clustered index** determines the **physical order of rows in the table**.
    
- In PostgreSQL, a table can **only have one clustered index** because the table can be physically sorted in only one way.
    
- PostgreSQL **doesn’t automatically keep the table clustered**; you use the `CLUSTER` command to reorder the table:
    

```sql
-- Create an index
CREATE INDEX idx_students_id ON students(id);

-- Cluster the table by that index
CLUSTER students USING idx_students_id;
```

**Notes:**

- After clustering, the table rows are physically sorted by the index.
    
- Future inserts **won’t automatically maintain clustering**; you need to `CLUSTER` again if desired.
    
- Improves performance for **range queries** on the clustered column.
    

---

## **2. Non-Clustered Index**

- A **non-clustered index** is **separate from the table**. It stores pointers (TIDs) to the actual rows.
    
- You can have **many non-clustered indexes** on a table.
    
- PostgreSQL’s default indexes (B-tree, GIN, GiST, etc.) are **non-clustered** unless you explicitly cluster the table.
    

```sql
CREATE INDEX idx_students_name ON students(name);
```

- The table rows themselves are **not reordered**.
    
- Efficient for selective lookups and joins, but may require an extra step to fetch the actual row.
    

---

### **Summary Table**

|Feature|Clustered|Non-Clustered|
|---|---|---|
|Physical row order|Yes|No|
|Number per table|1|Many|
|Storage|Table rows are sorted|Index is separate|
|Example|`CLUSTER` on primary key|Regular B-tree, GIN, GiST|
|Use case|Range queries on large tables|Lookup by various columns|

---

💡 **Important PostgreSQL note:**  
PostgreSQL **does not automatically maintain clustering** like SQL Server. `CLUSTER` is a one-time operation; for ongoing clustering, you’d need periodic re-clustering.

---

> PostgreSQL **doesn’t have “clustered indexes” the way SQL Server or MySQL do**, but it has similar functionality. Here’s how it works:



## **1. Non-Clustered Indexes**

- **All PostgreSQL indexes are technically non-clustered by default.**
    
- Examples: B-tree, GIN, GiST, SP-GiST, BRIN.
    
- These indexes **store pointers to table rows** rather than physically sorting the table.
    

```sql
CREATE INDEX idx_students_name ON students(name);
```

✅ This is a non-clustered index. You can have many of these per table.


![[Pasted image 20251207133333.png]]

---

## **2. “Clustered” behavior in PostgreSQL**

- PostgreSQL has a `CLUSTER` command that **reorders the table physically based on an index**.
    
- Example:
    

```sql
CREATE INDEX idx_students_id ON students(id);
CLUSTER students USING idx_students_id;
```

- Now the **table rows are physically sorted** by `id`.
    
- **Important:** This is **one-time**. PostgreSQL **does not maintain clustering automatically**. New inserts can disrupt the order. You’d need to run `CLUSTER` again to restore it.
    
- A table can be clustered on **only one index** at a time.
    

---

### **TL;DR**

|Feature|PostgreSQL|
|---|---|
|Non-clustered indexes|✅ Default for all indexes|
|Clustered index|⚠️ Only via `CLUSTER` command; not automatic, only one per table|

---

Resource : https://www.postgresql.fastware.com/pzone/2025-01-understanding-the-mechanics-of-postgresql-b-tree-indexes

###### Tags : [[1 - SQL 🦬]]