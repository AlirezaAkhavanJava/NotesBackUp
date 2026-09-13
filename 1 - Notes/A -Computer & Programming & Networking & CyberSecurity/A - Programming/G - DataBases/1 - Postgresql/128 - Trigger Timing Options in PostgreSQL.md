
## ✅ Trigger Timing Options in PostgreSQL

PostgreSQL supports **two** timing phases:

### **1. BEFORE Trigger**

Fires **before** the operation happens.

- Useful for validation
    
- Modify data before insert/update
    
- Abort operation by raising an exception
    

### **2. AFTER Trigger**

Fires **after** the operation is completed.

- Useful for logging
    
- Auditing
    
- Sending notifications
    
- Writing to other tables
    

### **3. INSTEAD OF Trigger** (only for views)

Used to make a view updatable by replacing the underlying action.

---

## ❌ No “during” trigger

There is **no** trigger that fires _during_ the operation (because that concept doesn't exist — PostgreSQL either acts before or after, never in the middle of execution).

---

## Example

```sql
CREATE TRIGGER my_after_update
AFTER UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION log_user_updates();
```

---

## Summary Table

|Timing|Table/View|Purpose|
|---|---|---|
|**BEFORE**|Table|Validate or modify row before write|
|**AFTER**|Table|Logging, notifications, side-effects after write|
|**INSTEAD OF**|View|Allow writes to views|


###### Tags : [[1 - SQL 🥞]]