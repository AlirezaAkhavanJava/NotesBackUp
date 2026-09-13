
### 🔐 **What Are Advisory Locks in PostgreSQL?**

Advisory locks are **user-defined locks** — they let your **application code control concurrency**, not PostgreSQL itself.

They don’t lock tables or rows automatically — **you decide** what they represent.

Think of them as **named mutexes inside the database**.

---

### 🧩 **1. Simple Example**

```sql
-- Acquire a lock (session-level)
SELECT pg_advisory_lock(12345);

-- Do something critical here...

-- Release it
SELECT pg_advisory_unlock(12345);
```

✅ Key idea:  
Only **one session** can hold the same lock ID at a time.  
Others trying to get it will **wait**.

---

### ⚙️ **2. Non-blocking version**

```sql
SELECT pg_try_advisory_lock(12345);
```

- Returns `true` if the lock was acquired.
    
- Returns `false` if someone else already has it.  
    👉 Useful if you don’t want your app to hang.
    

---

### 🔢 **3. Lock IDs**

You can use:

- One `BIGINT` value
    
- Or a pair of `INT`s (two numbers)
    

Examples:

```sql
SELECT pg_advisory_lock(42);           -- single key
SELECT pg_advisory_lock(7, 9);         -- composite key
```

---

### 🧠 **4. Types of Advisory Locks**

|Type|Duration|Description|
|---|---|---|
|**Session-level**|Until connection ends|`pg_advisory_lock()` / `pg_advisory_unlock()`|
|**Transaction-level**|Until commit/rollback|`pg_advisory_xact_lock()`|

---

### 💻 **5. Example Use Case**

Let’s say multiple workers process the same table of tasks:

```sql
BEGIN;
SELECT pg_try_advisory_xact_lock(task_id)
FROM tasks
WHERE processed = false
LIMIT 1;
-- if true → mark as processed
UPDATE tasks SET processed = true WHERE id = task_id;
COMMIT;
```

➡️ Guarantees that **only one worker** picks each task.

---

### ⚡ **6. Summary**

|Feature|Advisory Locks|
|---|---|
|Type|Application-controlled lock|
|Scope|Session or transaction|
|Locks what|Arbitrary key, not specific rows|
|Use Case|Prevent concurrent job execution, custom synchronization|
|Automatic release|Yes (when session/transaction ends)|

---
## 🧱 **1. Why use them**

In a distributed or multi-threaded system, you sometimes want to make sure **only one instance of code runs at a time** — e.g.:

- Background jobs
    
- Batch data loaders
    
- Report generators
    

Advisory locks are perfect for that — lightweight, fast, and safe.

---

## 💻 **2. Simple JDBC Example**

```java
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TaskProcessorService {

    private final JdbcTemplate jdbc;

    public TaskProcessorService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional
    public void processCriticalTask() {
        // Try to acquire lock (ID = 42)
        Boolean locked = jdbc.queryForObject(
                "SELECT pg_try_advisory_lock(42)", Boolean.class
        );

        if (Boolean.TRUE.equals(locked)) {
            try {
                System.out.println("Lock acquired ✅ — running task...");
                // Do your critical operation here
                Thread.sleep(5000); // simulate work
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } finally {
                // Release lock
                jdbc.execute("SELECT pg_advisory_unlock(42)");
                System.out.println("Lock released 🔓");
            }
        } else {
            System.out.println("Another process is already running — skipping 🚫");
        }
    }
}
```

✅ **What happens:**

- Only one service instance can hold lock ID `42`.
    
- Others immediately get `false` from `pg_try_advisory_lock(42)` and skip.
    
- Lock is auto-released when session or transaction ends (safely).
    

---

## ⚙️ **3. Transactional Variant**

If you use a transactional lock tied to the current transaction:

```java
jdbc.execute("SELECT pg_advisory_xact_lock(42)");
```

It’s automatically released on commit/rollback — no need to unlock manually.

---

## 🧠 **4. Typical Use Case**

You’d often call this from a **scheduled job**:

```java
@Scheduled(fixedDelay = 60000)
public void scheduledJob() {
    taskProcessorService.processCriticalTask();
}
```

So even if multiple app instances run, only **one** will do the job at a time.

---

## ⚡ Summary

|Function|Behavior|
|---|---|
|`pg_advisory_lock(id)`|Blocks until lock acquired|
|`pg_try_advisory_lock(id)`|Returns immediately (true/false)|
|`pg_advisory_unlock(id)`|Manually releases lock|
|`pg_advisory_xact_lock(id)`|Auto-released at transaction end|


##### Tags : [[1 - SQL 🥞]]