


# **B-Tree in PostgreSQL — Full Breakdown**

PostgreSQL uses **B-Tree** (not binary tree, not AVL) as its **default index type**.

B-Tree = **Balanced Tree**  
Goal = **fast lookup, fast range queries, predictable performance**


![[Pasted image 20251207132312.png]]


---

# **1. Definition**

A **B-Tree (Balanced Tree)** is a multi-level tree structure where **each node can contain many keys**, not just two.

It keeps keys **sorted**, and the tree always stays **balanced**, which guarantees:

- **O(log n)** search
    
- **O(log n)** insert
    
- **O(log n)** delete
    

PostgreSQL uses the **Lehman & Yao variant**, which supports concurrency and splitting without global locks.

---

# **2. Components (Nodes)**

A PostgreSQL B-Tree index is made of **pages (8 KB)** just like tables.

There are three node types:

1. **Root page**
    
2. **Internal pages**
    
3. **Leaf pages** (where actual index entries live)
    

Leaf pages contain:

- Key value
    
- TID (tuple ID) → points to the heap row `(blockNumber, offset)`
    

---

# **3. How a B-Tree Search Works**

Example query:

```sql
SELECT * FROM users WHERE age = 25;
```

Process:

1. Go to **root** → find right child
    
2. Traverse **internal nodes**
    
3. Reach **leaf node**
    
4. Read all entries matching the key
    
5. Use TIDs to fetch heap tuples
    

**Guaranteed O(log n)** because the tree height is very small (usually 2–4 levels even for huge tables).

---

# **4. Insert Workflow (Step-by-Step)**

When inserting a row:

1. Postgres finds the right leaf page
    
2. If leaf has space → insert key + TID
    
3. If leaf is full → **page split**
    
4. Internal nodes update to reflect the new page
    
5. Tree stays balanced
    

---

# **5. Why B-Tree is Useful**

### **✔ Fast equality lookups**

```sql
WHERE id = 10
```

### **✔ Fast range queries**

```sql
WHERE age BETWEEN 20 AND 30
WHERE created_at > now() - interval '1 day'
```

### **✔ Ordered results without sorting**

```sql
ORDER BY created_at LIMIT 100
```

### **✔ Unique constraints**

Primary keys use B-Tree.

---

# **6. PostgreSQL B-Tree vs Binary Tree**

|Feature|Binary Tree|PostgreSQL B-Tree|
|---|---|---|
|Children per node|2|Many|
|Height|Can grow tall|Always balanced|
|Disk friendly|❌ terrible|✔ optimized|
|I/O operations|Many|Few|
|Complex concurrency|Hard|Easy via Lehman-Yao|

B-Tree is built for disk pages, not RAM.

---

# **7. How B-Tree Handles MVCC**

PostgreSQL does **NOT** store versions in the index.

Index entry points to **heap tuple versions**.  
If a new version is created (UPDATE):

- Index entry still points to the _old_ version
    
- If indexed column changes → new index entry added
    

This is why index scans must check MVCC visibility.

---

# **8. Downsides of B-Tree**

- Index bloat (dead entries accumulate)
    
- Large indexes slow down writes
    
- Cannot speed up `LIKE '%abc'`
    
- Cannot index large unbounded text efficiently
    

---

# **9. B-Tree Page Layout**

Each index page contains:

- Page header
    
- Line pointers
    
- Index tuples (key + TID)
    
- Special space (left/right siblings)
    

---

# **10. Practical Example (Postgres Internals)**

Index page tuple looks like:

```
(key, TID)
```

TID = `(blockNumber, offset)` in the heap.

---

# **11. When You Should Choose B-Tree**

Use B-Tree if:

|Query Type|B-Tree Good?|
|---|---|
|Equality|✔|
|Range|✔|
|Ordering|✔|
|Prefix text searches (`LIKE 'abc%'`)|✔|
|Full text search|❌|
|Contains array element|❌|
|Distance/geo search|❌|
|JSON key lookup|❌ needs GIN|

---

# **12. Real PostgreSQL Commands**

Create standard B-Tree:

```sql
CREATE INDEX idx_users_age ON users(age);
```

Unique B-Tree:

```sql
CREATE UNIQUE INDEX idx_users_email ON users(email);
```

See index structure:

```sql
SELECT * FROM pg_indexes WHERE tablename = 'users';
```




###### Tags : [[1 - SQL 🦬]]