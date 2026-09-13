
## 🧠 1️⃣ What is Cache?

A **cache** is a small, fast storage area (usually in **RAM**) where the database keeps _recently used data_ — so it doesn’t have to read it again from the **slow disk**.

Think of it like your brain remembering something you just looked at — faster than going back to check again.

---

## 💾 2️⃣ Why Cache Exists

Disk = slow 🐢  
RAM = fast ⚡

So when you run:

```sql
SELECT * FROM users WHERE id = 1;
```

If the data is not in cache:

- The engine reads it from disk (slow).
    
- Then stores it in cache (memory).
    

Next time you run the same query:

- It’s fetched directly from cache (fast).
    

---

## ⚙️ 3️⃣ PostgreSQL Cache Layers

There are **two main layers** of caching:

|Layer|Type|Description|
|---|---|---|
|**Shared Buffers**|Database cache|Managed by PostgreSQL; stores recently used pages (8KB blocks).|
|**OS Cache (Page Cache)**|Kernel-level cache|The operating system also caches disk files in RAM.|

When you fetch a row:

1. PostgreSQL checks its **shared buffer cache**.
    
2. If not there, it asks the OS (which might already have it cached).
    
3. Only if both miss, it goes to disk.
    

---

## 🔄 4️⃣ Cache Workflow Example

Let’s trace what happens:

|Step|Action|Where data comes from|
|---|---|---|
|1|First query|Disk → Shared Buffer → Client|
|2|Second query|Shared Buffer (Cache hit)|
|3|Other queries|OS cache might help too|

That’s why repeated queries are much faster.

---

## 📊 5️⃣ Cache Settings in PostgreSQL

Important parameters in `postgresql.conf`:

|Parameter|Role|
|---|---|
|`shared_buffers`|How much RAM PostgreSQL can use for caching data pages (default ~25% of total memory).|
|`work_mem`|Used for sorting/join operations per query.|
|`effective_cache_size`|How much OS cache PostgreSQL _expects_ to have (used for query planning, not actual memory).|

---

## 📈 6️⃣ Checking Cache Performance

You can check cache hit rate:

```sql
SELECT blks_hit, blks_read,
       blks_hit * 100.0 / (blks_hit + blks_read) AS cache_hit_ratio
FROM pg_stat_database
WHERE datname = 'yourdbname';
```

If `cache_hit_ratio` > 95%, you’re good ✅  
If lower → increase `shared_buffers` or add more RAM.

---

## ⚡ 7️⃣ Summary

|Concept|Description|
|---|---|
|**Cache**|Temporary memory store for recent/frequent data|
|**Goal**|Avoid slow disk reads|
|**Shared Buffers**|PostgreSQL-managed cache|
|**OS Cache**|Kernel-level disk cache|
|**Good Cache Hit Ratio**|95%+ is ideal|

---

In short:

> The **cache** is the database’s short-term memory — it remembers recent pages to make queries much faster.

---

 how to **tune PostgreSQL’s cache for better performance** — practical and simple :



## ⚙️ 1️⃣ The 3 main memory areas to tune

|Setting|Purpose|
|---|---|
|**`shared_buffers`**|Main cache for table/index pages.|
|**`work_mem`**|Memory per query (for sorting, joins).|
|**`effective_cache_size`**|Hint for the optimizer about total OS cache.|

These live inside `postgresql.conf` (usually `/etc/postgresql/<version>/main/postgresql.conf`).

---

## 💾 2️⃣ `shared_buffers`

### 🔍 What it is

PostgreSQL’s own internal cache — keeps recently used 8KB pages from tables and indexes.

### 🧠 Rule of thumb

Set it to **25% of total system RAM** (sometimes up to 40% if PostgreSQL is the only big service).

Example for an 8 GB server:

```conf
shared_buffers = 2GB
```

Too small → more disk reads.  
Too big → OS cache becomes less effective.

---

## 🧮 3️⃣ `work_mem`

### 🔍 What it is

Memory per operation (sorts, joins, aggregations).  
Each _active query_ can use it, so be careful.

### 🧠 Rule of thumb

Start with:

```conf
work_mem = 64MB
```

Then monitor.

If you have 50 concurrent queries, total = `64MB × 50 = 3.2GB`.  
If that’s too much → reduce.

Use bigger values only for analytical or heavy queries.

---

## 🧩 4️⃣ `effective_cache_size`

### 🔍 What it is

A _planner hint_ — tells PostgreSQL how much OS-level cache is probably available.

It doesn’t allocate memory itself.

### 🧠 Rule of thumb

Set to about **75% of total RAM**.

Example:

```conf
effective_cache_size = 6GB
```

(for an 8 GB server)

---

## 📈 5️⃣ Check cache efficiency

Run:

```sql
SELECT blks_hit, blks_read,
       ROUND(blks_hit * 100.0 / (blks_hit + blks_read), 2) AS cache_hit_ratio
FROM pg_stat_database
WHERE datname = 'yourdbname';
```

Aim for **cache_hit_ratio ≥ 95%**.

If lower:

- Increase `shared_buffers`
    
- Add RAM
    
- Create proper indexes (to reduce full scans)
    

---

## 🔧 6️⃣ Apply and restart

After editing `postgresql.conf`, reload:

```bash
sudo systemctl restart postgresql
```

Or apply smaller changes live:

```sql
SELECT pg_reload_conf();
```

---

## ✅ 7️⃣ Summary

|Parameter|Typical Value|Purpose|
|---|---|---|
|`shared_buffers`|25% RAM|PostgreSQL cache|
|`work_mem`|16–64 MB|Query memory per operation|
|`effective_cache_size`|75% RAM|Planner hint for OS cache|
|Cache hit ratio|> 95%|Healthy performance|

---


##### Tags : [[1 - SQL 🥞]]