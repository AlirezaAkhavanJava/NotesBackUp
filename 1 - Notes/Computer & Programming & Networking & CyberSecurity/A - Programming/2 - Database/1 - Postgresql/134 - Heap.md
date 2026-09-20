

# **What “Heap” Means in PostgreSQL**

### **Definition**

In PostgreSQL, a **heap** is the **on-disk storage format used for tables**.  
It’s simply the way PostgreSQL stores table rows **inside data pages**.

It has _nothing_ to do with runtime memory like Java’s heap.

### **Heap = unordered table storage**

PostgreSQL heap tables:

- Store rows in **8 KB pages**
    
- Do **NOT** guarantee any order
    
- Support **MVCC** by storing multiple row versions
    
- Are stored as files in the `base/` directory
    

**So “heap” = raw table storage format.**

---

# **What “Heap” Means in Java**

In Java:

- **Heap** = part of **RAM** where objects are allocated.
    
- Managed by the **JVM**
    
- Cleaned by **garbage collector**
    
- Has nothing to do with disk storage or files
    

So **Java heap = in-memory object storage**, while  
**PostgreSQL heap = on-disk page-based table storage**.

### **Totally different worlds.**

---

# **PostgreSQL Heap = Heap File, not Heap Memory**

PostgreSQL uses a **heap file organization**, similar to DB theory:

- Rows are stored wherever space is available
    
- No sorting by key
    
- Updates create new tuple versions (MVCC)
    
- Dead tuples accumulate → VACUUM cleans them
    

### Why is it called “heap”?

In classical DB design:

- “Heap file” = **unordered** file of records.
    
- Choosing “heap” means PostgreSQL does not maintain order in the table.
    

---

# **What actually lives inside the PostgreSQL heap?**

Inside heap pages you have:

- Page header
    
- Line pointers
    
- Row versions (tuples)
    
- Free space
    
- Dead tuples (until vacuum)
    
- HOT chain entries (update chains)
    

This is stored on disk, not in RAM.

---

# **Quick comparison**

|Feature|PostgreSQL Heap|Java Heap|
|---|---|---|
|What is it?|Table storage on disk|Memory for Java objects in RAM|
|Managed by|PostgreSQL storage engine|JVM + garbage collector|
|Size|Grows with table|Depends on JVM settings|
|Order|Unordered|Not applicable|
|MVCC|Yes (tuple versions)|No|
|Vacuum needed|Yes|No|

---

# **In human language**

- PostgreSQL heap = **where your table rows live on disk**
    
- Java heap = **where your objects live in memory**
    

They share only the name “heap”. Meaning completely different things.

---


###### Tags : [[1 - SQL 🥞]]