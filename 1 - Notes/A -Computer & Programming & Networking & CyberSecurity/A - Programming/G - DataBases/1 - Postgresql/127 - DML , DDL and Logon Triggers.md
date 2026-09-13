
# ✅ 1. **DML Triggers** (PostgreSQL supports these)

DML = Data Manipulation Language

- `INSERT`
    
- `UPDATE`
    
- `DELETE`
    
- `TRUNCATE`
    

These are the **normal triggers** you already know.

### Example (DML Trigger)

```sql
CREATE TRIGGER audit_student
AFTER INSERT OR UPDATE OR DELETE
ON students
FOR EACH ROW
EXECUTE FUNCTION audit_fn();
```

These can be:

- BEFORE
    
- AFTER
    
- FOR EACH ROW
    
- FOR EACH STATEMENT
    

So yes — PostgreSQL fully supports DML triggers.

---

# ❗ 2. **DDL Triggers** (PostgreSQL _does NOT_ have true DDL triggers)

DDL = Data Definition Language

- `CREATE TABLE`
    
- `ALTER TABLE`
    
- `DROP TABLE`
    
- `CREATE INDEX`
    
- etc.
    

PostgreSQL **does not** support DDL triggers like Oracle or SQL Server.

BUT…

### PostgreSQL has **Event Triggers**, which are close.

Event triggers can fire on:

- `CREATE`
    
- `ALTER`
    
- `DROP`
    
- `DDL_COMMAND_START`
    
- `DDL_COMMAND_END`
    
- `SQL_DROP`
    

So if you need to catch schema changes, you use **Event Triggers**.

### Example (event trigger)

```sql
CREATE OR REPLACE FUNCTION log_ddl()
RETURNS event_trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'DDL command: %', TG_TAG;
END;
$$;

CREATE EVENT TRIGGER ddl_logger
ON ddl_command_end
EXECUTE FUNCTION log_ddl();
```

This runs every time any DDL finishes.

---

# ❗ 3. **Logon / Logoff Triggers**

### PostgreSQL does _NOT support_ logon or logoff triggers.

This is a feature seen in Oracle or SQL Server:

- `AFTER LOGON`
    
- `AFTER LOGOFF`
    

PostgreSQL **has no equivalent**.

### Why?

Because PostgreSQL uses a **process-per-connection model**, not a central event framework for session lifecycle events.

### Workarounds:

- Use `log_connections` and parse logs
    
- Use `pg_stat_activity` to monitor connected users
    
- Patch PostgreSQL (rare and not recommended)
    
- Use connection pooling logs (like PgBouncer)
    

But **no native logon/logoff triggers**.

---

# 🔥 Summary Table

|Trigger Type|Supported in PostgreSQL?|How|
|---|---|---|
|**DML Triggers**|✔ Yes|Normal triggers (`INSERT/UPDATE/DELETE/TRUNCATE`)|
|**DDL Triggers**|❌ No|But ✔ Event Triggers instead|
|**Logon Triggers**|❌ No|No direct support|

---

# 🧠 Quick Visual

```
       PostgreSQL Trigger Support
-----------------------------------------
DML Trigger          ✔ Supported
DDL Trigger          ❌ Not direct → use Event Trigger
Logon Trigger        ❌ Not supported at all
```



###### Tags : [[1 - SQL 🥞]]