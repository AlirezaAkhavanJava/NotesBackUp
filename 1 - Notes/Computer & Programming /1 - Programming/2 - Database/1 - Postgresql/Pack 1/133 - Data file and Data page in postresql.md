
# **Data File vs Data Page in PostgreSQL**

PostgreSQL stores data using a **two-level structure**:

- **Files** (on disk)
    
- **Pages / Blocks** (inside the files)
    

You _must_ understand pages first, because PostgreSQL reads/writes **pages**, not rows.

---

# **1. Data Page (a.k.a. Block)**

### **Definition**

A **data page** is the **fundamental I/O unit** in PostgreSQL.  
**Size**: always **8 KB** by default.

PostgreSQL _never reads or writes rows individually_ — it always reads/writes entire pages.

### **What is inside a page?**

Each 8 KB page contains:

1. **Page Header** (~24 bytes)
    
2. **Line Pointer Array**
    
    - One entry per row in the page
        
    - These pointers index _tuples_
        
3. **Tuples (rows)**
    
    - The actual row data
        
4. **Free Space**
    
5. **Special Space** (used by indexes, not tables)
    

### **Important behaviors**

- Rows never move between pages.
    
- Updates create a **new row version (MVCC tuple)**, often on the _same_ page.
    
- A page may contain **dead tuples** that VACUUM cleans.
    

### **Why pages matter**

- Index scans fetch pages, not rows
    
- Sequential scans read pages in order
    
- Performance depends heavily on page layout
    

---

# **2. Data File**

### **Definition**

A **data file** is a physical file stored under `base/` or `pg_tblspc/` that holds the pages of a table or index.

Every table’s main file is located at:

```
$PGDATA/base/<database_oid>/<relation_oid>
```

### **Properties of data files**

- A file is a sequence of **8 KB pages**.
    
- Files grow in 1 GB segments:
    
    - File
        
    - File.1
        
    - File.2
        
    - …
        

### **One table = multiple files**

A table consists of:

|File type|Purpose|
|---|---|
|main file|actual table data|
|toast file|stores large values > 2 KB|
|toast index|index for toast|
|FSM file|Free Space Map (locates free space inside pages)|
|VM file|Visibility Map (helps vacuum operations)|

Example for table with relfilenode `12345`:

```
12345        -- main data file
12345_fsm    -- free space map
12345_vm     -- visibility map
12345_init   -- template file (for unlogged tables)
```

---

# **How they relate**

### **Data file**

- Just a container for pages.
    
- Only meaningful as a sequence of bytes on disk.
    

### **Data page**

- Real logical storage unit.
    
- PostgreSQL uses pages for:
    
    - reads/writes
        
    - MVCC visibility
        
    - vacuuming
        
    - index lookups
        
    - WAL logging
        

---

# **3. Practical Workflow Example**

### Query:

```sql
SELECT * FROM users WHERE id = 10;
```

What happens inside PostgreSQL:

1. Index lookup → finds TID = `(page_number, offset)`
    
2. PostgreSQL reads **that page** (8 KB) from data file
    
3. PostgreSQL reads the tuple from inside the page
    
4. Checks MVCC snapshot
    
5. Returns the row
    

**Everything points to pages, never files directly.**

---

# **4. Quick Comparison**

|Feature|Data File|Data Page|
|---|---|---|
|Level|Physical|Logical|
|Size|0–∞ GB|8 KB fixed|
|Unit of I/O|❌ Not used|✔ Pages are the I/O unit|
|Contains rows?|Indirectly|Yes|
|Involves MVCC?|Indirectly|Yes|
|Can contain metadata?|No|Yes (header, free space)|

---

# **5. Why this matters to you**

If you're building high-performance systems:

- Page bloat kills performance → fix with VACUUM / autovacuum tuning
    
- Understanding pages helps index design
    
- Knowing file structure helps debugging corruption
    
- Analyzing pages explains dead tuple problems
    
- Page-level inspection is used by `pg_filedump`, `pageinspect`, etc.
    



###### Tags : [[1 - SQL 🦬]]