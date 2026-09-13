

## 💾 1️⃣ The Big Idea

A **database** stores everything permanently on **disk** — but not all files are the same.  
Different parts of the database engine use **different storage areas** for:

- user data
    
- indexes
    
- logs
    
- temporary work files
    
- system metadata
    

---

## 🧩 2️⃣ Main Disk Storage Areas

|Storage Area|Purpose|
|---|---|
|**Data Files (Base Directory)**|Store tables, indexes, schemas — the actual user data|
|**WAL (Write-Ahead Log)**|Keeps a log of every change for crash recovery|
|**Temporary Files**|Used for big sorts, joins, and temp tables|
|**Configuration Files**|Settings like `postgresql.conf`, `pg_hba.conf`|
|**Global Catalog**|System-wide tables (user accounts, cluster info)|
|**Tablespaces**|Custom directories you can assign to different drives|

---

## 📂 3️⃣ PostgreSQL Directory Layout (Typical)

```
/var/lib/postgresql/data/
 ├── base/              ← main data (tables, indexes)
 │    ├── 16384/        ← one folder per database
 │    │     ├── 12500   ← one table file
 │    │     ├── 12501   ← one index file
 │    │     ├── 12500_fsm  ← free space map
 │    │     ├── 12500_vm   ← visibility map
 │    │     └── ...
 │
 ├── global/            ← global system catalogs
 ├── pg_wal/            ← WAL logs for recovery
 ├── pg_tblspc/         ← user-defined tablespaces
 ├── pg_stat/           ← runtime statistics
 ├── pg_temp/           ← temporary work files
 └── postgresql.conf    ← main configuration file
```

---

## 📦 4️⃣ Explanation of Key Storage Areas

### 🧱 **1. Base (Data Directory)**

- Contains one folder per **database**.
    
- Inside, each **table** and **index** is stored as a binary file.
    
- Each file = 8KB **pages (blocks)**.
    

👉 Example:  
`12500` = your table  
`12501` = its index

---

### 🔁 **2. pg_wal (Write-Ahead Log)**

- Every INSERT, UPDATE, DELETE first goes here before being written to the data file.
    
- Ensures **durability** — even if power fails, PostgreSQL can replay logs and restore consistency.
    

---

### 🧹 **3. Temporary Files**

- Used when queries need more RAM than allowed (`work_mem` limit).
    
- Stored in `/tmp/` or inside `pg_temp/`.
    
- Auto-deleted after the query ends.
    

---

### 🌍 **4. Global**

- Stores cluster-level system tables — users, roles, and global settings shared by all databases in the cluster.
    

---

### 🧭 **5. Tablespaces**

- Let you store data on different disks/partitions.
    

Example:

```sql
CREATE TABLESPACE fastspace LOCATION '/mnt/ssd/';
CREATE TABLE mytable (...) TABLESPACE fastspace;
```

Useful when:

- Some tables need faster disks (SSD)
    
- Some can live on slower HDDs
    

---

## ⚡ 5️⃣ Internal Mini-Areas Inside Data Files

Each table file contains:

|Area|Description|
|---|---|
|**Page Header**|Metadata about that page|
|**Tuple Data**|Actual rows|
|**Line Pointers**|Offsets to tuples|
|**Free Space**|Unused room for new rows|

PostgreSQL’s **VACUUM** reclaims space from deleted rows.

---

## 📊 6️⃣ Summary

|Storage Area|Function|
|---|---|
|**base/**|Real user data (tables, indexes)|
|**pg_wal/**|Write-Ahead Log for recovery|
|**pg_temp/**|Temporary query files|
|**global/**|Cluster-level metadata|
|**pg_tblspc/**|Custom data locations|
|**postgresql.conf**|Engine configuration|

---

In short:

> The **disk** is divided into specialized storage areas — each responsible for different aspects of the database: user data, system data, logs, or temporary work.



##### Tags : [[1 - SQL 🥞]]