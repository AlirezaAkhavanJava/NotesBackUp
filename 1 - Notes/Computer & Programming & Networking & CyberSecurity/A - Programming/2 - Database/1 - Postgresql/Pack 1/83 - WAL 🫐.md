

## 💾 1️⃣ What is WAL?

**WAL = Write-Ahead Log**  
It’s a special **log file** PostgreSQL uses to guarantee **data safety and recovery**.

Whenever data changes (INSERT, UPDATE, DELETE), PostgreSQL **writes the change to WAL first**, _before_ it touches the main data files.

So if your server crashes 💥 — WAL can replay all the logged changes and restore the database.

👉 It’s like a **black box flight recorder** for your database.

---

## 🧱 2️⃣ Why “Write-Ahead”?

Because you **write the log ahead** of the real data write.

That means:

1. Log change to WAL file.
    
2. Confirm the transaction (COMMIT).
    
3. Later, write the actual data to the table file.
    

If the system crashes between steps 2 and 3 — WAL ensures recovery.

---

## 📂 3️⃣ Where WAL Lives

Location (by default):

```
/var/lib/postgresql/data/pg_wal/
```

This folder contains many binary WAL segment files:

```
00000001000000000000000A
00000001000000000000000B
...
```

Each file stores a batch of recorded changes (usually 16MB each).

---

## ⚙️ 4️⃣ How WAL Works (Step-by-Step)

Let’s trace an example:

```sql
BEGIN;
UPDATE users SET name = 'Ethan' WHERE id = 1;
COMMIT;
```

PostgreSQL does:

1. **Change is generated** → stored in memory (buffer).
    
2. **WAL record created** → describes the change (which page, which tuple).
    
3. **WAL written to disk** (`pg_wal/`).
    
4. **Transaction commits** → success returned to client.
    
5. Later, the **background writer** flushes the actual data pages to disk.
    

So even if power goes off after COMMIT, WAL can replay the update.

---

## 🔁 5️⃣ WAL During Recovery

After crash/restart:

1. PostgreSQL checks last checkpoint (safe save point).
    
2. It replays WAL records created _after_ that checkpoint.
    
3. Database returns to exact state before the crash.
    

No corruption, no lost transactions ✅

---

## 🧮 6️⃣ WAL + Checkpoints

- A **checkpoint** = when PostgreSQL writes all dirty data pages from memory to disk.
    
- After that, WAL up to that point is no longer needed for crash recovery.
    

Example:

```
WAL files = 00000001 → 00000010
Checkpoint = after 00000009
→ WAL 00000001–09 can be recycled.
```

---

## ⚡ 7️⃣ WAL in Replication

WAL isn’t just for recovery — it’s also used for **replication**.

- **Primary server** writes WAL.
    
- **Replica server** reads WAL (via streaming) and replays it.
    

That keeps replicas in sync in real time.

---

## 🔧 8️⃣ WAL Configuration (in `postgresql.conf`)

|Setting|Purpose|
|---|---|
|`wal_level`|How detailed WAL is (default: `replica`, can be `minimal` or `logical`)|
|`archive_mode`|Enables WAL file archiving|
|`archive_command`|Command to copy/compress old WAL files|
|`max_wal_size`|How big the WAL area can grow|
|`checkpoint_timeout`|Time between checkpoints|

---

## 🧠 9️⃣ Summary

|Concept|Description|
|---|---|
|**WAL**|Log of every change before it’s applied|
|**Purpose**|Crash recovery & replication|
|**Location**|`pg_wal/` directory|
|**Unit**|16 MB segment files|
|**Key features**|Write-ahead safety, replay, durability|

---

In short:

> WAL is PostgreSQL’s **safety net** — it records every change first, so even if your database crashes or power goes out, nothing is lost.

##### Tags : [[1 - SQL 🦬]]