#  **What Are Triggers?**

A **Trigger** in PostgreSQL is **a piece of code that automatically runs when an event happens on a table or view**.

Think of it as PostgreSQL saying:

> “When this table changes, I’ll run your custom logic automatically.”

Triggers run **without you calling them** — they respond to operations like:

- `INSERT`
    
- `UPDATE`
    
- `DELETE`
    
- `TRUNCATE`
    

Triggers can:

- validate data
    
- log data
    
- enforce rules
    
- update other tables
    
- prevent invalid changes
    
- create audit trails
    

---

# 🧩 **A Trigger Has Two Parts**

### 1️⃣ The **Trigger Function** (PL/pgSQL code)

### 2️⃣ The **Trigger** itself (binding: event → function)

---

# 🛠️ Example: A Simple Audit Trigger

## Step 1 — Trigger Function

```sql
CREATE OR REPLACE FUNCTION log_student_changes()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO student_audit(name, action, at_time)
    VALUES (NEW.name, TG_OP, now());

    RETURN NEW;
END;
$$;
```

## Step 2 — Create the Trigger

```sql
CREATE TRIGGER student_audit_trigger
AFTER INSERT OR UPDATE ON students
FOR EACH ROW
EXECUTE FUNCTION log_student_changes();
```

Now anytime a row in `students` is inserted or updated, an audit entry is auto-inserted.

---

# 🔥 **Trigger Timing Options**

### **BEFORE**

Runs _before_ the operation  
→ perfect for validations or modifying `NEW` values.

### **AFTER**

Runs _after_ the operation  
→ great for logging or performing follow-up work.

### **INSTEAD OF**

Used with **views**  
→ override what INSERT/UPDATE/DELETE on a view actually does.

---

# 🧩 **Row vs Statement Triggers**

### **FOR EACH ROW**

Runs once _per row_ affected.

Example: If UPDATE affects 100 rows → trigger runs 100 times.

### **FOR EACH STATEMENT**

Runs once _per SQL statement_, no matter how many rows affected.

---

# 🧠 Special Variables Available Inside Trigger Functions

|Variable|Meaning|
|---|---|
|`NEW`|The new row (for INSERT/UPDATE)|
|`OLD`|The old row (for UPDATE/DELETE)|
|`TG_OP`|Operation name (`INSERT`, `UPDATE`, `DELETE`)|
|`TG_TABLE_NAME`|Table name|
|`TG_WHEN`|BEFORE/AFTER|

Example:

```sql
RAISE NOTICE '% → %', OLD.mark, NEW.mark;
```

---

# ⚠️ Important Notes

- Triggers can **modify data** (in BEFORE triggers only).
    
- Triggers must return:
    
    - `NEW` for INSERT/UPDATE
        
    - `OLD` for DELETE
        
- Badly written triggers can slow down tables.
    
- Use triggers for rules that MUST always be enforced in the database.
    

---

# 🎯 When You Should Use a Trigger

- Data auditing
    
- Auto-updating timestamps (e.g. `updated_at`)
    
- Enforcing complex constraints
    
- Cascading changes across tables
    
- Preventing invalid updates
    
- Soft deletes (moving old rows to archive table)
    

---

# 🎯 When NOT to Use Triggers

Be honest here: if logic belongs in your backend, keep it there.

Avoid triggers when:

- Logic is business-level, not data-level
    
- You need predictable performance
    
- You want maintainability in a large codebase
    

---



###### Tags : [[1 - SQL 🦬]]