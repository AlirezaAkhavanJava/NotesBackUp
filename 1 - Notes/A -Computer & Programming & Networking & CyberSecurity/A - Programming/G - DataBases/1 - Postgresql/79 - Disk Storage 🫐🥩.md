 **zero → clear** on how a **database stores data on disk** (using PostgreSQL as an example, since it’s a classic model).

---

## 💾 1️⃣ What “Disk Storage” Means

When you create a table and insert data:

```sql
CREATE TABLE users (id INT, name TEXT);
INSERT INTO users VALUES (1, 'Ethan');
```

That data doesn’t live in RAM permanently — it’s written to the **disk**, inside the **data directory** (for PostgreSQL, usually `/var/lib/postgresql/data/`).

So the disk holds _all real data_ — rows, indexes, and logs.

---

## 📁 2️⃣ The Disk Structure

On disk, PostgreSQL organizes data like this:

```
data/
 ├── base/
 │    ├── 16384/        ← database folder
 │    │     ├── 12500   ← table file (no extension)
 │    │     ├── 12500_fsm
 │    │     ├── 12500_vm
 │    │     └── 12501   ← index file
 │    ├── ...
 ├── global/            ← shared system tables
 ├── pg_wal/            ← Write-Ahead Log
 └── pg_tblspc/         ← tablespaces (custom storage locations)
```

Each **table and index** = one or more binary files.  
Names like `12500` are _internal object IDs_ — not readable directly.

---

## 📦 3️⃣ Table Files and Pages

Each table file is made of **8KB pages (blocks)**.

```
Table file (12500)
 ├── Page 1 (8KB)
 ├── Page 2 (8KB)
 ├── Page 3 (8KB)
 └── ...
```

Each page stores:

- A **page header** (metadata)
    
- Multiple **tuples** (rows)
    
- A **line pointer array** (to find each row in that page)
    

When a table grows large → PostgreSQL adds more 8KB pages to that file.

If the table exceeds ~1GB → it splits into `12500.1`, `12500.2`, etc.

---

## ✍️ 4️⃣ How Writing Happens

When you `INSERT` or `UPDATE`:

1. The new row goes into **shared buffers** (RAM).
    
2. The change is logged in the **WAL** (`pg_wal/`).
    
3. Later, background writers **flush pages to disk**.
    
4. This makes PostgreSQL **crash-safe** — WAL can replay missing changes if needed.
    

---

## 🔄 5️⃣ How Reading Happens

When you `SELECT` something:

1. The engine checks if the needed **page** is already in RAM (buffer cache).
    
2. If not, it **reads the 8KB page** from disk into memory.
    
3. Future reads of the same page are now faster (no disk access).
    

That’s why databases with lots of RAM are faster — fewer disk reads.

---

## 🧽 6️⃣ Free Space & Vacuum

When rows are deleted or updated:

- Old tuples remain marked as “dead” inside the page.
    
- PostgreSQL later runs **VACUUM** to reuse or clean those spaces.
    

This prevents disk bloat but keeps concurrency safe.

---

## ⚡ 7️⃣ Index Storage

Indexes are stored as **separate files** (usually B-trees).  
Each node of the B-tree is also stored as 8KB pages.

They point to specific tuples (by page + offset).

---

## 🧠 Summary

|Component|Stored Where|Description|
|---|---|---|
|**Tables**|`/base/<dbid>/`|Main data in 8KB pages|
|**Indexes**|same folder|Separate files (B-trees, etc.)|
|**WAL logs**|`/pg_wal/`|Transaction safety logs|
|**FSM/VM files**|same folder|Free space & visibility maps|
|**Buffers**|in RAM|Cache for active pages|

---

In short:

> The **disk** is where the database’s true, permanent data lives — organized into **pages, files, and logs**. The **RAM** is just a fast workspace.



##### Tags : [[1 - SQL 🥞]]